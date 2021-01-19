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

var compareMessages = func (a, b) {
    if (a.level != b.level) return cmp(b.level, a.level);
    if (a.priority != b.priority) return cmp(b.priority, a.priority);
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
    debug.dump(msg);
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

    #PARKING BRAKE
    setlistener("/controls/gear/brake-parking", func (node) {
        if (node.getBoolValue()) {
            setMessage(MSG_CAUTION, 'PRK BRK NOT RELEASED', 0);
        }
        else {
            clearMessage(MSG_CAUTION, 'PRK BRK NOT RELEASED', 0);
        }
    }, 1, 0);

    #ENG 1 FAIL (Shutdown)
    setlistener("/engines/engine[0]/running", func (node) {
        if (!node.getBoolValue()) {
            setMessage(MSG_CAUTION, 'ENG 1 FAIL', 0);
        }
        else {
            clearMessage(MSG_CAUTION, 'ENG 1 FAIL', 0);
        }
    }, 1, 0);

    #ENG 2 FAIL (Shutdown)
    setlistener("/engines/engine[1]/running", func (node) {
        if (!node.getBoolValue()) {
            setMessage(MSG_CAUTION, 'ENG 2 FAIL', 0);
        }
        else {
            clearMessage(MSG_CAUTION, 'ENG 2 FAIL', 0);
        }
    }, 1, 0);

    #BRAKE OVERHEAT
    setlistener("/gear/brake-overheat", func (node) {
        if (node.getBoolValue()) {
            setMessage(MSG_CAUTION, 'BRK OVERHEAT', 0);
        }
        else {
            clearMessage(MSG_CAUTION, 'BRK OVERHEAT', 0);
        }
    }, 1, 0);
});
