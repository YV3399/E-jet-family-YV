# Performance metrics for the Embraer E-Jet FMS/MCDU/FPL

# Note that we use lbs for fuel throughout, because that's what FG uses in
# most places.

io.include('performance/current-gs-ff.nas');
io.include('performance/pilot-spd-ff.nas');

var myprops = nil;

var PERF_MODE_FULL_PERF = 0;
var PERF_MODE_CURRENT_GS_FF = 1;
var PERF_MODE_PILOT_SPD_FF = 2;

var makeInfo = func {
    var totalDist = myprops.totalDist.getValue();
    return {
        fob: myprops.totalFuel.getValue(),
        totalDist: totalDist,
        dist: totalDist - myprops.distRemaining.getValue(),
        groundspeed: myprops.groundspeed.getValue(),
        ff: myprops.fuelFlowL.getValue() + myprops.fuelFlowR.getValue(),
        time: myprops.daySeconds.getValue(),
        cruiseAlt: myprops.cruiseAlt.getValue(),
        currentAlt: myprops.alt.getValue(),
        landingAlt: myprops.landingAlt.getValue(),
        cruiseIAS: myprops.cruiseIAS.getValue(),
        cruiseMach: myprops.cruiseMach.getValue(),
    };
};

# A performance point can be actual or estimated, and has the following keys:
# - ta (time of arrival, seconds from midnight)
# - fob (fuel on board, lbs)

var initProfile = func() {
    return {
        actual: [],
        estimated: [],
        destRunwayIndex: nil,
    };
};

var updateProfile = func (mode, fp, info, profile) {
    print("updateProfile");
    var totalDist = myprops.totalDist.getValue();
    var planSize = fp.getPlanSize();

    var current = {
        ta: info.time,
        fob: info.fob,
    };

    mode.init(info);

    if (size(profile.estimated) < planSize) {
        setsize(profile.estimated, planSize);
    }
    for (var i = 0; i < planSize; i += 1) {
        var wp = fp.getWP(i);
        var isDestination = 0;
        if (i > 1 and math.abs(wp.distance_along_route - totalDist) < 0.1) {
            # this is the destination
            profile.destRunwayIndex = i;
            isDestination = 1;
        }
        else if (i == 1 and planSize == 2) {
            isDestination = 1;
        }
        if (wp.distance_along_route <= info.dist) {
            # first situation: we are already past this waypoint.
            while (size(profile.actual) <= i) {
                # Nothing logged for this one yet!
                # We'll assume that this is because we've only just reached the
                # waypoint, so we log the current situation for it.
                append(profile.actual, current);
            }
            # Now just in case we don't have any estimates for this one yet,
            # copy over the actual value to the estimates to fill any gaps.
            # Normally however, there should already be estimates, in which
            # case we just keep the last estimate from before we reached the
            # waypoint.
            if (profile.estimated[i] == nil) {
                profile.estimated[i] = profile.actual[i];
            }
        }
        else {
            # second situation: we have yet to reach the waypoint.
            profile.estimated[i] = mode.estimateWaypoint(wp.distance_along_route, wp.id);
        }
        # forward some calculated to properties
        if (i == fp.current) {
            myprops.fuelWP0.setValue(profile.estimated[i].fob);
            myprops.etaWP0.setValue(profile.estimated[i].ta);
        }
        else if (i == fp.current + 1) {
            myprops.fuelWP1.setValue(profile.estimated[i].fob);
            myprops.etaWP1.setValue(profile.estimated[i].ta);
        }
        if (isDestination) {
            myprops.fuelDest.setValue(profile.estimated[i].fob);
            myprops.etaDest.setValue(profile.estimated[i].ta);
        }
    }
};

var performanceProfile = initProfile();

