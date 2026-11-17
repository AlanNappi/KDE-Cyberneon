#!/usr/bin/env python3
"""CyberNeon netrunner 'hacking' wallpaper (original artwork).

usage: make_wallpaper.py OUT.png [--login] [--label TEXT] [--logo FILE] [--monitor-width PX]

Rendered at 3840x2160. With picture-options 'zoom' on a 16:9 primary monitor of width
--monitor-width, the red fillet that joins the dock bar and the top bar lands exactly on the
panel corner (dock 90 px wide, top bar 34 px high, red top block up to x=110).
--logo  : an image you provide (transparent background) placed in the centre sigil, tinted neon red.
          Without it an original chevron emblem is drawn. No third-party logo ships with the repo.
--login : variant for the login screen / GRUB (no panel fillet).
"""
import argparse, math, random, sys
import cairo
from PIL import Image, ImageChops

_ap = argparse.ArgumentParser()
_ap.add_argument("out")
_ap.add_argument("--login", action="store_true")
_ap.add_argument("--label", default="N E T R U N N E R")
_ap.add_argument("--logo", default="")
_ap.add_argument("--monitor-width", type=int, default=1920)
ARGS = _ap.parse_args()
OUT = ARGS.out

W, H = 3840, 2160
S = W / ARGS.monitor_width   # image px per screen px on the primary monitor
LOGIN = ARGS.login
random.seed(2077)

def rgb(h, a=1.0):
    h = h.lstrip("#"); return tuple(int(h[i:i+2], 16)/255 for i in (0, 2, 4)) + (a,)

CY, RED, NAVY, DIM = "#5beedc", "#ff2a4f", "#070d1a", "#1b3a4a"
MONO, UI = "JetBrainsMono Nerd Font Mono", "Chakra Petch"

surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, W, H)
cr = cairo.Context(surf)
g = cairo.LinearGradient(0, 0, 0, H)
g.add_color_stop_rgb(0, *rgb("#060b16")[:3]); g.add_color_stop_rgb(1, *rgb("#0a1426")[:3])
cr.set_source(g); cr.paint()

def font(face=MONO, size=22, bold=False):
    cr.select_font_face(face, cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD if bold else cairo.FONT_WEIGHT_NORMAL)
    cr.set_font_size(size)

def text(s, x, y, col=CY, a=1.0, face=MONO, size=22, bold=False):
    font(face, size, bold); cr.set_source_rgba(*rgb(col, a)); cr.move_to(x, y); cr.show_text(s)

def line(pts, col, a, lw):
    cr.new_path(); cr.move_to(*pts[0])
    for p in pts[1:]: cr.line_to(*p)
    cr.set_source_rgba(*rgb(col, a)); cr.set_line_width(lw); cr.stroke()

def poly(pts, col, a=1.0, stroke=None, lw=3):
    cr.new_path(); cr.move_to(*pts[0])
    for p in pts[1:]: cr.line_to(*p)
    cr.close_path()
    if col: cr.set_source_rgba(*rgb(col, a)); cr.fill_preserve() if stroke else cr.fill()
    if stroke: cr.set_source_rgba(*rgb(stroke[0], stroke[1])); cr.set_line_width(lw); cr.stroke()

hexb = lambda: "%02X" % random.randint(0, 255)

# ------------------------------------------------------------- 1. hex dump wall
font(MONO, 20)
for row, y in enumerate(range(60, H, 34)):
    addr = "0x%06X" % (0x3F0000 + row * 16)
    text(addr, 40, y, CY, 0.05, size=20)
    x = 210
    while x < W - 60:
        b = hexb()
        r = random.random()
        if r < 0.004: text(b, x, y, RED, 0.55, size=20)
        elif r < 0.02: text(b, x, y, CY, 0.30, size=20)
        else: text(b, x, y, CY, 0.045, size=20)
        x += 46

