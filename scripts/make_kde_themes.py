#!/usr/bin/env python3
"""Generate the KDE Plasma 6 parts of CyberNeon (work on X11 and Wayland):
  - Aurorae window decoration "CyberNeon"  (red titlebar with 45deg cut, 4/4/6 px border, centred square buttons)
  - Plasma desktop theme "CyberNeon"        (top bar with neon bottom line + red corner block, dock with red bar,
                                             popups/tooltips), plus its colours file

Same geometry as the Budgie version: titlebar 19 px, dock 90 px (red bar 76-90), top bar 34 px (red block to x=110).

usage: make_kde_themes.py --aurorae DIR --plasma DIR --colors FILE
FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
"""
import argparse, json, shutil
from pathlib import Path

RED, RED_DIM, RED_HOT = "#ff2a4f", "#8c1a33", "#ff8fa3"
CY, NAVY, NAVY_DEEP, VIEW = "#5beedc", "#111e29", "#070d1a", "#0b1620"
TITLE_H = 19          # = title text height in the Budgie version
BL, BR, BB = 4, 4, 6  # side / bottom borders
CUT = 19              # 45deg cut on the top-left corner (legs of the triangle)


def svg_doc(w, h, body):
    return (f'<?xml version="1.0" encoding="UTF-8"?>\n'
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}</svg>\n')


def rect(id_, x, y, w, h, fill, opacity=None):
    o = f' fill-opacity="{opacity}"' if opacity is not None else ""
    return f'  <rect id="{id_}" x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}"{o}/>\n'


# --------------------------------------------------------------------------- Aurorae
def aurorae_decoration():
    """FrameSvg elements laid out on one canvas (positions are arbitrary, sizes matter)."""
    body, x = "", 0
    for prefix, col in (("decoration", RED), ("decoration-inactive", RED_DIM)):
        y = 0 if prefix == "decoration" else 60
        # top-left corner: red block with the 45deg cut, 22 x TITLE_H
        # Aurorae scales corners to the side border width (BL), so the corner is BL x TITLE_H with a BL-px cut;
        # the big 45deg cut of the Budgie version needs a QML decoration (see README)
        body += (f'  <g id="{prefix}-topleft"><rect x="{x}" y="{y}" width="{BL}" height="{TITLE_H}" fill="none"/>'
                 f'<polygon points="{x+BL},{y} {x+BL},{y+TITLE_H} {x},{y+TITLE_H} {x},{y+BL}" fill="{col}"/></g>\n')
        body += rect(f"{prefix}-top", x + 30, y, 10, TITLE_H, col)
        body += rect(f"{prefix}-topright", x + 50, y, BR, TITLE_H, col)
        body += rect(f"{prefix}-left", x + 60, y, BL, 10, col)
        body += rect(f"{prefix}-right", x + 70, y, BR, 10, col)
        body += rect(f"{prefix}-center", x + 80, y, 10, 10, NAVY, 0)
        body += rect(f"{prefix}-bottomleft", x + 100, y, BL, BB, col)
        body += rect(f"{prefix}-bottom", x + 110, y, 10, BB, col)
        body += rect(f"{prefix}-bottomright", x + 130, y, BR, BB, col)
    # maximized: plain red titlebar, no borders, no cut
    for prefix, col in (("decoration-maximized", RED), ("decoration-maximized-inactive", RED_DIM)):
        y = 120 if prefix == "decoration-maximized" else 150
        body += rect(f"{prefix}-top", 0, y, 10, TITLE_H, col)
        body += rect(f"{prefix}-topleft", 20, y, 1, TITLE_H, col)
        body += rect(f"{prefix}-topright", 30, y, 1, TITLE_H, col)
        body += rect(f"{prefix}-center", 40, y, 10, 10, NAVY, 0)
    return svg_doc(200, 180, body)


