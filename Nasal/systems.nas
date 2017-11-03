# E-jet-family SYSTEMS
#########################

## LIVERY SELECT
################

aircraft.livery.init("Aircraft/E-jet-family/Models/Liveries/" ~ getprop("sim/aero"));

## LIGHTS
#########

# create all lights
var beacon_switch = props.globals.getNode("controls/switches/beacon", 2);
var beacon = aircraft.light.new("sim/model/lights/beacon", [0.015, 3], "controls/lighting/beacon");

var strobe_switch = props.globals.getNode("controls/switches/strobe", 2);
var strobe = aircraft.light.new("sim/model/lights/strobe", [0.025, 1.5], "controls/lighting/strobe");

## SOUNDS
#########

# seatbelt/no smoking sign triggers
setlistener("controls/switches/seatbelt-sign", func {
	props.getNode("sim/sound/seatbelt-sign").setBoolValue(1);

	settimer(func {
		props.getNode("sim/sound/seatbelt-sign").setBoolValue(0);
	}, 2);
});

setlistener("controls/switches/no-smoking-sign", func {
	props.getNode("sim/sound/no-smoking-sign").setBoolValue(1);

	settimer(func {
		props.getNode("sim/sound/no-smoking-sign").setBoolValue(0);
	}, 2);
});

## ENGINES
##########

# APU loop function
var apuLoop = func {
	var on_fireNode = props.getNode("engines/apu/on-fire");
	var serviceableNode = props.getNode("engines/apu/serviceable");
	var starterNode = props.getNode("controls/APU/starter");
	var master_switchNode = props.getNode("controls/APU/master-switch");
	var runningNode = props.getNode("engines/apu/running");
	if (on_fireNode.getBoolValue()) {
		serviceableNode.setBoolValue(0);
	}

	if (props.getNode("controls/APU/fire-switch").getBoolValue()) {
		on_fireNode.setBoolValue(0);
	}

	if (serviceableNode.getBoolValue() and (master_switchNode.getBoolValue() or starterNode.getBoolValue())) {
		if (starterNode.getBoolValue()) {
			var rpm = getprop("engines/apu/rpm");

			rpm += getprop("sim/time/delta-realtime-sec") * 25;
			if (rpm >= 100) {
				rpm = 100;
			}
			setprop("engines/apu/rpm", rpm);
		}

		if (master_switchNode.getBoolValue() and getprop("engines/apu/rpm") == 100) {
			runningNode.setBoolValue(1);
		}
	} else {
		runningNode.setBoolValue(0);

		var rpm = getprop("engines/apu/rpm");
		rpm -= getprop("sim/time/delta-realtime-sec") * 30;
		if (rpm < 0) {
			rpm = 0;
		}
		setprop("engines/apu/rpm", rpm);
	}

	settimer(apuLoop, 0);
 };
 
# engine loop function
var engineLoop = func(engine_no) {
	var engOn_fire = props.getNode("engines/engine[" ~ engine_no ~ "]/on-fire");
	var tree2 = "controls/engines/engine[" ~ engine_no ~ "]/";

	if (engOn_fire.getBoolValue()) {
		props.getNode("sim/failure-manager/engines/engine[" ~ engine_no ~ "]/serviceable").setBoolValue(0);
	}

	if (props.getNode(tree2 ~ "fire-bottle-discharge").getBoolValue()) {
		engOn_fire.setBoolValue(0);
	}

	if (props.getNode("sim/failure-manager/engines/engine[" ~ engine_no ~ "]/serviceable").getBoolValue()) {
		props.getNode(tree2 ~ "cutoff").setBoolValue(props.getNode(tree2 ~ "cutoff-switch").getBoolValue());
	}
	props.getNode(tree2 ~ "starter").setBoolValue(props.getNode(tree2 ~ "starter-switch").getBoolValue());

	var eng_start_sw = getprop("controls/engines/engine-start-switch");
	if (eng_start_sw == 0 or eng_start_sw == 2) {
		props.getNode(tree2 ~ "starter").setBoolValue(1);
	}

	if (!props.getNode("engines/apu/running").getBoolValue()) {
		props.getNode(tree2 ~ "starter").setBoolValue(0);
	}

	settimer(func {
		engineLoop(engine_no);
	}, 0);
};

