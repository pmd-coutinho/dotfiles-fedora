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
mise → dictation venv → services → then calls the other scripts in this order:
`setup-root.sh` → `setup-round2.sh` → `fix-igpu.sh` → `setup-round3.sh` →
`install-toolbox.sh` → `setup-editors.sh` → `setup-round6.sh` →
`setup-round7.sh` → `setup-round8.sh` → `setup-round10.sh` → `setup-round4.sh`.
Note the run order is **not** the numeric order (round4's OS hardening runs
last) and there is no round5 or round9. The redundant `dnf` lines across scripts
are intentional and harmless (no-ops on re-run). Every script sources
`lib/common.sh` for `step`/`warn`/`ok` (and `asuser`/`fetch_bin` when root).

## What's here

| Path | Purpose |
|---|---|
| `bootstrap.sh` | **Start here.** Full ordered rebuild. |
| `setup-root.sh` | NVIDIA app-profile (VRAM-leak fix), greetd + keyring PAM, gdm→greetd, base services. |
| `setup-round2.sh` | 32G btrfs swapfile + zswap, power auto-switch udev rule, tuigreet polish, CachyOS kernel + NVIDIA akmod rebuild. |
| `setup-round3.sh` | Apps: VS Code (MS repo), Vivaldi, OpenVPN3, Slack (native rpm — Flatpak sandbox breaks notification action routing), Obsidian/Telegram (Flatpak), lazygit/lazydocker (COPR), bat/ripgrep/eza/btop. |
| `install-toolbox.sh` | JetBrains Toolbox (user-level) → install Rider from its GUI. |
| `setup-round4.sh` | OS hardening: NVIDIA VRAM-preserve across suspend, journald 500M cap, inotify bump (Rider/VS Code/dotnet-watch), snapper + btrfs-assistant timeline snapshots (root only). |
| `fix-igpu.sh` | `xe.force_probe=a788` — kernel 7.0+ dropped i915 for this Raptor Lake iGPU; without it the laptop panel + Huawei go dark. |
| `setup-editors.sh` | Catppuccin for VS Code + Rider, VS Code keyring fix (niri), Rider native-Wayland toolkit. |
| `setup-round6.sh` | Workflow tooling: git+delta (Catppuccin) + aliases, dotnet-ef, Azure CLI, modern CLI (tldr/duf/procs/difftastic/just + dust/xh/watchexec binaries), neovim/LazyVim with C# (Roslyn) LSP. See [`docs/CLI-WORKFLOW.md`](docs/CLI-WORKFLOW.md) for how to use it all. |
| `setup-round7.sh` | CLI gap-fillers: sd, hyperfine, uv, glow, yq. |
| `setup-round8.sh` | Dev/ops TUIs + helpers: hurl, lnav, gum (dnf/COPR); mergiraf (git merge driver), trippy, kondo, ouch, pay-respects (pinned binaries); csharprepl (dotnet tool), posting + isd (uv tools). |
| `setup-round10.sh` | Audit gap-fillers: restic (**installed, not configured** — nothing in `~`/`~/dev` is backed up off-machine yet), git-absorb, hexyl, tokei; ast-grep (pinned binary, invoke as `ast-grep` — `sg` collides with shadow-utils). |
| `archive/` | Superseded one-offs (kernel-modules half-install fix, old walker/bt script) kept for history; **not** run by bootstrap. |
| `docs/DICTATION.md` | **GPU voice dictation** (offline faster-whisper): `Mod+Shift+D` speak→English, `Mod+Alt+D` verbatim. Stow pkg `dictation` + `setup.sh` venv. |
| `*/` | stow packages: alacritty, atuin, autostart, bin, btop, dictation, environment, fuzzel, gh-dash, ghostty, git, gtk, jj, lazygit, mise, niri, nvim, quickshell, satty, starship, systemd, yazi, zellij, zsh. (VS Code is **not** stowed — `setup-editors.sh` seeds `~/.config/Code/User/settings.json` from `vscode/.../settings.dist.json`; the live file is gitignored, see security note.) |

## The stack

