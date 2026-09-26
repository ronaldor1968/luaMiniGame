intersection() {
    union() {
        translate([0,0,0]) cylinder(h=7,d=0.5);
        translate([0,7,0]) cylinder(h=7,d=0.5);
        translate([7,7,0]) cylinder(h=7,d=0.5);
        translate([7,0,0]) cylinder(h=7,d=0.5);

        translate([0,0,0]) rotate([0,90,0]) cylinder(h=7,d=0.5);
        translate([0,7,0]) rotate([0,90,0]) cylinder(h=7,d=0.5);
        translate([0,0,7]) rotate([0,90,0]) cylinder(h=7,d=0.5);
        translate([0,7,7]) rotate([0,90,0]) cylinder(h=7,d=0.5);

        translate([0,0,0]) rotate([-90,0,0]) cylinder(h=7,d=0.5);
        translate([7,0,0]) rotate([-90,0,0]) cylinder(h=7,d=0.5);
        translate([0,0,7]) rotate([-90,0,0]) cylinder(h=7,d=0.5);
        translate([7,0,7]) rotate([-90,0,0]) cylinder(h=7,d=0.5);
    }

    sphere(1.5, $fn=100);
}

