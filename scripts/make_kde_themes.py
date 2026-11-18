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


def cframe(prefix, y0, fill, fa, line, la, border=2, cut=10, tl=True, br=True, margin=None, tick=None):
    """One FrameSvg frame (all 9 elements, ids prefixed) with 45deg cuts at top-left / bottom-right, a `border` px
    outline on the outer edge and an optional tick (side, colour, width) inside one edge."""
    c = max(cut, border, 1)
    sizes = {"center": (10, 10), "top": (10, c), "bottom": (10, c), "left": (c, 10), "right": (c, 10),
             "topleft": (c, c), "topright": (c, c), "bottomleft": (c, c), "bottomright": (c, c)}

    def base(x, y, w, h):
        return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" fill-opacity="{fa}"/>'

    def ln(x, y, w, h):
        return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{line}" fill-opacity="{la}"/>' if la > 0 and border > 0 else ""

    def tk(side, x, y, w, h):
        if not tick or tick[0] != side:
            return ""
        _, col, tw = tick
        if side == "left": return f'<rect x="{x + border}" y="{y}" width="{tw}" height="{h}" fill="{col}"/>'
        if side == "bottom": return f'<rect x="{x}" y="{y + h - border - tw}" width="{w}" height="{tw}" fill="{col}"/>'
        return ""

    def edge(side):
        def f(x, y, w, h):
            s = base(x, y, w, h)
            if side == "top": s += ln(x, y, w, border)
            if side == "bottom": s += ln(x, y + h - border, w, border)
            if side == "left": s += ln(x, y, border, h)
            if side == "right": s += ln(x + w - border, y, border, h)
            return s + tk(side, x, y, w, h)
        return f

    def corner(which, is_cut):
        def f(x, y, w, h):
            top, left = which.startswith("top"), which.endswith("left")
            if not is_cut:
                s = base(x, y, w, h)
                s += ln(x, y if top else y + h - border, w, border) + ln(x if left else x + w - border, y, border, h)
                if tick and tick[0] == "left" and left: s += f'<rect x="{x + border}" y="{y + (border if top else 0)}" width="{tick[2]}" height="{h - border}" fill="{tick[1]}"/>'
                if tick and tick[0] == "bottom" and not top: s += f'<rect x="{x + (border if left else 0)}" y="{y + h - border - tick[2]}" width="{w - border}" height="{tick[2]}" fill="{tick[1]}"/>'
                return s
            if which == "topleft":
                tri = f"{x + w},{y} {x + w},{y + h} {x},{y + h}"
                stroke = f'<line x1="{x}" y1="{y + h - border / 2}" x2="{x + w - border / 2}" y2="{y}" stroke="{line}" stroke-opacity="{la}" stroke-width="{border * 1.42}"/>'
            else:   # bottomright
                tri = f"{x},{y} {x + w},{y} {x},{y + h}"
                stroke = f'<line x1="{x + border / 2}" y1="{y + h}" x2="{x + w}" y2="{y + border / 2}" stroke="{line}" stroke-opacity="{la}" stroke-width="{border * 1.42}"/>'
            return f'<polygon points="{tri}" fill="{fill}" fill-opacity="{fa}"/>' + (stroke if la > 0 and border > 0 else "")
        return f

    fills = {"center": lambda x, y, w, h: base(x, y, w, h), "top": edge("top"), "bottom": edge("bottom"),
             "left": edge("left"), "right": edge("right"),
             "topleft": corner("topleft", tl and cut > 0), "bottomright": corner("bottomright", br and cut > 0),
             "topright": corner("topright", False), "bottomleft": corner("bottomleft", False)}
    hints = {}
    if margin is not None:
        hints = {"top-margin": (1, margin), "bottom-margin": (1, margin), "left-margin": (margin, 1), "right-margin": (margin, 1)}
    return frame_set(prefix, sizes, fills, hints, y0)


