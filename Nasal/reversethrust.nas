togglereverser = func {
	r1 = "/fdm/jsbsim/propulsion/engine";
	r2 = "/fdm/jsbsim/propulsion/engine[1]";
	r3 = "/controls/engines/engine"; 
	r4 = "/controls/engines/engine[1]"; 
	r5 = "/sim/input/selected";
	rv1 = "/engines/engine/reverser-pos-norm"; 
	rv2 = "/engines/engine[1]/reverser-pos-norm"; 

	val = getprop(rv1);
	if (val == 0 or val == nil) {
		interpolate(rv1, 1.0, 1.4); 
		interpolate(rv2, 1.0, 1.4);  
		setprop(r1,"reverser-angle-rad","1.7");
		setprop(r2,"reverser-angle-rad","1.7");
		setprop(r3,"reverser", "true");
		setprop(r4,"reverser", "true");
		setprop(r5,"engine", "true");
		setprop(r5,"engine[1]", "true");
	} else {
		if (val == 1.0){
			interpolate(rv1, 0.0, 1.4);
			interpolate(rv2, 0.0, 1.4);   
			setprop(r1,"reverser-angle-rad",0);
			setprop(r2,"reverser-angle-rad",0);
			setprop(r3,"reverser",0);
			setprop(r4,"reverser",0);
			setprop(r5,"engine", "true");
			setprop(r5,"engine[1]", "true");
		}
	}
}
