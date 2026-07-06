#!/usr/bin/env bash
# ============================================================================
# Round 7 — CLI gap-fillers: sd (sed), hyperfine (benchmarks), uv (python),
# glow (markdown), yq (yaml/json). Run as: sudo bash ~/dotfiles/setup-round7.sh
# (sudo needed for dnf; user-level bits run via `asuser`). Idempotent.
# ============================================================================
set -uo pipefail
step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }
ok()   { echo -e "\033[1;32m$*\033[0m"; }
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
RUSER="${SUDO_USER:-$(logname 2>/dev/null)}"
RUID="$(id -u "$RUSER")"
UHOME="$(getent passwd "$RUSER" | cut -d: -f6)"
asuser() { sudo -u "$RUSER" env XDG_RUNTIME_DIR="/run/user/$RUID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$RUID/bus" HOME="$UHOME" "$@"; }

# ── Packages (Fedora repos) ───────────────────────────────────────────────
# Fedora's `yq` IS mikefarah's Go yq (github.com/mikefarah/yq), not the old
# python jq-wrapper — safe to take from dnf.
step "Installing dnf packages (hyperfine, uv, glow, yq)"
dnf -y install hyperfine uv glow yq \
  || warn "one or more dnf packages failed — check names/repos"

# ── sd: not packaged in Fedora → pinned prebuilt binary → ~/.local/bin ────
# Version-PINNED with sha256 verification (fail-closed), same pattern as
# setup-round6.sh. To upgrade: bump the URL and recompute the hash with
# `curl -fsSL <url> | sha256sum`.
step "Fetching sd into ~/.local/bin (sha256-verified)"
asuser mkdir -p "$UHOME/.local/bin"
fetch_bin() {  # $1=binary-name  $2=url  $3=sha256
  local bin="$1" url="$2" sum="$3" tmp
  tmp=$(mktemp -d)
  if ! curl -fsSL "$url" -o "$tmp/a"; then warn "$bin: download failed"; rm -rf "$tmp"; return; fi
  if ! echo "$sum  $tmp/a" | sha256sum -c --status; then
    warn "$bin: SHA256 MISMATCH — refusing to install (expected $sum)"; rm -rf "$tmp"; return
  fi
  case "$url" in
    *.tar.gz|*.tgz) tar -xzf "$tmp/a" -C "$tmp" ;;
    *.tar.xz)       tar -xJf "$tmp/a" -C "$tmp" ;;
    *.zip)          (cd "$tmp" && unzip -q a) ;;
  esac
  local found; found=$(find "$tmp" -type f -name "$bin" | head -1)
  if [ -n "$found" ]; then
    install -m755 "$found" "$UHOME/.local/bin/$bin"; chown "$RUSER:$RUSER" "$UHOME/.local/bin/$bin"
    ok "  installed $bin (verified)"
  else warn "$bin: binary not found in archive"; fi
  rm -rf "$tmp"
}
fetch_bin sd \
  "https://github.com/chmln/sd/releases/download/v1.0.0/sd-v1.0.0-x86_64-unknown-linux-musl.tar.gz" \
  "9f42e4fec7848fa8d6eeab7b1090f5c9c9e374c94a9974db6ff33df052c9e132"

echo
ok "Round 7 done."
echo "  Try:  sd 'foo' 'bar' file.txt   |  hyperfine 'cmd A' 'cmd B'"
echo "        uvx ruff check .          |  glow README.md  |  yq '.a.b' f.yaml"
