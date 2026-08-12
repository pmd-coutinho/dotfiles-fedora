#!/usr/bin/env bash
# Regenerate emoji.tsv — the data behind `fz-emoji` (Mod+E).
# Format: <char>TAB<name>. fz-emoji shows both columns and copies column 1.
#
# Emoji come from the Unicode "fully-qualified" test set (the ones that render).
# The curated SYMBOLS block below is the source of truth for the non-emoji
# glyphs (arrows, maths, punctuation, currency) — edit it here, then run this
# script and `git diff` the result.
set -euo pipefail
cd "$(dirname "$0")"
out=emoji.tsv

symbols() {
  # <char><TAB><searchable name>
  printf '%s\n' \
"→	arrow right" "←	arrow left" "↑	arrow up" "↓	arrow down" \
"↔	arrow left right" "⇒	double arrow right" "⇐	double arrow left" \
"⟶	long arrow right" "—	em dash" "–	en dash" "•	bullet" "·	middle dot" \
"…	ellipsis" "«	left angle quote" "»	right angle quote" \
"“	left double quote" "”	right double quote" "‘	left single quote" \
"’	right single quote apostrophe" "′	prime" "″	double prime" \
"×	multiplication times" "÷	division" "±	plus minus" \
"≈	approximately equal" "≠	not equal" "≤	less than or equal" \
"≥	greater than or equal" "∞	infinity" "√	square root" "∑	sum sigma" \
"∏	product" "∫	integral" "∂	partial derivative" "∆	delta increment" \
"π	pi" "µ	micro mu" "°	degree" "Ω	ohm omega" "€	euro" \
"£	pound sterling" "¥	yen" "¢	cent" "©	copyright" "®	registered" \
"™	trademark" "§	section" "¶	pilcrow paragraph" "†	dagger" \
"‡	double dagger" "★	star filled" "☆	star outline" "✓	check tick" \
"✗	cross ballot x" "✔	heavy check" "№	numero" "℃	degrees celsius" \
"℉	degrees fahrenheit"
}

{
  echo "# emoji + symbol data for fz-emoji — <char>TAB<name>."
  echo "# Regenerate: fuzzel/.config/fuzzel/regen-emoji.sh"
  curl -fsSL --max-time 20 "https://unicode.org/Public/emoji/latest/emoji-test.txt" \
    | awk -F'#' '/; fully-qualified/ {
        s=$2; sub(/^ /,"",s);
        n=index(s," "); ch=substr(s,1,n-1); rest=substr(s,n+1);
        sub(/^E[0-9.]+ /,"",rest);
        printf "%s\t%s\n", ch, rest;
      }'
  symbols
} > "$out"
echo "wrote $out ($(wc -l < "$out") lines)"
