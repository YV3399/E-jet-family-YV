var messages = {
    'warning': {},
    'caution': {},
    'advisory': {},
    'status': {},
};

var signalProp = props.globals.getNode('/instrumentation/eicas/signals/messages-changed');

var raiseSignal = func () { signalProp.setValue(1); }

var setMessage = func (level, message, priority) {
    messages[level][priority ~ ":" ~ message] = message;
    raiseSignal();
};

var clearMessage = func (level, message, priority) {
    delete(messages[level], priority ~ ":" ~ message);
    raiseSignal();
};

setlistener("sim/signals/fdm-initialized", func {
    #PARKING BRAKE
    setlistener("/controls/gear/brake-parking", func (node) {
        if (node.getBoolValue()) {
            setMessage('caution', 'PRK BRK NOT RELEASED', 0);
        }
        else {
            clearMessage('caution', 'PRK BRK NOT RELEASED', 0);
        }
    }, 1, 0);

    #ENG 1 FAIL (Shutdown)
    setlistener("/engines/engine[0]/running", func (node) {
        if (!node.getBoolValue()) {
            setMessage('caution', 'ENG 1 FAIL', 0);
        }
        else {
            clearMessage('caution', 'ENG 1 FAIL', 0);
        }
    }, 1, 0);

    #ENG 2 FAIL (Shutdown)
    setlistener("/engines/engine[1]/running", func (node) {
        if (!node.getBoolValue()) {
            setMessage('caution', 'ENG 2 FAIL', 0);
        }
        else {
            clearMessage('caution', 'ENG 2 FAIL', 0);
        }
    }, 1, 0);

    #BRAKE OVERHEAT
    setlistener("/gear/brake-overheat", func (node) {
        if (node.getBoolValue()) {
            setMessage('caution', 'BRK OVERHEAT', 0);
        }
        else {
            clearMessage('caution', 'BRK OVERHEAT', 0);
        }
    }, 1, 0);
});
