#!/usr/bin/env bash
# Reproducible setup for the dictation tool. Run after `stow dictation`.
#   ~/.local/share/dictation/setup.sh
# Idempotent: safe to re-run to repair or upgrade the venv.
set -euo pipefail

DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
VENV="$DIR/venv"

echo "==> Creating venv at $VENV"
python3 -m venv "$VENV"

echo "==> Upgrading pip"
"$VENV/bin/pip" install -q -U pip

echo "==> Installing faster-whisper + CUDA (cuBLAS/cuDNN) wheels"
"$VENV/bin/pip" install -q faster-whisper nvidia-cublas-cu12 nvidia-cudnn-cu12

echo "==> Verifying import"
"$VENV/bin/python" -c "import faster_whisper, ctranslate2; print('faster-whisper', faster_whisper.__version__, '/ ctranslate2', ctranslate2.__version__)"

cat <<'NOTE'

Done. Notes:
  - First dictation downloads the model (large-v3, ~3GB) and loads it onto the
    GPU (~30s). Subsequent dictations are near-instant.
  - Pin a mic (optional) by writing its source name to ~/.config/dictation/source:
        pactl list short sources         # find the name
        mkdir -p ~/.config/dictation
        echo '<source-name>' > ~/.config/dictation/source
    Delete that file to follow the system default instead.
  - No NVIDIA GPU? The server auto-falls back to CPU/int8 (slower); consider
    setting DICTATE_MODEL=small or medium in dictate.sh.
NOTE
