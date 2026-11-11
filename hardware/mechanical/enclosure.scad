// =============================================================================
//  OutageAlarm v1 — 3D-printable enclosure
//
//  A wedge-shaped shell: the control face tilts toward the user and the front
//  leans back. It sits on a dark base whose undercut makes it look like it floats.
//  Units: millimeters
//
//  Export the STLs from the command line:
//    openscad -o stl/enclosure_shell.stl -D "part=\"shell\"" enclosure.scad
//    openscad -o stl/enclosure_base.stl  -D "part=\"base\""  enclosure.scad
//
//  Coordinate system (assembled):
//    origin = inner front-left corner, on the top face of the base
//             (the shell's walls stand on the base at z = 0)
//    X -> right | Y -> back | Z -> up
//    Parts on the tilted control face are positioned in top view (X, Y);
//    on_face() lifts them onto the face and tilts them with it.
//
//  Side view (from the left):
//
//                                       ___---|
//                   control face ___---       |
//                          ___---             |  back: USB-C, "5V"
//                  ___---                     |
//            /---                             |
//     front /  OutageAlarm                    |
//          /__________________________________|
//          \_________ base (dark) ____________/   <- undercut
//
//  Top view (shell removed):
//
//                               back
//    +-----------------------------------------------------+
//    | o [=========== 18650 holder ===========] [TP4056]  o |==> USB-C
//    |     -------------- rib --------------               |
//    |  +-------------------------------+                  |
//    |  |   6x4 cm perfboard            |                  |
//    |  |                 [relay]       |                  |
//    | o+-------------------------------+                o |
//    +-----------------------------------------------------+
//                               front
//    o = screw posts, molded into the shell
//
//  On the control face: the speaker grille over the buzzer (left) and a
//  column with TEST, ARM and POWER (right).
// =============================================================================

/* [Part to render] */
part = "assembled"; // [assembled, exploded, cutaway, interior, shell, base]

/* [Colors (renders only)] */
shell_color = "#ECEAE4";
base_color = "#2A2C30";
accent_color = "#D7261E";    // TEST button cap

/* [Shell] */
in_x = 118;          // inner width
in_y = 70;           // inner depth
front_h = 27;        // shell height at the front face
slope = 20;          // tilt of the control face (degrees)
lean = 10;           // the front face leans back by this angle (degrees)
wall = 2.4;          // side walls (6 lines of 0.4 mm)
face_t = 2.4;        // control face thickness, square to the face
corner_r = 10;       // outer corner radius, top view
edge_c = 3;          // chamfer around the control face
bottom_c = 1;        // chamfer along the bottom edge

/* [Base] */
base_t = 6;          // base thickness
undercut = 3;        // 45° undercut along the bottom edge (the "floating" shadow)
base_c = 1;          // chamfer along the top edge (forms a groove with the shell's)

/* [Shell screws: 4 x M3 x 12 countersunk, self-tapping] */
post_xy = 5.2;       // post center, measured from both inner walls
post_d = 6;          // post diameter
screw_pilot = 2.5;   // pilot hole in the post
screw_depth = 10;    // pilot hole depth
screw_clear = 3.4;   // clearance hole in the base
screw_head_d = 6.2;  // countersink diameter

/* [18650 battery holder] */
holder_x = 78;       // holder length
holder_y = 22;       // holder width
holder_z = 21;       // holder height with the cell
holder_x0 = 8.8;     // X position of the left end
holder_gap = 0.5;    // gap to the back wall
rib_h = 6;           // rib in front of the holder
rib_t = 1.6;

/* [6x4 cm perfboard] */
pcb_x = 60;
pcb_y = 40;
pcb_x0 = 9.5;            // front-left corner of the board (X)
pcb_y0 = 4;              // front-left corner of the board (Y)
pcb_hole_margin = 2.0;   // mounting hole center to board edge (measure yours!)
standoff_h = 5;
standoff_d = 6;
standoff_hole = 1.8;     // pilot hole for M2 self-tapping screws
relay_pos = [39, 3];     // relay corner on the board: front-right area
board_parts_h = 9;       // tallest part on the board other than the relay

