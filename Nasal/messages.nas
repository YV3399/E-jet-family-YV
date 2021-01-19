var MSG_WARNING = 4;
var MSG_CAUTION = 3;
var MSG_ADVISORY = 2;
var MSG_STATUS = 1;
var MSG_MAINTENANCE = 0;

var signalProp = props.globals.getNode('/instrumentation/eicas/signals/messages-changed');
var blinkProp = props.globals.getNode('/instrumentation/eicas/blink-state');
var masterCautionProp = props.globals.getNode('/instrumentation/eicas/master/caution');
var masterWarningProp = props.globals.getNode('/instrumentation/eicas/master/warning');

var raiseSignal = func () { signalProp.setValue(1); }

var messages = [];

var compare = func (a, b) {
    if (a == b) return 0;
    if (a < b) return -1;
    if (a > b) return 1;
    die("OH TEH NOES");
};

var compareMessages = func (a, b) {
    if (a.level != b.level) return compare(b.level, a.level);
    if (a.priority != b.priority) return compare(b.priority, a.priority);
    return cmp(a.text, b.text);
};

var sortMessages = func () {
    messages = sort(messages, compareMessages);
};

var setMessage = func (level, text, priority) {
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
    var msg = { level: level, text: text, priority: priority, blink: blink };
    append(messages, msg);
    sortMessages();
    raiseSignal();
};

var clearMessage = func (level, text, priority) {
    var newMessages = [];
    foreach (var msg; messages) {
        if (msg.text != text or msg.level != level) {
            append(newMessages, msg);
        }
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

    var listenOnProp = func (prop, cond, level, text, priority) {
        setlistener(prop, func(node) {
            if (cond(node.getValue())) {
                setMessage(level, text, priority);
            }
            else {
                clearMessage(level, text, priority);
            }
        }, 1, 0);
    };

    var yes = func (val) { return !!val; }
    var no = func (val) { return !val; }

    listenOnProp("/controls/gear/brake-parking", yes, MSG_CAUTION, 'PRK BRK NOT REL', 0);
    listenOnProp("/engines/engine[0]/running", no, MSG_CAUTION, 'ENG 1 FAIL', 0);
    listenOnProp("/engines/engine[1]/running", no, MSG_CAUTION, 'ENG 2 FAIL', 0);
    listenOnProp("/gear/brake-overheat", yes, MSG_CAUTION, 'BRK OVERHEAT', 0);
    listenOnProp("/instrumentation/eicas/messages/xpdr-stby", yes, MSG_CAUTION, 'XPDR 1 IN STBY', 0);
    listenOnProp("/instrumentation/eicas/messages/fuel-imbalance", yes, MSG_CAUTION, 'FUEL IMBALANCE', 0);
    listenOnProp("/instrumentation/eicas/messages/fuel-low-left", yes, MSG_WARNING, 'FUEL 1 LO LEVEL', 10);
    listenOnProp("/instrumentation/eicas/messages/fuel-low-right", yes, MSG_WARNING, 'FUEL 2 LO LEVEL', 10);
    listenOnProp("/instrumentation/eicas/messages/doors/l1/open", yes, MSG_WARNING, 'DOOR PAX FWD OPEN', 0);
    listenOnProp("/instrumentation/eicas/messages/doors/l2/open", yes, MSG_WARNING, 'DOOR PAX AFT OPEN', 0);
    listenOnProp("/instrumentation/eicas/messages/doors/r1/open", yes, MSG_WARNING, 'DOOR SERV FWD OPEN', 0);
    listenOnProp("/instrumentation/eicas/messages/doors/r2/open", yes, MSG_WARNING, 'DOOR SERV AFT OPEN', 0);
});
