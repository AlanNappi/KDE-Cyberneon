#!/usr/bin/env python3
"""Generate the CyberNeon Kvantum theme (Qt widget style, KDE edition). Original artwork.
Cut-corner cyan-outlined buttons/fields/tabs, red-framed translucent menus, cyan tooltips, hatched progress bars,
square check boxes and diamond radio buttons. Elements not defined here fall back to Kvantum's default theme.

usage: make_kvantum.py OUT_DIR      (writes OUT_DIR/CyberNeon.kvconfig and OUT_DIR/CyberNeon.svg)
FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
"""
import sys
from pathlib import Path

CY, CYT, RED, NAVY, VIEW, WIN = "#5beedc", "#7eddd5", "#ff2a4f", "#111e29", "#0b1620", "#0f1b26"

parts = []          # svg fragments
cursor = {"x": 0, "y": 0, "row_h": 0}


def place(w, h):
    """allocate a spot on the canvas for an element of size w x h"""
    if cursor["x"] + w > 1400:
        cursor["x"] = 0; cursor["y"] += cursor["row_h"] + 6; cursor["row_h"] = 0
    x, y = cursor["x"], cursor["y"]
    cursor["x"] += w + 6; cursor["row_h"] = max(cursor["row_h"], h)
    return x, y


def el(id_, w, h, body_fn):
    x, y = place(w, h)
    parts.append(f'<g id="{id_}"><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#000" fill-opacity="0"/>{body_fn(x, y, w, h)}</g>')


def rect(x, y, w, h, c, a=1.0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}" fill-opacity="{a}"/>' if a > 0 else ""


def poly(pts, c, a=1.0):
    return f'<polygon points="{" ".join(f"{px},{py}" for px, py in pts)}" fill="{c}" fill-opacity="{a}"/>' if a > 0 else ""


def frame(name, state, line, line_a, fill, fill_a, w=4, cut_tl=True, cut_br=True):
    """interior + 8 frame pieces; the outline is a 1 px line on the outer edge, corners tl/br cut at 45deg"""
    el(f"{name}-{state}", 20, 20, lambda x, y, W, H: rect(x, y, W, H, fill, fill_a))
    el(f"{name}-{state}-top", 20, w, lambda x, y, W, H: rect(x, y, W, H, fill, fill_a) + rect(x, y, W, 1, line, line_a))
    el(f"{name}-{state}-bottom", 20, w, lambda x, y, W, H: rect(x, y, W, H, fill, fill_a) + rect(x, y + H - 1, W, 1, line, line_a))
    el(f"{name}-{state}-left", w, 20, lambda x, y, W, H: rect(x, y, W, H, fill, fill_a) + rect(x, y, 1, H, line, line_a))
    el(f"{name}-{state}-right", w, 20, lambda x, y, W, H: rect(x, y, W, H, fill, fill_a) + rect(x + W - 1, y, 1, H, line, line_a))

    def cut_corner(flip):
        # diagonal from (0,w) to (w,0); flip=False -> fill lower-right (top-left corner), True -> upper-left (bottom-right)
        def f(x, y, W, H):
            tri = [(x + W, y), (x + W, y + H), (x, y + H)] if not flip else [(x, y), (x + W, y), (x, y + H)]
            return (poly(tri, fill, fill_a) +
                    f'<line x1="{x}" y1="{y + H - 0.5}" x2="{x + W - 0.5}" y2="{y}" stroke="{line}" stroke-opacity="{line_a}" stroke-width="1.2"/>')
        return f

    def square_corner(top, left):
        def f(x, y, W, H):
            s = rect(x, y, W, H, fill, fill_a)
            s += rect(x, y if top else y + H - 1, W, 1, line, line_a)
            s += rect(x if left else x + W - 1, y, 1, H, line, line_a)
            return s
        return f

    el(f"{name}-{state}-topleft", w, w, cut_corner(False) if cut_tl else square_corner(True, True))
    el(f"{name}-{state}-topright", w, w, square_corner(True, False))
    el(f"{name}-{state}-bottomleft", w, w, square_corner(False, True))
    el(f"{name}-{state}-bottomright", w, w, cut_corner(True) if cut_br else square_corner(False, False))


# ---------------------------------------------------------------- push / tool buttons, combo
for st, (la, fill, fa) in {"normal": (0.55, CY, 0.03), "focused": (1.0, CY, 0.12), "pressed": (1.0, CY, 0.24),
                           "toggled": (1.0, CY, 0.18), "disabled": (0.2, CY, 0.0)}.items():
    frame("button", st, CY, la, fill, fa)
