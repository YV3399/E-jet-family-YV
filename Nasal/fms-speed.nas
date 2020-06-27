# FMS speed calculations for the Embraer E-Jet family

var phase_to = 0;
var phase_toclb = 1;
var phase_departure = 2;
var phase_climb = 3;
var phase_cruise = 4;
var phase_descent = 5;
var phase_approach = 6;

var update_speed_restrictions = func (fp, phase) {
    var i = fp.current;
    var wp = fp.getWP(i);
    var climbLimit = 400;
    var descentLimit = 400;
    var distanceRemaining = getprop("/autopilot/route-manager/distance-remaining-nm");
    var totalDistance = getprop("/autopilot/route-manager/total-distance");
    var routeProgress = totalDistance - distanceRemaining;

    # Search ahead for speed limits for the descent and cruise
    var maxLookahead = 4.0; # look 4 miles ahead
    # First, find the end of the departure
    i = 0;
    wp = fp.getWP(i);
    while (wp != nil and wp.wp_parent != nil and wp.wp_parent.tp_type == "sid") {
        i += 1;
        wp = fp.getWP(i);
    }
    # now move forward to the current waypoint
    while (wp != nil and wp.distance_along_route <= routeProgress + maxLookahead) {
        if (wp.speed_cstr_type == "at" or wp.speed_cstr_type == "below") {
            if (wp.speed_cstr < descentLimit) {
                descentLimit = wp.speed_cstr;
            }
        }
        i += 1;
        wp = fp.getWP(i);
    }
    setprop("/fms/internal/speed-limit-descent", descentLimit);

    # Search ahead for speed limits for the climb
    i = fp.current;
    wp = fp.getWP(i);
    while (wp != nil and wp.wp_parent != nil and wp.wp_parent.tp_type == "sid") {
        if (wp.speed_cstr_type == "at" or wp.speed_cstr_type == "below") {
            climbLimit = wp.speed_cstr;
            break;
        }
        i += 1;
        wp = fp.getWP(i);
    }
    setprop("/fms/internal/speed-limit-climb", climbLimit);
};

var clear_speed_restrictions = func () {
    # Set an arbitrary high limit
    setprop("/fms/speed-limit-climb", 400);
    setprop("/fms/speed-limit-descent", 400);
};

var update_fms_speed = func () {
    var phase = getprop("/fms/phase");

    var fp = flightplan();
    if (fp != nil) {
        update_speed_restrictions(fp, phase);
    }
    else {
        clear_speed_restrictions();
    }

    if (phase == phase_to) {
        if (getprop("/fms/internal/cond/departure")) {
            # skip the "TO CLB" phase
            setprop("/fms/phase", phase_departure);
        }
        if (getprop("/fms/internal/cond/to-clb")) {
            setprop("/fms/phase", phase_toclb);
        }
    }
    else if (phase == phase_toclb) {
        if (getprop("/fms/internal/cond/departure")) {
            setprop("/fms/phase", phase_departure);
        }
    }
    else if (phase == phase_departure) {
        if (getprop("/fms/internal/cond/climb")) {
            setprop("/fms/phase", phase_climb);
        }
    }
    else if (phase == phase_climb) {
        if (getprop("/fms/internal/cond/cruise")) {
            setprop("/fms/phase", phase_cruise);
        }
    }
    else if (phase == phase_cruise) {
        if (getprop("/fms/internal/cond/climb")) {
            setprop("/fms/phase", phase_climb);
        }
        if (getprop("/fms/internal/cond/descent")) {
            setprop("/fms/phase", phase_descent);
        }
    }
    else if (phase == phase_descent) {
        if (getprop("/fms/internal/cond/cruise")) {
            setprop("/fms/phase", phase_cruise);
        }
        if (getprop("/fms/internal/cond/climb")) {
            setprop("/fms/phase", phase_climb);
        }
        if (getprop("/fms/internal/cond/approach")) {
            setprop("/fms/phase", phase_approach);
        }
    }
    else if (phase == phase_approach) {
        # TOGA button pushed during approach
        if (getprop("/fms/internal/cond/toga")) {
            setprop("/fms/phase", phase_to);
            setprop("/fms/internal/toc-reached", 0);
        }
    }
};

setlistener("sim/signals/fdm-initialized", func {
	var timer = maketimer(0.1, func () { update_fms_speed(); });
    timer.simulatedTime = 1;
    timer.singleShot = 0;
	timer.start();
});
