#!/usr/bin/env python3
"""Draw the OutageAlarm v1 perfboard layout: perfboard.svg, next to this file.

The layout is the data below, in holes of a 2.54 mm perfboard: (i, j), with i
counted to the right and j to the back from the board's front-left corner. The
board is cut along lines of holes, so its edges run through the outer holes.

The drawing is 1:1 on A4 landscape: printed at 100 %, it is a template for
cutting the board and drilling the screw and relay holes.

Keep these in sync with hardware/mechanical/enclosure.scad: the board size
(pcb_cols, pcb_rows), k1_hole, d1_hole, r1_hole, and the holder and TP4056
positions (holder_x0, holder_y0, chg_x, chg_y0).

Usage: python3 perfboard.py [output.svg]
"""

import sys
import textwrap
from pathlib import Path

PITCH = 2.54
COLS, ROWS = 45, 26          # board size in hole spacings: 114.3 x 66.04 mm
CUT = 2                      # corners cut at 45 degrees through the 2nd hole
ORIGIN = ((118 - COLS * PITCH) / 2, (70 - ROWS * PITCH) / 2)   # board corner in the enclosure (mm)
SCREWS = [(2, 2), (COLS - 2, 2), (2, ROWS - 2), (COLS - 2, ROWS - 2)]

K1 = (22, 3)                 # hole of the relay's front-left pin (NC); its pins span 5 x 5 spacings
D1 = (29, 3)                 # anode; the cathode (band) is 5 holes behind it
R1 = (31, 2)                 # front lead; the other one is 8 holes behind it

# Outlines of the parts stuck on the board, in enclosure mm: x, y, width, depth
HOLDER = (10.5, 47.5, 78, 22)
U1 = (98.3 - 17.4 / 2, 69.5 - 29, 17.4, 29)


def k1_pins():
    """K1's pins, off the grid: the SRD footprint centered on its 5 x 5 spacings."""
    ci, cj = K1[0] + 2.5, K1[1] + 2.5
    dx, dy = 6.1 / PITCH, 6.0 / PITCH
    return {"NC": (ci - dx, cj - dy), "NO": (ci - dx, cj + dy),
            "coil0": (ci + dx, cj - dy), "coil1": (ci + dx, cj + dy),
            "COM": (ci + 8.05 / PITCH, cj)}


def k1_body():
    ci, cj = K1[0] + 2.5, K1[1] + 2.5
    return (ci - 10.25 / PITCH, cj - 7.7 / PITCH, ci + 9.35 / PITCH, cj + 7.7 / PITCH)


PINS = k1_pins()

# Pads where the wires land: hole, label, side of the label
PADS = [
    ((33, 2), "LED1 + (long leg)", "r"),
    ((33, 3), "LED1 −", "r"),
    ((33, 4), "U1 IN−", "r"),
    ((33, 5), "ARM (SW1)", "r"),
    ((33, 6), "ARM (SW1)", "r"),
    ((33, 7), "U1 OUT+", "r"),
    ((33, 8), "TEST (SW2)", "r"),
    ((33, 9), "TEST (SW2)", "r"),
    ((33, 10), "U1 IN+", "r"),
    ((20, 3), "BZ1 + (red)", "l"),
    ((20, 4), "BZ1 − (black)", "l"),
    ((20, 5), "U1 OUT−", "l"),
]

# Links on the solder side (bare tinned wire): net, colour class, path in holes.
# "u" = the 5 V side (orange), "b" = the battery side (blue), as in schematic.svg.
LINKS = [
    ("LED", "u", [(R1[0], R1[1]), (33, 2)]),
    ("0V", "u", [PINS["coil0"], (K1[0] + 6, K1[1]), (33, 3), (33, 4)]),
    ("COIL", "u", [PINS["coil1"], (K1[0] + 6, K1[1] + 5), (33, 8)]),
    ("+5V", "u", [(33, 9), (33, 10), (R1[0], R1[1] + 8)]),
    ("ARM", "b", [PINS["COM"], (K1[0] + 6, K1[1] + 2), (33, 5)]),
    ("BAT+", "b", [(33, 6), (33, 7)]),
    ("BZ+", "b", [(20, 3), (K1[0] - 1, K1[1]), PINS["NC"]]),
    ("BAT−", "b", [(20, 4), (20, 5)]),
]

