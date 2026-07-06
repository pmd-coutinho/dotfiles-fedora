# CLI workflow cheatsheet

Quick reference for the tooling added in Round 6 (`setup-round6.sh`), oriented
around a .NET / NopCommerce + Azure SQL + podman workflow. Everything here is
available in a fresh shell.

> Examples use placeholders like `<sql-server>`, `<rg>` (resource group),
> `<app>`, `<project>`, `<sql-container>` — substitute your own. This file is
> committed to a public repo, so it intentionally contains no real hostnames,
> database names, or credentials.

---

## Git — delta + difftastic + aliases

`git diff` / `git log` / `git show` render through **delta** (Catppuccin Mocha,
line numbers, syntax highlighting). Aliases (`git/.gitconfig`):

| Alias | Expands to | Use |
|---|---|---|
| `git st` | `status` | quick status |
| `git lg` | graph log | pretty history, all branches |
| `git co` / `git sw` | `checkout` / `switch` | change branch |
| `git ci` / `git cm "msg"` | `commit` / `commit -m` | commit |
| `git amend` | `commit --amend --no-edit` | fix last commit, keep message |
| `git dc` | `diff --cached` | review what's staged before committing |
| `git unstage <f>` | `restore --staged` | unstage a file |
| `git pf` | `push --force-with-lease` | safe force-push |
| `git dft` | structural diff (difftastic) | **see below** |

**`git dft`** shows *which code constructs* changed (method/class/block), not raw
line deltas — far more readable for C# refactors, renames, and reformats:

```bash
git dft                 # working tree, structural
git dft HEAD~3          # vs 3 commits ago
```

---

## .NET — dotnet-ef + watchexec

```bash
dotnet ef migrations add <Name>     # create an EF Core migration
dotnet ef database update           # apply migrations
dotnet ef migrations remove         # drop the last (unapplied) migration

# watchexec: re-run a command on file changes (lighter than dotnet watch for
# tests/scripts; pairs well with a local SQL container)
watchexec -e cs -- dotnet test
watchexec -e cs,cshtml --restart -- dotnet run
```

`dotnet format` ships with the SDK (no install): `dotnet format` /
`dotnet format --verify-no-changes` (CI-style check).

---

## Azure — az CLI

Signed in interactively (`az login`); the starship prompt shows the active
subscription (`󰠅 …`).

```bash
az account show                                  # current subscription/tenant
az account set --subscription <name-or-id>
az sql db list --server <sql-server> -o table    # DBs on a server
az webapp log tail -n <app> -g <rg>              # live App Service logs
az webapp list -g <rg> -o table
devtunnel host                                   # authenticates via az
```

---

## HTTP — xh (API testing)

Cleaner than curl; JSON body by default, colorized output.

```bash
xh :5000/api/products                       # GET localhost:5000/...
xh POST :5000/api/login email=x@y.com password=secret   # JSON body
xh -a user:pass GET https://host/api/orders # basic auth
xh GET https://host/api/x 'Authorization:Bearer TOKEN'  # custom header
```

---

## System & containers — procs, dust, duf

```bash
procs dotnet            # find dotnet processes (tree, ports, start time)
procs --sortd cpu       # sort by CPU desc
procs --tree

dust <project>          # disk usage tree — finds fat obj/ bin/ .nuget dirs fast
dust -d 2 ~/dev         # limit depth

duf                     # disk free per mount, pretty
```

---

## just — per-project task runner

Drop a `justfile` in a repo root; run recipes from anywhere inside it. Example:

```make
# justfile
default:
    @just --list

up:       podman compose up -d
down:     podman compose down
test:     dotnet test
build:    dotnet build
migrate:  dotnet ef database update
reset-db: podman restart <sql-container> && just migrate
run:      dotnet run --project src/<App>
```

```bash
just            # list recipes
just up         # run a recipe
just reset-db
```

---

## tldr — practical cheatsheets

Concise, example-first (vs full man pages). Cache refresh: `tldr --update`.

```bash
tldr dotnet     tldr az     tldr podman     tldr just     tldr git
```

---

## neovim — LazyVim + C# (Roslyn)

Launch with `nvim` or the `v` alias. In a `.cs` file the Roslyn LSP attaches to
the solution.

| Key | Action |
|---|---|
| `<leader>ff` / `<leader>/` | find files / live grep (project) |
| `gd` / `gr` | go to definition / references |
| `K` | hover docs |
| `<leader>ca` | code actions |
| `<leader>cf` | format (csharpier) |
| `<leader>e` | file explorer |
| `<leader>gg` | lazygit |

First launch finishes any remaining plugin/LSP install. `:Mason` to manage
language servers; `:LazyExtras` to toggle language packs.

---

## zellij — terminal multiplexer (AI-agent sessions)

Batteries-included alternative to tmux with an on-screen keymap, so you stop
losing track of parallel sessions (e.g. one Claude Code / opencode agent per
ticket). Config is a stow package (`zellij/.config/zellij/config.kdl`):
Catppuccin Mocha, `wl-copy` clipboard, `zsh`, and **session serialization** —
sessions survive detach, crash, and reboot.

Keybinds are left at Zellij **defaults** on purpose; the bottom status bar shows
them live. `Ctrl-<key>` enters a mode, then a letter acts:

