// =============================================================================
//  OutageAlarm v1 — 3D-printable enclosure
//
//  A wedge-shaped shell: the control face tilts toward the user and the front
//  leans back. It sits on a dark base whose undercut makes it look like it floats.
//  The shell wears a mech-style livery, like the markings on anime mechs:
//  straight lines, 45° cuts, hazard stripes, a unit code and a chamfered
//  stroke font. It is inlaid in a second filament (two-colour 3MF).
//  Units: millimeters
//
//  Three printed parts:
//    top    the control face and its chamfer; a lip underneath fits inside
//           the walls and is glued to them
//    sides  the walls and the screw posts
//    base   the floor; the shell (top + sides) is screwed to it from below
//
//  All the electronics sit on one perfboard that covers the floor. The four
//  shell screws pass through its corners, so the posts clamp it to the base.
//
//  Export the STLs from the command line:
//    openscad -o stl/enclosure_top.stl   -D "part=\"top\""   enclosure.scad
//    openscad -o stl/enclosure_sides.stl -D "part=\"sides\"" enclosure.scad
//    openscad -o stl/enclosure_base.stl  -D "part=\"base\""  enclosure.scad
//
//  Two colours: export the top and the sides with the livery recessed and the
//  inlays that fill it, then pack them into 3MFs with make_3mf.py:
//    for p in top_2color sides_2color inlay_face inlay_front inlay_back; do
//      openscad -o parts/$p.stl -D "part=\"$p\"" enclosure.scad
//    done
//    python3 make_3mf.py parts 3mf
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
//     front /  OUTAGE ALARM                   |
//          /__________________________________|
//          \_________ base (dark) ____________/   <- undercut
//
//  Top view (shell removed):
//
//                               back
//    +-----------------------------------------------------+
//    | /-------------------------------------------------\ |
//    | |o  [========= 18650 holder =========] [TP4056]  o| |==> USB-C
//    | |                                                 | |
//    | |   perfboard                                     | |
//    | |                   [relay] D1 R1 :               | |
//    | |o                                               o| |
//    | \-------------------------------------------------/ |
//    +-----------------------------------------------------+
//                               front
//    o = screw posts, molded into the shell; the screws pass through the board
//    : = pads for the wires to U1 and to the parts on the shell
//
//  On the control face: the speaker grille over the buzzer (left) and a
//  column with TEST, ARM and POWER (right).
// =============================================================================

/* [Part to render] */
part = "assembled"; // [assembled, exploded, cutaway, interior, joint, top, sides, base, top_2color, sides_2color, inlay_face, inlay_front, inlay_back]

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

/* [Joint between the top and the sides] */
// The seam runs along the crease under the face chamfer. A lip under the top
// fits inside the walls with a gap for the glue on each side.
lip_h = 4;           // lip height, below the seam
lip_t = 1.6;         // lip thickness (4 lines of 0.4 mm)
glue_gap = 0.15;     // lip to walls, each side: room for the glue (0.2-0.25 if your fit is tight)
lip_chamfer = 0.6;   // lead-in on the lip's outer bottom edge
glue_groove = [0.8, 0.6];   // groove in the top over the inner edge of the walls: width over the wall, depth
post_gap = 0.3;      // screw posts to the lip

/* [Base] */
base_t = 6;          // base thickness
undercut = 3;        // 45° undercut along the bottom edge (the "floating" shadow)
base_c = 1;          // chamfer along the top edge (forms a groove with the shell's)

/* [Shell screws: 4 x M3 x 16 countersunk, self-tapping] */
// They go up through the base and the perfboard into the posts, so they also
// clamp the board. The posts stand over the board's holes 2 in from each corner.
screw_len = 16;      // overall length, head included
post_d = 6;          // post diameter
screw_pilot = 2.5;   // pilot hole in the post
screw_depth = 10;    // pilot hole depth, from the bottom of the post
screw_clear = 3.4;   // clearance hole in the base (drill the board to 3.2)
screw_head_d = 6.2;  // countersink diameter

/* [Perfboard: all the electronics] */
// A 2.54 mm perfboard, cut along lines of holes so that its edges run through
// the centers of the outer holes, with its corners cut at 45° through the
// second hole. Hole (i, j) counts from its front-left corner: i to the right,
// j to the back. The layout is in hardware/electronics/perfboard.py.
pcb_cols = 45;           // width in hole spacings: 114.3 mm
pcb_rows = 26;           // depth in hole spacings: 66.04 mm
pcb_t = 1.6;             // board thickness: the screw posts clamp it (measure yours)
pocket_d = 2;            // pocket in the base under the board, for its solder side
pocket_rim = 3;          // rim under the board's edge: the outer row of holes rests on it
k1_hole = [22, 3];       // relay K1: hole of its front-left pin (NC); its pins span 5 x 5 spacings
d1_hole = [29, 3];       // D1: hole of its anode; the cathode is 5 holes behind it
r1_hole = [31, 2];       // R1: hole of its front lead; the other one is 8 holes behind it
board_parts_h = 9;       // tallest part on the board other than the relay, the holder and U1

/* [18650 battery holder] */
holder_x = 78;       // holder length
holder_y = 22;       // holder width
holder_z = 21;       // holder height with the cell
holder_x0 = 10.5;    // X position of the left end
holder_gap = 0.5;    // gap to the back wall

