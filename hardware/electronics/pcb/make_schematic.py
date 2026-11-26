"""Writes the PCB's schematic (KiCad 8 .kicad_sch) from board.py.

Each pin gets a short wire and a global label with its net's name: a schematic "by labels", in blocks. The
symbols come from KiCad 8's libraries and are embedded in the file. The circuit drawing of the kit is still
hardware/electronics/schematic.svg; this file exists so that KiCad can check the board against it (ERC, DRC
with schematic parity) and so the project opens and edits in KiCad. Plain Python:
    python make_schematic.py [out.kicad_sch]
Adapted from DiceTester's placa/scripts/gerar_esquema.py.
"""
import math
import os
import sys
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import board as BD  # noqa: E402
import kicad_lib as K  # noqa: E402
from make_project import ROOT_UUID  # noqa: E402


def uid(key):
    return str(uuid.uuid5(uuid.NAMESPACE_URL, "OutageAlarm/pcb/" + key))


G = 1.27


def q(v):
    return round(round(v / G) * G, 2)


STUB = 2.54
BLOCKS = [
    ("DETECTION - TEST cuts the relay coil; D1 takes the coil's spike", ["J3", "K1", "D1"]),
    ("POWER LED - straight across the 5 V, before TEST", ["J4", "R1"]),
    ("U1 - TP4056 module (IN+, IN-, OUT-, OUT+), by wires", ["J1"]),
    ("ALARM - ARM switch, relay NC contact, buzzer", ["J2", "J5"]),
]
PARTS = {p["ref"]: p for p in BD.PARTS}
assert sorted(r for _, refs in BLOCKS for r in refs) == sorted(PARTS), "a part is missing from the blocks"


def effects(size=1.27, hide=False, justify=None, bold=False):
    s = "(effects (font (size %s %s)%s)" % (size, size, " (bold yes)" if bold else "")
    if justify:
        s += " (justify %s)" % justify
    if hide:
        s += " (hide yes)"
    return s + ")"


def pin_out(p):
    """Direction out of the symbol (screen, y down) from the pin's library angle."""
    a = math.radians(p[6] + 180.0)
    return (round(math.cos(a)), -round(math.sin(a)))


