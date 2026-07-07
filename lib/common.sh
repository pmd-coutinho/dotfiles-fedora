# shellcheck shell=bash
# Shared helpers for the setup scripts — source after `set -uo pipefail`:
#     . "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
# Every script gets step/warn/ok; when running as root (the setup-round*
# scripts) it also gets RUSER/RUID/UHOME + asuser + fetch_bin.

step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }
ok()   { echo -e "\033[1;32m$*\033[0m"; }

if [ "$(id -u)" -eq 0 ]; then
    RUSER="${SUDO_USER:-$(logname 2>/dev/null)}"
    RUID="$(id -u "$RUSER")"
    UHOME="$(getent passwd "$RUSER" | cut -d: -f6)"

    # Run a command as the invoking user with a sane session env. HOME matters:
    # without it, flatpak/dotnet/uv user-level installs land under root's home.
    asuser() { sudo -u "$RUSER" env XDG_RUNTIME_DIR="/run/user/$RUID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$RUID/bus" HOME="$UHOME" "$@"; }

    # fetch_bin <name> <url> <sha256> — version-PINNED, fail-closed download of
    # a prebuilt release binary into ~/.local/bin (a mismatch skips the install
    # rather than running an unverified binary). To upgrade: bump the URL and
    # recompute the hash with `curl -fsSL <url> | sha256sum`.
    fetch_bin() {
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
fi