/* [TP4056 USB-C charger module] */
chg_x = 98.3;                // module center (X); the USB-C faces the back wall
chg_pcb = [17.4, 29];        // module: width (X) x length (Y)
chg_pcb_t = 1.2;             // module board thickness
chg_conn_h = 3.2;            // USB-C receptacle height
chg_lift = 1;                // module above the perfboard: 1 mm double-sided foam tape
usb_opening = [12.6, 7.2];   // large enough for the plug overmold to reach the receptacle

/* [Controls on the face (top-view positions)] */
ctrl_x = 98;                 // X of the control column
test_y = 19;                 // TEST button (PBS-11B, NC)
test_d = 12.2;               // 12 mm bushing hole
test_ring_r = 12.5;          // ring marked around TEST
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
grille_outline_r = 17.5;     // ring marked around the grille, with four ticks

/* [Marks and two-colour livery] */
show_livery = true;          // renders: show the two-colour shell, livery inlaid
livery_color = "#D7261E";    // second filament: renders, and a hint stored in the 3MF
inlay_depth = 0.6;           // depth of the recessed marks = inlay thickness (3 layers of 0.2 mm)
livery_gap = 1.8;            // livery to the face edges and to other features
mark_w = 1.2;                // rings and ticks
label_cap = 4;               // TEST / ARM / POWER: cap height
label_stroke = 0.8;
logo_text = "OUTAGE ALARM";  // wordmark on the front
logo_cap = 6;                // also the size of the "5V" on the back
logo_stroke = 1.4;
unit_code = "OA-01";         // cut out of the title band
caption = "FAIL-SAFE";       // over the rule beside the hazard stripes
band_h = 7;                  // title band at the back of the face
hazard_h = 8;                // hazard stripes at the front of the face

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

// Perfboard, centered in the shell
pitch = 2.54;
pcb_x = pcb_cols * pitch;
pcb_y = pcb_rows * pitch;
pcb_x0 = (in_x - pcb_x) / 2;                // front-left corner of the board
pcb_y0 = (in_y - pcb_y) / 2;
pcb_cut = 2;                                // corners cut at 45° through the second hole
function hole(i, j) = [pcb_x0 + i * pitch, pcb_y0 + j * pitch];
post_x = pcb_x0 + 2 * pitch;                // the posts stand over the holes 2 in from each corner
post_y = pcb_y0 + 2 * pitch;

// Relay K1 (SRD footprint, COM on the right). Its pins are off the 2.54 mm
// grid: they are centered on the 5 x 5 spacings from k1_hole, and COM sits
// between two holes.
k1_c = hole(k1_hole[0] + 2.5, k1_hole[1] + 2.5);   // center of the pin field
relay_size = [19.6, 15.4, 15.3];
relay_x0 = k1_c[0] - 10.25;                 // body: from 18.3 mm left of COM to 1.3 mm right of it
relay_x1 = relay_x0 + relay_size[0];
relay_y0 = k1_c[1] - relay_size[1] / 2;
relay_y1 = relay_y0 + relay_size[1];
relay_top = pcb_t + relay_size[2];

holder_y0 = in_y - holder_gap - holder_y;   // front face of the 18650 holder
chg_y1 = in_y - 0.5;                        // back end of the TP4056 (connector face)
chg_y0 = chg_y1 - chg_pcb[1];
chg_base = pcb_t + chg_lift;                // underside of the module
chg_z = chg_base + chg_pcb_t + chg_conn_h / 2;   // USB-C center height above the base
chg_top = chg_z + chg_conn_h / 2;
ring_r = buzzer_d / 2 + 0.3 + ring_t;       // outer radius of the buzzer ring
logo_z = (bottom_c + front_h - edge_c) / 2;
back_z = chg_z + usb_opening[1] / 2 + 5;    // "5V" on the back wall, over the USB-C
art_areas = ["face", "front", "back"];      // where the marks and livery are

// [x, y, direction to the corner in x, in y]
posts = [[post_x, post_y, -1, -1], [in_x - post_x, post_y, 1, -1],
         [post_x, in_y - post_y, -1, 1], [in_x - post_x, in_y - post_y, 1, 1]];

cut_view = (part == "cutaway");
cut_x = buzzer_x;                           // the cutaway removes everything at x > cut_x
explode = (part == "exploded") ? 40 : 0;   // sides up by this, top by twice

// -----------------------------------------------------------------------------
//  Clearance checks (the render fails if a layout change breaks one)
// -----------------------------------------------------------------------------

function top_z(y) = top0 + y * tan_s;                  // outer control face at plan y
function ceil_z(y) = top_z(y) - face_t / cos_s;        // inner control face at plan y
// A point of the board, near the front-left corner, clears the shell's
// rounded inner corner by 0.5 mm
function in_corner(p) = p[0] >= inner_r || p[1] >= inner_r || norm(p - [inner_r, inner_r]) <= inner_r - 0.5;

bz_depth = face_t + buzzer_h;                          // outer face to the buzzer's back end
bz_back_y = buzzer_y + bz_depth * sin_s;               // center of the buzzer's back end
bz_back_z = top_z(buzzer_y) - bz_depth * cos_s;
bz_low_z = bz_back_z - buzzer_d / 2 * sin_s;           // lowest point of the buzzer
bz_at_holder = bz_back_z + (holder_y0 - bz_back_y) * tan_s;
bz_front_y = buzzer_y - ring_r * cos_s + face_t * sin_s;
rocker_low_z = top_z(arm_y) - rocker_cut[1] / 2 * sin_s - (face_t + 19) * cos_s;
test_low_z = top_z(test_y) - 6 * sin_s - (face_t + 22) * cos_s;
holder_top = pcb_t + holder_z;                         // the holder stands on the board