# Solder joints of the parts on the board
JOINTS = list(PINS.values()) + [D1, (D1[0], D1[1] + 5), R1, (R1[0], R1[1] + 8)]

# Page layout (mm)
PAGE_W, PAGE_H = 297, 210
VIEW_Y = 37                                  # back edge of both boards
VIEW_X = (16, PAGE_W - 16 - COLS * PITCH)    # component side, solder side

INK, MUTED = "#1f2328", "#57606a"
U_COL, B_COL = "#bc4c00", "#0969da"
BOARD, EDGE, HOLE, COPPER = "#f3e6c8", "#8c6a3a", "#8f7a55", "#d9a15f"


class View:
    """Maps holes to page mm; the solder side is mirrored left to right."""

    def __init__(self, x0, mirror):
        self.x0, self.mirror = x0, mirror

    def p(self, i, j):
        u = COLS - i if self.mirror else i
        return (self.x0 + u * PITCH, VIEW_Y + (ROWS - j) * PITCH)

    def mm(self, x, y):
        """Enclosure coordinates (mm) to page mm."""
        return self.p((x - ORIGIN[0]) / PITCH, (y - ORIGIN[1]) / PITCH)

    def anchor(self, side):
        right = (side == "r") != self.mirror
        return ("start", 0.75) if right else ("end", -0.75)


def f(v):
    return f"{v:.2f}".rstrip("0").rstrip(".")


def pts(view, holes):
    return " ".join(f"{f(x)},{f(y)}" for x, y in (view.p(*h) for h in holes))


def text(x, y, s, size=2.4, anchor="start", fill=INK, weight=None, extra="", halo=False):
    w = f' font-weight="{weight}"' if weight else ""
    w += ' class="halo"' if halo else ""
    s = s.replace("&", "&amp;").replace("<", "&lt;")
    return (f'<text x="{f(x)}" y="{f(y)}" font-size="{size}" text-anchor="{anchor}" '
            f'fill="{fill}"{w}{extra}>{s}</text>')


def board_outline(view):
    c = CUT
    corners = [(c, 0), (COLS - c, 0), (COLS, c), (COLS, ROWS - c),
               (COLS - c, ROWS), (c, ROWS), (0, ROWS - c), (0, c)]
    return "M" + " L".join(f"{f(x)},{f(y)}" for x, y in (view.p(*h) for h in corners)) + " Z"


def keep_clear(view):
    """Dashed line around the area that may hold parts: inside the outer row,
    and outside the 3 x 3 holes around each screw."""
    a, b = 1.5, 3.5
    poly = [(b, a), (COLS - b, a), (COLS - b, b), (COLS - a, b), (COLS - a, ROWS - b),
            (COLS - b, ROWS - b), (COLS - b, ROWS - a), (b, ROWS - a), (b, ROWS - b),
            (a, ROWS - b), (a, b), (b, b)]
    return f'<polygon points="{pts(view, poly)}" class="clear"/>'


def outline_box(view, box, label, note):
    x, y, w, d = box
    (x0, y1), (x1, y0) = view.mm(x, y), view.mm(x + w, y + d)
    xa, xb = min(x0, x1), max(x0, x1)
    out = [f'<rect x="{f(xa)}" y="{f(y0)}" width="{f(xb - xa)}" height="{f(y1 - y0)}" class="part"/>']
    cx, cy = (xa + xb) / 2, (y0 + y1) / 2
    out.append(text(cx, cy - 0.6, label, 2.6, "middle", weight=700, halo=True))
    for k, line in enumerate(note):
        out.append(text(cx, cy + 2.6 + 2.8 * k, line, 2.1, "middle", MUTED, halo=True))
    return out


