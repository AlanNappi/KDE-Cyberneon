#!/bin/bash
# FAN MADE by a huge fan - inspired by Cyberpunk 2077 by CD PROJEKT RED. Cyberpunk 2077, Arasaka and all
# related names/logos/trademarks belong to CD PROJEKT S.A. Unofficial, non-commercial, not endorsed by CD PROJEKT RED.
# CyberNeon for KDE Plasma 6 (X11 and Wayland) - user-level installer (login screen and GRUB: system/*.sh).
#
#   ./install.sh                 install / update everything (reads cyberneon.conf)
#   ./install.sh --no-layout     keep your panels and widgets (don't run kde/layout.js)
#   ./install.sh --skip-papirus  don't download the Papirus icon theme
#   ./install.sh -h
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SC="$REPO/scripts"
LAYOUT=1; PAPIRUS=1
for arg in "$@"; do
    case "$arg" in
        --no-layout) LAYOUT=0 ;;
        --skip-papirus) PAPIRUS=0 ;;
        -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
        *) echo "unknown option: $arg"; exit 1 ;;
    esac
done

# ------------------------------------------------------------------ config
LOGO=""; LABEL="N E T R U N N E R"; HUD_LABEL=""; WALLPAPER="cyberneon.png"; DOLPHIN_OPACITY=90
PINNED="applications:systemsettings.desktop,preferred://filemanager,preferred://browser,applications:org.kde.konsole.desktop,applications:libreoffice-calc.desktop"
UI_FONT="Chakra Petch,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1"
FIXED_FONT="JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
TITLE_FONT="Chakra Petch,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
# shellcheck source=cyberneon.conf
[ -f "$REPO/cyberneon.conf" ] && . "$REPO/cyberneon.conf"
[ -n "$LOGO" ] && [ "${LOGO:0:1}" != "/" ] && LOGO="$REPO/$LOGO"
if [ -n "$LOGO" ] && [ ! -f "$LOGO" ]; then echo "!! LOGO not found ($LOGO): using the original emblem"; LOGO=""; fi
[ -z "$HUD_LABEL" ] && HUD_LABEL="$(id -un | tr '[:lower:]' '[:upper:]')"

