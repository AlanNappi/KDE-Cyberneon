#!/bin/bash
# Host side: build the lab image (first time) and run the test; results in lab/out/.
# Needs Docker. Uses the host GPU render node (/dev/dri/renderD*) so KWin can composite with OpenGL.
set -euo pipefail
L="$(cd "$(dirname "$0")" && pwd)"; REPO="$(dirname "$L")"
mkdir -p "$L/out"; rm -f "$L/out"/*
docker build -t cyberneon-kde-lab "$L"
ARGS=(--rm --shm-size=1g --cap-add=SYS_NICE -v "$REPO:/repo:ro" -v "$L/out:/out" -v "$L/inside.sh:/inside.sh:ro")
for r in /dev/dri/renderD*; do [ -e "$r" ] && ARGS+=(--device "$r" --group-add "$(stat -c %g "$r")"); done
[ -d "$HOME/.local/share/icons/Papirus-Dark" ] && ARGS+=(-v "$HOME/.local/share/icons:/hosticons:ro")
docker run "${ARGS[@]}" cyberneon-kde-lab dbus-run-session -- bash /inside.sh
echo "results: $L/out"
