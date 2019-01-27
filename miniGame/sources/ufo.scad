
module luzes() {
    translate([0,0,2]) {
        $fn=50;
        for (angulo = [0:45:135]) {
            hull() {
                color("red") translate([-25 * cos(angulo), -25 * sin(angulo),0]) sphere(3);
                color("blue") translate([25 * cos(angulo), 25 * sin(angulo),0]) sphere(3);
            }
        }
    }
}

module cupula() {
    translate([0,0,3]) scale([1,1,0.6]) sphere(15, $fn=200); 
}

module corpo() {
    scale([1,1,0.2]) sphere(30, $fn=200);
}

module ufo() {
    color("cyan") corpo();
    color("blue") cupula();    
    color("magenta") luzes();
}

ufo();

//corpo();
//cupula(); 
//luzes();