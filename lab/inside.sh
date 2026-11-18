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

# test doubles: a journal containing a secret (it must never reach the screen) and a sound player that only logs
mkdir -p /tmp/stubs
cat > /tmp/stubs/journalctl <<'EOF'
#!/bin/bash
now=$(date +%s)
for p in "6 kwin_wayland" "4 NetworkManager" "3 sshd" "6 systemd"; do
    set -- $p; now=$((now+1))
    echo "{\"__REALTIME_TIMESTAMP\":\"${now}000000\",\"PRIORITY\":\"$1\",\"SYSLOG_IDENTIFIER\":\"$2\",\"MESSAGE\":\"SECRET-JOURNAL-TEXT user@example.org\"}"
done
EOF
printf '#!/bin/bash\necho "$(date +%%T) $*" >> /out/sfx.log\n' > /tmp/stubs/paplay
chmod +x /tmp/stubs/*; export PATH=/tmp/stubs:$PATH

log "starting kwin_wayland (virtual 1920x1080)"
QT_LOGGING_RULES="kwin_scripting.debug=true;js.debug=true" kwin_wayland --virtual --width 1920 --height 1080 --xwayland --socket wayland-cyberneon --no-lockscreen \
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
sed -i 's/^SOUND_FX=.*/SOUND_FX="yes"/' ~/cyberneon-kde/cyberneon.conf
cd ~/cyberneon-kde && ./install.sh > "$OUT/install.log" 2>&1; echo "install exit: $?" >> "$OUT/install.log"
sleep 50
shot 02-cyberneon-desktop
log "desktop frames for the GIF"
mkdir -p "$OUT/gif"
for i in $(seq -w 1 14); do spectacle -b -n -f -o "$OUT/gif/desk-$i.png" >/dev/null 2>&1; done
cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc "$OUT/appletsrc.txt" 2>/dev/null
cp ~/.config/plasmashellrc "$OUT/plasmashellrc.txt" 2>/dev/null

wallpaper_diff() {   # compares the area around the sigil (only the wallpaper moves there)
    magick compare -metric AE \( "$OUT/$1.png" -crop 640x670+660+170 +repage \) \( "$OUT/$2.png" -crop 640x670+660+170 +repage \) null: 2>> "$OUT/mocks.txt"
    echo " wallpaper px differ $3 (2.5 s apart)" >> "$OUT/mocks.txt"
}

