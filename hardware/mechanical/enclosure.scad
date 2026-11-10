// =============================================================================
//  OutageAlarm v1 — 3D-printable enclosure (base + press-fit lid)
//  Units: millimeters
//
//  Export STL from the command line:
//    openscad -o stl/enclosure_base.stl -D "part=\"base\"" enclosure.scad
//    openscad -o stl/enclosure_lid.stl  -D "part=\"lid\""  enclosure.scad
//
//  Coordinate system:
//    origin = inner front-left corner, on the top face of the floor
//    X -> right | Y -> back | Z -> up
//    (component positions below are measured from this origin)
//
//  Top view (lid removed):
//
//                          back
//    +--------------------------------------------------+
//    | [========= 18650 holder ==========]              |
//    |  -------------- rib --------------               |
//    | +------------------------------+                 |
//    | |   6x4 cm perfboard           |  +----------+   |
//    | |     (relay on the right)     |  |  TP4056  |===| USB-C
//    | +------------------------------+  +----------+   |
//    +--------------------------------------------------+
//                 front: ARM switch, TEST button
//
//  The buzzer is mounted on the lid above the battery holder; the POWER LED
//  is on the lid, on the right side.
// =============================================================================

/* [Part to render] */
part = "assembled"; // [assembled, exploded, base, lid]

/* [Enclosure] */
in_x = 96;         // inner width
in_y = 70;         // inner depth
in_z = 38;         // inner height (floor to rim)
wall = 2.4;        // wall thickness (6 lines of 0.4 mm)
floor_t = 2.0;     // floor thickness
corner_r = 3;      // outer corner radius

/* [Lid] */
lid_t = 2.4;       // lid plate thickness
lip_h = 4;         // press-fit lip height
lip_t = 1.6;       // press-fit lip thickness
clearance = 0.25;  // lip clearance (increase if the lid is too tight)

/* [18650 battery holder] */
holder_x = 78;     // holder length
holder_y = 22;     // holder width
holder_z = 21;     // holder height with the cell
holder_x0 = 2;     // X position of the left end
holder_gap = 0.5;
rib_h = 6;         // height of the rib that keeps the holder against the back wall
rib_t = 1.6;

/* [6x4 cm perfboard] */
pcb_x = 60;
pcb_y = 40;
pcb_x0 = 2;             // front-left corner of the board (X)
pcb_y0 = 3;             // front-left corner of the board (Y)
pcb_hole_margin = 2.0;  // mounting hole center to board edge (measure yours!)
standoff_h = 5;
standoff_d = 6;
standoff_hole = 1.8;    // pilot hole for M2 self-tapping screws

/* [TP4056 USB-C charger module] */
chg_y = 19;                  // module center in Y (right wall)
chg_z = 8;                   // USB-C connector center height above the floor
chg_pcb = [29, 17.4];        // module: length (X) x width (Y)
chg_pcb_t = 1.2;             // module board thickness
chg_conn_h = 3.2;            // USB-C receptacle height
usb_opening = [12.6, 7.2];   // large enough for the plug overmold to reach the receptacle

/* [ARM switch (MTS-101)] */
switch_x = 64;     // center X (front wall)
switch_z = 24;     // center height above the floor
switch_d = 6.4;    // M6 bushing hole

/* [TEST button (NC pushbutton, PBS-11B)] */
button_x = 84;     // center X (front wall)
button_z = 24;     // center height above the floor
button_d = 12.2;   // 12 mm bushing hole

/* [5 mm LED] */
led_x = 78;
led_y = 52;
led_d = 5.2;

/* [SFM-27 buzzer] */
buzzer_x = 25;
buzzer_y = 50;
buzzer_d = 30;     // body diameter (check yours: 29–30 mm)
buzzer_h = 15;
ring_h = 4;        // centering ring height
ring_t = 1.6;