- **Compositor**: niri, on niri's **default render device** — the `debug { render-drm-device }` dGPU pin is commented out in `config.kdl` (kept with its rationale) since the 4K monitor moved to the Intel iGPU. 3 monitors: Huawei top-left, laptop below it, Gigabyte (4K@144 via DSC) right.
- **Bars/UI**: **quickshell** (`quickshell/` stow pkg, one QML process) owns the bar (per output), notifications (server + popups + Mod+Shift+N panel), volume/brightness OSD, wallpaper, idle timeouts (lock 10m / screens-off 15m), the Mod+Shift+E session menu, the **lockscreen** (ext-session-lock + PAM) and the **PolicyKit agent**. Bar extras: middle-click the volume module for an output/input picker (plus card-profile switching, for sinks hidden behind an inactive profile), 󰅶 toggles caffeine (suspends the idle lock), a red mic glyph appears only while something is recording, and now-playing/recording indicators show when relevant. Colors come from the palette via `Theme.qml.in`. Launcher + pickers are **fuzzel** (`fuzzel/` stow pkg): Mod+D app/run launcher, and dmenu-driven pickers for clipboard (`fz-clipboard` over cliphist), emoji/symbols (`fz-emoji`), files (`fz-files`) and calc (`fz-calc` over qalc, Mod+Ctrl+=) — see the launchers table. (Replaced walker + elephant, removed 2026-08-12.) All lock paths — Super+Alt+L, the 10m idle timeout, the session menu and the notification panel — go through `Services/Session.qml`; a minimal `swayidle -w before-sleep 'qs ipc call lock lock'` holds the logind sleep inhibitor for lock-before-sleep. waybar/swaync configs retired to `archive/`; hyprlock/waybar/swaync/swaybg/wlogout are no longer installed.
- **Login**: greetd + tuigreet (GDM kept installed as rescue).
- **Terminal/shell**: Ghostty (CaskaydiaCove Nerd Font) · zsh (autosuggestions, syntax-highlighting, fzf-tab) + starship + atuin + zoxide + mise · zellij (sessions/multiplexing; tmux + fuzzel configs retired to `archive/`).
- **Kernel**: CachyOS (BORE scheduler) via `bieszczaders/kernel-cachyos`; stock Fedora kernel is the GRUB fallback.
- **Swap**: 32G btrfs swapfile + **zswap** (zstd/zsmalloc) — zram disabled. For large .NET builds.
- **Power**: tuned + tuned-ppd; udev auto-switch AC→performance / battery→balanced; the quickshell bar module uses the native `PowerProfiles` D-Bus binding, event-driven (there is **no** `powerprofilesctl` — that ships with the conflicting power-profiles-daemon).
- **Screenshots + screen tools**: `Print` → grim+satty annotate; native niri grabs on Mod/Alt/Ctrl+Print. The rest of the toolkit lives in `bin/` and is region-selected with slurp: `Mod+Shift+Print` screen record (toggle; `Mod+Alt+Print` with audio, and the bar shows a pulsing indicator), `Mod+Shift+T` OCR → clipboard, `Mod+Shift+C` colour picker → hex, `Mod+Shift+Q` QR/barcode scan. All of them are also in the bar's **󰹑 screen-tools menu**, which lists each keybind next to its entry.
- **Passwords**: KeePassXC (`~/vault/Passwords.kdbx`) two-way synced to Google Drive via `rclone bisync` (systemd `.path` + `.timer` units, `systemd/` stow pkg). On a fresh install the rclone Drive OAuth (`rclone config`) and the first `rclone bisync --resync` are manual — see [`docs/SECURITY.md`](docs/SECURITY.md) for the safety flags and recovery commands.

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
Interactive: `Print`→satty, `Mod+E`/`Mod+Slash` fuzzel pickers, tuigreet + F12 power menu, unplug AC → bar power icon flips, volume key → OSD pops, `Mod+Shift+N` notification panel, `Mod+Shift+E` session menu.

## Known gotchas (learned the hard way)

