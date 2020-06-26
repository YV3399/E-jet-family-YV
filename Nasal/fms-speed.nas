var phase_to = 0;
var phase_toclb = 1;
var phase_departure = 2;
var phase_climb = 3;
var phase_cruise = 4;
var phase_descent = 5;
var phase_approach = 6;

var update_fms_speed = func () {
    var phase = getprop("/fms/phase");

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
