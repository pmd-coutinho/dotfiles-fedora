#!/usr/bin/env bash
# The running kernel 7.0.12 was installed without its kernel-modules
# package (only kernel-core came in during the nvidia transaction), so
# bluetooth (btusb/btintel) and ~2500 other drivers are missing.
# This installs the matching modules in place — no new kernel, nvidia
# kmod stays valid.  Run as: sudo bash ~/dotfiles/fix-kernel-modules.sh
set -uo pipefail
step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

KV="$(uname -r)"        # e.g. 7.0.12-201.fc44.x86_64
VR="${KV%.*}"           # strip .x86_64 -> 7.0.12-201.fc44
step "Installing kernel-modules for running kernel $KV"
dnf -y install "kernel-modules-${VR}" "kernel-modules-extra-${VR}" \
    || { warn "exact-version install failed — try: sudo dnf install kernel (pulls a full matched kernel)"; exit 1; }

step "Refreshing module dependencies"
depmod -a "$KV"

step "Loading bluetooth now (no reboot needed if modules are in place)"
modprobe btusb 2>/dev/null && echo "btusb loaded" || warn "btusb load failed — a reboot will pick it up"

step "Enabling + starting bluetooth.service"
systemctl enable bluetooth.service
# Only start if the controller actually appeared, so this never hangs.
if [ -d /sys/class/bluetooth ]; then
    systemctl start bluetooth.service
    sleep 1
    bluetoothctl list 2>/dev/null | grep Controller && echo "bluetooth is up" \
        || warn "service started but no controller yet — reboot to be safe"
else
    warn "/sys/class/bluetooth still absent — reboot to load the new modules"
fi

echo
echo -e "\033[1;32mDone. If bluetooth didn't come up live, just reboot — the modules are installed now.\033[0m"
