#!/usr/bin/env python3
"""Warm model server for dictation. Loads faster-whisper once and serves
transcribe/translate requests over a unix socket so each dictation is fast.

Protocol (one request per connection):
  "PING"          -> "PONG"
  "<path-to-wav>" -> transcribed/translated text (UTF-8)

Config via env:
  DICTATE_MODEL   (default: large-v3)
  DICTATE_DEVICE  (default: cuda; falls back to cpu on failure)
  DICTATE_COMPUTE (default: float16; cpu fallback uses int8)
  DICTATE_TASK    (default: translate -> always English out; use "transcribe" to keep source language)
  DICTATE_LANG    (default: unset -> auto-detect the spoken language)
"""
import os
import socket
import sys
import traceback

from faster_whisper import WhisperModel

RUNDIR = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "dictate")
SOCK = os.path.join(RUNDIR, "sock")

MODEL = os.environ.get("DICTATE_MODEL", "large-v3")
DEVICE = os.environ.get("DICTATE_DEVICE", "cuda")
COMPUTE = os.environ.get("DICTATE_COMPUTE", "float16")
TASK = os.environ.get("DICTATE_TASK", "translate")
LANG = os.environ.get("DICTATE_LANG") or None


def log(*a):
    print("[dictate-server]", *a, file=sys.stderr, flush=True)


def load_model():
    global DEVICE, COMPUTE
    try:
        m = WhisperModel(MODEL, device=DEVICE, compute_type=COMPUTE)
        log(f"loaded {MODEL} on {DEVICE}/{COMPUTE}")
        return m
    except Exception as e:
        log(f"GPU load failed ({e!r}); falling back to CPU/int8")
        DEVICE, COMPUTE = "cpu", "int8"
        m = WhisperModel(MODEL, device="cpu", compute_type="int8")
        log(f"loaded {MODEL} on cpu/int8")
        return m


def transcribe(model, path, task):
    if task not in ("translate", "transcribe"):
        task = TASK
    segments, _info = model.transcribe(
        path,
        task=task,
        language=LANG,
        beam_size=5,
        vad_filter=True,
    )
    return "".join(s.text for s in segments).strip()


def main():
    os.makedirs(RUNDIR, exist_ok=True)
    if os.path.exists(SOCK):
        os.unlink(SOCK)

    model = load_model()

    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(SOCK)
    srv.listen(1)
    log("ready, listening on", SOCK)

    while True:
        conn, _ = srv.accept()
        try:
            data = b""
            while True:
                chunk = conn.recv(65536)
                if not chunk:
                    break
                data += chunk
            req = data.decode().strip()
            if req == "PING":
                conn.sendall(b"PONG")
                continue
            if not req:
                conn.sendall(b"")
                continue
            # Request is either "<path>" or "<task>\t<path>" (task: translate|transcribe).
            if "\t" in req:
                task, path = req.split("\t", 1)
            else:
                task, path = TASK, req
            text = transcribe(model, path.strip(), task.strip())
            conn.sendall(text.encode())
        except Exception:
            log(traceback.format_exc())
            try:
                conn.sendall(b"")
            except Exception:
                pass
        finally:
            conn.close()


if __name__ == "__main__":
    main()
