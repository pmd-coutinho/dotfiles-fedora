# Pedro's Fedora + niri desktop

Catppuccin-Mocha niri (Wayland) desktop for an **MSI Vector 16 HX A14VHG**
(Intel Raptor Lake iGPU + NVIDIA RTX 4080 laptop), Fedora 44.

Configs are managed with **GNU stow** (one dir per app). System-level setup
lives in the scripts below.

## Rebuild from a fresh Fedora 44 install

Prereqs: **Secure Boot OFF** (the NVIDIA + CachyOS kernel modules are
unsigned), an internet connection, and `git`/`stow` (`sudo dnf install -y git stow`).

```bash
git clone git@github.com:pmd-coutinho/dotfiles-fedora.git ~/dotfiles
bash ~/dotfiles/bootstrap.sh            # does everything, sudos where needed
reboot                                  # lands on CachyOS kernel + greetd + zswap
```

`bootstrap.sh` is idempotent and orchestrates the whole build:
COPRs/RPMFusion → packages → fonts/fzf-tab/wallpaper → `stow` → gsettings →
mise → dictation venv → services → then calls the system scripts (`setup-root.sh`,
`setup-round2.sh`, `fix-igpu.sh`) for the `/etc`, swap, power, and kernel bits.
The redundant `dnf` lines across scripts are intentional and harmless (no-ops
on re-run).

## What's here

| Path | Purpose |
|---|---|
| `bootstrap.sh` | **Start here.** Full ordered rebuild. |
| `setup-root.sh` | NVIDIA app-profile (VRAM-leak fix), greetd + keyring PAM, gdm→greetd, base services. |
| `setup-round2.sh` | 32G btrfs swapfile + zswap, power auto-switch udev rule, tuigreet polish, CachyOS kernel + NVIDIA akmod rebuild. |
| `setup-round3.sh` | Apps: VS Code (MS repo), Vivaldi, OpenVPN3, Slack (native rpm — Flatpak sandbox breaks notification action routing), Obsidian/AyuGram (Flatpak), lazygit/lazydocker (COPR), bat/ripgrep/eza/btop. |
| `install-toolbox.sh` | JetBrains Toolbox (user-level) → install Rider from its GUI. |
| `setup-round4.sh` | OS hardening: NVIDIA VRAM-preserve across suspend, journald 500M cap, inotify bump (Rider/VS Code/dotnet-watch), snapper + btrfs-assistant timeline snapshots (root only). |
| `fix-igpu.sh` | `xe.force_probe=a788` — kernel 7.0+ dropped i915 for this Raptor Lake iGPU; without it the laptop panel + Huawei go dark. |
| `setup-editors.sh` | Catppuccin for VS Code + Rider, VS Code keyring fix (niri), Rider native-Wayland toolkit. |
| `setup-round6.sh` | Workflow tooling: git+delta (Catppuccin) + aliases, dotnet-ef, Azure CLI, modern CLI (tldr/duf/procs/difftastic/just + dust/xh/watchexec binaries), neovim/LazyVim with C# (Roslyn) LSP. See [`docs/CLI-WORKFLOW.md`](docs/CLI-WORKFLOW.md) for how to use it all. |
| `archive/` | Superseded one-offs (kernel-modules half-install fix, old walker/bt script) kept for history; **not** run by bootstrap. |
| `docs/DICTATION.md` | **GPU voice dictation** (offline faster-whisper): `Mod+Shift+D` speak→English, `Mod+Alt+D` verbatim. Stow pkg `dictation` + `setup.sh` venv. |
| `*/` | stow packages: niri, waybar, walker, ghostty, git, nvim, zsh, hyprlock, satty, swaync, starship, atuin, gtk, lazygit, btop, bin, systemd, alacritty, dictation. (VS Code is **not** stowed — `setup-editors.sh` seeds `~/.config/Code/User/settings.json` from `vscode/.../settings.dist.json`; the live file is gitignored, see security note.) |

## The stack