GLYPHS = {   # drawn inside the 13x13 square (square spans x 4.5..17.5, y 3..16 in a 22x19 button)
    "minimize": '<rect x="8" y="12" width="6" height="2" fill="{c}"/>',
    "maximize": '<rect x="8" y="6.5" width="6" height="6" fill="none" stroke="{c}" stroke-width="1.6"/>',
    "restore": ('<rect x="9.5" y="5.5" width="5" height="5" fill="none" stroke="{c}" stroke-width="1.4"/>'
                '<rect x="7.5" y="8" width="5" height="5" fill="{bg}" stroke="{c}" stroke-width="1.4"/>'),
    "close": ('<path d="M8 6.5 L14 12.5 M14 6.5 L8 12.5" stroke="{c}" stroke-width="1.8" '
              'stroke-linecap="square" fill="none"/>'),
    "alldesktops": '<rect x="9" y="7.5" width="4" height="4" fill="{c}"/>',
    "keepabove": '<path d="M8 11.5 L11 7.5 L14 11.5" stroke="{c}" stroke-width="1.8" fill="none"/>',
    "keepbelow": '<path d="M8 7.5 L11 11.5 L14 7.5" stroke="{c}" stroke-width="1.8" fill="none"/>',
    "shade": '<rect x="8" y="7" width="6" height="2" fill="{c}"/>',
    "help": '<rect x="10" y="12" width="2" height="2" fill="{c}"/><rect x="10" y="6" width="2" height="4" fill="{c}"/>',
}


def aurorae_button(kind):
    """22x19 button: outlined navy square, glyph; hover/pressed = filled square with cyan (close: red) glyph."""
    W, H = 22, 19
    hover_glyph = RED if kind == "close" else CY
    states = {
        "active":      (None, NAVY, NAVY, 1.0),
        "inactive":    (None, NAVY, NAVY, 0.75),
        "hover":       (NAVY, NAVY, hover_glyph, 1.0),
        "pressed":     (NAVY, NAVY, RED_HOT if kind == "close" else "#9ff0e8", 1.0),
        "deactivated": (None, NAVY, NAVY, 0.35),
    }
    body = ""
    for i, (state, (fill, outline, glyph, op)) in enumerate(states.items()):
        ox = i * (W + 4)
        sq_fill = fill if fill else "none"
        bg = fill if fill else RED
        g = GLYPHS[kind].format(c=glyph, bg=bg)
        body += (f'  <g id="{state}-center" opacity="{op}">'
                 f'<rect x="{ox}" y="0" width="{W}" height="{H}" fill="#000" fill-opacity="0"/>'
                 f'<g transform="translate({ox},0)">'
                 f'<rect x="5.5" y="3" width="11" height="13" fill="none"/>'
                 f'<rect x="5" y="3.5" width="12" height="12" fill="{sq_fill}" stroke="{outline}" stroke-width="2"/>'
                 f'{g}</g></g>\n')
    return svg_doc(5 * (W + 4), H, body)


AURORAE_RC = f"""[General]
ActiveTextColor=17,30,41
InactiveTextColor=17,30,41,215
UseTextShadow=false
TitleAlignment=Center
TitleVerticalAlignment=Center
Animation=0
Shadow=false
DecorationPosition=0

[Layout]
BorderLeft={BL}
BorderRight={BR}
BorderBottom={BB}
TitleEdgeTop=0
TitleEdgeBottom=0
TitleEdgeLeft=8
TitleEdgeRight=4
TitleEdgeTopMaximized=0
TitleEdgeBottomMaximized=0
TitleEdgeLeftMaximized=8
TitleEdgeRightMaximized=4
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight={TITLE_H}
ButtonWidth=22
ButtonHeight={TITLE_H}
ButtonSpacing=0
ButtonMarginTop=0
ButtonMarginTopMaximized=0
ExplicitButtonSpacer=10
PaddingTop=0
PaddingBottom=0
PaddingLeft=0
PaddingRight=0
"""


def write_aurorae(out: Path):
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    (out / "decoration.svg").write_text(aurorae_decoration())
    for k in GLYPHS:
        (out / f"{k}.svg").write_text(aurorae_button(k))
    (out / "CyberNeonrc").write_text(AURORAE_RC)
    meta = ("[Desktop Entry]\nName=CyberNeon\n"
            "Comment=Fan-made netrunner decoration inspired by Cyberpunk 2077 by CD PROJEKT RED\n"
            "X-KDE-PluginInfo-Author=CyberNeon (fan made)\nX-KDE-PluginInfo-Name=CyberNeon\n"
            "X-KDE-PluginInfo-Version=1.0\nX-KDE-PluginInfo-License=GPL-2.0-or-later\n")
    (out / "metadata.desktop").write_text(meta)
    (out / "metadata.json").write_text(json.dumps({"KPlugin": {
        "Id": "CyberNeon", "Name": "CyberNeon", "Version": "1.0", "License": "GPL-2.0-or-later",
        "Description": "Fan-made netrunner decoration inspired by Cyberpunk 2077 by CD PROJEKT RED",
        "Authors": [{"Name": "CyberNeon (fan made)"}]}}, indent=2) + "\n")


