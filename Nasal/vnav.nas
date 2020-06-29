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

var findFirstEnroute = func (fp) {
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

var findFirstArrival = func (fp) {
    var i = 0;
    var wp = nil;
    for (i = 1; i < fp.getPlanSize(); i += 1) {
        wp = fp.getWP(i);
        if (wp == nil or (wp.wp_parent != nil and (wp.wp_parent.tp_type == "star" or wp.wp_parent.tp_type == "IAP"))) {
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
    var totalDistance = getprop("/autopilot/route-manager/total-distance");
    var firstEnroute = findFirstEnroute(fp);
    var wp = fp.getWP(firstEnroute);

    if (wp == nil) {
        print("Flightplan not closed");
        return nil; # flightplan is not closed
    }

    var cruiseAltitude = getprop("/autopilot/route-manager/cruise/altitude-ft") or 10000;

    var profile = [];

    ############################# departure ############################# 
    var gradient = 0;
    var a = cruiseAltitude;
    var a0 = fp.departure.elevation * M2FT;
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
        gradient = (wpUpperBound(wp) - a0) / wp.distance_along_route + 1;
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
            gradient = (upperBound - a0) / wp.distance_along_route;
        }
        else if (lowerBound > a) {
            append(waypointStack, {"wp": wp, "alt": lowerBound, "dist": wp.distance_along_route});
            gradient = (lowerBound - a0) / wp.distance_along_route;
        }
    }
    
    var s = nil;
    var dist = 0.0;
    var alt = fp.departure.elevation * M2FT;
    var fpa = 0.0;

    append(profile,
        {
            "name": fp.getWP(0).wp_name,
            "dist": 0.0,
            "mode": "fpa",
            "fpa": 0.0,
            "alt": alt
        });
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

    ############################# cruise ############################# 
    
    append(profile,
            {
                "name": "TOC",
                "dist": nil,
                "mode": "flch",
                "fpa": 3, # dummy
                "alt": cruiseAltitude
            });

    ############################# descent ############################# 

    var destElev = fp.destination.elevation * M2FT;
    var topOfDescent = totalDistance - (cruiseAltitude - destElev) / descent_feet_per_nm;

    i = findFirstArrival(fp);
    wp = fp.getWP(i);
    if (wp != nil) {
        # check if top of descent needs to be moved
        for ( ; i < fp.getPlanSize(); i += 1) {
            wp = fp.getWP(i);
            if (wp == nil) {
                break;
            }
            var upperBound = wpUpperBound(wp);
            if (upperBound < cruiseAltitude) {
                topOfDescent = wp.distance_along_route - (cruiseAltitude - upperBound) / descent_feet_per_nm;
                break;
            }
        }
    }

    # inject top of descent
    append(profile,
            {
                "name": "TOD",
                "dist": topOfDescent,
                "mode": "fpa",
                "fpa": 0.0,
                "alt": cruiseAltitude
            });

    dist = topOfDescent;
    alt = cruiseAltitude;
    gradient = descent_feet_per_nm;

    for (i = findFirstArrival(fp); i < fp.getPlanSize(); i += 1) {
        wp = fp.getWP(i);
        if (wp == nil) {
            break;
        }
        if (wp.distance_along_route < topOfDescent) {
            # keep cruising
            continue;
        }
        var a = (wp.distance_along_route - dist) * gradient;
        var upperBound = wpUpperBound(wp);
        var lowerBound = wpLowerBound(wp);
        if (wp.wp_type == "runway") {
            # We're at the destination runway; append one final waypoint and we're done.
            # The last vertical leg is always "FLCH".
            append(profile,
                    {
                        "name": wp.wp_name,
                        "dist": wp.distance_along_route,
                        "mode": "flch",
                        "fpa": -3,
                        "alt": destElev,
                    });
            break;
        }
        else if (upperBound < lowerBound) {
            print("Impossible profile at ", wp.wp_name, ": ", upperBound, " < ", lowerBound);
            return nil;
        }
        else if (upperBound < a) {
            # Current trajectory is too high for an "at or below" restriction,
            # adjust it.
            var deltaDist = wp.distance_along_route - dist;
            var deltaAlt = upperBound - alt;
            gradient = deltaAlt / deltaDist;
            fpa = math.atan2(deltaAlt * feet_to_nm, deltaDist) * R2D;
            alt = upperBound;
            dist = wp.distance_along_route;
            append(profile,
                    {
                        "name": wp.wp_name,
                        "dist": wp.distance_along_route,
                        "mode": "fpa",
                        "fpa": fpa,
                        "alt": alt,
                    });
            gradient = (totalDistance - wp.distance_along_route) / (destElev - alt);
        }
        else if (lowerBound > a) {
            # Current trajectory is too low for an "at or above" restriction,
            # adjust it.
            var deltaDist = wp.distance_along_route - dist;
            var deltaAlt = lowerBound - alt;
            gradient = deltaAlt / deltaDist;
            fpa = math.atan2(deltaAlt * feet_to_nm, deltaDist) * R2D;
            alt = lowerBound;
            dist = wp.distance_along_route;
            append(profile,
                    {
                        "name": wp.wp_name,
                        "dist": wp.distance_along_route,
                        "mode": "fpa",
                        "fpa": fpa,
                        "alt": alt,
                    });
            gradient = (totalDistance - wp.distance_along_route) / (destElev - alt);
        }
    }

    return profile;
};

var print_vnav_wp = func (s) {
    var distStr = "---.--";
    if (s["dist"] != nil) {
        distStr = sprintf("%6.1f", s["dist"]);
    }
    if (s["mode"] == "fpa") {
        printf("%-10s @%5.0f %s nm %-4s %3.1f°", s["name"], s["alt"], distStr, s["mode"], s["fpa"]);
    }
    else {
        printf("%-10s @%5.0f %s nm %-4s", s["name"], s["alt"], distStr, s["mode"]);
    }
};

var print_profile = func (profile) {
    if (profile == nil) {
        print("No VNAV profile");
        return;
    }
    foreach (var wp ; profile) {
        print_vnav_wp(wp);
    }
};

var update_vnav = func () {
    var distanceRemaining = getprop("/autopilot/route-manager/distance-remaining-nm");
    var totalDistance = getprop("/autopilot/route-manager/total-distance");
    var routeProgress = totalDistance - distanceRemaining;
    var altitude = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    var fp = flightplan();
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
    print_profile(profile);
});

setlistener("autopilot/route-manager/cruise/altitude-ft", func {
    print("Cruise altitude changed");
    var profile = make_profile(flightplan());
    print_profile(profile);
});
