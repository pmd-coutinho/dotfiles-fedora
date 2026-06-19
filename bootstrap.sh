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
         errornointernet/walker bieszczaders/kernel-cachyos varlad/zellij; do
    sudo dnf -y copr enable "$c"
done

# ── 1. Packages ──────────────────────────────────────────────────────────
step "Installing packages (dnf)"
sudo dnf -y install \
  niri waybar xwayland-satellite \
  akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power \
  ghostty alacritty \
  zsh zsh-autosuggestions zsh-syntax-highlighting fzf fd-find \
  bat ripgrep eza btop ShellCheck \
  starship atuin zoxide stow tmux zellij \
  SwayNotificationCenter swaybg swayidle hyprlock \
  walker elephant elephant-calc elephant-files elephant-clipboard \
  elephant-symbols elephant-unicode elephant-websearch elephant-runner \
  elephant-desktopapplications elephant-menus elephant-nirisessions \
  elephant-providerlist elephant-bluetooth elephant-bookmarks \
  elephant-snippets elephant-todo elephant-windows elephant-1password \
  satty grim slurp wl-clipboard cliphist wlogout \
  papirus-icon-theme adw-gtk3-theme jetbrains-mono-fonts \
  brightnessctl playerctl pavucontrol pulseaudio-utils network-manager-applet blueman solaar \
  wtype ffmpeg \
  mate-polkit gnome-keyring tuned tuned-ppd \
  greetd tuigreet \
  kernel-cachyos kernel-cachyos-devel-matched
# NOTE: install the GCC kernel-cachyos, NOT kernel-cachyos-lto (breaks akmods).

# ── 2. Manual fetches (fonts, tmux/zsh plugins, wallpaper) ───────────────
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

step "tmux TPM + zsh fzf-tab"
[ -d ~/.tmux/plugins/tpm ] || git clone -q --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
mkdir -p ~/.local/share/zsh
[ -d ~/.local/share/zsh/fzf-tab ] || git clone -q --depth 1 https://github.com/Aloxaf/fzf-tab ~/.local/share/zsh/fzf-tab
# zsh-abbr needs its zsh-job-queue submodule
[ -d ~/.local/share/zsh/zsh-abbr ] || git clone -q --depth 1 --recurse-submodules https://github.com/olets/zsh-abbr ~/.local/share/zsh/zsh-abbr

step "Wallpaper"
mkdir -p ~/Pictures/wallpapers ~/Pictures/Screenshots
[ -f ~/Pictures/wallpapers/cat-waves.png ] || curl -fsSL -o ~/Pictures/wallpapers/cat-waves.png \
  "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/main/waves/cat-waves.png" || true

# ── 3. Dotfiles via stow ─────────────────────────────────────────────────
step "Stowing dotfiles"
cd "$DOTS"
# back up any real files stow would collide with
# NOTE: no 'vscode' here — VS Code settings.json is seeded from a template by
# setup-editors.sh (the live file holds machine state and must not be tracked).
for pkg in alacritty atuin bin btop dictation fuzzel ghostty git gtk hyprlock lazygit niri nvim \
           satty starship swaync systemd tmux walker waybar zellij zsh; do
    stow -v "$pkg" 2>&1 | grep -i conflict && warn "conflict in $pkg — resolve then re-run 'stow $pkg'"
done

# Tracked git hooks: pre-commit validates shell/zsh/zellij configs before commit
git -C "$DOTS" config core.hooksPath hooks

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
# niri spawns swaync directly; disable the redundant (failing) systemd unit,
# and mask the nvidia-settings autostart that fails under niri.
systemctl --user disable --now swaync.service 2>/dev/null || true
systemctl --user mask 'app-nvidia\x2dsettings\x2duser@autostart.service' 2>/dev/null || true
systemctl --user enable --now niri-vivaldi-private-watch.service 2>/dev/null || true
# click a notification -> focus the app it came from
systemctl --user enable --now niri-notify-click.service 2>/dev/null || true
# tmux plugins (non-interactive)
~/.tmux/plugins/tpm/bin/install_plugins 2>/dev/null || true

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
step "Apps + CLI tools (VS Code, Vivaldi, OpenVPN3, Slack/Obsidian/AyuGram, lazygit/lazydocker)"
sudo bash "$DOTS/setup-round3.sh"

step "atuin: import existing shell history"
atuin import auto 2>/dev/null || true

step "JetBrains Toolbox (then open it and install Rider)"
bash "$DOTS/install-toolbox.sh" || warn "run install-toolbox.sh manually later"

step "Editor theming (VS Code + Rider Catppuccin, VS Code keyring fix)"
bash "$DOTS/setup-editors.sh" || warn "run setup-editors.sh manually later"

step "Workflow tooling (git+delta, .NET tools, Azure CLI, modern CLI, neovim/LazyVim)"
sudo bash "$DOTS/setup-round6.sh" || warn "run setup-round6.sh manually later"

echo "  .NET SDK: run 'mise use -g dotnet@9' (or the version your solutions target)."
echo "  Note: GUI-launched Rider won't inherit mise PATH — set its SDK path or DOTNET_ROOT."

# ── 9. OS hardening (Round 4): nvidia suspend, journald, inotify, snapshots
step "OS hardening (NVIDIA suspend VRAM, journald cap, inotify, snapper)"
sudo bash "$DOTS/setup-round4.sh"

echo
ok "Bootstrap complete. REBOOT to land on the CachyOS kernel + greetd + zswap."
echo "After reboot, verify with the checklist in README.md."