# start the loop 2 seconds after the FDM initializes

setlistener("sim/signals/fdm-initialized", func {
	settimer(func {
		engineLoop(0);
		engineLoop(1);
		apuLoop();
	}, 2);
	itaf.ap_init();
});

# startup/shutdown functions
var startup = func {
	setprop("controls/electric/battery-switch", 1);
	props.setAll("controls/electric/engine", "generator", 1);
	props.setAll("controls/engines/engine", "cutoff-switch", 1);
	setprop("controls/APU/master-switch", 1);
	setprop("controls/APU/starter", 1);

	var listener1 = setlistener("engines/apu/running", func {
		if (props.getNode("engines/apu/running").getBoolValue()) {
			setprop("controls/engines/engine-start-switch", 2);
			settimer(func {
				props.setAll("controls/engines/engine","cutoff-switch", 0);
			}, 2);
			removelistener(listener1);
		}
	}, 0, 0);
	var listener2 = setlistener("engines/engine[0]/running", func {
		if (props.getNode("engines/engine[0]/running").getBoolValue()) {
			settimer(func {
				setprop("controls/APU/master-switch", 0);
				setprop("controls/APU/starter", 0);
				setprop("controls/electric/battery-switch", 0);
			}, 2);
			removelistener(listener2);
		}
	}, 0, 0);
};
var shutdown = func {
	props.setAll("controls/electric/engine", "generator", 0);
	props.setAll("controls/engines/engine", "cutoff-switch", 1);
};

# listener to activate these functions accordingly
setlistener("sim/model/start-idling", func(idle) {
	if (idle.getBoolValue()) {
		startup();
	} else {
		shutdown();
	}
}, 0, 0);

## GEAR
#######

# prevent retraction of the landing gear when any of the wheels are compressed
setlistener("controls/gear/gear-down", func {
	var down = props.getNode("controls/gear/gear-down").getBoolValue();
	if (!down and (getprop("gear/gear[0]/wow") or getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow"))) {
		props.getNode("controls/gear/gear-down").setBoolValue(1);
	}
});

setlistener("/controls/gear/gear-down", func { controls.click(8) } );
controls.gearDown = func(v) {
	if (v < 0) {
		if(!getprop("gear/gear[1]/wow"))setprop("/controls/gear/gear-down", 0);
	} elsif (v > 0) {
		setprop("/controls/gear/gear-down", 1);
	}
}

## INSTRUMENTS
##############

var instruments = {
	calcBugDeg: func(bug, limit) {
		var heading = getprop("orientation/heading-magnetic-deg");
		var bugDeg = 0;

		while (bug < 0) {
			bug += 360;
		}
		while (bug > 360) {
			bug -= 360;
		}
		if (bug < limit) {
			bug += 360;
		}
		if (heading < limit) {
			heading += 360;
		}
		# bug is adjusted normally
		var bugPos = heading - bug;

		if (math.abs(bugPos) < limit) {
			bugDeg = bugPos;
		} else {
			if (bugPos < 0) {
				bugPos = math.abs(bugPos + 360);
			}

			# bug is on the far right
			if (bugPos >= 180) {
				bugDeg = -limit;
			# bug is on the far left
			} elsif (bugPos < 180){
				bugDeg = limit;
			}
		}

		return bugDeg;
	},
	loop: func {
		instruments.setHSIBugsDeg();
		instruments.setSpeedBugs();
		instruments.setMPProps();
		instruments.calcEGTDegC();

		settimer(instruments.loop, 0);
	},
	# set the rotation of the HSI bugs
	setHSIBugsDeg: func {
		setprop("sim/model/ERJ/heading-bug-pfd-deg", instruments.calcBugDeg(getprop("autopilot/settings/heading-bug-deg"), 80));
		setprop("sim/model/ERJ/heading-bug-deg", instruments.calcBugDeg(getprop("autopilot/settings/heading-bug-deg"), 37));
		setprop("sim/model/ERJ/nav1-bug-deg", instruments.calcBugDeg(getprop("instrumentation/nav[0]/heading-deg"), 37));
		setprop("sim/model/ERJ/nav2-bug-deg", instruments.calcBugDeg(getprop("instrumentation/nav[1]/heading-deg"), 37));
		if (getprop("autopilot/route-manager/route/num") > 0 and getprop("autopilot/route-manager/wp[0]/bearing-deg") != nil) {
			setprop("sim/model/ERJ/wp-bearing-deg", instruments.calcBugDeg(getprop("autopilot/route-manager/wp[0]/bearing-deg"), 45));
		}
	},
	setSpeedBugs: func {
		setprop("sim/model/ERJ/ias-bug-kt-norm", getprop("autopilot/settings/target-speed-kt") - getprop("velocities/airspeed-kt"));
		setprop("sim/model/ERJ/mach-bug-kt-norm", (getprop("autopilot/settings/target-speed-mach") - getprop("velocities/mach")) * 600);
	},
	setMPProps: func {
		var getCoord = func(tree) {
			var x = getprop(tree ~ "position/global-x");
			var y = getprop(tree ~ "position/global-y");
			var z = getprop(tree ~ "position/global-z");
			return geo.Coord.new().set_xyz(x, y, z);
		};
		var calcMPDistance = func(tree) {
			var distance = nil;
			call(func distance = geo.aircraft_position().distance_to(getCoord(tree)), nil, var err = []);
			if (size(err) or distance == nil) {
				return 0;
			} else {
				return distance;
			}
		};
		var calcMPBearing = func(tree) {
			return geo.aircraft_position().course_to(getCoord(tree));
		};

		for (var i = 0; i < 6; i += 1) {
			var mp = "ai/models/multiplayer[" ~ i ~ "]/";
			if (getprop(mp ~ "valid")) {
				setprop("sim/model/ERJ/multiplayer-distance[" ~ i ~ "]", calcMPDistance(mp));
				setprop("sim/model/ERJ/multiplayer-bearing[" ~ i ~ "]", instruments.calcBugDeg(calcMPBearing(mp), 45));
			}
		}
	},
	calcEGTDegC: func() {
		foreach (var engine; props.getNode("engines").getChildren("engine")) {
			var egt_degf = engine.getValue("egt-degf");

			if (egt_degf != nil) {
				engine.setValue("egt-degc", (egt_degf - 32) * 1.8);
			}
		}
	}
};

# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func {
	settimer(instruments.loop, 2);
});