assert(bz_at_holder >= holder_top + 2, str("Buzzer too close to the 18650 holder: ", bz_at_holder));
assert(bz_low_z >= pcb_t + board_parts_h + 2, str("Buzzer too close to the perfboard: ", bz_low_z));
assert(relay_x0 >= buzzer_x + ring_r + 1 || relay_y1 + 2 <= bz_front_y,
       "The relay must stay to the right of or in front of the buzzer");
assert(relay_top + 2 <= ceil_z(relay_y0), "The relay hits the control face");
assert(relay_y0 >= relay_top * tan_l + 2, "The relay hits the front wall");
assert(hole(d1_hole[0], 0)[0] - 1.35 >= relay_x1 + 0.3, "D1 hits the relay");
assert(rocker_low_z >= chg_top + 3, "The ARM switch hits the TP4056 module");
assert(test_low_z >= pcb_t + 3, "The TEST button hits the perfboard");
assert(hole(r1_hole[0], 0)[0] + 1.5 <= ctrl_x - 7, "A part on the perfboard is under the TEST button");
assert(holder_x0 + holder_x + 1 <= chg_x - chg_pcb[0] / 2, "The 18650 holder overlaps the TP4056 module");
assert(chg_x + chg_pcb[0] / 2 + 0.5 <= in_x - post_x - post_d / 2, "The TP4056 module hits a screw post");
assert(holder_x0 >= post_x + post_d / 2 + 0.5, "The 18650 holder hits a screw post");
assert(norm([post_x, post_y] - [inner_r, inner_r]) + screw_head_d / 2 <= corner_r - undercut - 0.3,
       "The screw heads do not fit on the bottom face");
// The perfboard: inside the walls (the front one leans in over its edge),
// its cut corners clear of the shell's rounded ones, enough board around the
// screw holes, the outer row of holes (only) on the base's rim, and the
// screws long enough to bite into the posts but not past their pilot holes
assert(pcb_x0 >= 0.5 && pcb_y0 >= 0.5 + pcb_t * tan_l, "The perfboard is too big for the shell");
assert(in_corner([pcb_x0, pcb_y0 + pcb_cut * pitch]) && in_corner([pcb_x0 + pcb_cut * pitch, pcb_y0]),
       "The perfboard's cut corners hit the shell's rounded corners");
assert((4 - pcb_cut) * pitch / sqrt(2) - screw_clear / 2 >= 1, "The screw holes are too close to the board's cut corners");
assert(pocket_rim >= pitch && pocket_rim <= 2 * pitch - 1, "The base's rim must hold the board's outer row of holes, and only it");
assert(screw_len - base_t - pcb_t >= 6 && screw_len - base_t - pcb_t <= screw_depth - 0.5,
       "The screws are too short or too long for the posts");
// The top's lip, inside the walls (ce: see the helpers)
assert(relay_top + 1 <= lean_z(0, -ce - lip_h) ||
       relay_y0 >= relay_top * tan_l + glue_gap + lip_t + 1, "The relay hits the top's lip");
assert(top_z(holder_y0) - ce - lip_h >= holder_top + 2, "The top's lip hits the 18650 holder");
assert(buzzer_x - buzzer_d / 2 >= glue_gap + lip_t + 1, "The buzzer hits the top's lip");
assert(ctrl_x + rocker_cut[0] / 2 + 1 <= in_x - glue_gap - lip_t - 1, "The ARM switch hits the top's lip");
assert(lip_t >= 1.2 && glue_gap >= 0.05, "The lip is too thin or has no room for glue");
assert(buzzer_x - ring_r >= edge_c + 3 && bz_front_y >= edge_c + 3 && bz_back_y + ring_r <= in_y - edge_c - 3,
       "The buzzer ring is too close to the walls to stay on the top");

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
front_zc = front_h - ce / (1 - tan_l * tan_s);   // where the chamfer meets the front, on its lean plane

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

// Height where the front plane through plan y0 at z = 0, leaning back by
// `lean`, meets the plane parallel to the face dz below it (vertical offset).
// Rings built with it keep the front walls exactly on their lean planes.
function lean_z(y0, dz) = (top0 + dz + y0 * tan_s) / (1 - tan_l * tan_s);

// Inner outline inset by d, on the plane parallel to the face dz below it
function in_ring(d, dz) = at_face(inner_pts(d, lean_z(d, dz)), dz);

// Inside the inner outline inset by d, between the planes parallel to the
// face dz0 and dz1 below it (dz0 < dz1)
module slab(d, dz0, dz1) {
    loft([in_ring(d, dz0), in_ring(d, dz1)]);
}

// Between the inner outlines inset by d0 (outside) and d1 (inside)
module slab_ring(d0, d1, dz0, dz1) {
    difference() {
        slab(d0, dz0, dz1);
        slab(d1, dz0 - 1, dz1 + 1);
    }
}

// Everything above the plane parallel to the face, dz below it
module above_plane(dz) {
    translate([0, 0, dz]) on_face(0, 0) translate([-100, -100, 0]) cube([400, 400, 200]);
}

// Inside the inner walls inset by d, over the whole height
module inner_prism(d) {
    loft([at_z(inner_pts(d, -5), -5), at_z(inner_pts(d, total_h + 10), total_h + 10)]);
}

// Place children on the control face: origin on the outer surface at plan
// position (x, y), local Z = outward normal, local Y = up the slope.
module on_face(x, y) {
    translate([x, y, top_z(y)]) rotate([slope, 0, 0]) children();
}

