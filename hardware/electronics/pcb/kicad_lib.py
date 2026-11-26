"""Reads KiCad 8 symbol libraries (.kicad_sym): a symbol's text, its pins and its extent.
Used by make_schematic.py. Plain Python. Adapted from DiceTester's placa/scripts/kicad_lib.py."""
import os
import re

KICAD_DIRS = [os.environ.get("KICAD_BIN") and os.path.join(os.environ["KICAD_BIN"], "..", "share", "kicad"),
              r"D:\Program Files\KiCad\8.0\share\kicad", r"C:\Program Files\KiCad\8.0\share\kicad", "/usr/share/kicad"]


def share_dir(sub):
    for d in KICAD_DIRS:
        if d and os.path.isdir(os.path.join(d, sub)):
            return os.path.join(d, sub)
    raise FileNotFoundError(f"KiCad 8 '{sub}' not found; set KICAD_BIN to KiCad's bin folder")


def sexpr_end(txt, start):
    """End (exclusive) of the s-expression that starts at txt[start] == '('."""
    n, i, quoted = 0, start, False
    while i < len(txt):
        c = txt[i]
        if quoted:
            if c == "\\":
                i += 1
            elif c == '"':
                quoted = False
        elif c == '"':
            quoted = True
        elif c == "(":
            n += 1
        elif c == ")":
            n -= 1
            if n == 0:
                return i + 1
        i += 1
    raise ValueError("unterminated s-expression")


_cache = {}


def symbol(lib_id):
    """Text of a symbol ('Lib:Name'), with 'extends' resolved."""
    lib, name = lib_id.split(":")
    if lib not in _cache:
        _cache[lib] = open(os.path.join(share_dir("symbols"), lib + ".kicad_sym"), encoding="utf-8").read()
    txt = _cache[lib]
    m = re.search(r'\n\t\(symbol "%s"\n' % re.escape(name), txt)
    if not m:
        raise KeyError(lib_id)
    start = txt.index("(", m.start())
    s = txt[start:sexpr_end(txt, start)]
    ext = re.search(r'\(extends "([^"]+)"\)', s)
    if ext:                                   # derived symbol: the parent's drawing and pins, the child's properties
        parent = symbol(lib + ":" + ext.group(1))
        props = re.findall(r"\n\t\t\(property .*?\n\t\t\)", s, re.S)
        body = re.sub(r"\n\t\t\(property .*?\n\t\t\)", "", parent, flags=re.S)
        body = body.replace('(symbol "%s"' % ext.group(1), '(symbol "%s"' % name, 1)
        body = re.sub(r'\(symbol "%s_(\d+)_(\d+)"' % re.escape(ext.group(1)), r'(symbol "%s_\1_\2"' % name, body)
        i = body.index("\n", body.index("(symbol"))
        s = body[:i] + "".join(props) + body[i:]
    return s


def pins(lib_id):
    """Pins: (number, name, type, unit, x, y, angle, length), mm, y up (the library's convention)."""
    s = symbol(lib_id)
    out = []
    for m in re.finditer(r'\(symbol "[^"]+_(\d+)_(\d+)"', s):
        unit = int(m.group(1))
        start = s.index("(", m.start())
        sub = s[start:sexpr_end(s, start)]
        for p in re.finditer(r'\(pin (\w+) \w+\s*\(at ([-\d.]+) ([-\d.]+) ([-\d.]+)\)\s*\(length ([-\d.]+)\).*?'
                             r'\(name "([^"]*)".*?\(number "([^"]*)"', sub, re.S):
            out.append((p.group(7), p.group(6), p.group(1), unit, float(p.group(2)), float(p.group(3)),
                        float(p.group(4)), float(p.group(5))))
    return out


def extent(lib_id):
    """(x0, y0, x1, y1) of the symbol's drawing and pins, library coordinates (y up)."""
    s = symbol(lib_id)
    xs, ys = [0.0], [0.0]
    for m in re.finditer(r"\((?:xy|start|end|center) (-?[\d.]+) (-?[\d.]+)\)", s):
        xs.append(float(m.group(1)))
        ys.append(float(m.group(2)))
    for p in pins(lib_id):
        xs.append(p[4])
        ys.append(p[5])
    return min(xs), min(ys), max(xs), max(ys)
