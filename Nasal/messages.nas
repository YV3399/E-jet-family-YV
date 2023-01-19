# AOP p2165+

var MSG_WARNING = 4;
var MSG_CAUTION = 3;
var MSG_ADVISORY = 2;
var MSG_STATUS = 1;
var MSG_MAINTENANCE = 0;

var signalProp = props.globals.getNode('/instrumentation/eicas/signals/messages-changed');
var blinkProp = props.globals.getNode('/instrumentation/eicas/blink-state');
var masterCautionProp = props.globals.getNode('/instrumentation/eicas/master/caution');
var masterWarningProp = props.globals.getNode('/instrumentation/eicas/master/warning');
var simTimeProp = props.globals.getNode('/sim/time/elapsed-sec');

var raiseSignal = func () { signalProp.setValue(1); }

var messages = [];

var compare = func (a, b) {
    if (a == b) return 0;
    if (a < b) return -1;
    if (a > b) return 1;
    die("OH TEH NOES");
};

var compareMessages = func (a, b) {
    return compare(b.level, a.level)
        or compare(b.priority, a.priority)
        or compare(a.timestamp, a.timestamp)
        or cmp(a.text, b.text);
};

var sortMessages = func () {
    messages = sort(messages, compareMessages);
};

var setMessage = func (level, text, priority, rootEicas=0) {
    var blink = 0;
    if (level == MSG_ADVISORY) {
        blink = 11; # blink for ~5 seconds
    }
    else if (level > MSG_ADVISORY) {
        blink = 864000; # I can keep doing this all day long
    }
    if (level == MSG_WARNING) {
        masterWarningProp.setBoolValue(1);
    }
    if (level == MSG_CAUTION) {
        masterCautionProp.setBoolValue(1);
    }
    var msg = {
            level: level,
            text: text,
            priority: priority,
            blink: blink,
            timestamp: simTimeProp.getValue() or 0,
            rootEicas: rootEicas,
        };
    append(messages, msg);
    sortMessages();
    raiseSignal();
};

var clearMessage = func (level, text, priority) {
    var newMessages = [];
    var blinking = { MSG_WARNING: 0, MSG_CAUTION: 0 };
    foreach (var msg; messages) {
        if (msg.text != text or msg.level != level) {
            append(newMessages, msg);
            if (msg.blink) {
                blinking[msg.level] = 1;
            }
        }
    }
    if (!blinking[MSG_WARNING]) {
        masterWarningProp.setBoolValue(0);
    }
    if (!blinking[MSG_CAUTION]) {
        masterCautionProp.setBoolValue(0);
    }
    messages = newMessages;
    raiseSignal();
};

var clearBlinks = func (level) {
    foreach (var msg; messages) {
        if (msg.level == level) {
            msg.blink = 0;
        }
    }
};

var countdownBlinks = func (level) {
    foreach (var msg; messages) {
        if (msg.level == level and msg.blink > 0) {
            msg.blink = msg.blink - 1;
        }
    }
};

