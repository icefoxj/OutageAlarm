"""OutageAlarm OA-01 PCB: the single source of truth of the printed circuit board.

The board replaces the perfboard (hardware/electronics/perfboard.py) with the same outline, the same screw
holes and the same part positions, so it fits the enclosure (hardware/mechanical/enclosure.scad) unchanged:
- outline: 114.3 x 66.04 mm (45 x 26 hole spacings of 2.54 mm), corners cut at 45 deg through the 2nd hole;
- four 3.2 mm holes 2 spacings in from each corner, where the shell's screws pass;
- K1, D1 and R1 on the perfboard's columns (k1_hole, d1_hole, r1_hole in enclosure.scad), and the wire pads
  where the perfboard has them.

Everything is in mm, in the enclosure's frame: origin at the inner front-left corner of the shell, x to the
right, y to the back (the top view of docs/mechanical.md). The scripts in this folder read this file:
make_schematic.py, make_pcb.py (KiCad's Python), check_pcb.py, render_pcb.py and make_bom.py.
"""

NAME = "OutageAlarm"
CODE = "OA-01"
TITLE = "OUTAGE ALARM"
VERSION = "1.3"              # the kit version this board belongs to (CHANGELOG): silkscreen and file names
COMPANY = "3DTesla"
DATE = "2026-11-26"

# --------------------------------------------------------------------------------------------- outline
PITCH = 2.54
COLS, ROWS = 45, 26
IN_X, IN_Y = 118.0, 70.0                       # inside of the shell (enclosure.scad: in_x, in_y)
X0 = (IN_X - COLS * PITCH) / 2                 # front-left corner of the board
Y0 = (IN_Y - ROWS * PITCH) / 2
W, H = COLS * PITCH, ROWS * PITCH
CUT = 2 * PITCH                                # 45 deg corner cuts
THICKNESS = 1.6


def hole(i, j):
    """Centre of perfboard hole (i, j), counted from the board's front-left corner."""
    return (round(X0 + i * PITCH, 3), round(Y0 + j * PITCH, 3))


OUTLINE = [(X0 + CUT, Y0), (X0 + W - CUT, Y0), (X0 + W, Y0 + CUT), (X0 + W, Y0 + H - CUT),
           (X0 + W - CUT, Y0 + H), (X0 + CUT, Y0 + H), (X0, Y0 + H - CUT), (X0, Y0 + CUT)]
SCREW_HOLES = [hole(2, 2), hole(COLS - 2, 2), hole(2, ROWS - 2), hole(COLS - 2, ROWS - 2)]

# Keep-outs from the enclosure: the screw posts press on the board around the holes (7 mm posts), the base
# carries the board on a 3 mm rim along its edge and on a 2 mm rib under the 18650 holder, so no solder joint
# may sit there (the solder side lies over a 2 mm pocket elsewhere)
POST_KEEPOUT_R = 4.5
RIM = 3.0
HOLDER = (11.0, 47.5, 78.0, 22.0)              # x, y, width, depth (enclosure.scad: holder_x0, holder_y0...)
RIB = (HOLDER[0] + 6, HOLDER[1] + HOLDER[3] / 2 - 1, HOLDER[2] - 12, 2.0)
U1_OUTLINE = (98.3 - 17.4 / 2, 69.5 - 29.0, 17.4, 29.0)   # the TP4056 module, on foam tape

# --------------------------------------------------------------------------------------------- parts
# place: two pads and where they go; make_pcb.py finds the rotation that puts them there.
# pins: pad number -> net (None = not connected).
HDR = "Connector_PinHeader_2.54mm:PinHeader_1x%02d_P2.54mm_Vertical"
COL = hole(33, 0)[0]                           # the column of wire pads, as on the perfboard

K1_COM = (round(hole(24.5, 5.5)[0] + 8.05, 3), hole(24.5, 5.5)[1])   # SRD footprint: COM 8.05 mm right of the pin field's centre