// Place children on the front face: origin on the outer surface at height z,
// local Z = outward normal, local Y = up the face.
module on_front(x, z) {
    translate([x, -wall + z * tan_l, z]) rotate([90 - lean, 0, 0]) children();
}

// Place children on the back face: origin on the outer surface at (x, z),
// local Z = outward normal; local X runs to -X, so text reads from behind.
module on_back(x, z) {
    translate([x, in_y + wall, z]) rotate([90, 0, 180]) children();
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

// Band from u0 to u1 along its bottom edge (at v0), its ends leaning 45° right
module slant(u0, u1, v0, v1) {
    k = v1 - v0;
    polygon([[u0, v0], [u1, v0], [u1 + k, v1], [u0 + k, v1]]);
}

module ring_2d(r, w) {
    difference() {
        circle(r = r + w / 2, $fn = 120);
        circle(r = r - w / 2, $fn = 120);
    }
}

// Color for renders. In the cutaway view it also removes everything at
// x > cut_x. Call it with no transform around it, so the cut happens in
// assembly coordinates. render() turns the cut into real geometry, so the
// section faces keep the part's color in preview images. mesh = true
// renders the part in the other views too, for parts the preview (OpenCSG)
// can't resolve. Never put render() inside paint(): rendering a rendered
// part again fails in OpenSCAD 2021 ("The given mesh is not closed").
module paint(c, mesh = false) {
    color(c)
        if (cut_view)
            render() difference() {
                children();
                translate([cut_x, -50, -base_t - 50]) cube([200, out_y + 100, total_h + 100]);
            }
        else if (mesh)
            render() children();
        else
            children();
}

// -----------------------------------------------------------------------------
//  Lettering: a straight-line, chamfered "mech" font
//
//  Glyphs are center lines on a grid 6 units tall and up to 4 wide. Strokes get
//  mitred joins and square ends, and each glyph is clipped to its cell, so the
//  stroke ends that run into another stroke stay hidden inside it.
// -----------------------------------------------------------------------------

// [character, width in grid units, polylines]; a polyline that ends where it
// starts is closed
mech_glyphs = [
    [" ", 3, []],
    ["-", 3, [[[0, 3], [3, 3]]]],
    ["0", 4, [[[1, 0], [4, 0], [4, 5], [3, 6], [0, 6], [0, 1], [1, 0]]]],
    ["1", 1.5, [[[0, 4.5], [1.5, 6], [1.5, 0]]]],
    ["5", 4, [[[4, 6], [0, 6], [0, 3], [3, 3], [4, 2], [4, 1], [3, 0], [0, 0]]]],
    ["A", 4, [[[0, 0], [0, 5], [1, 6], [3, 6], [4, 5], [4, 0]], [[0, 2.5], [4, 2.5]]]],
    ["D", 4, [[[0, 0], [3, 0], [4, 1], [4, 5], [3, 6], [0, 6], [0, 0]]]],
    ["E", 4, [[[4, 6], [0, 6], [0, 0], [4, 0]], [[0, 3], [3, 3]]]],
    ["F", 4, [[[4, 6], [0, 6], [0, 0]], [[0, 3], [3, 3]]]],
    ["G", 4, [[[4, 6], [1, 6], [0, 5], [0, 1], [1, 0], [4, 0], [4, 3], [2, 3]]]],
    ["I", 0, [[[0, 0], [0, 6]]]],
    ["L", 4, [[[0, 6], [0, 0], [4, 0]]]],
    ["M", 4, [[[0, 0], [0, 6], [2, 3], [4, 6], [4, 0]]]],
    ["O", 4, [[[1, 0], [3, 0], [4, 1], [4, 5], [3, 6], [1, 6], [0, 5], [0, 1], [1, 0]]]],
    ["P", 4, [[[0, 0], [0, 6], [3, 6], [4, 5], [4, 4], [3, 3], [0, 3]]]],
    ["R", 4, [[[0, 0], [0, 6], [3, 6], [4, 5], [4, 4], [3, 3], [0, 3]], [[3, 3], [4, 2], [4, 0]]]],
    ["S", 4, [[[4, 6], [1, 6], [0, 5], [0, 4], [1, 3], [3, 3], [4, 2], [4, 1], [3, 0], [0, 0]]]],
    ["T", 4, [[[0, 6], [4, 6]], [[2, 6], [2, 0]]]],
    ["U", 4, [[[0, 6], [0, 1], [1, 0], [3, 0], [4, 1], [4, 6]]]],
    ["V", 4, [[[0, 6], [0, 2], [2, 0], [4, 2], [4, 6]]]],
    ["W", 4, [[[0, 6], [0, 0], [2, 3], [4, 0], [4, 6]]]],
];

function _psum(v, n) = n <= 0 ? 0 : v[n - 1] + _psum(v, n - 1);   // sum of the first n
function mech_glyph(c) =
    let (i = search(c, mech_glyphs)[0])
    assert(is_num(i), str("The mech font has no \"", c, "\" glyph"))
    mech_glyphs[i];
function mech_advances(s, cap, w) = [for (c = s) mech_glyph(c)[1] * (cap - w) / 6 + 2 * w];
function mech_width(s, cap, w) = _psum(mech_advances(s, cap, w), len(s)) - w;

function _dir(a, b) = (b - a) / norm(b - a);

// Mitred outlines at distance h on both sides of a polyline: [left, right]
function _sides(p, h, closed) =
    let (n = len(p), m = closed ? n : n - 1,
         d = [for (i = [0 : 1 : m - 1]) _dir(p[i], p[(i + 1) % n])],
         q = [for (t = d) [-t[1], t[0]]])
    [for (s = [1, -1]) [for (j = [0 : 1 : n - 1])
        !closed && j == 0     ? p[0] + h * (s * q[0] - d[0]) :
        !closed && j == n - 1 ? p[j] + h * (s * q[m - 1] + d[m - 1]) :
        let (a = q[(j + m - 1) % m], b = q[j % m]) p[j] + s * h * (a + b) / (1 + a * b)]];

// Polyline of width w, with mitred joins and square ends
module stroke(pts, w) {
    closed = len(pts) > 2 && pts[0] == pts[len(pts) - 1];
    p = closed ? [for (i = [0 : 1 : len(pts) - 2]) pts[i]] : pts;
    n = len(p);
    sd = _sides(p, w / 2, closed);
    for (i = [0 : 1 : (closed ? n : n - 1) - 1])
        polygon([sd[0][i], sd[0][(i + 1) % n], sd[1][(i + 1) % n], sd[1][i]]);
}

// Text in the mech font; cap = cap height, outside the strokes
module mech_text(s, cap, w, halign = "left", valign = "bottom") {
    u = (cap - w) / 6;
    adv = mech_advances(s, cap, w);
    tw = _psum(adv, len(s)) - w;
    translate([halign == "right" ? -tw : halign == "center" ? -tw / 2 : 0,
               valign == "center" ? -cap / 2 : 0])
        for (i = [0 : 1 : len(s) - 1]) {
            g = mech_glyph(s[i]);
            if (len(g[2]) > 0)
                translate([_psum(adv, i), 0]) intersection() {
                    square([g[1] * u + w, cap]);
                    union() for (line = g[2]) stroke([for (p = line) p * u + [w, w] / 2], w);
                }
        }
}

// -----------------------------------------------------------------------------
//  Livery layout, in face coordinates (u, v): u = X, v = distance up the slope
//  from plan y = 0. on_face(0, 0) maps them onto the face.
// -----------------------------------------------------------------------------

function fv(y) = y / cos_s;
face_u0 = -wall + edge_c;                                   // flat part of the face
face_u1 = in_x + wall - edge_c;
face_v0 = fv(-wall + front_zc * tan_l + edge_c * (cos_s - sin_s));
face_v1 = fv(in_y + wall - edge_c * (cos_s + sin_s));
face_r = corner_r - edge_c;                                 // its corner radius, top view
grille_c = [buzzer_x, fv(buzzer_y)];
test_c = [ctrl_x, fv(test_y)];
tick_r = [grille_outline_r - 2, grille_outline_r + 3];      // reticle ticks: inner, outer radius

// Title band at the back of the face: three speed dashes, then the band with
// the unit code cut out, two panel breaks, and a 45° end short of POWER
power_u = label_x - mech_width("POWER", label_cap, label_stroke);
band_v1 = face_v1 - 3;
band_v0 = band_v1 - band_h;
dash_w = [2, 3, 4.5];
dash_u = [for (i = [0 : 2]) face_u0 + 6 + _psum(dash_w, i) + 2 * i];
band_u0 = dash_u[2] + dash_w[2] + 2;
band_u1 = power_u - 1 - band_h;                             // bottom-right corner
code_cap = band_h - 3;
code_w = 0.9;
code_u0 = band_u0 + band_h + 1;
code_u1 = code_u0 + mech_width(unit_code, code_cap, code_w);

// Hazard stripes at the front of the face, then a rule with the caption over it
haz_v0 = face_v0 + 2.8;
haz_v1 = haz_v0 + hazard_h;
haz_w = 2.2;
haz_u = [for (i = [0 : 4]) face_u0 + 7.4 + 2 * haz_w * i];
rule_u0 = haz_u[4] + haz_w + 2.4;
rule_u1 = label_x - 6;
caption_u0 = haz_u[4] + haz_w + hazard_h + 2.4;

assert(band_v0 - (grille_c[1] + tick_r[1]) >= livery_gap, "The title band is too close to the grille");
assert(band_v1 <= face_v1 - livery_gap, "The title band runs into the face chamfer");
assert(dash_u[0] + (face_v1 - face_r / cos_s - band_v0) >= face_u0 + face_r,
       "The speed dashes run into the face's corner");
assert(code_u1 + 2.4 + 1.2 + 2 <= band_u1, "The unit code does not fit in the title band");
assert(haz_v0 - face_v0 >= livery_gap && haz_u[0] >= face_u0 + face_r,
       "The hazard stripes run into the face's edge");
assert(grille_c[1] - tick_r[1] - haz_v1 >= livery_gap, "The hazard stripes are too close to the grille");
assert(caption_u0 + mech_width(caption, label_cap, label_stroke) + livery_gap <= rule_u1,
       "The caption is longer than its rule");
assert(norm([rule_u1 + 1.2, haz_v0 + 1.2] - test_c) >= test_ring_r + mark_w / 2 + livery_gap,
       "The rule runs into the TEST ring");
assert(fv(test_y) - label_cap / 2 - haz_v1 >= livery_gap, "The caption is too close to the TEST label");
assert(mech_width(logo_text, logo_cap, logo_stroke) / 2 + 12.8 <= in_x / 2 + wall - corner_r - livery_gap,
       "The wordmark is too wide for the front");
// The face prints on the bed, so its inlay is whole in each of its 3 layers.
// On the walls each layer cuts the inlay into a strip about 0.7 mm wide, so
// strokes need 1.4 mm across and the gaps between them 0.7 mm.
assert(label_stroke >= 0.8 && (label_cap - label_stroke) / 2 - label_stroke >= 0.75,
       "The face lettering is too fine to print");
assert(logo_stroke >= 1.4 && (logo_cap - logo_stroke) / 2 - logo_stroke >= 0.7,
       "The wall lettering is too fine to print");

// -----------------------------------------------------------------------------
//  Marks and livery (2D). The marks (labels, rings, wordmark, "5V") are on both
//  shells; the livery only on the two-colour one.
// -----------------------------------------------------------------------------

module face_art(livery) {
    // Reticle around the grille: a ring crossed by four ticks
    translate(grille_c) {
        ring_2d(grille_outline_r, mark_w);
        for (a = [0 : 90 : 270]) rotate(a)
            translate([tick_r[0], -mark_w / 2]) square([tick_r[1] - tick_r[0], mark_w]);
    }
    translate(test_c) ring_2d(test_ring_r, mark_w);
    for (l = [["TEST", test_y], ["ARM", arm_y], ["POWER", led_y]])
        translate([label_x, fv(l[1])]) mech_text(l[0], label_cap, label_stroke, "right", "center");