# ---------------------------------------------------------------- line edits
for st, (la, fa) in {"normal": (0.45, 1.0), "focused": (1.0, 1.0), "disabled": (0.2, 0.6)}.items():
    frame("lineedit", st, CY, la, VIEW, fa, cut_tl=False)
# ---------------------------------------------------------------- tabs (active tab = toggled)
for st, (la, fa) in {"normal": (0.35, 0.0), "focused": (0.8, 0.08), "toggled": (1.0, 0.16), "disabled": (0.15, 0.0)}.items():
    frame("tab", st, CY, la, CY, fa, cut_br=False)
frame("tabframe", "normal", CY, 0.35, WIN, 1.0, cut_tl=False, cut_br=False)
# ---------------------------------------------------------------- menus (red frame), menu items, tooltips
frame("menu", "normal", RED, 1.0, NAVY, 0.94, w=4)
for st, fa in {"normal": 0.0, "focused": 0.18, "pressed": 0.26, "toggled": 0.18}.items():
    frame("menuitem", st, CY, 0.0 if st == "normal" else 0.9, CY, fa, w=2, cut_tl=False, cut_br=False)
frame("tooltip", "normal", CY, 0.9, VIEW, 0.97, cut_tl=False)
# ---------------------------------------------------------------- item views (selection)
for st, (la, fa) in {"normal": (0.0, 0.0), "focused": (0.0, 0.10), "pressed": (0.9, 0.24), "toggled": (0.6, 0.20)}.items():
    frame("itemview", st, CY, la, CY, fa, w=2, cut_tl=False, cut_br=False)
# ---------------------------------------------------------------- toolbar / menubar / header / statusbar / groupbox / groove
def bar(name, line_side, la=0.3, fill=NAVY):
    for st in ("normal", "focused", "pressed", "toggled", "disabled"):
        el(f"{name}-{st}", 20, 20, lambda x, y, W, H: rect(x, y, W, H, fill))
        for side in ("top", "bottom", "left", "right"):
            w_, h_ = (20, 1) if side in ("top", "bottom") else (1, 20)
            a = la if side == line_side else 0.0
            el(f"{name}-{st}-{side}", w_, h_, lambda x, y, W, H, a=a: rect(x, y, W, H, fill) + rect(x, y, W, H, CY, a))
        for c in ("topleft", "topright", "bottomleft", "bottomright"):
            el(f"{name}-{st}-{c}", 1, 1, lambda x, y, W, H: rect(x, y, W, H, fill))


bar("toolbar", "bottom")
bar("menubar", "bottom", 0.2)
bar("header", "bottom", 0.4)
bar("statusbar", "top", 0.2)
frame("groupbox", "normal", CY, 0.3, WIN, 0.0, cut_br=False)
for st in ("normal", "focused", "pressed", "disabled"):
    el(f"scrollbargroove-{st}", 20, 20, lambda x, y, W, H: rect(x, y, W, H, VIEW))
# ---------------------------------------------------------------- scrollbar slider, slider groove + handle
for st, a in {"normal": 0.45, "focused": 0.75, "pressed": 1.0, "disabled": 0.15}.items():
    el(f"scrollbarslider-{st}", 20, 20, lambda x, y, W, H, a=a: rect(x, y, W, H, CY, a))
for st in ("normal", "focused", "pressed", "disabled", "toggled"):
    el(f"slider-{st}", 20, 20, lambda x, y, W, H: rect(x, y, W, H, CY, 0.25))
for st, (fill, a) in {"normal": (CY, 1.0), "focused": ("#9ff0e8", 1.0), "pressed": (RED, 1.0), "disabled": (CY, 0.3)}.items():
    el(f"slidercursor-{st}", 16, 16, lambda x, y, W, H, fill=fill, a=a:
       poly([(x + 3, y), (x + W, y), (x + W, y + H - 3), (x + W - 3, y + H), (x, y + H), (x, y + 3)], fill, a))
# ---------------------------------------------------------------- progress bar: navy groove, hatched cyan contents
frame("progress", "normal", CY, 0.4, VIEW, 1.0, w=2, cut_tl=False, cut_br=False)


