#!/usr/bin/env python3
"""Translates the text on cover images with Gemini (image editing).

Queue: table `image_translations` (one row per image URL and language; new
images are queued by a database trigger, old ones by the button in the
translation panel). For every image:

  1. Scan once (cheap text model): is there text worth translating?
     No → all languages are marked `no_text` (the app keeps the original).
  2. Per language: Gemini edits the image, replacing only the text.
     The result is resized to the original size, stored in the `posts`
     bucket under image-translations/<lang>/ and marked `completed`.
     The app then shows it instead of the original in that language.

Without GEMINI_API_KEY, or when the prepaid credit is used up, the worker
stops without touching the queue and writes the reason to `worker_status`
(shown in the panel). After topping up, the next run continues.

Environment:
  GEMINI_API_KEY               Google AI Studio key (required to do work)
  GEMINI_IMAGE_MODEL           default gemini-3.1-flash-image
  GEMINI_TEXT_MODEL            default gemini-flash-latest
  SUPABASE_SERVICE_ROLE_KEY    or SUPABASE_ACCESS_TOKEN (key is fetched)
  LIMIT                        max image edits per run (default 300)
  TIME_BUDGET_MIN              stop starting new items after this (default 300)
  WORKERS                      parallel requests (default 4)
  PLAN_ONLY=1                  only print how many rows are pending
"""
from __future__ import annotations

import base64
import concurrent.futures as cf
import hashlib
import io
import json
import os
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

PROJECT_REF = "vdcdibvclaulqxfjyzpq"
SUPABASE_URL = os.environ.get("SUPABASE_URL", f"https://{PROJECT_REF}.supabase.co").rstrip("/")
BUCKET = "posts"
PREFIX = "image-translations"
WORKER = "image-translation"
IMAGE_MODEL = os.environ.get("GEMINI_IMAGE_MODEL", "gemini-3.1-flash-image")
TEXT_MODEL = os.environ.get("GEMINI_TEXT_MODEL", "gemini-flash-latest")
GEMINI = "https://generativelanguage.googleapis.com/v1beta/models"
STALE_AFTER_S = 2 * 3600
MAX_ATTEMPTS = 3

LANG_NAMES = {
    "en": "English",
    "ru": "Russian",
    "es": "Spanish",
    "pl": "Polish",
    "tr": "Turkish",
    "he": "Hebrew (right-to-left)",
}
# Aspect ratios Gemini can produce.
RATIOS = {"1:1": 1.0, "2:3": 2 / 3, "3:2": 1.5, "3:4": 0.75, "4:3": 4 / 3,
          "4:5": 0.8, "5:4": 1.25, "9:16": 9 / 16, "16:9": 16 / 9, "21:9": 21 / 9}


def log(*args):
    print(*args, flush=True)


def now_iso() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


# ─── Supabase ────────────────────────────────────────────────────────────────

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


def update_rows(source_url: str, fields: dict, language: str | None = None):
    q = f"source_url=eq.{urllib.parse.quote(source_url, safe='')}"
    if language:
        q += f"&language=eq.{language}"
    rest("PATCH", f"/rest/v1/image_translations?{q}", body={**fields, "updated_at": now_iso()},
         headers={"Prefer": "return=minimal"})


def set_status(state: str, message: str = ""):
    try:
        rest("POST", "/rest/v1/worker_status?on_conflict=name",
             body={"name": WORKER, "state": state, "message": message, "updated_at": now_iso()},
             headers={"Prefer": "resolution=merge-duplicates,return=minimal"})
    except Exception as e:  # noqa: BLE001
        log(f"(could not write worker status: {str(e)[:120]})")


# ─── Gemini ──────────────────────────────────────────────────────────────────

class OutOfCredit(Exception):
    pass


class BadKey(Exception):
    pass