    if (livery) {
        // Title band
        for (i = [0 : 2]) slant(dash_u[i], dash_u[i] + dash_w[i], band_v0, band_v1);
        difference() {
            slant(band_u0, band_u1, band_v0, band_v1);
            translate([code_u0, band_v0 + 1.5]) mech_text(unit_code, code_cap, code_w);
            for (b = [code_u1, code_u1 + 2.4]) slant(b - 1, b + 0.2, band_v0 - 1, band_v1 + 1);
        }
        // Hazard stripes, and the caption over a rule
        for (u = haz_u) slant(u, u + haz_w, haz_v0, haz_v1);
        slant(rule_u0, rule_u1, haz_v0, haz_v0 + 1.2);
        translate([caption_u0, haz_v1 - label_cap]) mech_text(caption, label_cap, label_stroke);
    }
}

module front_art(livery) {
    mech_text(logo_text, logo_cap, logo_stroke, "center", "center");
    if (livery) {   // two slashes on each side
        hw = mech_width(logo_text, logo_cap, logo_stroke) / 2;
        for (k = [0, 1]) {
            slant(-hw - 2 - logo_cap - 1.6 - 3.2 * k, -hw - 2 - logo_cap - 3.2 * k, -logo_cap / 2, logo_cap / 2);
            slant(hw + 2 + 3.2 * k, hw + 3.6 + 3.2 * k, -logo_cap / 2, logo_cap / 2);
        }
    }
}

module back_art() {
    translate([-6, 0]) lightning_bolt(logo_cap);
    translate([-2.4, 0]) mech_text("5V", logo_cap, logo_stroke, "left", "center");
}

// Recess for one area's marks (and livery), from inlay_depth under the surface
// to 1 mm above it
module art_recess(area, livery) {
    module recess() translate([0, 0, -inlay_depth]) linear_extrude(inlay_depth + 1, convexity = 10) children();
    if (area == "face") on_face(0, 0) recess() face_art(livery);
    if (area == "front") on_front(in_x / 2, logo_z) recess() front_art(livery);
    if (area == "back") on_back(chg_x, back_z) recess() back_art();
}

// -----------------------------------------------------------------------------
//  Shell — modeled whole, then split along the crease under the face chamfer
//  into the top (face + chamfer + lip) and the sides (walls + screw posts)
// -----------------------------------------------------------------------------

split_dz = -ce;                              // the seam: plane parallel to the face, edge_c under it

module shell_outer() {
    loft([at_z(outer_pts(bottom_c), 0),
          at_z(outer_pts(0, bottom_c), bottom_c),
          at_face(outer_pts(0, front_zc), split_dz),
          at_face(face_chamfer(-wall, -wall + front_zc * tan_l, in_x + wall, in_y + wall,
                               corner_r, edge_c), 0)]);
}

module shell_cavity() {
    dz = -face_t / cos_s - ce;               // where the inner chamfer starts
    loft([at_z(inner_pts(0, -1), -1),
          in_ring(0, dz),
          at_face(face_chamfer(0, lean_z(0, dz) * tan_l, in_x, in_y, inner_r, edge_c), -face_t / cos_s)]);
}

// The whole shell, without the screw posts.
// livery = false: one colour, with the marks engraved.
// livery = true: recessed for the two-colour inlays (marks and livery).
module shell(livery = false) {
    difference() {
        shell_outer();
        difference() {
            shell_cavity();
            buzzer_ring();
        }
        shell_holes();
        for (a = art_areas) art_recess(a, livery);
    }
}

// Top: everything above the seam, the buzzer ring, and the lip. The inner
// chamfer's ridge under the seam (up to 3.1 mm from the walls, at the back)
// is left out: the lip takes its place.
module top(livery = false) {
    difference() {
        union() {
            intersection() {
                shell(livery);
                union() {
                    above_plane(split_dz);
                    inner_prism(edge_c + 2);
                }
            }
            lip();
        }
        glue_groove_cut();
    }
}

// Sides: the walls under the seam, and the screw posts
module sides(livery = false) {
    union() {
        difference() {
            shell(livery);
            above_plane(split_dz);
            inner_prism(0);
        }
        screw_posts();
    }
}

// Lip under the top: fits inside the walls with glue_gap on each side and a
// 45° lead-in on its outer bottom edge. It reaches up into the face: at the
// front the inner chamfer covers only part of its thickness, and the rest
// would hang free when the top prints face down.
module lip() {
    face_in = -face_t / cos_s;               // underside of the face
    difference() {
        loft([in_ring(glue_gap + lip_chamfer, split_dz - lip_h),
              in_ring(glue_gap, split_dz - lip_h + lip_chamfer),
              in_ring(glue_gap, face_in + 0.2)]);
        slab(glue_gap + lip_t, split_dz - lip_h - 1, face_in + 1);
    }
}

// Groove in the top's seat, over the inner edge of the walls: it takes the
// glue that the lip and the seat push out, so it doesn't reach the seam
module glue_groove_cut() {
    slab_ring(-glue_groove[0], glue_gap, split_dz - 1, split_dz + glue_groove[1]);
}

// Screw posts in the corners, notched for the lip. They stand on the perfboard
// (pcb_t above the base) and reach up to the seam.
module screw_posts() {
    difference() {
        intersection() {
            for (p = posts)
                translate([0, 0, pcb_t]) linear_extrude(back_h + 10) hull() {
                    translate([p[0], p[1]]) circle(d = post_d);
                    translate([p[0] + 6 * p[2], p[1] + 6 * p[3]]) circle(d = post_d);
                }
            inner_prism(-0.2);               // into the walls a little, so they fuse
        }
        above_plane(split_dz);
        slab_ring(-1, glue_gap + lip_t + post_gap, split_dz - lip_h - post_gap, split_dz + 1);
        for (p = posts)
            translate([p[0], p[1], pcb_t - 1]) cylinder(d = screw_pilot, h = screw_depth + 1, $fn = 24);
    }
}

// The second-filament part for one area: fills its recess flush with the surface.
// The face inlay goes with the top, the front and back inlays with the sides.
module inlay(area) {
    intersection() {
        shell_outer();
        art_recess(area, true);
    }
}

// Buzzer centering ring: 4 segments; the gaps at 0/90/180/270° leave
// room for glue and for the SFM-27 wires.
module buzzer_ring() {
    on_face(buzzer_x, buzzer_y) translate([0, 0, -face_t - ring_h])
        for (a = [45 : 90 : 315])
            rotate([0, 0, a - 20]) rotate_extrude(angle = 40)
                translate([buzzer_d / 2 + 0.3, 0]) square([ring_t, ring_h + 1]);
}

module shell_holes() {
    // Speaker grille: center hole + three rings of arc slots
    on_face(buzzer_x, buzzer_y) {
        translate([0, 0, -face_t - 1]) cylinder(d = grille_center_d, h = face_t + 2, $fn = 24);
        for (r = grille_r) {
            gap = (grille_bridge + grille_w) / r * 180 / PI;
            for (j = [0 : 3]) rotate([0, 0, 45 + 90 * j + gap / 2]) arc_slot(r, 90 - gap);
        }
    }

