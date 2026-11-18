#!/bin/bash
# Runs inside the lab container (under dbus-run-session): headless Plasma 6 (KWin virtual backend, OpenGL on the
# host render node), stock screenshot, real install.sh, then screenshots of every CyberNeon part:
# desktop (+ frames for a GIF), windows, glitch effect mid-animation, Alt+Tab, launcher, notification,
# lock screen, splash, SDDM; plus qmllint and effect checks.
set -u
OUT=/out
export XDG_RUNTIME_DIR=/tmp/xdg-netrunner; mkdir -p -m 700 "$XDG_RUNTIME_DIR"
export XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=KDE XDG_SESSION_DESKTOP=KDE KDE_FULL_SESSION=true KDE_SESSION_VERSION=6
export QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=wayland-cyberneon SHELL=/bin/bash QT_FORCE_STDERR_LOGGING=1
shot() { spectacle -b -n -f -o "$OUT/$1.png" >/dev/null 2>&1; sleep 0.3
         magick "$OUT/$1.png" -format "  $1.png %wx%h colors=%k\n" info: 2>/dev/null || echo "  screenshot $1 failed"; }
log() { echo "[lab $(date +%T)] $*"; }
call() { gdbus call --session --dest "$1" --object-path "$2" --method "$3" "${@:4}"; }

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
cp -rL /repo ~/cyberneon-kde && rm -rf ~/cyberneon-kde/lab
cd ~/cyberneon-kde && ./install.sh > "$OUT/install.log" 2>&1; echo "install exit: $?" >> "$OUT/install.log"
sleep 50
shot 02-cyberneon-desktop
log "desktop frames for the GIF"
mkdir -p "$OUT/gif"
for i in $(seq -w 1 14); do spectacle -b -n -f -o "$OUT/gif/desk-$i.png" >/dev/null 2>&1; done
cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc "$OUT/appletsrc.txt" 2>/dev/null
cp ~/.config/plasmashellrc "$OUT/plasmashellrc.txt" 2>/dev/null

log "notification (bottom-left)"
call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications.Notify \
    "CyberNeon" 0 "dialog-information" "INCOMING CALL // FIXER" "New gig available in your district. Meet at the usual place." \
    "[]" "{}" 20000 >/dev/null 2>&1
sleep 2.5
shot 09-notification

log "opening Konsole and Dolphin (Dolphin last = focused)"
konsole --workdir "$HOME/cyberneon-kde" > /dev/null 2>&1 &
sleep 8
dolphin --new-window "$HOME/cyberneon-kde" > /dev/null 2>&1 &
sleep 12
shot 03-cyberneon-windows

log "glitch effect mid-animation (animations slowed down 12x)"
kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 12
call org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1; sleep 2
konsole --separate --workdir /tmp > /dev/null 2>&1 &
sleep 1.0
shot 07-glitch-open
sleep 8
kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 1
call org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1; sleep 2

log "Alt+Tab switcher (KWin's own switcher preview tool, sample windows)"
/usr/lib/kwin-tabbox-preview "$HOME/.local/share/kwin/tabbox/cyberneon/contents/ui/main.qml" > "$OUT/tabbox.log" 2>&1 &
sleep 5
shot 08-alttab
pkill -f kwin-tabbox-preview 2>/dev/null; sleep 1

log "launcher (Plasma popup)"
call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu >/dev/null 2>&1
sleep 4
shot 06-launcher-menu
call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu >/dev/null 2>&1
sleep 1
{ for e in cyberneon_glitch scale blur contrast; do
    echo "$e loaded: $(call org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded $e 2>&1)"; done
  echo "decoration: $(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme)"
  echo "tabbox: $(kreadconfig6 --file kwinrc --group TabBox --key LayoutName)"
  grep -iE "glitch|shader|cyberneon|tabbox" "$OUT/kwin.log" | tail -20; } > "$OUT/effects.txt"

log "lock screen (greeter test mode)"
/usr/lib/kscreenlocker_greet --testing > "$OUT/locker.log" 2>&1 &
sleep 8
shot 10-lockscreen
pkill -f kscreenlocker_greet 2>/dev/null

log "splash test"
ksplashqml --test --window org.cyberneon.desktop > "$OUT/splash.log" 2>&1 &
sleep 5
shot 05-splash
pkill -f ksplashqml 2>/dev/null

log "SDDM greeter test mode"
mkdir -p /tmp/sddmtheme && cp -rL "$HOME/cyberneon-kde/kde/sddm/cyberneon/." /tmp/sddmtheme/
cp "$HOME/.local/share/cyberneon/system/cyberneon-wallpaper.png" /tmp/sddmtheme/background.png 2>/dev/null
sddm-greeter-qt6 --test-mode --theme /tmp/sddmtheme > "$OUT/sddm.log" 2>&1 &
sleep 12
shot 04-sddm-test
pkill -f sddm-greeter 2>/dev/null

log "qmllint"
/usr/lib/qt6/bin/qmllint "$HOME"/cyberneon-kde/kde/plasmoids/*/contents/ui/main.qml \
    "$HOME"/cyberneon-kde/kde/shared/CyberNeonLive.qml "$HOME"/cyberneon-kde/kde/tabbox/cyberneon/contents/ui/main.qml \
    "$HOME"/cyberneon-kde/kde/sddm/cyberneon/Main.qml > "$OUT/qmllint.txt" 2>&1; echo "qmllint exit: $?" >> "$OUT/qmllint.txt"
grep -iE "cyberneon|qml.*error|TypeError|ReferenceError" "$OUT/plasmashell.log" | tail -40 > "$OUT/plasmashell-errors.txt"
chmod -R a+rwX "$OUT"
log "done"