- **Compositor**: niri, rendering on the **NVIDIA dGPU** (`debug { render-drm-device }` by-path). 3 monitors: Huawei top-left, laptop below it, Gigabyte (4K@144 via DSC) right.
- **Bars/UI**: waybar (one full bar per output), SwayNC notifications, walker launcher (+ elephant backend), hyprlock + swayidle (lock 10m / screens-off 15m).
- **Login**: greetd + tuigreet (GDM kept installed as rescue).
- **Terminal/shell**: Ghostty (CaskaydiaCove Nerd Font) · zsh (autosuggestions, syntax-highlighting, fzf-tab) + starship + atuin + zoxide + mise · zellij (sessions/multiplexing; tmux + fuzzel configs retired to `archive/`).
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
- **atuin ↑ history**: if up-arrow only shows the current session, set `filter_mode_shell_up_key_binding = "global"` and run `atuin import auto`.
- **New apps not in walker**: elephant only scans at startup. The `elephant-rescan.path` user unit (in the `systemd/` stow pkg) watches the app dirs and restarts elephant automatically; if it's not enabled, `systemctl --user restart elephant`.
- **lazydocker** talks to **podman** via `DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock` (zshrc) + `systemctl --user enable --now podman.socket`.
- **Rider + mise .NET**: GUI-launched Rider doesn't inherit mise's shell PATH — point Rider at the mise dotnet SDK path or export `DOTNET_ROOT` where the graphical session sees it. `mise use -g dotnet@9` (not `@latest`, which is currently a .NET 11 preview).
- **`cd` is zoxide** (`--cmd cd`); `ls`/`ll`/`la`/`lt` are eza; `cat` is bat (raw `\cat` still works). fzf owns Ctrl-T/Alt-C, atuin owns Ctrl-R.
- **Snapshot recovery**: if a kernel/driver update breaks boot, pick the **stock Fedora kernel** in GRUB (always present), then `sudo snapper rollback <N>` + reboot. `snapper list` / `btrfs-assistant` to browse. (grub-btrfs for boot-menu snapshot entries isn't packaged — COPR-only, optional.)
- **NVIDIA suspend**: `NVreg_PreserveVideoMemoryAllocations=1` (in `/etc/modprobe.d/nvidia-power.conf`) is required for the nvidia-suspend/resume services to actually preserve the session; lives in the initramfs so `dracut -f` after changing it.
- **git uses `delta`** (Catppuccin Mocha) as pager; `git dft` does a structural diff via difftastic. Identity stays the personal Gmail (`git/.gitconfig`); the old `~/.gitconfig` is backed up to `~/.gitconfig.pre-round6` on first `setup-round6.sh` run.
- **nvim C# LSP** (the one fiddly bit): `nvim/` uses LazyVim + `roslyn.nvim` with the Mason `roslyn` server. If it won't attach in a `.cs` file, `:Mason` → install/check `roslyn`, or fall back to OmniSharp (`:LazyExtras` → enable `lang.omnisharp`, remove `lua/plugins/dotnet.lua`).
- **`app-nvidia\x2dsettings\x2duser@autostart.service`** fails on login (nvidia-settings autostart under niri). Masked by the **escaped** unit name — the un-escaped `app-nvidia-settings-user@…` form never matched, which is why it kept showing up.
- **chezmoi is unused** — stow is the dotfiles system. `~/.config/chezmoi/key.txt` is an **age key** kept intentionally; don't delete it without checking what it decrypts.
- **Security — VS Code settings are NOT tracked**: VS Code rewrites `settings.json` with machine state (mssql connection profiles → server FQDNs, DB names, tokens). The repo is public, so that file is **gitignored**; only `settings.dist.json` (theme/UI, no connections) is tracked and seeded by `setup-editors.sh`. Never `git add -f` the live settings. (History was scrubbed once to remove previously-committed connection metadata.)
- **Click a notification → focus its app**: the `niri-notify-click.service` user unit (`bin/niri-notify-click`, a passive D-Bus monitor) maps each notification to its `desktop-entry` and focuses that app's niri window on click. Needed because some apps (e.g. Slack) don't act on their own notification action under Wayland.

## TODO

(nothing pending — the repo lives at `github.com/pmd-coutinho/dotfiles-fedora`,
branch `master`)
