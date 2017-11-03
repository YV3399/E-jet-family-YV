# Create initial announced variables at startup of the sim
V1 = "";
VR = "";
V2 = "";

# The actual function
var vspeeds = func {

       # Create/populate variables at each function cycle
       # Retrieve total aircraft weight and convert to kg.
	WT = getprop("/fdm/jsbsim/inertia/weight-lbs")*0.00045359237;
	flaps = getprop("/instrumentation/fmc/to-flap");

       # Calculate V-speeds with flaps 10
	if (flaps == 10) {
		V1 = (0.3*(WT-80))+125;
		VR = (0.3*(WT-80))+140;
		V2 = (0.3*(WT-80))+150;
	}

       # Calculate V-speeds with flaps 15
	elsif (flaps == 15) {
		V1 = (0.3*(WT-80))+115;
		VR = (0.3*(WT-80))+130;
		V2 = (0.3*(WT-80))+140;
	}

       # Export the calculated V-speeds to the property-tree, for further use
	setprop("/instrumentation/fmc/vspeeds/V1",V1);
	setprop("/instrumentation/fmc/vspeeds/VR",VR);
	setprop("/instrumentation/fmc/vspeeds/V2",V2);

       # Repeat the function each second
	settimer(vspeeds, 1);
}

# Only start the function when the FDM is initialized, to prevent the problem of not-yet-created properties.
_setlistener("/sim/signals/fdm-initialized", vspeeds);