def gemini(model: str, body: dict) -> dict:
    key = os.environ["GEMINI_API_KEY"].strip()
    req = urllib.request.Request(
        f"{GEMINI}/{model}:generateContent",
        data=json.dumps(body).encode(),
        method="POST",
        headers={"Content-Type": "application/json", "x-goog-api-key": key},
    )
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            msg = e.read().decode(errors="replace")
            low = msg.lower()
            if e.code == 402 or any(w in low for w in ("prepay", "credit", "billing", "insufficient")):
                raise OutOfCredit(msg[:300]) from None
            if e.code in (401, 403) or "api key not valid" in low or "api_key_invalid" in low:
                raise BadKey(msg[:300]) from None
            if e.code == 429 or e.code >= 500:
                if "limit: 0" in low:  # free tier has no image quota
                    raise OutOfCredit(msg[:300]) from None
                time.sleep(min(60, 5 * 2 ** attempt))
                continue
            raise RuntimeError(f"Gemini {e.code}: {msg[:300]}") from None
        except urllib.error.URLError:
            time.sleep(2 ** attempt)
    raise RuntimeError("Gemini: too many retries")


def image_part(data: bytes, mime: str) -> dict:
    return {"inline_data": {"mime_type": mime, "data": base64.b64encode(data).decode()}}


def scan(data: bytes, mime: str) -> tuple[bool, str]:
    prompt = (
        "Look at this cover image from a Christian youth magazine app (German). "
        "Is there readable text in it that a reader in another language would want translated "
        "(headlines, quotes, captions)? Answer false if there is no text, or only logos/brand "
        "names (e.g. 'Jugendkompass'), numbers, or tiny illegible text. "
        'Reply as JSON: {"has_text": true|false, "text": "<the text exactly as written>"}'
    )
    res = gemini(TEXT_MODEL, {
        "contents": [{"parts": [image_part(data, mime), {"text": prompt}]}],
        "generationConfig": {"responseMimeType": "application/json", "temperature": 0},
    })
    txt = "".join(p.get("text", "") for p in res["candidates"][0]["content"]["parts"])
    parsed = json.loads(txt)
    return bool(parsed.get("has_text")), (parsed.get("text") or "").strip()


def nearest_ratio(w: int, h: int) -> str:
    r = w / h
    return min(RATIOS, key=lambda k: abs(RATIOS[k] - r))


