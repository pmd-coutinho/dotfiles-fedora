#!/usr/bin/env bash
# ============================================================================
# Round 6 — workflow tooling: git+delta, .NET tools, Azure CLI, modern CLI,
# neovim (LazyVim) IDE. Run as: sudo bash ~/dotfiles/setup-round6.sh
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
DOTS="$UHOME/dotfiles"

# ── Packages (Fedora repos) ───────────────────────────────────────────────
step "Installing dnf packages (delta, tealdeer, duf, procs, difftastic, just, neovim, azure-cli)"
dnf -y install git-delta tealdeer duf procs difftastic just neovim azure-cli \
  || warn "one or more dnf packages failed — check names/repos"

# ── Modern CLI binaries not packaged: dust, xh, watchexec → ~/.local/bin ──
# Version-PINNED with sha256 verification (fail-closed: a mismatch skips the
# install rather than running an unverified binary). To upgrade: bump the URL
# and recompute the hash with `curl -fsSL <url> | sha256sum`.
step "Fetching prebuilt binaries (dust, xh, watchexec) into ~/.local/bin (sha256-verified)"
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
fetch_bin dust \
  "https://github.com/bootandy/dust/releases/download/v1.2.4/dust-v1.2.4-x86_64-unknown-linux-gnu.tar.gz" \
  "707cfdbfb9d2dc536f8c3853815bbe98a01012f2772463835edae06816551160"
fetch_bin xh \
  "https://github.com/ducaale/xh/releases/download/v0.25.3/xh-v0.25.3-x86_64-unknown-linux-musl.tar.gz" \
  "fc738e616b327e7a10256e206c78073bfeed95d73af6ba9ced4c5eb20ac8d717"
fetch_bin watchexec \
  "https://github.com/watchexec/watchexec/releases/download/v2.5.1/watchexec-2.5.1-x86_64-unknown-linux-gnu.tar.xz" \
  "cafc381f74e95f8e93e796ef590c7cbbf3409dda6d56cf3dee6109c10e5188ee"

# ── tealdeer cache ────────────────────────────────────────────────────────
step "Seeding tldr cache"
asuser tldr --update || warn "tldr --update failed (network?)"

# ── .NET: global tools + node for nvim extras (via mise) ──────────────────
step ".NET global tools (dotnet-ef) + node@lts (mise)"
MISE="$UHOME/.local/bin/mise"
[ -x "$MISE" ] || MISE="$(command -v mise || true)"
if [ -n "$MISE" ]; then
  asuser "$MISE" use -g node@lts || warn "mise node install failed"
  asuser "$MISE" exec -- dotnet tool install --global dotnet-ef 2>&1 | tail -2 \
    || asuser "$MISE" exec -- dotnet tool update --global dotnet-ef 2>&1 | tail -2 \
    || warn "dotnet-ef install failed"
else warn "mise not found — skipping dotnet-ef + node"; fi

# ── Git: import old ~/.gitconfig identity is already in the git/ package; ──
#    back up any real ~/.gitconfig and stow the managed one.
#    (bootstrap.sh already stows git/nvim — under bootstrap this is a no-op,
#    kept so the script works standalone and resolves .gitconfig conflicts.)
step "Stowing git + nvim packages"
if [ -f "$UHOME/.gitconfig" ] && [ ! -L "$UHOME/.gitconfig" ]; then
  asuser cp "$UHOME/.gitconfig" "$UHOME/.gitconfig.pre-round6"
  rm -f "$UHOME/.gitconfig"
  ok "  backed up old ~/.gitconfig -> ~/.gitconfig.pre-round6"
fi
asuser bash -c "cd '$DOTS' && stow git nvim" || warn "stow git/nvim had conflicts — resolve and re-run"

# ── Failing autostart unit (escaped name — the unescaped form never matched) ─
step "Masking the failing nvidia-settings autostart user unit"
asuser systemctl --user mask 'app-nvidia\x2dsettings\x2duser@autostart.service' 2>/dev/null || true
asuser systemctl --user reset-failed 'app-nvidia\x2dsettings\x2duser@autostart.service' 2>/dev/null || true

# ── neovim: install plugins + mason tools headlessly ──────────────────────
step "Bootstrapping LazyVim (plugin + LSP install) — first run can take a minute"
asuser nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Lazy sync needs finishing — just open nvim once"

echo
ok "Round 6 done."
echo "  Next (interactive, as you):"
echo "    • az login                 # Azure CLI sign-in (also enables devtunnel auth)"
echo "    • open a new shell         # picks up PATH (~/.dotnet/tools), EDITOR=nvim, aliases"
echo "    • nvim a .cs file          # confirm the Roslyn LSP attaches (the one fiddly bit)"
