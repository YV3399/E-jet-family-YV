var PHASE_PREFLIGHT = 0;
var PHASE_TAXI_OUT = 1;
var PHASE_AIRBORNE = 2;
var PHASE_TAXI_IN = 3;
var PHASE_FINISHED = 4;

var phaseprops = [
    nil,
    props.globals.getNode('fms/oooi/events/out'),
    props.globals.getNode('fms/oooi/events/off'),
    props.globals.getNode('fms/oooi/events/on'),
    props.globals.getNode('fms/oooi/events/in'),
];

var phasenames = [
    'PREFLIGHT',
    'OUT',
    'OFF',
    'ON',
    'IN'
];

var reset = func {
    foreach (var p; phaseprops) {
        if (p != nil)
            p.setValue('');
    }
};

reset();

var getETA4 = func {
    var time_secs = getprop("/fms/performance/destination/eta");
    if (time_secs == '') return '';
    var corrected = math.mod(time_secs, 86400);
    var hours = math.floor(corrected / 3600);
    var minutes = math.mod(math.floor(corrected / 60), 60);
    return sprintf("%02.0f%02.0f", hours, minutes);
};

var report = func {
    var departure = getprop('/autopilot/route-manager/departure/airport') or 'ZZZZ';
    var destination = getprop('/autopilot/route-manager/destination/airport') or 'ZZZZ';
    var items = [sprintf("%s/%s", departure, destination)];
    for (var phase = PHASE_TAXI_OUT; phase <= PHASE_FINISHED; phase += 1) {
        var what = phasenames[phase];
        var when = phaseprops[phase].getValue();
        if (when == '') {
            if (phase == PHASE_TAXI_IN) {
                # current phase is airborne, so append ETA
                var eta = getETA4();
                if (eta != '')
                    append(items, sprintf("ETA/%s", eta));
            }
            break;
        }
        append(items, sprintf("%s/%s", what, when));
    }
    var str = string.join(' ', items);
    setprop('fms/oooi/report', str);
    globals.acars.system.sendProgress(nil, str);
};

var recordEvent = func(what) {
    if (what == PHASE_PREFLIGHT) reset();
    var where = phaseprops[what];
    if (where != nil) {
        var when = sprintf("%02i%02i", getprop('/sim/time/utc/hour'), getprop('/sim/time/utc/minute'));
        where.setValue(when);
    }
    setprop('/fms/oooi/phase', what);
    report();
};

setlistener('fms/oooi/conditions/out', func (node) {
    if (node.getBoolValue()) { recordEvent(PHASE_TAXI_OUT); }
}, 1, 0);
setlistener('fms/oooi/conditions/off', func (node) {
    if (node.getBoolValue()) { recordEvent(PHASE_AIRBORNE); }
}, 1, 0);
setlistener('fms/oooi/conditions/on', func (node) {
    if (node.getBoolValue()) { recordEvent(PHASE_TAXI_IN); }
}, 1, 0);
setlistener('fms/oooi/conditions/in', func (node) {
    if (node.getBoolValue()) { recordEvent(PHASE_FINISHED); }
}, 1, 0);
