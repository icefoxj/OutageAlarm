"""Pictures of the PCB as it would come from the factory (black solder mask, white silkscreen, HASL pads):
docs/img/pcb_top.png and docs/img/pcb_bottom.png (the bottom seen from below, so mirrored).
Runs with KiCad 8's Python (pcbnew and matplotlib):
    python render_pcb.py [board.kicad_pcb] [out_dir]
"""
import os
import sys

import matplotlib
import pcbnew

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Circle, PathPatch  # noqa: E402
from matplotlib.path import Path  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import board as BD  # noqa: E402

OX, OY = 100.0, 150.0
BG, MASK, CU, PAD, SILK = "#F4F5F7", "#1B1D21", "#2B2E35", "#C3C7CD", "#F2F2EE"


def layer_paths(b, layer, mirror):
    ps = pcbnew.SHAPE_POLY_SET()
    b.ConvertBrdLayerToPolygonalContours(layer, ps)
    out = []
    for i in range(ps.OutlineCount()):
        rings = [ps.Outline(i)] + [ps.Hole(i, h) for h in range(ps.HoleCount(i))]
        verts, codes = [], []
        for r in rings:
            pts = [pt(r.CPoint(j), mirror) for j in range(r.PointCount())]
            verts += pts + [pts[0]]
            codes += [Path.MOVETO] + [Path.LINETO] * (len(pts) - 1) + [Path.CLOSEPOLY]
        out.append(Path(verts, codes))
    return out


def pt(p, mirror):
    x, y = pcbnew.ToMM(p.x) - OX, OY - pcbnew.ToMM(p.y)
    return (BD.X0 * 2 + BD.W - x, y) if mirror else (x, y)


def render(pcb, out, side):
    b = pcbnew.LoadBoard(pcb)
    mirror = side == "bottom"
    cu, mask, silk = ((pcbnew.F_Cu, pcbnew.F_Mask, pcbnew.F_SilkS) if not mirror
                      else (pcbnew.B_Cu, pcbnew.B_Mask, pcbnew.B_SilkS))
    m = 4.0
    x0, x1, y0, y1 = BD.X0 - m, BD.X0 + BD.W + m, BD.Y0 - m - 4, BD.Y0 + BD.H + m
    fig = plt.figure(figsize=(16, 16 * (y1 - y0) / (x1 - x0)), dpi=100)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(x0, x1)
    ax.set_ylim(y0, y1)
    ax.set_aspect("equal")
    ax.axis("off")
    fig.patch.set_facecolor(BG)
    outline = [((BD.X0 * 2 + BD.W - x) if mirror else x, y) for x, y in BD.OUTLINE]
    ax.add_patch(PathPatch(Path(outline + [outline[0]], [Path.MOVETO] + [Path.LINETO] * len(outline)),
                           facecolor=MASK, edgecolor="#0E0F11", lw=1.0))
    for p in layer_paths(b, cu, mirror):
        ax.add_patch(PathPatch(p, facecolor=CU, edgecolor="none"))
    for p in layer_paths(b, mask, mirror):              # mask openings: the exposed copper of the pads
        ax.add_patch(PathPatch(p, facecolor=PAD, edgecolor="none"))
    for p in layer_paths(b, silk, mirror):
        ax.add_patch(PathPatch(p, facecolor=SILK, edgecolor="none"))
    for fp in b.GetFootprints():
        for pd in fp.Pads():
            d = pcbnew.ToMM(pd.GetDrillSize().x)
            if d > 0:
                ax.add_patch(Circle(pt(pd.GetPosition(), mirror), d / 2, facecolor=BG, edgecolor="#8A8E95", lw=0.6))
    label = ("COMPONENT SIDE (TOP)" if not mirror else "SOLDER SIDE (BOTTOM), SEEN FROM BELOW")
    ax.text(BD.X0, BD.Y0 - 3.2, f"{BD.CODE} PCB V{BD.VERSION}  //  {label}", fontsize=13, family="monospace",
            color="#1F2328", va="center")
    fig.savefig(out, dpi=100, facecolor=BG)
    plt.close(fig)
    return out


if __name__ == "__main__":
    args = sys.argv[1:]
    pcb = args[0] if args else os.path.join(HERE, "..", "kicad", BD.NAME + ".kicad_pcb")
    out_dir = args[1] if len(args) > 1 else os.path.join(HERE, "..", "..", "..", "docs", "img")
    for side in ("top", "bottom"):
        print("wrote", render(pcb, os.path.join(out_dir, f"pcb_{side}.png"), side))