/* [Engraved text] */
label_text = "OutageAlarm";
label_size = 5;
label_x = 69;      // lid label center (between the buzzer and the right edge)
label_y = 22;
engrave = 0.6;     // engraving depth
font = "Liberation Sans:style=Bold";

/* [Hidden] */
$fn = 64;
eps = 0.01;
out_x = in_x + 2 * wall;
out_y = in_y + 2 * wall;
base_h = floor_t + in_z;
inner_r = max(corner_r - wall, 0.5);
chg_ledge_h = chg_z - chg_conn_h / 2 - chg_pcb_t;   // height where the TP4056 module rests
holder_y0 = in_y - holder_y - holder_gap;           // front face of the 18650 holder

// -----------------------------------------------------------------------------
//  Helpers
// -----------------------------------------------------------------------------

// Block with rounded corners in the XY plane, origin at corner (0,0,0)
module rounded_block(x, y, z, r) {
    hull()
        for (i = [r, x - r], j = [r, y - r])
            translate([i, j, 0]) cylinder(r = r, h = z);
}

// Centered 2D rectangle with rounded corners
module rounded_rect(x, y, r) {
    offset(r = r) square([x - 2 * r, y - 2 * r], center = true);
}

function pcb_holes() = [
    for (i = [pcb_hole_margin, pcb_x - pcb_hole_margin])
        for (j = [pcb_hole_margin, pcb_y - pcb_hole_margin])
            [pcb_x0 + i, pcb_y0 + j]
];

// Text engraved on a vertical wall.
//   side = "front" (normal -Y) | "right" (normal +X)
//   pos  = coordinate along the wall (X on the front, Y on the right)
module wall_text(t, size, pos, z, side) {
    if (side == "front")
        translate([pos, -wall + engrave, z]) rotate([90, 0, 0])
            linear_extrude(engrave + 1)
                text(t, size = size, font = font, halign = "center", valign = "center");
    else
        translate([in_x + wall - engrave, pos, z]) rotate([90, 0, 90])
            linear_extrude(engrave + 1)
                text(t, size = size, font = font, halign = "center", valign = "center");
}

// -----------------------------------------------------------------------------
//  Base
// -----------------------------------------------------------------------------

module base() {
    difference() {
        union() {
            difference() {
                translate([-wall, -wall, 0])
                    rounded_block(out_x, out_y, base_h, corner_r);
                translate([0, 0, floor_t])
                    rounded_block(in_x, in_y, in_z + 1, inner_r);
            }
            translate([0, 0, floor_t - eps]) base_internals();
        }
        base_cuts();
    }
}

module base_internals() {
    // Rib that keeps the 18650 holder against the back wall
    translate([holder_x0 + 6, holder_y0 - rib_t, 0])
        cube([holder_x - 12, rib_t, rib_h]);

    // Perfboard standoffs
    for (p = pcb_holes())
        translate([p[0], p[1], 0]) cylinder(d = standoff_d, h = standoff_h);

    // TP4056 cradle: two L-shaped guides against the right wall.
    // The module rests on the ledges by its edges; the middle stays clear for solder joints.
    x0 = in_x - chg_pcb[0];
    for (s = [-1, 1]) {
        yg = (s < 0) ? chg_y - chg_pcb[1] / 2 - clearance - 1.6
                     : chg_y + chg_pcb[1] / 2 + clearance;
        translate([x0, yg, 0])
            cube([chg_pcb[0], 1.6, chg_ledge_h + chg_pcb_t + 1.5]);
        ya = (s < 0) ? chg_y - chg_pcb[1] / 2 - clearance
                     : chg_y + chg_pcb[1] / 2 + clearance - 1.5;
        translate([x0, ya, 0])
            cube([chg_pcb[0], 1.5, chg_ledge_h]);
    }
}

module base_cuts() {
    // Standoff pilot holes (leave 1 mm of floor)
    for (p = pcb_holes())
        translate([p[0], p[1], floor_t - 1])
            cylinder(d = standoff_hole, h = standoff_h + 2);

