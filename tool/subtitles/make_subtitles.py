#!/usr/bin/env python3
"""English subtitles for the (German) videos with Whisper (free, open model).

Whisper's "translate" task listens to the German audio and writes English
segments with timestamps. Result: JSON [{"s": start, "e": end, "t": text}]
in storage videos/subtitles/en/<hash>.json + a row in video_subtitles
(keyed by the video URL, which the app knows). Videos that already have
subtitles are skipped.  Env: SUPABASE_ACCESS_TOKEN or SUPABASE_SERVICE_ROLE_KEY,
WHISPER_MODEL (default small), SHARD/SHARDS.
"""
import hashlib, json, os, subprocess, sys, tempfile, urllib.request, urllib.parse

REF = "vdcdibvclaulqxfjyzpq"
SB = f"https://{REF}.supabase.co"


def key():
    k = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if k:
        return k
    r = urllib.request.Request(f"https://api.supabase.com/v1/projects/{REF}/api-keys?reveal=true",
                               headers={"Authorization": f"Bearer {os.environ['SUPABASE_ACCESS_TOKEN']}"})
    return [x["api_key"] for x in json.load(urllib.request.urlopen(r)) if x["name"] == "service_role"][0]


KEY = key()
H = {"apikey": KEY, "Authorization": f"Bearer {KEY}"}


def rest(method, path, body=None, raw=None, ctype="application/json", extra=None):
    data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
    r = urllib.request.Request(SB + path, data=data, method=method,
                               headers={**H, **({"Content-Type": ctype} if data else {}), **(extra or {})})
    with urllib.request.urlopen(r, timeout=300) as res:
        t = res.read()
        return json.loads(t) if t and "json" in res.headers.get("Content-Type", "") else None


videos = rest("GET", "/rest/v1/videos?select=id,url,title&order=created_at.desc")
done = {r["video_url"] for r in rest("GET", "/rest/v1/video_subtitles?select=video_url&language=eq.en")}
todo = [v for v in videos if v.get("url") and v["url"] not in done]
shard, shards = int(os.environ.get("SHARD", 0)), int(os.environ.get("SHARDS", 1))
todo = [v for i, v in enumerate(todo) if i % shards == shard]
print(f"{len(todo)} videos to subtitle in this shard", flush=True)
if os.environ.get("PLAN_ONLY"):
    sys.exit(0)

import numpy as np  # noqa: E402
from faster_whisper import WhisperModel  # noqa: E402

model = WhisperModel(os.environ.get("WHISPER_MODEL", "small"), device="cpu", compute_type="int8")
for v in todo:
    try:
        with tempfile.TemporaryDirectory() as d:
            mp4 = f"{d}/v.mp4"
            urllib.request.urlretrieve(urllib.parse.quote(v["url"], safe=":/?&=%"), mp4)
            # Raw 16 kHz mono PCM straight from ffmpeg (avoids PyAV version issues)
            pcm = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", mp4, "-ac", "1", "-ar", "16000",
                                  "-f", "f32le", "pipe:1"], check=True, capture_output=True).stdout
            audio = np.frombuffer(pcm, dtype=np.float32)
            segs, _ = model.transcribe(audio, language="de", task="translate", vad_filter=True)
            out = [{"s": round(s.start, 2), "e": round(s.end, 2), "t": s.text.strip()} for s in segs if s.text.strip()]
        path = f"subtitles/en/{hashlib.sha1(v['url'].encode()).hexdigest()[:16]}.json"
        rest("POST", f"/storage/v1/object/videos/{path}", raw=json.dumps(out, ensure_ascii=False).encode(),
             extra={"x-upsert": "true"})
        rest("POST", "/rest/v1/video_subtitles?on_conflict=video_url,language",
             body={"video_url": v["url"], "language": "en", "url": f"{SB}/storage/v1/object/public/videos/{path}"},
             extra={"Prefer": "resolution=merge-duplicates,return=minimal"})
        print(f"OK {len(out):4d} lines  {v['title']}", flush=True)
    except Exception as e:  # noqa: BLE001
        print(f"FAIL {v.get('title')}: {e}", flush=True)