reactive_tests() {
    osd() { local m=$1; shift; call org.kde.plasmashell /org/kde/osdService "org.kde.osdService.$m" "$@" >/dev/null 2>&1; }
    log "reactive: live terminal, no battery, no TUXEDO Control Center"
    python3 -c "
import socket, time, os
c = socket.create_connection((os.environ['LAB_PEER'], 8443)); e = time.time() + 26
while time.time() < e: c.recv(1 << 20)" &
    local client=$!
    sleep 12
    shot 11-live-terminal-trace
    wait $client
    sleep 7
    shot 12-live-terminal
    { echo "--- cn-netlog"; ~/.local/share/cyberneon/bin/cn-netlog; } > "$OUT/netlog.txt" 2>&1

    log "reactive: Quickhack OSD"
    osd volumeChanged 42 100; sleep 0.8; shot 13-osd-volume
    sleep 2.2; shot 13-osd-hidden
    osd brightnessChanged 70; sleep 0.8; shot 14-osd-brightness; sleep 2.2
    osd kbdLayoutChanged "it"; sleep 0.8; shot 15-osd-text; sleep 2.2
    osd volumeChanged 0 100; sleep 0.8; shot 16-osd-muted; sleep 2.2
    for v in 10 20 30 40 50 60 70 80; do osd volumeChanged $v 100; sleep 0.03; done; sleep 0.2; shot 17-osd-burst; sleep 2.2

    [ "${LAB_STOP:-}" = osd ] && return
    log "reactive: notification sound (twice: the second is throttled)"
    for i in 1 2; do call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications.Notify \
        "CyberNeon" 0 "dialog-information" "INCOMING CALL // FIXER" "SECRET-NOTIFICATION-TEXT" "[]" "{}" 3000 >/dev/null 2>&1; sleep 0.5; done
    sleep 2

    log "reactive: alert mode (real CPU load at lowest priority)"
    local pids=() n
    mkdir -p "$OUT/gif"
    for n in $(seq "$(nproc)"); do nice -n 19 sh -c 'while :; do :; done' & pids+=($!); done
    sleep 9
    shot 18-alert
    for i in 1 2 3 4 5 6; do spectacle -b -n -f -o "$OUT/gif/alert-$i.png" >/dev/null 2>&1; done
    echo "kwinrc during alert: $(kreadconfig6 --file kwinrc --group Effect-cyberneon_glitch --key Alert)" > "$OUT/alert.txt"
    kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 10
    call org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1; sleep 1.5
    konsole --separate --workdir /tmp > /dev/null 2>&1 & local kpid=$!
    sleep 1.4; shot 19-alert-window-glitch; sleep 7; kill $kpid 2>/dev/null
    kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 1
    call org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1
    kill "${pids[@]}" 2>/dev/null; wait "${pids[@]}" 2>/dev/null
    sleep 14
    echo "kwinrc after load: $(kreadconfig6 --file kwinrc --group Effect-cyberneon_glitch --key Alert)" >> "$OUT/alert.txt"
    grep -E "cyberneon_glitch: (alert|shader)" "$OUT/kwin.log" | tail -6 >> "$OUT/alert.txt"
    shot 20-after-alert

    log "reactive: fake battery + TUXEDO Control Center on a private system bus"
    dbus-daemon --session --address=unix:path=/tmp/sysbus --nofork --nopidfile > /dev/null 2>&1 &
    sleep 1; export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/sysbus
    dbus-update-activation-environment DBUS_SYSTEM_BUS_ADDRESS 2>/dev/null
    python3 -m dbusmock --system --template upower > "$OUT/mock-upower.log" 2>&1 &
    python3 -m dbusmock --system com.tuxedocomputers.tccd /com/tuxedocomputers/tccd com.tuxedocomputers.tccd > "$OUT/mock-tcc.log" 2>&1 &
    sleep 3
    sysc() { gdbus call --system --dest "$1" --object-path "$2" --method "$3" "${@:4}"; }
    local bat
    bat=$(sysc org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.DBus.Mock.AddDischargingBattery mock_BAT Stellaris 62.0 7200 | grep -oE "/org/[^']+")
    busctl --system call com.tuxedocomputers.tccd /com/tuxedocomputers/tccd org.freedesktop.DBus.Mock AddMethod sssss \
        com.tuxedocomputers.tccd GetActiveProfileJSON "" s 'ret = "{\"id\":\"lab\",\"name\":\"Cool and breezy\"}"'
    { echo "battery object: $bat"; echo "cn-tcc: $(~/.local/share/cyberneon/bin/cn-tcc)"; } > "$OUT/mocks.txt"
    kquitapp6 plasmashell >/dev/null 2>&1; sleep 3
    plasmashell > "$OUT/plasmashell2.log" 2>&1 &
    sleep 30
    shot 21-battery
    log "reactive: battery at 15% -> low power"
    sysc org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.DBus.Mock.SetDeviceProperties "$bat" "{'Percentage': <15.0>, 'Energy': <7.5>}" >> "$OUT/mocks.txt" 2>&1
    sleep 6
    shot 22-lowpower-a; sleep 2.5; shot 22-lowpower-b
    wallpaper_diff 22-lowpower-a 22-lowpower-b "at low power"
    sysc org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.DBus.Mock.SetDeviceProperties "$bat" "{'Percentage': <62.0>, 'Energy': <30.0>}" >/dev/null 2>&1
    sleep 6
    shot 23-power-a; sleep 2.5; shot 23-power-b
    wallpaper_diff 23-power-a 23-power-b "on normal power"

    log "reactive: lock screen must not show live data"
    /usr/lib/kscreenlocker_greet --testing > "$OUT/locker-reactive.log" 2>&1 &
    sleep 8; shot 24-lockscreen-terminal; pkill -f kscreenlocker_greet 2>/dev/null
    { echo "--- plasmarc OSD: $(kreadconfig6 --file plasmarc --group OSD --key Enabled)"
      echo "--- sound theme: $(kreadconfig6 --file kdeglobals --group Sounds --key Theme)"; ls ~/.local/share/sounds/cyberneon/stereo
      echo "--- autostart"; cat ~/.config/autostart/cyberneon-jackin.desktop
      echo "--- sfx log"; cat "$OUT/sfx.log" 2>/dev/null
      echo "--- secrets leaked into logs/commands:"; grep -l "SECRET-" "$OUT"/netlog.txt "$OUT"/plasmashell*.log 2>/dev/null
      echo "--- helpers still running"; pgrep -c -f cn-bus-watch; } > "$OUT/reactive.txt" 2>&1
}

if [ "${LAB_MODE:-full}" = reactive ]; then
    reactive_tests
    grep -iE "cyberneon|qml.*error|TypeError|ReferenceError" "$OUT/plasmashell.log" "$OUT/plasmashell2.log" | tail -40 > "$OUT/plasmashell-errors.txt"
    chmod -R a+rwX "$OUT"; log "done (reactive)"; exit 0
fi

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

reactive_tests

log "qmllint"
/usr/lib/qt6/bin/qmllint "$HOME"/cyberneon-kde/kde/plasmoids/*/contents/ui/main.qml \
    "$HOME"/cyberneon-kde/kde/shared/*.qml "$HOME"/cyberneon-kde/kde/tabbox/cyberneon/contents/ui/main.qml \
    "$HOME"/cyberneon-kde/kde/sddm/cyberneon/Main.qml > "$OUT/qmllint.txt" 2>&1; echo "qmllint exit: $?" >> "$OUT/qmllint.txt"
grep -iE "cyberneon|qml.*error|TypeError|ReferenceError" "$OUT/plasmashell.log" "$OUT/plasmashell2.log" | tail -40 > "$OUT/plasmashell-errors.txt"
chmod -R a+rwX "$OUT"
log "done"