var printPerformanceProfile = func (fp, profile) {
    print("----- PERFORMANCE PLAN -----");
    printf("%-8s %-5s/%-5s %-6s/%-6s",
        "WPT ID", "ETA", "ATA", "EFOB", "AFOB");
    print("----------------------------------------------");
    for (var i = 0; i < fp.getPlanSize(); i += 1) {
        var wp = fp.getWP(i);
        var e = (i >= size(profile.estimated)) ? nil : profile.estimated[i];
        var a = (i >= size(profile.actual)) ? nil : profile.actual[i];
        printf("%-8s %5s/%5s %6.0f/%6.0f",
            wp.id,
            (e == nil) ? "-----" : mcdu.formatZulu(e.ta),
            (a == nil) ? "-----" : mcdu.formatZulu(a.ta),
            (e == nil) ? 0 : e.fob,
            (a == nil) ? 0 : a.fob);
    }
}

var initialized = 0;
var listeners = [];
var timer = nil;

var teardown = func {
    foreach (var l; listeners) {
        removelistener(l);
    }
    listeners = [];
    if (timer != nil) {
        timer.stop();
        timer = nil;
    }
    initialized = 0;
};

var initialize = func {
    if (initialized) teardown();
    initialized = 1;

    myprops = {
        totalDist: props.globals.getNode('/autopilot/route-manager/total-distance'),
        distRemaining: props.globals.getNode('/autopilot/route-manager/distance-remaining-nm'),
        totalFuel: props.globals.getNode('/fdm/jsbsim/propulsion/total-fuel-lbs'),
        daySeconds: props.globals.getNode('/sim/time/utc/day-seconds'),
        groundspeed: props.globals.getNode('velocities/groundspeed-kt'),
        fuelFlowL: props.globals.getNode('/fdm/jsbsim/propulsion/engine[0]/fuel-flow-rate-pps'),
        fuelFlowR: props.globals.getNode('/fdm/jsbsim/propulsion/engine[1]/fuel-flow-rate-pps'),
        fuelWP0: props.globals.getNode('/fms/performance/wp[0]/efob'),
        fuelWP1: props.globals.getNode('/fms/performance/wp[1]/efob'),
        fuelDest: props.globals.getNode('/fms/performance/destination/efob'),
        etaWP0: props.globals.getNode('/fms/performance/wp[0]/eta'),
        etaWP1: props.globals.getNode('/fms/performance/wp[1]/eta'),
        etaDest: props.globals.getNode('/fms/performance/destination/eta'),
        perfMode: props.globals.getNode('/controls/flight/perf-mode'),
        cruiseAlt: props.globals.getNode('/autopilot/route-manager/cruise/altitude-ft'),
        cruiseIAS: props.globals.getNode('/controls/flight/speed-schedule/cruise-kts'),
        cruiseMach: props.globals.getNode('/controls/flight/speed-schedule/cruise-mach'),
        alt: props.globals.getNode('/instrumentation/altimeter/indicated-altitude-ft'),
        landingAlt: props.globals.getNode('/fms/approach-conditions/runway-elevation'),
    };
    append(listeners,
        setlistener("autopilot/route-manager/active", func { performanceProfile = initProfile(); }));
    append(listeners,
        setlistener("autopilot/route-manager/signals/edited", func { performanceProfile = initProfile(); }));
    var perfMode = CurrentGsFfMode.new();
    append(listeners,
        setlistener("controls/flight/perf-mode", func (node) {
            if (node.getValue() == PERF_MODE_PILOT_SPD_FF) {
                perfMode = PilotSpeedFfMode.new();
            }
            else {
                perfMode = CurrentGsFfMode.new();
            }
        }));
	timer = maketimer(5, func () {
        var fp = getVisibleFlightplan();
        var info = makeInfo();
        updateProfile(perfMode, fp, info, performanceProfile);
        printPerformanceProfile(fp, performanceProfile);
    });
    timer.simulatedTime = 1;
    timer.singleShot = 0;
	timer.start();
};

setlistener("sim/signals/fdm-initialized", initialize);
