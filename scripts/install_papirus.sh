#!/bin/bash
# Install Papirus / Papirus-Dark (GPL-3) into ~/.local/share/icons from GitHub (pinned release)
# and add a "cyber" folder colour (cyan front, petrol back, navy symbol, red sheet) that becomes the
# default folder colour. Skips the download when Papirus-Dark with the cyber colour is already there.
set -euo pipefail
ICONS="$HOME/.local/share/icons"
if [ -e "$ICONS/Papirus-Dark/64x64/places/folder-cyber.svg" ]; then
    echo "papirus: already installed with cyber folders"; exit 0
fi
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
# pinned to the release this setup was made with (PAPIRUS_TAG=latest to take the newest one)
TAG="${PAPIRUS_TAG:-20260801}"
if [ "$TAG" = latest ]; then
    TAG=$(curl -sSf --max-time 20 https://api.github.com/repos/PapirusDevelopmentTeam/papirus-icon-theme/releases/latest \
          | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')
fi
echo "papirus: downloading release $TAG"
curl -sSfL --max-time 600 -o "$TMP/papirus.tar.gz" \
    "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/refs/tags/$TAG.tar.gz"
mkdir -p "$TMP/x" "$ICONS"
tar -xzf "$TMP/papirus.tar.gz" -C "$TMP/x" --strip-components=1 --wildcards '*/Papirus/*' '*/Papirus-Dark/*' '*/LICENSE'
rm -rf "$ICONS/Papirus" "$ICONS/Papirus-Dark"
cp -a "$TMP/x/Papirus" "$TMP/x/Papirus-Dark" "$ICONS/"
cp "$TMP/x/LICENSE" "$ICONS/Papirus/"

python3 -I - "$ICONS" <<'PY'
import os, re, sys
from pathlib import Path
MAP = {"#00bcd4": "#3fd8c8", "#0096aa": "#22968c", "#00424a": "#0b1620", "#e4e4e4": "#fb3048"}
base = Path(sys.argv[1]); made = relinked = 0
for theme in ("Papirus", "Papirus-Dark"):
    for places in sorted((base / theme).glob("*/places")):
        for n in os.listdir(places):                      # 1. cyber variants from the cyan ones
            if "-cyan" not in n:
                continue
            src, new = places / n, places / n.replace("-cyan", "-cyber", 1)
            if new.exists() or new.is_symlink():
                continue
            if src.is_symlink():
                os.symlink(os.readlink(src).replace("-cyan", "-cyber", 1), new)
            else:
                t = src.read_text()
                for a, b in MAP.items():
                    t = re.sub(a, b, t, flags=re.I)
                new.write_text(t)
            made += 1
        for n in os.listdir(places):                      # 2. default (blue) links -> cyber
            p = places / n
            if not p.is_symlink() or "-blue" in n:
                continue
            tgt = os.readlink(p)
            if "-blue" in tgt and (places / tgt.replace("-blue", "-cyber", 1)).exists():
                p.unlink(); os.symlink(tgt.replace("-blue", "-cyber", 1), p); relinked += 1
print(f"papirus: {made} cyber icons, {relinked} links")
PY
for t in Papirus Papirus-Dark; do gtk-update-icon-cache -q -f -t "$ICONS/$t" || true; done
echo "papirus ok"
