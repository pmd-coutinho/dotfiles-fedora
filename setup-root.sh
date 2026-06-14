#!/usr/bin/env bash
# Root-level setup for the niri desktop build-out.
# Run as: sudo bash ~/dotfiles/setup-root.sh
# Idempotent — safe to re-run if a step fails.
set -uo pipefail

step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }

[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

# ── 1. COPRs ──────────────────────────────────────────────────────────
step "Enabling COPRs (ghostty, starship, hyprlock)"
dnf -y copr enable scottames/ghostty
dnf -y copr enable atim/starship
dnf -y copr enable solopasha/hyprland || warn "solopasha/hyprland COPR failed to enable — hyprlock will be skipped"

# ── 2. Main package transaction ───────────────────────────────────────
step "Installing packages"
dnf -y install \
    akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power \
    atuin zoxide SwayNotificationCenter swaybg swayidle \
    fzf zsh-autosuggestions zsh-syntax-highlighting \
    stow papirus-icon-theme adw-gtk3-theme cliphist \
    brightnessctl pavucontrol network-manager-applet blueman \
    mate-polkit gnome-keyring grim slurp wlogout \
    jetbrains-mono-fonts greetd tuigreet \
    ghostty starship \
    || { warn "main dnf transaction failed — fix and re-run"; exit 1; }

step "Installing hyprlock (best effort)"
dnf -y install hyprlock || warn "hyprlock not installable — swaylock remains the fallback (Super+Alt+L bind will need changing)"

# ── 3. NVIDIA: VRAM-leak application profile (from niri wiki) ────────
step "Writing NVIDIA application profile for niri"
mkdir -p /etc/nvidia/nvidia-application-profiles-rc.d
cat > /etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json <<'EOF'
{
    "rules": [
        {
            "pattern": {
                "feature": "procname",
                "matches": "niri"
            },
            "profile": "Limit Free Buffer Pool On Wayland Compositors"
        }
    ],
    "profiles": [
        {
            "name": "Limit Free Buffer Pool On Wayland Compositors",
            "settings": [
                {
                    "key": "GLVidHeapReuseRatio",
                    "value": 0
                }
            ]
        }
    ]
}
EOF

# ── 4. greetd + tuigreet ─────────────────────────────────────────────
step "Configuring greetd with tuigreet"
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-user-session --asterisks --sessions /usr/share/wayland-sessions --cmd niri-session --theme 'border=magenta;text=gray;prompt=lightmagenta;time=lightblue;action=gray;button=lightmagenta;container=black;input=white' --greeting 'welcome back, pedro'"
user = "greetd"
EOF

# tuigreet --remember needs its cache dir
mkdir -p /var/cache/tuigreet
chown greetd:greetd /var/cache/tuigreet 2>/dev/null || warn "greetd user missing? check greetd package"

# gnome-keyring auto-unlock at login (GDM did this implicitly)
if ! grep -q pam_gnome_keyring /etc/pam.d/greetd 2>/dev/null; then
    step "Adding gnome-keyring to greetd PAM"
    cat >> /etc/pam.d/greetd <<'EOF'
auth        optional    pam_gnome_keyring.so
session     optional    pam_gnome_keyring.so auto_start
EOF
else
    echo "pam_gnome_keyring already present in /etc/pam.d/greetd"
fi

# ── 5. Services ───────────────────────────────────────────────────────
step "Switching display manager: gdm -> greetd"
systemctl disable gdm
systemctl enable greetd

step "Enabling nvidia-powerd (dynamic boost)"
systemctl enable nvidia-powerd || warn "nvidia-powerd enable failed (service appears after driver install)"

# ── 6. Wait for the nvidia kmod build ─────────────────────────────────
step "Waiting for akmods to build the nvidia kernel module (can take a few minutes)"
for i in $(seq 1 60); do
    v=$(modinfo -F version nvidia 2>/dev/null) && { echo "nvidia kmod built: $v"; break; }
    sleep 10
    echo "  still building... (${i}0s)"
done
modinfo -F version nvidia >/dev/null 2>&1 || {
    warn "nvidia module not built yet — check 'journalctl -u akmods' before rebooting!"
    exit 1
}

echo
echo -e "\033[1;32mAll root setup done. Rescue note: if greetd fails at boot ->\033[0m"
echo "  Ctrl+Alt+F3, login, then: sudo systemctl disable greetd && sudo systemctl enable gdm && sudo reboot"
echo
echo "Next: tell Claude it's done (or just reboot if you're finishing up yourself)."