# ------------------------------------------------------------- 2. circuit traces
def trace(x, y, steps, col, a, lw):
    pts = [(x, y)]
    d = random.choice([(1, 0), (0, 1), (1, 1), (1, -1)])
    for _ in range(steps):
        if random.random() < 0.3:
            d = random.choice([(1, 0), (0, 1), (1, 1), (1, -1), (0, -1)])
        L = random.choice([40, 80, 120])
        x, y = x + d[0]*L, y + d[1]*L
        pts.append((x, y))
    line(pts, col, a, lw)
    for px, py in (pts[0], pts[-1]):
        cr.new_path(); cr.arc(px, py, 7, 0, 2*math.pi); cr.set_source_rgba(*rgb(col, a + 0.1)); cr.set_line_width(3); cr.stroke()
    return pts

for _ in range(70):
    trace(random.uniform(0, W), random.uniform(0, H), random.randint(4, 12), "#1d4256", 0.55, 3)
for _ in range(14):  # live traces with a data pulse
    pts = trace(random.uniform(0, W), random.uniform(0, H), random.randint(5, 10), CY, 0.28, 3)
    i = random.randint(0, len(pts) - 2)
    line([pts[i], pts[i+1]], CY, 0.9, 4)

# ------------------------------------------------------------- 3. falling data streams
for _ in range(26):
    x = random.choice(range(80, W - 80, 46)); y0 = random.uniform(-200, H*0.6); n = random.randint(10, 26)
    for k in range(n):
        a = 0.05 + 0.35 * (k / n)
        text(hexb()[0], x, y0 + k*34, CY, a, size=24)
    text(hexb()[0], x, y0 + n*34, "#d8fffa", 0.9, size=24, bold=True)

# ------------------------------------------------------------- 4. central ICE-breaker sigil
cx, cy = 1920, 1010
def ring(r, col, a, lw, a0=0, a1=2*math.pi):
    cr.new_path(); cr.arc(cx, cy, r, a0, a1); cr.set_source_rgba(*rgb(col, a)); cr.set_line_width(lw); cr.stroke()

cr.new_path(); cr.arc(cx, cy, 560, 0, 2*math.pi); cr.set_source_rgba(*rgb(NAVY, 0.75)); cr.fill()
ring(560, CY, 0.25, 3)
for k in range(180):  # tick ring
    t = 2*math.pi*k/180; L = 30 if k % 10 == 0 else 12
    a = 0.8 if k % 10 == 0 else 0.35
    line([(cx + 540*math.cos(t), cy + 540*math.sin(t)), (cx + (540-L)*math.cos(t), cy + (540-L)*math.sin(t))], CY, a, 3)
for k in range(6):  # segmented arcs
    st = k*math.pi/3 + 0.12
    ring(470, CY, 0.85, 12, st, st + math.pi/3 - 0.24)
ring(420, RED, 0.9, 8, -math.pi*0.85, -math.pi*0.45)
ring(420, RED, 0.9, 8, math.pi*0.15, math.pi*0.25)
cr.set_dash([18, 14]); ring(380, CY, 0.45, 3); cr.set_dash([])
hexpts = [(cx + 300*math.cos(math.pi/6 + k*math.pi/3), cy + 300*math.sin(math.pi/6 + k*math.pi/3)) for k in range(6)]
poly(hexpts, "#0b1726", 0.95, (CY, 0.9), 5)
inner = [(cx + 255*math.cos(math.pi/6 + k*math.pi/3), cy + 255*math.sin(math.pi/6 + k*math.pi/3)) for k in range(6)]
poly(inner, None, stroke=(CY, 0.35), lw=2)
# centre emblem: a logo you provide (tinted neon red, glow from the bloom pass) or the original chevrons
if ARGS.logo:
    from PIL import Image as _Im
    _src = _Im.open(ARGS.logo).convert("RGBA")
    _src = _src.crop(_src.getbbox())
    _sz = 380
    _m = _src.split()[3].resize((_sz, _sz), _Im.LANCZOS)
    _logo = _Im.new("RGBA", (_sz, _sz), (255, 42, 79, 0)); _logo.putalpha(_m)
    _lp = OUT + ".logo.png"; _logo.save(_lp)
    _ls = cairo.ImageSurface.create_from_png(_lp)
    cr.set_source_surface(_ls, cx - _sz / 2, cy - _sz / 2 - 10); cr.paint()
    import os as _os; _os.remove(_lp)
