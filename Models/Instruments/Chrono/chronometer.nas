# E-jet-family EICAS by D-ECHO based on
# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

#sources: http://www.smartcockpit.com/docs/Embraer_190-Powerplant.pdf http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf http://www.smartcockpit.com/docs/Embraer_190-APU.pdf

var ED_only = nil;
var chrono_display = nil;
var page = "only";
var DC=0.01744;
var started = 0;
var stop=0;

setprop("/gear/gear[2]/wow", 1);
setprop("/systems/electrical/outputs/clock", 0);

var roundToNearest = func(n, m) {
	var x = int(n/m)*m;
	if((math.mod(n,m)) > (m/2) and n > 0)
			x = x + m;
	if((m - (math.mod(n,m))) > (m/2) and n < 0)
			x = x - m;
	return x;
}

var Chronometer = {
	new: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			if (family == "Arial") {
				return "DSEG/DSEG7/Classic/DSEG7Classic-Bold.ttf";
			}
            else{
				return "LiberationFonts/LiberationSans-Regular.ttf";
			}
		};

		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

        var svg_keys = [
                "UTC.hrmo",
                "UTC.mindy",
                "UTC.secy",
                "chrono.min",
                "chrono.sec",
                "et.hr",
                "et.min",
            ];
		 
        foreach (var key; svg_keys) {
            me[key] = canvas_group.getElementById(key);
        }

		me.page = canvas_group;

        me.props = {
            powered: props.globals.getNode('instrumentation/chrono/powered', 1),
            et: {
                total: props.globals.getNode('instrumentation/chrono/elapsed_time/total', 1),
                sec: props.globals.getNode('instrumentation/chrono/elapsed_time/sec', 1),
                min: props.globals.getNode('instrumentation/chrono/elapsed_time/min', 1),
                hr: props.globals.getNode('instrumentation/chrono/elapsed_time/hr', 1),
                reset: props.globals.getNode('instrumentation/chrono/elapsed_time/reset', 1),
                running: props.globals.getNode('instrumentation/chrono/chrono/running', 1),
            },
            chrono: {
                total: props.globals.getNode('instrumentation/chrono/chrono/total', 1),
                sec: props.globals.getNode('instrumentation/chrono/chrono/sec', 1),
                min: props.globals.getNode('instrumentation/chrono/chrono/min', 1),
                reset: props.globals.getNode('instrumentation/chrono/chrono/reset', 1),
                start: props.globals.getNode('instrumentation/chrono/chrono/start', 1),
                running: props.globals.getNode('instrumentation/chrono/chrono/running', 1),
            },
            utc: {
                hour: props.globals.getNode('sim/time/utc/hour', 1),
                minute: props.globals.getNode('sim/time/utc/minute', 1),
                second: props.globals.getNode('sim/time/utc/second', 1),
            },
        };
        me.props.powered.setBoolValue(0);
        me.props.et.total.setIntValue(0);
        me.props.et.sec.setIntValue(0);
        me.props.et.min.setIntValue(0);
        me.props.et.hr.setIntValue(0);
        me.props.et.reset.setBoolValue(0);
        me.props.et.running.setBoolValue(0);
        me.props.chrono.total.setIntValue(0);
        me.props.chrono.sec.setIntValue(0);
        me.props.chrono.min.setIntValue(0);
        me.props.chrono.reset.setBoolValue(0);
        me.props.chrono.running.setBoolValue(0);

        me.timers = {
            chrono: maketimer(1, func { me.tickChrono(); }),
            et: maketimer(1, func { me.tickET(); }),
        };
        me.timers.chrono.simulatedTime = 1;
        me.timers.et.simulatedTime = 1;

        me.listeners = [];
        me.powerOff();
        me.powerListener = setlistener('systems/electrical/outputs/clock', func (node) {
            var value = node.getValue();
            if (value >= 15) {
                if (!me.props.powered.getBoolValue())
                    me.powerOn();
            }
            else {
                if (me.props.powered.getBoolValue())
                    me.powerOff();
            }
        }, 1, 0);

		return me;
	},

    powerOn: func {
        var self = me;
        me.props.powered.setBoolValue(1);
        append(me.listeners, setlistener(me.props.chrono.start, func (node) { if (!node.getBoolValue()) self.toggleChrono(); }, 0, 0));
        append(me.listeners, setlistener(me.props.chrono.reset, func (node) { if (!node.getBoolValue()) self.resetChrono(); }, 0, 0));
        append(me.listeners, setlistener(me.props.et.reset, func { if (!self.props.et.running.getBoolValue()) self.resetET(); }, 0, 0));
        append(me.listeners, setlistener('gear/gear[1]/wow', func (node) {
            if (node.getBoolValue())
                self.stopET();
            else
                self.startET();
        }, 0, 0));
        append(me.listeners, setlistener(me.props.utc.second, func (node) { self["UTC.secy"].setText(sprintf("%02d", node.getValue())); }, 1, 0));
        append(me.listeners, setlistener(me.props.utc.minute, func (node) { self["UTC.mindy"].setText(sprintf("%02d", node.getValue())); }, 1, 0));
        append(me.listeners, setlistener(me.props.utc.hour, func (node) { self["UTC.hrmo"].setText(sprintf("%02d", node.getValue())); }, 1, 0));
        append(me.listeners, setlistener(me.props.chrono.sec, func (node) { self["chrono.sec"].setText(sprintf("%02d", node.getValue())); }, 1, 0));
        append(me.listeners, setlistener(me.props.chrono.min, func (node) { self["chrono.min"].setText(sprintf("%02d", node.getValue())); }, 1, 0));
        append(me.listeners, setlistener(me.props.et.hr, func (node) { self["et.hr"].setText(sprintf("%02d", node.getValue())); }, 1, 0));
        append(me.listeners, setlistener(me.props.et.min, func (node) { self["et.min"].setText(sprintf("%02d", node.getValue())); }, 1, 0));
        me.page.show();
    },

    powerOff: func {
        me.props.powered.setBoolValue(0);
        me.stopChrono();
        me.stopET();
        foreach (var l; me.listeners) {
            removelistener(l);
        }
        me.listeners = [];
        me.page.hide();
    },

    startChrono: func {
        if (me.props.powered.getBoolValue()) {
            me.timers.chrono.start();
            me.props.chrono.running.setBoolValue(1);
        }
    },

    stopChrono: func {
        me.timers.chrono.stop();
        me.props.chrono.running.setBoolValue(0);
    },

    toggleChrono: func {
        if (me.props.chrono.running.getBoolValue()) {
            me.stopChrono();
        }
        else {
            me.startChrono();
        }
    },

    resetChrono: func {
        if (!me.props.chrono.running.getBoolValue()) {
            me.props.chrono.total.setValue(0);
            me.props.chrono.sec.setValue(0);
            me.props.chrono.min.setValue(0);
        }
    },

    tickChrono: func {
        var total = me.props.chrono.total.getValue() + 1;
        me.props.chrono.total.setValue(total);
        me.props.chrono.sec.setValue(math.mod(total, 60.0));
        me.props.chrono.min.setValue(math.floor(total / 60.0));
    },

    startET: func {
        if (me.props.powered.getBoolValue()) {
            me.timers.et.start();
            me.props.et.running.setBoolValue(1);
        }
    },

    stopET: func {
        me.timers.et.stop();
        me.props.et.running.setBoolValue(0);
    },

    resetET: func {
        me.props.et.total.setValue(0);
        me.props.et.sec.setValue(0);
        me.props.et.min.setValue(0);
        me.props.et.hr.setValue(0);
    },

    tickET: func {
        var total = me.props.et.total.getValue() + 1;
        me.props.et.total.setValue(total);
        me.props.et.sec.setValue(math.mod(total, 60.0));
        me.props.et.min.setValue(math.mod(math.floor(total / 60.0), 60.0));
        me.props.et.hr.setValue(math.floor(total / 3600.0));
    },
};

var initialized = 0;

var init = func {
    if (initialized)
        return;
    else
        initialized = 1;
	chrono_display = canvas.new({
		"name": "Chrono",
		"size": [1024, 1530],
		"view": [1024, 1530],
		"mipmapping": 1
	});
	chrono_display.addPlacement({"node": "chrono_screen"});
	var groupED = chrono_display.createGroup();

	ed = Chronometer.new(groupED, "Aircraft/E-jet-family/Models/Instruments/Chrono/chronometer.svg");
};

setlistener("sim/signals/fdm-initialized", init);

var showChrono= func {
	var dlg = canvas.Window.new([512, 765], "dialog").set("resize", 1);
	dlg.setCanvas(chrono_display);
}
