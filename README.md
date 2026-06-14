# Pedro's Fedora + niri desktop

Catppuccin-Mocha niri (Wayland) desktop for an **MSI Vector 16 HX A14VHG**
(Intel Raptor Lake iGPU + NVIDIA RTX 4080 laptop), Fedora 44.

Configs are managed with **GNU stow** (one dir per app). System-level setup
lives in the scripts below.

## Rebuild from a fresh Fedora 44 install

Prereqs: **Secure Boot OFF** (the NVIDIA + CachyOS kernel modules are
unsigned), an internet connection, and `git`/`stow` (`sudo dnf install -y git stow`).

```bash
git clone <your-remote> ~/dotfiles      # TODO: set up the remote (see below)
bash ~/dotfiles/bootstrap.sh            # does everything, sudos where needed
reboot                                  # lands on CachyOS kernel + greetd + zswap
```

`bootstrap.sh` is idempotent and orchestrates the whole build:
COPRs/RPMFusion → packages → fonts/TPM/fzf-tab/wallpaper → `stow` → gsettings →
mise → services → then calls the system scripts (`setup-root.sh`,
`setup-round2.sh`, `fix-igpu.sh`) for the `/etc`, swap, power, and kernel bits.
The redundant `dnf` lines across scripts are intentional and harmless (no-ops
on re-run).

## What's here

| Path | Purpose |
|---|---|
| `bootstrap.sh` | **Start here.** Full ordered rebuild. |
| `setup-root.sh` | NVIDIA app-profile (VRAM-leak fix), greetd + keyring PAM, gdm→greetd, base services. |
| `setup-round2.sh` | 32G btrfs swapfile + zswap, power auto-switch udev rule, tuigreet polish, CachyOS kernel + NVIDIA akmod rebuild. |
| `fix-igpu.sh` | `xe.force_probe=a788` — kernel 7.0+ dropped i915 for this Raptor Lake iGPU; without it the laptop panel + Huawei go dark. |
| `archive/` | Superseded one-offs (kernel-modules half-install fix, old walker/bt script) kept for history; **not** run by bootstrap. |
| `*/` | stow packages: niri, waybar, walker, ghostty, zsh, tmux, hyprlock, satty, swaync, fuzzel, starship, atuin, gtk, alacritty. |

## The stack

- **Compositor**: niri, rendering on the **NVIDIA dGPU** (`debug { render-drm-device }` by-path). 3 monitors: Huawei top-left, laptop below it, Gigabyte (4K@144 via DSC) right.
- **Bars/UI**: waybar (one full bar per output), SwayNC notifications, walker launcher (+ elephant backend), hyprlock + swayidle (lock 10m / screens-off 15m).
- **Login**: greetd + tuigreet (GDM kept installed as rescue).
- **Terminal/shell**: Ghostty (CaskaydiaCove Nerd Font) · zsh (autosuggestions, syntax-highlighting, fzf-tab) + starship + atuin + zoxide + mise · tmux (TPM + catppuccin).
- **Kernel**: CachyOS (BORE scheduler) via `bieszczaders/kernel-cachyos`; stock Fedora kernel is the GRUB fallback.
- **Swap**: 32G btrfs swapfile + **zswap** (zstd/zsmalloc) — zram disabled. For large .NET builds.
- **Power**: tuned + tuned-ppd; udev auto-switch AC→performance / battery→balanced; waybar toggle via the `net.hadess.PowerProfiles` D-Bus interface (there is **no** `powerprofilesctl` — that ships with the conflicting power-profiles-daemon).
- **Screenshots**: `Print` → grim+satty annotate; native niri grabs on Mod/Alt/Ctrl+Print.

## Post-reboot verification

```bash
uname -r                                              # *cachyos*
sysctl kernel.sched_bore                              # = 1
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
cat /sys/module/zswap/parameters/enabled              # Y
swapon --show                                         # /swap/swapfile 32G, no zram
busctl --system get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles \
  net.hadess.PowerProfiles ActiveProfile              # "performance" on AC
niri msg outputs                                      # 3 monitors, Gigabyte 4K@144
```
Interactive: `Print`→satty, `Mod+E`/`Mod+Slash` walker pickers, tuigreet + F12 power menu, unplug AC → waybar power icon flips.

## Known gotchas (learned the hard way)

- **Secure Boot must stay off** — unsigned NVIDIA/CachyOS kmods won't load otherwise.
- **iGPU on kernel 7.0+**: needs `xe.force_probe=a788` (`fix-igpu.sh`) or the Intel-driven outputs go dark.
- **`kernel-cachyos`, not `-lto`** — the LTO/Clang build breaks GCC akmods (NVIDIA won't build).
- **CachyOS kernel updates** re-trigger the NVIDIA akmod build; wait for it (`modinfo -F version nvidia -k <kver>`) before rebooting, or boot the Fedora kernel.
- **Monitors are matched by make/model/serial** in niri (connector names like DP-3 shuffle when the NVIDIA driver loads). The Huawei's EDID serial is literally 13 spaces — keep them in the config string.
- **Walker file search needs `fd`** (`fd-find`); the emoji/symbol & calc providers are separate `elephant-*` packages.

## TODO

- [ ] **Push to a git remote** (off-machine backup — currently local-only):
  `git remote add origin <url> && git push -u origin main`