    // USB-C opening in the right wall
    translate([in_x - 1, chg_y, floor_t + chg_z]) rotate([0, 90, 0]) rotate([0, 0, 90])
        linear_extrude(wall + 2) rounded_rect(usb_opening[0], usb_opening[1], 2);

    // ARM switch and TEST button holes in the front wall
    translate([switch_x, -wall - 1, floor_t + switch_z]) rotate([-90, 0, 0])
        cylinder(d = switch_d, h = wall + 2);
    translate([button_x, -wall - 1, floor_t + button_z]) rotate([-90, 0, 0])
        cylinder(d = button_d, h = wall + 2);

    // Notch on the left rim to pry the lid open with a fingernail
    translate([-wall - 1, in_y / 2 - 8, base_h - 1.5])
        cube([wall + 2, 16, 2]);

    // Wall labels
    wall_text("ARM", 3.5, switch_x, floor_t + switch_z - 9, "front");
    wall_text("TEST", 3.5, button_x, floor_t + button_z - 13, "front");
    wall_text("5V", 4, chg_y, floor_t + chg_z + 8, "right");
}

// -----------------------------------------------------------------------------
//  Lid — modeled in its installed position: z = 0 is the underside of the
//  plate, which rests on the wall rim.
// -----------------------------------------------------------------------------

module lid() {
    difference() {
        union() {
            // Plate
            translate([-wall, -wall, 0])
                rounded_block(out_x, out_y, lid_t, corner_r);

            // Press-fit lip (goes inside the base)
            translate([clearance, clearance, -lip_h])
                difference() {
                    rounded_block(in_x - 2 * clearance, in_y - 2 * clearance, lip_h + eps,
                                  max(inner_r - clearance, 0.3));
                    translate([lip_t, lip_t, -1])
                        rounded_block(in_x - 2 * clearance - 2 * lip_t,
                                      in_y - 2 * clearance - 2 * lip_t, lip_h + 2, 0.3);
                }

            // Buzzer centering ring: 4 segments; the gaps at 0/90/180/270°
            // let the SFM-27 mounting ears through (align them with X).
            translate([buzzer_x, buzzer_y, -ring_h])
                for (a = [45, 135, 225, 315])
                    rotate([0, 0, a - 20])
                        rotate_extrude(angle = 40)
                            translate([buzzer_d / 2 + 0.3, 0])
                                square([ring_t, ring_h + eps]);
        }

        // Sound holes above the buzzer
        translate([buzzer_x, buzzer_y, -1]) {
            cylinder(d = 3, h = lid_t + 2);
            for (a = [0 : 60 : 359])
                rotate([0, 0, a]) translate([5, 0, 0]) cylinder(d = 2.2, h = lid_t + 2);
            for (a = [15 : 30 : 359])
                rotate([0, 0, a]) translate([9, 0, 0]) cylinder(d = 2.2, h = lid_t + 2);
        }

        // LED hole (the LED goes in from below; its flange stops against the lid)
        translate([led_x, led_y, -1]) cylinder(d = led_d, h = lid_t + 2);

        // Labels engraved on top
        translate([led_x, led_y - 8, lid_t - engrave])
            linear_extrude(engrave + 1)
                text("POWER", size = 4, font = font, halign = "center", valign = "center");
        translate([label_x, label_y, lid_t - engrave])
            linear_extrude(engrave + 1)
                text(label_text, size = label_size, font = font, halign = "center", valign = "center");
    }
}

// -----------------------------------------------------------------------------
//  Components (visualization only; not printed)
// -----------------------------------------------------------------------------