def draw_view(view, solder):
    out = [f'<!-- {"Solder side, mirrored" if solder else "Component side"} -->',
           f'<path d="{board_outline(view)}" fill="{BOARD}" stroke="{EDGE}" stroke-width="0.35"/>',
           f'<path d="{board_outline(view)}" fill="url(#{"pads" if solder else "holes"}{int(solder)})"/>',
           keep_clear(view)]

    # Hole numbers along the front edge and the left (or right) edge
    for i in range(0, COLS + 1, 5):
        x, y = view.p(i, 0)
        out.append(text(x, y + 3.6, str(i), 1.9, "middle", MUTED))
    for j in range(0, ROWS + 1, 5):
        x, y = view.p(COLS if view.mirror else 0, j)
        out.append(text(x - 1.6, y + 0.65, str(j), 1.9, "end", MUTED))

    # Parts stuck on the board
    out += outline_box(view, HOLDER, "BT1 · 18650 holder",
                       ["thin double-sided tape", "its wires go straight to U1 B+ and B−"])
    out += outline_box(view, U1, "U1", ["TP4056", "USB-C at", "the back"])

    # K1, D1 and R1: drawn on the component side, ghosted on the solder side
    ghost = ' opacity="0.35"' if solder else ""
    bx0, by0, bx1, by1 = k1_body()
    (ax, ay), (cx, cy) = view.p(bx0, by1), view.p(bx1, by0)
    out.append(f'<g{ghost}><rect x="{f(min(ax, cx))}" y="{f(ay)}" width="{f(abs(cx - ax))}" '
               f'height="{f(cy - ay)}" rx="0.6" class="relay"/>')
    mx, my = view.p(K1[0] + 2.5, K1[1] + 2.5)
    out.append(text(mx, my - 0.4, "K1", 3.2, "middle", weight=700))
    out.append(text(mx, my + 2.6, "SRD-05VDC-SL-C", 1.9, "middle", MUTED) + "</g>")
    for name, (i, j) in PINS.items():
        x, y = view.p(i, j)
        if not solder:
            out.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="0.65" fill="#ffffff" stroke="{INK}" stroke-width="0.25"/>')
        label = "coil" if name.startswith("coil") else name
        if name == "COM":                           # beside it, toward the body's middle
            out.append(text(x + (1.1 if solder else -1.1), y + 0.7, label, 1.9, "start" if solder else "end", halo=True))
        elif j < K1[1] + 2.5:                       # front pins: label behind them
            out.append(text(x, y - 1.2, label, 1.9, "middle", halo=True))
        else:                                       # back pins: label in front of them
            out.append(text(x, y + 2.7, label, 1.9, "middle", halo=True))

    # D1 (band toward the cathode, at the back) and R1, lying flat
    for (i, j), n, length, width, fill, band in [(D1, 5, 5.2, 2.7, "#2b2b2b", True),
                                                  (R1, 8, 6.3, 2.4, "#d8b98a", False)]:
        (x, ya), (_, yb) = view.p(i, j), view.p(i, j + n)
        ym = (ya + yb) / 2
        g = [f'<g{ghost}><line x1="{f(x)}" y1="{f(ya)}" x2="{f(x)}" y2="{f(yb)}" stroke="#9aa0a6" stroke-width="0.45"/>',
             f'<rect x="{f(x - width / 2)}" y="{f(ym - length / 2)}" width="{f(width)}" height="{f(length)}" '
             f'rx="0.8" fill="{fill}" stroke="{INK}" stroke-width="0.25"/>']
        if band:
            g.append(f'<rect x="{f(x - width / 2)}" y="{f(ym - length / 2 + 0.5)}" width="{f(width)}" '
                     f'height="0.7" fill="#c9ced3"/>')
        name = "D1" if band else "R1"
        g.append(text(x, yb - 1.3, name, 2.4, "middle", weight=700, halo=True) + "</g>")
        out += g

    # Wire pads (rings) and their labels
    links = [f'<polyline points="{pts(view, path)}" class="{cls}{"" if solder else " thru"}"/>'
             for net, cls, path in LINKS]
    if not solder:
        out += links
    for h, label, side in PADS:
        x, y = view.p(*h)
        cls = next(c for n, c, path in LINKS if h in path)
        col = U_COL if cls == "u" else B_COL
        out.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="0.85" fill="#ffffff" stroke="{col}" stroke-width="0.4"/>')
        anchor, dx = view.anchor(side)
        out.append(text(x + dx * 1.6, y + 0.8, label, 2.2, anchor, halo=True))

    # Links: bold on the solder side, dashed (seen through the board) on the other
    if solder:
        out += links
    for h, label, side in PADS:
        x, y = view.p(*h)
        out.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="0.36" fill="{INK}"/>')

    # Solder joints of the parts
    if solder:
        for h in JOINTS:
            x, y = view.p(*h)
            out.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="0.7" fill="#9aa0a6" stroke="{INK}" stroke-width="0.2"/>')

    # Screw holes
    for h in SCREWS:
        x, y = view.p(*h)
        out.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="1.6" fill="#ffffff" stroke="{INK}" stroke-width="0.35"/>')
        out.append(f'<path d="M{f(x - 2.4)},{f(y)} H{f(x + 2.4)} M{f(x)},{f(y - 2.4)} V{f(y + 2.4)}" '
                   f'stroke="{INK}" stroke-width="0.2"/>')
    return out


