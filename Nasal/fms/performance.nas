# Performance metrics for the Embraer E-Jet FMS/MCDU/FPL

# Note that we use lbs for fuel throughout, because that's what FG uses in
# most places.

var myprops = nil;

# A performance point can be actual or estimated, and has the following keys:
# - ta (time of arrival, seconds from midnight)
# - fob (fuel on board, lbs)

var initProfile = func() {
    return {
        actual: [],
        estimated: [],
    };
};

var updateProfile = func (fp, mode, profile) {
    var info = {
        fob: myprops.totalFuel.getValue(),
        dist: myprops.totalDist.getValue() - myprops.distRemaining.getValue(),
        groundspeed: myprops.groundspeed.getValue(),
        ff: myprops.fuelFlowL.getValue() + myprops.fuelFlowR.getValue(),
        time: myprops.daySeconds.getValue(),
    };

    var planSize = fp.getPlanSize();

    var current = {
        ta: info.time,
        fob: info.fob,
    };

    if (size(profile.estimated) < planSize) {
        setsize(profile.estimated, planSize);
    }
    for (var i = 0; i < planSize; i += 1) {
        var wp = fp.getWP(i);
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
            profile.estimated[i] = mode(wp.distance_along_route, info);
        }
    }
};

var estimateSimple = func(dist, info) {
    var groundspeed = info.groundspeed;
    if (groundspeed < 120) groundspeed = 120; # avoid div-by-0 and such
    var delta_dist = dist - info.dist;
    var te = delta_dist / groundspeed * 3600;
    return {
        # ETA is current time +/- est. time to/from waypoint
        ta: info.time + te,

        # EFOB is current FOB +/- est. fuel burn to/from waypoint
        fob: info.fob - te * info.ff
    };
};

var performanceProfile = initProfile();

var printPerformanceProfile = func (profile) {
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
            (e == nil) ? "-----" : mcdu.formatZuluSeconds(e.ta),
            (a == nil) ? "-----" : mcdu.formatZuluSeconds(a.ta),
            (e == nil) ? 0 : e.fob,
            (a == nil) ? 0 : a.fob);
    }
}

setlistener("sim/signals/fdm-initialized", func {
    myprops = {
        totalDist: props.globals.getNode('/autopilot/route-manager/total-distance'),
        distRemaining: props.globals.getNode('/autopilot/route-manager/distance-remaining-nm'),
        totalFuel: props.globals.getNode('/fdm/jsbsim/propulsion/total-fuel-lbs'),
        daySeconds: props.globals.getNode('/sim/time/utc/day-seconds'),
        groundspeed: props.globals.getNode('velocities/groundspeed-kt'),
        fuelFlowL: props.globals.getNode('/fdm/jsbsim/propulsion/engine[0]/fuel-flow-rate-pps'),
        fuelFlowR: props.globals.getNode('/fdm/jsbsim/propulsion/engine[1]/fuel-flow-rate-pps'),
    };
    setlistener("autopilot/route-manager/active", func { performanceProfile = initProfile(); });
    setlistener("autopilot/route-manager/signals/edited", func { performanceProfile = initProfile(); });
	var timer = maketimer(5, func () {
        var fp = getVisibleFlightplan();
        updateProfile(fp, estimateSimple, performanceProfile);
    });
    timer.simulatedTime = 1;
    timer.singleShot = 0;
	timer.start();
});
