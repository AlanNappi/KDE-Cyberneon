#!/usr/bin/env python3
"""Build the assets for the login screen and the GRUB theme from the login wallpaper.

usage: make_system_assets.py LOGIN_4K.png OUT_DIR
writes OUT_DIR/cyberneon-login.png and OUT_DIR/grub/{background.png, select_*.png, menu_*.png, terminal_box_*.png}
(the GRUB .pf2 fonts are made by install.sh with grub-mkfont)
"""
import sys
from pathlib import Path
from PIL import Image, ImageEnhance

src, out = Path(sys.argv[1]), Path(sys.argv[2])
grub = out / "grub"
grub.mkdir(parents=True, exist_ok=True)

im = Image.open(src).convert("RGB").resize((1920, 1080), Image.LANCZOS)
im.save(out / "cyberneon-login.png")
ImageEnhance.Brightness(im).enhance(0.55).save(grub / "background.png")  # darker: keeps the menu readable

CY, RED, NAVY = (91, 238, 220, 255), (255, 42, 79, 255), (11, 22, 32, 215)


def px(name, w, h, col):
    Image.new("RGBA", (w, h), col).save(grub / f"{name}.png")


# selected entry: cyan block with a red bar on the left
px("select_c", 8, 8, CY); px("select_w", 6, 8, RED); px("select_e", 2, 8, CY)
px("select_n", 8, 1, CY); px("select_s", 8, 1, CY)
px("select_nw", 6, 1, RED); px("select_sw", 6, 1, RED); px("select_ne", 2, 1, CY); px("select_se", 2, 1, CY)
# menu frame: translucent navy with a red border
px("menu_c", 8, 8, NAVY)
for n, (w, h) in {"menu_n": (8, 3), "menu_s": (8, 3), "menu_w": (3, 8), "menu_e": (3, 8),
                  "menu_nw": (3, 3), "menu_ne": (3, 3), "menu_sw": (3, 3), "menu_se": (3, 3)}.items():
    px(n, w, h, RED)
# console box
px("terminal_box_c", 8, 8, (11, 22, 32, 240))
for n in ("n", "s", "w", "e", "nw", "ne", "sw", "se"):
    w, h = (8, 2) if n in ("n", "s") else (2, 8) if n in ("w", "e") else (2, 2)
    px(f"terminal_box_{n}", w, h, CY)
print("system assets:", out)