def glow_shadow(color, cut=10, out=22, strength=0.6):
    """shadow-* elements: a neon glow around a cut-corner frame, as embedded PNG tiles. The tiles reach `cut` px
    under the window (so the glow follows the 45deg corners); shadow-hint-*-margin = `out` = glow outside."""
    import base64, io, math
    from PIL import Image, ImageChops, ImageFilter
    T = out + cut                       # tile size
    S = 2 * T + 40                      # sample window (frame) + glow, big enough for 9 slices
    sc = 4                              # supersampling
    shape = Image.new("L", (S * sc, S * sc), 0)
    from PIL import ImageDraw
    d = ImageDraw.Draw(shape)
    x0, y0, x1, y1 = out * sc, out * sc, (S - out) * sc, (S - out) * sc
    c = cut * sc
    d.polygon([(x0 + c, y0), (x1, y0), (x1, y1 - c), (x1 - c, y1), (x0, y1), (x0, y0 + c)], fill=255)
    shape = shape.resize((S, S), Image.LANCZOS)
    rim = shape.filter(ImageFilter.MaxFilter(3))
    g1 = rim.filter(ImageFilter.GaussianBlur(out / 4)); g2 = rim.filter(ImageFilter.GaussianBlur(out / 2))
    glow = ImageChops.add(g1.point(lambda v: int(v * 0.8)), g2.point(lambda v: int(v * 0.7)))
    glow = ImageChops.subtract(glow, shape)                         # only outside the frame
    glow = glow.point(lambda v: int(min(255, v * strength * 1.6)))
    h = color.lstrip("#"); rgb = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    img = Image.new("RGBA", (S, S), rgb + (0,)); img.putalpha(glow)
    m = S // 2
    tiles = {"topleft": (0, 0, T, T), "top": (m, 0, m + 2, T), "topright": (S - T, 0, S, T),
             "left": (0, m, T, m + 2), "right": (S - T, m, S, m + 2),
             "bottomleft": (0, S - T, T, S), "bottom": (m, S - T, m + 2, S), "bottomright": (S - T, S - T, S, S)}
    body, x = "", 0
    for name, box in tiles.items():
        tile = img.crop(box); buf = io.BytesIO(); tile.save(buf, "PNG")
        b64 = base64.b64encode(buf.getvalue()).decode()
        w, hh = tile.size
        body += (f'  <image id="shadow-{name}" x="{x}" y="300" width="{w}" height="{hh}" '
                 f'xlink:href="data:image/png;base64,{b64}"/>\n')
        x += w + 6
    for side, (w, hh) in {"top": (1, out), "bottom": (1, out), "left": (out, 1), "right": (out, 1)}.items():
        body += f'  <rect id="shadow-hint-{side}-margin" x="{x}" y="300" width="{w}" height="{hh}" fill="#000" fill-opacity="0"/>\n'
        x += w + 6
    return body


def svg_doc_x(w, h, body):
    """svg_doc with the xlink namespace (embedded images)"""
    return (f'<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" '
            f'xmlns:xlink="http://www.w3.org/1999/xlink" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}</svg>\n')


def glass_frame(fill, fa, line, glow, cut=10, border=2, margin=8, translucent=False, glow_strength=0.6):
    """panel / dialog / tooltip background: cut-corner glass frame + neon glow shadow (+ blur mask)"""
    body = cframe("", 0, fill, fa, line, 1.0, border, cut, margin=margin)
    if translucent:
        body += cframe("mask-", 60, "#000000", 1.0, "#000000", 0.0, 0, cut)
    body += glow_shadow(glow, cut, 22, glow_strength)
    return svg_doc_x(900, 400, body)


def tasks_svg():
    """widgets/tasks.svg for the floating bottom dock: transparent idle, cut-corner cyan hover, active window =
    cyan plate with a bottom tick, attention = red."""
    body = ""
    for i, (prefix, fill, fa, la, tick) in enumerate([
            ("normal-", NAVY, 0.0, 0.0, None), ("minimized-", NAVY, 0.0, 0.0, None),
            ("hover-", CY, 0.12, 0.7, None), ("focus-", CY, 0.18, 0.9, ("bottom", CY, 3)),
            ("attention-", RED, 0.22, 1.0, ("bottom", RED, 3))]):
        body += cframe(prefix, i * 40, fill, fa, CY if prefix != "attention-" else RED, la, 1, 7, margin=6, tick=tick)
    return svg_doc(500, 220, body)


