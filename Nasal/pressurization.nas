var MODE_MAN = -1;
var MODE_AUTO = 0;
var MODE_LFE = 0;

var PHASE_GROUND = 0;
var PHASE_TAXI_OUT = 1;
var PHASE_TAKEOFF = 2;
var PHASE_CLIMB = 3;
var PHASE_CRUISE = 4;
var PHASE_DESCENT = 5;
var PHASE_ABORT = 6;
# The taxi-in phase is not actually in the manual, but if we transition from
# DESCENT or ABORT to GROUND after touchdown, running the engines up to 60% N2
# (e.g. after coming to a stop mid-taxi) would advance the mode to TAXI again,
# setting a pressure target of +0.11 PSI, which then prevents the doors from
# opening on stand. Hence, we introduce the TAXI_IN phase, which sets the same
# pressurization targets as GROUND, but does not transition to TAXI_OUT.
# Instead, it transitions to GROUND when either the engines are shut off, or
# at least one door is opened.
var PHASE_TAXI_IN = 7;

# attempt to achieve targets/diff-psi as fast as possible within rate limits
var TARGET_DIFF = 0;

# attempt to achieve targets/cabin-alt-ft as fast as possible within rate limits
var TARGET_ALT = 1;

# attempt to achieve targets/cabin-alt-ft by the time we expect to reach
# targets/reference-alt-ft, based on current vertical speed
var TARGET_ALT_BY = 2;

# calculate current target altitude from current pressure altitude,
# targets/cabin-alt-ft, and targets/reference-alt-ft.
# (target-alt = current-alt * reference-alt / cabin-alt)
var TARGET_MATCH_ALT = 3;

var flightPhaseNames = [
        'GROUND',
        'TAXI-OUT',
        'TAKEOFF',
        'CLIMB',
        'CRUISE',
        'DESCENT',
        'ABORT',
        'TAXI-IN',
    ];

var getFlightPhaseName = func (phase) {
    if (phase < 0 or phase >= size(flightPhaseNames)) {
        return sprintf('UNKNOWN_%i', phase);
    }
    else {
        return flightPhaseNames[phase];
    }
};

var expandNodeCatalog = func (node, path) {
    if (node == nil) {
        return props.globals.getNode(path);
    }
    elsif (typeof(node) == 'hash') {
        var result = {};
        foreach (var k; keys(node)) {
            var expanded = expandNodeCatalog(node[k], path ~ '/' ~ k);
            var kCamel = kebabToCamel(k);
            result[k] = result[kCamel] = expanded;
        }
        return result;
    }
    else {
        die('Unexpected type: ' ~ typeof(node));
    }
};

var kebabToCamel = func (kebab) {
    var words = split('-', kebab);
    var result = words[0];

    foreach (var word; subvec(words, 1)) {
        result ~= string.uc(utf8.substr(word, 0, 1)) ~ utf8.substr(word, 1);
    }

    return result;
};

var myprops = expandNodeCatalog({
    'controls': {
        'pressurization': {
            'mode': nil,
        },
    },
    'systems': {
        'pressurization': {
            'automatic': {
                'flight-phase': nil,
                'conditions': {
                    'wow': nil,
                    'doors-closed': nil,
                    'vertical': nil,
                    'engines-running': nil,
                    'engines-60n2': nil,
                    'engines-takeoff': nil,
                    'cruise-alt': nil,
                },
                'profile': {
                    'takeoff-alt': nil,
                    'takeoff-alt-from-fms': nil,
                    'landing-alt': nil,
                    'landing-alt-from-fms': nil,
                    'cruise-alt': nil,
                    'cruise-alt-from-fms': nil,
                },
            },
            'pressures': {
                'outside-hpa': nil,
                'cabin-hpa': nil,
                'lfe-hpa': nil,
                'diff-hpa': nil,
                'outside-ft': nil,
                'cabin-ft': nil,
                'lfe-ft': nil,
                'lfe-from-fms': nil,
                'diff-psi': nil,
                'rate-fpm': nil,
                'outside-rate-fpm': nil,
            },
            'limits': {
                'diff-psi-caution-max': nil,
                'diff-psi-caution-min': nil,
                'diff-psi-warning-max': nil,
                'diff-psi-warning-min': nil,
                'cabin-ft-caution-max': nil,
                'cabin-ft-warning-max': nil,
                'rate-fpm-caution-max': nil,
            },
            'targets': {
                'type': nil,
                'rate-fpm': nil,
                'diff-psi': nil,
                'alt-ft': nil,
                'rate-min-fpm': nil,
                'rate-max-fpm': nil,
                'cabin-alt-ft': nil,
                'reference-alt-ft': nil,
            },
            'profile': {
                'takeoff-alt': nil,
                'takeoff-alt-from-fms': nil,
                'cruise-alt': nil,
                'cruise-alt-from-fms': nil,
                'landing-alt': nil,
                'landing-alt-from-fms': nil,
            }
        }
    },
    'autopilot': {
        'route-manager': {
            'cruise': {
                'altitude-ft': nil,
            },
            'signals': {
                'edited': nil,
            },
        },
    },

}, '');

