#!/bin/bash
# CyberNeon: GRUB boot menu theme. Also makes the menu visible for 5 seconds at boot
# (Ubuntu hides it by default with timeout 0, so a theme would never be seen).
# Run ./install.sh first (it builds the assets), then:  sudo bash system/install-grub.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
U="$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)"
A="$U/.local/share/cyberneon/system/grub"
[ -f "$A/theme.txt" ] || { echo "assets not found in $A: run ./install.sh as your user first"; exit 1; }
ls "$A"/*.pf2 >/dev/null 2>&1 || { echo "GRUB fonts missing (grub-mkfont): install grub-common and rerun ./install.sh"; exit 1; }

install -d /boot/grub/themes/cyberneon
install -m644 "$A"/* /boot/grub/themes/cyberneon/

[ -f /etc/default/grub.bak-cyberneon ] || cp /etc/default/grub /etc/default/grub.bak-cyberneon
set_key() {
    if grep -qE "^#?[[:space:]]*$1=" /etc/default/grub; then
        sed -i -E "s|^#?[[:space:]]*$1=.*|$1=$2|" /etc/default/grub
    else
        echo "$1=$2" >> /etc/default/grub
    fi
}
set_key GRUB_THEME '"/boot/grub/themes/cyberneon/theme.txt"'
set_key GRUB_TIMEOUT_STYLE menu
set_key GRUB_TIMEOUT 5
set_key GRUB_GFXMODE '1920x1080,auto'
sed -i -E 's|^GRUB_TERMINAL=console|#GRUB_TERMINAL=console|' /etc/default/grub

update-grub
echo "OK: GRUB theme installed (menu visible for 5 seconds at boot)."
echo "undo: sudo cp /etc/default/grub.bak-cyberneon /etc/default/grub && sudo update-grub"
