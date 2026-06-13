#!/usr/bin/env bash
# Install walker + elephant (launcher) and bring up bluetooth.
# Run as: sudo bash ~/dotfiles/setup-walker-bt.sh
set -uo pipefail
step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

# ── Walker (Wayland launcher) + Elephant backend ─────────────────────
step "Enabling walker COPR (errornointernet/walker)"
dnf -y copr enable errornointernet/walker

step "Installing walker + elephant"
dnf -y install walker elephant || { warn "walker/elephant install failed"; exit 1; }

# ── Bluetooth ────────────────────────────────────────────────────────
# The Intel BE200 controller needs bluetooth.service running; it was
# enabled but dead, so waybar reported "no controller found".
step "Enabling + starting bluetooth.service"
systemctl enable --now bluetooth.service
sleep 2
if bluetoothctl list 2>/dev/null | grep -q Controller; then
    echo "Controller detected:"
    bluetoothctl list
else
    warn "Still no controller — check 'journalctl -u bluetooth -b' (may need firmware/reboot)"
fi

echo
echo -e "\033[1;32mDone. Tell Claude — it'll enable the elephant user service, stow walker, and restart the bars.\033[0m"