var initListener = nil;

var updateFlightPhase = func (node) {
    var current = myprops.systems.pressurization.automatic.flightPhase.getValue();
    var next = current;

    if (next < 0) {
        next = PHASE_GROUND;
    }
    if (next == PHASE_GROUND) {
        if (myprops.systems.pressurization.automatic.conditions.doorsClosed.getBoolValue() and
            myprops.systems.pressurization.automatic.conditions.engines60n2.getBoolValue()) {
            next = PHASE_TAXI_OUT;
        }
    }
    if (next == PHASE_TAXI_OUT or next == PHASE_TAXI_IN) {
        if (myprops.systems.pressurization.automatic.conditions.enginesTakeoff.getBoolValue()) {
            next = PHASE_TAKEOFF;
        }
    }
    if (next == PHASE_TAKEOFF) {
        if (!myprops.systems.pressurization.automatic.conditions.wow.getBoolValue()) {
            next = PHASE_CLIMB;
        }
    }
    if (next == PHASE_CLIMB) {
        if (myprops.systems.pressurization.automatic.conditions.cruiseAlt.getBoolValue()) {
            next = PHASE_CRUISE;
        }
    }
    if (next == PHASE_TAKEOFF or next == PHASE_CLIMB) {
        if (myprops.systems.pressurization.automatic.conditions.vertical.getValue() < 0 and
            myprops.systems.pressurization.pressures.outsideFt.getValue() < 10000) {
            next = PHASE_ABORT;
        }
    }
    if (next == PHASE_CRUISE or next == PHASE_CLIMB) {
        if (myprops.systems.pressurization.automatic.conditions.vertical.getValue() < 0) {
            next = PHASE_DESCENT;
        }
    }
    if (next == PHASE_ABORT) {
        if (myprops.systems.pressurization.automatic.conditions.vertical.getValue() > 0) {
            next = PHASE_CLIMB;
        }
    }
    if (next > PHASE_TAKEOFF) {
        if (myprops.systems.pressurization.automatic.conditions.wow.getBoolValue()) {
            next = PHASE_TAXI_IN;
        }
    }
    if (next == PHASE_TAXI_IN) {
        if (!(myprops.systems.pressurization.automatic.conditions.enginesRunning.getBoolValue()) or
            !(myprops.systems.pressurization.automatic.conditions.doorsClosed.getBoolValue())) {
            next = PHASE_GROUND;
        }
    }
    if (next != current) {
        printf("%s -> %s", getFlightPhaseName(current), getFlightPhaseName(next));
        myprops.systems.pressurization.automatic.flightPhase.setValue(next);
    }
    updateTargets();
};