# --------------------------------------------------------------------------- Plasma desktop theme
def frame_set(prefix, sizes, fills, hints, y0):
    """sizes: dict element->(w,h); fills: dict element->svg fragment builder(x,y,w,h)."""
    body, x = "", 0
    for el, (w, h) in sizes.items():
        body += f'  <g id="{prefix}{el}">' + fills[el](x, y0, w, h) + "</g>\n"
        x += w + 6
    for el, (w, h) in hints.items():
        body += f'  <rect id="{prefix}hint-{el}" x="{x}" y="{y0}" width="{w}" height="{h}" fill="#000" fill-opacity="0"/>\n'
        x += w + 6
    return body


def solid(col, op=None):
    o = f' fill-opacity="{op}"' if op is not None else ""
    return lambda x, y, w, h: f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{col}"{o}/>'


def top_bottom_line(x, y, w, h):
    # navy base, red glow rising 10 px, then 2 px red and 2 px hot core at the very bottom (14 px total)
    gid = f"gb{x}_{y}"
    return (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{RED}" stop-opacity="0"/><stop offset="1" stop-color="{RED}" stop-opacity="0.55"/>'
            f'</linearGradient></defs>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{NAVY}"/>'
            f'<rect x="{x}" y="{y}" width="{w}" height="10" fill="url(#{gid})"/>'
            f'<rect x="{x}" y="{y + 10}" width="{w}" height="2" fill="{RED}"/>'
            f'<rect x="{x}" y="{y + 12}" width="{w}" height="2" fill="{RED_HOT}"/>')


def dock_glow(x, y, w, h):
    # navy base with the red glow rising towards the bar (10 px inside the 76 px dock)
    gid = f"gg{x}_{y}"
    return (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="0">'
            f'<stop offset="0" stop-color="{RED}" stop-opacity="0"/><stop offset="1" stop-color="{RED}" stop-opacity="0.6"/>'
            f'</linearGradient></defs>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{NAVY}"/>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#{gid})"/>')


def bar_shadow(x, y, w, h):
    # the dock's red bar, drawn by KWin as the panel's right shadow: 8 px red + 6 px hot core (screen x 76-90)
    return (f'<rect x="{x}" y="{y}" width="8" height="{h}" fill="{RED}"/>'
            f'<rect x="{x + 8}" y="{y}" width="6" height="{h}" fill="{RED_HOT}"/>')


def dock_right_bar(x, y, w, h):
    # navy base, red glow 10 px into the dock, 8 px red, 6 px hot core at the screen-side edge (24 px total)
    gid = f"gr{x}_{y}"
    return (f'<defs><linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="0">'
            f'<stop offset="0" stop-color="{RED}" stop-opacity="0"/><stop offset="1" stop-color="{RED}" stop-opacity="0.6"/>'
            f'</linearGradient></defs>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{NAVY}"/>'
            f'<rect x="{x}" y="{y}" width="10" height="{h}" fill="url(#{gid})"/>'
            f'<rect x="{x + 10}" y="{y}" width="8" height="{h}" fill="{RED}"/>'
            f'<rect x="{x + 18}" y="{y}" width="6" height="{h}" fill="{RED_HOT}"/>')


