var fast_update = func () {
    update_fms_speed();
};

var slow_update = func () {
    vnav.update();
    update_radios();
};

var modifiedFlightplan = nil;

var activeRoute = nil;
var modifiedRoute = nil;

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
    if (fp == nil) {
        print("NO FLIGHT PLAN");
        return;
    }
    # debug.dump(fp.departure_runway);
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
    kickRouteManager();
};

var updateLandingRunway = func () {
    print("UPDATE DESTINATION RUNWAY");
    var fp = flightplan();
    if (fp == nil) {
        print("NO FLIGHT PLAN");
        return;
    }
    # debug.dump(fp.destination_runway);
    if (fp.destination_runway != nil) {
        setprop("/fms/approach-conditions/runway-length-m", fp.destination_runway.length);
        setprop("/fms/approach-conditions/runway-width-m", fp.destination_runway.width);
        setprop("/fms/approach-conditions/runway-heading", fp.destination_runway.heading);
    }
    kickRouteManager();
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
        setprop("/fms/flightplan-modifications", 1);
        kickRouteManager();
    }
    return modifiedFlightplan;
};

var kickRouteManager = func {
    setprop("/autopilot/route-manager/active",
        getprop("/autopilot/route-manager/active"));
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
        setprop("/fms/flightplan-modifications", 1);
        kickRouteManager();
    }
    return flightplan();
};

var discardFlightplan = func () {
    modifiedFlightplan = nil;
    kickRouteManager();
    return flightplan();
};

var commitRoute = func () {
    if (modifiedRoute != nil) {
        modifiedFlightplan = modifiedRoute.toFlightplan();
        commitFlightplan();
        activeRoute = modifiedRoute;
        modifiedRoute = nil;
    }
    return getActiveRoute();
};

var discardRoute = func () {
    if (modifiedRoute != nil) {
        modifiedRoute = nil;
        discardFlightplan();
    }
    return getActiveRoute();
};

var updateModifiedFlightplanFromRoute = func () {
    if (modifiedRoute != nil) {
        modifiedFlightplan = modifiedRoute.toFlightplan();
        kickRouteManager();
    }
};

var getModifyableRoute = func () {
    if (modifiedRoute == nil) {
        if (activeRoute != nil) {
            modifiedRoute = activeRoute.clone();
        }
        else {
            modifiedRoute = fms.Route.new(flightplan().departure, flightplan().destination);
        }
    }
    return modifiedRoute;
};

var getActiveRoute = func () {
    if (activeRoute == nil) {
        activeRoute = fms.Route.new(flightplan().departure, flightplan().destination);
    }
    return activeRoute;
};

var getVisibleRoute = func () {
    if (modifiedRoute != nil) return modifiedRoute;
    return getActiveRoute();
};

var initDeparture = func (apt=nil) {
    var fp = flightplan();
    if (apt != nil)
        fp.departure = apt;
};

var updateOrigFuel = func (engineChanged, otherEngine) {
    if (!getprop("/engines/engine[" ~ otherEngine ~ "]/running")) {
        setprop("/fms/fuel/original",
            getprop("/consumables/fuel/total-kg") or 0);
    }
};

setlistener("/autopilot/route-manager/departure/runway", func () { updateTakeoffRunway(); }, 1, 0);
setlistener("fms/takeoff-conditions/qnh", func () { updateTakeoffPressureAlt(); }, 1, 0);
setlistener("fms/takeoff-conditions/runway-elevation", func () { updateTakeoffPressureAlt(); }, 1, 0);

setlistener("/autopilot/route-manager/destination/runway", func () { updateLandingRunway(); }, 1, 0);

setlistener("/engines/engine[0]/running", func (node) { if (node.getBoolValue()) { updateOrigFuel(0, 1); } }, 1, 0);
setlistener("/engines/engine[1]/running", func (node) { if (node.getBoolValue()) { updateOrigFuel(1, 0); } }, 1, 0);

var initialized = 0;

var tfast = maketimer(0.1, func () { fast_update(); });
tfast.simulatedTime = 1;
tfast.singleShot = 0;

var tslow = maketimer(1, func () { slow_update(); });
tslow.simulatedTime = 1;
tslow.singleShot = 0;

var unsetWaypointRef = func {
    setprop('/fms/navigation/reference-position/latitude-deg', nil);
    setprop('/fms/navigation/reference-position/longitude-deg', nil);
    setprop('/fms/navigation/reference-position/id', '');
    setprop('/fms/navigation/reference-position/valid', 0);
};

var setWaypointRef = func (lat, lon, name) {
    setprop('/fms/navigation/reference-position/latitude-deg', lat);
    setprop('/fms/navigation/reference-position/longitude-deg', lon);
    setprop('/fms/navigation/reference-position/id', name);
    setprop('/fms/navigation/reference-position/valid', 1);
};

var initWaypointRef = func (apt) {
    # debug.dump(apt, apt.lat, apt.lon);
    if (apt == nil or apt.lat == nil or apt.lon == nil) {
        unsetWaypointRef();
    }
    else {
        var parkings = apt.parking();
        var acpos = geo.aircraft_position();
        var targetpos = geo.Coord.new();
        targetpos.set_latlon(apt.lat, apt.lon);
        var dist = acpos.distance_to(targetpos);

        var bestID = apt.id;
        var bestDist = dist;
        var bestLat = apt.lat;
        var bestLon = apt.lon;
        foreach (var parking; parkings) {
            targetpos.set_latlon(parking.lat, parking.lon);
            dist = acpos.distance_to(targetpos);
            if (dist < bestDist) {
                bestID = apt.id ~ '.' ~ parking.name;
                bestDist = dist;
                bestLat = parking.lat;
                bestLon = parking.lon;
            }
        }
        setWaypointRef(bestLat, bestLon, bestID);
    }
};

var findWaypointRef = func (wpid) {
    var parts = [];
    if (string.match(wpid, '*.*'))
        parts = split('.', wpid);
    else
        parts = [wpid];
    var apts = findAirportsByICAO(parts[0]);
    if (size(apts) > 0) {
        var apt = apts[0];
        if (size(parts) > 1) {
            var parkings = apt.parking();
            foreach (var parking; parkings) {
                if (parking != nil and parking.name == parts[1]) {
                    setWaypointRef(parking.lat, parking.lon, apt.id ~ '.' ~ parking.name);
                    return 1;
                }
            }
        }
        setWaypointRef(apt.lat, apt.lon, apt.id);
        return 1;
    }
    unsetWaypointRef();
    return 0;
};

var initAirport = func {
    var apts = findAirportsWithinRange(4.0);
    var apt = nil;
    if (size(apts) > 0) {
        apt = apts[0];
    }
    initDeparture(apt);
    initWaypointRef(apt);
};

var powerOn = func {
    print("FMS POWER ON");
    initAirport();
    tfast.start();
    tslow.start();
};

var powerOff = func {
    print("FMS POWER OFF");
    tfast.stop();
    tslow.stop();
};

setlistener("sim/signals/fdm-initialized", func {
    if (initialized) return;
    initialized = 1;
    setlistener('/fms/powered', func (node) {
        if (node.getBoolValue())
            powerOn();
        else
            powerOff();
    }, 1, 0);
});
