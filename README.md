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
| `fix-igpu.sh` | Intel iGPU boot args by MUX mode (read from the `MsiDCVarData` UEFI var): **Discrete** → omit `i915,xe` from the initramfs image + `dracut -f` (an output-less i915 blanks the LUKS prompt; blacklisting it kills SOF audio); **MSHybrid** → `xe.force_probe=a788` (kernel 7.0+ dropped i915 for this Raptor Lake iGPU; without it the panel + Huawei went dark). |
| `setup-editors.sh` | Catppuccin for VS Code + Rider, VS Code keyring fix (niri), Rider native-Wayland toolkit. |
| `setup-round6.sh` | Workflow tooling: git+delta (Catppuccin) + aliases, dotnet-ef, Azure CLI, modern CLI (tldr/duf/procs/difftastic/just + dust/xh/watchexec binaries), neovim/LazyVim with C# (Roslyn) LSP. See [`docs/CLI-WORKFLOW.md`](docs/CLI-WORKFLOW.md) for how to use it all. |
| `setup-round7.sh` | CLI gap-fillers: sd, hyperfine, uv, glow, yq. |
| `setup-round8.sh` | Dev/ops TUIs + helpers: hurl, lnav, gum (dnf/COPR); mergiraf (git merge driver), trippy, kondo, ouch, pay-respects, msi-mux-switch (pinned binaries); csharprepl (dotnet tool), posting + isd (uv tools). |
| `setup-round10.sh` | Audit gap-fillers: restic (**installed, not configured** — nothing in `~`/`~/dev` is backed up off-machine yet), git-absorb, hexyl, tokei; ast-grep (pinned binary, invoke as `ast-grep` — `sg` collides with shadow-utils). |
| `archive/` | Superseded one-offs (kernel-modules half-install fix, old walker/bt script) kept for history; **not** run by bootstrap. |
| `docs/DICTATION.md` | **GPU voice dictation** (offline faster-whisper): `Mod+Shift+D` speak→English, `Mod+Alt+D` verbatim. Stow pkg `dictation` + `setup.sh` venv. |
| `sunshine/` | **Moonlight game-streaming host** (Sunshine, LizardByte COPR). `sunshine.conf` (KMS capture + NVENC), `apps.json` (Desktop / Steam Big Picture / Dota 2 via Flatpak Steam) and `stream-display` + `game-mode` prep scripts: the first repurposes the Gigabyte M28U at the client's resolution/refresh for each stream — niri 26.04 has no virtual outputs ([niri#3101](https://github.com/niri-wm/niri/discussions/3101)); Apollo's virtual display is Windows-only. Pairing state is gitignored. |
| `gamemode/` | Feral GameMode user config for Flatpak Steam (`gamemoderun %command%` on Dota 2): renice/soft-realtime only — governor + split-lock tweaks are made no-ops because tuned owns the governor and GameMode would flip it to powersave after every game. |
| `*/` | stow packages: alacritty, atuin, autostart, bin, btop, dictation, environment, fuzzel, gamemode, gh-dash, ghostty, git, gtk, jj, lazygit, mise, niri, nvim, quickshell, satty, starship, sunshine, systemd, yazi, zellij, zsh. (VS Code is **not** stowed — `setup-editors.sh` seeds `~/.config/Code/User/settings.json` from `vscode/.../settings.dist.json`; the live file is gitignored, see security note.) |

## The stack

