
module luzes() {
    translate([0,0,2]) {
        $fn=5;
        for (angulo = [0:9:171]) {
            hull() {
                color("red") translate([-28 * cos(angulo), -28 * sin(angulo),0.2]) sphere(0.5);
                color("blue") translate([28 * cos(angulo), 28 * sin(angulo),0.2]) sphere(0.5);
            }
        }
    }
    
    translate([0,0,2]) {
        $fn=5;
        for (angulo = [0:10:170]) {
            hull() {
                color("red") translate([-20 * cos(angulo), -20 * sin(angulo),2.2]) sphere(0.5);
                color("blue") translate([20 * cos(angulo), 20 * sin(angulo),2.2]) sphere(0.5);
            }
        }
    }
}

module cupula() {
    translate([0,0,3]) scale([1,1,0.6]) sphere(10, $fn=10); 
}

module corpo() {
    scale([1,1,0.2]) sphere(30, $fn=13);
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