# Changelog

All notable changes to OutageAlarm are listed here.
- The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
- Versions follow [Semantic Versioning](https://semver.org/). The major version is the project phase: v1 is the simple version, v2 will add an ESP32.

## [Unreleased]

## [1.1.0] - 2026-11-24

The enclosure in the house look of the other 3DTesla kits, a one-piece shell, and all the electronics on one perfboard.

### Changed

- **House look.** The enclosure now looks like the other 3DTesla kits:
  - a graphite body with its corners cut at 45° (they were rounded), on a darker base;
  - three grey armor plates with cut corners, glued onto the face, the front and the back, each located by two pegs;
  - the mech livery in house yellow (it was red), inlaid only in the plates. The reticle's ticks are at 45°, brackets frame ARM, the front plate carries the title band with "OA-01", and chevrons on the back plate point at the USB-C.
  - The shell and the base are now one-colour prints, with no marks. All the second colour is in one print of the three plates: 3 two-colour layers, about 6 filament changes (it was 59 layers, 116 changes, in the top and the sides).
  - The face is cut away under the rocker, so the 2 mm face plate alone holds it. TEST now mounts through 4.4 mm.
  - The mech font has the full glyph set of the other kits.
  - Print files: `stl/enclosure_plate_{face,front,back}.stl` and `3mf/enclosure_plates_2color.3mf` are new; `enclosure_top_2color.3mf` and `enclosure_sides_2color.3mf` are gone.
- **One-piece shell.** The top and the sides are one part again, printed face down: no lip, no glue joint. The screw posts reach up into the face. `stl/enclosure_shell.stl` replaces `enclosure_top.stl` and `enclosure_sides.stl`.
- **Sheets:** the schematic and the perfboard layout have the house header: "OA-01" on a yellow band, hazard stripes. The perfboard layout uses the monospace font of the other kits' sheets.
- **One perfboard for all the electronics.** It covers the floor and holds the 18650 holder, the TP4056 module, K1, D1, R1 and a pad for every wire.
  - The four shell screws pass through its corners, so the screw posts clamp it to the base. The standoffs and the M2 screws are gone.
  - The layout is in [hardware/electronics/perfboard.svg](hardware/electronics/perfboard.svg), drawn 1:1 on A4: printed at 100 %, it is a cutting and drilling template.
- **Base:** flat on top, with a 2 mm pocket for the board's solder side. The holder rib and the TP4056 cradle are gone.
- **Screw posts:** they moved over the board's holes (6.9 × 7.1 mm from the inner walls) and stop on top of the board. The screws are now M3 × 16.
- **USB-C opening:** 0.6 mm lower (5.4 mm above the base), for the TP4056 module on 1 mm foam tape on the board.

### Added

- **Theory guide** (`docs/theory/pdf/`, 2026-11-20): the theory course as an illustrated PDF in the house mech look, one per language (`OA-01_theory_<lang>.pdf`: en, pt, pt-br, es, fr, it, de), with the course's figures, drawings and pictures of the kit. Built from `docs/theory/` by the 3DTesla website repository, which keeps the translations and drawings; CLAUDE.md says how to keep it in step with every change to the kit.
- **Theory chapters** (`docs/theory/`, 2026-11-20): 7 chapters that explain the theory used in the kit, from the fundamentals to the kit's own numbers: the fail-safe principle, mains and isolation, the relay, the cell and the charger, the sound, the power budget and the enclosure. `docs/theory/figures.py` draws the 16 simulation and calculation figures into `docs/img/theory/`. Model values that are not in the repository are marked as assumptions; every number is a design value, an estimate or a simulation result. These chapters are the source of the kit's illustrated theory guide (PDF, seven languages).

### Not tested yet

- The enclosure has not been printed in this version either. Check on your parts:
  - the TEST button through 4.4 mm (the face and its plate) and the rocker's clips in the 2 mm face plate;
  - the fit of the plates' pegs in their holes (`peg_clear`);
  - the perfboard and the relay's off-grid pins against the 1:1 template.

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

[Unreleased]: https://github.com/icefoxj/OutageAlarm/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/icefoxj/OutageAlarm/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/icefoxj/OutageAlarm/releases/tag/v1.0.0