/* [TP4056 USB-C charger module] */
chg_x = 98.3;                // module center (X); the USB-C faces the back wall
chg_pcb = [17.4, 29];        // module: width (X) x length (Y)
chg_pcb_t = 1.2;             // module board thickness
chg_conn_h = 3.2;            // USB-C receptacle height
chg_z = 6;                   // USB-C center height above the base
usb_opening = [12.6, 7.2];   // large enough for the plug overmold to reach the receptacle

/* [Controls on the face (top-view positions)] */
ctrl_x = 98;                 // X of the control column
test_y = 19;                 // TEST button (PBS-11B, NC)
test_d = 12.2;               // 12 mm bushing hole
arm_y = 44;                  // ARM rocker switch (KCD1-101)
rocker_cut = [12.9, 19.2];   // rocker cutout: across x along the face
rocker_panel_t = 2.0;        // face thinned to this around the rocker, for the snap clips
led_y = 61;                  // POWER LED
led_d = 5.2;
label_x = 82;                // right edge of the TEST/ARM/POWER labels

/* [SFM-27 buzzer and grille] */
buzzer_x = 30;
buzzer_y = 38;
buzzer_d = 30;               // body diameter (check yours: 29–30 mm)
buzzer_h = 15;
ring_h = 4;                  // centering ring height
ring_t = 1.6;
grille_r = [5, 8.5, 12];     // radii of the slot rings
grille_w = 1.8;              // slot width
grille_bridge = 1.6;         // bridges between slots
grille_center_d = 3.4;
grille_outline_r = 17.5;     // engraved circle around the grille

/* [Engraving] */
engrave = 0.6;               // engraving depth
font_bold = "Liberation Sans:style=Bold";
font_regular = "Liberation Sans:style=Regular";
label_size = 3.4;
logo_size = 7;

/* [Hidden] */
$fn = 48;
eps = 0.01;
corner_n = 12;               // segments per rounded corner of the shell outline

out_x = in_x + 2 * wall;
out_y = in_y + 2 * wall;
inner_r = corner_r - wall;
sin_s = sin(slope);
cos_s = cos(slope);
tan_s = tan(slope);
tan_l = tan(lean);
front_y = -wall + front_h * tan_l;          // top edge of the front face (plan y)
top0 = front_h - front_y * tan_s;           // control face height at y = 0
back_h = top0 + (in_y + wall) * tan_s;      // shell height at the back face
total_h = back_h + base_t;

holder_y0 = in_y - holder_gap - holder_y;   // front face of the 18650 holder
chg_y1 = in_y - 0.5;                        // back end of the TP4056 (connector face)
chg_y0 = chg_y1 - chg_pcb[1];
chg_ledge = chg_z - chg_conn_h / 2 - chg_pcb_t;   // height where the module rests
chg_top = chg_z + chg_conn_h / 2;
guide_t = 1.2;                              // TP4056 cradle guides
cradle_x0 = chg_x - chg_pcb[0] / 2 - 0.25 - guide_t;
cradle_x1 = chg_x + chg_pcb[0] / 2 + 0.25 + guide_t;
ring_r = buzzer_d / 2 + 0.3 + ring_t;       // outer radius of the buzzer ring
logo_z = (bottom_c + front_h - edge_c) / 2;

// [x, y, direction to the corner in x, in y]
posts = [[post_xy, post_xy, -1, -1], [in_x - post_xy, post_xy, 1, -1],
         [post_xy, in_y - post_xy, -1, 1], [in_x - post_xy, in_y - post_xy, 1, 1]];

cut_view = (part == "cutaway");
cut_x = buzzer_x;                           // the cutaway removes everything at x > cut_x
explode = (part == "exploded") ? 55 : 0;

// -----------------------------------------------------------------------------
//  Clearance checks (the render fails if a layout change breaks one)
// -----------------------------------------------------------------------------

