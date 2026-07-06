# ~/.zshenv — sourced by ALL zsh invocations (login, non-login, interactive,
# and non-interactive), unlike .zshrc which is interactive-only.
#
# Put mise's shim directory on PATH here so mise-managed tools (yarn, node,
# dotnet, …) resolve even when `mise activate` in .zshrc never runs — e.g. a
# GUI/Toolbox-launched Rider, or the brief non-interactive shell JetBrains uses
# to import the environment. Shims dispatch to the active tool version without
# needing `mise activate` or its per-prompt hook-env, so this is the reliable
# path for non-interactive consumers like Aspire's DCP spawning `yarn`.
export PATH="$HOME/.local/share/mise/shims:$PATH"
