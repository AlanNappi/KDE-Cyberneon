#!/usr/bin/env python3
"""CyberNeon-Cursors: glowing HUD-style X cursors (original artwork); Xcursor files are written directly.

usage: make_cursors.py [OUT_DIR]   (default ~/.local/share/icons/CyberNeon-Cursors)
       PREVIEW=sheet.png make_cursors.py ...   also renders a preview sheet
"""
import math, os, struct, shutil, sys
from pathlib import Path
import cairo

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / ".local/share/icons/CyberNeon-Cursors"
if OUT.exists():
    shutil.rmtree(OUT)
CUR = OUT / "cursors"
CUR.mkdir(parents=True)
SIZES = (24, 32, 48, 64)

CY = (0x5b/255, 0xee/255, 0xdc/255)
RED = (0xff/255, 0x2a/255, 0x4f/255)
NAVY = (0x07/255, 0x0d/255, 0x1a/255)


def P(pts, s):
    return [(x*s, y*s) for x, y in pts]


def path(cr, pts, close=True):
    cr.new_path(); cr.move_to(*pts[0])
    for p in pts[1:]:
        cr.line_to(*p)
    if close:
        cr.close_path()


def glow_stroke(cr, pts, s, col=CY, lw=1.4, close=True, glow=True):
    """dark outline + soft glow + crisp neon line"""
    cr.set_line_join(cairo.LINE_JOIN_MITER); cr.set_line_cap(cairo.LINE_CAP_SQUARE)
    if glow:
        for w, a in ((5.0, 0.10), (3.6, 0.18)):
            path(cr, pts, close); cr.set_source_rgba(*col, a); cr.set_line_width(w*s); cr.stroke()
    path(cr, pts, close); cr.set_source_rgba(*NAVY, 0.95); cr.set_line_width((lw + 1.6)*s); cr.stroke()
    path(cr, pts, close); cr.set_source_rgba(*col, 1); cr.set_line_width(lw*s); cr.stroke()


def fill(cr, pts, col, a=1.0):
    path(cr, pts); cr.set_source_rgba(*col, a); cr.fill()


# ---------------------------------------------------------------- shapes (24 grid)
BLADE = [(2, 1.8), (2, 18.6), (6.3, 14.7), (9.0, 20.9), (11.8, 19.7), (9.2, 13.7), (15.0, 13.7)]


def arrow(cr, s, main=CY, accent=RED):
    pts = P(BLADE, s)
    fill(cr, pts, NAVY, 0.80)
    glow_stroke(cr, pts, s, main)
    # inner circuit line + red tip
    path(cr, P([(4.0, 6.4), (4.0, 13.2), (5.6, 11.8)], s), close=False)
    cr.set_source_rgba(*main, 0.9); cr.set_line_width(1.0*s); cr.stroke()
    fill(cr, P([(2.3, 2.6), (2.3, 6.0), (5.2, 4.9)], s), accent)
    return (2, 2)


def pointer(cr, s):
    # red blade with cyan lock-on brackets around the tip
    arrow(cr, s, main=RED, accent=CY)
    for pts in ([(9.5, 1.5), (13, 1.5), (13, 5)], [(17.5, 9), (17.5, 12.5), (14, 12.5)]):
        glow_stroke(cr, P(pts, s), s, CY, 1.2, close=False, glow=False)
    return (2, 2)


def ibeam(cr, s):
    glow_stroke(cr, P([(12, 4), (12, 20)], s), s, CY, 1.5, close=False)
    for pts in ([(8.5, 3), (10, 3), (10, 5)], [(15.5, 3), (14, 3), (14, 5)],
                [(8.5, 21), (10, 21), (10, 19)], [(15.5, 21), (14, 21), (14, 19)]):
        glow_stroke(cr, P(pts, s), s, CY, 1.1, close=False, glow=False)
    fill(cr, P([(11.3, 11.3), (12.7, 11.3), (12.7, 12.7), (11.3, 12.7)], s), RED)
    return (12, 12)


def reticle(cr, s):
    for pts in ([(12, 2), (12, 8.5)], [(12, 15.5), (12, 22)], [(2, 12), (8.5, 12)], [(15.5, 12), (22, 12)]):
        glow_stroke(cr, P(pts, s), s, CY, 1.3, close=False)
    for pts in ([(5, 8), (5, 5), (8, 5)], [(16, 5), (19, 5), (19, 8)], [(19, 16), (19, 19), (16, 19)], [(8, 19), (5, 19), (5, 16)]):
        glow_stroke(cr, P(pts, s), s, CY, 1.0, close=False, glow=False)
    fill(cr, P([(11.2, 11.2), (12.8, 11.2), (12.8, 12.8), (11.2, 12.8)], s), RED)
    return (12, 12)


