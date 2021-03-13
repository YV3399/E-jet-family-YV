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

setprop("/engines/engine[0]/n1", 0);
setprop("/engines/engine[1]/n1", 0);
setprop("/engines/engine[0]/n2", 0);
setprop("/engines/engine[1]/n2", 0);
setprop("/engines/engine[0]/itt_degc", 0);
setprop("/engines/engine[1]/itt_degc", 0);
setprop("/engines/engine[0]/oil-pressure-psi", 0);
setprop("/MFD/oil-pressure-needle[0]", 0);
setprop("/engines/engine[1]/oil-pressure-psi", 0);
setprop("/MFD/oil-pressure-needle[1]", 0);
setprop("/engines/engine[0]/oil-temperature-degc", 0);
setprop("/MFD/oil-temperature-needle[0]", 0);
setprop("/engines/engine[1]/oil-temperature-degc", 0);
setprop("/MFD/oil-temperature-needle[1]", 0);
setprop("/engines/engine[0]/fuel-flow_pph", 0);
setprop("/engines/engine[1]/fuel-flow_pph", 0);
setprop("/engines/engine[0]/reverser-pos-norm", 0);
setprop("/engines/engine[1]/reverser-pos-norm", 0);
setprop("/consumables/fuel/tank[0]/temperature-degc", 0);
setprop("/consumables/fuel/tank[1]/temperature-degc", 0);
setprop("/controls/engines/engine[0]/condition-lever-state", 0);
setprop("/controls/engines/engine[1]/condition-lever-state", 0);
setprop("/controls/engines/engine[0]/throttle-int", 0);
setprop("/controls/engines/engine[1]/throttle-int", 0);
setprop("/test", 0);
setprop("instrumentation/airspeed-indicator/indicated-speed-deg-2", 0);
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

var canvas_ED_base = {
	init: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			if (family == "Arial") {
				#return "7-Segment.ttf";
				return "LiberationFonts/LiberationSans-Regular.ttf";
			}else{
				return "LiberationFonts/LiberationSans-Regular.ttf";
			}
		};
		


		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		 var svg_keys = me.getKeys();
		 
		foreach(var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var svg_keys = me.getKeys();
			foreach (var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			}
		}
		

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		if (getprop("systems/electrical/outputs/clock") >= 15) {
				ED_only.page.show();
		} else {
			ED_only.page.hide();
		}
		
		settimer(func me.update(), 0.02);
	},
};

var canvas_ED_only = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_ED_only,canvas_ED_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["UTC.hrmo","UTC.mindy","UTC.secy","chrono.min","chrono.sec"];
	},
	update: func() {
		me["UTC.hrmo"].setText(sprintf("%02d", getprop("/sim/time/utc/hour") or 0));
		me["UTC.mindy"].setText(sprintf("%02d", getprop("/sim/time/utc/minute") or 0));
		me["UTC.secy"].setText(sprintf("%02d", getprop("/sim/time/utc/second") or 0));
		
		me["chrono.min"].setText(sprintf("%02d", getprop("/instrumentation/chrono/elapsed_time/minute") or 0));
		me["chrono.sec"].setText(sprintf("%02d", getprop("/instrumentation/chrono/elapsed_time/second") or 0));
		
		settimer(func me.update(), 0.02);
	},
};

setlistener("sim/signals/fdm-initialized", func {
	chrono_display = canvas.new({
		"name": "Chrono",
		"size": [1024, 1530],
		"view": [1024, 1530],
		"mipmapping": 1
	});
	chrono_display.addPlacement({"node": "chrono_screen"});
	var groupED = chrono_display.createGroup();

	ED_only = canvas_ED_only.new(groupED, "Aircraft/E-jet-family/Models/Instruments/Chrono/chronometer.svg");

	ED_only.update();
	canvas_ED_base.update();
});

var showChrono= func {
	var dlg = canvas.Window.new([512, 765], "dialog").set("resize", 1);
	dlg.setCanvas(chrono_display);
}

var count_up = func{
	var total_time = (getprop("/instrumentation/chrono/elapsed_time/total") or 0) + 1;
	if(stop){
		total_time=0;
		started=0;
		stop=0;
	}else{
		settimer(count_up, 1);
	}
	var secs = math.mod(total_time,60);
	#var mins = math.mod(total_time/60,1);
	setprop("/instrumentation/chrono/elapsed_time/total", total_time);
	setprop("/instrumentation/chrono/elapsed_time/second", secs);
	#setprop("/instrumentation/chrono/elapsed_time/minute", mins);
}

setlistener("/gear/gear[2]/wow", func{
	if(getprop("/gear/gear[2]/wow")==0 and started==0){
		setprop("instrumentation/chrono/elapsed_time/total", 0);
		count_up();
		started=1;
	}
});

setlistener("/instrumentation/chrono/elapsed_time/reset", func{
	if((getprop("/instrumentation/chrono/elapsed_time/reset") or 0)==1 and (getprop("/gear/gear[2]/wow") or 0) ==1){
		stop=1;
		count_up();
	}
});
	