PARTS = [
    dict(ref="K1", value="SRD-05VDC-SL-C", symbol="Relay:SANYOU_SRD_Form_C",
         footprint="Relay_THT:Relay_SPDT_SANYOU_SRD_Series_Form_C",
         pins={"1": "ARM", "2": "COIL", "3": None, "4": "BZ+", "5": "0V"},     # 1 COM, 2/5 coil, 3 NO, 4 NC (KiCad symbol)
         place={"1": K1_COM, "4": (round(K1_COM[0] - 14.2, 3), round(K1_COM[1] - 6.0, 3))},
         desc="5 V relay, SPDT; NC (pin 4) at the front left"),
    dict(ref="D1", value="1N4007", symbol="Device:D", footprint="Diode_THT:D_DO-41_SOD81_P10.16mm_Horizontal",
         pins={"1": "COIL", "2": "0V"},                                     # 1 = cathode (band)
         place={"1": hole(29, 7), "2": hole(29, 3)},
         desc="flyback diode across the coil, band to the back"),
    dict(ref="R1", value="1k", symbol="Device:R", footprint="Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal",
         pins={"1": "LED", "2": "+5V"},
         place={"1": hole(31, 2), "2": hole(31, 6)},
         desc="LED resistor, 1/4 W"),
    dict(ref="J1", value="U1", symbol="Connector_Generic:Conn_01x04", footprint=HDR % 4,
         pins={"1": "+5V", "2": "0V", "3": "BAT-", "4": "BAT+"},              # U1 IN+, IN-, OUT-, OUT+
         place={"1": hole(33, 8), "2": hole(33, 9)},
         desc="wires to the TP4056 module: IN+, IN-, OUT-, OUT+"),
    dict(ref="J2", value="ARM", symbol="Connector_Generic:Conn_01x02", footprint=HDR % 2,
         pins={"1": "BAT+", "2": "ARM"}, place={"1": hole(33, 13), "2": hole(33, 14)},
         desc="wires to SW1, the ARM rocker switch"),
    dict(ref="J3", value="TEST", symbol="Connector_Generic:Conn_01x02", footprint=HDR % 2,
         pins={"1": "COIL", "2": "+5V"}, place={"1": hole(33, 5), "2": hole(33, 6)},
         desc="wires to SW2, the TEST button (NC)"),
    dict(ref="J4", value="LED", symbol="Connector_Generic:Conn_01x02", footprint=HDR % 2,
         pins={"1": "LED", "2": "0V"}, place={"1": hole(33, 2), "2": hole(33, 3)},
         desc="wires to LED1: 1 = + (long leg), 2 = -"),
    dict(ref="J5", value="BZ", symbol="Connector_Generic:Conn_01x02", footprint=HDR % 2,
         pins={"1": "BZ+", "2": "BAT-"}, place={"1": hole(19, 3), "2": hole(19, 4)},   # one column left of the perfboard's: clear of K1
         desc="the buzzer's leads: 1 = + (red), 2 = - (black)"),
]

# --------------------------------------------------------------------------------------------- copper
TRACK = 0.6
CLEARANCE = 0.3
EDGE_CLEARANCE = 0.5
F, B = "F.Cu", "B.Cu"


def pad(ref, num):
    """Where a pad goes (from PARTS' place; connectors continue at 2.54 mm)."""
    p = next(x for x in PARTS if x["ref"] == ref)
    if num in p["place"]:
        return p["place"][num]
    if ref.startswith("J"):
        (x1, y1), (x2, y2) = p["place"]["1"], p["place"]["2"]
        k = int(num) - 1
        return (round(x1 + (x2 - x1) * k, 3), round(y1 + (y2 - y1) * k, 3))
    raise KeyError(f"{ref}.{num}: give it in make_pcb.py's pad positions")


K1_PADS = {"1": K1_COM, "2": (round(K1_COM[0] - 1.95, 3), round(K1_COM[1] + 6.05, 3)),
           "3": (round(K1_COM[0] - 14.15, 3), round(K1_COM[1] + 6.05, 3)),
           "4": (round(K1_COM[0] - 14.2, 3), round(K1_COM[1] - 6.0, 3)),
           "5": (round(K1_COM[0] - 1.95, 3), round(K1_COM[1] - 5.95, 3))}
