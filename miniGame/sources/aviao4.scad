

module turbina() {
    rotate([0,90,0]) {
        
        difference() {
            cylinder(h=30,d=30, $fn=8);
            translate([0,0,-1]) cylinder(h=32,d=25);
        }
        translate([0,0,15]) scale([1.5,1.5,4]) sphere(4);
        difference() {
            {
                translate([0,0,15]) for (angulo = [0:30:330]) {
                    rotate([0,30,angulo]) cube([1,10,16]);
                }
            }
            translate([0,0,30]) sphere(12);
        }
        
        translate([0,0,-120]) {
        
            
            difference() {
                cylinder(h=120,d1=25, d2=30, $fn=8);
                translate([0,0,-1]) cylinder(h=122,d1=20, d2=25);
            }
           
            
            
            translate([0,0,-8]) 
            for (angulo = [0:30:330]) {
                translate([8 * cos(angulo), 8 * sin(angulo),0]) rotate([0,14,angulo]) cube([1,5,26], center = true);
            }
                
            
        }
    }
}

module cabine() {
    
    
    translate([110,0,3]) {
        difference() {
            scale([2,1,1.5]) sphere(10, $fn=50);
            translate([0,0,-10]) cube([40,40,30], center=true);
        }
    }
}

module base() {
    
    
    difference() {
        union() {
            intersection() {
                   translate([80,0,0]) scale([10,3,2]) sphere(22, $fn=9);
                   translate([-50,0,0]) scale([10,3,1]) sphere(20, $fn=13);           
            }
            hull() {
                $fn=10;
                translate([-50,0,3]) scale([5,3,1]) sphere(15);
                translate([-40,0,0]) cube([120,25,5], center = true);
            }
        }
        translate([0,0,0]) rotate([0,99,0]) cylinder(h=150,d=25);
        translate([0,-30,0]) rotate([0,99,0]) cylinder(h=150,d=25);
        translate([0,30,0]) rotate([0,99,0]) cylinder(h=150,d=25);
        
    }        
}


module asa11() {
    hull() {
        translate([-40,100,0]) rotate([0,0,30]) cube([60,150,2], center=true);
        translate([-80,80,0]) rotate([0,0,10]) cube([80,80,2], center=true);
        translate([-70,145,0]) cube([60,100,2], center=true);
        translate([-40,145,5]) rotate([0,0,30]) cube([1,80,9], center=true);
    }
}
module asas1() {
    asa11();
    mirror([0,1,0]) asa11();
}

module asa21() {
    hull() {
        translate([-120,40,18]) rotate([20,0,30]) cube([30,60,2], center=true);
        translate([-130,40,18]) rotate([20,0,10]) cube([30,60,2], center=true);
        translate([-120,45,23]) rotate([20,0,30]) cube([1,60,9], center=true);
    }
}

module asas2() {
    asa21();
    mirror([0,1,0]) asa21();
}

module asa31() {
    hull() {
        translate([90,50,3]) rotate([-5,-2,10]) cube([25,40,2], center=true);
        translate([80,50,3]) rotate([-5,-2,0]) cube([25,40,2], center=true);
        translate([90,55,3]) rotate([-5,-2,10]) cube([1,40,2], center=true);
    }
}

module asas3() {
    asa31();
    mirror([0,1,0]) asa31();
}




module corpo() {
    sp = 30;
    rotate([0,0,0]) translate([0,-sp,0]) turbina();
    rotate([0,0,0]) translate([0,sp,0]) turbina();        
    rotate([0,0,0]) translate([0,0,0]) turbina();        
}

module aviao() {
    color("silver") corpo();
    color("silver") base();
    color("silver") asas1();
    color("blue") cabine();
    color("silver") asas2();
    color("silver") asas3();
}

aviao();

