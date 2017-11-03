###############################################################################
## 
##  Nasal for dual control of the Embraer E-jets over the multiplayer network.
##
##  Copyright (C) 2009  Anders Gidenstam  (anders(at)gidenstam.org)
##  Thanks to Skyop, this is modified from the A320 Dual-Control
##  This file is licensed under the GPL license version 2 or later.
##
###############################################################################

# Renaming (almost :)
var DCT = dual_control_tools;

######################################################################
# Pilot/copilot aircraft identifiers. Used by dual_control.
var copilot_type = "Aircraft/E-jet-family/XMLs/ERJ-copilot.xml";
var copilot_view = "Copilot View";

props.globals.initNode("/sim/remote/pilot-callsign", "", "STRING");
######################################################################

# MP enabled properties.
# NOTE: These must exist very early during startup - put them
#       in the -set.xml file.
var properties = [
# basic flight controls
"controls/flight/aileron",
"controls/flight/elevator",
"controls/flight/flaps",
"controls/engines/engine[0]/throttle",
"controls/engines/engine[1]/throttle",

# electrical system
"systems/electrical/outputs/efis",

# lights
"controls/lighting/beacon",
"controls/lighting/landing-lights[0]",
"controls/lighting/landing-lights[1]",
"controls/lighting/landing-lights[2]",
"controls/lighting/nav-lights",
"controls/lighting/strobe",
"controls/lighting/logo-lights",
"controls/lighting/cockpit",
"controls/lighting/cones",
"controls/lighting/interior",
"controls/lighting/panel-norm",
"controls/lighting/beacon",

# autopilot
# "autopilot/settings/heading-mode",
# "autopilot/settings/speed-mode",
# "autopilot/settings/heading-bug-deg",
# "autopilot/settings/target-speed-kt",
# "autopilot/settings/target-speed-mach",
# "autopilot/settings/target-altitude-ft",
# "autopilot/settings/vertical-speed-fpm"
];
var pilot_TDM1_mpp       = "sim/multiplay/generic/string[1]";
var copilotPropNum = 0;

var pilot_connect_copilot = func (copilot) {
	var propertyArray = [];
	for (var i = 0; i < size(properties); i += 1) {
		append(propertyArray, props.globals.getNode(properties[i]));
	}
	return 
        [
			##################################################
			# Set up TDM transmission of slow state properties.
			DCT.TDMEncoder.new
			(propertyArray,
			props.globals.getNode(pilot_TDM1_mpp),
			),
		];
}	

var pilot_disconnect_copilot = func {
}