P = {f"K1.{n}": xy for n, xy in K1_PADS.items()}
for _p in PARTS:
    if _p["ref"] != "K1":
        for _n in _p["pins"]:
            P[f"{_p['ref']}.{_n}"] = pad(_p["ref"], _n)

XR = round(COL + 2.93, 3)                      # the 0V link behind the column of wire pads (top layer)
XL = 47.0                                      # BAT- down the left of J5
TRACKS = [   # net, layer, points (each point a pad name or (x, y))
    ("LED", B, ["R1.1", "J4.1"]),
    ("+5V", B, ["J1.1", "J3.2", "R1.2"]),
    ("COIL", B, ["J3.1", (77.67, P["J3.1"][1]), (75.51, 16.84), "D1.1", (73.27, P["K1.2"][1]), "K1.2"]),
    ("0V", B, ["K1.5", (70.58, P["D1.2"][1]), "D1.2", "J4.2"]),
    ("0V", F, ["J4.2", (XR, P["J4.2"][1]), (XR, P["J1.2"][1]), "J1.2"]),
    ("BAT+", B, ["J1.4", "J2.1"]),
    ("ARM", F, ["J2.2", (73.5, P["J2.2"][1]), (73.5, P["K1.1"][1] + 1.37), "K1.1"]),
    ("BZ+", B, ["K1.4", (P["K1.4"][0] - 0.35, P["J5.1"][1]), "J5.1"]),
    ("BAT-", B, ["J1.3", (XL, P["J1.3"][1]), (XL, P["J5.2"][1]), "J5.2"]),
]

# --------------------------------------------------------------------------------------------- silkscreen
# Text in the house mech font (mechfont.py), drawn as filled polygons: (text, x, y, cap height, stroke,
# anchor) with (x, y) the anchor point at mid-height of the caps; anchor "left", "center" or "right".
LABEL_CAP, LABEL_W = 1.4, 0.22
LX = round(COL + 1.75, 3)                      # labels right of the column of wire pads
LABELS = [
    ("LED+", LX, P["J4.1"][1], "left"), ("LED-", LX, P["J4.2"][1], "left"),
    ("TEST", LX, (P["J3.1"][1] + P["J3.2"][1]) / 2, "left"),
    ("U1 IN+", LX, P["J1.1"][1], "left"), ("U1 IN-", LX, P["J1.2"][1], "left"),
    ("U1 OUT-", LX, P["J1.3"][1], "left"), ("U1 OUT+", LX, P["J1.4"][1], "left"),
    ("ARM", LX, (P["J2.1"][1] + P["J2.2"][1]) / 2, "left"),
    ("BZ+", P["J5.1"][0] - 1.9, P["J5.1"][1], "right"), ("BZ-", P["J5.2"][0] - 1.9, P["J5.2"][1], "right"),
]
REFS = [("K1", hole(24.5, 5.5)[0], 25.8, 2.2, 0.32),                 # above the relay (its outline has a drawing inside)
        ("D1", P["D1.1"][0], P["D1.1"][1] + 2.6, 1.6, 0.26),
        ("R1", P["R1.2"][0], P["R1.2"][1] + 2.1, 1.6, 0.26)]
NC_MARK = ("NC", P["K1.4"][0] + 2.6, P["K1.4"][1], 1.2, 0.2)   # beside the relay's NC pin

# Title block, top side, left of the relay: a title band with the unit code knocked out, the name, the
# version and the company, and hazard stripes
TITLE_BLOCK = dict(x0=10.0, x1=46.2, band=(40.0, 45.4), code_cap=3.2, code_w=0.5,
                   title_y=34.6, title_cap=3.4, title_w=0.48,
                   line_y=29.2, line_cap=2.0, line_w=0.3,
                   hazard=(21.4, 25.0), stripe=1.4)
# Bottom side: mirrored so it reads from below
BOTTOM_TEXT = [(f"{CODE} V{VERSION}", 31.0, 36.0, 2.4, 0.36), (COMPANY.upper(), 31.0, 31.6, 2.4, 0.36),
               ("SOLDER SIDE", 31.0, 26.0, 1.6, 0.26), ("TRIM LEADS TO 1.5 MM", 31.0, 22.8, 1.6, 0.26)]