def clip_to_rect(pts, x0, y0, x1, y1):
    """Sutherland-Hodgman clipping of a polygon to an axis-aligned rectangle (QtSvg has no reliable clipPath)"""
    def clip(poly_, inside, inter):
        out = []
        for i in range(len(poly_)):
            a, b = poly_[i - 1], poly_[i]
            if inside(b):
                if not inside(a):
                    out.append(inter(a, b))
                out.append(b)
            elif inside(a):
                out.append(inter(a, b))
        return out
    def ix(a, b, xv):
        t_ = (xv - a[0]) / (b[0] - a[0]); return (xv, a[1] + t_ * (b[1] - a[1]))
    def iy(a, b, yv):
        t_ = (yv - a[1]) / (b[1] - a[1]); return (a[0] + t_ * (b[0] - a[0]), yv)
    for inside, inter in ((lambda p_: p_[0] >= x0, lambda a, b: ix(a, b, x0)), (lambda p_: p_[0] <= x1, lambda a, b: ix(a, b, x1)),
                          (lambda p_: p_[1] >= y0, lambda a, b: iy(a, b, y0)), (lambda p_: p_[1] <= y1, lambda a, b: iy(a, b, y1))):
        pts = clip(pts, inside, inter)
        if not pts:
            break
    return pts


def hatch(x, y, W, H):
    # 45deg stripes (4 px stripe, 8 px period) over a dim cyan base, like the HUD widget
    s = rect(x, y, W, H, CY, 0.25)
    for i in range(-H - 8, W + 8, 8):
        stripe = [(x + i, y + H), (x + i + 4, y + H), (x + i + 4 + H, y), (x + i + H, y)]
        c = clip_to_rect(stripe, x, y, x + W, y + H)
        if len(c) >= 3:
            s += poly([(round(px, 2), round(py, 2)) for px, py in c], CY, 0.95)
    return s


el("progress-pattern-normal", 48, 16, hatch)
# ---------------------------------------------------------------- check boxes (squares) and radio buttons (diamonds)
def check(state_on, tri=False, a=1.0, hot=False):
    def f(x, y, W, H):
        s = rect(x + 1, y + 1, W - 2, H - 2, VIEW, 1.0)
        s += f'<rect x="{x + 1.5}" y="{y + 1.5}" width="{W - 3}" height="{H - 3}" fill="none" stroke="{CY}" stroke-opacity="{a}" stroke-width="1.4"/>'
        if state_on:
            s += rect(x + 4, y + 4, W - 8, H - 8, RED if hot else CY, a)
        if tri:
            s += rect(x + 4, y + H / 2 - 1.5, W - 8, 3, CY, a)
        return s
    return f


def radio(state_on, a=1.0, hot=False):
    def f(x, y, W, H):
        cx, cy = x + W / 2, y + H / 2
        s = poly([(cx, y + 1), (x + W - 1, cy), (cx, y + H - 1), (x + 1, cy)], VIEW)
        s += f'<polygon points="{cx},{y + 1.5} {x + W - 1.5},{cy} {cx},{y + H - 1.5} {x + 1.5},{cy}" fill="none" stroke="{CY}" stroke-opacity="{a}" stroke-width="1.4"/>'
        if state_on:
            s += poly([(cx, y + 5), (x + W - 5, cy), (cx, y + H - 5), (x + 5, cy)], RED if hot else CY, a)
        return s
    return f


for st, (a, hot) in {"normal": (0.8, False), "focused": (1.0, False), "pressed": (1.0, True), "disabled": (0.3, False)}.items():
    el(f"checkbox-{st}", 14, 14, check(False, a=a))
    el(f"checkbox-checked-{st}", 14, 14, check(True, a=a, hot=hot))
    el(f"checkbox-tristate-{st}", 14, 14, check(False, tri=True, a=a))
    el(f"radio-{st}", 14, 14, radio(False, a=a))
    el(f"radio-checked-{st}", 14, 14, radio(True, a=a, hot=hot))

SVG = ('<?xml version="1.0" encoding="UTF-8"?>\n'
       f'<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="{cursor["y"] + cursor["row_h"] + 10}">\n'
       + "\n".join(parts) + "\n</svg>\n")


def section(name, element, w=4, colors=None, extra=""):
    c = colors or {}
    return (f"[{name}]\nframe=true\nframe.element={element}\nframe.top={w}\nframe.bottom={w}\nframe.left={w}\nframe.right={w}\n"
            f"interior=true\ninterior.element={element}\n"
            + "".join(f"text.{k}.color={v}\n" for k, v in c.items()) + extra + "\n")