def dbl(cr, s, angle):
    cr.save(); cr.translate(12*s, 12*s); cr.rotate(angle); cr.translate(-12*s, -12*s)
    pts = P([(2, 12), (7, 7), (7, 10.4), (17, 10.4), (17, 7), (22, 12), (17, 17), (17, 13.6), (7, 13.6), (7, 17)], s)
    fill(cr, pts, NAVY, 0.8); glow_stroke(cr, pts, s, CY, 1.2)
    fill(cr, P([(11, 11), (13, 11), (13, 13), (11, 13)], s), RED)
    cr.restore()
    return (12, 12)


def move(cr, s):
    for a in (0, math.pi/2):
        cr.save(); cr.translate(12*s, 12*s); cr.rotate(a); cr.translate(-12*s, -12*s)
        pts = P([(2, 12), (6.5, 7.5), (6.5, 10.6), (17.5, 10.6), (17.5, 7.5), (22, 12), (17.5, 16.5), (17.5, 13.4), (6.5, 13.4), (6.5, 16.5)], s)
        glow_stroke(cr, pts, s, CY, 1.1)
        cr.restore()
    fill(cr, P([(10.5, 10.5), (13.5, 10.5), (13.5, 13.5), (10.5, 13.5)], s), RED)
    return (12, 12)


def forbidden(cr, s):
    for w, a in ((5, 0.12), (3.6, 0.2)):
        cr.new_path(); cr.arc(12*s, 12*s, 8*s, 0, 2*math.pi); cr.set_source_rgba(*RED, a); cr.set_line_width(w*s); cr.stroke()
    cr.new_path(); cr.arc(12*s, 12*s, 8*s, 0, 2*math.pi); cr.set_source_rgba(*NAVY, 0.95); cr.set_line_width(3.6*s); cr.stroke()
    cr.new_path(); cr.arc(12*s, 12*s, 8*s, 0, 2*math.pi); cr.set_source_rgba(*RED, 1); cr.set_line_width(2*s); cr.stroke()
    glow_stroke(cr, P([(6.5, 6.5), (17.5, 17.5)], s), s, RED, 2.0, close=False, glow=False)
    return (12, 12)


def rings(cr, s, f, n, cx=12, cy=12, r1=8.5, r2=5.0, lw=2.2):
    a = 2*math.pi*f/n
    cr.set_line_cap(cairo.LINE_CAP_BUTT)
    cr.new_path(); cr.arc(cx*s, cy*s, r1*s, 0, 2*math.pi); cr.set_source_rgba(*NAVY, 0.9); cr.set_line_width((lw+1.8)*s); cr.stroke()
    for k in range(3):  # outer segmented ring, clockwise
        st = a + k*2*math.pi/3
        cr.new_path(); cr.arc(cx*s, cy*s, r1*s, st, st + 1.4); cr.set_source_rgba(*CY, 1); cr.set_line_width(lw*s); cr.stroke()
    for k in range(2):  # inner red ring, counter-clockwise
        st = -2*a + k*math.pi
        cr.new_path(); cr.arc(cx*s, cy*s, r2*s, st, st + 1.6); cr.set_source_rgba(*RED, 1); cr.set_line_width(1.6*s); cr.stroke()
    cr.rectangle((cx-1)*s, (cy-1)*s, 2*s, 2*s); cr.set_source_rgba(*CY, 1); cr.fill()


def wait(cr, s, f, n):
    rings(cr, s, f, n)
    return (12, 12)


def progress(cr, s, f, n):
    arrow(cr, s)
    rings(cr, s, f, n, cx=17.8, cy=18.2, r1=4.6, r2=2.4, lw=1.6)
    return (2, 2)


def render(fn, size, *args):
    s = size / 24
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
    cr = cairo.Context(surf)
    hx, hy = fn(cr, s, *args)
    surf.flush()
    return surf, int(round(hx*s)), int(round(hy*s))


