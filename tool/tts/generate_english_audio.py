#!/usr/bin/env python3
"""Generate English AI-voice versions of all article audios.

For every post with an audio file it takes the English translation of the
article (content_translations, filled by the translation worker), reads it
with the free, open Kokoro-82M voice model (Apache-2.0, runs on CPU) and
stores the MP3 in the `audios` bucket. The app plays it automatically when
the app language is English (table `audio_translations`).

* Only audios without an English version are generated; when the English
  text changes, the AI version is regenerated (hash in the file name).
* Manually uploaded translations (not under tts/) are never replaced.
* Work can be split across parallel jobs (SHARD / SHARDS).

Environment:
  SUPABASE_URL                 project URL
  SUPABASE_SERVICE_ROLE_KEY    or SUPABASE_ACCESS_TOKEN (key is fetched)
  KOKORO_MODEL, KOKORO_VOICES  model file paths
  SHARD, SHARDS                default 0 / 1
  TIME_BUDGET_MIN              stop starting new items after this (default 300)
  LIMIT                        max items per run (default: no limit)
  VOICE                        Kokoro voice (default am_michael)
  PLAN_ONLY=1                  only print how many items are pending
"""
from __future__ import annotations

import hashlib
import html
import io
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import zlib

PROJECT_REF = "vdcdibvclaulqxfjyzpq"
SUPABASE_URL = os.environ.get("SUPABASE_URL", f"https://{PROJECT_REF}.supabase.co").rstrip("/")
BUCKET = "audios"
LANGUAGE = "en"
TTS_PREFIX = "tts/en/"
HASH_VERSION = "kokoro-v1"


def log(*args):
    print(*args, flush=True)


def service_key() -> str:
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if key:
        return key
    token = os.environ.get("SUPABASE_ACCESS_TOKEN", "").strip()
    if not token:
        sys.exit("SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ACCESS_TOKEN required")
    req = urllib.request.Request(
        f"https://api.supabase.com/v1/projects/{PROJECT_REF}/api-keys?reveal=true",
        headers={"Authorization": f"Bearer {token}"},
    )
    for k in json.load(urllib.request.urlopen(req, timeout=30)):
        if k.get("name") == "service_role" and k.get("api_key"):
            return k["api_key"]
    sys.exit("service_role key not found via management API")


KEY = ""


def rest(method: str, path: str, body=None, headers=None, raw: bytes | None = None, ctype=None):
    url = f"{SUPABASE_URL}{path}"
    data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
    h = {"apikey": KEY, "Authorization": f"Bearer {KEY}"}
    if data is not None:
        h["Content-Type"] = ctype or "application/json"
    h.update(headers or {})
    req = urllib.request.Request(url, data=data, method=method, headers=h)
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                txt = r.read()
                return json.loads(txt) if txt and r.headers.get_content_type() == "application/json" else txt
        except urllib.error.HTTPError as e:
            msg = e.read().decode(errors="replace")[:300]
            if e.code >= 500 and attempt < 3:
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(f"{method} {path} -> {e.code}: {msg}") from None
        except urllib.error.URLError:
            if attempt < 3:
                time.sleep(2 ** attempt)
                continue
            raise


def chunked(items, n):
    for i in range(0, len(items), n):
        yield items[i:i + n]


# ─── Text ────────────────────────────────────────────────────────────────────

def clean_text(value: str) -> str:
    """HTML → plain text with paragraph breaks."""
    s = value or ""
    s = re.sub(r"(?i)<br\s*/?>", "\n", s)
    s = re.sub(r"(?i)</(p|div|h[1-6]|li|blockquote)>", "\n\n", s)
    s = re.sub(r"<[^>]+>", " ", s)
    s = html.unescape(s).replace(" ", " ")
    s = re.sub(r"https?://\S+", "", s)
    s = re.sub(r"[ \t]+", " ", s)
    s = re.sub(r"\n\s*\n+", "\n\n", s)
    return s.strip()


def paragraphs(title: str, body: str) -> list[str]:
    parts = [title.strip()] if title.strip() else []
    for p in clean_text(body).split("\n\n"):
        p = " ".join(p.split())
        if p:
            parts.append(p)
    return parts


def split_long(paragraph: str, limit: int = 450) -> list[str]:
    """Keeps requests short for the model (sentence boundaries)."""
    if len(paragraph) <= limit:
        return [paragraph]
    out, cur = [], ""
    for sentence in re.split(r"(?<=[.!?…])\s+", paragraph):
        if len(cur) + len(sentence) + 1 > limit and cur:
            out.append(cur)
            cur = sentence
        else:
            cur = f"{cur} {sentence}".strip()
    if cur:
        out.append(cur)
    # still too long (no punctuation): hard split at spaces
    final = []
    for c in out:
        while len(c) > limit * 1.6:
            cut = c.rfind(" ", 0, limit)
            cut = cut if cut > 0 else limit
            final.append(c[:cut])
            c = c[cut:].strip()
        final.append(c)
    return final


# ─── Work list ───────────────────────────────────────────────────────────────

