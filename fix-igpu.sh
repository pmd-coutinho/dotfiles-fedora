#!/usr/bin/env bash
# Kernel 7.0 moved Raptor Lake-S graphics (8086:a788) from i915 to the xe
# driver, but xe only binds it behind force_probe. Without this the iGPU
# (laptop panel + Huawei) has no driver at all.
# Run as: sudo bash ~/dotfiles/fix-igpu.sh   — then reboot.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

ARG="xe.force_probe=a788"

echo "==> Adding $ARG to existing boot entries"
grubby --update-kernel=ALL --args="$ARG"

echo "==> Persisting for future kernels"
grep -q "$ARG" /etc/default/grub || \
    sed -i "s/^\(GRUB_CMDLINE_LINUX=\"[^\"]*\)\"/\1 $ARG\"/" /etc/default/grub
if [ -f /etc/kernel/cmdline ] && ! grep -q "$ARG" /etc/kernel/cmdline; then
    sed -i "s/\$/ $ARG/" /etc/kernel/cmdline
fi

echo "==> Result:"
grubby --info=DEFAULT | grep args
echo
echo "Done — reboot to bring the iGPU (laptop panel + Huawei) back."
