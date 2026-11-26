"""The PCB's bill of materials (CSV), from board.py. Plain Python:
    python make_bom.py <out.csv>
Only what is soldered to the board; the parts that connect by wires are in docs/electronics.md.
"""
import csv
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import board as BD  # noqa: E402

out = sys.argv[1]
groups = {}
for p in BD.PARTS:
    key = (p["value"] if not p["ref"].startswith("J") else "pin header (optional)", p["footprint"])
    groups.setdefault(key, []).append(p)
with open(out, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f)
    w.writerow(["Qty", "References", "Value", "Footprint", "Description"])
    w.writerow([1, "PCB", f"{BD.NAME} {BD.CODE} v{BD.VERSION}", f"{BD.W:.1f} x {BD.H:.2f} mm, 2 layers, {BD.THICKNESS} mm",
                "the board itself: order it from the Gerber zip"])
    for (value, fp), parts in sorted(groups.items(), key=lambda kv: kv[1][0]["ref"]):
        refs = " ".join(p["ref"] for p in parts)
        desc = "; ".join(f"{p['ref']}: {p['desc']}" for p in parts) if len(parts) > 1 else parts[0]["desc"]
        w.writerow([len(parts), refs, value, fp, desc])
print("wrote", out)
