# AOM 14-09-20 / p. 1859: IRS
# AOM 2-56 / p. 109: INERTIAL REFERENCE SYSTEM (alignment time, latitude limits)

var STATUS_OFF = 0;
var STATUS_NO_REFERENCE = -2;
var STATUS_ALIGNING = -1;
var STATUS_READY = 1;

var alignmentTimerDelta = 10.0;

var calcAlignmentTime = func (latDeg) {
    latDeg = math.abs(latDeg);
    if (latDeg < 60)
        # curved progression from 5 minutes to 10 minutes
        return 300 + math.pow(latDeg / 60, 3.5) * 300;
    elsif (latDeg < 70)
        # 10 minutes
        return 600;
    else
        # 17 minutes
        return 1020;
};

var IRU = {
    new: func(number) {
        var rootProp = props.globals.getNode('/instrumentation/iru[' ~ number ~ ']', 1);
        var elecRootProp = props.globals.getNode('/systems/electrical/outputs/iru[' ~ number ~ ']', 1);
        return {
            parents: [IRU],
            number: number,
            props: {
                root: rootProp,
                
                elecPwr1: elecRootProp.getNode('pwr[0]', 1),
                elecPwr2: elecRootProp.getNode('pwr[1]', 1),
                powered: rootProp.getNode('powered', 1),

                pitchDeg: rootProp.getNode('outputs/pitch-deg', 1),
                rollDeg: rootProp.getNode('outputs/roll-deg', 1),
                headingDeg: rootProp.getNode('outputs/heading-deg', 1),
                trueHeadingDeg: rootProp.getNode('outputs/true-heading-deg', 1),
                latitudeDeg: rootProp.getNode('outputs/latitude-deg', 1),
                longitudeDeg: rootProp.getNode('outputs/longitude-deg', 1),
                outputsValid: rootProp.getNode('outputs/valid', 1),

                referenceValid: rootProp.getNode('reference/valid', 1),
                latitudeReferenceDeg: rootProp.getNode('reference/latitude-deg', 1),
                longitudeReferenceDeg: rootProp.getNode('reference/longitude-deg', 1),

                pitchErrorDeg: rootProp.getNode('error/pitch-deg', 1),
                rollErrorDeg: rootProp.getNode('error/roll-deg', 1),
                headingErrorDeg: rootProp.getNode('error/heading-deg', 1),
                trueHeadingErrorDeg: rootProp.getNode('error/true-heading-deg', 1),
                latitudeErrorDeg: rootProp.getNode('error/latitude-deg', 1),
                longitudeErrorDeg: rootProp.getNode('error/longitude-deg', 1),

                alignmentMode: props.globals.getNode('options/instrumentation/iru-alignment-mode'),
                alignmentCounter: rootProp.getNode('alignment/counter', 1),
                alignmentTime: rootProp.getNode('alignment/time', 1),
                alignmentTimeRemaining: rootProp.getNode('alignment/time-remaining', 1),
                alignmentStatus: rootProp.getNode('alignment/status', 1),
                alignmentAligning: rootProp.getNode('alignment/aligning', 1),

                signalsExcessiveMotion: rootProp.getNode('signals/excessive-motion', 1),
                signalsAligning: rootProp.getNode('signals/aligning', 1),

                groundSpeedReal: props.globals.getNode('velocities/groundspeed-kt'),
                latitudeDegReal: props.globals.getNode('position/latitude-deg'),
                longitudeDegReal: props.globals.getNode('position/longitude-deg'),
            },
            listeners: [],
            timers: [],
            initialized: 0,
        };
    },

    init: func {
        var self = me;
        if (me.initialized) return;
        me.initialized = 1;

        me.props.powered.setBoolValue(0);
        me.props.alignmentStatus.setIntValue(STATUS_OFF);
        me.props.alignmentTime.setValue(1020.0);
        me.props.alignmentCounter.setValue(0.0);
        me.props.signalsExcessiveMotion.setBoolValue(0);
        me.props.signalsAligning.setBoolValue(0);
        me.props.referenceValid.setBoolValue(0);

        var alignmentTimer = maketimer(alignmentTimerDelta, func { self.updateAlignment(alignmentTimerDelta); });
        alignmentTimer.simulatedTime = 1;
        alignmentTimer.start();
        append(me.timers, alignmentTimer);

        append(me.listeners, setlistener(me.props.elecPwr1, func { self.updatePower(); }, 1, 0));
        append(me.listeners, setlistener(me.props.elecPwr2, func { self.updatePower(); }, 1, 0));
        append(me.listeners, setlistener(me.props.powered, func { self.updateAlignment(0.0); }, 1, 0));
        append(me.listeners, setlistener(me.props.referenceValid, func { self.updateAlignment(0.0); }, 1, 0));
        append(me.listeners, setlistener(me.props.alignmentStatus, func (node) {
                self.props.signalsAligning.setBoolValue(node.getValue() == STATUS_ALIGNING);
            }, 1, 0));
        append(me.listeners, setlistener('/fms/radio/position-loaded[0]', func (node) {
                if (node.getBoolValue()) {
                    self.setReference(
                        "/position/latitude-deg",
                        "/position/longitude-deg");
                }
            }, 1, 0));
        append(me.listeners, setlistener('/fms/radio/position-loaded[2]', func (node) {
                if (node.getBoolValue()) {
                    self.setReference(
                        "/instrumentation/gps/indicated-latitude-deg",
                        "/instrumentation/gps/indicated-longitude-deg");
                }
            }, 1, 0));
    },

    teardown: func {
        foreach (var timer; me.timers) {
            timer.stop();
        }
        me.timers = [];
        foreach (var listener; me.listeners) {
            removelistener(listener);
        }
        me.listeners = [];
        me.initialized = 0;
    },

    updatePower: func {
        var pwr1 = me.props.elecPwr1.getValue() or 0.0;
        var pwr2 = me.props.elecPwr2.getValue() or 0.0;
        me.props.powered.setBoolValue(pwr1 + pwr2 > 18.0);
    },

    updateAlignment: func (delta = 0) {
        var status = me.props.alignmentStatus.getValue();
        var powered = me.props.powered.getBoolValue();
        if (status == STATUS_OFF or status == STATUS_NO_REFERENCE) {
            me.props.signalsExcessiveMotion.setBoolValue(0);
            if (powered) {
                me.restartAlignment();
            }
        }
        elsif (status == STATUS_ALIGNING) {
            if (!powered) {
                # Loss of power, alignment lost
                me.props.signalsExcessiveMotion.setBoolValue(0);
                me.resetAlignment();
            }
            elsif ((me.props.groundSpeedReal.getValue() or 0.0) > 0.1) {
                # Moving
                me.restartAlignment();
                me.props.signalsExcessiveMotion.setBoolValue(1);
            }
            elsif (!me.props.referenceValid.getBoolValue()) {
                # Reference invalid
                me.restartAlignment();
                me.props.signalsExcessiveMotion.setBoolValue(0);
            }
            else {
                me.stepAlignment(delta);
                me.props.signalsExcessiveMotion.setBoolValue(0);
            }
        }
        elsif (status == STATUS_READY) {
            if (!powered) {
                me.resetAlignment();
                me.props.signalsExcessiveMotion.setBoolValue(0);
            }
        }
    },

    setReference: func (latprop, lonprop) {
        var powered = me.props.powered.getBoolValue();
        var lat = getprop(latprop);
        var lon = getprop(lonprop);
        if (lat == nil or lon == nil) {
            me.props.referenceValid.setBoolValue(0);
        }
        else {
            me.props.latitudeReferenceDeg.setValue(lat);
            me.props.longitudeReferenceDeg.setValue(lon);
            me.props.referenceValid.setBoolValue(1);
        }
        if (powered) {
            me.restartAlignment();
        }
        else {
            me.resetAlignment();
        }
    },


    restartAlignment: func {
        me.props.alignmentCounter.setValue(0);
        if (!me.props.referenceValid.getBoolValue()) {
            me.props.alignmentStatus.setValue(STATUS_NO_REFERENCE);
        }
        else {
            var latitude = me.props.latitudeDegReal.getValue() or 0.0;
            var alignmentTime = calcAlignmentTime(latitude);
            me.props.alignmentTime.setValue(alignmentTime);
            me.props.alignmentTimeRemaining.setValue(alignmentTime);
            me.props.alignmentStatus.setValue(STATUS_ALIGNING);
        }
    },

    resetAlignment: func {
        me.props.alignmentCounter.setValue(0);
        me.props.alignmentStatus.setValue(STATUS_OFF);
    },

    stepAlignment: func (delta) {
        var counter = me.props.alignmentCounter.getValue();
        var time = me.props.alignmentTime.getValue();
        var mode = me.props.alignmentMode.getValue();
        if (mode == 'instant') {
            counter = time + delta;
        }
        elsif (mode == 'fast') {
            counter = counter + delta * 60;
        }
        else {
            counter = counter + delta;
        }
        me.props.alignmentCounter.setValue(counter);
        me.props.alignmentTimeRemaining.setValue(math.max(0.0, time - counter));
        if (counter >= time) {
            me.finishAlignment();
        }
    },

    finishAlignment: func {
        me.props.latitudeErrorDeg.setValue(
            me.props.latitudeReferenceDeg.getValue() -
            me.props.latitudeDegReal.getValue());
        me.props.longitudeErrorDeg.setValue(
            me.props.longitudeReferenceDeg.getValue() -
            me.props.longitudeDegReal.getValue());
        me.props.pitchErrorDeg.setValue(0.0);
        me.props.rollErrorDeg.setValue(0.0);
        me.props.headingErrorDeg.setValue(0.0);
        me.props.trueHeadingErrorDeg.setValue(0.0);
        me.props.alignmentStatus.setValue(STATUS_READY);
    },
};

var irus = [ IRU.new(0), IRU.new(1) ];

setlistener("sim/signals/fdm-initialized", func {
    foreach (var iru; irus) {
        iru.init();
    }
});