def edit(data: bytes, mime: str, lang: str, text: str, hint: str, size: tuple[int, int]) -> bytes:
    name = LANG_NAMES[lang]
    prompt = (
        f"Translate all visible German text in this image into {name}. "
        "Change ONLY the text: keep the photo, people, colours, layout, typography style, "
        "font weight, text size, alignment and positions exactly as they are. "
        "Keep logos and brand names (e.g. 'Jugendkompass') unchanged. "
        f"Use the standard {name} names for Bible books and references. "
        "Do not add any new text or elements."
    )
    if text:
        prompt += f"\nThe German text in the image is: \"{text}\""
    if hint:
        prompt += f"\nThe article title in {name} is: \"{hint}\" – use it if the image shows the title."
    res = gemini(IMAGE_MODEL, {
        "contents": [{"parts": [image_part(data, mime), {"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["IMAGE"],
            "imageConfig": {"aspectRatio": nearest_ratio(*size)},
        },
    })
    cand = (res.get("candidates") or [{}])[0]
    for p in (cand.get("content") or {}).get("parts", []):
        d = p.get("inline_data") or p.get("inlineData")
        if d and d.get("data"):
            return base64.b64decode(d["data"])
    raise RuntimeError(f"no image returned ({cand.get('finishReason', 'unknown')})")


def fit_to(original_size: tuple[int, int], data: bytes) -> bytes:
    """Scale/crop the result to the original pixel size, encode as JPEG."""
    from PIL import Image, ImageOps

    img = Image.open(io.BytesIO(data)).convert("RGB")
    img = ImageOps.fit(img, original_size, method=Image.LANCZOS)
    out = io.BytesIO()
    img.save(out, format="JPEG", quality=90, optimize=True)
    return out.getvalue()


# ─── Work ────────────────────────────────────────────────────────────────────

def download(url: str) -> tuple[bytes, str, tuple[int, int]]:
    from PIL import Image

    with urllib.request.urlopen(url, timeout=60) as r:
        data = r.read()
    img = Image.open(io.BytesIO(data))
    size = img.size
    # Gemini accepts jpeg/png/webp; normalise everything else (and huge files).
    if img.format not in ("JPEG", "PNG", "WEBP") or len(data) > 6_000_000:
        img = img.convert("RGB")
        img.thumbnail((2048, 2048))
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=92)
        return buf.getvalue(), "image/jpeg", size
    return data, Image.MIME[img.format], size


def title_hints(rows: list[dict]) -> dict:
    """(entity_type, entity_id, lang) -> translated title, where available."""
    hints = {}
    by_table: dict[str, set] = {}
    for r in rows:
        if r.get("entity_type") in ("posts", "impulses", "messages") and r.get("entity_id"):
            by_table.setdefault(r["entity_type"], set()).add(r["entity_id"])
    for table, ids in by_table.items():
        ids = list(ids)
        for i in range(0, len(ids), 80):
            chunk = ",".join(ids[i:i + 80])
            try:
                items = rest("GET", f"/rest/v1/{table}?select=id,content_id&id=in.({chunk})")
                cmap = {it["content_id"]: it["id"] for it in items if it.get("content_id")}
                if not cmap:
                    continue
                trs = rest("GET", "/rest/v1/content_translations?select=content_id,language,value"
                                  f"&field_name=eq.title&content_id=in.({','.join(cmap)})")
                for t in trs:
                    hints[(table, cmap[t["content_id"]], t["language"])] = (t["value"] or "").strip()
            except Exception as e:  # noqa: BLE001
                log(f"(no title hints for {table}: {str(e)[:100]})")
    return hints


def pending_rows() -> list[dict]:
    rows = rest("GET", "/rest/v1/image_translations?select=*&status=in.(pending,processing,failed)"
                       "&order=requested_at.desc&limit=5000")
    out = []
    now = time.time()
    for r in rows:
        if r["status"] == "failed" and (r.get("attempts") or 0) >= MAX_ATTEMPTS and not r.get("force"):
            continue
        if r["status"] == "processing" and r.get("started_at"):
            started = time.mktime(time.strptime(r["started_at"][:19], "%Y-%m-%dT%H:%M:%S")) - time.timezone
            if now - started < STALE_AFTER_S:
                continue
        out.append(r)
    return out


STOP = threading.Event()
STOP_REASON: list[tuple[str, str]] = []


def process_image(source_url: str, rows: list[dict], scans: dict, hints: dict) -> int:
    """Returns the number of image edits made."""
    if STOP.is_set():
        return 0
    langs = [r["language"] for r in rows]
    try:
        data, mime, size = download(source_url)
    except Exception as e:  # noqa: BLE001
        for r in rows:
            update_rows(source_url, {"status": "failed", "error": f"Bild nicht ladbar: {str(e)[:150]}",
                                     "attempts": (r.get("attempts") or 0) + 1}, r["language"])
        return 0

    sc = scans.get(source_url)
    if sc is None:
        has_text, text = scan(data, mime)
        rest("POST", "/rest/v1/image_text_scans?on_conflict=source_url",
             body={"source_url": source_url, "has_text": has_text, "detected_text": text},
             headers={"Prefer": "resolution=merge-duplicates,return=minimal"})
        sc = {"has_text": has_text, "detected_text": text}
    forced = {r["language"] for r in rows if r.get("force")}
    if not sc["has_text"] and not forced:
        update_rows(source_url, {"status": "no_text", "error": None, "finished_at": now_iso(), "force": False})
        log(f"  no text: {source_url.rsplit('/', 1)[-1]}")
        return 0

    edits = 0
    digest = hashlib.sha1(source_url.encode()).hexdigest()[:16]
    for r in rows:
        if STOP.is_set():
            break
        lang = r["language"]
        if not sc["has_text"] and lang not in forced:
            continue
        update_rows(source_url, {"status": "processing", "started_at": now_iso(), "error": None}, lang)
        try:
            out = fit_to(size, edit(data, mime, lang, sc.get("detected_text") or "",
                                    hints.get((r.get("entity_type"), r.get("entity_id"), lang), ""), size))
            stamp = int(time.time())
            path = f"{PREFIX}/{lang}/{digest}-{stamp}.jpg"
            rest("POST", f"/storage/v1/object/{BUCKET}/{urllib.parse.quote(path)}", raw=out,
                 ctype="image/jpeg", headers={"x-upsert": "true", "cache-control": "31536000"})
            old = r.get("storage_path")
            update_rows(source_url, {
                "status": "completed", "url": f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{path}",
                "storage_path": path, "finished_at": now_iso(), "error": None, "force": False,
                "attempts": (r.get("attempts") or 0) + 1,
            }, lang)
            if old and old != path:
                try:
                    rest("DELETE", f"/storage/v1/object/{BUCKET}", body={"prefixes": [old]})
                except Exception:  # noqa: BLE001
                    pass
            edits += 1
            log(f"  ✓ {lang} {source_url.rsplit('/', 1)[-1]}")
        except OutOfCredit as e:
            update_rows(source_url, {"status": "pending", "started_at": None}, lang)
            STOP_REASON.append(("no_credit", str(e)[:200]))
            STOP.set()
        except BadKey as e:
            update_rows(source_url, {"status": "pending", "started_at": None}, lang)
            STOP_REASON.append(("bad_key", str(e)[:200]))
            STOP.set()
        except Exception as e:  # noqa: BLE001
            update_rows(source_url, {"status": "failed", "error": str(e)[:300], "force": False,
                                     "attempts": (r.get("attempts") or 0) + 1}, lang)
            log(f"  ✗ {lang} {source_url.rsplit('/', 1)[-1]}: {str(e)[:160]}")
    return edits


def main():
    global KEY
    KEY = service_key()
    rows = pending_rows()
    by_url: dict[str, list[dict]] = {}
    for r in rows:
        by_url.setdefault(r["source_url"], []).append(r)
    log(f"{len(rows)} pending translations in {len(by_url)} images")

    if os.environ.get("PLAN_ONLY") == "1":
        out = os.environ.get("GITHUB_OUTPUT")
        if out:
            with open(out, "a") as f:
                f.write(f"pending={len(rows)}\n")
        return
    if not os.environ.get("GEMINI_API_KEY", "").strip():
        set_status("no_key", "GitHub-Secret GEMINI_API_KEY fehlt")
        log("GEMINI_API_KEY missing – nothing to do.")
        return
    if not rows:
        set_status("idle", "Alles übersetzt")
        return

    scans = {s["source_url"]: s for s in rest("GET", "/rest/v1/image_text_scans?select=*&limit=10000")}
    hints = title_hints(rows)
    limit = int(os.environ.get("LIMIT", "300"))
    deadline = time.time() + float(os.environ.get("TIME_BUDGET_MIN", "300")) * 60
    set_status("running", f"{len(rows)} offen")

    edits = 0
    lock = threading.Lock()
    urls = list(by_url)

    def run(url):
        nonlocal edits
        with lock:
            if edits >= limit or time.time() > deadline:
                return
        n = process_image(url, by_url[url], scans, hints)
        with lock:
            edits += n

    try:
        with cf.ThreadPoolExecutor(int(os.environ.get("WORKERS", "4"))) as pool:
            for f in cf.as_completed([pool.submit(run, u) for u in urls]):
                try:
                    f.result()
                except (OutOfCredit, BadKey) as e:
                    STOP_REASON.append(("no_credit" if isinstance(e, OutOfCredit) else "bad_key", str(e)[:200]))
                    STOP.set()
                except Exception as e:  # noqa: BLE001
                    log(f"(error: {str(e)[:200]})")
    finally:
        if STOP_REASON:
            state, msg = STOP_REASON[0]
            set_status(state, "Gemini-Guthaben aufgebraucht – bitte aufladen" if state == "no_credit"
                       else "GEMINI_API_KEY ungültig")
            log(f"Stopped: {state}: {msg}")
        else:
            left = len(pending_rows())
            set_status("idle" if left == 0 else "running",
                       "Alles übersetzt" if left == 0 else f"{left} offen – nächster Lauf macht weiter")
    log(f"{edits} images translated")


if __name__ == "__main__":
    main()