def notes_block(x, y, title, items, width=58):
    out = [text(x, y, title, 3.0, weight=700)]
    y += 5
    for item in items:
        lines = textwrap.wrap(item, width)
        out.append(text(x, y, "•", 2.6))
        for line in lines:
            out.append(text(x + 2.6, y, line, 2.6))
            y += 3.5
        y += 1.2
    return out


def svg():
    comp, sold = View(VIEW_X[0], False), View(VIEW_X[1], True)
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{PAGE_W}mm" height="{PAGE_H}mm" '
           f'viewBox="0 0 {PAGE_W} {PAGE_H}" font-family="Segoe UI, Helvetica, Arial, sans-serif">',
           "  <!-- OutageAlarm v1 — perfboard layout. Drawn by perfboard.py: edit the layout there.",
           "       1:1 on A4 landscape, in mm. Orange (.u) = the 5 V side, blue (.b) = the battery side. -->",
           "<defs>"]
    for k, v in enumerate((comp, sold)):
        x, y = v.p(0, ROWS)
        tile = (f'<circle cx="{f(PITCH / 2)}" cy="{f(PITCH / 2)}" r="0.5" fill="{HOLE}"/>' if k == 0 else
                f'<circle cx="{f(PITCH / 2)}" cy="{f(PITCH / 2)}" r="0.85" fill="{COPPER}"/>'
                f'<circle cx="{f(PITCH / 2)}" cy="{f(PITCH / 2)}" r="0.45" fill="#ffffff"/>')
        out.append(f'<pattern id="{"pads" if k else "holes"}{k}" patternUnits="userSpaceOnUse" '
                   f'x="{f(x - PITCH / 2)}" y="{f(y - PITCH / 2)}" width="{PITCH}" height="{PITCH}">{tile}</pattern>')
    out += ["</defs>",
            "<style>",
            f"  .u {{ stroke: {U_COL}; stroke-width: 0.9; fill: none; stroke-linecap: round; stroke-linejoin: round; }}",
            f"  .b {{ stroke: {B_COL}; stroke-width: 0.9; fill: none; stroke-linecap: round; stroke-linejoin: round; }}",
            "  .thru { stroke-width: 0.45; stroke-dasharray: 1 0.8; opacity: 0.8; }",
            f"  .part {{ fill: #ffffff; fill-opacity: 0.8; stroke: {INK}; stroke-width: 0.3; stroke-dasharray: 1.6 1; }}",
            f"  .relay {{ fill: #d6e4fb; stroke: #1f4fb0; stroke-width: 0.35; }}",
            "  .halo { paint-order: stroke; stroke: #ffffff; stroke-width: 0.7; stroke-linejoin: round; }",
            f"  .clear {{ fill: none; stroke: {EDGE}; stroke-width: 0.25; stroke-dasharray: 1.2 0.8; }}",
            "</style>",
            f'<rect width="{PAGE_W}" height="{PAGE_H}" fill="#ffffff"/>',
            text(16, 15, "OutageAlarm v1 — Perfboard layout", 6, weight=700),
            text(16, 21.5, "All the electronics on one 2.54 mm perfboard, clamped in the enclosure by its "
                 "four screws. 1:1 on A4 landscape: print at 100 % and check the 50 mm bar.", 2.8, fill=MUTED),
            text(VIEW_X[0], 32, "COMPONENT SIDE", 3.0, weight=700),
            text(VIEW_X[0] + 33, 32, "back of the enclosure at the top", 2.4, fill=MUTED),
            text(VIEW_X[1], 32, "SOLDER SIDE", 3.0, weight=700),
            text(VIEW_X[1] + 23, 32, "mirrored, as you see it while soldering", 2.4, fill=MUTED)]
    out += draw_view(comp, False)
    out += draw_view(sold, True)

    # Board size on the component side
    x0, y0 = comp.p(0, 0)
    x1, _ = comp.p(COLS, 0)
    yd = y0 + 7.5
    out += [f'<path d="M{f(x0)},{f(yd - 1.5)} V{f(yd + 1.5)} M{f(x1)},{f(yd - 1.5)} V{f(yd + 1.5)} '
            f'M{f(x0)},{f(yd)} H{f(x1)}" stroke="{MUTED}" stroke-width="0.25"/>',
            f'<rect x="{f((x0 + x1) / 2 - 24)}" y="{f(yd - 2)}" width="48" height="4" fill="#ffffff"/>',
            text((x0 + x1) / 2, yd + 0.9, f"{COLS * PITCH:.1f} × {ROWS * PITCH:.1f} mm "
                 f"({COLS} × {ROWS} hole spacings)", 2.4, "middle", MUTED)]

    # Legend
    ly = 124
    lx = VIEW_X[0]
    out += [f'<line x1="{lx}" y1="{ly}" x2="{lx + 8}" y2="{ly}" class="u"/>',
            text(lx + 10, ly + 0.9, "5 V side: +5V, COIL, 0V, LED (live only while the outlet has power)", 2.4),
            f'<line x1="{lx}" y1="{ly + 5}" x2="{lx + 8}" y2="{ly + 5}" class="b"/>',
            text(lx + 10, ly + 5.9, "battery side: BAT+, ARM, BZ+, BAT−", 2.4),
            f'<circle cx="{lx + 4}" cy="{ly + 10}" r="0.85" fill="#ffffff" stroke="{INK}" stroke-width="0.4"/>',
            f'<circle cx="{lx + 4}" cy="{ly + 10}" r="0.36" fill="{INK}"/>',
            text(lx + 10, ly + 10.9, "pad for a wire", 2.4),
            f'<line x1="{lx + 92}" y1="{ly}" x2="{lx + 100}" y2="{ly}" class="clear"/>',
            text(lx + 102, ly + 0.9, "keep clear outside: the outer row rests on the base, and the posts", 2.4),
            text(lx + 102, ly + 4.2, "press on the 3 × 3 holes around each screw hole", 2.4),
            f'<circle cx="{lx + 96}" cy="{ly + 10}" r="1.6" fill="#ffffff" stroke="{INK}" stroke-width="0.35"/>',
            text(lx + 102, ly + 10.9, "drill 3.2 mm for the M3 screws (4 ×)", 2.4)]
    sx = PAGE_W - 16 - 50
    out += [f'<path d="M{sx},{ly + 8.5} V{ly + 10} H{sx + 50} V{ly + 8.5} M{sx + 25},{ly + 9} V{ly + 10}" '
            f'stroke="{INK}" stroke-width="0.3" fill="none"/>',
            text(sx + 25, ly + 13.6, "50 mm", 2.4, "middle")]

    # Steps
    ny = 147
    out += notes_block(VIEW_X[0], ny, "1 · Cut and drill", [
        f"Cut a {COLS * PITCH:.1f} × {ROWS * PITCH:.1f} mm piece ({COLS} × {ROWS} hole spacings) "
        "from a 10 × 15 cm perfboard, along lines of holes.",
        "Cut each corner at 45°, through the 2nd hole along each edge.",
        "Drill the 4 screw holes, 2 holes in from each corner, to 3.2 mm.",
        "K1's pins are off the 2.54 mm grid. Drill its 5 holes to 1.3 mm where this drawing "
        "shows them. COM falls between two holes.",
    ])
    out += notes_block(VIEW_X[0] + 92, ny, "2 · Solder", [
        "Fit K1, then D1 (band to the back) and R1 (1 kΩ), flat on the board.",
        "Make the links with bare tinned wire on the solder side, along the coloured lines. "
        "Bridge COM to the hole beside it with solder.",
        "Find K1's NC pin with a multimeter first. If yours is the back one, link BZ1 + to it.",
        "Trim the leads to 1.5 mm: the solder side sits over a 2 mm pocket in the base.",
    ])
    out += notes_block(VIEW_X[0] + 184, ny, "3 · Wires and mounting", [
        "Solder each wire to its pad: about 10 cm to U1, 15 cm to the parts on the shell.",
        "The holder's red and black wires go straight to U1 B+ and B−, not to the board.",
        "Stick the holder and U1 inside their outlines. Put U1 on 1 mm foam tape, "
        "with its USB-C at the back edge.",
        "Lay the board on the base. The 4 M3 × 16 screws go through the base and the board "
        "into the posts.",
    ], width=54)
    out.append("</svg>")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    dest = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).with_name("perfboard.svg")
    dest.write_text(svg(), encoding="utf-8", newline="\n")
    print(f"wrote {dest}")