module base_components() {
    translate([0, 0, floor_t]) {
        // 18650 holder + cell
        color([0.12, 0.12, 0.12]) translate([holder_x0, holder_y0, 0]) difference() {
            cube([holder_x, holder_y, holder_z - 4]);
            translate([2, 1.5, 2]) cube([holder_x - 4, holder_y - 3, holder_z]);
        }
        color("Teal") translate([holder_x0 + 5.5, holder_y0 + holder_y / 2, 2 + 9.2])
            rotate([0, 90, 0]) cylinder(d = 18.4, h = 65);
        // Perfboard
        color("DarkGreen") translate([pcb_x0, pcb_y0, standoff_h]) cube([pcb_x, pcb_y, 1.6]);
        // SRD-05VDC relay (19 x 15.5 x 15.3), on the right half of the board
        color("RoyalBlue") translate([pcb_x0 + 38, pcb_y0 + 12, standoff_h + 1.6])
            cube([19, 15.5, 15.3]);
        // Diode and resistor
        color("Black") translate([pcb_x0 + 10, pcb_y0 + 10, standoff_h + 1.6 + 1.3])
            rotate([0, 90, 0]) cylinder(d = 2.7, h = 5.2);
        color("Tan") translate([pcb_x0 + 22, pcb_y0 + 10, standoff_h + 1.6 + 1.2])
            rotate([0, 90, 0]) cylinder(d = 2.4, h = 6.3);
        // TP4056 module + USB-C receptacle
        color("MediumBlue") translate([in_x - chg_pcb[0], chg_y - chg_pcb[1] / 2, chg_ledge_h])
            cube([chg_pcb[0], chg_pcb[1], chg_pcb_t]);
        color("Silver") translate([in_x - 7.5, chg_y - 4.5, chg_ledge_h + chg_pcb_t])
            cube([7.5, 9, chg_conn_h]);
        // MTS-101 switch (inner body + outer lever)
        color("Silver") translate([switch_x - 3.9, 0, switch_z - 6.6]) cube([7.8, 9.5, 13.2]);
        color("Silver") translate([switch_x, 0, switch_z]) rotate([90, 0, 0])
            cylinder(d = 6, h = wall + 8);
        color("Silver") translate([switch_x, -wall - 8, switch_z]) rotate([90, 0, 0])
            rotate([0, 20, 0]) cylinder(d1 = 3, d2 = 2.2, h = 10);
        // TEST button (inner body + outer bezel and red cap)
        color("DimGray") translate([button_x, 0, button_z]) rotate([-90, 0, 0])
            cylinder(d = 12, h = 16);
        color("DimGray") translate([button_x, -wall, button_z]) rotate([90, 0, 0])
            cylinder(d = 18.4, h = 3);
        color("Red") translate([button_x, -wall - 3, button_z]) rotate([90, 0, 0])
            cylinder(d = 9, h = 4);
    }
}

module lid_components() {
    // Buzzer hanging under the lid
    color([0.15, 0.15, 0.15]) translate([buzzer_x, buzzer_y, -buzzer_h])
        cylinder(d = buzzer_d, h = buzzer_h);
    // LED (flange under the lid, dome sticking out)
    color("Lime") translate([led_x, led_y, 0]) {
        translate([0, 0, -1]) cylinder(d = 5.8, h = 1);
        cylinder(d = 5, h = lid_t + 2.5);
        translate([0, 0, lid_t + 2.5]) sphere(d = 5);
    }
}

// -----------------------------------------------------------------------------
//  Part selection
// -----------------------------------------------------------------------------

if (part == "base") {
    base();
} else if (part == "lid") {
    // Upside down: top face on the print bed
    translate([0, in_y, lid_t]) rotate([180, 0, 0]) lid();
} else if (part == "exploded") {
    color("Gainsboro") base();
    base_components();
    translate([0, 0, base_h + 40]) {
        color("WhiteSmoke") lid();
        lid_components();
    }
} else {  // assembled
    color("Gainsboro") base();
    base_components();
    translate([0, 0, base_h]) {
        color("WhiteSmoke") lid();
        lid_components();
    }
}