## AUTOPILOT
############

# Basic roll mode controller
var set_ap_basic_roll = func {
	var roll = getprop("instrumentation/attitude-indicator[0]/indicated-roll-deg");
	if (math.abs(roll) > 5) {
		setprop("controls/autoflight/basic-roll-mode", 0);
		setprop("controls/autoflight/basic-roll-select", roll);
	} else {
		var heading = getprop("instrumentation/heading-indicator[0]/indicated-heading-deg");
		setprop("controls/autoflight/basic-roll-mode", 1);
		setprop("controls/autoflight/basic-roll-heading-select", heading);
	}
};
# Basic pitch mode controller
var set_ap_basic_pitch = func {
	var pitch = getprop("instrumentation/attitude-indicator[0]/indicated-pitch-deg");
	setprop("controls/autoflight/pitch-select", int((pitch / 0.5) + 0.5) * 0.5);
};
setlistener("controls/autoflight/lateral-mode", func(v) {
	if (v.getValue() == 0) set_ap_basic_roll();
}, 0, 0);
setlistener("controls/autoflight/vertical-mode", func(v) {
	if (v.getValue() == 0 and getprop("controls/autoflight/lateral-mode") != 2) set_ap_basic_pitch();
}, 0, 0);
setlistener("controls/autoflight/autopilot/engage", func(v) {
	if (v.getBoolValue()) {
		var lat = getprop("controls/autoflight/lateral-mode");
		var ver = getprop("controls/autoflight/vertical-mode");
		if (lat == 0) set_ap_basic_roll();
		if (ver == 0 and lat != 2) set_ap_basic_pitch();
	}
}, 0, 0);
setlistener("controls/autoflight/flight-director/engage", func(v) {
	if (v.getBoolValue()) {
		var lat = getprop("controls/autoflight/lateral-mode");
		var ver = getprop("controls/autoflight/vertical-mode");
		if (lat == 0) set_ap_basic_roll();
		if (ver == 0 and lat != 2) set_ap_basic_pitch();
	}
}, 0, 0);
