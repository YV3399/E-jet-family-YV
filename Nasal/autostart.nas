# Autostart functionality for the Embraer E-Jet

# Global var for tracking ongoing startup processes

var say = func (msg) {
    print(msg);
    gui.popupTip(msg);
};

var ongoing = {
    'cancel': nil,
};

var cancelOngoing = func {
    if (ongoing.cancel != nil) {
        ongoing.cancel();
        ongoing.cancel = nil;
    }
};

var when = func(prop, cond, what) {
    var listener = nil;
    var check = func (node) {
        if (cond(node)) {
            if (listener) {
                removelistener(listener);
            }
            ongoing.cancel = nil;
            what();
        }
    };
    ongoing.cancel = func {
        removelistener(listener);
    }
    listener = setlistener(prop, check, 1, 0);
};

# Cold And Dark state: everything is turned off.
var coldAndDark = func {
    cancelOngoing();
    setprop("/controls/gear/brake-parking", 1);
    setprop("/controls/electric/external-power", 0);
    setprop("/controls/electric/external-power-connected", 0);
    setprop("/fadec/engine-switch[0]", 0);
    setprop("/fadec/engine-switch[1]", 0);
    setprop("/controls/fuel/tank[0]/boost-pump[0]", 0);
    setprop("/controls/fuel/tank[1]/boost-pump[0]", 0);
    setprop("/controls/fuel/tank[1]/boost-pump[1]", 0);
    setprop("/controls/fuel/tank[2]/boost-pump[0]", 0);
    setprop("/controls/fuel/crossfeed", 0);
    setprop("/controls/apu/starter", 0);
    setprop("/controls/electric/apu-generator", 0);
    setprop("/controls/electric/battery-switch[0]", 0);
    setprop("/controls/electric/battery-switch[1]", 0);
    setprop("/controls/electric/tru-switch[0]", 0);
    setprop("/controls/electric/tru-switch[1]", 0);
    setprop("/controls/electric/tru-switch[2]", 0);
    setprop("/controls/electric/bus-tie-ac", 0);
    setprop("/controls/electric/bus-tie-dc", 0);
    setprop("/controls/electric/engine[0]/generator", 0);
    setprop("/controls/electric/engine[1]/generator", 0);
    setprop("/controls/lighting/beacon", 0);
    setprop("/controls/lighting/cabin", 0);
    setprop("/controls/lighting/cockpit", 0);
    setprop("/controls/lighting/dome", 0);
    setprop("/controls/lighting/landing-lights[0]", 0);
    setprop("/controls/lighting/landing-lights[1]", 0);
    setprop("/controls/lighting/landing-lights[2]", 0);
    setprop("/controls/lighting/logo-lights", 0);
    setprop("/controls/lighting/nav-lights-switch", 0);
    setprop("/controls/lighting/strobe", 0);
    setprop("/controls/lighting/taxi-lights[0]", 0);
    setprop("/controls/lighting/taxi-lights[1]", 0);
    setprop("/controls/pressurization/pack[0]", 0);
    setprop("/controls/pressurization/pack[1]", 0);
    setprop("/controls/pneumatic/apu-bleed", 0);
    setprop("/controls/pneumatic/xbleed", 0);
    setprop("/controls/pneumatic/engine-bleed[0]", 0);
    setprop("/controls/pneumatic/engine-bleed[1]", 0);
    setprop("/controls/switches/chocks", 1);
    setprop("/controls/switches/cones", 1);
    setprop("/controls/switches/cones", 1);
};

