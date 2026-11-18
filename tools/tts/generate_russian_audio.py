#!/usr/bin/env python3
"""Russian AI voice for article audios with Piper (free, open source, MIT).

Reuses the English pipeline (queue audio_tts_jobs, texts from
content_translations, storage, audio_translations) with LANGUAGE = ru and the
Piper voice ru_RU-dmitri-medium instead of Kokoro (Kokoro has no Russian).
"""
import os, subprocess, sys, tempfile, time, zlib

sys.path.insert(0, os.path.dirname(__file__))
import generate_english_audio as g  # noqa: E402

g.LANGUAGE = "ru"
g.TTS_PREFIX = "tts/ru/"
g.HASH_VERSION = "piper-ru-v1"
MODEL = os.environ.get("PIPER_MODEL", "ru_RU-dmitri-medium.onnx")


def synth(parts):
    import numpy as np
    import soundfile as sf
    with tempfile.TemporaryDirectory() as d:
        wav = f"{d}/out.wav"
        subprocess.run(["piper", "--model", MODEL, "--output_file", wav, "--sentence_silence", "0.35"],
                       input="\n".join(parts).encode(), check=True, capture_output=True)
        data, sr = sf.read(wav, dtype="float32")
    return np.asarray(data, dtype=np.float32), sr


def main():
    g.KEY = g.service_key()
    shard, shards = int(os.environ.get("SHARD", 0)), max(1, int(os.environ.get("SHARDS", 1)))
    items = [i for i in g.pending_items() if zlib.crc32(i["audio_id"].encode()) % shards == shard]
    g.log(f"{len(items)} Russian audios for shard {shard}/{shards}")
    budget, t0 = float(os.environ.get("TIME_BUDGET_MIN", "300")) * 60, time.time()
    for item in items:
        if time.time() - t0 > budget:
            break
        g.set_job(item["audio_id"], status="processing", started_at=g.now_iso(), finished_at=None,
                  attempts=item.get("attempts", 0) + 1, error=None)
        try:
            samples, sr = synth(g.paragraphs(item["title"], item["body"]))
            g.store(item, g.to_mp3(samples, sr))
            g.set_job(item["audio_id"], status="completed", finished_at=g.now_iso(), force=False,
                      text_digest=item["digest"], duration_seconds=round(len(samples) / sr, 1))
            g.log(f"✓ {item['title'][:60]}")
        except Exception as e:  # noqa: BLE001
            g.set_job(item["audio_id"], status="failed", finished_at=g.now_iso(), error=str(e)[:500])
            g.log(f"✗ {item['audio_id']}: {e}")


if __name__ == "__main__":
    main()
