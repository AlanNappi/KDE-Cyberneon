#!/bin/bash
# Runs inside the lab container (under dbus-run-session): headless Plasma 6 (KWin virtual backend, OpenGL on the
# host render node), stock screenshot, real install.sh, CyberNeon screenshots, SDDM test mode, qmllint.
set -u
OUT=/out
export XDG_RUNTIME_DIR=/tmp/xdg-netrunner; mkdir -p -m 700 "$XDG_RUNTIME_DIR"
export XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=KDE XDG_SESSION_DESKTOP=KDE KDE_FULL_SESSION=true KDE_SESSION_VERSION=6
export QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=wayland-cyberneon SHELL=/bin/bash
shot() { spectacle -b -n -f -o "$OUT/$1.png" >/dev/null 2>&1; sleep 1
         magick "$OUT/$1.png" -format "  $1.png %wx%h colors=%k\n" info: 2>/dev/null || echo "  screenshot $1 failed"; }
log() { echo "[lab $(date +%T)] $*"; }

log "starting kwin_wayland (virtual 1920x1080)"
kwin_wayland --virtual --width 1920 --height 1080 --xwayland --socket wayland-cyberneon --no-lockscreen \
    > "$OUT/kwin.log" 2>&1 &
sleep 10
export DISPLAY=:0
dbus-update-activation-environment --all 2>/dev/null   # D-Bus activated KDE services need the Wayland env
/usr/lib/kactivitymanagerd > /dev/null 2>&1 &
kded6 > /dev/null 2>&1 &
ksystemstats > /dev/null 2>&1 &
sleep 2
log "starting plasmashell"
plasmashell > "$OUT/plasmashell.log" 2>&1 &
sleep 40
shot 01-plasma-stock

log "installing CyberNeon (real install.sh)"
mkdir -p ~/.local/share/icons
[ -d /hosticons/Papirus-Dark ] && cp -r /hosticons/Papirus /hosticons/Papirus-Dark ~/.local/share/icons/
cp -r /repo ~/cyberneon-kde && rm -rf ~/cyberneon-kde/lab
cd ~/cyberneon-kde && ./install.sh > "$OUT/install.log" 2>&1; echo "install exit: $?" >> "$OUT/install.log"
sleep 45
shot 02-cyberneon-desktop
sleep 1.5
shot 02b-cyberneon-desktop-later
cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc "$OUT/appletsrc.txt" 2>/dev/null
{ for n in cyberneon-launcher cyberneon-logo; do echo "$n -> $(QT_QPA_PLATFORM=offscreen kiconfinder6 $n 2>&1 | tail -1)"; done; } > "$OUT/icons.txt"

log "opening Konsole and Dolphin (Dolphin last = focused)"
konsole --workdir "$HOME/cyberneon-kde" > /dev/null 2>&1 &
sleep 8
dolphin --new-window "$HOME/cyberneon-kde" > /dev/null 2>&1 &
sleep 12
shot 03-cyberneon-windows

log "launcher menu (Plasma popup) + effect check"
gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.activateLauncherMenu >/dev/null 2>&1
sleep 4
shot 06-launcher-menu
gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.activateLauncherMenu >/dev/null 2>&1
sleep 1
{ echo "cyberneon_glitch loaded: $(gdbus call --session --dest org.kde.KWin --object-path /Effects --method org.kde.kwin.Effects.isEffectLoaded cyberneon_glitch 2>&1)";
  echo "scale loaded: $(gdbus call --session --dest org.kde.KWin --object-path /Effects --method org.kde.kwin.Effects.isEffectLoaded scale 2>&1)";
  echo "decoration: $(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme)"; } > "$OUT/effects.txt"

log "splash test"
ksplashqml --test --window org.cyberneon.desktop > "$OUT/splash.log" 2>&1 &
sleep 4
shot 05-splash
pkill -f ksplashqml 2>/dev/null

log "SDDM greeter test mode"
sddm-greeter-qt6 --test-mode --theme "$HOME/cyberneon-kde/kde/sddm/cyberneon" > "$OUT/sddm.log" 2>&1 &
sleep 12
shot 04-sddm-test
pkill -f sddm-greeter 2>/dev/null

log "qmllint"
/usr/lib/qt6/bin/qmllint "$HOME"/cyberneon-kde/kde/plasmoids/*/contents/ui/main.qml \
    "$HOME"/cyberneon-kde/kde/sddm/cyberneon/Main.qml > "$OUT/qmllint.txt" 2>&1; echo "qmllint exit: $?" >> "$OUT/qmllint.txt"
log "done"