def write_xcursor(name, fn, frames=1, delay=60):
    imgs = []
    for size in SIZES:
        for f in range(frames):
            imgs.append((size,) + render(fn, size, *((f, frames) if frames > 1 else ())))
    header = struct.pack("<4sIII", b"Xcur", 16, 0x10000, len(imgs))
    pos, toc, chunks = 16 + len(imgs)*12, b"", b""
    for size, surf, hx, hy in imgs:
        data, stride = bytes(surf.get_data()), surf.get_stride()
        if stride != size*4:
            data = b"".join(data[r*stride:r*stride + size*4] for r in range(size))
        chunk = struct.pack("<IIIIIIIII", 36, 0xfffd0002, size, 1, size, size, hx, hy, delay) + data
        toc += struct.pack("<III", 0xfffd0002, size, pos); chunks += chunk; pos += len(chunk)
    (CUR / name).write_bytes(header + toc + chunks)


BASE = {
    "left_ptr": (arrow, 1), "hand2": (pointer, 1), "xterm": (ibeam, 1), "crosshair": (reticle, 1),
    "sb_h_double_arrow": (lambda cr, s: dbl(cr, s, 0), 1),
    "sb_v_double_arrow": (lambda cr, s: dbl(cr, s, math.pi/2), 1),
    "fd_double_arrow": (lambda cr, s: dbl(cr, s, math.pi/4), 1),
    "bd_double_arrow": (lambda cr, s: dbl(cr, s, -math.pi/4), 1),
    "fleur": (move, 1), "crossed_circle": (forbidden, 1),
    "watch": (wait, 18), "left_ptr_watch": (progress, 18),
}
ALIASES = {
    "left_ptr": ["default", "arrow", "top_left_arrow", "left_arrow", "context-menu"],
    "hand2": ["pointer", "hand1", "hand", "pointing_hand", "e29285e634086352946a0e7090d73106",
              "9d800788f1b08800ae810202380a0822"],
    "xterm": ["text", "ibeam", "vertical-text"],
    "crosshair": ["cross", "tcross", "cell", "color-picker", "target"],
    "sb_h_double_arrow": ["ew-resize", "e-resize", "w-resize", "col-resize", "h_double_arrow", "size_hor",
                          "right_side", "left_side", "split_h", "14fef782d02440884392942c11205230"],
    "sb_v_double_arrow": ["ns-resize", "n-resize", "s-resize", "row-resize", "v_double_arrow", "size_ver",
                          "top_side", "bottom_side", "split_v", "2870a09082c103050810ffdffffe0204"],
    "fd_double_arrow": ["nwse-resize", "nw-resize", "se-resize", "size_fdiag", "top_left_corner",
                        "bottom_right_corner", "c7088f0f3e6c8088236ef8e1e3e70000"],
    "bd_double_arrow": ["nesw-resize", "ne-resize", "sw-resize", "size_bdiag", "top_right_corner",
                        "bottom_left_corner", "fcf1c3c7cd4491d801f1e1c78f100000"],
    "fleur": ["move", "all-scroll", "size_all", "grabbing", "dnd-move", "closedhand",
              "4498f0e0c1937ffe01fd06f973665830", "9081237383d90e509aa00f00170e968f"],
    "crossed_circle": ["not-allowed", "no-drop", "forbidden", "circle", "dnd-no-drop",
                       "03b6e0fcb3499374a867c041f52298f0"],
    "watch": ["wait"],
    "left_ptr_watch": ["progress", "half-busy", "00000000000000020006000e7e9ffc3f",
                       "3ecb610c1bf2410f44200f48c40d3599", "08e8e1c95fe2fc01f976f1e063a24ccd"],
}
for name, (fn, frames) in BASE.items():
    write_xcursor(name, fn, frames)
    for a in ALIASES.get(name, []):
        os.symlink(name, CUR / a)
(OUT / "index.theme").write_text("[Icon Theme]\nName=CyberNeon-Cursors\nComment=Netrunner HUD cursors\nInherits=DMZ-White\n")

prev = os.environ.get("PREVIEW")
if prev:
    sheet = cairo.ImageSurface(cairo.FORMAT_ARGB32, 72*len(BASE) + 16, 176)
    cr = cairo.Context(sheet)
    cr.set_source_rgb(0.94, 0.94, 0.94); cr.rectangle(0, 0, sheet.get_width(), 88); cr.fill()
    cr.set_source_rgb(0.03, 0.05, 0.10); cr.rectangle(0, 88, sheet.get_width(), 88); cr.fill()
    for i, (name, (fn, frames)) in enumerate(BASE.items()):
        surf, _, _ = render(fn, 64, *((4, frames) if frames > 1 else ()))
        for y in (12, 100):
            cr.set_source_surface(surf, 8 + i*72, y); cr.paint()
    sheet.write_to_png(prev)
print("cursors:", len(list(CUR.iterdir())))