var targetFuncs = [
    # PHASE_GROUND:
    func {
        myprops.systems.pressurization.targets.diffPsi.setValue(-0.01);
        myprops.systems.pressurization.targets.type.setValue(TARGET_DIFF);
        myprops.systems.pressurization.targets.rateMinFpm.setValue(-300);
        myprops.systems.pressurization.targets.rateMaxFpm.setValue(500);
    },

    # PHASE_TAXI_OUT:
    func {
        myprops.systems.pressurization.targets.diffPsi.setValue(0.11);
        myprops.systems.pressurization.targets.type.setValue(TARGET_DIFF);
        myprops.systems.pressurization.targets.rateMinFpm.setValue(-300);
        myprops.systems.pressurization.targets.rateMaxFpm.setValue(300);
    },

    # PHASE_TAKEOFF:
    func {
        myprops.systems.pressurization.targets.diffPsi.setValue(0.15);
        myprops.systems.pressurization.targets.type.setValue(TARGET_DIFF);
        myprops.systems.pressurization.targets.rateMinFpm.setValue(-400);
        myprops.systems.pressurization.targets.rateMaxFpm.setValue(500);
    },

    # PHASE_CLIMB:
    func {
        if (myprops.systems.pressurization.automatic.profile.cruiseAltFromFms.getBoolValue()) {
            var cruiseAlt = myprops.systems.pressurization.automatic.profile.cruiseAlt.getValue();
            if (cruiseAlt < 37000) {
                myprops.systems.pressurization.targets.diffPsi.setValue(7.8);
                myprops.systems.pressurization.targets.cabinAltFt.setValue(7000 * cruiseAlt / 37000);
                myprops.systems.pressurization.targets.referenceAltFt.setValue(cruiseAlt);
                myprops.systems.pressurization.targets.type.setValue(TARGET_ALT_BY);
            }
            else {
                myprops.systems.pressurization.targets.diffPsi.setValue(8.4);
                myprops.systems.pressurization.targets.cabinAltFt.setValue(8000);
                myprops.systems.pressurization.targets.referenceAltFt.setValue(cruiseAlt);
                myprops.systems.pressurization.targets.type.setValue(TARGET_ALT_BY);
            }
            myprops.systems.pressurization.targets.rateMinFpm.setValue(-600);
            myprops.systems.pressurization.targets.rateMaxFpm.setValue(750);
        }
        else {
            # diff and reference are not actually used, the MATCH_ALT
            # controller selects suitable values as the aircraft climbs.
            myprops.systems.pressurization.targets.diffPsi.setValue(8.4);
            myprops.systems.pressurization.targets.referenceAltFt.setValue(41000);
            myprops.systems.pressurization.targets.type.setValue(TARGET_MATCH_ALT);
        }
    },

    # PHASE_CRUISE:
    func {
        if (myprops.systems.pressurization.automatic.profile.cruiseAltFromFms.getBoolValue()) {
            var cruiseAlt = myprops.systems.pressurization.automatic.profile.cruiseAlt.getValue();
            if (cruiseAlt < 37000) {
                myprops.systems.pressurization.targets.diffPsi.setValue(7.8);
                myprops.systems.pressurization.targets.cabinAltFt.setValue(7000);
                myprops.systems.pressurization.targets.referenceAltFt.setValue(cruiseAlt);
                myprops.systems.pressurization.targets.type.setValue(TARGET_ALT);
            }
            else {
                myprops.systems.pressurization.targets.diffPsi.setValue(8.4);
                myprops.systems.pressurization.targets.cabinAltFt.setValue(8000);
                myprops.systems.pressurization.targets.referenceAltFt.setValue(cruiseAlt);
                myprops.systems.pressurization.targets.type.setValue(TARGET_ALT);
            }
        }
        else {
            # diff and reference are not actually used, the MATCH_ALT
            # controller selects suitable values as the aircraft climbs.
            myprops.systems.pressurization.targets.diffPsi.setValue(8.4);
            myprops.systems.pressurization.targets.referenceAltFt.setValue(41000);
            myprops.systems.pressurization.targets.type.setValue(TARGET_MATCH_ALT);
        }
        myprops.systems.pressurization.targets.rateMinFpm.setValue(-300);
        myprops.systems.pressurization.targets.rateMaxFpm.setValue(500);
    },

    # PHASE_DESCENT:
    func {
        var lfe = myprops.systems.pressurization.pressures.lfeFt.getValue();
        myprops.systems.pressurization.targets.diffPsi.setValue(0.0);
        myprops.systems.pressurization.targets.cabinAltFt.setValue(lfe);
        myprops.systems.pressurization.targets.referenceAltFt.setValue(lfe);
        myprops.systems.pressurization.targets.type.setValue(TARGET_ALT_BY);
        myprops.systems.pressurization.targets.rateMinFpm.setValue(-750);
        myprops.systems.pressurization.targets.rateMaxFpm.setValue(-200);
    },

    # PHASE_ABORT:
    func {
        var lfe = myprops.systems.pressurization.pressures.lfeFt.getValue();
        myprops.systems.pressurization.targets.diffPsi.setValue(0.0);
        myprops.systems.pressurization.targets.cabinAltFt.setValue(lfe);
        myprops.systems.pressurization.targets.referenceAltFt.setValue(lfe);
        myprops.systems.pressurization.targets.type.setValue(TARGET_ALT_BY);
        myprops.systems.pressurization.targets.rateMinFpm.setValue(-750);
        myprops.systems.pressurization.targets.rateMaxFpm.setValue(300);
    },

    # PHASE_TAXI_IN:
    func {
        myprops.systems.pressurization.targets.diffPsi.setValue(-0.01);
        myprops.systems.pressurization.targets.type.setValue(TARGET_DIFF);
        myprops.systems.pressurization.targets.rateMinFpm.setValue(-300);
        myprops.systems.pressurization.targets.rateMaxFpm.setValue(500);
    },
];