function top_z(y) = top0 + y * tan_s;                  // outer control face at plan y
function pcb_holes() = [
    for (i = [pcb_hole_margin, pcb_x - pcb_hole_margin])
        for (j = [pcb_hole_margin, pcb_y - pcb_hole_margin])
            [pcb_x0 + i, pcb_y0 + j]
];
function ceil_z(y) = top_z(y) - face_t / cos_s;        // inner control face at plan y

bz_depth = face_t + buzzer_h;                          // outer face to the buzzer's back end
bz_back_y = buzzer_y + bz_depth * sin_s;               // center of the buzzer's back end
bz_back_z = top_z(buzzer_y) - bz_depth * cos_s;
bz_low_z = bz_back_z - buzzer_d / 2 * sin_s;           // lowest point of the buzzer
bz_at_holder = bz_back_z + (holder_y0 - bz_back_y) * tan_s;
bz_front_y = buzzer_y - ring_r * cos_s + face_t * sin_s;
relay_y1 = pcb_y0 + relay_pos[1] + 15.5;
relay_top = standoff_h + 1.6 + 15.3;
rocker_low_z = top_z(arm_y) - rocker_cut[1] / 2 * sin_s - (face_t + 19) * cos_s;
test_low_z = top_z(test_y) - 6 * sin_s - (face_t + 22) * cos_s;

assert(bz_at_holder >= holder_z + 2, str("Buzzer too close to the 18650 holder: ", bz_at_holder));
assert(bz_low_z >= standoff_h + 1.6 + board_parts_h + 2, str("Buzzer too close to the perfboard: ", bz_low_z));
assert(pcb_x0 + relay_pos[0] >= buzzer_x + ring_r + 1 || relay_y1 + 2 <= bz_front_y,
       "The relay must stay to the right of or in front of the buzzer");
assert(relay_top + 2 <= ceil_z(pcb_y0 + relay_pos[1]), "The relay hits the control face");
assert(rocker_low_z >= chg_top + 3, "The ARM switch hits the TP4056 module");
assert(test_low_z >= 3, "The TEST button hits the base");
assert(holder_x0 + holder_x + 1 <= cradle_x0, "The 18650 holder overlaps the TP4056 cradle");
assert(cradle_x1 + 1 <= in_x - post_xy - post_d / 2, "The TP4056 cradle hits a screw post");
assert(holder_x0 >= post_xy + post_d / 2 + 0.5, "The 18650 holder hits a screw post");
assert(norm([pcb_x0, pcb_y0] - [post_xy, post_xy]) >= post_d / 2 + 1, "The perfboard hits a screw post");
assert(norm(pcb_holes()[0] - [post_xy, post_xy]) >= (post_d + standoff_d) / 2, "A standoff hits a screw post");
assert(pcb_y0 + relay_pos[1] >= relay_top * tan_l + 2, "The relay hits the front wall");
assert(norm([post_xy, post_xy] - [inner_r, inner_r]) + screw_head_d / 2 <= corner_r - undercut - 0.3,
       "The screw heads do not fit on the bottom face");
assert(pcb_x0 + pcb_x + 2 <= ctrl_x - 7, "The TEST button is above the perfboard");
assert(pcb_y0 + pcb_y + 1 <= holder_y0 - rib_t, "The perfboard hits the holder rib");

echo(str("Enclosure: ", out_x, " x ", out_y, " mm, ", front_h + base_t, " mm tall at the front, ",
         round(total_h * 10) / 10, " mm at the back"));

// -----------------------------------------------------------------------------
//  Helpers
// -----------------------------------------------------------------------------

// Rounded rectangle outline, counterclockwise, 4 * (n + 1) points
function rr(x0, y0, x1, y1, r, n = corner_n) =
    let (c = [[x1 - r, y1 - r], [x0 + r, y1 - r], [x0 + r, y0 + r], [x1 - r, y0 + r]])
    [for (k = [0 : 3]) for (i = [0 : n])
        let (a = 90 * k + 90 * i / n) [c[k][0] + r * cos(a), c[k][1] + r * sin(a)]];

