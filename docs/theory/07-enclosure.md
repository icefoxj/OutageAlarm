# 7. The enclosure

OA-01's enclosure is a 3D-printed wedge: a one-piece **shell** (the control face, the walls and the screw posts) and a darker **base**, both in graphite, with three grey **armor plates** glued onto the face, the front and the back. It holds one perfboard with all the electronics, puts the controls where hands and eyes find them, lets the buzzer out, keeps the charger's heat in check and carries the mech livery on its plates, in the house style of the other 3DTesla kits. The model is parametric, in OpenSCAD, and it has not been test-printed yet: the numbers below are the design values of the model, and the thermal results are estimates from a simple model.

## 7.1 The wedge

Seen from the side, the shell is a wedge: the control face tilts **20°** toward the user and the front leans back **10°**. The outer footprint is 122.8 × 74.8 mm, with its corners cut at 45° (9 mm) in top view; the whole unit is 33 mm tall at the front and 58.5 mm at the back, base included. Walls and face are 2.4 mm thick (six lines of a 0.4 mm nozzle), and a 3 mm, 45° chamfer runs around the face.

The shape follows the parts and the user:

- **The tilt** turns the face toward someone standing or sitting in front of a desk or a shelf, so the POWER LED is seen and the TEST button and the ARM switch are reached without lifting the unit. A face tilted by $\theta$ is foreshortened by $\cos\theta$ seen from above and by $\sin\theta$ seen from the front; 20° keeps it readable from both.
- **The tall back** gives room for the tallest parts: the 18650 holder (about 21 mm high with the cell) against the back wall, and the TP4056 module with its USB-C receptacle facing the back, 5.4 mm above the base.
- **The buzzer** (30 mm wide, 15 mm deep) hangs under the grille where the face is high enough, and the relay sits in front and to its right. The model checks every one of these clearances with `assert()` statements, so a change of a parameter that makes two parts collide stops the build.
- **The base** is 6 mm thick with a 45° undercut of 3 mm along its bottom edge: from normal viewing angles its own shadow separates the shell from the table, and the unit seems to float.

## 7.2 Heat inside a closed box

The enclosure has no vents (the grille is the only opening, and the buzzer seals it). Two things warm it: K1's coil, 0.36 W all the time, and the TP4056 while it recharges the cell, about 1 W for a few hours after an outage (chapter 4).

Heat leaves a closed box through its outer surface by **natural convection** and **radiation**. Both together can be lumped into a heat transfer coefficient $h$, typically 5–10 W/(m²·K) for a small object in still air (about half of it radiation, for a matt plastic surface). The steady temperature rise of the box over the room is then

$$\Delta T = \frac{P}{h A}$$

OA-01's outer surface, without the bottom that stands on the shelf, is about 280 cm² (0.028 m²). With $h$ ≈ 9 W/(m²·K), the box sheds about 0.25 W per kelvin:

- **standby** (coil and LED, 0.37 W): ΔT ≈ 1.5 K;
- **recharging at 1 A** (≈ 1.4 W in total): about 6 K at the peak.

The box does not reach that at once. Its parts have a **heat capacity** $C_{th}$: the printed plastic, the cell and the board, roughly 190 J/K together (estimated from typical masses and specific heats). The rise follows a first-order lag with the time constant

$$\tau_{th} = \frac{C_{th}}{hA} \approx \frac{190}{0.25} \approx 750\ \text{s} \approx 13\ \text{min}$$

![Inside the box while it recharges](../img/theory/box_temperature.png)

*Figure T16 (simulation, lumped thermal model, assumed h = 9 W/(m²·K), 190 J/K): mean temperature rise of the enclosure over the room after the power returns from a long outage, with the charger at 1 A and at 0.5 A.*

