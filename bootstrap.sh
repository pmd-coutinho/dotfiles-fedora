#!/usr/bin/env bash
# ============================================================================
# bootstrap.sh — rebuild Pedro's Fedora 44 + niri Catppuccin-Mocha desktop
# from a fresh install. Idempotent; safe to re-run. Run as your user:
#     bash ~/dotfiles/bootstrap.sh
# It will sudo where needed. See README.md for the full story.
#
# Assumes: Fedora 44, this repo cloned to ~/dotfiles, Secure Boot OFF
# (NVIDIA + CachyOS kmods are unsigned), an internet connection.
# ============================================================================
set -uo pipefail
DOTS="$HOME/dotfiles"
step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }
ok()   { echo -e "\033[1;32m$*\033[0m"; }

# ── 0. RPMFusion + COPRs ─────────────────────────────────────────────────
step "Enabling RPMFusion (free + nonfree) and COPRs"
sudo dnf -y install \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" || true
for c in scottames/ghostty atim/starship solopasha/hyprland \
         errornointernet/walker errornointernet/packages errornointernet/quickshell \
         bieszczaders/kernel-cachyos \
         ifas/zellij; do   # ifas tracks latest (0.44.3); varlad's COPR stalled at 0.42.2
    sudo dnf -y copr enable "$c"
done

# ── 1. Packages ──────────────────────────────────────────────────────────
step "Installing packages (dnf)"
sudo dnf -y install \
  niri quickshell xwayland-satellite \
  akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power \
  ghostty alacritty \
  zsh zsh-autosuggestions zsh-syntax-highlighting fzf fd-find \
  bat ripgrep eza btop ShellCheck gettext unzip \
  yazi jujutsu \
  starship atuin zoxide stow zellij mosh \
  swaybg swayidle hyprlock wlsunset \
  walker elephant elephant-calc elephant-files elephant-clipboard \
  elephant-symbols elephant-unicode elephant-websearch elephant-runner \
  elephant-desktopapplications elephant-menus elephant-nirisessions \
  elephant-providerlist elephant-bluetooth elephant-bookmarks \
  elephant-snippets elephant-todo elephant-windows elephant-1password \
  keepassxc rclone \
  satty grim slurp wl-clipboard cliphist wlogout \
  papirus-icon-theme adw-gtk3-theme jetbrains-mono-fonts \
  brightnessctl playerctl pavucontrol pulseaudio-utils network-manager-applet blueman solaar \
  cups printer-driver-brlaser \
  wtype ffmpeg \
  mate-polkit gnome-keyring tuned tuned-ppd \
  greetd tuigreet \
  kernel-cachyos kernel-cachyos-devel-matched
# NOTE: install the GCC kernel-cachyos, NOT kernel-cachyos-lto (breaks akmods).

# ── 2. Manual fetches (fonts, zsh plugins, wallpaper) ────────────────────
step "Nerd fonts (CaskaydiaCove + JetBrainsMono)"
mkdir -p ~/.local/share/fonts
for f in CascadiaCode JetBrainsMono; do
    d=~/.local/share/fonts/${f}Nerd
    if [ ! -d "$d" ]; then
        mkdir -p "$d"
        curl -fsSL -o /tmp/$f.tar.xz \
          "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$f.tar.xz" \
          && tar -xJf /tmp/$f.tar.xz -C "$d"
    fi
done
fc-cache -f >/dev/null

step "zsh fzf-tab + zsh-abbr"
mkdir -p ~/.local/share/zsh
[ -d ~/.local/share/zsh/fzf-tab ] || git clone -q --depth 1 https://github.com/Aloxaf/fzf-tab ~/.local/share/zsh/fzf-tab
# zsh-abbr needs its zsh-job-queue submodule
[ -d ~/.local/share/zsh/zsh-abbr ] || git clone -q --depth 1 --recurse-submodules https://github.com/olets/zsh-abbr ~/.local/share/zsh/zsh-abbr

# gh CLI extensions (gh-dash PR/issue dashboard)
if command -v gh >/dev/null; then
    gh extension list 2>/dev/null | grep -q gh-dash || gh extension install dlvhdr/gh-dash || true
fi