BTN = {"normal": CY, "focus": "#9ff0e8", "press": "#d8fffa", "toggle": CY}
KVCONFIG = f"""# CyberNeon Kvantum theme - FAN MADE, inspired by Cyberpunk 2077 by CD PROJEKT RED
[%General]
author=CyberNeon (fan made)
comment=Netrunner neon: cut-corner cyan outlines, red translucent menus
x11drag=menubar_and_primary_toolbar
alt_mnemonic=true
left_tabs=true
attach_active_tab=false
group_toolbar_buttons=false
spread_progressbar=true
composite=true
menu_shadow_depth=0
tooltip_shadow_depth=0
splitter_width=1
scroll_width=8
scroll_min_extent=36
slider_width=4
slider_handle_width=16
slider_handle_length=16
check_size=14
progressbar_thickness=10
textless_progressbar=false
toolbutton_style=1
translucent_windows=false
blurring=false
popup_blurring=true
menu_blur_radius=6
tooltip_blur_radius=4
reduce_menu_opacity=0
animate_states=true
button_contents_shift=false
combo_as_lineedit=true
combo_menu=true
layout_spacing=6
layout_margin=9
scrollbar_in_view=true
transient_scrollbar=false
respect_DE=true
no_window_pattern=true
small_icon_size=16
large_icon_size=32
button_icon_size=16
toolbar_icon_size=22

[GeneralColors]
window.color={WIN}
base.color={VIEW}
alt.base.color={NAVY}
button.color={NAVY}
light.color=#1b2e3b
mid.light.color=#182a36
dark.color=#070d1a
mid.color=#132230
highlight.color={CY}
inactive.highlight.color=#1e3d40
text.color={CYT}
window.text.color={CYT}
button.text.color={CY}
disabled.text.color=#4f8f8a
tooltip.text.color={CY}
highlight.text.color={VIEW}
link.color={CY}
link.visited.color=#ff6b81
progress.indicator.text.color={VIEW}

[Hacks]
transparent_dolphin_view=false
respect_darkness=true
blur_konsole=true
no_selection_tint=true

""" + section("PanelButtonCommand", "button", colors=BTN, extra="text.margin.left=6\ntext.margin.right=6\ntext.margin.top=2\ntext.margin.bottom=2\nindicator.element=arrow\n") \
    + section("PanelButtonTool", "button", colors=BTN) \
    + section("ToolbarButton", "button", colors=BTN) \
    + section("ComboBox", "button", colors=BTN, extra="indicator.element=arrow\n") \
    + section("LineEdit", "lineedit", colors={"normal": CYT, "focus": CY}) \
    + section("Tab", "tab", colors={"normal": "#4f8f8a", "focus": CYT, "toggle": CY}, extra="text.bold=true\n") \
    + section("TabFrame", "tabframe") \
    + section("Menu", "menu", colors={"normal": CYT}) \
    + section("MenuItem", "menuitem", w=2, colors={"normal": CYT, "focus": CY}) \
    + section("ToolTip", "tooltip", colors={"normal": CY}) \
    + section("ItemView", "itemview", w=2, colors={"normal": CYT, "focus": CY, "press": CY, "toggle": CY}) \
    + section("Progressbar", "progress", w=2) \
    + "[ProgressbarContents]\nframe=false\ninterior=true\ninterior.element=progress-pattern\n\n" \
    + "[ScrollbarSlider]\nframe=false\ninterior=true\ninterior.element=scrollbarslider\n\n" \
    + "[ScrollbarGroove]\nframe=false\ninterior=true\ninterior.element=scrollbargroove\n\n" \
    + section("Toolbar", "toolbar", w=1, colors={"normal": CY}) \
    + section("MenuBar", "menubar", w=1, colors={"normal": CYT}) \
    + section("MenuBarItem", "menuitem", w=2, colors={"normal": CYT, "focus": CY}) \
    + section("HeaderSection", "header", w=1, colors={"normal": CY, "focus": "#9ff0e8"}) \
    + section("StatusBar", "statusbar", w=1, colors={"normal": CYT}) \
    + section("GroupBox", "groupbox", colors={"normal": CY}) \
    + "[Slider]\nframe=false\ninterior=true\ninterior.element=slider\n\n" \
    + "[SliderCursor]\nframe=false\ninterior=true\ninterior.element=slidercursor\n\n" \
    + f"[CheckBox]\nindicator.element=checkbox\nindicator.size=14\ntext.normal.color={CYT}\ntext.focus.color={CY}\n\n" \
    + f"[RadioButton]\nindicator.element=radio\nindicator.size=14\ntext.normal.color={CYT}\ntext.focus.color={CY}\n\n"


def main():
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    (out / "CyberNeon.svg").write_text(SVG)
    (out / "CyberNeon.kvconfig").write_text(KVCONFIG)
    print("kvantum theme:", out, f"({len(parts)} elements)")


if __name__ == "__main__":
    main()