    // TEST button
    on_face(ctrl_x, test_y) translate([0, 0, -face_t - 1]) cylinder(d = test_d, h = face_t + 2);

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

    // USB-C opening in the back wall
    translate([chg_x, in_y - 1, chg_z]) rotate([-90, 0, 0])
        linear_extrude(wall + 2) offset(r = 2) square(usb_opening - [4, 4], center = true);
}

// -----------------------------------------------------------------------------
//  Base — the shell stands on it, and the perfboard lies on it, inside the walls
// -----------------------------------------------------------------------------

// The perfboard's outline (2D), with its corners cut at 45°
module pcb_outline() {
    c = pcb_cut * pitch;
    translate([pcb_x0, pcb_y0])
        polygon([[c, 0], [pcb_x - c, 0], [pcb_x, c], [pcb_x, pcb_y - c],
                 [pcb_x - c, pcb_y], [c, pcb_y], [0, pcb_y - c], [0, c]]);
}

module base() {
    difference() {
        loft([at_z(outer_pts(undercut), -base_t),
              at_z(outer_pts(0), -base_t + undercut),
              at_z(outer_pts(0), -base_c),
              at_z(outer_pts(base_c), 0)]);
        base_cuts();
    }
}

module base_cuts() {
    // Pocket under the perfboard, for its solder joints. The board rests on a
    // rim under its outer row of holes, on a pad around each screw (the posts
    // press on it from above) and on a rib under the 18650 holder, which takes
    // the push when the cell goes in.
    translate([0, 0, -pocket_d]) linear_extrude(pocket_d + 1) difference() {
        offset(delta = -pocket_rim) pcb_outline();
        for (p = posts) translate([p[0], p[1]]) circle(r = 4.5);
        translate([holder_x0 + 6, holder_y0 + holder_y / 2 - 1]) square([holder_x - 12, 2]);
    }

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

module board_components() {
    // Perfboard, drilled for the four shell screws
    paint("#C49A5A") linear_extrude(pcb_t) difference() {
        pcb_outline();
        for (p = posts) translate([p[0], p[1]]) circle(d = 3.2, $fn = 24);
    }

