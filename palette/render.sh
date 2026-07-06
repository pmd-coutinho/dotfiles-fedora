#!/usr/bin/env bash
# Render theme templates (*.in) from the canonical Catppuccin palette.
#   render.sh           render every *.in in the repo to its target (drop .in)
#   render.sh --check   verify each target matches its template (no write); the
#                       pre-commit hook calls this so colours can't drift.
# Only ${ctp_*} variables are substituted, so any other ${...} in a config is
# left untouched.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dots="$(cd "$here/.." && pwd)"

set -a; . "$here/catppuccin-mocha.env"; set +a
vars="$(grep -oE '^ctp_[a-z0-9]+' "$here/catppuccin-mocha.env" | sed 's/^/$/' | tr '\n' ' ')"

# Zellij layouts share one zjstatus tab-bar block: colour-resolve the fragment,
# then let layout templates pull it in as ${zjstatus_tabbar}.
zjstatus_tabbar="$(envsubst "$vars" < "$dots/zellij/.config/zellij/layouts/_zjstatus-tabbar.kdl")"
export zjstatus_tabbar
vars="$vars \$zjstatus_tabbar"

mode="${1:-render}"
fail=0
while IFS= read -r t; do
    target="${t%.in}"
    if [[ $mode == --check ]]; then
        diff -q <(envsubst "$vars" < "$t") "$target" >/dev/null 2>&1 \
            || { echo "render: $target out of sync with $(basename "$t") — run palette/render.sh" >&2; fail=1; }
    else
        envsubst "$vars" < "$t" > "$target"
        echo "rendered ${target#"$dots"/}"
    fi
done < <(find "$dots" -name '*.in' -not -path '*/.git/*')
exit $fail
