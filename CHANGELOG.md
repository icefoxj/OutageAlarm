# Changelog

All notable changes to OutageAlarm are listed here.
- The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
- Versions follow [Semantic Versioning](https://semver.org/). The major version is the project phase: v1 is the simple version, v2 will add an ESP32.

## [Unreleased]

## [1.0.0] - 2026-11-11

First release: the simple v1, with no microcontroller and no firmware.

### Circuit

- **Normal operation:** a USB charger in the wall powers a TP4056 module with protection (U1). U1 keeps an 18650 cell (BT1) charged, and the same 5 V keeps relay K1 energised.
- **Outage:** when the 5 V is lost, K1's NC contact closes and the SFM-27 buzzer (BZ1) sounds, powered by the cell. Any loss of the 5 V sets it off: outage, tripped breaker, dead charger or loose cable.
- **TEST and ARM:**
  - TEST (SW2, an NC pushbutton) cuts the relay coil, so it checks the whole chain the way a real outage does.
  - ARM (SW1, a KCD1-101 rocker switch) arms and disarms the alarm.
- **Documentation:** the schematic, BOM, calculations, wiring table, bench test and troubleshooting are in [docs/electronics.md](docs/electronics.md).

### Enclosure

- **Shape:** a wedge. The control face tilts 20° and the front leans back 10°, with R10 corners and a 45° chamfer around the face. It sits on a dark base with a 45° undercut.
  - Size: 122.8 × 74.8 mm, 33 mm tall at the front and 58.5 mm at the back.
- **Printed parts:** three, all printed without supports:
  - the top: the face and its chamfer;
  - the sides: the walls and the screw posts;
  - the base.
- **Joint:** the top is glued onto the sides. A lip under the top fits inside the walls, with a 0.15 mm glue gap per side, a lead-in chamfer and a groove for the excess glue. The seam runs along the crease under the face chamfer.
- **Closing:** the shell screws onto the base with four hidden M3 screws from below.
- **Mech-style livery,** like the markings on anime mechs, inlaid 0.6 mm in a second filament:
  - a title band with the unit code "OA-01";
  - a reticle around the speaker grille;
  - hazard stripes with "FAIL-SAFE";
  - "// OUTAGE ALARM //" on the front and "5V" on the back.
  - All the lettering is in a chamfered, straight-line stroke font.
- **Print files:**
  - Two-colour 3MFs for the top (3 two-colour layers) and for the sides (56).
  - One-colour STLs for all three parts, with the labels engraved.
- **Model:** parametric, in OpenSCAD, with a clearance check (`assert`) for every critical fit.

### Tooling

- **CI:** GitHub Actions renders the STLs, the 3MFs and the images whenever the model changes. It fails on any OpenSCAD error or warning.
- **3MF builder:** `make_3mf.py` packs the two-colour parts into core 3MFs. It checks that every mesh is closed and every inlay is exactly 0.6 mm thick.

### Not tested yet

- The enclosure has not been test-printed. Check these on your parts:
  - the rocker switch cutout and the TEST button hole (they vary by vendor);
  - the fit of the top's lip in the sides (`glue_gap`).

[Unreleased]: https://github.com/icefoxj/OutageAlarm/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/icefoxj/OutageAlarm/releases/tag/v1.0.0
