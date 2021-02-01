# VNAV calculations for the Embraer E-Jet family

# TODO:
# - correctly handle TOC when issuing DIRECTs
# - generate profile past destination to deal with missed approaches

var nm_to_feet = 6076.0;
var feet_to_nm = 1.0 / nm_to_feet;
setprop("/fms/vnav/route-progress", 0.0);

# Calculate FPA in degrees from a distance in nmi and an altitude difference
# in ft.

var calcFPA = func (deltaAlt, dist) {
    return math.atan2(deltaAlt * feet_to_nm, dist) * R2D;
}

# Convert climb/descent gradient in ft/nmi to flight path angle in degrees.
var gradientToFPA = func (gradient) {
    return math.atan2(gradient * feet_to_nm, 1.0) * R2D;
};

# Convert flight path angle in degrees to climb/descent gradient in ft/nmi.
var fpaToGradient = func (fpa) {
    # Limit to -45° <= fpa <= 45° to avoid numeric instability due to large
    # tan() outputs
    fpa = math.min(45, math.max(-45, fpa));
    return math.tan(fpa * D2R) * nm_to_feet;
};

var findFirstEnroute = func (fp) {
    var i = 0;
    var wp = nil;
    for (i = 1; i < fp.getPlanSize(); i += 1) {
        wp = fp.getWP(i);
        if (wp == nil or wp.wp_role != 'sid') {
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
        if (wp == nil or wp.wp_role == 'star' or wp.wp_role == 'approach' or wp.wp_role == 'missed' or wp.wp_role == 'runway') {
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
    var descent_fpa = -math.abs(getprop("/controls/flight/speed-schedule/descent-fpa"));
    var descent_feet_per_nm = fpaToGradient(descent_fpa);
    var fp = flightplan();
    if (fp == nil) {
        print("VNAV: No flightplan");
        return nil;
    }
    var totalDistance = getprop("/autopilot/route-manager/total-distance");
    var firstEnroute = findFirstEnroute(fp);
    var wp = fp.getWP(firstEnroute);

    if (wp == nil) {
        print("VNAV: Flightplan not closed");
        return nil; # flightplan is not closed
    }

    var cruiseAltitude = getprop("/autopilot/route-manager/cruise/altitude-ft") or 10000;

    var profile = { waypoints: [], totalDistance: totalDistance, topOfDescent: 0 };

    ############################# departure ############################# 
    var gradient = 0;
    var a = cruiseAltitude;
    var a0 = 0;
    if (fp.departure != nil and fp.departure.elevation != nil) {
        a0 = fp.departure.elevation * M2FT;
    }
    else {
        printf("No departure set, vertical profile may be incorrect");
    }
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
            print("VNAV: Impossible profile at ", wp.wp_name, ": ", upperBound, " < ", lowerBound);
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
    var alt = 0;
    if (fp.departure != nil and fp.departure.elevation != nil) {
        alt = fp.departure.elevation * M2FT;
    }
    else {
        printf("No departure set, vertical profile may be incorrect");
    }
    var fpa = 0.0;

    append(profile.waypoints,
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
                # print("VNAV: delta dist: ", deltaDist, ", delta alt: ", deltaAlt * feet_to_nm);
                fpa = calcFPA(deltaAlt, deltaDist);
            }
            else {
                gradient = 0.0;
                fpa = 0.0;
            }
            alt = s["alt"];
            dist = s["dist"];
            append(profile.waypoints,
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
    
    append(profile.waypoints,
            {
                "name": "TOC",
                "dist": nil,
                "mode": "flch",
                "fpa": 3, # dummy
                "alt": cruiseAltitude
            });

    ############################# descent ############################# 

    var destElev = 0;
    if (fp.destination != nil and fp.destination.elevation != nil) {
        destElev = fp.destination.elevation * M2FT;
    }
    else {
        printf("No destination set, vertical profile may be incorrect");
    }
    var topOfDescent = totalDistance - (destElev - cruiseAltitude) / descent_feet_per_nm;
    profile.topOfDescent = topOfDescent;

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
                topOfDescent = math.min(wp.distance_along_route - (upperBound - cruiseAltitude) / descent_feet_per_nm, topOfDescent);
                break;
            }
        }
    }

    # inject top of descent
    append(profile.waypoints,
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

    var runwayReached = 0;

    for (i = findFirstArrival(fp); i < fp.getPlanSize(); i += 1) {
        wp = fp.getWP(i);
        if (wp == nil) {
            break;
        }
        if (wp.distance_along_route < topOfDescent) {
            # keep cruising
            continue;
        }
        var a = alt + (wp.distance_along_route - dist) * gradient;
        var upperBound = wpUpperBound(wp);
        var lowerBound = wpLowerBound(wp);
        if (wp.wp_type == "runway") {
            # We're at the destination runway; append one final waypoint and we're done.
            # The last vertical leg is always "FLCH".
            append(profile.waypoints,
                    {
                        "name": wp.wp_name,
                        "dist": wp.distance_along_route,
                        "mode": "flch",
                        "fpa": -3,
                        "alt": destElev,
                    });
            runwayReached = 1;
            break;
        }

        # printf("%-5s %.0f <= %.0f <= %.0f?",
        #     wp.wp_name, lowerBound, a, upperBound);

        if (lowerBound > -1000 or upperBound < 60000) {
            a = math.min(upperBound, math.max(lowerBound, a));
            # printf("New a = %.0f", a);
            var deltaDist = wp.distance_along_route - dist;
            var deltaAlt = a - alt;
            gradient = deltaAlt / deltaDist;
            fpa = calcFPA(deltaAlt, deltaDist);
            alt = a;
            dist = wp.distance_along_route;
            append(profile.waypoints,
                    {
                        "name": wp.wp_name,
                        "dist": wp.distance_along_route,
                        "mode": "fpa",
                        "fpa": fpa,
                        "alt": alt,
                    });
            gradient = (destElev - alt) / (totalDistance - wp.distance_along_route);
            # printf("New gradient = %3.1f", gradient);
        }
    }

    if (!runwayReached) {
        append(profile.waypoints,
                {
                    "name": fp.destination.id,
                    "dist": totalDistance,
                    "mode": "flch",
                    "fpa": -3,
                    "alt": destElev,
                });
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
    foreach (var wp ; profile.waypoints) {
        print_vnav_wp(wp);
    }
};

var VNAV = {
    new: func () {
        var m = { parents: [VNAV] };
        m.profile = nil;
        m.current = 0;
        m.tocReached = 0;
        m.desNowAvailable = 0;
        m.desNowMode = 0;
        m.desNowTriggered = 0;
        return m;
    },

    loadProfile: func (profile) {
        me.profile = profile;
        if (profile == nil) {
            setprop("/fms/vnav/available", 0);
            me.reset();
        }
        else {
            setprop("/fms/vnav/available", 1);
            setprop("/fms/internal/tod", profile.totalDistance - profile.topOfDescent);
            me.reposition();
        }
    },

    reset: func () {
        me.current = 0;
        me.tocReached = 0;
        setprop("/fms/vnav/selected-alt", 0.0);
        setprop("/fms/vnav/selected-mode", "flch");
        setprop("/fms/vnav/selected-fpa", 0.0);
        setprop("/fms/vnav/current", 0);
        setprop("/fms/vnav/currentWP/name", "");
        setprop("/fms/vnav/currentWP/dist", 0.0);
        setprop("/fms/vnav/currentWP/alt", 0.0);
        setprop("/fms/vnav/currentWP/mode", "flch");
    },

    jumpTo: func () {
        if (me.profile == nil) {
            return;
        }
        wp = me.profile.waypoints[me.current];
        setprop("/fms/vnav/selected-alt", wp["alt"]);
        setprop("/fms/vnav/selected-mode", wp["mode"]);
        setprop("/fms/vnav/selected-fpa", wp["fpa"] or 0);
        setprop("/fms/vnav/current", me.current);
        setprop("/fms/vnav/currentWP/name", wp["name"]);
        setprop("/fms/vnav/currentWP/dist", wp["dist"] or 9999);
        setprop("/fms/vnav/currentWP/alt", wp["alt"]);
        setprop("/fms/vnav/currentWP/mode", wp["mode"]);
        if (getprop("/controls/flight/vnav-enabled")) {
            # delay activation by half a second, to make sure the selected
            # altitude has been forwarded to ITAF.
            settimer(func () { me.activate(); }, 0.5);
        }
    },

    reposition: func () {
        if (me.profile == nil) {
            me.reset();
            return;
        }
        var i = 0;
        var distanceRemaining = getprop("/autopilot/route-manager/distance-remaining-nm");
        var totalDistance = getprop("/autopilot/route-manager/total-distance");
        var routeProgress = totalDistance - distanceRemaining;
        if (me.tocReached) {
            # fast forward to first point after TOC
            while (i < size(me.profile.waypoints) and me.profile.waypoints[i]["name"] != "TOC") {
                i += 1;
            }
        }
        me.current = i;
    },

    desNow: func () {
        if (!me.desNowAvailable) {
            return 0;
        }
        me.desNowTriggered = 1;
        me.desNowMode = 1;
        me.desNowAvailable = 0;
        return 1;
    },

    update: func () {
        var profile = me.profile;
        if (profile == nil or me.current >= size(profile.waypoints)) {
            # No VNAV profile loaded, or we're past the end.
            setprop("/fms/vnav/available", 0);
            return;
        }
        var distanceRemaining = getprop("/autopilot/route-manager/distance-remaining-nm");
        var totalDistance = getprop("/autopilot/route-manager/total-distance");
        var routeProgress = totalDistance - distanceRemaining;
        var altitude = getprop("/instrumentation/altimeter/indicated-altitude-ft");

        var done = 0;
        var advanced = 0;
        var wp = nil;

        # printf("Route progress: %3.1f nm, %1.0f ft", routeProgress, altitude);
        while (done == 0 and me.current < size(profile.waypoints)) {
            wp = profile.waypoints[me.current];
            # print_vnav_wp(wp);
            if (wp["name"] == "TOC") {
                if (me.tocReached or (altitude + 50 >= wp["alt"])) {
                    # We've reached cruise altitude
                    me.current += 1;
                    me.tocReached = 1;
                    advanced = 1;
                }
                else {
                    # Next waypoint is TOC, but we haven't reached cruise altitude
                    # yet.
                    done = 1;
                }
            }
            else {
                if (routeProgress >= (wp["dist"] or 0)) {
                    me.current += 1;
                    advanced = 1;
                }
                else {
                    done = 1;
                }
            }
        }
        if (advanced) {
            # New waypoint has been selected, so update our targets.
            me.jumpTo();
        }
        if (!me.desNowTriggered and me.desNowAvailable and distanceRemaining <= profile.topOfDescent + 50.0) {
            me.desNowAvailable = 1;
        }
        if (me.current < size(profile.waypoints)) {
            wp = profile.waypoints[me.current];
        }
        else {
            wp = nil;
        }
        # update actual VNAV availability
        setprop("/fms/vnav/available", wp != nil);
        if (wp != nil) {
            # default to trying to capture the target ASAP
            var profileAlt = wp["alt"];
            if (wp["dist"] != nil and wp["mode"] == "fpa" and wp["fpa"] != nil) {
                # WP is a regular FPA waypoint, and has an FPA associated
                # with it
                var gradient = fpaToGradient(wp["fpa"]);
                if (wp["dist"] - routeProgress > 0.1) {
                    profileAlt = wp["alt"] - (gradient * (wp["dist"] - routeProgress));
                }
                # printf("FPA: %3.1f° / %4.0f ft/nmi over %3.1f nmi to reach %5.0f ft -> %5.0f ft",
                #     wp["fpa"], gradient, wp["dist"] - routeProgress, wp["alt"], profileAlt);

                # Off by more than 50 feet? Adjust FPA.
                if (altitude > profileAlt + 50) {
                    # If above, expedite descent by up to -1.5°.
                    var correction = math.max(0, math.min(1.5, (altitude - profileAlt) * 1.5 / 1000.0));
                    setprop("/fms/vnav/selected-fpa", math.min(0, wp["fpa"] - correction));
                }
                else if (altitude < profileAlt - 50) {
                    if (me.desNowMode) {
                        # If early descent selected, maintain constant 1000 fpm
                        # descent until capturing the profile.
                        var targetFPM = -1000;
                        var speed = getprop("/velocities/groundspeed-kt");
                        var speedMPM = speed / 60.0;
                        var fpa = calcFPA(targetFPM, speedMPM);
                        setprop("/fms/vnav/selected-fpa", fpa);
                    }
                    else {
                        # If below, expedite climb by up to 1.5°.
                        var correction = math.max(0, math.min(1.5, -(altitude - profileAlt) * 1.5 / 1000.0));
                        setprop("/fms/vnav/selected-fpa", math.max(0, wp["fpa"] + 1.5));
                    }
                }
                else if (me.desNowMode) {
                    # we've captured the profile in DES NOW mode
                    me.desNowMode = 0;
                    setprop("/fms/vnav/selected-fpa", wp["fpa"]);
                }
            }
            setprop("/fms/vnav/profile-alt", profileAlt);
            setprop("/fms/vnav/alt-deviation", altitude - profileAlt);
        }
        setprop("/fms/vnav/route-progress", routeProgress);
        # TODO: switch to VFLCH (and back!) when path cannot be captured before
        # next waypoint.
    },

    nominalProfileAltAt: func(dist) {
        if (me.profile == nil or me.profile.waypoints == nil) return 0;
        var numWPs = size(me.profile.waypoints);
        if (numWPs == 0) return 0;
        var wpFrom = me.profile.waypoints[0];
        var wpTo = wpFrom;
        var distFrom = 0.0;
        var distTo = 0.0;
        var tod = me.profile.totalDistance - me.profile.topOfDescent;

        for (var j = 1; j < numWPs; j += 1) {
            wpFrom = wpTo;
            wpTo = me.profile.waypoints[j];
            distFrom = distTo;
            distTo = wpTo.dist;
            if (distTo == nil) {
                var dalt = math.abs(wpTo.alt - wpFrom.alt);
                # Wild guess for an average climb:
                # - 300 knots ground speed
                # - 2000 fpm
                # Factor 60 because knots is per hour but fpm is per minute
                distTo = distFrom + dalt * 300 / 60 / 2000;
            }
            if (distFrom <= dist and distTo > dist) {
                break;
            }
        }
        if (dist == distFrom or distFrom == distTo) {
            return wpFrom.alt;
        }
        else {
            return wpFrom.alt + (wpTo.alt - wpFrom.alt) * (dist - distFrom) / (distTo - distFrom);
        }
    },

    activate: func () {
        if (getprop("/controls/flight/vnav-enabled") and me.profile != nil) {
            var wp = me.profile.waypoints[me.current];
            if (wp == nil) {
                print("VNAV: No waypoint");
                return;
            }
            printf("VNAV: activate %s", wp["name"]);
            if (wp["mode"] == "flch") {
                # 4 = FLCH
                setprop("/it-autoflight/input/vert", 4);
            }
            else if (wp["mode"] == "fpa") {
                # 5 = FPA
                # Just follow the vertical path.
                setprop("/it-autoflight/input/vert", 5);
            }
        }
        else {
            print("VNAV: No profile or VNAV disabled");
        }
    }

};

var vnav = VNAV.new();

setlistener("sim/signals/fdm-initialized", func {
    vnav.reset();
	var timer = maketimer(1, func () { vnav.update(); });
    timer.simulatedTime = 1;
    timer.singleShot = 0;
	# timer.start();
});

setlistener("controls/flight/vnav-enabled", func {
    vnav.activate();
});

setlistener("autopilot/route-manager/signals/edited", func {
    print("VNAV: Flightplan edited");
    if (getprop("autopilot/route-manager/active")) {
        var profile = make_profile(flightplan());
        print_profile(profile);
        vnav.loadProfile(profile);
    }
    else {
        vnav.reset();
    }
});

setlistener("autopilot/route-manager/cruise/altitude-ft", func {
    print("VNAV: Cruise altitude changed");
    if (getprop("autopilot/route-manager/active")) {
        var profile = make_profile(flightplan());
        print_profile(profile);
        vnav.loadProfile(profile);
    }
    else {
        vnav.reset();
    }
});

setlistener("autopilot/route-manager/active", func {
    print("VNAV: Flightplan activated or closed");
    if (getprop("autopilot/route-manager/active")) {
        var profile = make_profile(flightplan());
        print_profile(profile);
        vnav.loadProfile(profile);
    }
    else {
        vnav.reset();
    }
});