The mean rise is small. The local one is not: the TP4056 chip concentrates its watt in a few square millimetres and runs much hotter than the air around it, which is why it has thermal regulation (it throttles at about 120 °C die temperature). The hot phase is short, because the cell is almost always full: the kit's documentation notes that it only happens for a few hours after an outage. For less heat it offers the 2.4 kΩ program resistor, which halves the charge current and roughly halves the heat power (peak mean rise about 4 K instead of 6 K in the model).

## 7.3 Materials and temperature

The kit prints the shell in graphite PLA or PETG, the base in a darker graphite and the plates in light grey. The two materials differ mainly in how they behave when warm:

- **PLA** softens around its glass transition, about 55–60 °C. A PLA box in a room, warmed by a few kelvin, is far from it.
- **PETG** softens around 75–80 °C. The kit's documentation recommends it "for warm places": an attic, a garage in summer, a shelf in the sun, or next to a heater, where a dark PLA part could creep under the screws over months.

Colour matters in the sun. A graphite shell absorbs most of the sunlight that falls on it, where a white one would reflect most of it. Out of the sun it hardly matters: the box loses its heat by convection and by infrared radiation, and in the infrared most plastics are nearly black, whatever their visible colour. So a graphite box in direct sun runs much warmer than the model above, which is one more reason for PETG in sunny places, or better, for a spot in the shade. The cell inside cares too: lithium-ion cells are generally charged between about 0 and 45 °C and age faster when kept hot at full charge (chapter 4). An outage alarm should live somewhere a person would be comfortable.

## 7.4 Printing without supports: the 45° rule

A fused-filament printer lays each line of plastic on top of the previous layer. A wall that leans out by an angle $\theta$ from the vertical makes each layer step out by

$$\Delta = h \tan\theta$$

where $h$ is the layer height. With $h$ = 0.2 mm and a 0.4 mm wide line, a 45° overhang steps out 0.2 mm per layer: each new line rests on half of the one below, which is about the limit that prints cleanly without supports. Steeper overhangs droop; horizontal ones need **bridges** (lines stretched between two supports, which work over short spans) or supports.

All the parts of OA-01 are oriented to stay within that rule:

- **The shell** prints **face down**, in one piece. The face is the first layer, so it comes out flat for its armor plate, and the grille and the holes form in the first layers. In this orientation the face chamfer is exactly 45°, the walls lean at most 30° and the screw posts grow straight up from the face. The part is 49 mm tall as printed.
- **The base** prints flat; its undercut is a 45° overhang, and the pocket for the perfboard's solder side is on top.
- **The armor plates** print **visible face down**, all three together. The visible face takes the texture of the bed (glossy on smooth PEI or glass, matt on textured PEI), the 0.6 mm chamfer around it is a 45° overhang, and the locating pegs grow up from the back.

No supports means no support scars, no post-processing and exact surfaces where parts meet. The orientations are already in the print files.

## 7.5 A livery in three layers

The mech livery (title bands with the unit code OA-01, a reticle around the grille, hazard stripes with "FAIL-SAFE", brackets around ARM, the labels TEST, ARM and POWER, the wordmark on the front and "5V" on the back) is **inlaid** flush in a second filament, 0.6 mm deep, in house yellow. A printer with a multi-material unit changes filament within a layer; every layer that holds a second colour costs up to two filament changes and some purged plastic, so the geometry of the inlay decides the cost.

- On a **flat plate printed face down**, the inlay is a slab parallel to the layers: 0.6 mm is exactly **3 layers** of 0.2 mm (0.15 or 0.12 mm layers also divide it).
- On a **wall that stands up in the print**, the inlay would be a thin skin across many layers, one per 0.2 mm of its height. An earlier version of OA-01 had the wordmark on the front wall and "5V" on the back wall: 27 and 29 layers, 56 in all, about 110 changes.

That is why the whole livery sits on three flat **armor plates**, glued onto the shell, and why the three print together: all the second colour is in the same 3 layers, about 6 filament changes for the whole enclosure, and the shell and the base print in one colour on any printer. The plates are a style of the house too: on the other kits, plates with cut corners stand on a graphite body and carry the livery.