# jjui (jj TUI) — no Fedora-44 COPR, so install the prebuilt release binary
if ! command -v jjui >/dev/null; then
    JJUI_VER=0.10.6
    jtmp=$(mktemp -d)
    if curl -sL -o "$jtmp/jjui.zip" "https://github.com/idursun/jjui/releases/download/v${JJUI_VER}/jjui-${JJUI_VER}-linux-amd64.zip" \
        && unzip -oq "$jtmp/jjui.zip" -d "$jtmp"; then
        install -m755 "$jtmp"/jjui-*-linux-amd64 ~/.local/bin/jjui
    fi
    rm -rf "$jtmp"
fi

step "Wallpaper"
mkdir -p ~/Pictures/wallpapers ~/Pictures/Screenshots
[ -f ~/Pictures/wallpapers/cat-waves.png ] || curl -fsSL -o ~/Pictures/wallpapers/cat-waves.png \
  "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/main/waves/cat-waves.png" || true

# ── 3. Dotfiles via stow ─────────────────────────────────────────────────
step "Rendering theme templates from the Catppuccin palette"
bash "$DOTS/palette/render.sh"

step "Stowing dotfiles"
cd "$DOTS"
# back up any real files stow would collide with
# NOTE: no 'vscode' here — VS Code settings.json is seeded from a template by
# setup-editors.sh (the live file holds machine state and must not be tracked).
for pkg in alacritty atuin autostart bin btop dictation environment gh-dash ghostty git gtk hyprlock \
           jj lazygit niri nvim quickshell satty starship systemd walker yazi zellij zsh; do
    stow -v "$pkg" 2>&1 | grep -i conflict && warn "conflict in $pkg — resolve then re-run 'stow $pkg'"
done

# Tracked git hooks: pre-commit validates shell/zsh/zellij configs before commit
git -C "$DOTS" config core.hooksPath hooks

step "yazi Catppuccin flavor + jj colocated sandbox"
# flavor lands in ~/.config/yazi/flavors (gitignored); ya pkg (new) / ya pack (old)
command -v ya >/dev/null && { ya pkg install 2>/dev/null \
    || ya pkg add yazi-rs/flavors:catppuccin-mocha 2>/dev/null || true; }
# colocate jj in the dotfiles repo so you can trial jj without affecting git
command -v jj >/dev/null && [ ! -d "$DOTS/.jj" ] && ( cd "$DOTS" && jj git init --colocate ) || true

step "Network printer (Brother DCP-1612W / DCP-1610W series via brlaser)"
# Host-based printer (no standard PDL) → brlaser renders on the host. Uses the
# stable mDNS hostname (DHCP-proof). Only added if missing. Adjust the hostname
# if you re-point to a different printer.
if command -v lpadmin >/dev/null && ! lpstat -p Brother_DCP1612W >/dev/null 2>&1; then
    ppd=$(lpinfo -m 2>/dev/null | awk 'tolower($0) ~ /brlaser/ && /1610/ {print $1; exit}')
    if [ -n "$ppd" ]; then
        # raw socket (port 9100), NOT ipp:// — the printer's IPP service rejects
        # the raw brlaser stream and auto-disables the queue. error-policy
        # retry-job so a transient failure doesn't disable the whole printer.
        sudo lpadmin -p Brother_DCP1612W -v socket://BRNFC017C866FB3.local:9100 -m "$ppd" \
            -D "Brother DCP-1612W" -L Network -E -o printer-error-policy=retry-job \
            && sudo cupsaccept Brother_DCP1612W && sudo cupsenable Brother_DCP1612W \
            && sudo lpadmin -d Brother_DCP1612W && ok "  added Brother_DCP1612W"
    else
        warn "brlaser PPD not found (printer-driver-brlaser installed?)"
    fi
fi

# ── 4. GTK / appearance ──────────────────────────────────────────────────
step "GTK + appearance gsettings"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'

# ── 5. mise tools ────────────────────────────────────────────────────────
step "mise tools (claude / opencode / codex)"
command -v mise >/dev/null || curl -fsSL https://mise.run | sh
~/.local/bin/mise install 2>/dev/null || mise install 2>/dev/null || true

# ── 5b. Voice dictation (faster-whisper venv) ────────────────────────────
step "Voice dictation venv (faster-whisper + CUDA wheels)"
# Builds ~/.local/share/dictation/venv. The large-v3 model (~3GB) downloads
# lazily on first dictation, not here. See docs/DICTATION.md.
bash ~/.local/share/dictation/setup.sh || warn "run ~/.local/share/dictation/setup.sh manually later"

