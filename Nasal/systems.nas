# E-jet-family SYSTEMS
#########################

## LIVERY SELECT
################

var aero = substr(getprop("sim/aero"), 4);
aircraft.livery.init("Aircraft/E-jet-family/Models/Liveries/" ~ aero);

## LIGHTS
#########

# create all lights
var beacon_switch = props.globals.getNode("controls/switches/beacon", 2);
var beacon = aircraft.light.new("sim/model/lights/beacon", [0.015, 3], "controls/lighting/beacon");

var strobe_switch = props.globals.getNode("controls/switches/strobe", 2);
var strobe = aircraft.light.new("sim/model/lights/strobe", [0.025, 1.5], "controls/lighting/strobe");

## ENGINES
##########
 
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

	settimer(func {
		engineLoop(engine_no);
	}, 0);
};

# start the loop 2 seconds after the FDM initializes

setlistener("sim/signals/fdm-initialized", func {
	settimer(func {
		engineLoop(0);
		engineLoop(1);
	}, 2);
	# itaf.ap_init();
});

# startup/shutdown functions
var startup = func {
	setprop("controls/electric/battery-switch", 1);
	props.setAll("controls/electric/engine", "generator", 1);
	props.setAll("controls/engines/engine", "cutoff-switch", 1);

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

#setlistener("/controls/gear/gear-down", func { controls.click(8) } );
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

## AUTOMATIC A/T KTS/MACH SWITCHING
###################################

var prevAlt = 0;
var atKtsMachLoop = func {
    var alt = math.floor(getprop("instrumentation/altimeter/indicated-altitude-ft"));
    if (alt >= 29000 and prevAlt < 29000) {
        # switch to Mach
        var mach = getprop("instrumentation/airspeed-indicator/indicated-mach");
        setprop("it-autoflight/input/mach", mach);
        setprop("it-autoflight/input/kts-mach", 1);
    }
    if (alt < 28900 and prevAlt >= 28900) {
        # switch to IAS
        var kts = getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
        setprop("it-autoflight/input/kts", kts);
        setprop("it-autoflight/input/kts-mach", 0);
    }
    prevAlt = alt;
    settimer(atKtsMachLoop, 2);
};
setlistener("sim/signals/fdm-initialized", func {
    settimer(atKtsMachLoop, 2);
});

## AUTOPILOT
############

# Selecting a different nav source on the active side, or switching sides,
# when the autopilot is in LNAV or NAV mode, reverts the autopilot to HDG
# mode.

var checkNavDisengage = func () {
    var side = getprop("/controls/flight/nav-src/side");
    var navsrc = getprop("/instrumentation/pfd[" ~ side ~ "]/nav-src");
    var apLat = getprop("/it-autoflight/output/lat");
    var apNav2 = getprop("/it-autoflight/input/use-nav2-radio");
    var apNavsrc = navsrc;
    setprop("/controls/flight/nav-src/lat-mode", (navsrc == 0) ? 1 : 2);
    setprop("/controls/flight/nav-src/nav2", (navsrc == 2) ? 1 : 0);
    if (apLat == 1) {
        # LNAV
        apNavsrc = 0;
    }
    else if (apLat == 2) {
        # VOR/LOC
        if (apNav2) {
            apNavsrc = 2;
        }
        else {
            apNavsrc = 1;
        }
    }
    else {
        # Some other mode - no need to disengage anything
        return;
    }
    if (apNavsrc != navsrc) {
        # disengage!
        # (select HDG HOLD)
        setprop("/it-autoflight/input/lat", 3);
    }
};

# once to initialize, and then on each change of any of the inputs.
checkNavDisengage();
setlistener("/controls/flight/nav-src/side", checkNavDisengage);
setlistener("/instrumentation/pfd[0]/nav-src", checkNavDisengage);
setlistener("/instrumentation/pfd[1]/nav-src", checkNavDisengage);

var apActiveProp = props.globals.getNode('it-autoflight/output/ap1', 1);
var apControlProp1 = props.globals.getNode('it-autoflight/input/ap1', 1);
var apControlProp2 = props.globals.getNode('it-autoflight/input/ap2', 1);
var apWarningProp = props.globals.getNode('instrumentation/annun/ap-disconnect-warning', 1);

var atActiveProp = props.globals.getNode('it-autoflight/output/athr', 1);
var atControlProp = props.globals.getNode('it-autoflight/input/athr', 1);
var atWarningProp = props.globals.getNode('instrumentation/annun/at-disconnect-warning', 1);

setlistener("/controls/autoflight/disconnect", func (node) {
    if (node.getBoolValue()) {
        apWarningProp.setBoolValue(apActiveProp.getBoolValue());
        apControlProp1.setBoolValue(0);
        apControlProp2.setBoolValue(0);
    }
}, 1, 0);
setlistener("/it-autoflight/output/ap1", func (node) {
    if (node.getBoolValue()) {
        apWarningProp.setBoolValue(0);
    }
}, 1, 0);
setlistener("/controls/autoflight/at-disconnect", func (node) {
    if (node.getBoolValue()) {
        atWarningProp.setBoolValue(atActiveProp.getBoolValue());
        atControlProp.setBoolValue(0);
    }
}, 1, 0);
setlistener("/it-autoflight/output/at", func (node) {
    if (node.getBoolValue()) {
        atWarningProp.setBoolValue(0);
    }
}, 1, 0);

var resetBrakeHeat = func {
    var tempC = getprop('/environment/temperature-degc');
    var tempK = tempC + 273.2;
    printf("Brake heat reset - temperature: %i°C / %i K", tempC, tempK);
    foreach (var g; [1,2]) {
        foreach (var b; [0,1]) {
            var basepath = '/gear/gear[' ~ g ~ ']/brakes/brake[' ~ b ~ ']';
            var c = getprop(basepath ~ '/heat-capacity');
            var h = c * tempK;
            setprop(basepath ~ '/heat', h);
        }
    }
};

setlistener("sim/signals/fdm-initialized", func settimer(func {resetBrakeHeat();}, 10));

setlistener('autopilot/disconnect-conditions/control-input-filtered', func (node) {
    if (node.getDoubleValue() > 0.99999) {
        if (getprop('it-autoflight/output/ap1')) {
            setprop('controls/autoflight/disconnect', 1);
            setprop('controls/autoflight/disconnect', 0);
        }
    }
}, 1, 0);
