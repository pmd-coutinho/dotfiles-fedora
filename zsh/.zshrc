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
alias ll='ls -lah --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ip='ip -color=auto'

# ── PATH ──────────────────────────────────────────────────────────────
path=(~/.local/bin $path)
export PATH

# ── Tool hooks (order matters: starship last) ─────────────────────────
command -v mise    >/dev/null && eval "$(mise activate zsh)"
command -v zoxide  >/dev/null && eval "$(zoxide init zsh)"
command -v atuin   >/dev/null && eval "$(atuin init zsh)"
command -v starship >/dev/null && eval "$(starship init zsh)"

# ── Syntax highlighting (must be sourced last) ────────────────────────
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
