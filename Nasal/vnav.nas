# VNAV calculations for the Embraer E-Jet family

var phase_to = 0;
var phase_toclb = 1;
var phase_departure = 2;
var phase_climb = 3;
var phase_cruise = 4;
var phase_descent = 5;
var phase_approach = 6;

var feet_to_nm = 0.003149385628695797;

var update_vnav = func () {
    var distanceRemaining = getprop("/autopilot/route-manager/distance-remaining-nm");
    var totalDistance = getprop("/autopilot/route-manager/total-distance");
    var routeProgress = totalDistance - distanceRemaining;
    var altitude = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    var fp = flightplan();
    if (fp != nil) {
        var upperBound = 0;
        var lowerBound = -1000;
        var requiredClimb = 0;
        var requiredDescent = 0;
        var altTarget = 0;
    
        var i = fp.current;
        var wp = fp.getWP(i);
        if (i == 0 or (wp != nil and wp.wp_parent != nil and wp.wp_parent.tp_type == "sid")) {
            print("departure");
            # We're on the SID

            # default upper bound is cruise altitude.
            upperBound = getprop("/autopilot/route-manager/cruise/altitude-ft") or 35000;

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
                    var angle = math.atan2(altDifferenceNM, distanceTo);
                    if (angle > requiredClimb) {
                        requiredClimb = angle;
                    }
                }
                i += 1;
                wp = fp.getWP(i);
            }
            print("ALT target: ", upperBound);
            setprop("/fms/alt-target", upperBound);
            print("Climb gradient: ", requiredClimb);
            setprop("/fms/climb-gradient", requiredClimb);
        }
        else {
            print("cruise/descent");
        }
    }
    else {
        print("No flightplan");
    }
}

setlistener("sim/signals/fdm-initialized", func {
	var timer = maketimer(1, func () { update_vnav(); });
    timer.simulatedTime = 1;
    timer.singleShot = 0;
	timer.start();
});
