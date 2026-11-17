#!/bin/bash
# CyberNeon: SDDM login theme (KDE Plasma 6). FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED.
# Run ./install.sh first (it builds the assets), then:  sudo bash system/install-sddm.sh
# Preview without changing anything:  sddm-greeter-qt6 --test-mode --theme kde/sddm/cyberneon
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
REPO="$(cd "$(dirname "$0")/.." && pwd)"
U="$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)"
A="$U/.local/share/cyberneon/system"
[ -f "$A/cyberneon-login.png" ] || { echo "assets not found in $A: run ./install.sh as your user first"; exit 1; }

T=/usr/share/sddm/themes/cyberneon
rm -rf "$T"; install -d "$T"
install -m644 "$REPO"/kde/sddm/cyberneon/* "$T/"
install -m644 "$A/cyberneon-login.png" "$T/background.png"

rm -rf /usr/share/icons/CyberNeon-Cursors
cp -r "$U/.local/share/icons/CyberNeon-Cursors" /usr/share/icons/CyberNeon-Cursors
chown -R root:root /usr/share/icons/CyberNeon-Cursors; chmod -R a+rX /usr/share/icons/CyberNeon-Cursors "$T"
install -d /usr/local/share/fonts/cyberneon
install -m644 "$U"/.local/share/fonts/cyberneon/*.ttf /usr/local/share/fonts/cyberneon/
fc-cache -f /usr/local/share/fonts/cyberneon >/dev/null

install -d /etc/sddm.conf.d
cat > /etc/sddm.conf.d/10-cyberneon.conf <<'CONF'
[Theme]
Current=cyberneon
CursorTheme=CyberNeon-Cursors
CursorSize=24
CONF
echo "OK: SDDM theme installed (visible at the next logout / reboot)."
echo "undo: sudo rm /etc/sddm.conf.d/10-cyberneon.conf"