def pending_items() -> list[dict]:
    posts = rest("GET", "/rest/v1/posts?select=id,audio_id,content_id&audio_id=not.is.null&content_id=not.is.null")
    existing = {
        r["audio_id"]: r
        for r in rest("GET", f"/rest/v1/audio_translations?select=audio_id,storage_path&language=eq.{LANGUAGE}")
    }
    by_content = {}
    for chunk in chunked([p["content_id"] for p in posts], 80):
        ids = ",".join(chunk)
        rows = rest(
            "GET",
            f"/rest/v1/content_translations?select=content_id,field_name,value"
            f"&language=eq.{LANGUAGE}&field_name=in.(title,body)&content_id=in.({ids})",
        )
        for r in rows:
            by_content.setdefault(r["content_id"], {})[r["field_name"]] = r["value"] or ""

    items = []
    seen_audio = set()
    for p in posts:
        audio_id = p["audio_id"]
        if audio_id in seen_audio:
            continue
        tr = by_content.get(p["content_id"], {})
        if not tr.get("body", "").strip():
            continue  # English translation not ready yet
        seen_audio.add(audio_id)
        title, body = tr.get("title", ""), tr["body"]
        digest = hashlib.sha1(f"{HASH_VERSION}|{title}|{body}".encode()).hexdigest()[:10]
        current = existing.get(audio_id)
        if current:
            path = current.get("storage_path") or ""
            if not path.startswith(TTS_PREFIX):
                continue  # manual upload – keep it
            if path.endswith(f"-{digest}.mp3"):
                continue  # up to date
        items.append({"audio_id": audio_id, "title": title, "body": body, "digest": digest,
                      "old_path": (current or {}).get("storage_path")})
    items.sort(key=lambda i: i["audio_id"])
    return items


# ─── Synthesis ───────────────────────────────────────────────────────────────

def synthesize(kokoro, voice: str, parts: list[str]):
    import numpy as np

    sr = 24000
    pause = np.zeros(int(sr * 0.45), dtype=np.float32)
    audio = []
    for i, part in enumerate(parts):
        for chunk in split_long(part):
            samples, sr = kokoro.create(chunk, voice=voice, speed=1.0, lang="en-us")
            audio.append(samples.astype(np.float32))
        audio.append(pause if i else np.zeros(int(sr * 0.8), dtype=np.float32))  # longer after title
    return np.concatenate(audio), sr


def to_mp3(samples, sr) -> bytes:
    import soundfile as sf

    wav = io.BytesIO()
    sf.write(wav, samples, sr, format="WAV", subtype="PCM_16")
    proc = subprocess.run(
        ["ffmpeg", "-loglevel", "error", "-i", "pipe:0", "-ac", "1", "-b:a", "64k", "-f", "mp3", "pipe:1"],
        input=wav.getvalue(), capture_output=True, check=True,
    )
    return proc.stdout


def store(item: dict, mp3: bytes):
    path = f"{TTS_PREFIX}{item['audio_id']}-{item['digest']}.mp3"
    rest("POST", f"/storage/v1/object/{BUCKET}/{urllib.parse.quote(path)}", raw=mp3,
         ctype="audio/mpeg", headers={"x-upsert": "true", "cache-control": "31536000"})
    url = f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{path}"
    rest("POST", "/rest/v1/audio_translations?on_conflict=audio_id,language",
         body={"audio_id": item["audio_id"], "language": LANGUAGE, "url": url,
               "storage_path": path, "file_name": path.rsplit("/", 1)[-1]},
         headers={"Prefer": "resolution=merge-duplicates,return=minimal"})
    old = item.get("old_path")
    if old and old != path and old.startswith(TTS_PREFIX):
        try:
            rest("DELETE", f"/storage/v1/object/{BUCKET}", body={"prefixes": [old]})
        except Exception as e:  # noqa: BLE001
            log(f"  (could not delete old file {old}: {e})")
    return url


def main():
    global KEY
    KEY = service_key()
    shard = int(os.environ.get("SHARD", "0"))
    shards = max(1, int(os.environ.get("SHARDS", "1")))
    budget = float(os.environ.get("TIME_BUDGET_MIN", "300")) * 60
    limit = int(os.environ.get("LIMIT", "0") or 0)
    voice = os.environ.get("VOICE", "am_michael")

    items = pending_items()
    if os.environ.get("PLAN_ONLY") == "1":
        log(f"pending={len(items)}")
        out = os.environ.get("GITHUB_OUTPUT")
        if out:
            with open(out, "a") as f:
                f.write(f"pending={len(items)}\n")
        return

    mine = [i for i in items if zlib.crc32(i["audio_id"].encode()) % shards == shard]
    if limit:
        mine = mine[:limit]
    log(f"{len(items)} pending in total, {len(mine)} for shard {shard}/{shards}")
    if not mine:
        return

    from kokoro_onnx import Kokoro

    kokoro = Kokoro(os.environ.get("KOKORO_MODEL", "kokoro-v1.0.onnx"),
                    os.environ.get("KOKORO_VOICES", "voices-v1.0.bin"))
    started = time.time()
    done = failed = 0
    for item in mine:
        if time.time() - started > budget:
            log("time budget reached – the next run continues")
            break
        t0 = time.time()
        try:
            samples, sr = synthesize(kokoro, voice, paragraphs(item["title"], item["body"]))
            url = store(item, to_mp3(samples, sr))
            done += 1
            log(f"✓ {item['audio_id']} {len(samples) / sr / 60:.1f} min audio in "
                f"{(time.time() - t0) / 60:.1f} min – {item['title'][:60]}")
            log(f"  {url}")
        except Exception as e:  # noqa: BLE001
            failed += 1
            log(f"✗ {item['audio_id']}: {e}")
    log(f"done={done} failed={failed}")
    if failed and not done:
        sys.exit(1)


if __name__ == "__main__":
    main()