// Outlines inset by d; the front edge moves back with the lean at height z
function outer_pts(d, z = 0) = rr(-wall + d, -wall + d + z * tan_l, in_x + wall - d, in_y + wall - d, corner_r - d);
function inner_pts(d, z = 0) = rr(d, d + z * tan_l, in_x - d, in_y - d, inner_r - d);
function at_z(pts, z) = [for (p = pts) [p[0], p[1], z]];
function at_face(pts, dz) = [for (p = pts) [p[0], p[1], top_z(p[1]) + dz]];

// Chamfer around the control face, 45° to the face, so it also prints at 45°
// with the face on the bed. Given the outline where the walls cross a plane
// c below the face (square to it), returns the outline of the chamfer on the face.
function face_chamfer(x0, y0, x1, y1, r, c) =
    rr(x0 + c, y0 + c * (cos_s - sin_s), x1 - c, y1 - c * (cos_s + sin_s), r - c);
ce = edge_c / cos_s;                         // chamfer depth, measured vertically

// Closed solid through a stack of rings (same point count, bottom to top)
module loft(rings) {
    n = len(rings[0]);
    m = len(rings);
    top = (m - 1) * n;
    sides = [for (k = [0 : m - 2]) for (i = [0 : n - 1])
                let (a = k * n + i, b = k * n + (i + 1) % n)
                each [[a, a + n, b + n], [a, b + n, b]]];
    polyhedron(
        points = [for (r = rings) each r],
        faces = concat([for (i = [1 : n - 2]) [0, i, i + 1]],
                       [for (i = [1 : n - 2]) [top, top + i + 1, top + i]],
                       sides),
        convexity = 4);
}

// Place children on the control face: origin on the outer surface at plan
// position (x, y), local Z = outward normal, local Y = up the slope.
module on_face(x, y) {
    translate([x, y, top_z(y)]) rotate([slope, 0, 0]) children();
}

// Engrave 2D children into the surface at the local origin
module engrave_2d() {
    translate([0, 0, -engrave]) linear_extrude(engrave + 1, convexity = 10) children();
}

module face_label(t, y) {
    on_face(label_x, y) engrave_2d()
        text(t, size = label_size, font = font_bold, halign = "right", valign = "center",
             spacing = 1.1);
}

module engraved_ring(r, w) {
    engrave_2d() difference() {
        circle(r = r + w / 2, $fn = 120);
        circle(r = r - w / 2, $fn = 120);
    }
}

// Arc-shaped slot through the face, from angle 0 to a, with rounded ends
module arc_slot(r, a) {
    translate([0, 0, -face_t - 1]) {
        rotate_extrude(angle = a, $fn = 120)
            translate([r - grille_w / 2, 0]) square([grille_w, face_t + 2]);
        for (t = [0, a]) rotate([0, 0, t]) translate([r, 0, 0])
            cylinder(d = grille_w, h = face_t + 2, $fn = 16);
    }
}

module lightning_bolt(h) {
    scale(h) translate([-0.5, -0.5])
        polygon([[0.45, 1], [0.15, 0.45], [0.45, 0.45], [0.3, 0],
                 [0.85, 0.6], [0.55, 0.6], [0.75, 1]]);
}

// Place children on the front face: origin on the outer surface at height z,
// local Z = outward normal, local Y = up the face.
module on_front(x, z) {
    translate([x, -wall + z * tan_l, z]) rotate([90 - lean, 0, 0]) children();
}

// Color for renders. In the cutaway view it also removes everything at
// x > cut_x. Call it with no transform around it, so the cut happens in
// assembly coordinates. render() turns the cut into real geometry, so the
// section faces keep the part's color in preview images.
module paint(c) {
    color(c)
        if (cut_view)
            render() difference() {
                children();
                translate([cut_x, -50, -base_t - 50]) cube([200, out_y + 100, total_h + 100]);
            }
        else
            children();
}