def panel_background():
    body = ""
    # top bar (north): bottom neon line; left end = red block (90..110 px on screen, continues the dock bar)
    n_sizes = {"center": (10, 10), "top": (10, 1), "bottom": (10, 14), "left": (20, 10), "right": (1, 10),
               "topleft": (20, 1), "topright": (1, 1), "bottomleft": (20, 14), "bottomright": (1, 14)}
    n_fill = {"center": solid(NAVY), "top": solid(NAVY), "bottom": top_bottom_line, "left": solid(RED),
              "right": solid(NAVY), "topleft": solid(RED), "topright": solid(NAVY),
              "bottomleft": solid(RED), "bottomright": top_bottom_line}
    n_hint = {"top-margin": (1, 1), "bottom-margin": (1, 4), "left-margin": (1, 1), "right-margin": (6, 1)}
    body += frame_set("north-", n_sizes, n_fill, n_hint, 0)
    # dock (west): red bar on the right edge (76..90 px on screen)
    w_sizes = {"center": (10, 10), "top": (10, 1), "bottom": (10, 1), "left": (1, 10), "right": (24, 10),
               "topleft": (1, 1), "topright": (24, 1), "bottomleft": (1, 1), "bottomright": (24, 1)}
    w_fill = {"center": solid(NAVY), "top": solid(NAVY), "bottom": solid(NAVY), "left": solid(NAVY),
              "right": dock_right_bar, "topleft": solid(NAVY), "topright": dock_right_bar,
              "bottomleft": solid(NAVY), "bottomright": dock_right_bar}
    w_hint = {"top-margin": (1, 8), "bottom-margin": (1, 8), "left-margin": (8, 1), "right-margin": (22, 1)}  # Kickoff logo: 35 px at x=38
    body += frame_set("west-", w_sizes, w_fill, w_hint, 40)
    # any other location: navy with a 2 px red frame
    g_sizes = {k: v for k, v in {"center": (10, 10), "top": (10, 2), "bottom": (10, 2), "left": (2, 10), "right": (2, 10),
                                 "topleft": (2, 2), "topright": (2, 2), "bottomleft": (2, 2), "bottomright": (2, 2)}.items()}
    g_fill = {k: (solid(NAVY) if k == "center" else solid(RED)) for k in g_sizes}
    body += frame_set("", g_sizes, g_fill, {"top-margin": (1, 4), "bottom-margin": (1, 4), "left-margin": (4, 1), "right-margin": (4, 1)}, 80)
    return svg_doc(400, 110, body)


def tasks_svg():
    """widgets/tasks.svg: icontasks frames. Plasma sizes the task icons inside these margins, so they keep the
    dock icons at ~50 px centred at x=38 (clear of the red bar), like Budgie."""
    L, R, T, B = 4, 23, 7, 7   # 90 px dock: icons ~50 px, clear of the red bar (Plasma centres them at ~x=44)
    def frame(prefix, fill, tick=None):
        sizes = {"center": (10, 10), "top": (10, T), "bottom": (10, B), "left": (L, 10), "right": (R, 10),
                 "topleft": (L, T), "topright": (R, T), "bottomleft": (L, B), "bottomright": (R, B)}
        def mk(el):
            def f(x, y, w, h):
                s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill[0]}" fill-opacity="{fill[1]}"/>'
                if tick and el in ("left", "topleft", "bottomleft"):
                    s += f'<rect x="{x}" y="{y}" width="3" height="{h}" fill="{tick}"/>'
                return s
            return f
        fills = {el: mk(el) for el in sizes}
        hints = {"top-margin": (1, T), "bottom-margin": (1, B), "left-margin": (L, 1), "right-margin": (R, 1)}
        return frame_set(prefix, sizes, fills, hints, {"normal-": 0, "hover-": 30, "focus-": 60, "attention-": 90, "minimized-": 120}[prefix])
    body = (frame("normal-", (NAVY, 0)) + frame("minimized-", (NAVY, 0)) + frame("hover-", (CY, 0.10))
            + frame("focus-", (CY, 0.16), tick=CY) + frame("attention-", (RED, 0.22), tick=RED))
    return svg_doc(400, 160, body)