| Key | Mode / action |
|---|---|
| `Ctrl-p` then `n` / `d` / `x` | pane: new / split-down / close |
| `Ctrl-t` then `n` / `h` `l` | tab: new / prev / next |
| `Ctrl-o` then `d` | session: **detach** (leaves it running) |
| `Ctrl-s` then `e` | scrollback: edit buffer in nvim |
| `Ctrl-h/j/k/l` | move focus between panes |
| `Ctrl-q` | quit (kills the session) |

Session management (the part that fixes "lost track"):

```bash
zellij                  # start a new session (auto-named)
zellij -s ot-12935      # start a named session (use the ticket)
zellij ls               # list running + serialized sessions
zellij a                # attach to the last/only session
zellij a ot-12935       # attach to a named one
zellij setup --check    # validate config.kdl
```

Run an agent per session and detach (`Ctrl-o d`) instead of stacking panes in
one tmux window — `zellij ls` is then your single overview.

**Preconfigured `dev` layout** (`zellij/.config/zellij/layouts/dev.kdl`) —
tab 1 auto-runs Claude Code, tab 2 is a plain zsh:

```bash
cd <project>
zd                            # attach-or-create, session named after the dir
zd ot-12935                   # ...or name it explicitly
zellij -s ot-12935 -n dev     # the raw form zd wraps
```

**`zd`** (zsh function) is the day-to-day entry point: it attaches to the
session named after the current dir (resurrecting it if dead), or creates a new
one with the `dev` layout — so re-running it in a repo drops you back where you
left off instead of spawning duplicates. Refuses to nest if already inside Zellij.

Use **`-n`** (`--new-session-with-layout`), not `--layout`: combined with `-s`,
`--layout` tries to add tabs to an *existing* session and errors with "session
not found". `-n` always creates a new session.

### Project → ticket → tabs (zp / zs)

Zellij sessions are a flat namespace, so the **project→session→tabs** hierarchy
is encoded in the session name: **`<project>:<ticket>`** (e.g.
`nxg-csharp-nopcommerce:OT-12935`). `/` is rejected by Zellij; `:` is the
delimiter.

| Cmd | Job |
|---|---|
| **`zp`** | Sessionizer: fzf a project (subdir of `$ZELLIJ_PROJECT_DIRS`, default `~/dev`), then pick one of its `<project>:*` sessions or **＋ new ticket**. Creates `<project>:<ticket>` with the project's layout, else `dev`. Also lists children of `$ZELLIJ_CONTAINER_DIRS` as leaf workspaces — see below. |
| **`zs`** (Ctrl-f) | Flat fzf navigator over *all* sessions. Type a project to filter to its tickets, or a ticket to jump straight. Run from a plain terminal. |
| `zd` | Quick attach-or-create for the current dir (no ticket). |
| `zdl` | fzf picker; Ctrl-X deletes the highlighted session. |

`zp`/`zs`/`zd` attach from *outside* Zellij; **inside** a session use Zellij's
native `Ctrl-o w` (session-manager) to switch without detaching.

**Container dirs → leaf workspaces.** Some `~/dev` entries aren't repos — they're
*containers* of unrelated dirs: a worktrees pool, or a scratch folder holding
several sub-projects. List them in **`$ZELLIJ_CONTAINER_DIRS`** (default
`~/dev/exporation ~/dev/worktrees`) and `zp` lists their *children* as pickable
workspaces (hiding the containers themselves). Picking one is a one-shot
attach-or-create cwd'd into that dir — no ticket sub-prompt, since the dir *is*
the workspace. Naming reuses the `:` namespace:

- a **git worktree** is named after its parent repo (detected via
  `git rev-parse --git-common-dir`): `~/dev/worktrees/OT-12943` →
  **`nxg-csharp-nopcommerce:OT-12943`**, so `zs` filtering by the repo surfaces
  worktrees right next to that repo's ticket sessions;
- anything else after its container: `~/dev/exporation/workflow` →
  **`exporation:workflow`**.

(Equivalent to `cd <dir> && zd`, but discoverable from the `zp` picker with a
project-aware name.)

**Per-project layouts:** drop `~/.config/zellij/layouts/<project>.kdl` and `zp`
uses it for that project's new sessions (e.g. a repo that wants `claude + shell
+ sql`); everything else falls back to `dev`. Worktrees pick up their parent
repo's layout the same way. This is the "organize by project, not just by
feature" piece.

---

## Text & data — sd, yq, glow (round 7)

```bash
sd 'v1/api' 'v2/api' src/**/*.cs      # sed, but literal-by-default + sane regex
sd -p 'foo(\d+)' 'bar$1' file.txt     # -p previews without writing

yq '.services.db.image' compose.yaml  # jq for YAML (also JSON/TOML/XML)
yq -i '.version = "2"' config.yaml    # edit in place

glow README.md                        # render markdown in the terminal
glow -p docs/                         # browse a docs dir, pager mode
```

---

## Benchmarks & Python — hyperfine, uv (round 7)

```bash
hyperfine 'dotnet build' 'dotnet build --no-restore'   # A/B with warmup+stats
hyperfine --warmup 3 'zsh -i -c exit'                  # e.g. shell startup time

uv venv && uv pip install requests    # pip/venv, but instant
uvx ruff check .                      # run a python tool without installing it
uv run script.py                      # PEP 723 inline-deps scripts
```

---

## Other tools already in the stack

`bat` (cat), `eza` (ls/ll/la/lt), `fd` (find), `rg` (ripgrep/grep), `fzf`
(Ctrl-T files, Alt-C dir), `atuin` (Ctrl-R history), `zoxide` (`cd` = jump),
`lazygit` (`lg`), `lazydocker` (`lzd`), `btop`.