// -----------------------------------------------------------------------------
//  Shell — top, walls and screw posts in one piece
// -----------------------------------------------------------------------------

module shell() {
    difference() {
        loft([at_z(outer_pts(bottom_c), 0),
              at_z(outer_pts(0, bottom_c), bottom_c),
              at_face(outer_pts(0, front_h - ce), -ce),
              at_face(face_chamfer(-wall, -wall + (front_h - ce) * tan_l, in_x + wall, in_y + wall,
                                   corner_r, edge_c), 0)]);
        // Hollow, minus the solid features inside it
        difference() {
            loft([at_z(inner_pts(0, -1), -1),
                  at_face(inner_pts(0, front_h - face_t - ce), -face_t / cos_s - ce),
                  at_face(face_chamfer(0, (front_h - face_t - ce) * tan_l, in_x, in_y, inner_r, edge_c),
                          -face_t / cos_s)]);
            shell_inner_solids();
        }
        shell_cuts();
    }
}

module shell_inner_solids() {
    // Screw posts, filling the corners from the base up to the face
    for (p = posts)
        linear_extrude(back_h + 10) hull() {
            translate([p[0], p[1]]) circle(d = post_d);
            translate([p[0] + 6 * p[2], p[1] + 6 * p[3]]) circle(d = post_d);
        }

    // Buzzer centering ring: 4 segments; the gaps at 0/90/180/270° leave
    // room for glue and for the SFM-27 wires.
    on_face(buzzer_x, buzzer_y) translate([0, 0, -face_t - ring_h])
        for (a = [45 : 90 : 315])
            rotate([0, 0, a - 20]) rotate_extrude(angle = 40)
                translate([buzzer_d / 2 + 0.3, 0]) square([ring_t, ring_h + 1]);
}

module shell_cuts() {
    // Speaker grille: center hole + three rings of arc slots
    on_face(buzzer_x, buzzer_y) {
        translate([0, 0, -face_t - 1]) cylinder(d = grille_center_d, h = face_t + 2, $fn = 24);
        for (r = grille_r) {
            gap = (grille_bridge + grille_w) / r * 180 / PI;
            for (j = [0 : 3]) rotate([0, 0, 45 + 90 * j + gap / 2]) arc_slot(r, 90 - gap);
        }
        engraved_ring(grille_outline_r, 1);
    }

    // TEST button
    on_face(ctrl_x, test_y) {
        translate([0, 0, -face_t - 1]) cylinder(d = test_d, h = face_t + 2);
        engraved_ring(12.5, 1);
    }

    // ARM rocker switch, with the face thinned from inside around it
    on_face(ctrl_x, arm_y) {
        translate([0, 0, -face_t - 1]) linear_extrude(face_t + 2)
            offset(r = 0.5) square(rocker_cut - [1, 1], center = true);
        if (rocker_panel_t < face_t)
            translate([0, 0, -face_t - 10]) linear_extrude(10 + face_t - rocker_panel_t)
                offset(r = 1) square(rocker_cut + [2, 2], center = true);
    }

    // POWER LED (goes in from below; its flange stops against the face)
    on_face(ctrl_x, led_y) translate([0, 0, -face_t - 1]) cylinder(d = led_d, h = face_t + 2);

    // Labels
    face_label("TEST", test_y);
    face_label("ARM", arm_y);
    face_label("POWER", led_y);

    // Wordmark on the front face
    on_front(in_x / 2 + 1, logo_z) engrave_2d() {
            text("Outage", size = logo_size, font = font_bold, halign = "right", valign = "center");
            text("Alarm", size = logo_size, font = font_regular, halign = "left", valign = "center");
        }

