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
# Resolve the latest GitHub release asset for linux x86_64 (prefer musl), same
# pattern as the AyuGram fetch in setup-round3.sh. Pinned-by-latest; re-running
# upgrades them.
step "Fetching prebuilt binaries (dust, xh, watchexec) into ~/.local/bin"
asuser mkdir -p "$UHOME/.local/bin"
fetch_bin() {  # $1=repo  $2=binary-name  $3=asset-grep
  local repo="$1" bin="$2" pat="$3" url tmp
  url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
    | python3 -c "import json,sys,re
pat=re.compile(r'''$pat''')
for a in json.load(sys.stdin)['assets']:
    if pat.search(a['name']): print(a['browser_download_url']); break")
  if [ -z "$url" ]; then warn "$bin: no matching asset found"; return; fi
  tmp=$(mktemp -d)
  curl -fsSL "$url" -o "$tmp/a"
  case "$url" in
    *.tar.gz|*.tgz) tar -xzf "$tmp/a" -C "$tmp" ;;
    *.tar.xz)       tar -xJf "$tmp/a" -C "$tmp" ;;
    *.zip)          (cd "$tmp" && unzip -q a) ;;
  esac
  local found; found=$(find "$tmp" -type f -name "$bin" | head -1)
  if [ -n "$found" ]; then
    install -m755 "$found" "$UHOME/.local/bin/$bin"; chown "$RUSER:$RUSER" "$UHOME/.local/bin/$bin"
    ok "  installed $bin"
  else warn "$bin: binary not found in archive"; fi
  rm -rf "$tmp"
}
fetch_bin "bootandy/dust"        "dust"      "x86_64-unknown-linux-(musl|gnu)\.tar\.gz"
fetch_bin "ducaale/xh"           "xh"        "x86_64-unknown-linux-musl\.tar\.gz"
fetch_bin "watchexec/watchexec"  "watchexec" "x86_64-unknown-linux-(musl|gnu)\.tar\.xz"

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
