# VNAV calculations for the Embraer E-Jet family

var phase_to = 0;
var phase_toclb = 1;
var phase_departure = 2;
var phase_climb = 3;
var phase_cruise = 4;
var phase_descent = 5;
var phase_approach = 6;

var nm_to_feet = 6076.0;
var feet_to_nm = 1.0 / nm_to_feet;
var climb_feet_per_nm = 318.0; # 3° climb
var descent_feet_per_nm = 318.0;

var find_first_enroute = func (fp) {
    var i = 0;
    var wp = nil;
    for (i = 1; i < fp.getPlanSize(); i += 1) {
        wp = fp.getWP(i);
        if (wp == nil or wp.wp_parent == nil or wp.wp_parent.tp_type != "sid") {
            return i;
        }
    }
    return i;
};

var wpUpperBound = func(wp) {
    if (wp.alt_cstr_type == "below" or wp.alt_cstr_type == "at") {
        return wp.alt_cstr;
    }
    else {
        return 60000; # way above service ceiling
    }
}

var wpLowerBound = func(wp) {
    if (wp.alt_cstr_type == "above" or wp.alt_cstr_type == "at") {
        return wp.alt_cstr;
    }
    else {
        return -1000; # low enough
    }
}

var make_profile = func () {
    var fp = flightplan();
    if (fp == nil) {
        print("No flightplan");
        return nil;
    }
    var firstEnroute = find_first_enroute(fp);
    var wp = fp.getWP(firstEnroute);

    if (wp == nil) {
        print("Flightplan not closed");
        return nil; # flightplan is not closed
    }

    var cruiseAltitude = getprop("/autopilot/route-manager/cruise/altitude-ft") or 10000;

    # first, the departure.
    var gradient = 0;
    var a = cruiseAltitude;
    var waypointStack = [];
    var i = 0;
    # find the last waypoint on the departure that has an altitude restriction
    for (i = firstEnroute - 1; i > 0; i -= 1) {
        wp = fp.getWP(i);
        if (wp == nil or wp.distance_along_route < 0.1 or wpUpperBound(wp) < cruiseAltitude) {
            break;
        }
    }
    if (wp != nil) {
        # make it a minimally higher gradient to trigger the min/max logic in
        # the first loop iteration
        gradient = wpUpperBound(wp) / wp.distance_along_route + 1;
    }
    for (; i > 0; i -= 1) {
        wp = fp.getWP(i);
        if (wp == nil or wp.distance_along_route < 0.1) {
            break;
        }
        var upperBound = wpUpperBound(wp);
        var lowerBound = wpLowerBound(wp);
        if (upperBound < lowerBound) {
            print("Impossible profile at ", wp.wp_name, ": ", upperBound, " < ", lowerBound);
            return nil;
        }
        else if (upperBound < a) {
            append(waypointStack, {"wp": wp, "alt": upperBound, "dist": wp.distance_along_route});
            gradient = upperBound / wp.distance_along_route;
        }
        else if (lowerBound > a) {
            append(waypointStack, {"wp": wp, "alt": lowerBound, "dist": wp.distance_along_route});
            gradient = lowerBound / wp.distance_along_route;
        }
    }
    
    var profile = [];
    var s = nil;
    var dist = 0.0;
    var alt = 0.0;
    var fpa = 0.0;
    while (1) {
        s = pop(waypointStack);
        if (s == nil) {
            break;
        }
        else {
            if (s["dist"] > dist) {
                var deltaDist = s["dist"] - dist;
                var deltaAlt = s["alt"] - alt;
                gradient = deltaAlt / deltaDist;
                print("delta dist: ", deltaDist, ", delta alt: ", deltaAlt * feet_to_nm);
                fpa = math.atan2(deltaAlt * feet_to_nm, deltaDist) * R2D;
            }
            else {
                gradient = 0.0;
                fpa = 0.0;
            }
            alt = s["alt"];
            dist = s["dist"];
            printf("%-10s @%5.0f %6.1f nm %+5.0f (%+3.1f°)", s["wp"].wp_name, s["alt"], s["dist"], gradient, fpa);
            append(profile,
                {
                    "name": s["wp"].wp_name,
                    "dist": dist,
                    "mode": "fpa",
                    "fpa": fpa,
                    "alt": s["alt"]
                });
        }
    }
    
    dist += 2 * (cruiseAltitude - alt) / climb_feet_per_nm; # generous
    printf("%-10s @%5.0f ----.- nm FLCH", "TOC", cruiseAltitude, dist);
    append(profile,
            {
                "name": "TOC",
                "dist": nil,
                "mode": "flch",
                "fpa": 3, # dummy
                "alt": cruiseAltitude
            });

    return profile;
};

