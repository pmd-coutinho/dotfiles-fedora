# Workflow cheatsheet

Daily-driver keybinds & commands for this setup. `*` = added/changed in the
2026-06 workflow overhaul. See also [CLI-WORKFLOW.md](CLI-WORKFLOW.md) and
[rider-setup.md](rider-setup.md).

---

## Zellij — sessions (project → ticket → tabs)

Sessions are named `project:ticket` (e.g. `nxg-csharp-nopcommerce:OT-12935`).
These shell commands run **from a plain terminal** (outside Zellij).

| Command | What |
|---|---|
| `zd` * | Attach-or-create a session named after the current dir (resurrects if dead) |
| `zd <name>` * | …or name it explicitly |
| `zp` * | **Project → ticket sessionizer**: fzf a repo under `~/dev`, then pick/create a ticket session |
| `zs` * / **Ctrl-f** * | Flat fzf navigator over *all* sessions (type a project or ticket to jump) |
| `zdl` * | fzf session picker — **Ctrl-X** deletes the highlighted session, **Enter** attaches |
| `zellij ls` | List running + serialized sessions |
| `zellij -s <n> -n <layout>` | Raw create (use `-n`, not `--layout`, with `-s`) |

**Layouts** (`~/.config/zellij/layouts/`): `dev` (claude + shell) · `nxg-csharp-nopcommerce` * (claude/shell/dotnet/git). `zp` auto-picks `<project>.kdl` if it exists.

---

## Zellij — inside a session

Modal: press the `Ctrl` combo to enter a mode, then a letter. Hints show in the bottom status-bar.

| Key | Mode / action |
|---|---|
| **Ctrl-p** then `n`/`d`/`r`/`x` | Pane: new / split-down / split-right / close |
| **Ctrl-t** then `n`/`h`/`l`/`1-9` | Tab: new / prev / next / go-to-N |
| **Ctrl-o** then `w` | **Session-manager** — switch session without detaching |
| **Ctrl-o** then `d` | **Detach** (session keeps running) |
| **Ctrl-s** | Scroll / search mode (then `s` to search) |
| **Ctrl-n** | Resize mode (then arrows/`hjkl`) |
| **Alt-←↑↓→** / **Alt-hjkl** | Move focus between panes (no prefix) |
| **Ctrl-q** | Quit (kills the session) |
| Pane mode → `z` | Toggle pane frames on/off |

**Autolock** * — auto-locks (keys pass straight through) when the pane runs `nvim/fzf/lazygit/less/man`; auto-unlocks on exit.

| Key | What |
|---|---|
| **Alt-z** * | Disable autolock (stay unlocked) |
| **Alt-Shift-z** * | Re-enable autolock |
| **Ctrl-g** | Manually toggle Locked mode |

Bars *: **top** = zjstatus (session · tabs · git branch · clock) · **bottom** = a second zjstatus (static keymap hint line).

---

## zsh — abbreviations (type + Space to expand) *

Expand in place, so atuin/history record the real command.

| Abbr | Expands | Abbr | Expands |
|---|---|---|---|
| `g` | `git` | `d` | `dotnet` |
| `gst` | `git status` | `dr` | `dotnet run` |
| `gco` | `git checkout` | `dt` | `dotnet test` |
| `gsw` | `git switch` | `db` | `dotnet build` |
| `ga` | `git add` | `dw` | `dotnet watch` |
| `gc` | `git commit` | `def` | `dotnet ef` |
| `gd` | `git diff` | `pc` | `podman compose` |
| `gp` / `gpf` | `git push` / `…--force-with-lease` | `j` | `just` |
| `gl` / `glo` | `git pull` / `git log --oneline -20` | | |

Add more: `abbr add k=v`, then paste the line into `.zshrc`.

---

## zsh — keybinds & launchers

| Key / cmd | What |
|---|---|
| **Ctrl-f** * | `zs` — Zellij session navigator |
| **Ctrl-r** | atuin history (global; selecting **edits** the line, doesn't auto-run) * |
| **↑** | atuin history scoped to current directory * |
| **Ctrl-t** / **Alt-c** | fzf file / fzf cd |
| **Tab** | fzf-tab completion with previews (eza dirs, bat files, git-log branches) * |
| `cd <x>` / `cdi` | zoxide jump / interactive |
| `y` * | **yazi** file manager — cds to where you quit |
| `ll` / `la` / `lt` | eza long / all / tree |
| `lg` / `lzd` / `v` | lazygit / lazydocker / nvim |

---

## git & lazygit

| Cmd | What |
|---|---|
| `git st` / `lg` / `dft` | status / graph log / **difftastic** structural diff |
| `git co`·`sw` / `ci`·`cm "msg"` | checkout·switch / commit·commit-m |
| `git amend` / `dc` / `unstage <f>` / `pf` | amend-no-edit / diff --cached / restore --staged / push --force-with-lease |
| `lg` | lazygit (delta diffs) |
| lazygit **`U`** * | difftastic structural diff of the selected file |

---

## jj (jujutsu) sandbox * — in `~/dotfiles`

Colocated: shares the real `.git`, so git keeps working. A trial — not on work repos yet.

| Cmd | What |
|---|---|
| `jj` / `jj log` | Log (working-copy `@` + history) |
| `jj st` | Status of the working-copy commit |
| `jjui` | TUI (lazygit-style for jj) |
| `jj git init --colocate` | Set up jj in another repo |

---

## yazi (file manager) *

Launch with `y` (cds on quit). Inside:

| Key | What |
|---|---|
| `h` / `j` / `k` / `l` | Up-dir / down / up / enter-dir-or-open |
| `Space` / `v` | Select / visual select |
| `y` / `x` / `p` / `d` | Copy / cut / paste / delete |
| `/` / `gg` / `G` | Find / top / bottom |
| `q` / `Q` | Quit (cd) / quit (no cd) |

---

## Theme — Catppuccin palette (single source) *

| Action | Cmd |
|---|---|
| Change a colour everywhere | edit `palette/catppuccin-mocha.env`, then `palette/render.sh` |
| Templated files | `*.in` → rendered to real file (waybar style+config, swaync, alacritty, niri, starship, satty, hyprlock, walker theme) |
| Verify in sync | `palette/render.sh --check` (also run by the pre-commit hook) |

---

## Dotfiles repo workflow

| Action | Cmd / note |
|---|---|
| Rebuild a machine | `bash ~/dotfiles/bootstrap.sh` (idempotent) |
| Stow one package | `cd ~/dotfiles && stow <pkg>` |
| Pre-commit checks * | shellcheck (`*.sh`), `zsh -n`, `zellij setup --check`, palette `render.sh --check` |
| Bypass the hook once | `git commit --no-verify` |
| GitHub PRs/issues | `gh dash` * |

---

## .NET dev loop

| Cmd | What |
|---|---|
| `dotnet ef migrations add <N>` / `database update` | EF migrations |
| `watchexec -e cs -- dotnet test --filter 'FullyQualifiedName~<C>'` | Re-run tests on change |
| `just <recipe>` | Project task runner |
| `xh :5000/api/...` | HTTP client |

**Rider** (daily IDE): heap `-Xmx8192m`, `-Dawt.toolkit.name=WLToolkit` (native Wayland), SWA exclusions — see [rider-setup.md](rider-setup.md). Worktrees: `Git → New Worktree` (start point = `main`).