- **Secure Boot must stay off** — unsigned NVIDIA/CachyOS kmods won't load otherwise.
- **iGPU on kernel 7.0+**: needs `xe.force_probe=a788` (`fix-igpu.sh`) or the Intel-driven outputs go dark.
- **`kernel-cachyos`, not `-lto`** — the LTO/Clang build breaks GCC akmods (NVIDIA won't build).
- **CachyOS kernel updates** re-trigger the NVIDIA akmod build; wait for it (`modinfo -F version nvidia -k <kver>`) before rebooting, or boot the Fedora kernel.
- **Monitors are matched by make/model/serial** in niri (connector names like DP-3 shuffle when the NVIDIA driver loads). The Huawei's EDID serial is literally 13 spaces — keep them in the config string.
- **fuzzel needs `fd`, `cliphist`, `wl-clipboard`, `qalc`**: `fz-files` shells out to `fd`; `fz-clipboard` reads cliphist (fed by the two `wl-paste --watch cliphist store` niri startup spawns — text + images); emoji/symbols come from a committed `~/.config/fuzzel/emoji.tsv` (regenerate with `fuzzel/.config/fuzzel/regen-emoji.sh`). Clipboard **image previews** show as `[[ binary data … ]]` — fuzzel can't thumbnail, but they copy back fine.
- **GNOME apps (Nautilus, Decibels) may not open a window under niri**: they ask for a Wayland *service* connection over `org.gnome.Mutter.ServiceChannel`, which niri implements but rejects with `Invalid service client type`, so the app starts and exits windowless. Unrelated to the launcher — it fails the same way from a terminal.
- **`wl-screenrec` cannot work on this laptop**: it always builds a VAAPI filter chain (even with `--no-hw`), and VAAPI encode is unavailable here — libva can't auto-select a driver, `LIBVA_DRIVER_NAME=iHD` reaches the Intel iGPU but reports "No usable encoding profile found", and the NVIDIA node isn't supported by iHD. `bin/screen-record` therefore prefers **wf-recorder** (software x264 via ffmpeg); override with `SCREENREC_BIN`.
- **atuin ↑ history**: if up-arrow only shows the current session, set `filter_mode_shell_up_key_binding = "global"` and run `atuin import auto`.
- **quickshell breaks on Qt updates**: it's built against a specific Qt minor (COPR `errornointernet/quickshell`); after a `dnf upgrade` that bumps Qt, the shell may fail to start until the COPR rebuilds. Fallback: `dnf downgrade qt6-qtbase` or wait it out — niri itself is unaffected.
- **quickshell hot-reload goes stale**: after many file edits the running instance sometimes silently stops applying reloads — if a change doesn't show up, restart it, don't debug ghosts.
- **restarting quickshell**: the process name varies between `qs` and `quickshell` depending on how it was launched, and stale instances keep drawing their old windows (duplicate bars/menus, wrong-monitor popups). Restart with `pkill -x qs; pkill -x quickshell; qs -d`.
- **tray icons go missing after a quickshell restart**: quickshell owns the `org.kde.StatusNotifierWatcher`, so restarting it creates a *new* watcher. Apps that watch for that name re-register themselves (nm-applet, blueman, Telegram, voxide); apps that only register once at startup do **not** — in practice **KeePassXC and Slack**, which then have no icon until they're restarted. Check who is actually registered with:
  `busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems`
  Also note quickshell's watcher accepts the *object-path* form of `RegisterStatusNotifierItem` but rejects the *service-name* form ("Ignoring invalid StatusNotifierItem registration") — the spec allows both, so an app using the name form will never appear.
- **swaync/waybar/swaybg/wlogout/hyprlock are gone** — quickshell owns notifications, the bar, wallpaper, the session menu and the lockscreen. Nothing installs them any more. (Historic trap, in case one comes back: while swaync is *installed* it must stay masked, because dbus-broker re-spawns it via D-Bus activation even when disabled.)
- **console.log in QML is filtered** from quickshell's default log level — use `console.warn` when debugging the shell, and read logs with `qs log`.
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
- **Click a notification → focus its app**: quickshell *is* the notification server, so `Services/Notifs.qml` maps each notification's `desktop-entry` to a niri window and focuses it (`focusSource()`). This replaced the `niri-notify-click` D-Bus-eavesdropping daemon entirely. Still needed because some apps (e.g. Slack) don't act on their own notification action under Wayland.
- **Speakers vanish after a bluetooth headset disconnects**: this laptop's SOF card puts `Speaker` and `Headphones` in *mutually exclusive* profiles and WirePlumber picks by static priority, so it can sit in the Headphones profile with nothing plugged in — no Speaker sink exists and audio falls through to an HDMI output. `audio-jack-profile.service` (in `systemd/`) watches the jack and switches the profile to match. Run `audio-jack-profile` by hand to force a re-check.

## TODO

- **Screen toolkit**: recording (wf-recorder → h264_nvenc), OCR (eng+por,
  accents intact) and the colour picker are verified. **QR decode is not** —
  `zbarimg` runs and its no-code-found path is handled, but no QR was ever
  decoded here. Point `Mod+Shift+Q` at a real code once to close this out.
- **qmllint in `hooks/pre-commit` is advisory** (it reports, never blocks).
  quickshell synthesizes the `qs.*` modules at runtime so imports can't resolve;
  the categories downstream of that are disabled. Consider making it blocking
  once it has been quiet for a while.

The repo lives at `github.com/pmd-coutinho/dotfiles-fedora`, branch `master`.
