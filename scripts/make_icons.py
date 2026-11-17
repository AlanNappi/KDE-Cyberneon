#!/usr/bin/env python3
"""CyberNeon-Icons: circled neon line icons (original artwork) over Papirus-Dark, plus the menu logo
and an original emblem that replaces the Budgie bird (ubuntu-budgie-symbolic).

usage: make_icons.py [OUT_DIR]   (default ~/.local/share/icons/CyberNeon-Icons)
"""
import os, sys
from pathlib import Path

C = "#5beedc"      # cyan
N = "#0b1620"      # navy fill
R = "#ff2a4f"      # neon red
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / ".local/share/icons/CyberNeon-Icons"
APPS = OUT / "scalable/apps"
APPS.mkdir(parents=True, exist_ok=True)

ST = f'fill="none" stroke="{C}" stroke-width="3.2" stroke-linecap="square" stroke-linejoin="miter"'


def circled(inner: str) -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'
            f'<circle cx="32" cy="32" r="28" fill="{N}"/>'
            f'<circle cx="32" cy="32" r="27" fill="none" stroke="{C}" stroke-width="3.4"/>'
            f'<g {ST}>{inner}</g></svg>')


GLYPHS = {
    # terminal  >_
    "terminal": '<polyline points="19,23 28,32 19,41"/><line x1="32" y1="42" x2="45" y2="42"/>',
    # archive box (files)
    "files": '<rect x="16.5" y="19" width="31" height="8"/><polyline points="19,27 19,45 45,45 45,27"/>'
             '<line x1="27" y1="33" x2="37" y2="33"/>',
    # globe (web)
    "web": '<circle cx="32" cy="32" r="14"/><ellipse cx="32" cy="32" rx="6" ry="14"/>'
           '<line x1="18" y1="32" x2="46" y2="32"/><line x1="20.5" y1="25" x2="43.5" y2="25"/>'
           '<line x1="20.5" y1="39" x2="43.5" y2="39"/>',
    # spreadsheet grid
    "sheet": '<rect x="18" y="19" width="28" height="26"/><line x1="18" y1="27" x2="46" y2="27"/>'
             '<line x1="18" y1="36" x2="46" y2="36"/><line x1="28" y1="19" x2="28" y2="45"/>',
    # sliders (settings)
    "settings": '<line x1="18" y1="23" x2="46" y2="23"/><line x1="18" y1="32" x2="46" y2="32"/>'
                '<line x1="18" y1="41" x2="46" y2="41"/>'
                f'<rect x="34" y="19.5" width="5" height="7" fill="{C}"/>'
                f'<rect x="22" y="28.5" width="5" height="7" fill="{C}"/>'
                f'<rect x="30" y="37.5" width="5" height="7" fill="{C}"/>',
    # envelope (mail)
    "mail": '<rect x="17" y="21" width="30" height="22"/><polyline points="17,21 32,34 47,21"/>',
    # calculator
    "calc": '<rect x="20" y="16" width="24" height="32"/><line x1="24" y1="23" x2="40" y2="23"/>'
            '<line x1="25" y1="31" x2="27" y2="31"/><line x1="31" y1="31" x2="33" y2="31"/>'
            '<line x1="37" y1="31" x2="39" y2="31"/><line x1="25" y1="38" x2="27" y2="38"/>'
            '<line x1="31" y1="38" x2="33" y2="38"/><line x1="37" y1="38" x2="39" y2="42"/>',
    # text editor (notes)
    "editor": '<polyline points="38,17 21,17 21,47 43,47 43,22 38,17"/><line x1="26" y1="27" x2="38" y2="27"/>'
              '<line x1="26" y1="33" x2="38" y2="33"/><line x1="26" y1="39" x2="34" y2="39"/>',
}