var copilot_connect_pilot = func (pilot) {
	# Initialize Nasal wrappers for copilot pick anaimations.
	return
        [
		##################################################
         # Set up TDM reception of slow state properties.
			DCT.TDMDecoder.new
			(pilot.getNode(pilot_TDM1_mpp),
			[
			func (v) {
				pilot.getNode(properties[0], 1).setValue(v);
				if (props.globals.getNode(properties[0]) != nil) {
					props.globals.getNode(properties[0]).setValue(v);
				} else {
					props.globals.initNode(properties[0], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[1], 1).setValue(v);
				if (props.globals.getNode(properties[1]) != nil) {
					props.globals.getNode(properties[1]).setValue(v);
				} else {
					props.globals.initNode(properties[1], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[2], 1).setValue(v);
				if (props.globals.getNode(properties[2]) != nil) {
					props.globals.getNode(properties[2]).setValue(v);
				} else {
					props.globals.initNode(properties[2], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[3], 1).setValue(v);
				if (props.globals.getNode(properties[3]) != nil) {
					props.globals.getNode(properties[3]).setValue(v);
				} else {
					props.globals.initNode(properties[3], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[4], 1).setValue(v);
				if (props.globals.getNode(properties[4]) != nil) {
					props.globals.getNode(properties[4]).setValue(v);
				} else {
					props.globals.initNode(properties[4], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[5], 1).setValue(v);
				if (props.globals.getNode(properties[5]) != nil) {
					props.globals.getNode(properties[5]).setValue(v);
				} else {
					props.globals.initNode(properties[5], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[6], 1).setValue(v);
				if (props.globals.getNode(properties[6]) != nil) {
					props.globals.getNode(properties[6]).setValue(v);
				} else {
					props.globals.initNode(properties[6], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[7], 1).setValue(v);
				if (props.globals.getNode(properties[7]) != nil) {
					props.globals.getNode(properties[7]).setValue(v);
				} else {
					props.globals.initNode(properties[7], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[8], 1).setValue(v);
				if (props.globals.getNode(properties[8]) != nil) {
					props.globals.getNode(properties[8]).setValue(v);
				} else {
					props.globals.initNode(properties[8], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[9], 1).setValue(v);
				if (props.globals.getNode(properties[9]) != nil) {
					props.globals.getNode(properties[9]).setValue(v);
				} else {
					props.globals.initNode(properties[9], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[10], 1).setValue(v);
				if (props.globals.getNode(properties[10]) != nil) {
					props.globals.getNode(properties[10]).setValue(v);
				} else {
					props.globals.initNode(properties[10], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[11], 1).setValue(v);
				if (props.globals.getNode(properties[11]) != nil) {
					props.globals.getNode(properties[11]).setValue(v);
				} else {
					props.globals.initNode(properties[11], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[12], 1).setValue(v);
				if (props.globals.getNode(properties[12]) != nil) {
					props.globals.getNode(properties[12]).setValue(v);
				} else {
					props.globals.initNode(properties[12], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[13], 1).setValue(v);
				if (props.globals.getNode(properties[13]) != nil) {
					props.globals.getNode(properties[13]).setValue(v);
				} else {
					props.globals.initNode(properties[13], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[14], 1).setValue(v);
				if (props.globals.getNode(properties[14]) != nil) {
					props.globals.getNode(properties[14]).setValue(v);
				} else {
					props.globals.initNode(properties[14], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[15], 1).setValue(v);
				if (props.globals.getNode(properties[15]) != nil) {
					props.globals.getNode(properties[15]).setValue(v);
				} else {
					props.globals.initNode(properties[15], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[16], 1).setValue(v);
				if (props.globals.getNode(properties[16]) != nil) {
					props.globals.getNode(properties[16]).setValue(v);
				} else {
					props.globals.initNode(properties[16], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[17], 1).setValue(v);
				if (props.globals.getNode(properties[17]) != nil) {
					props.globals.getNode(properties[17]).setValue(v);
				} else {
					props.globals.initNode(properties[17], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[18], 1).setValue(v);
				if (props.globals.getNode(properties[18]) != nil) {
					props.globals.getNode(properties[18]).setValue(v);
				} else {
					props.globals.initNode(properties[18], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[19], 1).setValue(v);
				if (props.globals.getNode(properties[19]) != nil) {
					props.globals.getNode(properties[19]).setValue(v);
				} else {
					props.globals.initNode(properties[19], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[20], 1).setValue(v);
				if (props.globals.getNode(properties[20]) != nil) {
					props.globals.getNode(properties[20]).setValue(v);
				} else {
					props.globals.initNode(properties[20], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[21], 1).setValue(v);
				if (props.globals.getNode(properties[21]) != nil) {
					props.globals.getNode(properties[21]).setValue(v);
				} else {
					props.globals.initNode(properties[21], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[22], 1).setValue(v);
				if (props.globals.getNode(properties[22]) != nil) {
					props.globals.getNode(properties[22]).setValue(v);
				} else {
					props.globals.initNode(properties[22], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[23], 1).setValue(v);
				if (props.globals.getNode(properties[23]) != nil) {
					props.globals.getNode(properties[23]).setValue(v);
				} else {
					props.globals.initNode(properties[23], v, "DOUBLE");
				}
			},
			func (v) {
				pilot.getNode(properties[24], 1).setValue(v);
				if (props.globals.getNode(properties[24]) != nil) {
					props.globals.getNode(properties[24]).setValue(v);
				} else {
					props.globals.initNode(properties[24], v, "DOUBLE");
				}
			}
			]),
		];
}

var copilot_disconnect_pilot = func {
}

######################################################################
# Copilot Nasal wrappers

var set_copilot_wrappers = func (pilot) {
	for (var i = 0; i < size(properties); i += 1) {
		pilot.getNode(properties[i]).alias(props.globals.getNode(properties[i]));
	}
}