Resolution follows from the same geometry. Printed flat, the lettering is drawn with strokes of 0.8 mm or more, two lines of a 0.4 mm nozzle, so each stroke is whole in each of its 3 layers. On a wall, each layer would cut the inlay into a strip only about 0.7 mm wide, and the lettering would need strokes about twice as wide. A one-colour version of the plates, with the marks engraved 0.6 mm deep instead, needs no second filament at all.

## 7.6 Plates on pegs

The shell is a single part: with the livery on the plates there is no colour to split it for, so it has no seam and nothing to glue. Only the three armor plates are glued on, and each is located by two pegs, a small exercise in tolerances:

- each plate has two **pegs** on its back, 3 mm in diameter and 1.6 mm long, that go into **blind holes** in the shell, 3.3 mm wide and 1.9 mm deep;
- the 0.15 mm of **clearance** per side takes the normal dimensional error of a print, typically of the order of ±0.1 mm, and the glue; the extra 0.3 mm at the bottom of the holes makes sure the plate sits on its face, not on its pegs.

Two pegs are exactly enough to locate a flat part on a flat face: the plate lying on the face fixes three degrees of freedom, the first peg fixes its position in the plane, the second its rotation. With 0.3 mm of play between a peg and its hole, the plate can still shift by up to ±0.15 mm and turn by at most the play divided by the distance between the pegs: 0.3 mm over the 49 mm between the face plate's pegs is about 0.35°. A third peg would add nothing but a fit that may not close.

The glue goes on as a few small dots of CA gel or epoxy, away from the edges and the holes, so none squeezes out where it would show. A plate glued flat on a face loads the glue in **shear** when something pushes or rubs along it, the way adhesives are strongest, rather than in peel.

## 7.7 One board, four screws

All the electronics sit on one perfboard, 114.3 × 66.0 mm (45 × 26 hole spacings of 2.54 mm), 1.6 mm thick, with its corners cut at 45° to clear the cut inner corners of the shell. It needs no screws of its own:

- four **M3 × 16 countersunk self-tapping screws** come up from below, through the base and through the board's corner holes, into the screw posts moulded in the shell; they bite 6 mm into the posts;
- the posts stop on top of the board, so tightening the screws **clamps the board** between the posts and a 3 mm rim of the base that carries its outer row of holes;
- the solder side faces down into a 2 mm pocket in the base, which is why every lead must be trimmed to 1.5 mm or less.

A self-tapping screw forms its own thread in a pilot hole slightly smaller than its diameter (2.5 mm for M3 in the model), displacing the plastic rather than cutting it. Thread-forming in plastic holds well as long as it is not over-tightened and not unscrewed too often; the shell is meant to be closed once, after the test, and opened rarely. The heads sit fully on the bottom face, inside the undercut, so they are invisible and the unit stands flat.

## 7.8 Summary

| Fact | Consequence for OA-01 |
|---|---|
| Face tilted 20°, front leaning 10° | controls readable and reachable on a desk; tall back for the holder and U1 |
| Closed box: $\Delta T = P / (hA)$, $\tau \approx C_{th}/(hA)$ | ≈ 1.5 K in standby, ≈ 6 K peak while recharging at 1 A (model); the TP4056 itself runs hot |
| PLA softens ≈ 55–60 °C, PETG ≈ 75–80 °C | PLA indoors, PETG for warm places |
| Overhang step $h \tan\theta$; 45° is the limit | every part printed without supports, in the orientation stored in the files |
| Inlay printed flat = 3 layers; on a wall, one layer per 0.2 mm of height | livery on three flat plates printed together: 3 layers, ≈ 6 filament changes |
| Two pegs per plate, 0.15 mm clearance per side; glue in shear | each plate goes on in one place, within ±0.15 mm and 0.35°; a one-piece shell |
| Four screws through the board | the board is clamped, no standoffs; leads ≤ 1.5 mm |

Back to the [index](README.md).