def button_svg():
    """widgets/button.svg (Plasma components): cut-corner cyan buttons"""
    body = ""
    spec = [("normal-", CY, 0.06, 0.5), ("pressed-", CY, 0.30, 1.0), ("hover-", CY, 0.10, 1.0), ("focus-", CY, 0.0, 1.0),
            ("toolbutton-hover-", CY, 0.12, 0.7), ("toolbutton-pressed-", CY, 0.28, 1.0), ("toolbutton-focus-", CY, 0.0, 1.0)]
    for i, (prefix, fill, fa, la) in enumerate(spec):
        body += cframe(prefix, i * 40, fill, fa, CY, la, 1, 6, margin=5)
    body += cframe("mask-normal-", len(spec) * 40, "#000000", 1.0, "#000000", 0.0, 0, 6)
    return svg_doc(500, 40 * len(spec) + 40, body)


def lineedit_svg():
    """widgets/lineedit.svg: fields with the bottom-right corner cut (also the lock screen password field)"""
    body = (cframe("base-", 0, VIEW, 0.85, CY, 0.45, 1, 7, tl=False, margin=6)
            + cframe("hover-", 40, VIEW, 0.0, CY, 0.8, 1, 7, tl=False, margin=6)
            + cframe("focus-", 80, VIEW, 0.0, CY, 1.0, 2, 7, tl=False, margin=6)
            + cframe("focusframe-", 120, VIEW, 0.0, CY, 1.0, 2, 7, tl=False, margin=6)
            + '  <rect id="hint-focus-over-base" x="0" y="170" width="1" height="1" fill="#000" fill-opacity="0"/>\n')
    return svg_doc(500, 180, body)


def viewitem_svg():
    """widgets/viewitem.svg: list highlights (Kickoff, KRunner, popups) with a cyan tick on the left"""
    body = ""
    for i, (prefix, fa, la, tick) in enumerate([("normal-", 0.0, 0.0, None), ("hover-", 0.10, 0.45, ("left", CY, 3)),
                                                ("selected-", 0.20, 0.8, ("left", CY, 3)), ("selected+hover-", 0.28, 1.0, ("left", CY, 3))]):
        body += cframe(prefix, i * 40, CY, fa, CY, la, 1, 6, margin=4, tick=tick)
    return svg_doc(500, 170, body)


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
    """Plasma desktop theme v3: floating glass panels and popups with cut corners, neon glow shadows and blur masks,
    cut-corner buttons/fields/list highlights."""
    if out.exists():
        shutil.rmtree(out)
    for d in ("widgets", "dialogs", "translucent/widgets", "translucent/dialogs"):
        (out / d).mkdir(parents=True)
    w = lambda rel, s: (out / rel).write_text(s)
    # panels: opaque fallback + translucent glass (blurred behind, cut-corner mask), red neon glow
    w("widgets/panel-background.svg", glass_frame(NAVY, 0.97, RED, RED, cut=12, margin=4))
    w("translucent/widgets/panel-background.svg", glass_frame(NAVY_DEEP, 0.62, RED, RED, cut=12, margin=4, translucent=True))
    # popups, menus, notifications, widget backgrounds
    for rel in ("dialogs/background.svg", "widgets/background.svg"):
        w(rel, glass_frame(NAVY, 0.97, RED, RED, cut=10, margin=10, glow_strength=0.5))
        w("translucent/" + rel, glass_frame(NAVY_DEEP, 0.72, RED, RED, cut=10, margin=10, translucent=True, glow_strength=0.5))
    w("widgets/tooltip.svg", glass_frame(VIEW, 0.97, CY, CY, cut=6, border=1, margin=6, glow_strength=0.45))
    w("translucent/widgets/tooltip.svg", glass_frame(VIEW, 0.8, CY, CY, cut=6, border=1, margin=6, translucent=True, glow_strength=0.45))
    w("widgets/tasks.svg", tasks_svg())
    w("widgets/button.svg", button_svg())
    w("widgets/lineedit.svg", lineedit_svg())
    w("widgets/viewitem.svg", viewitem_svg())
    w("colors", colors)
    w("plasmarc", "[Settings]\nFallbackTheme=default\n\n[ContrastEffect]\nenabled=true\ncontrast=0.9\nintensity=0.9\nsaturation=1.6\n\n"
                  "[AdaptiveTransparency]\nenabled=true\n\n[BlurBehindEffect]\nenabled=true\n")
    w("metadata.json", json.dumps({
        "KPlugin": {"Id": "CyberNeon", "Name": "CyberNeon", "Version": "3.0", "License": "GPL-2.0-or-later",
                    "Category": "", "Website": "",
                    "Description": "Fan-made netrunner Plasma theme (glass, neon glow) inspired by Cyberpunk 2077 by CD PROJEKT RED",
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