def chamfered(center, center_a, edge, border=2, cut=10, margin=10, mask=False):
    """FrameSvg with 45deg cut top-left / bottom-right corners (cut x cut), a `border` px outline on the outer edge.
    mask=True adds the mask-* elements (opaque, same shape) that KWin's blur uses as blur region."""
    def body_for(prefix, col_c, a_c, col_e, a_e):
        sizes = {"center": (10, 10), "top": (10, cut), "bottom": (10, cut), "left": (cut, 10), "right": (cut, 10),
                 "topleft": (cut, cut), "topright": (cut, cut), "bottomleft": (cut, cut), "bottomright": (cut, cut)}
        def edge_fn(side):
            def f(x, y, w, h):
                s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{col_c}" fill-opacity="{a_c}"/>'
                if a_e > 0:
                    if side == "top": s += f'<rect x="{x}" y="{y}" width="{w}" height="{border}" fill="{col_e}" fill-opacity="{a_e}"/>'
                    if side == "bottom": s += f'<rect x="{x}" y="{y + h - border}" width="{w}" height="{border}" fill="{col_e}" fill-opacity="{a_e}"/>'
                    if side == "left": s += f'<rect x="{x}" y="{y}" width="{border}" height="{h}" fill="{col_e}" fill-opacity="{a_e}"/>'
                    if side == "right": s += f'<rect x="{x + w - border}" y="{y}" width="{border}" height="{h}" fill="{col_e}" fill-opacity="{a_e}"/>'
                return s
            return f
        def cut_fn(which):
            def f(x, y, w, h):
                if which == "topleft":
                    tri = f"{x + w},{y} {x + w},{y + h} {x},{y + h}"
                    ln = f'<line x1="{x}" y1="{y + h - border / 2}" x2="{x + w - border / 2}" y2="{y}" stroke="{col_e}" stroke-opacity="{a_e}" stroke-width="{border * 1.4}"/>'
                else:
                    tri = f"{x},{y} {x + w},{y} {x},{y + h}"
                    ln = f'<line x1="{x + border / 2}" y1="{y + h}" x2="{x + w}" y2="{y + border / 2}" stroke="{col_e}" stroke-opacity="{a_e}" stroke-width="{border * 1.4}"/>'
                return f'<polygon points="{tri}" fill="{col_c}" fill-opacity="{a_c}"/>' + (ln if a_e > 0 else "")
            return f
        def square_fn(top, left):
            def f(x, y, w, h):
                s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{col_c}" fill-opacity="{a_c}"/>'
                if a_e > 0:
                    s += f'<rect x="{x}" y="{y if top else y + h - border}" width="{w}" height="{border}" fill="{col_e}" fill-opacity="{a_e}"/>'
                    s += f'<rect x="{x if left else x + w - border}" y="{y}" width="{border}" height="{h}" fill="{col_e}" fill-opacity="{a_e}"/>'
                return s
            return f
        fills = {"center": solid(col_c, a_c), "top": edge_fn("top"), "bottom": edge_fn("bottom"), "left": edge_fn("left"),
                 "right": edge_fn("right"), "topleft": cut_fn("topleft"), "bottomright": cut_fn("bottomright"),
                 "topright": square_fn(True, False), "bottomleft": square_fn(False, True)}
        hints = {"top-margin": (1, margin), "bottom-margin": (1, margin), "left-margin": (margin, 1), "right-margin": (margin, 1)} if prefix == "" else {}
        return frame_set(prefix, sizes, fills, hints, 0 if prefix == "" else 40)
    body = body_for("", center, center_a, edge, 1.0)
    if mask:
        body += body_for("mask-", "#000000", 1.0, "#000000", 0.0)
    return svg_doc(400, 80, body)


def framed(center, edge, border, margin):
    sizes = {"center": (10, 10), "top": (10, border), "bottom": (10, border), "left": (border, 10), "right": (border, 10),
             "topleft": (border, border), "topright": (border, border), "bottomleft": (border, border), "bottomright": (border, border)}
    fills = {k: (solid(center) if k == "center" else solid(edge)) for k in sizes}
    hints = {"top-margin": (1, margin), "bottom-margin": (1, margin), "left-margin": (margin, 1), "right-margin": (margin, 1)}
    return svg_doc(300, 40, frame_set("", sizes, fills, hints, 0))