else:
    for k, a in enumerate((0.35, 0.6, 1.0)):  # nested chevrons
        poly([(cx - 150 + k*30, cy - 90 + k*45), (cx - 110 + k*30, cy - 90 + k*45), (cx, cy + 20 + k*45),
              (cx + 110 - k*30, cy - 90 + k*45), (cx + 150 - k*30, cy - 90 + k*45), (cx, cy + 75 + k*45)], CY, a)
    poly([(cx - 46, cy - 170), (cx + 46, cy - 170), (cx + 46, cy - 146), (cx - 46, cy - 146)], RED, 1)
font(UI, 44, True); s = ARGS.label; ext = cr.text_extents(s)
text(s, cx - ext.x_advance/2, cy + 230, RED, 1.0, UI, 44, True)
for ang, lab in ((-2.45, "NODE 0x3F"), (-0.65, "SECTOR 07"), (0.55, "TRACE: OFF"), (2.55, "LINK 98.7%")):
    text(lab, cx + 610*math.cos(ang) - 70, cy + 610*math.sin(ang), CY, 0.7, UI, 30, True)

# ------------------------------------------------------------- 5. terminal window (left)
tx, ty, tw, th = 230, 330, 1040, 860
poly([(tx, ty), (tx + tw, ty), (tx + tw, ty + th - 50), (tx + tw - 50, ty + th), (tx, ty + th)], NAVY, 0.88, (CY, 0.8), 3)
poly([(tx, ty), (tx + tw, ty), (tx + tw, ty + 46), (tx + 30, ty + 46), (tx, ty + 16)], RED, 1)
text("root@netrun: ~/jack-in", tx + 48, ty + 33, NAVY, 1, UI, 26, True)
log = [
    (CY, 1.0, "> jack_in --target 10.0.66.13 --stealth"),
    (CY, 0.55, "[ OK ] neural handshake ........ 12ms"),
    (CY, 0.55, "[ OK ] proxy chain: 7 hops"),
    (RED, 0.95, "[ICE ] black wall detected: layer 3"),
    (CY, 1.0, "> load icebreaker.daemon"),
    (CY, 0.55, "[ OK ] payload mapped @ 0x7FA3C000"),
    (CY, 0.55, "[ .. ] cracking 2048-bit session key"),
    (CY, 0.55, "       ##################----  78%"),
    (RED, 0.95, "[WARN] trace program active: 00:41"),
    (CY, 1.0, "> exfil --stream /vault/blueprints/*"),
    (CY, 0.55, "[ OK ] 1.2 GB @ 340 MB/s"),
    (CY, 1.0, "> wipe --logs && disconnect"),
]
for i, (c, a, s) in enumerate(log):
    text(s, tx + 34, ty + 110 + i*56, c, a, MONO, 30)
font(MONO, 30); _e = cr.text_extents(log[-1][2])
cr.set_source_rgba(*rgb(CY, 1)); cr.rectangle(tx + 34 + _e.x_advance + 8, ty + 110 + 11*56 - 26, 18, 32); cr.fill()

# ------------------------------------------------------------- 6. network graph (top right)
nodes = [(2820, 330), (3080, 250), (3330, 380), (3560, 280), (2950, 560), (3220, 620), (3480, 560), (3650, 760), (3100, 860)]
edges = [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5), (5, 6), (6, 7), (2, 5), (5, 8), (3, 6), (1, 4)]
path_e = {(0, 4), (4, 5), (5, 6), (6, 7)}
for a, b in edges:
    hot = (a, b) in path_e
    line([nodes[a], nodes[b]], CY if hot else DIM, 0.9 if hot else 0.8, 4 if hot else 3)