var updateTargets = func {
    var phase = myprops.systems.pressurization.automatic.flightPhase.getValue();
    if (phase < PHASE_GROUND or phase > PHASE_TAXI_IN) {
        printf("INVALID PHASE: %i", phase);
        return;
    }
    var update = targetFuncs[phase];
    if (update != nil)
        update();
};

var updateProfile = func {
    var cruiseAlt = myprops.autopilot.routeManager.cruise.altitudeFt.getValue();
    if (cruiseAlt > 0) {
        myprops.systems.pressurization.automatic.profile.cruiseAlt.setValue(cruiseAlt);
        myprops.systems.pressurization.automatic.profile.cruiseAltFromFms.setBoolValue(1);
    }
    else {
        myprops.systems.pressurization.automatic.profile.cruiseAltFromFms.setBoolValue(0);
    }

    var fp = flightplan();

    if (fp.departure != nil and fp.departure.elevation != nil) {
        myprops.systems.pressurization.automatic.profile.takeoffAlt.setValue(fp.departure.elevation);
        myprops.systems.pressurization.automatic.profile.takeoffAltFromFms.setBoolValue(1);
    }
    else {
        myprops.systems.pressurization.automatic.profile.takeoffAltFromFms.setBoolValue(0);
    }
    if (fp.destination != nil and fp.destination.elevation != nil) {
        myprops.systems.pressurization.automatic.profile.landingAlt.setValue(fp.destination.elevation);
        myprops.systems.pressurization.automatic.profile.landingAltFromFms.setBoolValue(1);
    }
    else {
        myprops.systems.pressurization.automatic.profile.landingAltFromFms.setBoolValue(0);
    }

    updateLFE();
    updateTargets();
};

var updateLFE = func {
    var mode = myprops.controls.pressurization.mode.getValue();
    if (mode == MODE_AUTO) {
        if (myprops.systems.pressurization.automatic.profile.landingAltFromFms.getBoolValue()) {
            myprops.systems.pressurization.pressures.lfeFt.setValue(
                myprops.systems.pressurization.automatic.profile.landingAlt.getValue());
            myprops.systems.pressurization.pressures.lfeFromFms.setBoolValue(1);
        }
    }
    else {
        myprops.systems.pressurization.pressures.lfeFromFms.setBoolValue(0);
    }
};

var initialize = func {
    if (initListener != nil) {
        removelistener(initListener);
        initListener = nil;
    }
    updateFlightPhase(nil);
    foreach (var k; keys(myprops.systems.pressurization.automatic.conditions)) {
        var p = myprops.systems.pressurization.automatic.conditions[k];
        setlistener(p, updateFlightPhase, 0, 0);
    }
    setlistener(myprops.autopilot.routeManager.cruise.altitudeFt, updateProfile, 1, 0);
    setlistener(myprops.autopilot.routeManager.signals.edited, updateProfile, 0, 0);
    setlistener(myprops.controls.pressurization.mode, updateLFE, 1, 0);
};

initListener = setlistener('/sim/signals/fdm-initialized', initialize);