setlistener("sim/signals/fdm-initialized", func {
    blinkTimer = maketimer(0.5, func { blinkProp.toggleBoolValue(); });
    blinkTimer.simulatedTime = 1;
    blinkTimer.start();
    setlistener(blinkProp, func {
        countdownBlinks(MSG_ADVISORY);
    });
    setlistener(masterWarningProp, func (node) {
        if (!node.getBoolValue()) {
            clearBlinks(MSG_WARNING);
        }
    });
    setlistener(masterCautionProp, func (node) {
        if (!node.getBoolValue()) {
            clearBlinks(MSG_CAUTION);
        }
    });

    var listenOnProp = func (prop, cond, level, text, priority, rootEicas=0) {
        setlistener(prop, func(node) {
            if (cond(node.getValue())) {
                setMessage(level, text, priority, rootEicas);
            }
            else {
                clearMessage(level, text, priority);
            }
        }, 1, 0);
    };

    var yes = func (val) { return !!val; }
    var no = func (val) { return !val; }

    listenOnProp("/engines/engine[0]/running", no, MSG_CAUTION, 'ENG 1 FAIL', 0);
    listenOnProp("/engines/engine[1]/running", no, MSG_CAUTION, 'ENG 2 FAIL', 0);
    listenOnProp("/gear/brake-overheat", yes, MSG_CAUTION, 'BRK OVERHEAT', 0);
    listenOnProp("/instrumentation/eicas/messages/parking-brake", yes, MSG_CAUTION, 'PRK BRK NOT REL', 0);
    listenOnProp("/instrumentation/eicas/messages/xpdr-stby", yes, MSG_CAUTION, 'XPDR 1 IN STBY', 0);
    listenOnProp("/instrumentation/eicas/messages/fuel-imbalance", yes, MSG_CAUTION, 'FUEL IMBALANCE', 0);
    listenOnProp("/instrumentation/eicas/messages/fuel-low-left", yes, MSG_WARNING, 'FUEL 1 LO LEVEL', 10);
    listenOnProp("/instrumentation/eicas/messages/fuel-low-right", yes, MSG_WARNING, 'FUEL 2 LO LEVEL', 10);
    listenOnProp("/instrumentation/eicas/messages/fuel-equal-xfeed-open", yes, MSG_CAUTION, 'FUEL EQUAL - XFEED OPEN', 0);
    listenOnProp("/instrumentation/eicas/messages/doors/l1/open", yes, MSG_WARNING, 'DOOR PAX FWD OPEN', 0);
    listenOnProp("/instrumentation/eicas/messages/doors/l2/open", yes, MSG_WARNING, 'DOOR PAX AFT OPEN', 0);
    listenOnProp("/instrumentation/eicas/messages/doors/r1/open", yes, MSG_WARNING, 'DOOR SERV FWD OPEN', 0);
    listenOnProp("/instrumentation/eicas/messages/doors/r2/open", yes, MSG_WARNING, 'DOOR SERV AFT OPEN', 0);
    listenOnProp("/instrumentation/eicas/messages/electrical/emergency", yes, MSG_WARNING, 'ELEC EMERGENCY', 0, 1);
    listenOnProp("/instrumentation/eicas/messages/electrical/batteries-off", yes, MSG_WARNING, 'BATT 1-2 OFF', 0);
    listenOnProp("/instrumentation/eicas/messages/iru-excessive-motion", yes, MSG_CAUTION, 'IRS EXCESSIVE MOTION', 0);
    listenOnProp("/systems/electrical/sources/battery[0]/status", no, MSG_CAUTION, 'BATT 1 OFF', 0);
    listenOnProp("/systems/electrical/sources/battery[1]/status", no, MSG_CAUTION, 'BATT 2 OFF', 0);
    listenOnProp("/instrumentation/eicas/messages/electrical/external-power-connected", yes, MSG_CAUTION, 'GPU CONNECTED', 0);
    listenOnProp("/instrumentation/eicas/messages/electrical/idg1", yes, MSG_CAUTION, 'IDG 1 OFF', 0);
    listenOnProp("/instrumentation/eicas/messages/electrical/idg2", yes, MSG_CAUTION, 'IDG 2 OFF', 0);
    listenOnProp("/systems/electrical/buses/ac[1]/powered", no, MSG_CAUTION, 'AC BUS 1 OFF', 0, 1);
    listenOnProp("/systems/electrical/buses/ac[2]/powered", no, MSG_CAUTION, 'AC BUS 2 OFF', 0, 1);
    listenOnProp("/systems/electrical/buses/ac[3]/powered", no, MSG_CAUTION, 'AC ESS BUS OFF', 0, 1);
    listenOnProp("/systems/electrical/buses/ac[4]/powered", no, MSG_CAUTION, 'AC STBY BUS OFF', 0);
    listenOnProp("/systems/electrical/buses/dc[1]/powered", no, MSG_CAUTION, 'DC BUS 1 OFF', 0, 1);
    listenOnProp("/systems/electrical/buses/dc[2]/powered", no, MSG_CAUTION, 'DC BUS 2 OFF', 0, 1);
    listenOnProp("/systems/electrical/buses/dc[3]/powered", no, MSG_CAUTION, 'DC ESS BUS 1 OFF', 0, 1);
    listenOnProp("/systems/electrical/buses/dc[4]/powered", no, MSG_CAUTION, 'DC ESS BUS 2 OFF', 0, 1);
    listenOnProp("/systems/electrical/buses/dc[5]/powered", no, MSG_CAUTION, 'DC ESS BUS 3 OFF', 0, 1);
    listenOnProp("/instrumentation/iru[0]/outputs/valid-att", no, MSG_CAUTION, 'IRS 1 FAIL', 1);
    listenOnProp("/instrumentation/iru[1]/outputs/valid-att", no, MSG_CAUTION, 'IRS 2 FAIL', 1);
    listenOnProp("/instrumentation/iru[0]/outputs/valid", no, MSG_ADVISORY, 'IRS 1 NAV MODE FAIL', 1);
    listenOnProp("/instrumentation/iru[1]/outputs/valid", no, MSG_ADVISORY, 'IRS 2 NAV MODE FAIL', 1);
    listenOnProp("/instrumentation/iru[0]/signals/aligning", yes, MSG_ADVISORY, 'IRS 1 ALIGNING', 0);
    listenOnProp("/instrumentation/iru[1]/signals/aligning", yes, MSG_ADVISORY, 'IRS 2 ALIGNING', 0);
    listenOnProp("/instrumentation/iru[0]/reference/valid", no, MSG_ADVISORY, 'IRS 1 PRES POS INVALID', 0);
    listenOnProp("/instrumentation/iru[1]/reference/valid", no, MSG_ADVISORY, 'IRS 2 PRES POS INVALID', 0);
    listenOnProp("fdm/jsbsim/fcs/yaw-damper-enable", no, MSG_ADVISORY, 'YD OFF', 0);
    listenOnProp("fdm/jsbsim/gear/unit[0]/castered", yes, MSG_ADVISORY, 'STEER OFF', 0);
    listenOnProp("/instrumentation/eicas/messages/apu/shutdown", yes, MSG_STATUS, 'APU SHUTTING DOWN', 0);
    listenOnProp("/controls/flight/steep-approach", yes, MSG_STATUS, 'STEEP APPR', 0);
    listenOnProp("/cpdlc/unread", yes, MSG_STATUS, 'ATC UPLINK', 0);
    listenOnProp("/acars/telex/unread", yes, MSG_STATUS, 'ACARS MSG', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_WARNING, 'DEBUG WARN 1', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_WARNING, 'DEBUG WARN 2', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_WARNING, 'DEBUG WARN 3', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_WARNING, 'DEBUG WARN 4', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_WARNING, 'DEBUG WARN 5', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 1', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 2', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 3', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 4', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 5', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 6', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 7', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 8', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 9', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 10', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 11', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 12', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 13', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 14', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 15', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_CAUTION, 'DEBUG CAUTION 16', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 1', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 2', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 3', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 4', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 5', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 6', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 7', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 8', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 9', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 10', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 11', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 12', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 13', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 14', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 15', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_ADVISORY, 'DEBUG ADVISORY 16', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 1', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 2', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 3', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 4', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 5', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 6', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 7', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 8', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 9', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 10', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 11', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 12', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 13', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 14', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 15', 0);
    listenOnProp("/instrumentation/eicas/messages/debug", yes, MSG_STATUS, 'DEBUG STATUS 16', 0);
});
