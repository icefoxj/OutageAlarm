"""Writes the KiCad 8 project files of the PCB: OutageAlarm.kicad_pro, sym-lib-table and fp-lib-table.

The design rules (clearance, track width, edge clearance) come from board.py. The library tables point at
KiCad 8's own libraries, so the project opens in a KiCad without global tables. Plain Python:
    python make_project.py
"""
import json
import os
import sys
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import board as BD  # noqa: E402

KICAD = os.path.join(HERE, "..", "kicad")
ROOT_UUID = str(uuid.uuid5(uuid.NAMESPACE_URL, "OutageAlarm/pcb/schematic-root"))


def project():
    rules = {"max_error": 0.005, "min_clearance": 0.2, "min_connection": 0.0,
             "min_copper_edge_clearance": BD.EDGE_CLEARANCE, "min_hole_clearance": 0.25, "min_hole_to_hole": 0.25,
             "min_microvia_diameter": 0.2, "min_microvia_drill": 0.1, "min_resolved_spokes": 2,
             "min_silk_clearance": 0.0, "min_text_height": 0.8, "min_text_thickness": 0.08,
             "min_through_hole_diameter": 0.3, "min_track_width": 0.2, "min_via_annular_width": 0.1,
             "min_via_diameter": 0.6, "solder_mask_to_copper_clearance": 0.0, "use_height_for_length_calcs": True}
    net_class = {"bus_width": 12, "clearance": BD.CLEARANCE, "diff_pair_gap": 0.25, "diff_pair_via_gap": 0.25,
                 "diff_pair_width": 0.2, "line_style": 0, "microvia_diameter": 0.3, "microvia_drill": 0.1,
                 "name": "Default", "pcb_color": "rgba(0, 0, 0, 0.000)", "schematic_color": "rgba(0, 0, 0, 0.000)",
                 "track_width": BD.TRACK, "via_diameter": 0.8, "via_drill": 0.4, "wire_width": 6}
    d = {
        "board": {"design_settings": {"defaults": {"board_outline_line_width": 0.1, "copper_line_width": 0.2,
                                                   "silk_line_width": 0.15, "silk_text_size_h": 1.0,
                                                   "silk_text_size_v": 1.0, "silk_text_thickness": 0.15},
                                      "rules": rules, "track_widths": [0.0, BD.TRACK], "via_dimensions": []},
                  "layer_presets": [], "viewports": []},
        "boards": [],
        "cvpcb": {"equivalence_files": []},
        "libraries": {"pinned_footprint_libs": [], "pinned_symbol_libs": []},
        "meta": {"filename": BD.NAME + ".kicad_pro", "version": 1},
        "net_settings": {"classes": [net_class], "meta": {"version": 3}, "net_colors": None,
                         "netclass_assignments": None, "netclass_patterns": []},
        "pcbnew": {"last_paths": {}, "page_layout_descr_file": ""},
        "schematic": {"legacy_lib_dir": "", "legacy_lib_list": []},
        "sheets": [[ROOT_UUID, "Root"]],
        "text_variables": {},
    }
    with open(os.path.join(KICAD, BD.NAME + ".kicad_pro"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(d, f, indent=2)
        f.write("\n")


SYMBOL_LIBS = ["Connector_Generic", "Device", "Mechanical", "Relay"]
FOOTPRINT_LIBS = ["Connector_PinHeader_2.54mm", "Diode_THT", "MountingHole", "Relay_THT", "Resistor_THT"]


def tables():
    s = ["(sym_lib_table", "  (version 7)"]
    s += ['  (lib (name "%s")(type "KiCad")(uri "${KICAD8_SYMBOL_DIR}/%s.kicad_sym")(options "")(descr "KiCad 8"))'
          % (n, n) for n in SYMBOL_LIBS]
    s.append(")")
    with open(os.path.join(KICAD, "sym-lib-table"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(s) + "\n")
    t = ["(fp_lib_table", "  (version 7)"]
    t += ['  (lib (name "%s")(type "KiCad")(uri "${KICAD8_FOOTPRINT_DIR}/%s.pretty")(options "")(descr "KiCad 8"))'
          % (n, n) for n in FOOTPRINT_LIBS]
    t.append(")")
    with open(os.path.join(KICAD, "fp-lib-table"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(t) + "\n")


if __name__ == "__main__":
    os.makedirs(KICAD, exist_ok=True)
    project()
    tables()
    print("wrote", os.path.abspath(KICAD))
