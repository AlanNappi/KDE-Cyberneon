#!/bin/bash
# Install the fonts used by CyberNeon (Chakra Petch, Rajdhani, Orbitron - SIL Open Font License)
# from assets/fonts into ~/.local/share/fonts/cyberneon.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
D="$HOME/.local/share/fonts/cyberneon"
mkdir -p "$D"
cp -f "$REPO"/assets/fonts/*.ttf "$REPO"/assets/fonts/OFL-*.txt "$D/"
fc-cache -f "$D" >/dev/null
echo "fonts ok: $D"
