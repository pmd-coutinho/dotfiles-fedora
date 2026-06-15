#!/usr/bin/env bash
# ============================================================================
# setup-editors.sh — Catppuccin Mocha theming for VS Code + Rider, plus the
# VS Code keyring fix for niri. Idempotent; run as your user (no sudo).
#     bash ~/dotfiles/setup-editors.sh
# ============================================================================
set -uo pipefail
step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }
ok()   { echo -e "\033[1;32m$*\033[0m"; }

# ── VS Code: Catppuccin theme + icons ────────────────────────────────────
if command -v code >/dev/null; then
    step "VS Code: Catppuccin extensions"
    code --install-extension Catppuccin.catppuccin-vsc \
         --install-extension Catppuccin.catppuccin-vsc-icons --force
    # settings.json is symlinked from the dotfiles 'vscode' package (stow vscode).

    # ── VS Code keyring fix ──────────────────────────────────────────────
    # niri sets XDG_CURRENT_DESKTOP=niri, which Electron can't map to a keyring
    # backend, so it can't find gnome-keyring (which IS running). Pin the
    # backend in argv.json. Comment-tolerant, only adds the key if missing.
    step "VS Code: pin keyring backend to gnome-libsecret"
    ARGV="$HOME/.vscode/argv.json"
    if [ -f "$ARGV" ] && ! grep -q 'password-store' "$ARGV"; then
        python3 - "$ARGV" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
i = s.rstrip().rfind('}')
head = s[:i].rstrip()
if not head.endswith(','):
    head += ','
open(p, 'w').write(head + '\n\t"password-store": "gnome-libsecret"\n}\n')
PY
        ok "  added password-store -> gnome-libsecret (restart VS Code)"
    else
        ok "  already set (or argv.json absent — launch VS Code once first)"
    fi
else
    warn "VS Code ('code') not installed — skipping (run setup-round3.sh)."
fi

# ── Rider: Catppuccin theme plugin ───────────────────────────────────────
# Headless installPlugins often can't reach the marketplace (repositories:
# [null]); the GUI install is reliable. Try headless, fall back to a note.
step "Rider: Catppuccin theme plugin"
RIDER_OK=0
for bin in "$HOME/.local/share/JetBrains/Toolbox/apps/rider/bin/rider" \
           "$HOME/.local/share/JetBrains/Toolbox/apps/rider-2/bin/rider"; do
    [ -x "$bin" ] || continue
    if "$bin" installPlugins com.github.catppuccin.jetbrains 2>&1 | grep -q "installed\|already"; then
        ok "  installed for $bin"; RIDER_OK=1
    fi
done
if [ "$RIDER_OK" -eq 0 ]; then
    warn "Install Catppuccin in Rider via the GUI (1 minute):"
    echo "  Settings -> Plugins -> Marketplace -> search 'Catppuccin' -> Install -> Restart"
    echo "  Then: Settings -> Appearance & Behavior -> Appearance -> Theme -> 'Catppuccin Mocha'"
    echo "  (accept the prompt to also switch the editor color scheme to match)"
fi

ok "Editors themed. Fully quit & reopen VS Code (and Rider) to apply."