var update_vnav = func () {
    var distanceRemaining = getprop("/autopilot/route-manager/distance-remaining-nm");
    var totalDistance = getprop("/autopilot/route-manager/total-distance");
    var routeProgress = totalDistance - distanceRemaining;
    var altitude = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    var fp = flightplan();
    if (fp != nil) {
        var i = fp.current;
        var wp = fp.getWP(i);
        if (i == 0 or (wp != nil and wp.wp_parent != nil and wp.wp_parent.tp_type == "sid")) {
            # We're on the SID

            var requiredClimb = 0;

            # default upper bound is cruise altitude.
            var upperBound = getprop("/autopilot/route-manager/cruise/altitude-ft") or 35000;
            # forbid climbing beyond cleared altitude
            upperBound =
                math.max(
                    getprop("/controls/flight/cleared-altitude"),
                    upperBound);

            if (i == 0) { i = 1; } # skip the first waypoint

            if (altitude < upperBound) {
                requiredClimb = 3;
            }

            # walk through the SID to figure out altitude restrictions
            wp = fp.getWP(i);
            while (wp != nil and wp.wp_parent != nil and wp.wp_parent.tp_type == "sid") {
                # check upper bound
                if (wp.alt_cstr_type == "below" or wp.alt_cstr_type == "at") {
                    upperBound = math.min(wp.alt_cstr, upperBound);
                }

                # check lower bound to see what kind of climb gradient we
                # need
                if (wp.alt_cstr_type == "at" or wp.alt_cstr_type == "above") {
                    var distanceTo = wp.distance_along_route - routeProgress;
                    var altDifference = wp.alt_cstr - altitude;
                    var altDifferenceNM = altDifference * feet_to_nm;
                    var angle = math.atan2(altDifferenceNM, distanceTo) * R2D;
                    if (angle > requiredClimb) {
                        requiredClimb = angle;
                    }
                }
                i += 1;
                wp = fp.getWP(i);
            }
            setprop("/fms/alt-target", upperBound);
            setprop("/fms/climb-gradient", requiredClimb);
            setprop("/fms/descent-gradient", 0);
        }
        else {

            # We're cruising or on the arrival

            # Default lower bounds is current clearance.
            var lowerBound = getprop("/controls/flight/cleared-altitude");

            # We assume that descending is not necessary unless proven
            # otherwise.
            var requiredDescent = 0;

            while (wp != nil) {
                var altType = wp.alt_cstr_type;
                var altVal = wp.alt_cstr;
                if (wp.wp_type == "runway") {
                    altType = "at";
                    altVal = 0; # TODO: find runway elevation
                }
                if (altType == "above" or altType == "at") {
                    # this is a lower limit
                    lowerBound = math.max(lowerBound, altVal);
                }
                if (altType == "below" or altType == "at") {
                    var distanceTo = wp.distance_along_route - routeProgress;
                    var altDifference = altVal - altitude;
                    var altDifferenceNM = altDifference * feet_to_nm;
                    # angle at which we need to descend in order to hit the
                    # target exactly
                    var angle = math.atan2(altDifferenceNM, distanceTo) * R2D;

                    if (angle < requiredDescent) {
                        requiredDescent = angle;
                    }
                }
                if (wp.wp_type == "runway") {
                    # if we hit the destination runway, we're still on
                    # descent/approach, and that means we should ignore the missed
                    # approach procedure that follows.
                    break;
                }
                i += 1;
                wp = fp.getWP(i);
            }

            # Now figure out whether we can still climb
            if (requiredDescent > -2.99) {
                var upperBound = math.min(
                        getprop("/controls/flight/cleared-altitude"),
                        getprop("/autopilot/route-manager/cruise/altitude-ft") or 35000);
                setprop("/fms/alt-target", upperBound);
                if (altitude < upperBound - 50) {
                    setprop("/fms/climb-gradient", 3.0);
                    setprop("/fms/descent-gradient", 0);
                }
                else {
                    setprop("/fms/climb-gradient", 0);
                    setprop("/fms/descent-gradient", 0);
                }
            }
            else {
                setprop("/fms/alt-target", lowerBound);
                setprop("/fms/climb-gradient", 0);
                setprop("/fms/descent-gradient", requiredDescent);
            }
        }
    }
    else {
    }
}

setlistener("sim/signals/fdm-initialized", func {
	var timer = maketimer(1, func () { update_vnav(); });
    timer.simulatedTime = 1;
    timer.singleShot = 0;
	timer.start();
});

setlistener("autopilot/route-manager/signals/edited", func {
    print("Flightplan edited");
    var profile = make_profile(flightplan());
    print(profile);
});
