# ~/.zshrc — lean, no framework

# ── History ───────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # share across sessions
setopt HIST_IGNORE_ALL_DUPS   # no duplicate entries
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # expand !! before running
setopt INC_APPEND_HISTORY

# ── Options ───────────────────────────────────────────────────────────
setopt AUTO_CD                # `..` instead of `cd ..`
setopt INTERACTIVE_COMMENTS   # allow # comments in interactive shell
setopt NO_BEEP

# ── Completion ────────────────────────────────────────────────────────
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
zstyle ':completion:*' menu no                              # fzf-tab takes over
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# fzf-tab: fuzzy tab completion (git clone in ~/.local/share/zsh)
[[ -r ~/.local/share/zsh/fzf-tab/fzf-tab.plugin.zsh ]] && \
    source ~/.local/share/zsh/fzf-tab/fzf-tab.plugin.zsh

# ── Plugins (dnf packages) ────────────────────────────────────────────
[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'  # mocha overlay0

# zsh-abbr: abbreviations that expand in place (git clone in ~/.local/share/zsh).
# Source before syntax-highlighting; abbr definitions live in the Aliases section.
[[ -r ~/.local/share/zsh/zsh-abbr/zsh-abbr.zsh ]] && \
    source ~/.local/share/zsh/zsh-abbr/zsh-abbr.zsh

# ── Keybinds ──────────────────────────────────────────────────────────
bindkey -e                            # emacs mode
bindkey '^[[1;5C' forward-word        # ctrl+right
bindkey '^[[1;5D' backward-word       # ctrl+left
bindkey '^[[3~'   delete-char         # delete
bindkey '^[[H'    beginning-of-line   # home
bindkey '^[[F'    end-of-line         # end

# ── Aliases ───────────────────────────────────────────────────────────
# eza in place of ls
if command -v eza >/dev/null; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -lah --group-directories-first --icons=auto --git'
    alias la='eza -a --group-directories-first --icons=auto'
    alias lt='eza --tree --level=2 --icons=auto'
else
    alias ll='ls -lah --color=auto'
    alias ls='ls --color=auto'
fi
# bat in place of cat (auto-passes-through when piped, so scripts are safe;
# raw cat is still available as \cat)
command -v bat >/dev/null && alias cat='bat --style=plain --paging=never'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias lg='lazygit'
alias lzd='lazydocker'
command -v nvim >/dev/null && alias v='nvim'

# zsh-abbr session abbreviations — expand in place on SPACE, so atuin/history
# record the REAL command (not the abbr). Declarative (not a state file); grow
# with `abbr add k=v`, then paste the line here. Guarded so a fresh box (before
# bootstrap clones zsh-abbr) doesn't error.
if command -v abbr >/dev/null; then
    ABBR_QUIET=1                      # don't echo "Added …" for each line below
    abbr -S g='git'
    abbr -S gst='git status'
    abbr -S gco='git checkout'
    abbr -S gsw='git switch'
    abbr -S ga='git add'
    abbr -S gc='git commit'
    abbr -S gd='git diff'
    abbr -S gp='git push'
    abbr -S gpf='git push --force-with-lease'
    abbr -S gl='git pull'
    abbr -S glo='git log --oneline -20'
    abbr -S d='dotnet'
    abbr -S dr='dotnet run'
    abbr -S dt='dotnet test'
    abbr -S db='dotnet build'
    abbr -S dw='dotnet watch'
    abbr -S def='dotnet ef'
    abbr -S pc='podman compose'
    abbr -S j='just'
    ABBR_QUIET=0
fi

# zd [name] — Zellij attach-or-create. Attaches to the session named after the
# current dir (or $1), resurrecting it if dead; creates new ones with the `dev`
# layout (Claude Code + shell tabs). Avoids re-creating every time.
zd() {
    if [[ -n $ZELLIJ ]]; then
        print -u2 "zd: already inside Zellij session '${ZELLIJ_SESSION_NAME:-?}'"
        return 1
    fi
    local name="${1:-${PWD:t}}"
    if zellij ls -s 2>/dev/null | grep -qxF -- "$name"; then
        zellij attach -f "$name"   # -f re-runs commands if resurrecting a dead session
    else
        zellij -s "$name" -n dev
    fi
}

# zdl — fzf picker over Zellij sessions. Enter attaches (resurrecting dead
# ones); Ctrl-X deletes the highlighted session (killing it first if running)
# and refreshes the list, so you can prune several without leaving. Deletion
# works even from inside Zellij; only attaching is blocked when nested.
zdl() {
    command -v fzf >/dev/null || { print -u2 "zdl: fzf not found"; return 1; }
    local sel
    sel=$(
        zellij ls -n 2>/dev/null |
        fzf --no-sort \
            --header='enter: attach   ctrl-x: delete   esc: cancel' \
            --bind 'ctrl-x:execute-silent(zellij delete-session -f {1})+reload(zellij ls -n 2>/dev/null)'
    ) || return
    [[ -n $sel ]] || return
    local name=${sel%% *}
    if [[ -n $ZELLIJ ]]; then
        print -u2 "zdl: inside Zellij — not attaching to '$name' (would nest)"
        return 1
    fi
    zellij attach -f "$name"
}

# Roots that `zp` scans for projects (immediate subdirs become projects).
ZELLIJ_PROJECT_DIRS=(~/dev)

# zp — project → ticket sessionizer. Two stages: pick a project (subdir of
# $ZELLIJ_PROJECT_DIRS), then pick one of its existing `<project>:<ticket>`
# sessions or create a new ticket. Sessions are named `<project>:<ticket>` so
# the flat Zellij namespace reads as project→session. New sessions use
# ~/.config/zellij/layouts/<project>.kdl if it exists, else the `dev` layout.
zp() {
    command -v fzf >/dev/null || { print -u2 "zp: fzf not found"; return 1; }
    [[ -z $ZELLIJ ]] || { print -u2 "zp: run from outside Zellij (can't attach while nested)"; return 1; }
    local proj_path
    proj_path=$(fd --type d --max-depth 1 --min-depth 1 . $ZELLIJ_PROJECT_DIRS 2>/dev/null |
                fzf --prompt='project > ') || return
    [[ -n $proj_path ]] || return
    local proj=${proj_path:t}

    local -a all
    all=(${(f)"$(zellij ls -s 2>/dev/null)"})
    local new='＋ new ticket…'
    local pick
    pick=$(print -l -- "$new" ${(M)all:#${proj}:*} | fzf --prompt="${proj} > ") || return
    [[ -n $pick ]] || return

    local session
    if [[ $pick == $new ]]; then
        local ticket
        read "ticket?ticket (e.g. OT-12935): "
        [[ -n $ticket ]] || { print -u2 "zp: no ticket given"; return 1; }
        session="${proj}:${ticket}"
    else
        session=$pick
    fi

    local layout=dev
    [[ -f ~/.config/zellij/layouts/${proj}.kdl ]] && layout=$proj

    builtin cd -- "$proj_path" || return
    if print -l -- $all | grep -qxF -- "$session"; then
        zellij attach -f "$session"
    else
        zellij -s "$session" -n "$layout"
    fi
}

# zs — flat fzf navigator over ALL sessions (names are `project:ticket`, so
# fuzzy-type a project to filter to its tickets, or a ticket to jump straight).
# Bound to Ctrl-f. Use from a plain terminal; inside Zellij use `Ctrl-o w`.
zs() {
    command -v fzf >/dev/null || { print -u2 "zs: fzf not found"; return 1; }
    [[ -z $ZELLIJ ]] || { print -u2 "zs: already inside Zellij — use Ctrl-o w to switch"; return 1; }
    local sel
    sel=$(zellij ls -n 2>/dev/null |
          fzf --no-sort --prompt='session > ' --header='enter: attach   esc: cancel') || return
    [[ -n $sel ]] || return
    zellij attach -f "${sel%% *}"
}
# Ctrl-f at the prompt → zs (saves any half-typed line, restores it after).
_zs_widget() { zle push-line; BUFFER='zs'; zle accept-line; }
zle -N _zs_widget
bindkey '^F' _zs_widget

# ── Tool env ──────────────────────────────────────────────────────────
export BAT_THEME="Catppuccin Mocha"
# lazydocker → podman's docker-compatible socket
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"
# ssh-agent.service (systemd user) — KeePassXC loads keys into it on unlock
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
# zoxide must init before atuin/starship/syntax-highlighting for our setup;
# its doctor flags that ordering but cd works fine — silence the nag.
export _ZO_DOCTOR=0
# fzf: fd as the engine + Catppuccin Mocha colors
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a --height=40% --layout=reverse --border=rounded"

# ── PATH ──────────────────────────────────────────────────────────────
# ~/.dotnet/tools = global dotnet tools (dotnet-ef, etc.)
path=(~/.local/bin ~/.dotnet/tools $path)
export PATH

# ── Editor ────────────────────────────────────────────────────────────
# nvim when present (full LazyVim setup), nano as the safe fallback.
if command -v nvim >/dev/null; then export EDITOR=nvim VISUAL=nvim; else export EDITOR=nano; fi

# ── Tool hooks (order matters) ────────────────────────────────────────
# .NET SDK provided by mise. Static fallback so DOTNET_ROOT exists even
# outside a mise-managed dir (e.g. terminal-launched Rider); `mise activate`
# below still overrides it per-project.
export DOTNET_ROOT="$HOME/.local/share/mise/dotnet-root"
# Make OpenSSL clients (.NET HttpClient, curl) trust the ASP.NET dev HTTPS cert.
# Must include the Fedora system bundle too, else other TLS verification breaks.
export SSL_CERT_DIR="$HOME/.aspnet/dev-certs/trust:/etc/pki/tls/certs"
# Aspire/DCP overrides SSL_CERT_DIR per-resource with a dev-cert-only temp dir,
# dropping public CA roots → external HTTPS (Azure Service Bus) fails UntrustedRoot.
# DCP leaves SSL_CERT_FILE alone, so pin the system bundle to keep public roots.
export SSL_CERT_FILE="/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
command -v mise    >/dev/null && eval "$(mise activate zsh)"
command -v zoxide  >/dev/null && eval "$(zoxide init zsh --cmd cd)"   # cd = zoxide, cdi = interactive
# fzf keybindings BEFORE atuin so atuin keeps Ctrl-R (fzf gets Ctrl-T / Alt-C)
[[ -r /usr/share/fzf/shell/key-bindings.zsh ]] && source /usr/share/fzf/shell/key-bindings.zsh
[[ -r /usr/share/fzf/shell/completion.zsh ]]   && source /usr/share/fzf/shell/completion.zsh
command -v atuin   >/dev/null && eval "$(atuin init zsh)"
command -v starship >/dev/null && eval "$(starship init zsh)"  # prompt last

# ── Syntax highlighting (must be sourced last) ────────────────────────
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