    // 18650 holder + cell, on the board
    paint([0.1, 0.1, 0.1]) translate([holder_x0, holder_y0, pcb_t]) difference() {
        cube([holder_x, holder_y, holder_z - 4]);
        translate([2, 1.5, 2]) cube([holder_x - 4, holder_y - 3, holder_z]);
    }
    paint("#1F8A8A") translate([holder_x0 + 5.5, holder_y0 + holder_y / 2, pcb_t + 2 + 9.2])
        rotate([0, 90, 0]) cylinder(d = 18.4, h = 65);
    paint("Silver") translate([holder_x0 + 4, holder_y0 + holder_y / 2, pcb_t + 2 + 9.2])
        rotate([0, 90, 0]) cylinder(d = 12, h = 1.5);

    // Relay, diode and resistor
    paint("#2F5FD0") translate([relay_x0, relay_y0, pcb_t]) cube(relay_size);
    d1 = hole(d1_hole[0], d1_hole[1] + 2.5);
    paint("Black") translate([d1[0], d1[1] - 2.6, pcb_t + 1.35]) rotate([-90, 0, 0]) cylinder(d = 2.7, h = 5.2);
    paint("Silver") translate([d1[0], d1[1] + 1.8, pcb_t + 1.35]) rotate([-90, 0, 0]) cylinder(d = 2.8, h = 0.6);
    r1 = hole(r1_hole[0], r1_hole[1] + 4);
    paint("Tan") translate([r1[0], r1[1] - 3.15, pcb_t + 1.2]) rotate([-90, 0, 0]) cylinder(d = 2.4, h = 6.3);