# Aircraft running on battery.
# This will power up all DC ESS buses and the AC STBY bus.
var batteryPowered = func {
    cancelOngoing();
    setprop("/controls/gear/brake-parking", 1);
    setprop("/controls/electric/battery-switch[0]", 1);
    setprop("/controls/electric/battery-switch[1]", 1);
    setprop("/controls/electric/external-power-connected", 0);
    setprop("/controls/electric/external-power", 0);
    setprop("/fadec/engine-switch[0]", 0);
    setprop("/fadec/engine-switch[1]", 0);
    setprop("/controls/fuel/tank[0]/boost-pump[0]", 0);
    setprop("/controls/fuel/tank[1]/boost-pump[0]", 0);
    setprop("/controls/fuel/tank[1]/boost-pump[1]", 0);
    setprop("/controls/fuel/tank[2]/boost-pump[0]", 0);
    setprop("/controls/fuel/crossfeed", 0);
    setprop("/controls/apu/starter", 0);
    setprop("/controls/electric/apu-generator", 0);
    setprop("/controls/electric/tru-switch[0]", 0);
    setprop("/controls/electric/tru-switch[1]", 0);
    setprop("/controls/electric/tru-switch[2]", 0);
    setprop("/controls/electric/bus-tie-ac", 0);
    setprop("/controls/electric/bus-tie-dc", 0);
    setprop("/controls/electric/engine[0]/generator", 0);
    setprop("/controls/electric/engine[1]/generator", 0);
    setprop("/controls/lighting/beacon", 0);
    setprop("/controls/lighting/cabin", 0);
    setprop("/controls/lighting/cockpit", 0);
    setprop("/controls/lighting/dome", 0);
    setprop("/controls/lighting/landing-lights[0]", 0);
    setprop("/controls/lighting/landing-lights[1]", 0);
    setprop("/controls/lighting/landing-lights[2]", 0);
    setprop("/controls/lighting/logo-lights", 0);
    setprop("/controls/lighting/nav-lights-switch", 0);
    setprop("/controls/lighting/strobe", 0);
    setprop("/controls/lighting/taxi-lights[0]", 0);
    setprop("/controls/lighting/taxi-lights[1]", 0);
    setprop("/controls/pressurization/pack[0]", 0);
    setprop("/controls/pressurization/pack[1]", 0);
    setprop("/controls/pneumatic/apu-bleed", 0);
    setprop("/controls/pneumatic/xbleed", 0);
    setprop("/controls/pneumatic/engine-bleed[0]", 0);
    setprop("/controls/pneumatic/engine-bleed[1]", 0);
    setprop("/controls/switches/chocks", 1);
    setprop("/controls/switches/cones", 1);
    setprop("/controls/switches/cones", 1);
};

# Aircraft powered by a GPU.
# This will power up all DC and AC buses and make bleed air from the GPU
# available.
var groundPowered = func {
    cancelOngoing();
    setprop("/controls/gear/brake-parking", 1);
    setprop("/controls/electric/external-power-connected", 1);
    setprop("/controls/electric/external-power", 1);
    setprop("/controls/electric/battery-switch[0]", 1);
    setprop("/controls/electric/battery-switch[1]", 1);
    setprop("/fadec/engine-switch[0]", 0);
    setprop("/fadec/engine-switch[1]", 0);
    setprop("/controls/fuel/tank[0]/boost-pump[0]", 0);
    setprop("/controls/fuel/tank[1]/boost-pump[0]", 0);
    setprop("/controls/fuel/tank[1]/boost-pump[1]", 0);
    setprop("/controls/fuel/tank[2]/boost-pump[0]", 0);
    setprop("/controls/fuel/crossfeed", 0);
    setprop("/controls/apu/starter", 0);
    setprop("/controls/electric/apu-generator", 0);
    setprop("/controls/electric/tru-switch[0]", 1);
    setprop("/controls/electric/tru-switch[1]", 1);
    setprop("/controls/electric/tru-switch[2]", 1);
    setprop("/controls/electric/bus-tie-ac", 0);
    setprop("/controls/electric/bus-tie-dc", 0);
    setprop("/controls/electric/engine[0]/generator", 0);
    setprop("/controls/electric/engine[1]/generator", 0);
    setprop("/controls/lighting/beacon", 0);
    setprop("/controls/lighting/cabin", 0);
    setprop("/controls/lighting/cockpit", 0);
    setprop("/controls/lighting/dome", 0);
    setprop("/controls/lighting/landing-lights[0]", 0);
    setprop("/controls/lighting/landing-lights[1]", 0);
    setprop("/controls/lighting/landing-lights[2]", 0);
    setprop("/controls/lighting/logo-lights", 0);
    setprop("/controls/lighting/nav-lights-switch", 0);
    setprop("/controls/lighting/strobe", 0);
    setprop("/controls/lighting/taxi-lights[0]", 0);
    setprop("/controls/lighting/taxi-lights[1]", 0);
    setprop("/controls/pressurization/pack[0]", 0);
    setprop("/controls/pressurization/pack[1]", 0);
    setprop("/controls/pneumatic/apu-bleed", 0);
    setprop("/controls/pneumatic/xbleed", 1);
    setprop("/controls/pneumatic/engine-bleed[0]", 0);
    setprop("/controls/pneumatic/engine-bleed[1]", 0);
    setprop("/controls/switches/chocks", 1);
    setprop("/controls/switches/cones", 1);
    setprop("/controls/switches/cones", 1);
};

