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
};

var engineTimer = nil;

# start the loop 2 seconds after the FDM initializes

setlistener("sim/signals/fdm-initialized", func {
	settimer(func {
        if (engineTimer == nil) {
            engineTimer = maketimer(0.5, func {
                engineLoop(0);
                engineLoop(1);
            });
            engineTimer.simulatedTime = 1;
            engineTimer.singleShot = 0;
            engineTimer.start();
        }
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


var resetTemperatures = func {
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
    setprop('engines/apu/temp-c', tempC);
};

setlistener("sim/signals/fdm-initialized", func settimer(func {resetTemperatures();}, 10));

