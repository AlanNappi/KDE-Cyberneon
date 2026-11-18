#!/bin/bash
# Host side: build the lab image (first time) and run the test; results in lab/out/.
# usage: run-lab.sh [reactive]   "reactive" runs only the install and the reactive HUD tests.
# Needs Docker. Uses the host GPU render node (/dev/dri/renderD*) so KWin can composite with OpenGL.
set -euo pipefail
L="$(cd "$(dirname "$0")" && pwd)"; REPO="$(dirname "$L")"
mkdir -p "$L/out"; rm -rf "$L/out"/* 2>/dev/null || docker run --rm -v "$L/out:/out" archlinux:latest sh -c "rm -rf /out/*"
docker build -t cyberneon-kde-lab "$L"
ARGS=(--rm --shm-size=1g --cap-add=SYS_NICE -v "$REPO:/repo:ro" -v "$L/out:/out" -v "$L/inside.sh:/inside.sh:ro")
for r in /dev/dri/renderD*; do [ -e "$r" ] && ARGS+=(--device "$r" --group-add "$(stat -c %g "$r")"); done
[ -d "$HOME/.local/share/icons/Papirus-Dark" ] && ARGS+=(-v "$HOME/.local/share/icons:/hosticons:ro")
# a second container streams data, so the lab has real network traffic and a real remote connection
PEER=cyberneon-lab-peer; docker rm -f "$PEER" >/dev/null 2>&1 || true
docker run -d --rm --name "$PEER" cyberneon-kde-lab python3 -c '
import socket, threading, time
s = socket.create_server(("", 8443))
def feed(c):
    try:
        while True: c.sendall(bytes(1 << 20)); time.sleep(0.05)
    except OSError: pass
while True: threading.Thread(target=feed, args=(s.accept()[0],), daemon=True).start()' >/dev/null
trap 'docker rm -f "$PEER" >/dev/null 2>&1 || true' EXIT
ARGS+=(-e LAB_MODE="${1:-full}" -e LAB_STOP="${LAB_STOP:-}" -e LAB_PEER="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$PEER")")
docker run "${ARGS[@]}" cyberneon-kde-lab dbus-run-session -- bash /inside.sh
echo "results: $L/out"
