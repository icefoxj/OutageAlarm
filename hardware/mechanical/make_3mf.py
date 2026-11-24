#!/usr/bin/env python3
"""Pack the two-colour armor plates of the enclosure into one 3MF.

    python3 make_3mf.py <parts dir> <output dir>

<parts dir> holds the STLs that enclosure.scad exports, in print orientation, with
part = "plate_face_2color", "plate_front_2color", "plate_back_2color", "inlay_face",
"inlay_front" and "inlay_back" (see the header of enclosure.scad, or
.github/workflows/render-enclosure.yml). It writes enclosure_plates_2color.3mf.

The 3MF follows the core spec (2015/02), with no slicer extensions. Each plate is
one object made of two named meshes, the plate and its inlay, and the three plates
are laid out side by side on the bed, so they print together. Creality Print, Bambu
Studio, OrcaSlicer and PrusaSlicer load each plate as one object whose parts each
take their own filament. The colours go in as base materials: a hint that the
slicer may ignore.

Before writing, it checks that:
- every mesh is closed and consistently oriented, with a positive volume;
- each printed part lies on the bed (z = 0);
- every inlay is a slab exactly INLAY_DEPTH thick, so no part of it thins out over
  an edge, a chamfer or a hole.
It prints the layers that hold each inlay. Each of them costs filament changes.

Python 3 standard library only.
"""

import math
import struct
import sys
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

INLAY_DEPTH = 0.6   # inlay_depth in enclosure.scad
LAYER = 0.2         # layer height used to count the two-colour layers
GREY, YELLOW = ("Grey", "#A7ABB1"), ("Yellow", "#FFCC00")   # plate_color, livery_color in enclosure.scad
GAP = 6             # between the plates on the bed (mm)
# Output file, objects: (object name, parts: (name in the 3MF, STL file, colour)).
# The first part of an object is the printed plate; the second is the inlay that
# fills its recess.
MODELS = [
    ("enclosure_plates_2color.3mf", [
        ("OutageAlarm face plate", [("face_plate", "plate_face_2color.stl", GREY),
                                    ("face_livery", "inlay_face.stl", YELLOW)]),
        ("OutageAlarm front plate", [("front_plate", "plate_front_2color.stl", GREY),
                                     ("front_livery", "inlay_front.stl", YELLOW)]),
        ("OutageAlarm back plate", [("back_plate", "plate_back_2color.stl", GREY),
                                    ("back_livery", "inlay_back.stl", YELLOW)]),
    ]),
]


def fail(message):
    sys.exit(f"make_3mf: {message}")


def read_stl(path):
    """Indexed mesh from an ASCII or binary STL: (vertices, triangles)."""
    data = path.read_bytes()
    corners = []
    if data.lstrip().startswith(b"solid") and b"facet" in data[:1024]:
        for line in data.decode("ascii").splitlines():
            t = line.split()
            if t and t[0] == "vertex":
                corners.append(tuple(float(c) for c in t[1:4]))
    else:
        (n,) = struct.unpack_from("<I", data, 80)
        for i in range(n):
            f = struct.unpack_from("<12f", data, 84 + 50 * i)
            corners += [f[3:6], f[6:9], f[9:12]]
    index, verts, tris = {}, [], []
    for k in range(0, len(corners), 3):
        tri = []
        for c in corners[k:k + 3]:
            if c not in index:
                index[c] = len(verts)
                verts.append(c)
            tri.append(index[c])
        if len(set(tri)) == 3:
            tris.append(tri)
    return verts, tris


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def check_closed(name, tris):
    """Every edge must be used once in each direction."""
    edges = Counter((t[i], t[(i + 1) % 3]) for t in tris for i in range(3))
    bad = sum(1 for (a, b), n in edges.items() if n != 1 or edges.get((b, a)) != 1)
    if bad:
        fail(f"{name}: {bad} edges are open, shared by more than two triangles or flipped")


def volume(verts, tris):
    return sum(dot(verts[a], cross(verts[b], verts[c])) for a, b, c in tris) / 6


def slab_thickness(verts, tris):
    """Along the direction of the largest faces: (distance between the outermost
    vertices, largest distance of a vertex from both of those two planes)."""
    area, normal = defaultdict(float), defaultdict(lambda: (0.0, 0.0, 0.0))
    for a, b, c in tris:
        n = cross(sub(verts[b], verts[a]), sub(verts[c], verts[a]))
        length = math.sqrt(dot(n, n))
        if length == 0:
            continue
        u = tuple(x / length for x in n)
        key = max(tuple(round(x, 2) for x in u), tuple(round(-x, 2) for x in u))
        if key != tuple(round(x, 2) for x in u):
            n = tuple(-x for x in n)
        area[key] += length / 2
        normal[key] = tuple(p + q for p, q in zip(normal[key], n))
    n = normal[max(area, key=area.get)]
    n = tuple(x / math.sqrt(dot(n, n)) for x in n)
    d = [dot(v, n) for v in verts]
    lo, hi = min(d), max(d)
    return hi - lo, max(min(x - lo, hi - x) for x in d)


