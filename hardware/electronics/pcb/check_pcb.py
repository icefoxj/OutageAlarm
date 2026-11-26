"""Checks the PCB against the kit, beyond KiCad's ERC and DRC. Runs with KiCad 8's Python:
    python check_pcb.py [board.kicad_pcb]

1. Connections: every pad's net against the wiring table of docs/electronics.md, typed here a second time on
   purpose (board.py is the first), with the off-board parts named by their connector pins.
2. The enclosure: no solder joint over the base's rim (3 mm along the edge), over the pads around the screw
   posts or over the rib under the 18650 holder, where the board lies on the base; no copper under the posts.
3. The model: the outline, the screw holes and the K1, D1 and R1 positions as in enclosure.scad.
Exits 1 on any difference.
"""
import math
import os
import re
import sys

import pcbnew

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import board as BD  # noqa: E402

OX, OY = 100.0, 150.0
pcb = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "kicad", BD.NAME + ".kicad_pcb")
errors = []


def xy(p):
    return (pcbnew.ToMM(p.x) - OX, OY - pcbnew.ToMM(p.y))


# --- 1. connections (docs/electronics.md, "Wiring table") ---------------------------------------------------
WIRING = {
    "+5V": {"J1.1", "R1.2", "J3.2"},              # U1 IN+ · R1 · SW2 (TEST)
    "COIL": {"J3.1", "K1.2", "D1.1"},             # SW2 (TEST) · K1 coil · D1 cathode
    "0V": {"J1.2", "K1.5", "D1.2", "J4.2"},       # U1 IN- · K1 coil · D1 anode · LED1 cathode
    "LED": {"R1.1", "J4.1"},                      # R1 · LED1 anode
    "BAT+": {"J1.4", "J2.1"},                     # U1 OUT+ · SW1 (ARM)
    "ARM": {"J2.2", "K1.1"},                      # SW1 · K1 COM
    "BZ+": {"K1.4", "J5.1"},                      # K1 NC · BZ1 +
    "BAT-": {"J1.3", "J5.2"},                     # U1 OUT- · BZ1 -
}
NOT_CONNECTED = {"K1.3"}                          # K1 NO

b = pcbnew.LoadBoard(pcb)
found = {}
pads = []
for fp in b.GetFootprints():
    for p in fp.Pads():
        name = f"{fp.GetReference()}.{p.GetNumber()}"
        n = p.GetNetname()
        if n and not n.startswith("unconnected-"):
            found.setdefault(n, set()).add(name)
        elif not fp.GetReference().startswith("H") and name not in NOT_CONNECTED:
            errors.append(f"{name} has no net")
        if p.GetAttribute() == pcbnew.PAD_ATTRIB_PTH:
            pads.append((name, xy(p.GetPosition()), pcbnew.ToMM(max(p.GetSize().x, p.GetSize().y)) / 2))
if found != WIRING:
    for n in sorted(set(found) | set(WIRING)):
        if found.get(n) != WIRING.get(n):
            errors.append(f"net {n}: board {sorted(found.get(n, []))}, wiring table {sorted(WIRING.get(n, []))}")

# --- 2. the enclosure's keep-outs ----------------------------------------------------------------------------


def inside_by(pt, poly, d):
    """True if pt is inside the convex CCW polygon by at least d."""
    for i in range(len(poly)):
        (x0, y0), (x1, y1) = poly[i], poly[(i + 1) % len(poly)]
        ex, ey = x1 - x0, y1 - y0
        if ((pt[0] - x0) * -ey + (pt[1] - y0) * ex) / math.hypot(ex, ey) < d:
            return False
    return True


rx, ry, rw, rh = BD.RIB
for name, (x, y), r in pads:
    if not inside_by((x, y), BD.OUTLINE, BD.RIM + r):
        errors.append(f"{name}: solder joint over the base's rim")
    for hx, hy in BD.SCREW_HOLES:
        if math.hypot(x - hx, y - hy) < BD.POST_KEEPOUT_R + r:
            errors.append(f"{name}: solder joint on a screw post's pad")
    if rx - r < x < rx + rw + r and ry - r < y < ry + rh + r:
        errors.append(f"{name}: solder joint over the holder's rib")
for t in b.GetTracks():
    for p in (t.GetStart(), t.GetEnd()):
        x, y = xy(p)
        for hx, hy in BD.SCREW_HOLES:
            if math.hypot(x - hx, y - hy) < BD.POST_KEEPOUT_R + BD.TRACK / 2:
                errors.append(f"track of {t.GetNetname()} under a screw post")

# --- 3. the enclosure model ------------------------------------------------------------------------------------
scad = open(os.path.join(HERE, "..", "..", "mechanical", "enclosure.scad"), encoding="utf-8").read()


def scad_value(name):
    m = re.search(r"^%s\s*=\s*([^;]+);" % name, scad, re.M)
    return eval(m.group(1))   # numbers and [a, b] lists only


if (scad_value("pcb_cols"), scad_value("pcb_rows")) != (BD.COLS, BD.ROWS):
    errors.append("the board's size differs from enclosure.scad (pcb_cols, pcb_rows)")
if abs(scad_value("pcb_t") - BD.THICKNESS) > 1e-6:
    errors.append("the board's thickness differs from enclosure.scad (pcb_t)")
k1, d1, r1 = scad_value("k1_hole"), scad_value("d1_hole"), scad_value("r1_hole")
cx, cy = BD.hole(k1[0] + 2.5, k1[1] + 2.5)
if math.hypot(BD.K1_COM[0] - 8.05 - cx, BD.K1_COM[1] - cy) > 0.01:
    errors.append("K1 is not where enclosure.scad puts it (k1_hole)")
for ref, (i, j) in (("D1", d1), ("R1", r1)):
    if abs(BD.P[ref + ".2" if ref == "D1" else ref + ".1"][0] - BD.hole(i, j)[0]) > 0.01:
        errors.append(f"{ref} is not on the column enclosure.scad gives it")
if abs(BD.P["D1.2"][1] - BD.hole(*d1)[1]) > 0.01 or abs(BD.P["R1.1"][1] - BD.hole(*r1)[1]) > 0.01:
    errors.append("D1's anode or R1's front lead is not on the row enclosure.scad gives it")
holes = sorted((round(xy(fp.GetPosition())[0], 2), round(xy(fp.GetPosition())[1], 2))
               for fp in b.GetFootprints() if fp.GetReference().startswith("H"))
if holes != sorted((round(x, 2), round(y, 2)) for x, y in BD.SCREW_HOLES):
    errors.append(f"screw holes at {holes}")
bb = b.GetBoardEdgesBoundingBox()
if abs(pcbnew.ToMM(bb.GetWidth()) - BD.W) > 0.15 or abs(pcbnew.ToMM(bb.GetHeight()) - BD.H) > 0.15:
    errors.append("the outline is not %.2f x %.2f mm" % (BD.W, BD.H))

for e in errors:
    print("ERROR:", e)
print("check_pcb: %d nets, %d through-hole pads, %d tracks, %d errors"
      % (len(found), len(pads), len(list(b.GetTracks())), len(errors)))
sys.exit(1 if errors else 0)