class Schematic:
    def __init__(self):
        self.items, self.libs = [], set()

    def symbol(self, lib_id, ref, value, x, y, fields, nets, nc=(), in_bom=True):
        self.libs.add(lib_id)
        x, y = q(x), q(y)
        x0, y0, x1, y1 = K.extent(lib_id)
        if (1, 0) in {pin_out(p) for p in K.pins(lib_id)}:      # pins to the right: reference and value above
            props = [("Reference", ref, (x + x0, y - y1 - 6.0), False), ("Value", value, (x + x0, y - y1 - 3.8), False)]
        else:
            props = [("Reference", ref, (x + x1 + 1.5, y - y1 + 1.0), False),
                     ("Value", value, (x + x1 + 1.5, y - y1 + 3.2), False)]
        props += [(k, v, (x, y), True) for k, v in fields]
        t = ['\t(symbol\n\t\t(lib_id "%s")\n\t\t(at %s %s 0)\n\t\t(unit 1)\n\t\t(exclude_from_sim no)\n\t\t(in_bom %s)'
             '\n\t\t(on_board yes)\n\t\t(dnp no)\n\t\t(uuid "%s")' % (lib_id, x, y, "yes" if in_bom else "no", uid(ref))]
        for k, v, (px, py), hide in props:
            t.append('\t\t(property "%s" "%s" (at %s %s 0) %s)'
                     % (k, v.replace('"', "'"), round(px, 2), round(py, 2), effects(hide=hide, justify="left")))
        for p in K.pins(lib_id):
            num = p[0]
            t.append('\t\t(pin "%s" (uuid "%s"))' % (num, uid(ref + ".pin." + num)))
            px, py = q(x + p[4]), q(y - p[5])
            if num in nc:
                self.items.append('\t(no_connect (at %s %s) (uuid "%s"))' % (px, py, uid(ref + ".nc." + num)))
                continue
            net = nets.get(num)
            if not net:
                continue
            dx, dy = pin_out(p)
            ex, ey = q(px + dx * STUB), q(py + dy * STUB)
            self.items.append('\t(wire (pts (xy %s %s) (xy %s %s)) (stroke (width 0) (type default)) (uuid "%s"))'
                              % (px, py, ex, ey, uid(ref + ".wire." + num)))
            ang, just = {(1, 0): (0, "left"), (-1, 0): (180, "right"), (0, -1): (90, "left"), (0, 1): (270, "right")}[(dx, dy)]
            self.items.append('\t(global_label "%s" (shape passive) (at %s %s %d) (fields_autoplaced yes) %s (uuid "%s")\n'
                              '\t\t(property "Intersheetrefs" "${INTERSHEET_REFS}" (at %s %s 0) %s))'
                              % (net, ex, ey, ang, effects(justify=just), uid(ref + ".label." + num), ex, ey,
                                 effects(justify=just, hide=True)))
        t.append('\t\t(instances (project "%s" (path "/%s" (reference "%s") (unit 1))))' % (BD.NAME, ROOT_UUID, ref))
        t.append("\t)")
        self.items.append("\n".join(t))

    def text(self, txt, x, y, size=2.5):
        self.items.append('\t(text "%s" (exclude_from_sim no) (at %s %s 0) %s (uuid "%s"))'
                          % (txt, q(x), q(y), effects(size, justify="left bottom", bold=True), uid("text." + txt)))

    def write(self, out):
        libs = []
        for lid in sorted(self.libs):
            s = K.symbol(lid).replace('(symbol "%s"' % lid.split(":")[1], '(symbol "%s"' % lid, 1)
            libs.append("\t\t" + s.replace("\n", "\n\t"))
        head = ('(kicad_sch\n\t(version 20231120)\n\t(generator "eeschema")\n\t(generator_version "8.0")\n\t(uuid "%s")\n'
                '\t(paper "A3")\n\t(title_block\n\t\t(title "Outage Alarm %s - PCB")\n\t\t(date "%s")\n\t\t(rev "v%s")\n'
                '\t\t(company "%s")\n\t\t(comment 1 "Generated by pcb/make_schematic.py from board.py: do not edit by hand")\n'
                '\t\t(comment 2 "Circuit drawing: hardware/electronics/schematic.svg. LED1, SW1, SW2, BZ1, U1: by wires")\n'
                '\t)\n' % (ROOT_UUID, BD.CODE, BD.DATE, BD.VERSION, BD.COMPANY))
        body = (head + "\t(lib_symbols\n" + "\n".join(libs) + "\n\t)\n" + "\n".join(self.items) +
                '\n\t(sheet_instances\n\t\t(path "/"\n\t\t\t(page "1")\n\t\t)\n\t)\n)\n')
        with open(out, "w", encoding="utf-8", newline="\n") as f:
            f.write(body)
        return out


def build():
    S = Schematic()
    x_start, y = 25.4, 30.48
    for title, refs in BLOCKS:
        S.text(title, x_start, y)
        y += 10.16
        x, row_h = x_start, 0.0
        for ref in refs:
            p = PARTS[ref]
            x0, y0, x1, y1 = K.extent(p["symbol"])
            left, right = max(0.0, -x0) + 16.0, x1 + 22.0
            cx, cy = x + left, y + y1 + 9.0
            nc = [n for n, net in p["pins"].items() if net is None]
            S.symbol(p["symbol"], ref, p["value"], cx, cy,
                     [("Footprint", p["footprint"]), ("Datasheet", "~"), ("Description", p["desc"])], p["pins"], nc=nc)
            x += left + right
            row_h = max(row_h, (y1 - y0) + 18.0)
        y += row_h + 5.08
    S.text("MOUNTING - the enclosure's four screws pass through these holes", x_start, y)
    y += 12.7
    for i in range(len(BD.SCREW_HOLES)):
        S.symbol("Mechanical:MountingHole", "H%d" % (i + 1), "M3", x_start + 10 + i * 25.4, y,
                 [("Footprint", "MountingHole:MountingHole_3.2mm_M3"), ("Datasheet", "~")], {}, in_bom=False)
    return S


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "kicad", BD.NAME + ".kicad_sch")
    print("wrote", build().write(out))
