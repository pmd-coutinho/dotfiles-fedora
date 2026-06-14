#!/usr/bin/env bash
# JetBrains Toolbox installer (user-level, no root). Run: bash ~/dotfiles/install-toolbox.sh
# Toolbox then manages Rider (and any other JetBrains IDE) + updates.
set -euo pipefail
DEST="$HOME/.local/share/JetBrains/Toolbox/bin"
if [ -x "$DEST/jetbrains-toolbox" ]; then
    echo "Toolbox already installed at $DEST — launching."
else
    echo "Resolving latest Toolbox release..."
    URL=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" \
          | python3 -c "import json,sys; print(json.load(sys.stdin)['TBA'][0]['downloads']['linux']['link'])")
    echo "Downloading $URL"
    mkdir -p "$DEST"
    curl -fsSL "$URL" -o /tmp/toolbox.tar.gz
    tar -xzf /tmp/toolbox.tar.gz -C /tmp
    # Copy the ENTIRE bin/ payload — the launcher needs its bundled jre/ + lib/
    # alongside it (copying only the binary => "Failed to start JVM").
    cp -r /tmp/jetbrains-toolbox-*/bin/. "$DEST/"
    echo "Installed to $DEST"
fi
echo "Launching Toolbox — in its window, install Rider. It self-registers a .desktop entry."
setsid "$DEST/jetbrains-toolbox" >/dev/null 2>&1 &
echo "Done. Rider will appear in walker once Toolbox finishes installing it."