# icon names each glyph overrides
NAMES = {
    "terminal": ["com.gexperts.Tilix", "utilities-terminal", "org.gnome.Terminal", "terminal", "org.kde.konsole", "konsole"],
    "files": ["org.gnome.Nautilus", "nemo", "system-file-manager", "file-manager", "org.kde.dolphin", "dolphin"],
    "web": ["firefox", "web-browser", "internet-web-browser"],
    "sheet": ["libreoffice-calc"],
    "settings": ["preferences-desktop", "org.buddiesofbudgie.Settings", "preferences-system",
                 "budgie-desktop-settings", "systemsettings", "org.kde.systemsettings"],
    "mail": ["org.gnome.Geary", "internet-mail", "mail-client"],
    "calc": ["org.gnome.Calculator", "accessories-calculator", "gnome-calculator"],
    "editor": ["org.gnome.TextEditor", "org.gnome.gedit", "accessories-text-editor", "text-editor"],
}

for key, names in NAMES.items():
    svg = circled(GLYPHS[key])
    for n in names:
        (APPS / f"{n}.svg").write_text(svg)

# menu logo: filled cut-corner plate with navy slashes and a red notch
logo = (f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'
        f'<polygon points="10,8 54,8 54,42 42,56 10,56" fill="{C}"/>'
        f'<polygon points="18,16 26,16 26,48 18,48" fill="{N}"/>'
        f'<polygon points="31,16 46,16 46,24 39,24 39,48 31,48" fill="{N}"/>'
        f'<polygon points="46,44 54,44 54,42 42,56 40,56" fill="{R}"/>'
        f'</svg>')
(APPS / "cyberneon-logo.svg").write_text(logo)
# KDE dock: Kickoff draws its icon ~45 px, centred at x=38; this variant is scaled so the plate is ~34 px wide,
# the same size as the Budgie menu button (measured in the lab)
dock_logo = logo.replace('viewBox="0 0 64 64">', 'viewBox="0 0 64 64"><g transform="translate(32 32) scale(1.1) translate(-32 -32)">', 1)
dock_logo = dock_logo.replace("</svg>", "</g></svg>")
(APPS / "cyberneon-logo-dock.svg").write_text(dock_logo)

# original emblem (hexagon + visor + red slit) used in place of the Budgie bird
SYM = OUT / "symbolic/apps"
SYM.mkdir(parents=True, exist_ok=True)
(SYM / "cyberneon-emblem-symbolic.svg").write_text(
    '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">\n'
    '  <path fill="#5beedc" fill-rule="evenodd" d="M8 0.4 14.6 4.2 14.6 11.8 8 15.6 1.4 11.8 1.4 4.2Z M8 1.9 2.7 4.95 2.7 11.05 8 14.1 13.3 11.05 13.3 4.95Z"/>\n'
    '  <path fill="#5beedc" d="M4.1 5.2H6.2L8 9.1 9.8 5.2H11.9L8 12.6Z"/>\n'
    '  <rect class="error" fill="#ff2a4f" x="6.4" y="3.1" width="3.2" height="1.2"/>\n'
    '</svg>\n')
bird = SYM / "ubuntu-budgie-symbolic.svg"
if not bird.exists():  # make_logo_icon.py may already have put a user logo here
    bird.write_text((SYM / "cyberneon-emblem-symbolic.svg").read_text())
for alias in ("start-here-symbolic.svg", "budgie-start-here-symbolic.svg"):
    p = SYM / alias
    if p.is_symlink() or p.exists():
        p.unlink()
    os.symlink("ubuntu-budgie-symbolic.svg", p)

(OUT / "index.theme").write_text(
    "[Icon Theme]\nName=CyberNeon-Icons\nComment=Circled neon app icons over Papirus-Dark\n"
    "Inherits=Papirus-Dark,Papirus,hicolor\nDirectories=scalable/apps,symbolic/apps,256x256/apps\n\n"
    "[scalable/apps]\nSize=64\nMinSize=8\nMaxSize=512\nType=Scalable\nContext=Applications\n\n"
    "[symbolic/apps]\nSize=16\nMinSize=8\nMaxSize=512\nType=Scalable\nContext=Applications\n\n"
    "[256x256/apps]\nSize=256\nMinSize=16\nMaxSize=512\nType=Scalable\nContext=Applications\n")
print("icons:", len(list(APPS.glob("*.svg"))), "->", OUT)
