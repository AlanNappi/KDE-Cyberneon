#!/usr/bin/env python3
"""Build the CyberNeon GTK theme: a recolored copy of Pocillo-dark plus the CyberNeon overrides.

usage: build_theme.py --overrides DIR [--src /usr/share/themes/Pocillo-dark] [--dst ~/.themes/CyberNeon]
"""
import argparse, re, shutil
from pathlib import Path

HEX = {
    # accent blue -> netrunner cyan (and darker states)
    "#5294e2": "#5beedc", "#4882c7": "#4fd3c3", "#4b88d0": "#53dccb",
    "#457cbe": "#49c7b8", "#4277b6": "#44bdaf", "#3f72af": "#40b3a6",
    "#3f5371": "#1e3d40", "#3e506c": "#1c393c", "#3c4a62": "#193236",
    # surfaces -> deep navy / petrol
    "#20222a": "#0f1b26", "#2e313a": "#0b1620", "#383c4a": "#111e29",
    "#34363d": "#132230", "#2c2e36": "#0d1822", "#33353c": "#122029",
    "#3f4148": "#182a36", "#434653": "#1b2e3b", "#3d414f": "#182a37",
    "#4f5157": "#21384a", "#60636d": "#2a4556",
    # foregrounds -> cyan text
    "#bcbdbf": "#7eddd5", "#abadb0": "#6fc4bd", "#919397": "#5aa39d",
    "#a6a7aa": "#68b8b1", "#e5e5e6": "#9ff0e8", "#757575": "#4f8f8a",
    # error -> neon red
    "#fc4138": "#ff2a4f", "#fc726c": "#ff6b7c", "#fc6c65": "#ff6274",
    "#fc5f58": "#ff5266", "#fc5850": "#fd475c", "#fc5048": "#fc3c52",
    # warning / success / purple
    "#fdd663": "#fcee0a", "#6c6346": "#5a5520",
    "#81c995": "#2ef2a8", "#c58af9": "#ff6b81",
}
RGB = {
    (188, 189, 191): (126, 221, 213),
    (82, 148, 226): (91, 238, 220),
    (255, 255, 255): (91, 238, 220),
}
HEX_RE = re.compile(r"#[0-9a-fA-F]{6}\b")
RGBA_RE = re.compile(r"rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*([,)])")


def recolor(text: str) -> str:
    text = HEX_RE.sub(lambda m: HEX.get(m.group(0).lower(), m.group(0)), text)

    def rgb_sub(m):
        key = tuple(int(m.group(i)) for i in (1, 2, 3))
        if key not in RGB:
            return m.group(0)
        r, g, b = RGB[key]
        return f"{m.group(0).split('(')[0]}({r}, {g}, {b}{m.group(4)}"

    return RGBA_RE.sub(rgb_sub, text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="/usr/share/themes/Pocillo-dark")
    ap.add_argument("--dst", default=str(Path.home() / ".themes" / "CyberNeon"))
    ap.add_argument("--overrides", required=True, help="directory with gtk-3.0-overrides.css and gtk-4.0-overrides.css")
    a = ap.parse_args()
    src, dst, ov = Path(a.src), Path(a.dst), Path(a.overrides)
    if not (src / "gtk-3.0" / "gtk.css").exists():
        raise SystemExit(f"base theme not found: {src} (package ubuntu-budgie-themes)")

    if dst.exists():
        shutil.rmtree(dst)
    dst.mkdir(parents=True)
    for sub in ("gtk-2.0", "gtk-3.0", "gtk-4.0"):
        if (src / sub).exists():
            shutil.copytree(src / sub, dst / sub, symlinks=True)
    shutil.copy(src / "COPYING", dst / "COPYING")

    for f in dst.rglob("*"):
        if f.is_file() and not f.is_symlink() and (f.suffix in (".css", ".rc", ".svg") or f.name == "gtkrc"):
            f.write_text(recolor(f.read_text()))

    for sub in ("gtk-3.0", "gtk-4.0"):
        css = dst / sub / "gtk.css"
        if css.exists():
            css.write_text(css.read_text() + "\n\n" + (ov / f"{sub}-overrides.css").read_text())

    (dst / "index.theme").write_text(
        "[Desktop Entry]\nType=X-GNOME-Metatheme\nName=CyberNeon\n"
        "Comment=Netrunner neon red/cyan on navy, recolored from Pocillo-dark (GPL-2)\n"
        "Encoding=UTF-8\n\n[X-GNOME-Metatheme]\nGtkTheme=CyberNeon\nMetacityTheme=CyberNeon\n"
        "IconTheme=CyberNeon-Icons\nCursorTheme=CyberNeon-Cursors\n")
    print("theme built:", dst)


if __name__ == "__main__":
    main()
