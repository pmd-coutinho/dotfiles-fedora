# Voice dictation (GPU, offline)

Push-to-toggle speech-to-text that types into the focused window on niri/Wayland.
Speak Portuguese or English; choose per keybind whether to **translate to English**
or **transcribe verbatim**. Runs fully offline on the RTX 4080 via
[faster-whisper](https://github.com/SYSTRAN/faster-whisper) (`large-v3`).

## Keybinds

| Key | Mode | Result |
|---|---|---|
| `Mod+Shift+D` | translate | speak PT (or EN) → types **English** |
| `Mod+Alt+D` | transcribe | types **verbatim** in the spoken language (e.g. Portuguese) |

Both are **toggles**: first press starts recording (notification shows the mic +
mode), second press stops, runs Whisper on the GPU, and types the result via
`wtype`. The mode is fixed at the first press and remembered for the stop press,
so stopping with the other key can't desync it.

> niri fires keybinds on press only (no release event, no `bindr`), so true
> hold-to-talk push-to-talk isn't possible without an evdev daemon + `input`
> group access. The toggle is the deliberate, dependency-free choice.

## How it works

```
dictate.sh <mode>            # niri keybind target (toggle)
  ├─ 1st press: ffmpeg records the mic → /run/user/$UID/dictate/rec.wav
  └─ 2nd press: client.py sends "<mode>\t<wav>" to the warm server over a
                unix socket; result is typed with `wtype -`
server.py                    # loads large-v3 once onto the GPU, serves both
                             # translate + transcribe over $XDG_RUNTIME_DIR/dictate/sock
```

The server is **lazy-started** on first dictation (≈30s to load the model into
VRAM, shown as "Warming up model…") and stays resident afterwards, so every
later dictation is near-instant. It is intentionally **not** a startup service —
that keeps ~3–4GB of VRAM free when you're not dictating.

Files (stow package `dictation`, symlinked into `~/.local/share/dictation/`):

| File | Purpose |
|---|---|
| `dictate.sh` | niri keybind target; record ↔ transcribe+type toggle |
| `server.py` | warm faster-whisper model server (unix socket) |
| `client.py` | tiny socket client (`--ping`, or `<wav> [task]`) |
| `setup.sh` | builds the venv (`faster-whisper` + CUDA wheels); idempotent |

The `venv/` and the model cache are machine-built and gitignored.

## Setup (handled by bootstrap.sh)

`bootstrap.sh` installs `wtype`, `ffmpeg`, `pulseaudio-utils`, stows the
`dictation` package, then runs `setup.sh`. To do it manually:

```bash
stow dictation                          # from ~/dotfiles
~/.local/share/dictation/setup.sh       # creates venv, installs faster-whisper + CUDA wheels
```

First dictation downloads the `large-v3` model (~3GB) to the HF cache.

## Choosing the mic

By default it follows the **current system default** source (`pactl
get-default-source`) at record time. The internal laptop mic is pinned here
because it's cleaner and always present (the Bluetooth headset runs in lossy HFP
mode while its mic is active):

```bash
mkdir -p ~/.config/dictation
pactl list short sources                # find the source name you want
echo 'alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source' \
  > ~/.config/dictation/source
```

Delete `~/.config/dictation/source` to follow the system default again. This pin
is **machine-specific** (the ALSA path differs per hardware) and is not tracked.

## Tuning (env vars, set in `dictate.sh`)

| Var | Default | Notes |
|---|---|---|
| `DICTATE_MODEL` | `large-v3` | Best for translation. `large-v3-turbo` is 2.7–4× faster for *transcription* but degrades translation — don't use it on the translate path. |
| `DICTATE_DEVICE` | `cuda` | Auto-falls back to `cpu`/`int8` if the GPU load fails. |
| `DICTATE_COMPUTE` | `float16` | |
| `DICTATE_LANG` | _(auto)_ | Pin e.g. `pt` to skip language auto-detect. |
| `DICTATE_SOURCE` | _(unset)_ | One-off mic override (beats the config-file pin). |

Why `large-v3` and not a leaderboard topper: Canary-Qwen / Parakeet top the Open
ASR leaderboard but are English-centric and run on NVIDIA NeMo (not a faster-whisper
drop-in); Voxtral edges Whisper on WER but covers only 13 languages on a heavier
runtime. For PT↔EN on this stack, `large-v3` is the right call.

## Troubleshooting

- **Nothing typed / "No speech detected"**: check the mic level —
  `ffmpeg -f pulse -i "$(pactl get-default-source)" -t 2 /tmp/t.wav && \
   ffmpeg -i /tmp/t.wav -af volumedetect -f null - 2>&1 | grep mean_volume`
  (digital silence reads ~−91 dB; a live mic is well above that). Pin a better mic above.
- **`libcublas.so.12 not found`**: the CUDA wheels aren't on `LD_LIBRARY_PATH`.
  `dictate.sh` sets it by globbing the venv's `nvidia/*/lib`; re-run `setup.sh` if the venv is incomplete.
- **Server logs**: `cat /run/user/$UID/dictate/server.log`.
- **Stuck recording**: `rm /run/user/$UID/dictate/rec.pid` and tap the key once.
- **Model reload after edits**: `pkill -f dictation/server.py` — it lazy-restarts on the next dictation.
