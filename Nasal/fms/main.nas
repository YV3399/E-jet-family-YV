var fast_update = func () {
    update_fms_speed();
};

var slow_update = func () {
    vnav.update();
    update_radios();
};

var modifiedFlightplan = nil;

var calcPressureAlt = func (elev, qnh) {
    return 145366.45 * (1.0 - math.pow(qnh / 1013.25, 0.190284));
};

var updateTakeoffPressureAlt = func () {
    var elev = getprop("/fms/takeoff-conditions/runway-elevation") or 0.0;
    var qnh = getprop("/fms/takeoff-conditions/qnh") or 1013.0;
    var palt = calcPressureAlt(elev, qnh);
    setprop("/fms/takeoff-conditions/pressure-alt", palt);
};

var updateTakeoffRunway = func () {
    print("UPDATE DEPARTURE RUNWAY");
    var fp = flightplan();
    debug.dump(fp.departure_runway);
    if (fp.departure_runway != nil) {
        print("Set runway heading: %03.0f", fp.departure_runway.heading);
        setprop("/fms/takeoff-conditions/runway-heading", fp.departure_runway.heading);
        setprop("/fms/takeoff-conditions/runway-elevation", getprop("/autopilot/route-manager/departure/field-elevation-ft"));
        if (getprop("/environment/metar/valid")) {
            print("Valid METAR");
            setprop("/fms/takeoff-conditions/oat", math.floor(getprop("/environment/metar/temperature-degc")));
            setprop("/fms/takeoff-conditions/qnh", getprop("environment/metar/pressure-sea-level-inhg") * 33.86389);
            setprop("/fms/takeoff-conditions/wind-dir", getprop("environment/metar/base-wind-dir-deg") or 0);
            setprop("/fms/takeoff-conditions/wind-speed", getprop("environment/metar/base-wind-speed-kt") or 0);
        }
        else {
            print("No METAR");
        }
   }
};


var cloneFlightplan = func (old = nil) {
    if (old == nil) {
        old = flightplan();
    }
    var new = old.clone();
    new.current = old.current;
    new.cruiseAltitudeFt = old.cruiseAltitudeFt;
    return new;
};

var getModifyableFlightplan = func () {
    if (modifiedFlightplan == nil) {
        var fp = flightplan();
        if (fp == nil) {
            modifiedFlightplan = createFlightplan();
        }
        else {
            modifiedFlightplan = cloneFlightplan();
        }
    }
    return modifiedFlightplan;
};

# Get whichever flightplan is currently "visible" in the RTE, FPL, etc., views.
# If a flightplan is currently being edited, return this draft, otherwise, the
# active flightplan.
var getVisibleFlightplan = func () {
    if (modifiedFlightplan == nil) {
        return flightplan();
    }
    else {
        return modifiedFlightplan;
    }
};

var commitFlightplan = func () {
    if (modifiedFlightplan != nil) {
        var current = math.max(0, modifiedFlightplan.current);
        var fp0 = flightplan();
        var fp1 = modifiedFlightplan;
        var rwy0 = (fp0 == nil or fp0.departure_runway == nil or fp0.departure == nil) ? '' : fp0.departure.id ~ fp0.departure_runway.id;
        var rwy1 = (fp1 == nil or fp1.departure_runway == nil or fp1.departure == nil) ? '' : fp1.departure.id ~ fp1.departure_runway.id;
        printf("%s vs. %s", rwy0, rwy1);
        modifiedFlightplan.activate();
        fgcommand("activate-flightplan", {active: 1});
        modifiedFlightplan.current = math.max(0, current);
        modifiedFlightplan = nil;
        if (rwy0 != rwy1) {
            updateTakeoffRunway();
        }
    }
    return flightplan();
};

var discardFlightplan = func () {
    modifiedFlightplan = nil;
    return flightplan();
};

setlistener("/autopilot/route-manager/departure/runway", func () { updateTakeoffRunway(); });
setlistener("fms/takeoff-conditions/qnh", func () { updateTakeoffPressureAlt(); });
setlistener("fms/takeoff-conditions/runway-elevation", func () { updateTakeoffPressureAlt(); });

setlistener("sim/signals/fdm-initialized", func {
	var tfast = maketimer(0.1, func () { fast_update(); });
    tfast.simulatedTime = 1;
    tfast.singleShot = 0;
	tfast.start();

	var tslow = maketimer(1, func () { slow_update(); });
    tslow.simulatedTime = 1;
    tslow.singleShot = 0;
	tslow.start();
});