    // USB-C opening and "5V" on the back wall
    translate([chg_x, in_y - 1, chg_z]) rotate([-90, 0, 0])
        linear_extrude(wall + 2) offset(r = 2) square(usb_opening - [4, 4], center = true);
    translate([chg_x, in_y + wall - engrave, chg_z + usb_opening[1] / 2 + 5]) rotate([90, 0, 180])
        linear_extrude(engrave + 1, convexity = 10) {
            translate([-6, 0]) lightning_bolt(5.5);
            translate([1.5, 0]) text("5V", size = 4.5, font = font_bold, halign = "center", valign = "center");
        }

    // Screw pilot holes
    for (p = posts)
        translate([p[0], p[1], -1]) cylinder(d = screw_pilot, h = screw_depth + 1, $fn = 24);
}

// -----------------------------------------------------------------------------
//  Base — the shell stands on it; the components mount on its top face
// -----------------------------------------------------------------------------

module base() {
    difference() {
        union() {
            loft([at_z(outer_pts(undercut), -base_t),
                  at_z(outer_pts(0), -base_t + undercut),
                  at_z(outer_pts(0), -base_c),
                  at_z(outer_pts(base_c), 0)]);
            translate([0, 0, -eps]) base_internals();
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
        translate([p[0], p[1], 0]) cylinder(d = standoff_d, h = standoff_h + eps);

    // TP4056 cradle: two L-shaped guides. The module rests on the ledges by
    // its edges; the middle stays clear for solder joints.
    for (s = [-1, 1]) {
        xg = (s < 0) ? cradle_x0 : chg_x + chg_pcb[0] / 2 + 0.25;
        translate([xg, chg_y0, 0]) cube([guide_t, chg_pcb[1], chg_ledge + chg_pcb_t + 1.5]);
        xl = (s < 0) ? chg_x - chg_pcb[0] / 2 - 0.25 : chg_x + chg_pcb[0] / 2 + 0.25 - 1.5;
        translate([xl, chg_y0, 0]) cube([1.5, chg_pcb[1], chg_ledge]);
    }
    // End stop: takes the push of the USB plug
    translate([chg_x - chg_pcb[0] / 2 - 0.25, chg_y0 - 0.25 - 1.6, 0])
        cube([chg_pcb[0] + 0.5, 1.6, chg_ledge + chg_pcb_t]);
}

module base_cuts() {
    // Standoff pilot holes
    for (p = pcb_holes())
        translate([p[0], p[1], -3]) cylinder(d = standoff_hole, h = standoff_h + 4, $fn = 16);

    // Shell screws: clearance hole + countersink from below
    for (p = posts) translate([p[0], p[1], 0]) {
        translate([0, 0, -base_t - 1]) cylinder(d = screw_clear, h = base_t + 2, $fn = 24);
        translate([0, 0, -base_t - eps])
            cylinder(d1 = screw_head_d, d2 = screw_clear, h = (screw_head_d - screw_clear) / 2, $fn = 24);
    }
}

// -----------------------------------------------------------------------------
//  Components (visualization only; not printed)
// -----------------------------------------------------------------------------

module base_components() {
    // 18650 holder + cell
    paint([0.1, 0.1, 0.1]) translate([holder_x0, holder_y0, 0]) difference() {
        cube([holder_x, holder_y, holder_z - 4]);
        translate([2, 1.5, 2]) cube([holder_x - 4, holder_y - 3, holder_z]);
    }
    paint("#1F8A8A") translate([holder_x0 + 5.5, holder_y0 + holder_y / 2, 2 + 9.2])
        rotate([0, 90, 0]) cylinder(d = 18.4, h = 65);
    paint("Silver") translate([holder_x0 + 4, holder_y0 + holder_y / 2, 2 + 9.2])
        rotate([0, 90, 0]) cylinder(d = 12, h = 1.5);

    // Perfboard, relay, diode and resistor
    paint("#2F6B3A") translate([pcb_x0, pcb_y0, standoff_h]) cube([pcb_x, pcb_y, 1.6]);
    paint("#2F5FD0") translate([pcb_x0 + relay_pos[0], pcb_y0 + relay_pos[1], standoff_h + 1.6])
        cube([19, 15.5, 15.3]);
    paint("Black") translate([pcb_x0 + 10, pcb_y0 + 24, standoff_h + 1.6 + 1.3])
        rotate([0, 90, 0]) cylinder(d = 2.7, h = 5.2);
    paint("Tan") translate([pcb_x0 + 22, pcb_y0 + 24, standoff_h + 1.6 + 1.2])
        rotate([0, 90, 0]) cylinder(d = 2.4, h = 6.3);

    // TP4056 module + USB-C receptacle
    paint("#1D4ED8") translate([chg_x - chg_pcb[0] / 2, chg_y0, chg_ledge])
        cube([chg_pcb[0], chg_pcb[1], chg_pcb_t]);
    paint("Silver") translate([chg_x - 4.5, chg_y1 - 7.4, chg_ledge + chg_pcb_t])
        cube([9, 7.4, chg_conn_h]);
}

module shell_components() {
    // SFM-27 buzzer, sound face glued against the face, mounting ears at its back end
    paint("#1C1C1E") on_face(buzzer_x, buzzer_y) translate([0, 0, -face_t - buzzer_h])
        cylinder(d = buzzer_d, h = buzzer_h, $fn = 64);
    paint("#1C1C1E") on_face(buzzer_x, buzzer_y) translate([0, 0, -face_t - buzzer_h])
        linear_extrude(1.5) difference() {
            hull() for (s = [-1, 1]) translate([17 * s, 0]) circle(d = 7);
            for (s = [-1, 1]) translate([17 * s, 0]) circle(d = 3);
        }

    // TEST button (PBS-11B): body below the face; nut, collar and cap above
    paint("#202022") on_face(ctrl_x, test_y) translate([0, 0, -face_t - 17]) cylinder(d = 12, h = 17);
    paint("#A8A9AD") on_face(ctrl_x, test_y) cylinder(d = 16.5, h = 2, $fn = 6);
    paint("#202022") on_face(ctrl_x, test_y) cylinder(d = 12.6, h = 3.6);
    paint(accent_color) on_face(ctrl_x, test_y) translate([0, 0, 3.6]) cylinder(d = 9.6, h = 4.5);

    // ARM rocker switch (KCD1-101): body, bezel, rocker and its "I" mark
    paint("#151515") on_face(ctrl_x, arm_y) translate([0, 0, -face_t - 13])
        linear_extrude(13) square(rocker_cut - [0.4, 0.4], center = true);
    paint("#151515") on_face(ctrl_x, arm_y)
        linear_extrude(2) offset(r = 1) square([13, 19], center = true);
    paint("#2B2B2B") on_face(ctrl_x, arm_y) translate([0, 0, 1.5]) rotate([8, 0, 0])
        linear_extrude(2.5) square([11, 16.5], center = true);
    paint("White") on_face(ctrl_x, arm_y) translate([0, 0, 1.5]) rotate([8, 0, 0])
        translate([0, 4.5, 2.6]) cube([1, 4, 0.4], center = true);

    // POWER LED: flange under the face, dome sticking out
    paint("#36D16A") on_face(ctrl_x, led_y) union() {
        translate([0, 0, -face_t - 1]) cylinder(d = 5.8, h = 1);
        translate([0, 0, -face_t]) cylinder(d = 5, h = face_t + 1.2);
        translate([0, 0, 1.2]) sphere(d = 5);
    }
}

// -----------------------------------------------------------------------------
//  Part selection
// -----------------------------------------------------------------------------

if (part == "shell") {
    // Control face down on the print bed
    color(shell_color) translate([0, 0, top0 * cos_s]) rotate([180 - slope, 0, 0]) shell();
} else if (part == "base") {
    color(base_color) translate([0, 0, base_t]) base();
} else if (part == "interior") {
    paint(base_color) base();
    base_components();
} else {  // assembled, exploded, cutaway
    paint(base_color) base();
    base_components();
    translate([0, 0, explode]) {
        paint(shell_color) shell();
        shell_components();
    }
}