# ── 6. Services ──────────────────────────────────────────────────────────
step "Enabling services"
sudo systemctl enable --now tuned bluetooth nvidia-powerd 2>/dev/null || true
systemctl --user enable --now elephant 2>/dev/null || true
elephant service enable 2>/dev/null || true
# auto-rescan elephant when apps are installed/removed (so walker sees them)
systemctl --user enable --now elephant-rescan.path 2>/dev/null || true
# mask the nvidia-settings autostart that fails under niri.
systemctl --user mask 'app-nvidia\x2dsettings\x2duser@autostart.service' 2>/dev/null || true
systemctl --user enable --now niri-vivaldi-private-watch.service 2>/dev/null || true
# desktop authorization prompts under niri (the package's XDG autostart is MATE-only)
systemctl --user enable --now polkit-mate-agent.service 2>/dev/null || true
# ssh-agent socket at $XDG_RUNTIME_DIR/ssh-agent.socket — KeePassXC loads keys
# into it; git commit signing and environment.d's SSH_AUTH_SOCK depend on it
systemctl --user enable --now ssh-agent.service 2>/dev/null || true
# vault sync (rclone) — only once ~/vault exists (set up manually, see SECURITY.md)
if [ -d ~/vault ]; then
    systemctl --user enable --now rclone-vault-sync.timer rclone-vault-sync.path 2>/dev/null || true
fi

# ── 7. System setup (swap/zswap, kernel, greetd, power) ──────────────────
step "Root system setup (swap/zswap, power, greetd, CachyOS kernel + nvidia)"
echo "Running setup-root.sh (NVIDIA profile, greetd PAM/keyring, base services)..."
sudo bash "$DOTS/setup-root.sh"          # NVIDIA app-profile, greetd, gdm->greetd
echo "Running setup-round2.sh (swap+zswap, power udev, tuigreet, CachyOS kernel)..."
sudo bash "$DOTS/setup-round2.sh"        # 32G zswap swapfile, power switch, kernel

# Intel iGPU on kernel 7.0+ needs xe.force_probe (see README/known-issues)
if ! grep -q 'xe.force_probe' /etc/kernel/cmdline 2>/dev/null; then
    step "Applying Intel iGPU fix (xe.force_probe)"
    sudo bash "$DOTS/fix-igpu.sh"
fi

# ── 8. Applications (Round 3): repos, flatpaks, COPR CLI tools ───────────
step "Apps + CLI tools (VS Code, Vivaldi, OpenVPN3, Slack/Obsidian/Telegram, lazygit/lazydocker)"
sudo bash "$DOTS/setup-round3.sh"

step "atuin: import existing shell history"
atuin import auto 2>/dev/null || true

step "JetBrains Toolbox (then open it and install Rider)"
bash "$DOTS/install-toolbox.sh" || warn "run install-toolbox.sh manually later"

step "Editor theming (VS Code + Rider Catppuccin, VS Code keyring fix)"
bash "$DOTS/setup-editors.sh" || warn "run setup-editors.sh manually later"

step "Workflow tooling (git+delta, .NET tools, Azure CLI, modern CLI, neovim/LazyVim)"
sudo bash "$DOTS/setup-round6.sh" || warn "run setup-round6.sh manually later"

step "CLI gap-fillers (sd, hyperfine, uv, glow, yq)"
sudo bash "$DOTS/setup-round7.sh" || warn "run setup-round7.sh manually later"

step "Dev/ops TUIs + helpers (hurl, mergiraf, lnav, gum, posting, isd, csharprepl…)"
sudo bash "$DOTS/setup-round8.sh" || warn "run setup-round8.sh manually later"

echo "  .NET SDK: run 'mise use -g dotnet@9' (or the version your solutions target)."
echo "  Note: GUI-launched Rider won't inherit mise PATH — set its SDK path or DOTNET_ROOT."

# ── 9. OS hardening (Round 4): nvidia suspend, journald, inotify, snapshots
step "OS hardening (NVIDIA suspend VRAM, journald cap, inotify, snapper)"
sudo bash "$DOTS/setup-round4.sh"

echo
ok "Bootstrap complete. REBOOT to land on the CachyOS kernel + greetd + zswap."
echo "After reboot, verify with the checklist in README.md."