say() { printf '\033[38;2;91;238;220m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;255;42;79m!!\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
kw() { kwriteconfig6 "$@"; }
dbus_call() { gdbus call --session --dest "$1" --object-path "$2" --method "$3" "${@:4}"; }

# ------------------------------------------------------------------ checks
say "checking requirements"
echo "${XDG_CURRENT_DESKTOP:-}" | grep -qi kde || warn "this does not look like a KDE Plasma session"
missing=()
for c in python3 kwriteconfig6 kreadconfig6 kpackagetool6 plasma-apply-colorscheme plasma-apply-desktoptheme \
         plasma-apply-cursortheme gdbus fc-cache curl; do have "$c" || missing+=("$c"); done
python3 -I -c "import PIL, cairo" 2>/dev/null || missing+=("python3 Pillow + pycairo")
if [ ${#missing[@]} -gt 0 ]; then
    warn "missing: ${missing[*]}"
    echo "   Debian/Ubuntu/Kubuntu/KDE neon: sudo apt install python3-pil python3-cairo curl"
    echo "   Fedora:                         sudo dnf install python3-pillow python3-cairo curl"
    echo "   Arch:                           sudo pacman -S python-pillow python-cairo curl"
    exit 1
fi
SESSION="${XDG_SESSION_TYPE:-unknown}"
say "session: $SESSION"

# primary screen size (wallpaper fillet scaling): kscreen-doctor works on X11 and Wayland
MON_W=$({ kscreen-doctor -j 2>/dev/null || true; } | python3 -I -c '
import json, sys
try:
    outs = [o for o in json.load(sys.stdin)["outputs"] if o.get("enabled") and o.get("connected")]
    p = sorted(outs, key=lambda o: o.get("priority", 99))[0]
    scale = p.get("scale", 1) or 1
    print(int(round(p["size"]["width"] / scale)))
except Exception:
    print(1920)' 2>/dev/null | head -1)
[[ "$MON_W" =~ ^[0-9]+$ ]] || MON_W=1920
say "primary screen width: ${MON_W}px (logical)"

# ------------------------------------------------------------------ backup
DATA="$HOME/.local/share/cyberneon"
BK="$DATA/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK"
for f in kdeglobals kwinrc kwinrulesrc plasmarc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc kcminputrc \
         konsolerc ksplashrc kscreenlockerrc plasmanotifyrc gtk-3.0/settings.ini gtk-4.0/settings.ini gtk-3.0/gtk.css gtk-4.0/gtk.css Kvantum/kvantum.kvconfig; do
    [ -f "$HOME/.config/$f" ] && { mkdir -p "$BK/config/$(dirname "$f")"; cp "$HOME/.config/$f" "$BK/config/$f"; }
done
[ -f "$HOME/.gtkrc-2.0" ] && cp "$HOME/.gtkrc-2.0" "$BK/gtkrc-2.0"
[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$BK/bashrc"
[ -d "$DATA/backups/pristine" ] || cp -r "$BK" "$DATA/backups/pristine"
say "backup: $BK"

# ------------------------------------------------------------------ shared assets
say "fonts";                 bash "$SC/install_fonts.sh"
if [ "$PAPIRUS" = 1 ]; then say "Papirus icons (cyber folders)"; bash "$SC/install_papirus.sh"; fi

say "GTK theme for GTK apps -> ~/.themes/CyberNeon"
python3 -I "$SC/build_theme.py" --src "$REPO/third_party/Pocillo-dark" --overrides "$REPO/theme"
mkdir -p "$HOME/.config/gtk-4.0"; cp "$REPO/theme/libadwaita.css" "$HOME/.config/gtk-4.0/gtk.css"

say "icons -> CyberNeon-Icons"
ICONS="$HOME/.local/share/icons"
rm -rf "$ICONS/CyberNeon-Icons"
LAUNCHER_ICON="cyberneon-emblem-symbolic"
if [ -n "$LOGO" ]; then
    python3 -I "$SC/make_logo_icon.py" "$LOGO" "$ICONS/CyberNeon-Icons" --png "$DATA/launcher-logo.png"
    LAUNCHER_ICON="$DATA/launcher-logo.png"
fi
python3 -I "$SC/make_icons.py" "$ICONS/CyberNeon-Icons"
if [ -n "$LOGO" ]; then   # launcher logo as a named icon (Plasma launchers want an icon name, not a path)
    mkdir -p "$ICONS/CyberNeon-Icons/256x256/apps"
    cp "$DATA/launcher-logo.png" "$ICONS/CyberNeon-Icons/256x256/apps/cyberneon-launcher.png"
    LAUNCHER_ICON="cyberneon-launcher"
fi
have gtk-update-icon-cache && gtk-update-icon-cache -q -f -t "$ICONS/CyberNeon-Icons" || true

say "cursors -> CyberNeon-Cursors"
python3 -I "$SC/make_cursors.py" "$ICONS/CyberNeon-Cursors"
mkdir -p "$HOME/.icons/default"   # for X11 / XWayland apps (libXcursor searches ~/.icons)
ln -sfn "$ICONS/CyberNeon-Cursors" "$HOME/.icons/CyberNeon-Cursors"
printf '[Icon Theme]\nName=Default\nInherits=CyberNeon-Cursors\n' > "$HOME/.icons/default/index.theme"

for snapdesk in /var/lib/snapd/desktop/applications/firefox_firefox.desktop; do   # snap Firefox: absolute icon path
    [ -f "$snapdesk" ] && { mkdir -p "$HOME/.local/share/applications"
        sed 's|^Icon=/snap/firefox/current/default256.png|Icon=firefox|' "$snapdesk" > "$HOME/.local/share/applications/firefox_firefox.desktop"; }
done

say "wallpaper -> ~/Pictures/Wallpapers/$WALLPAPER"
WALLDIR="$HOME/Pictures/Wallpapers"; mkdir -p "$WALLDIR"
WARGS=(--label "$LABEL" --monitor-width "$MON_W"); [ -n "$LOGO" ] && WARGS+=(--logo "$LOGO")
python3 -I "$SC/make_wallpaper.py" "$WALLDIR/$WALLPAPER" --no-fillet "${WARGS[@]}"

say "login / GRUB assets -> $DATA/system"
mkdir -p "$DATA/system"
python3 -I "$SC/make_wallpaper.py" "$DATA/system/login-4k.png" --login "${WARGS[@]}"
python3 -I "$SC/make_system_assets.py" "$DATA/system/login-4k.png" "$DATA/system"
rm -f "$DATA/system/login-4k.png"
cp "$WALLDIR/$WALLPAPER" "$DATA/system/cyberneon-wallpaper.png"   # animated SDDM login background
cp "$REPO/system/grub/theme.txt" "$DATA/system/grub/theme.txt"
if have grub-mkfont || have grub2-mkfont; then
    MK=$(command -v grub-mkfont || command -v grub2-mkfont); F="$HOME/.local/share/fonts/cyberneon"
    "$MK" -s 18 -o "$DATA/system/grub/chakra_medium_18.pf2" "$F/ChakraPetch-Medium.ttf"
    "$MK" -s 22 -o "$DATA/system/grub/chakra_medium_22.pf2" "$F/ChakraPetch-Medium.ttf"
    "$MK" -s 22 -o "$DATA/system/grub/chakra_bold_22.pf2" "$F/ChakraPetch-Bold.ttf"
    "$MK" -s 28 -o "$DATA/system/grub/chakra_bold_28.pf2" "$F/ChakraPetch-Bold.ttf"
fi

# ------------------------------------------------------------------ KDE themes
say "KDE: colour scheme, Plasma theme, Aurorae window decoration"
python3 -I "$SC/make_kde_themes.py" \
    --aurorae "$HOME/.local/share/aurorae/themes/CyberNeon" \
    --plasma "$HOME/.local/share/plasma/desktoptheme/CyberNeon" \
    --colors "$HOME/.local/share/color-schemes/CyberNeon.colors"
plasma-apply-colorscheme CyberNeon || true
plasma-apply-desktoptheme CyberNeon || true
plasma-apply-cursortheme CyberNeon-Cursors || true
kw --file kcminputrc --group Mouse --key cursorTheme CyberNeon-Cursors
kw --file kcminputrc --group Mouse --key cursorSize 24
kw --file kdeglobals --group Icons --key Theme CyberNeon-Icons
for ci in /usr/lib/*/libexec/plasma-changeicons /usr/libexec/plasma-changeicons /usr/lib/libexec/plasma-changeicons; do
    [ -x "$ci" ] && { "$ci" CyberNeon-Icons >/dev/null 2>&1 || true; break; }
done
kw --file kdeglobals --group General --key font "$UI_FONT"
kw --file kdeglobals --group General --key menuFont "$UI_FONT"
kw --file kdeglobals --group General --key toolBarFont "$UI_FONT"
kw --file kdeglobals --group General --key smallestReadableFont "$UI_FONT"
kw --file kdeglobals --group General --key fixed "$FIXED_FONT"
kw --file kdeglobals --group WM --key activeFont "$TITLE_FONT"
kw --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
# window decoration: QML (big 45deg cut, neon core, HUD details) or the simpler SVG Aurorae theme
# (copied, not installed with kpackagetool6: it rejects KWin/Decoration packages, even KDE's own plastik)
DECO_DIR="$HOME/.local/share/kwin/decorations/kwin4_decoration_qml_cyberneon"
rm -rf "$DECO_DIR"; mkdir -p "$DECO_DIR"
cp -r "$REPO/kde/decoration/cyberneon/." "$DECO_DIR/"
if [ "${DECORATION:-qml}" = svg ]; then DECO_THEME=__aurorae__svg__CyberNeon; else DECO_THEME=kwin4_decoration_qml_cyberneon; fi
kw --file kwinrc --group org.kde.kdecoration2 --key theme "$DECO_THEME"
kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
kw --file kwinrc --group org.kde.kdecoration2 --key BorderSize Normal
kw --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false

if ls /usr/lib/qt6/plugins/styles/libkvantum.so /usr/lib/*/qt6/plugins/styles/libkvantum.so /usr/lib64/qt6/plugins/styles/libkvantum.so >/dev/null 2>&1 \
   || have kvantummanager; then
    say "Kvantum widget style for Qt apps (cut-corner buttons, red translucent menus)"
    python3 -I "$SC/make_kvantum.py" "$HOME/.config/Kvantum/CyberNeon"
    printf '[General]\ntheme=CyberNeon\n' > "$HOME/.config/Kvantum/kvantum.kvconfig"
    kw --file kdeglobals --group KDE --key widgetStyle kvantum
    KVANTUM=1
else
    warn "Kvantum not installed: Qt apps keep Breeze with the CyberNeon colours (install the 'kvantum' package for the HUD-style widgets)"
fi

if [ "${ANIMATED_WALLPAPER:-yes}" = yes ]; then WP_PLUGIN=org.cyberneon.wallpaper; else WP_PLUGIN=org.kde.image; fi
say "CyberNeon Live wallpaper, global theme + splash, lock screen, Alt+Tab switcher, glitch effect"
# -L: the shared animation (kde/shared/CyberNeonLive.qml) is linked into each package
for pair in "kde/wallpaper/org.cyberneon.wallpaper:plasma/wallpapers/org.cyberneon.wallpaper" \
            "kde/lookandfeel/org.cyberneon.desktop:plasma/look-and-feel/org.cyberneon.desktop" \
            "kde/effects/cyberneon_glitch:kwin/effects/cyberneon_glitch" \
            "kde/tabbox/cyberneon:kwin/tabbox/cyberneon"; do
    src="$REPO/${pair%%:*}"; dst="$HOME/.local/share/${pair##*:}"
    rm -rf "$dst"; mkdir -p "$dst"; cp -rL "$src/." "$dst/"
done
sed -i "s|@WALLPAPER@|file://$WALLDIR/$WALLPAPER|" "$HOME/.local/share/plasma/look-and-feel/org.cyberneon.desktop/contents/splash/Splash.qml"
kw --file ksplashrc --group KSplash --key Engine KSplashQML
kw --file ksplashrc --group KSplash --key Theme org.cyberneon.desktop
# lock screen: the same (animated) wallpaper behind the Plasma lock screen, styled by the Plasma theme
kw --file kscreenlockerrc --group Greeter --key WallpaperPlugin "$WP_PLUGIN"
kw --file kscreenlockerrc --group Greeter --group Wallpaper --group "$WP_PLUGIN" --group General --key Image "file://$WALLDIR/$WALLPAPER"
kw --file kwinrc --group TabBox --key LayoutName cyberneon
kw --file kwinrc --group Plugins --key blurEnabled true
kw --file kwinrc --group Plugins --key contrastEnabled true
if [ "${GLITCH_EFFECT:-yes}" = yes ]; then
    kw --file kwinrc --group Plugins --key cyberneon_glitchEnabled true
    kw --file kwinrc --group Plugins --key scaleEnabled false     # Plasma's default open/close animation
else
    kw --file kwinrc --group Plugins --key cyberneon_glitchEnabled false
fi
RULES=$(kreadconfig6 --file kwinrulesrc --group General --key rules)
if [ "${KVANTUM:-0}" = 1 ]; then
    # Kvantum already gives Qt windows a blurred glass background: drop the old whole-window opacity rule
    RULES=$(echo "$RULES" | tr ',' '\n' | grep -vx cyberneon-dolphin | paste -sd, -)
    kw --file kwinrulesrc --group General --key rules "$RULES"
    kw --file kwinrulesrc --group General --key count "$(echo "$RULES" | tr ',' '\n' | grep -c . || true)"
    kwriteconfig6 --file kwinrulesrc --group cyberneon-dolphin --key Description --delete 2>/dev/null || true
else
    say "Dolphin transparency (${DOLPHIN_OPACITY}%) - KWin window rule"
    case ",$RULES," in *,cyberneon-dolphin,*) ;; *) RULES="${RULES:+$RULES,}cyberneon-dolphin" ;; esac
    kw --file kwinrulesrc --group General --key rules "$RULES"
    kw --file kwinrulesrc --group General --key count "$(echo "$RULES" | tr ',' '\n' | grep -c .)"
    R=(--file kwinrulesrc --group cyberneon-dolphin)
    kw "${R[@]}" --key Description "CyberNeon: Dolphin transparency"
    kw "${R[@]}" --key wmclass dolphin
    kw "${R[@]}" --key wmclassmatch 1
    kw "${R[@]}" --key wmclasscomplete false
    kw "${R[@]}" --key opacityactive "$DOLPHIN_OPACITY"
    kw "${R[@]}" --key opacityactiverule 2
    kw "${R[@]}" --key opacityinactive "$DOLPHIN_OPACITY"
    kw "${R[@]}" --key opacityinactiverule 2
fi

say "Konsole profile + colours"
mkdir -p "$HOME/.local/share/konsole"
cp "$REPO/kde/konsole/CyberNeon.colorscheme" "$REPO/kde/konsole/CyberNeon.profile" "$HOME/.local/share/konsole/"
kw --file konsolerc --group "Desktop Entry" --key DefaultProfile CyberNeon.profile

say "GTK apps settings"
for v in 3.0 4.0; do
    mkdir -p "$HOME/.config/gtk-$v"
    S="$HOME/.config/gtk-$v/settings.ini"
    [ -f "$S" ] || printf '[Settings]\n' > "$S"
    python3 -I - "$S" <<'PY'
import configparser, sys
p = sys.argv[1]; c = configparser.ConfigParser(); c.optionxform = str; c.read(p)
if "Settings" not in c: c["Settings"] = {}
c["Settings"].update({"gtk-theme-name": "CyberNeon", "gtk-icon-theme-name": "CyberNeon-Icons",
                      "gtk-cursor-theme-name": "CyberNeon-Cursors", "gtk-cursor-theme-size": "24",
                      "gtk-font-name": "Chakra Petch Medium 10", "gtk-application-prefer-dark-theme": "1"})
with open(p, "w") as f: c.write(f, space_around_delimiters=False)
PY
done
printf 'gtk-theme-name="CyberNeon"\ngtk-icon-theme-name="CyberNeon-Icons"\ngtk-cursor-theme-name="CyberNeon-Cursors"\ngtk-font-name="Chakra Petch Medium 10"\n' > "$HOME/.gtkrc-2.0"
if have gsettings && gsettings list-schemas | grep -qx org.gnome.desktop.interface; then
    gsettings set org.gnome.desktop.interface gtk-theme CyberNeon || true
    gsettings set org.gnome.desktop.interface icon-theme CyberNeon-Icons || true
    gsettings set org.gnome.desktop.interface cursor-theme CyberNeon-Cursors || true
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
fi

say "bash prompt"
mkdir -p "$HOME/.config/cyberneon"
cp "$REPO/config/bash/prompt.bash" "$HOME/.config/cyberneon/prompt.bash"
if ! grep -q '# >>> cyberneon prompt >>>' "$HOME/.bashrc" 2>/dev/null; then
    printf '\n# >>> cyberneon prompt >>>\n[ -f "$HOME/.config/cyberneon/prompt.bash" ] && . "$HOME/.config/cyberneon/prompt.bash"\n# <<< cyberneon prompt <<<\n' >> "$HOME/.bashrc"
fi

say "Plasma HUD widgets: Biomonitor (operator: $HUD_LABEL), Radar + objective tracker, Chrono"
TMPW=$(mktemp -d); trap 'rm -rf "$TMPW"' EXIT
cp -r "$REPO/kde/plasmoids/." "$TMPW/"
sed -i "s/@HUD_LABEL@/$HUD_LABEL/" "$TMPW/org.cyberneon.biomonitor/contents/ui/main.qml"
for w in org.cyberneon.biomonitor org.cyberneon.radar org.cyberneon.chrono; do
    kpackagetool6 -t Plasma/Applet -u "$TMPW/$w" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Applet -i "$TMPW/$w" >/dev/null
done
for w in org.cyberneon.redblock org.cyberneon.hud org.cyberneon.clock; do   # v1/v2 widgets, no longer used
    kpackagetool6 -t Plasma/Applet -r "$w" >/dev/null 2>&1 || true
done
# notifications pop up bottom-left, like incoming holo calls
kw --file plasmanotifyrc --group Notifications --key PopupPosition 4

# ------------------------------------------------------------------ layout (panels, wallpaper, desktop widgets)
if [ "$LAYOUT" = 1 ]; then
    say "Plasma layout: HUD zones (badge + system panels, quick-slot dock, Biomonitor / Radar / Chrono)"
    LAUNCHERS=""
    IFS=',' read -ra L <<< "$PINNED"
    for l in "${L[@]}"; do
        if [[ "$l" == applications:* ]]; then
            d="${l#applications:}"; found=0
            for dir in "$HOME/.local/share/applications" /usr/share/applications /usr/local/share/applications \
                       /var/lib/snapd/desktop/applications /var/lib/flatpak/exports/share/applications \
                       "$HOME/.local/share/flatpak/exports/share/applications"; do
                [ -f "$dir/$d" ] && { found=1; break; }
            done
            [ "$found" = 1 ] || continue
        fi
        LAUNCHERS="${LAUNCHERS:+$LAUNCHERS,}$l"
    done
    SCRIPT=$(sed -e "s|@MENU_ICON@|cyberneon-logo-dock|" -e "s|@LOGO_ICON@|$LAUNCHER_ICON|" \
                 -e "s|@LAUNCHERS@|$LAUNCHERS|" -e "s|@WALLPAPER@|file://$WALLDIR/$WALLPAPER|" \
                 -e "s|@WALLPAPER_PLUGIN@|$WP_PLUGIN|" "$REPO/kde/layout.js")
    OUT=$(dbus_call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$SCRIPT" || true)
    echo "   $OUT" | head -c 300; echo
    for id in $(echo "$OUT" | grep -oE 'panels( [0-9]+)+' | cut -d' ' -f2-); do
        kw --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelOpacity 2   # translucent glass (blurred)
    done
else
    say "layout skipped (--no-layout): set the wallpaper to $WALLDIR/$WALLPAPER and add the CyberNeon widgets by hand"
fi

# ------------------------------------------------------------------ reload
say "reloading KWin and Plasma"
dbus_call org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true
if [ "${GLITCH_EFFECT:-yes}" = yes ]; then   # apply now (KWin would otherwise pick it up at the next login)
    dbus_call org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect scale >/dev/null 2>&1 || true
    dbus_call org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect cyberneon_glitch >/dev/null 2>&1 || true
fi
if systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null; then
    systemctl --user restart plasma-plasmashell.service || true
else
    (kquitapp6 plasmashell >/dev/null 2>&1 || true); sleep 2; (setsid -f plasmashell >/dev/null 2>&1 < /dev/null || true)
fi

say "done. Login + GRUB:  sudo bash $REPO/system/install-sddm.sh  /  sudo bash $REPO/system/install-grub.sh"
say "undo: $REPO/uninstall.sh   (backup of this run: $BK)"
