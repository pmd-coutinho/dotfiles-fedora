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
