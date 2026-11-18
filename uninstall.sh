#!/bin/bash
# FAN MADE by a huge fan - inspired by Cyberpunk 2077 by CD PROJEKT RED. Cyberpunk 2077, Arasaka and all
# related names/logos/trademarks belong to CD PROJEKT S.A. Unofficial, non-commercial, not endorsed by CD PROJEKT RED.
# CyberNeon for KDE - uninstall. Restores the KDE/GTK config files saved before the FIRST install
# (~/.local/share/cyberneon/backups/pristine) and removes everything install.sh added.
#
#   ./uninstall.sh            restore and remove (fonts and Papirus are kept)
#   ./uninstall.sh --purge    also remove the CyberNeon fonts and Papirus icons
# SDDM / GRUB: see the "undo" lines printed by system/install-*.sh.
set -euo pipefail
PURGE=0; [ "${1:-}" = "--purge" ] && PURGE=1
DATA="$HOME/.local/share/cyberneon"
P="$DATA/backups/pristine"
say() { printf '\033[38;2;91;238;220m==>\033[0m %s\n' "$*"; }

FILES="kdeglobals kwinrc kwinrulesrc plasmarc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc kcminputrc konsolerc ksplashrc kscreenlockerrc plasmanotifyrc
       gtk-3.0/settings.ini gtk-4.0/settings.ini gtk-3.0/gtk.css gtk-4.0/gtk.css Kvantum/kvantum.kvconfig"
if [ -d "$P" ]; then
    say "restoring KDE / GTK settings from $P"
    for f in $FILES; do
        if [ -f "$P/config/$f" ]; then cp "$P/config/$f" "$HOME/.config/$f"
        else case "$f" in gtk-4.0/gtk.css|Kvantum/kvantum.kvconfig) rm -f "$HOME/.config/$f" ;; esac; fi
    done
    if [ -f "$P/gtkrc-2.0" ]; then cp "$P/gtkrc-2.0" "$HOME/.gtkrc-2.0"; else rm -f "$HOME/.gtkrc-2.0"; fi
else
    say "no pristine backup found: KDE settings are left as they are"
fi

say "removing CyberNeon files"
for w in org.cyberneon.biomonitor org.cyberneon.radar org.cyberneon.chrono org.cyberneon.hud org.cyberneon.clock org.cyberneon.redblock; do kpackagetool6 -t Plasma/Applet -r "$w" >/dev/null 2>&1 || true; done
rm -rf "$HOME/.local/share/kwin/decorations/kwin4_decoration_qml_cyberneon"
rm -rf "$HOME/.themes/CyberNeon" \
       "$HOME/.local/share/icons/CyberNeon-Icons" "$HOME/.local/share/icons/CyberNeon-Cursors" \
       "$HOME/.local/share/aurorae/themes/CyberNeon" "$HOME/.local/share/plasma/desktoptheme/CyberNeon" \
       "$HOME/.local/share/color-schemes/CyberNeon.colors" \
       "$HOME/.local/share/konsole/CyberNeon.colorscheme" "$HOME/.local/share/konsole/CyberNeon.profile" \
       "$HOME/.config/cyberneon" "$DATA/launcher-logo.png" "$HOME/.config/Kvantum/CyberNeon" \
       "$HOME/.local/share/plasma/wallpapers/org.cyberneon.wallpaper" \
       "$HOME/.local/share/plasma/look-and-feel/org.cyberneon.desktop" "$HOME/.local/share/kwin/effects/cyberneon_glitch" \
       "$HOME/.local/share/kwin/tabbox/cyberneon"
[ -L "$HOME/.icons/CyberNeon-Cursors" ] && rm -f "$HOME/.icons/CyberNeon-Cursors"
grep -q 'Inherits=CyberNeon-Cursors' "$HOME/.icons/default/index.theme" 2>/dev/null && rm -f "$HOME/.icons/default/index.theme"
grep -q '^Icon=firefox$' "$HOME/.local/share/applications/firefox_firefox.desktop" 2>/dev/null \
    && rm -f "$HOME/.local/share/applications/firefox_firefox.desktop"
if grep -q '# >>> cyberneon prompt >>>' "$HOME/.bashrc" 2>/dev/null; then
    sed -i '/# >>> cyberneon prompt >>>/,/# <<< cyberneon prompt <<</d' "$HOME/.bashrc"
fi
if [ "$PURGE" = 1 ]; then
    rm -rf "$HOME/.local/share/fonts/cyberneon" "$HOME/.local/share/icons/Papirus" "$HOME/.local/share/icons/Papirus-Dark"
    fc-cache -f >/dev/null || true
fi

say "reloading KWin and Plasma"
gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure >/dev/null 2>&1 || true
if systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null; then
    systemctl --user restart plasma-plasmashell.service || true
else
    (kquitapp6 plasmashell >/dev/null 2>&1 || true); sleep 2; (setsid -f plasmashell >/dev/null 2>&1 < /dev/null || true)
fi
say "done (wallpapers in ~/Pictures/Wallpapers and backups in $DATA are kept). Log out and back in for a clean session."