for i, (x, y) in enumerate(nodes):
    col = RED if i == 7 else CY
    poly([(x - 16, y - 16), (x + 16, y - 16), (x + 16, y + 16), (x - 16, y + 16)], NAVY, 1, (col, 1), 4)
    if i in (0, 4, 5, 6, 7):
        cr.rectangle(x - 7, y - 7, 14, 14); cr.set_source_rgba(*rgb(col, 1)); cr.fill()
text("TARGET", 3610, 830, RED, 1, UI, 30, True)
text("ROUTE // 4 HOPS", 2800, 950, CY, 0.7, UI, 28, True)

# ------------------------------------------------------------- 7. warning strip (bottom left)
by = 1860
cr.save(); cr.rectangle(230, by, 760, 34); cr.clip()
cr.set_source_rgba(*rgb(RED, 1)); cr.paint()
for x in range(200, 1020, 44):
    poly([(x, by + 34), (x + 22, by + 34), (x + 56, by), (x + 34, by)], NAVY, 1)
cr.restore()
text("!! INTRUSION COUNTERMEASURES ARMED !!", 1020, by + 28, RED, 0.95, UI, 32, True)

# ------------------------------------------------------------- 8. red fillet (panel corner), desktop only
if not LOGIN:
    poly([(90*S, 34*S), (110*S, 34*S), (90*S, 54*S)], RED, 1)

base = OUT + ".tmp.png"
surf.write_to_png(base)

# ------------------------------------------------------------- post: glitch + scanlines
img = Image.open(base).convert("RGB")
# neon bloom: red tubes glow hard, cyan glows softly
from PIL import ImageFilter
rr, gg, bb = img.split()
redmask = ImageChops.subtract(rr, ImageChops.lighter(gg, bb)).point(lambda v: 255 if v > 120 else 0)
redglow = Image.merge("RGB", (redmask, redmask.point(lambda v: v * 42 // 255), redmask.point(lambda v: v * 79 // 255)))
img = ImageChops.screen(img, redglow.filter(ImageFilter.GaussianBlur(14)))
img = ImageChops.screen(img, redglow.filter(ImageFilter.GaussianBlur(40)).point(lambda v: int(v * 0.7)))
bright = img.point(lambda v: 0 if v < 190 else v)
img = ImageChops.screen(img, bright.filter(ImageFilter.GaussianBlur(10)).point(lambda v: int(v * 0.35)))
for _ in range(9):
    y0 = random.choice([random.randint(1250, 1800), random.randint(1960, 2120)]); hh = random.randint(2, 12)
    strip = ImageChops.offset(img.crop((0, y0, W, y0 + hh)), random.choice([-1, 1]) * random.randint(30, 140), 0)
    img.paste(strip, (0, y0))
r, gch, b = img.split()
img = Image.merge("RGB", (ImageChops.offset(r, 2, 0), gch, ImageChops.offset(b, -2, 0)))
scan = Image.new("L", (W, H), 0)
row = Image.new("L", (W, 1), 18)
for yy in range(0, H, 4):
    scan.paste(row, (0, yy))
img = ImageChops.subtract(img, Image.merge("RGB", (scan,)*3))
# keep the terminal title bar readable (no bloom on the text)
crisp = Image.open(base).convert("RGB")
img.paste(crisp.crop((260, 334, 1270, 374)), (260, 334))
# keep the panel fillet crisp
if not LOGIN:
    _b = (int(85*S), int(30*S), int(115*S), int(57.5*S))
    img.paste(Image.open(base).convert("RGB").crop(_b), _b[:2])
img.save(OUT, optimize=True)
import os; os.remove(base)
print("saved", OUT)
