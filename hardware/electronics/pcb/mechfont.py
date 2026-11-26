"""The house mech font as polygons, for the PCB's silkscreen.

The same glyphs as enclosure.scad (mech_glyphs) and the other kits' cad/mech.py: centre lines on a grid 6 units
tall and up to 4 wide, stroked with mitred joins and square ends, each glyph clipped to its cell so stroke ends
stay hidden. Plain Python (no KiCad): text() returns polygons in mm, which make_pcb.py turns into silkscreen.
"""

GLYPHS = {
    " ": (3, []),
    "-": (3, [[(0, 3), (3, 3)]]),
    "/": (3, [[(0, 0), (3, 6)]]),
    ".": (0, [[(0, 0), (0, 0.6)]]),
    ":": (0, [[(0, 0.6), (0, 1.4)], [(0, 4.0), (0, 4.8)]]),
    ">": (3, [[(0, 6), (3, 3), (0, 0)]]),
    "<": (3, [[(3, 6), (0, 3), (3, 0)]]),
    "+": (4, [[(0, 3), (4, 3)], [(2, 1), (2, 5)]]),
    "0": (4, [[(1, 0), (4, 0), (4, 5), (3, 6), (0, 6), (0, 1), (1, 0)]]),
    "1": (2, [[(0, 4.5), (2, 6), (2, 0)]]),
    "2": (4, [[(0, 6), (3, 6), (4, 5), (4, 4), (0, 0)], [(0, 0), (4, 0)]]),
    "3": (4, [[(0, 6), (3, 6), (4, 5), (4, 1), (3, 0), (0, 0)], [(1.5, 3), (4, 3)]]),
    "4": (4, [[(3, 0), (3, 6), (0, 2)], [(0, 2), (4, 2)]]),
    "5": (4, [[(4, 6), (0, 6), (0, 3), (3, 3), (4, 2), (4, 1), (3, 0), (0, 0)]]),
    "6": (4, [[(4, 6), (1, 6), (0, 5), (0, 0), (4, 0), (4, 3)], [(4, 3), (0, 3)]]),
    "7": (4, [[(0, 6), (4, 6), (4, 5), (1.5, 0)]]),
    "8": (4, [[(1, 0), (3, 0), (4, 1), (4, 5), (3, 6), (1, 6), (0, 5), (0, 1), (1, 0)], [(0, 3), (4, 3)]]),
    "9": (4, [[(0, 0), (3, 0), (4, 1), (4, 6), (0, 6), (0, 3)], [(0, 3), (4, 3)]]),
    "A": (4, [[(0, 0), (0, 5), (1, 6), (3, 6), (4, 5), (4, 0)], [(0, 2.5), (4, 2.5)]]),
    "B": (4, [[(0, 0), (0, 6)], [(0, 6), (3, 6), (4, 5), (4, 4), (3, 3), (0, 3)], [(3, 3), (4, 2), (4, 1), (3, 0), (0, 0)]]),
    "C": (4, [[(4, 6), (1, 6), (0, 5), (0, 1), (1, 0), (4, 0)]]),
    "D": (4, [[(0, 0), (3, 0), (4, 1), (4, 5), (3, 6), (0, 6), (0, 0)]]),
    "E": (4, [[(4, 6), (0, 6), (0, 0), (4, 0)], [(0, 3), (3, 3)]]),
    "F": (4, [[(4, 6), (0, 6), (0, 0)], [(0, 3), (3, 3)]]),
    "G": (4, [[(4, 5), (3, 6), (1, 6), (0, 5), (0, 1), (1, 0), (4, 0), (4, 3), (2, 3)]]),
    "H": (4, [[(0, 0), (0, 6)], [(4, 0), (4, 6)], [(0, 3), (4, 3)]]),
    "I": (0, [[(0, 0), (0, 6)]]),
    "J": (4, [[(4, 6), (4, 1), (3, 0), (1, 0), (0, 1)]]),
    "K": (4, [[(0, 0), (0, 6)], [(4, 6), (1, 3), (4, 0)], [(0, 3), (1, 3)]]),
    "L": (4, [[(0, 6), (0, 0), (4, 0)]]),
    "M": (4, [[(0, 0), (0, 6), (2, 3.5), (4, 6), (4, 0)]]),
    "N": (4, [[(0, 0), (0, 6), (4, 0), (4, 6)]]),
    "O": (4, [[(1, 0), (3, 0), (4, 1), (4, 5), (3, 6), (1, 6), (0, 5), (0, 1), (1, 0)]]),
    "P": (4, [[(0, 0), (0, 6)], [(0, 6), (3, 6), (4, 5), (4, 4), (3, 3), (0, 3)]]),
    "Q": (4, [[(1, 0), (3, 0), (4, 1), (4, 5), (3, 6), (1, 6), (0, 5), (0, 1), (1, 0)], [(2.5, 1.5), (4, 0)]]),
    "R": (4, [[(0, 0), (0, 6)], [(0, 6), (3, 6), (4, 5), (4, 4), (3, 3), (0, 3)], [(3, 3), (4, 2), (4, 0)]]),
    "S": (4, [[(4, 6), (1, 6), (0, 5), (0, 4), (1, 3), (3, 3), (4, 2), (4, 1), (3, 0), (0, 0)]]),
    "T": (4, [[(0, 6), (4, 6)], [(2, 6), (2, 0)]]),
    "U": (4, [[(0, 6), (0, 1), (1, 0), (3, 0), (4, 1), (4, 6)]]),
    "V": (4, [[(0, 6), (0, 2), (2, 0), (4, 2), (4, 6)]]),
    "W": (4, [[(0, 6), (0, 0), (2, 2), (4, 0), (4, 6)]]),
    "X": (4, [[(0, 0), (4, 6)], [(0, 6), (4, 0)]]),
    "Y": (4, [[(0, 6), (2, 3), (4, 6)], [(2, 3), (2, 0)]]),
    "Z": (4, [[(0, 6), (4, 6), (0, 0), (4, 0)]]),
}