- **Compositor**: niri, rendering on the NVIDIA dGPU (`debug { render-drm-device }` in `config.kdl`). The laptop runs in the MUX's **Discrete Graphics mode** (since 2026-09-17, see the "GPU MUX" gotcha): the panel and both external monitors are wired to the RTX 4080 and the Intel iGPU has no outputs, so nothing pays for cross-GPU copies. Not hot-reloadable. 3 monitors: Huawei (laptop HDMI port) top-left, laptop below it, Gigabyte (4K@144 via DSC, USB-C DP) right.
- **Bars/UI**: **quickshell** (`quickshell/` stow pkg, one QML process) owns the bar (per output), notifications (server + toasts + history), the **control center** (Mod+Shift+N / bell), the OSD, wallpaper, idle timeouts, the Mod+Shift+E session menu, the **lockscreen** (ext-session-lock + PAM) and the **PolicyKit agent**. Design system: `Theme/Theme.qml.in` (palette + semantic tokens, rendered by `palette/render.sh`; the `accent` follows the wallpaper via `Services/Wallpapers.qml`) and `Components/` (`Surface`, `BarItem`, `MenuRow`, `SliderBar`, `PasswordField`…). **Bar** (36px floating islands, identical on every output): workspace pills show the app icons of their windows and scroll to switch; the clock opens a calendar; right-island modules are icon-first (cpu/mem/volume as rings) with hover/pressed states and tooltips that list their clicks — volume: click mute · scroll · right = audio page (devices + card profiles); network/bluetooth: click = control-center page, right = toggle radio; power profile: click cycles; battery/bell: click = power page / notification list, bell right-click = DND. **Control center** (`ControlCenter/`): Controls tab (user/host/uptime, volume/mic/brightness sliders, Wi‑Fi/Bluetooth/DND/caffeine/night-light/power-profile tiles, media card with seek) and Notifications tab (per-app expandable groups, Today/Earlier, Clear all with 6s undo); sub-pages do Wi‑Fi (connect/PSK/forget; 802.1X → nm-connection-editor), Bluetooth (scan/pair/trust/connect; passkey pairing → blueman), audio devices, timed DND, power + battery. `qs ipc call controlcenter open wifi|bluetooth|audio|dnd|power|notifications` from a terminal. **Notifications** persist across restarts in `$XDG_STATE_HOME/quickshell/by-shell/<id>/notifications.json` (7 days / 200); toasts and the control center open on the laptop panel (`Config.mainOutput`; falls back to the focused output when it's off; `qs ipc call notifs setPopupOutput <name>` overrides toasts), pause on hover, dismiss on middle-click or swipe; `notifs setDnd/isDnd` keep working for sunshine's game-mode. **OSD** (`qs ipc call osd popup <kind> <value>`) covers volume/mic/brightness plus caps lock, DND, caffeine, night light and power profile (play/pause too if `Config.mediaOsd` is on; default off). **Idle** (`Services/Config.qml`): AC lock 10m / screens 15m, battery 5m / 7m, a 30s "locking in…" dim first, screens off 60s after a lock. Launcher + pickers are **fuzzel** (`fuzzel/` stow pkg): Mod+D app/run launcher, and dmenu-driven pickers for clipboard (`fz-clipboard` over cliphist), emoji/symbols (`fz-emoji`), files (`fz-files`), calc (`fz-calc` over qalc, Mod+Ctrl+=) and wallpaper (`fz-wallpaper`, Mod+Shift+W → crossfade + new accent). (Replaced walker + elephant, removed 2026-08-12.) All lock paths — Super+Alt+L, the idle timeout, the session menu and the control center's power button — go through `Services/Session.qml`; a minimal `swayidle -w before-sleep 'qs ipc call lock lock'` holds the logind sleep inhibitor for lock-before-sleep. waybar/swaync configs retired to `archive/`; hyprlock/waybar/swaync/swaybg/wlogout are no longer installed.
- **Login**: greetd + tuigreet (GDM kept installed as rescue).
- **Terminal/shell**: Ghostty (CaskaydiaCove Nerd Font) · zsh (autosuggestions, syntax-highlighting, fzf-tab) + starship + atuin + zoxide + mise · zellij (sessions/multiplexing; tmux + fuzzel configs retired to `archive/`).
- **Kernel**: CachyOS (BORE scheduler) via `bieszczaders/kernel-cachyos`; stock Fedora kernel is the GRUB fallback.
- **Swap**: 32G btrfs swapfile + **zswap** (zstd/zsmalloc) — zram disabled. For large .NET builds.
- **Power**: tuned + tuned-ppd; udev auto-switch AC→performance / battery→balanced; the quickshell bar module uses the native `PowerProfiles` D-Bus binding, event-driven (there is **no** `powerprofilesctl` — that ships with the conflicting power-profiles-daemon).
- **Screenshots + screen tools**: `Print` → grim+satty annotate; native niri grabs on Mod/Alt/Ctrl+Print. The rest of the toolkit lives in `bin/` and is region-selected with slurp: `Mod+Shift+Print` screen record (toggle; `Mod+Alt+Print` with audio, and the bar shows a pulsing indicator), `Mod+Shift+T` OCR → clipboard, `Mod+Shift+C` colour picker → hex, `Mod+Shift+Q` QR/barcode scan. All of them are also in the bar's **󰹑 screen-tools menu**, which lists each keybind next to its entry.
- **Game streaming**: Sunshine (user service `app-dev.lizardbyte.app.Sunshine`, web UI https://localhost:47990) → Moonlight on the MacBook Pro at 1920x1080@120. Per stream, `sunshine/.config/sunshine/stream-display on` saves the M28U's mode/scale, switches it to the client's `SUNSHINE_CLIENT_WIDTH×HEIGHT@FPS` (closest real mode, e.g. 1920x1080@119.879) at scale 1 and turns the laptop panel + Huawei off; `off` restores everything. `game-mode on` (second prep cmd) saves then sets notifications → DND, caffeine on (no idle lock mid-game) and the tuned-ppd profile → performance, restored on `off`; it uses the `notifs setDnd/isDnd` and `caffeine set/get` IPC calls added to quickshell's `shell.qml`. Dota 2 itself runs under Feral GameMode (`gamemode/` pkg; host `gamemoded` is D-Bus-activated by the sandboxed `gamemoderun`). KMS capture needs `cap_sys_admin` on `/usr/bin/sunshine` (bootstrap re-applies it) and the `input` group for uinput.
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
Interactive: `Print`→satty, `Mod+E`/`Mod+Slash` fuzzel pickers, tuigreet + F12 power menu, unplug AC → bar power icon flips, volume key → OSD pops, `Mod+Shift+N` control center (Wi‑Fi list populates, notification history survived the reboot), `Mod+Shift+E` session menu (←/→ moves, poweroff asks to confirm), `Super+Alt+L` lock → fade in, wrong password shakes, right one fades out.

## Known gotchas (learned the hard way)

- **Secure Boot must stay off** — unsigned NVIDIA/CachyOS kmods won't load otherwise.
- **iGPU driver depends on MUX mode** (`fix-igpu.sh` picks): in MSHybrid mode kernel 7.0+ needs `xe.force_probe=a788` or the Intel-driven outputs go dark; in Discrete mode (current) `i915`/`xe` are **omitted from the initramfs image** (`omit_drivers` in `/etc/dracut.conf.d/igpu-discrete.conf`) because an output-less DRM device breaks the boot splash (next gotcha), but i915 must still load after switch-root: the Intel SOF audio controller's HDMI codec binds to the i915 audio component and the card never probes without it (`deferred probe pending: init of i915 and HDMI codec failed` = no speakers/mic/jack). Do **not** use `rd.driver.blacklist` for this: dracut writes it to `/run/modprobe.d/initramfsblacklist.conf`, which survives switch-root, so it blacklists for the whole boot. `xe` is additionally in `modprobe.blacklist`. Re-run `sudo bash fix-igpu.sh` after every MUX switch.
- **GPU MUX (Discrete vs MSHybrid)**: MSI only exposes the switch in MSI Center on Windows, but [`steelbrain/msi-gpu-mux-switch`](https://github.com/steelbrain/msi-gpu-mux-switch) does it from Linux: it stages the target in the UEFI variable `MsiDCVarData` (byte 5 bits 0-1: 0 hybrid / 1 discrete / 2 integrated) and triggers the EC through the in-tree `msi-wmi-platform` driver (`Set_Data(0xD1)` / `Set_Data(0xBE)`). It was characterized on the MS-15M3 board; this MS-15M1 has the identical variable layout and the same WMI/EC methods (verified against the DSDT), so run it with `--allow-unsupported-hardware --allow-unvalidated-bios`, on AC power, then **full shutdown** (not reboot). `setup-round8.sh` installs the v0.2.0 release binary (sha256-pinned) to `~/.local/bin/msi-mux-switch`. Revert: `sudo msi-mux-switch mshybrid` + full shutdown. Writing EC byte 0x2E directly does **not** work — it is a status mirror the BIOS rewrites at POST. Switching modes renames connectors (DP-4→DP-3, HDMI-A-3→HDMI-A-2); niri's make/model matching copes.
- **LUKS prompt black under `rhgb quiet` in Discrete mode**: two causes, both fixed. (1) Fedora's plymouth uses simpledrm only when there is no LUKS, otherwise it waits for a real KMS driver; RPM Fusion omits nvidia from the initramfs, so the graphical splash had nowhere to draw → `setup-round4.sh` pins `UseSimpledrm=1` in `/etc/plymouth/plymouthd.conf` and rebuilds the initramfs. (2) Even on simpledrm, plymouth hands the splash to the first *real* DRM card that appears; i915 probing inside the initramfs (no outputs in Discrete mode) took the prompt with it to a black screen, and typing blind did nothing because the prompt was torn down → `fix-igpu.sh` omits `i915,xe` from the initramfs image and rebuilds it. Emergency fallback: delete `rhgb quiet` at the GRUB menu for a text prompt.
- **Flatpak Steam needs the NVIDIA extension matching the host driver** (`org.freedesktop.Platform.GL.nvidia-<ver>` + `GL32`, user scope). After a driver bump run `flatpak update` (or install the new version by hand) or Vulkan inside the sandbox has no NVIDIA ICD → Dota 2 "Failed to initialize Vulkan". In MSHybrid mode this was masked because the runtime's Mesa fell back to the Intel iGPU; in Discrete mode there is no fallback. `flatpak uninstall --unused` drops stale versions.
- **`kernel-cachyos`, not `-lto`** — the LTO/Clang build breaks GCC akmods (NVIDIA won't build).
- **CachyOS kernel updates** re-trigger the NVIDIA akmod build; wait for it (`modinfo -F version nvidia -k <kver>`) before rebooting, or boot the Fedora kernel.
- **Monitors are matched by make/model/serial** in niri (connector names like DP-3 shuffle when the NVIDIA driver loads). The Huawei's EDID serial is literally 13 spaces — keep them in the config string.
- **fuzzel needs `fd`, `cliphist`, `wl-clipboard`, `qalc`**: `fz-files` shells out to `fd`; `fz-clipboard` reads cliphist (fed by the two `wl-paste --watch cliphist store` niri startup spawns — text + images); emoji/symbols come from a committed `~/.config/fuzzel/emoji.tsv` (regenerate with `fuzzel/.config/fuzzel/regen-emoji.sh`). Clipboard **image previews** show as `[[ binary data … ]]` — fuzzel can't thumbnail, but they copy back fine.
- **GNOME apps (Nautilus, Decibels) may not open a window under niri**: they ask for a Wayland *service* connection over `org.gnome.Mutter.ServiceChannel`, which niri implements but rejects with `Invalid service client type`, so the app starts and exits windowless. Unrelated to the launcher — it fails the same way from a terminal.
- **`wl-screenrec` cannot work on this laptop**: it always builds a VAAPI filter chain (even with `--no-hw`), and VAAPI encode is unavailable here — libva can't auto-select a driver, `LIBVA_DRIVER_NAME=iHD` reaches the Intel iGPU but reports "No usable encoding profile found", and the NVIDIA node isn't supported by iHD. `bin/screen-record` therefore prefers **wf-recorder** (software x264 via ffmpeg); override with `SCREENREC_BIN`.
- **atuin ↑ history**: if up-arrow only shows the current session, set `filter_mode_shell_up_key_binding = "global"` and run `atuin import auto`.
- **quickshell breaks on Qt updates**: it's built against a specific Qt minor (COPR `errornointernet/quickshell`); after a `dnf upgrade` that bumps Qt, the shell may fail to start until the COPR rebuilds. Fallback: `dnf downgrade qt6-qtbase` or wait it out — niri itself is unaffected.
- **quickshell hot-reload goes stale**: after many file edits the running instance sometimes silently stops applying reloads — if a change doesn't show up, restart it, don't debug ghosts.
- **Switching git branches while quickshell runs logs scary reload errors** (`module "qs.X" is not installed`, `Y is not a type`): the checkout rewrites `~/.config/quickshell` file by file and the watcher reloads half-way through. The instance keeps the last config that loaded, so nothing breaks, but restart it afterwards (`pkill -x qs; pkill -x quickshell; qs -d`) so the watcher and the tree agree.
- **restarting quickshell**: the process name varies between `qs` and `quickshell` depending on how it was launched, and stale instances keep drawing their old windows (duplicate bars/menus, wrong-monitor popups). Restart with `pkill -x qs; pkill -x quickshell; qs -d`.
- **tray icons go missing after a quickshell restart**: quickshell owns the `org.kde.StatusNotifierWatcher`, so restarting it creates a *new* watcher. Apps that watch for that name re-register themselves (nm-applet, blueman, Telegram, voxide); apps that only register once at startup do **not** — in practice **KeePassXC and Slack**, which then have no icon until they're restarted. Check who is actually registered with:
  `busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems`
  Also note quickshell's watcher accepts the *object-path* form of `RegisterStatusNotifierItem` but rejects the *service-name* form ("Ignoring invalid StatusNotifierItem registration") — the spec allows both, so an app using the name form will never appear.
- **swaync/waybar/swaybg/wlogout/hyprlock are gone** — quickshell owns notifications, the bar, wallpaper, the session menu and the lockscreen. Nothing installs them any more. (Historic trap, in case one comes back: while swaync is *installed* it must stay masked, because dbus-broker re-spawns it via D-Bus activation even when disabled.)
- **console.log in QML is filtered** from quickshell's default log level — use `console.warn` when debugging the shell, and read logs with `qs log`.
- **Don't name an IpcHandler function `show`** — `qs ipc show` is a CLI subcommand and `qs ipc call osd show …` is parsed as it ("arguments were not expected"). That's why the OSD's entry point is `popup`.
- **Don't persist a JS object in `PersistentProperties`**: on hot reload it can't cross into the new engine ("JSValue can't be reassigned to another engine") and reads back `undefined`. Persist a JSON string and parse it (see `timesJson` in `Services/Notifs.qml`).
- **Testing the lock screen without locking**: `Lock/LockPreview.qml` renders the exact lock surfaces in plain overlay windows; its header has the `qs -p <copy>` recipe (wrong-password path included, Esc closes). Only ext-session-lock behaviour — unlock release, monitor power-off while locked — needs a real lock.
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
