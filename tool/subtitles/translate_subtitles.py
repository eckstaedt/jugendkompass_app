#!/usr/bin/env python3
"""Subtitles in another language (SUB_LANG: ru default, pl) from the English ones with
the free, open-source Helsinki-NLP MarianMT models (CPU, no API costs):
ru = opus-mt-en-ru, pl = opus-mt-en-sla with the target token >>pol<<.
Same timestamps, text translated line by line."""
import json, os, sys, urllib.request

LANG = os.environ.get("SUB_LANG", "ru")
MODELS = {"ru": ("Helsinki-NLP/opus-mt-en-ru", ""), "pl": ("Helsinki-NLP/opus-mt-en-sla", ">>pol<< ")}
if LANG not in MODELS:
    sys.exit(f"unsupported SUB_LANG {LANG}")
MODEL_NAME, PREFIX = MODELS[LANG]

sys.argv = sys.argv[:1]
os.environ.setdefault("PLAN_ONLY", "")
import importlib.util  # noqa: E402

spec = importlib.util.spec_from_file_location("ms", os.path.join(os.path.dirname(__file__), "make_subtitles.py"))
SB = os.environ.get("SUPABASE_URL", "https://api.jugendkompass.com").rstrip("/")
src = open(os.path.join(os.path.dirname(__file__), "make_subtitles.py")).read()
ns = {}
exec(src.split("videos = rest(")[0], ns)  # key() + rest() only
rest = ns["rest"]

en = rest("GET", "/rest/v1/video_subtitles?select=video_url,url&language=eq.en")
have = {r["video_url"] for r in rest("GET", f"/rest/v1/video_subtitles?select=video_url&language=eq.{LANG}")}
todo = [r for r in en if r["video_url"] not in have]
print(f"{len(todo)} videos to translate into {LANG}", flush=True)
if not todo:
    sys.exit(0)

from transformers import MarianMTModel, MarianTokenizer  # noqa: E402

tok, model = MarianTokenizer.from_pretrained(MODEL_NAME), MarianMTModel.from_pretrained(MODEL_NAME)


def translate(lines):
    out = []
    for i in range(0, len(lines), 16):
        batch = tok([PREFIX + x for x in lines[i:i + 16]], return_tensors="pt", padding=True, truncation=True)
        out += tok.batch_decode(model.generate(**batch, max_new_tokens=200), skip_special_tokens=True)
    return out


for r in todo:
    try:
        subs = json.load(urllib.request.urlopen(r["url"]))
        texts = translate([s["t"] for s in subs])
        out = [{**s, "t": t} for s, t in zip(subs, texts)]
        path = r["url"].split("/public/videos/")[1].replace("/en/", f"/{LANG}/")
        rest("POST", f"/storage/v1/object/videos/{path}", raw=json.dumps(out, ensure_ascii=False).encode(),
             extra={"x-upsert": "true"})
        rest("POST", "/rest/v1/video_subtitles?on_conflict=video_url,language",
             body={"video_url": r["video_url"], "language": LANG, "url": f"{SB}/storage/v1/object/public/videos/{path}"},
             extra={"Prefer": "resolution=merge-duplicates,return=minimal"})
        print(f"OK {len(out)} lines", flush=True)
    except Exception as e:  # noqa: BLE001
        print(f"FAIL {r['video_url'][-40:]}: {e}", flush=True)