def _glyph(c):
    if c not in GLYPHS:
        raise KeyError(f'the mech font has no "{c}" glyph')
    return GLYPHS[c]


def advances(s, cap, w):
    return [_glyph(c)[0] * (cap - w) / 6 + 2 * w for c in s]


def width(s, cap, w):
    return sum(advances(s, cap, w)) - w


def _dir(a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = (dx * dx + dy * dy) ** 0.5
    return (dx / n, dy / n)


def _sides(p, h, closed):
    """Mitred outlines at distance h on both sides of a polyline: [left, right]."""
    n = len(p)
    m = n if closed else n - 1
    d = [_dir(p[i], p[(i + 1) % n]) for i in range(m)]
    q = [(-t[1], t[0]) for t in d]
    out = []
    for s in (1, -1):
        side = []
        for j in range(n):
            if not closed and j == 0:
                side.append((p[0][0] + h * (s * q[0][0] - d[0][0]), p[0][1] + h * (s * q[0][1] - d[0][1])))
            elif not closed and j == n - 1:
                side.append((p[j][0] + h * (s * q[m - 1][0] + d[m - 1][0]), p[j][1] + h * (s * q[m - 1][1] + d[m - 1][1])))
            else:
                a, b = q[(j + m - 1) % m], q[j % m]
                k = s * h / (1 + a[0] * b[0] + a[1] * b[1])
                side.append((p[j][0] + k * (a[0] + b[0]), p[j][1] + k * (a[1] + b[1])))
        out.append(side)
    return out


def stroke(pts, w):
    """Polyline of width w (mitred joins, square ends) as quads; a polyline that ends where it starts is closed."""
    closed = len(pts) > 2 and pts[0] == pts[-1]
    p = pts[:-1] if closed else pts
    n = len(p)
    left, right = _sides(p, w / 2, closed)
    return [[left[i], left[(i + 1) % n], right[(i + 1) % n], right[i]] for i in range(n if closed else n - 1)]


def _clip(poly, x0, y0, x1, y1):
    """Sutherland-Hodgman: a polygon clipped to a rectangle."""
    def cut(pts, inside, inter):
        out = []
        for i in range(len(pts)):
            a, b = pts[i - 1], pts[i]
            if inside(b):
                if not inside(a):
                    out.append(inter(a, b))
                out.append(b)
            elif inside(a):
                out.append(inter(a, b))
        return out

    def ix(xc):
        return lambda a, b: (xc, a[1] + (b[1] - a[1]) * (xc - a[0]) / (b[0] - a[0]))

    def iy(yc):
        return lambda a, b: (a[0] + (b[0] - a[0]) * (yc - a[1]) / (b[1] - a[1]), yc)

    pts = poly
    for inside, inter in ((lambda p: p[0] >= x0, ix(x0)), (lambda p: p[0] <= x1, ix(x1)),
                          (lambda p: p[1] >= y0, iy(y0)), (lambda p: p[1] <= y1, iy(y1))):
        pts = cut(pts, inside, inter)
        if not pts:
            return []
    return pts


def text(s, x, y, cap, w, anchor="left", mirror=False):
    """Polygons of a line of text; (x, y) is the anchor at mid-height of the caps. mirror: for the bottom side."""
    u = (cap - w) / 6
    tw = width(s, cap, w)
    x_left = x - (tw if anchor == "right" else tw / 2 if anchor == "center" else 0)
    y_base = y - cap / 2
    polys = []
    cx = x_left
    for c, adv in zip(s, advances(s, cap, w)):
        gw, lines = _glyph(c)
        for line in lines:
            for quad in stroke([(cx + px * u + w / 2, y_base + py * u + w / 2) for px, py in line], w):
                q = _clip(quad, cx, y_base, cx + gw * u + w, y_base + cap)
                if len(q) >= 3:
                    polys.append(q)
        cx += adv
    if mirror:
        mid = x_left + tw / 2
        polys = [[(2 * mid - px, py) for px, py in reversed(p)] for p in polys]
    return polys


def slant(u0, u1, v0, v1):
    """Band from u0 to u1 along its bottom edge (at v0), its ends leaning 45 deg to the right."""
    k = v1 - v0
    return [(u0, v0), (u1, v0), (u1 + k, v1), (u0 + k, v1)]