# Start the APU
var startAPU = func (then = nil) {
    if (getprop("/controls/apu/starter") != 1) {
        say("Starting APU");
        setprop("/controls/electric/battery-switch[0]", 1);
        setprop("/controls/electric/battery-switch[1]", 1);
        # Technically we only need the DC pump, but we might as well turn all pumps
        # on.
        setprop("/controls/fuel/tank[0]/boost-pump[0]", 1);
        setprop("/controls/fuel/tank[1]/boost-pump[0]", 1);
        setprop("/controls/fuel/tank[1]/boost-pump[1]", 1);
        setprop("/controls/fuel/tank[2]/boost-pump[0]", 1);
        setprop("/controls/apu/starter", 2);
    }
    when(
        "/controls/apu/starter",
        func (node) { return (node.getValue() == 1); },
        func {
            say("APU started");
            setprop("/controls/pneumatic/apu-bleed", 1);
            setprop("/controls/pneumatic/xbleed", 1);
            setprop("/controls/electric/apu-generator", 1);
            setprop("/controls/electric/tru-switch[0]", 1);
            setprop("/controls/electric/tru-switch[1]", 1);
            setprop("/controls/electric/tru-switch[2]", 1);
            if (then != nil) then();
        });
};

var stopAPU = func (then = nil) {
    say("Stopping APU");
    setprop("/controls/pneumatic/apu-bleed", 0);
    setprop("/controls/electric/apu-generator", 0);
    setprop("/controls/apu/starter", 0);
    when(
        "/controls/apu/running",
        func (node) { return (node.getValue() == 0); },
        func {
            say("APU stopped");
            if (then != nil) then();
        });
};

var startEngine = func (n, then = nil) {
    say(sprintf("Starting Engine #%i", n + 1));
    setprop("/controls/pneumatic/xbleed", 1);
    setprop("/controls/fuel/tank[" ~ n ~ "]/boost-pump[0]", 1);
    setprop("/fadec/engine-switch[" ~ n ~ "]", 2);
    when(
        "/engines/engine[" ~ n ~ "]/running",
        func (node) { return (node.getValue() == 1); },
        func {
            say(sprintf("Engine #%i started", n + 1));
            setprop("/controls/electric/engine[" ~ n ~ "]/generator", 1);
            setprop("/controls/pneumatic/engine-bleed[" ~ n ~ "]", 1);
            if (then != nil) then();
        });
};

var alignAllIRUs = func () {
    for (var i = 0; i < 2; i += 1) {
        if (iru.irus[i].props.latitudeReferenceDeg.getValue() == nil or
                iru.irus[i].props.longitudeReferenceDeg.getValue() == nil) {
            setprop('/fms/navigation/position-selected', 2);
        }
        iru.irus[i].finishAlignment();
    }
};

# From cold and dark to ready to taxi
# Methods:
# 0 = APU
# 1 = GPU
var readyToTaxi = func (method) {
    printf("Ready To Taxi, Method: %i", method);
    var whenReady = func {
        setprop("/controls/electric/tru-switch[0]", 1);
        setprop("/controls/electric/tru-switch[1]", 1);
        setprop("/controls/electric/tru-switch[2]", 1);
        setprop("/controls/lighting/landing-lights[0]", 0);
        setprop("/controls/lighting/landing-lights[1]", 0);
        setprop("/controls/lighting/landing-lights[2]", 0);
        setprop("/controls/lighting/strobe", 0);
        setprop("/controls/lighting/taxi-lights[0]", 1);
        setprop("/controls/lighting/taxi-lights[1]", 1);
        setprop("/controls/switches/chocks", 0);
        setprop("/controls/switches/cones", 0);
        setprop("/controls/switches/cones", 0);
        say("Ready to taxi!");
    };
    if (method == 0) {
        cancelOngoing();
        startAPU(func {
            alignAllIRUs();
            setprop("/controls/lighting/beacon", 1);
            setprop("/controls/lighting/nav-lights-switch", 1);
            setprop("/controls/fuel/tank[0]/boost-pump[0]", 1);
            setprop("/controls/fuel/tank[1]/boost-pump[0]", 1);
            setprop("/controls/fuel/tank[1]/boost-pump[1]", 1);
            setprop("/controls/fuel/tank[2]/boost-pump[0]", 1);
            startEngine(0, func {
                startEngine(1, func {
                    stopAPU();
                    whenReady();
                })
            })
        });
    }
    else if (method == 1) {
        say("Enable GPU");
        groundPowered();
        alignAllIRUs();
        setprop("/controls/lighting/beacon", 1);
        setprop("/controls/lighting/nav-lights-switch", 1);
        setprop("/controls/fuel/tank[0]/boost-pump[0]", 1);
        setprop("/controls/fuel/tank[1]/boost-pump[0]", 1);
        setprop("/controls/fuel/tank[1]/boost-pump[1]", 1);
        setprop("/controls/fuel/tank[2]/boost-pump[0]", 1);
        startEngine(0, func {
            startEngine(1, func {
                setprop("/controls/electric/external-power", 0);
                setprop("/controls/electric/external-power-connected", 0);
                whenReady();
            })
        });
    }
};