def layers(verts, tris):
    """Indices of the LAYER-high layers whose mid-plane cuts the mesh."""
    found = set()
    for t in tris:
        zs = [verts[i][2] for i in t]
        lo, hi = min(zs), max(zs)
        for k in range(max(0, math.floor(lo / LAYER - 0.5)), math.ceil(hi / LAYER - 0.5) + 1):
            if lo < (k + 0.5) * LAYER < hi:
                found.add(k)
    return found


def z_ranges(ks):
    """'0.0-0.6, 10.2-15.4 mm' from a set of layer indices."""
    out, ks = [], sorted(ks)
    for i, k in enumerate(ks):
        if i == 0 or k != ks[i - 1] + 1:
            out.append([k, k])
        else:
            out[-1][1] = k
    return ", ".join(f"{a * LAYER:.1f}-{(b + 1) * LAYER:.1f}" for a, b in out) + " mm"


def num(x):
    s = f"{x:.5f}".rstrip("0").rstrip(".")
    return "0" if s in ("", "-0") else s


def write_3mf(path, objects):
    """objects: (object name, meshes: (part, verts, tris, colour, rgb))."""
    model = ['<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" '
             'xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02"><resources>'
             '<basematerials id="1">']
    colours = list(dict.fromkeys((m[3], m[4]) for _, meshes in objects for m in meshes))
    model += [f'<base name="{colour}" displaycolor="{rgb}FF"/>' for colour, rgb in colours]
    model.append("</basematerials>")
    next_id, groups = 2, []
    for name, meshes in objects:
        first = next_id
        for part, verts, tris, colour, rgb in meshes:
            model.append(f'<object id="{next_id}" name="{part}" type="model" pid="1" '
                         f'pindex="{colours.index((colour, rgb))}"><mesh><vertices>')
            model += [f'<vertex x="{num(x)}" y="{num(y)}" z="{num(z)}"/>' for x, y, z in verts]
            model.append("</vertices><triangles>")
            model += [f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tris]
            model.append("</triangles></mesh></object>")
            next_id += 1
        model.append(f'<object id="{next_id}" name="{name}" type="model"><components>')
        model += [f'<component objectid="{i}"/>' for i in range(first, next_id)]
        model.append("</components></object>")
        groups.append(next_id)
        next_id += 1
    model.append("</resources><build>")
    model += [f'<item objectid="{g}"/>' for g in groups]
    model.append("</build></model>")
    types = ('<?xml version="1.0" encoding="UTF-8"?>\n'
             '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
             '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
             '<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
             "</Types>")
    rels = ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Target="/3D/3dmodel.model" Id="rel0" '
            'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", types)
        z.writestr("_rels/.rels", rels)
        z.writestr("3D/3dmodel.model", "".join(model))


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    parts_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    for file_name, objects in MODELS:
        out_objects, two_colour, y_next = [], set(), 0.0
        for object_name, parts in objects:
            meshes = []
            for i, (part, file, (colour, rgb)) in enumerate(parts):
                verts, tris = read_stl(parts_dir / file)
                check_closed(part, tris)
                vol = volume(verts, tris)
                if vol <= 0:
                    fail(f"{part}: the mesh is inside out or empty")
                zs = [v[2] for v in verts]
                line = f"  {part}: {len(tris)} triangles, {vol / 1000:.2f} cm3, z {min(zs):.2f} to {max(zs):.2f} mm"
                if i == 0:
                    if abs(min(zs)) > 1e-3:
                        fail(f"{part}: it does not lie on the bed (lowest z = {min(zs)})")
                else:
                    t, off = slab_thickness(verts, tris)
                    if abs(t - INLAY_DEPTH) > 0.01 or off > 0.01:
                        fail(f"{part}: not a {INLAY_DEPTH} mm slab everywhere ({t:.3f} mm thick, a vertex "
                             f"{off:.3f} mm off its faces): it runs onto an edge, a chamfer or a hole")
                    ks = layers(verts, tris)
                    two_colour |= ks
                    line += f", {INLAY_DEPTH} mm deep, in {len(ks)} layers ({z_ranges(ks)})"
                meshes.append((part, verts, tris, colour, rgb))
                print(line)
            # Lay the plates out along Y, each one centred on X = 0, GAP from the last
            xs = [v[0] for v in meshes[0][1]]
            ys = [v[1] for v in meshes[0][1]]
            dx, dy = -(min(xs) + max(xs)) / 2, y_next - min(ys)
            y_next += max(ys) - min(ys) + GAP
            out_objects.append((object_name, [(m[0], [(x + dx, y + dy, z) for x, y, z in m[1]], m[2], m[3], m[4])
                                              for m in meshes]))
        out = out_dir / file_name
        write_3mf(out, out_objects)
        print(f"{out}: {len(two_colour)} two-colour layers of {LAYER} mm ({z_ranges(two_colour)})")


if __name__ == "__main__":
    main()