def colors_ini():
    def rgb(h):
        h = h.lstrip("#"); return ",".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))
    common = {
        "ForegroundNormal": rgb("#7eddd5"), "ForegroundInactive": rgb("#4f8f8a"), "ForegroundActive": rgb(CY),
        "ForegroundLink": rgb(CY), "ForegroundVisited": rgb("#ff6b81"), "ForegroundNegative": rgb(RED),
        "ForegroundNeutral": rgb("#fcee0a"), "ForegroundPositive": rgb("#2ef2a8"),
        "DecorationFocus": rgb(CY), "DecorationHover": rgb(CY),
    }
    groups = {
        "Colors:Window": {"BackgroundNormal": rgb("#0f1b26"), "BackgroundAlternate": rgb(NAVY)},
        "Colors:View": {"BackgroundNormal": rgb(VIEW), "BackgroundAlternate": rgb("#0f1b26")},
        "Colors:Button": {"BackgroundNormal": rgb(NAVY), "BackgroundAlternate": rgb("#132230")},
        "Colors:Header": {"BackgroundNormal": rgb(NAVY), "BackgroundAlternate": rgb("#0f1b26")},
        "Colors:Header][Inactive": {"BackgroundNormal": rgb(NAVY), "BackgroundAlternate": rgb("#0f1b26")},
        "Colors:Complementary": {"BackgroundNormal": rgb(NAVY_DEEP), "BackgroundAlternate": rgb(NAVY)},
        "Colors:Tooltip": {"BackgroundNormal": rgb(VIEW), "BackgroundAlternate": rgb(NAVY),
                           "ForegroundNormal": rgb(CY)},
        "Colors:Selection": {"BackgroundNormal": rgb(CY), "BackgroundAlternate": rgb("#1e3d40"),
                             "ForegroundNormal": rgb(VIEW), "ForegroundInactive": rgb("#1e3d40"),
                             "ForegroundActive": rgb(VIEW), "ForegroundLink": rgb(VIEW)},
    }
    out = ("# CyberNeon colour scheme - FAN MADE, inspired by Cyberpunk 2077 by CD PROJEKT RED\n"
           "[ColorEffects:Disabled]\nColor=56,56,56\nColorAmount=0\nColorEffect=0\nContrastAmount=0.65\n"
           "ContrastEffect=1\nIntensityAmount=0.1\nIntensityEffect=2\n\n"
           "[ColorEffects:Inactive]\nChangeSelectionColor=true\nColor=112,111,110\nColorAmount=0.025\n"
           "ColorEffect=2\nContrastAmount=0.1\nContrastEffect=2\nEnable=false\nIntensityAmount=0\nIntensityEffect=0\n\n")
    for g, vals in groups.items():
        out += f"[{g}]\n" + "".join(f"{k}={v}\n" for k, v in {**common, **vals}.items()) + "\n"
    out += ("[General]\nColorScheme=CyberNeon\nName=CyberNeon\nshadeSortColumn=true\n\n[KDE]\ncontrast=4\n\n"
            f"[WM]\nactiveBackground={rgb(RED)}\nactiveBlend={rgb(RED)}\nactiveForeground={rgb(NAVY)}\n"
            f"inactiveBackground={rgb(RED_DIM)}\ninactiveBlend={rgb(RED_DIM)}\ninactiveForeground={rgb(NAVY)}\n")
    return out


def write_plasma(out: Path, colors: str):
    if out.exists():
        shutil.rmtree(out)
    (out / "widgets").mkdir(parents=True)
    (out / "dialogs").mkdir()
    (out / "widgets/panel-background.svg").write_text(panel_background())
    # popups, menus, notifications: cut corners + red outline; translucent variants (with blur masks) are used
    # automatically by Plasma when the compositor can blur
    (out / "dialogs/background.svg").write_text(chamfered(NAVY, 1.0, RED, 2, 10, 10))
    (out / "widgets/background.svg").write_text(chamfered(NAVY, 1.0, RED, 2, 10, 10))
    (out / "widgets/tooltip.svg").write_text(chamfered(VIEW, 1.0, CY, 1, 6, 6))
    (out / "translucent/dialogs").mkdir(parents=True)
    (out / "translucent/widgets").mkdir(parents=True)
    (out / "translucent/dialogs/background.svg").write_text(chamfered(NAVY, 0.82, RED, 2, 10, 10, mask=True))
    (out / "translucent/widgets/background.svg").write_text(chamfered(NAVY, 0.82, RED, 2, 10, 10, mask=True))
    (out / "translucent/widgets/tooltip.svg").write_text(chamfered(VIEW, 0.86, CY, 1, 6, 6, mask=True))
    (out / "widgets/tasks.svg").write_text(tasks_svg())
    (out / "colors").write_text(colors)
    (out / "plasmarc").write_text("[Settings]\nFallbackTheme=default\n")
    (out / "metadata.json").write_text(json.dumps({
        "KPlugin": {"Id": "CyberNeon", "Name": "CyberNeon", "Version": "1.0", "License": "GPL-2.0-or-later",
                    "Category": "", "Website": "",
                    "Description": "Fan-made netrunner Plasma theme inspired by Cyberpunk 2077 by CD PROJEKT RED",
                    "Authors": [{"Name": "CyberNeon (fan made)"}]},
        "X-Plasma-API-Minimum-Version": "6.0"}, indent=2) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--aurorae", required=True)
    ap.add_argument("--plasma", required=True)
    ap.add_argument("--colors", required=True, help="where to write CyberNeon.colors")
    a = ap.parse_args()
    colors = colors_ini()
    Path(a.colors).parent.mkdir(parents=True, exist_ok=True)
    Path(a.colors).write_text(colors)
    write_aurorae(Path(a.aurorae))
    write_plasma(Path(a.plasma), colors)
    print("KDE themes:", a.aurorae, a.plasma, a.colors)


if __name__ == "__main__":
    main()
