#!/usr/bin/env bash
# ============================================================================
# Round 7 — CLI gap-fillers: sd (sed), hyperfine (benchmarks), uv (python),
# glow (markdown), yq (yaml/json). Run as: sudo bash ~/dotfiles/setup-round7.sh
# (sudo needed for dnf; user-level bits run via `asuser`). Idempotent.
# ============================================================================
set -uo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── Packages (Fedora repos) ───────────────────────────────────────────────
# Fedora's `yq` IS mikefarah's Go yq (github.com/mikefarah/yq), not the old
# python jq-wrapper — safe to take from dnf.
step "Installing dnf packages (hyperfine, uv, glow, yq)"
dnf -y install hyperfine uv glow yq \
  || warn "one or more dnf packages failed — check names/repos"

# ── sd: not packaged in Fedora → pinned prebuilt binary → ~/.local/bin ────
# fetch_bin (lib/common.sh) is version-pinned + sha256-verified, fail-closed.
step "Fetching sd into ~/.local/bin (sha256-verified)"
asuser mkdir -p "$UHOME/.local/bin"
fetch_bin sd \
  "https://github.com/chmln/sd/releases/download/v1.0.0/sd-v1.0.0-x86_64-unknown-linux-musl.tar.gz" \
  "9f42e4fec7848fa8d6eeab7b1090f5c9c9e374c94a9974db6ff33df052c9e132"

echo
ok "Round 7 done."
echo "  Try:  sd 'foo' 'bar' file.txt   |  hyperfine 'cmd A' 'cmd B'"
echo "        uvx ruff check .          |  glow README.md  |  yq '.a.b' f.yaml"
