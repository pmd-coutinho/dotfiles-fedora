#!/usr/bin/env bash
# Push-to-toggle dictation for niri/Wayland.
#   1st press -> start recording the mic
#   2nd press -> stop, run Whisper on the GPU, and type the result via wtype.
#
# Mode (1st arg, default "translate"; remembered for the matching stop press):
#   translate   -> speak PT/EN, always types English
#   transcribe  -> types verbatim in the spoken language (e.g. Portuguese)
set -uo pipefail

MODE="${1:-translate}"
case "$MODE" in translate|transcribe) ;; *) MODE="translate" ;; esac

DIR="$HOME/.local/share/dictation"
VENV="$DIR/venv"
PY="$VENV/bin/python"

RUNDIR="${XDG_RUNTIME_DIR:-/tmp}/dictate"
mkdir -p "$RUNDIR"
WAV="$RUNDIR/rec.wav"
RECPID="$RUNDIR/rec.pid"
MODEFILE="$RUNDIR/mode"

# faster-whisper's ctranslate2 needs the pip-installed cuBLAS/cuDNN libs on the path.
# nvidia is a namespace package, so glob every nvidia/*/lib dir under site-packages.
NVLIBS="$("$PY" -c 'import nvidia, os, glob; print(":".join(sorted(glob.glob(os.path.join(nvidia.__path__[0], "*", "lib")))))' 2>/dev/null || true)"
if [ -n "$NVLIBS" ]; then
  export LD_LIBRARY_PATH="$NVLIBS:${LD_LIBRARY_PATH:-}"
fi

notify() { notify-send -t "${2:-2000}" -a Dictation "🎙 Dictation" "$1"; }

ensure_server() {
  if "$PY" "$DIR/client.py" --ping >/dev/null 2>&1; then
    return 0
  fi
  notify "Warming up model…" 5000
  setsid "$PY" "$DIR/server.py" >"$RUNDIR/server.log" 2>&1 &
  for _ in $(seq 1 240); do
    sleep 0.5
    if "$PY" "$DIR/client.py" --ping >/dev/null 2>&1; then
      return 0
    fi
  done
  notify "Model failed to start — see $RUNDIR/server.log" 6000
  return 1
}

is_recording() { [ -f "$RECPID" ] && kill -0 "$(cat "$RECPID")" 2>/dev/null; }

if is_recording; then
  # ---- stop & transcribe ----
  kill -INT "$(cat "$RECPID")" 2>/dev/null || true
  rm -f "$RECPID"
  sleep 0.3   # let ffmpeg finalize the wav header
  MODE="$(cat "$MODEFILE" 2>/dev/null || echo translate)"
  notify "Transcribing… ($MODE)" 2000
  ensure_server || exit 1
  TEXT="$("$PY" "$DIR/client.py" "$WAV" "$MODE" 2>/dev/null || true)"
  TEXT="${TEXT#"${TEXT%%[![:space:]]*}"}"   # ltrim
  TEXT="${TEXT%"${TEXT##*[![:space:]]}"}"   # rtrim
  if [ -z "$TEXT" ]; then
    notify "No speech detected" 2000
    exit 0
  fi
  printf '%s' "$TEXT" | wtype -
  notify "✓ ${TEXT:0:80}" 2500
else
  # ---- start recording ----
  ensure_server || exit 1
  # Pick the mic: explicit override > pinned config file > current system default.
  SRC="${DICTATE_SOURCE:-}"
  if [ -z "$SRC" ] && [ -f "$HOME/.config/dictation/source" ]; then
    SRC="$(cat "$HOME/.config/dictation/source")"
  fi
  if [ -z "$SRC" ]; then
    SRC="$(pactl get-default-source 2>/dev/null)"
  fi
  [ -z "$SRC" ] && SRC="default"
  echo "$MODE" >"$MODEFILE"   # remember mode for the stop press
  notify "Listening · $MODE (${SRC:0:30})… press again to stop" 1500
  # -thread_queue_size helps with bluetooth/usb mics; explicit source avoids ffmpeg's
  # "default" resolving to something other than the PipeWire default.
  setsid ffmpeg -y -hide_banner -loglevel error -thread_queue_size 512 \
    -f pulse -i "$SRC" -ar 16000 -ac 1 "$WAV" >/dev/null 2>&1 &
  echo $! >"$RECPID"
fi