    // TP4056 module on foam tape, and its USB-C receptacle
    paint("#E4E4E4") translate([chg_x - chg_pcb[0] / 2 + 2, chg_y0 + 6, pcb_t]) cube([chg_pcb[0] - 4, 14, chg_lift]);
    paint("#1D4ED8") translate([chg_x - chg_pcb[0] / 2, chg_y0, chg_base])
        cube([chg_pcb[0], chg_pcb[1], chg_pcb_t]);
    paint("Silver") translate([chg_x - 4.5, chg_y1 - 7.4, chg_base + chg_pcb_t])
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

// Print orientations. Top: face down on the bed. Sides: the seam down on the
// bed (the same orientation, lowered by edge_c), so the seat comes out flat.
module top_pose() {
    translate([0, 0, top0 * cos_s]) rotate([180 - slope, 0, 0]) children();
}

module sides_pose() {
    translate([0, 0, -edge_c]) top_pose() children();
}

// A 10 mm slice through the joint at the back wall
module joint_section() {
    intersection() {
        children();
        translate([40, in_y - 9, top_z(in_y) + split_dz - 8]) cube([10, 13, 12]);
    }
}

// Labels and leaders for the joint view, just in front of the section,
// readable from -X. [text, label [y, z], halign, target [y, z]]
module joint_labels() {
    zb = top_z(in_y) + split_dz;             // the seam at the inner back wall
    left = in_y + wall + 3.3;                // label columns, either side of the section
    right = in_y - 3.5;
    labels = [
        ["TOP", [right - 2.5, top_z(right - 2.5) + 1.2], "left", [right - 2.5, top_z(right - 2.5) - 1]],
        ["SEAM", [left, zb + 0.6], "right", [in_y + wall, zb + wall * tan_s]],
        ["GROOVE", [left, zb + 3], "right", [in_y + 0.3, zb + 0.4]],
        ["SIDES", [left, zb - 5], "right", [in_y + wall / 2, zb - 4.5]],
        ["LIP", [right, zb - 3], "left", [in_y - glue_gap - lip_t / 2, zb - 2]],
        ["GLUE GAP", [right, zb - 5.5], "left", [in_y - glue_gap / 2, zb - 3.5]],
    ];
    multmatrix([[0, 0, -1, 39], [-1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]])   // (u, v) = (-y, z)
        linear_extrude(0.1) for (l = labels) {
            p = [-l[1][0], l[1][1]];
            t = [-l[3][0], l[3][1]];
            translate(p) mech_text(l[0], 0.7, 0.12, l[2], "center");
            stroke([p + [l[2] == "right" ? 0.3 : -0.3, 0], t], 0.06);
            translate(t) circle(r = 0.12, $fn = 16);
        }
}

// render(): the previews (and the PNGs) of these parts need meshes too
if (part == "top") {
    color(shell_color) render() top_pose() top(false);
} else if (part == "sides") {
    color(shell_color) render() sides_pose() sides(false);
} else if (part == "top_2color") {
    color(shell_color) render() top_pose() top(true);
} else if (part == "sides_2color") {
    color(shell_color) render() sides_pose() sides(true);
} else if (part == "inlay_face") {
    color(livery_color) render() top_pose() inlay("face");
} else if (part == "inlay_front") {
    color(livery_color) render() sides_pose() inlay("front");
} else if (part == "inlay_back") {
    color(livery_color) render() sides_pose() inlay("back");
} else if (part == "base") {
    color(base_color) translate([0, 0, base_t]) base();
} else if (part == "interior") {
    paint(base_color) base();
    board_components();
} else if (part == "joint") {
    // Seen from the left (-X): the top in white, the sides in gray-blue
    color(shell_color) render() joint_section() top(false);
    color("#A9B4BE") render() joint_section() sides(false);
    color("#33363B") joint_labels();
} else {  // assembled, exploded, cutaway
    paint(base_color) base();
    board_components();
    // mesh: the preview (OpenCSG) can't resolve the hundreds of small strokes
    // in the recesses and inlays, so the shell parts are computed as meshes.
    translate([0, 0, explode]) {
        paint(shell_color, mesh = true) sides(show_livery);
        if (show_livery) for (a = ["front", "back"]) paint(livery_color, mesh = true) inlay(a);
    }
    translate([0, 0, 2 * explode]) {
        paint(shell_color, mesh = true) top(show_livery);
        if (show_livery) paint(livery_color, mesh = true) inlay("face");
        shell_components();
    }
}
