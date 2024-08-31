# E-jet-family EICAS by D-ECHO based on
# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

#sources: http://www.smartcockpit.com/docs/Embraer_190-Powerplant.pdf http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf http://www.smartcockpit.com/docs/Embraer_190-APU.pdf

var ED_only = nil;
var IESS_display = nil;
var page = "only";
var DC=0.01744;
var ILS_hidden = 0;

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
setprop("/controls/engines/engine[0]/condition-lever-state", 0);
setprop("/controls/engines/engine[1]/condition-lever-state", 0);
setprop("/controls/engines/engine[0]/throttle-int", 0);
setprop("/controls/engines/engine[1]/throttle-int", 0);
setprop("/test", 0);
setprop("instrumentation/airspeed-indicator/indicated-speed-deg-2", 0);

setprop("/systems/electrical/outputs/iess", 0);

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
			return "LiberationFonts/LiberationSans-Regular.ttf";
		};


		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		 var svg_keys = me.getKeys();
		 
		foreach(var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var svg_keys = me.getKeys();
			foreach (var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var clip_el = canvas_group.getElementById(key ~ "_clip");
			if (clip_el != nil) {
				clip_el.setVisible(0);
				var tran_rect = clip_el.getTransformedBounds();
				var clip_rect = sprintf("rect(%d,%d, %d,%d)", 
				tran_rect[1], # 0 ys
				tran_rect[2], # 1 xe
				tran_rect[3], # 2 ye
				tran_rect[0]); #3 xs
				#   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
				me[key].set("clip", clip_rect);
				me[key].set("clip-frame", canvas.Element.PARENT);
			}
			}
		}
		
		me.h_trans = me["horizon"].createTransform();
		me.h_rot = me["horizon"].createTransform();

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		if (getprop("systems/electrical/outputs/iess") >= 15) {
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
		return ["horizon","alt.tape","altTextLow1","altTextHigh1","alt.rollingdigits","asi.tape","asi.rollingdigits","asi.10","asi.100","turnind","slip","vmo_bar","qnh","ILS","mach_number","mach_unit","ILS.vd","ILS.hd","mach_decpoint","alt.10000","alt.1000","alt.100"];
	},
	update: func() {
		
		var pitch = (getprop("orientation/pitch-deg") or 0);
		var roll =  getprop("orientation/roll-deg") or 0;
		me.h_trans.setTranslation(0,pitch*17);
		me.h_rot.setRotation(-roll*DC,me["horizon"].getCenter());
		me["turnind"].setRotation(roll*-DC);
		me["slip"].setTranslation(math.round(getprop("/instrumentation/slip-skid-ball/indicated-slip-skid") or 0)*5, 0);
		
		var airspeed=getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
		var vmo=getprop("instrumentation/iess/vmo") or 0;
		var vmo_diff=vmo-320;
		me["asi.tape"].setTranslation(0,airspeed*7.96);
		me["vmo_bar"].setTranslation(0,-vmo_diff*7.96);
		me["asi.rollingdigits"].setTranslation(0,math.round((10*math.mod(airspeed/10,1))*36, 0.1));
		var asi10=getprop("/instrumentation/pfd/asi-10") or 0;
		if(asi10!=0){
			me["asi.10"].show();
			me["asi.10"].setText(sprintf("%s", math.round((10*math.mod(asi10/10,1)))));
		}else{
			me["asi.10"].hide();
		}
		var asi100=getprop("/instrumentation/pfd/asi-100") or 0;
		if(asi100!=0){
			me["asi.100"].show();
			me["asi.100"].setText(sprintf("%s", math.round(asi100)));
		}else{
			me["asi.100"].hide();
		}
		
		var mach=getprop("velocities/mach") or 0;
		if(mach>0.45){
			me["mach_number"].show();
			me["mach_decpoint"].show();
			me["mach_unit"].show();
			me["mach_number"].setText(sprintf("%s", int(10*math.mod(mach + 0.005,1))));
		}else{
			me["mach_number"].hide();
			me["mach_decpoint"].hide();
			me["mach_unit"].hide();
		}
		
		var alt=getprop("/instrumentation/altimeter[2]/indicated-altitude-ft") or 0;

		me["alt.tape"].setTranslation(0,(alt - roundToNearest(alt, 2000))*0.2343);
		if (roundToNearest(alt, 1000) == 0) {
			#me["altTextLowSmall1"].setText(sprintf("%0.0f",5));
			#me["altTextHighSmall2"].setText(sprintf("%0.0f",5));
			var altNumLow = "-1";
			var altNumHigh = "1";
		} elsif (roundToNearest(alt, 1000) > 0) {
			#me["altTextLowSmall1"].setText(sprintf("%0.0f",5));
			#me["altTextHighSmall2"].setText(sprintf("%0.0f",5));
			var altNumLow = (roundToNearest(alt, 1000)/1000 - 1);
			var altNumHigh = (roundToNearest(alt, 1000)/1000);
		} elsif (roundToNearest(alt, 1000) < 0) {
			#me["altTextLowSmall1"].setText(sprintf("%0.0f",5));
			#me["altTextHighSmall2"].setText(sprintf("%0.0f",5));
			var altNumLow = roundToNearest(alt, 1000)/100+5;
			var altNumHigh = (roundToNearest(alt, 1000)/1000 + 1) ;
		}
		if ( altNumLow == 0 ) {
			altNumLow = "";
		}
		if ( altNumHigh == 0 and alt < 0) {
			altNumHigh = "-";
		}
		
		var alt100=(getprop("/instrumentation/iess/alt-1") or 0)/100;
		
		me["alt.rollingdigits"].setTranslation(0,math.round((10*math.mod(alt100,1))*getprop("/test"), 0.1));
		
		me["altTextLow1"].setText(sprintf("%s", altNumLow));
		#me["altTextHigh1"].setText(sprintf("%s", altNumCenter));
		me["altTextHigh1"].setText(sprintf("%s", altNumHigh));
		
		me["qnh"].setText(sprintf("%u", (getprop("/instrumentation/altimeter[2]/setting-hpa") or 0)));
		
		var alt10000=getprop("/instrumentation/iess/alt-10000") or 0;
		if(alt10000!=0){
			me["alt.10000"].show();
			me["alt.10000"].setText(sprintf("%s", math.round(alt10000)));
		}else{
			me["alt.10000"].hide();
		}
		
		var alt1000=getprop("/instrumentation/iess/alt-1000") or 0;
		if(alt1000!=0){
			me["alt.1000"].show();
			me["alt.1000"].setText(sprintf("%s", math.round((10*math.mod(alt1000/10,1)))));
		}else{
			me["alt.1000"].hide();
		}
		
		var alt100=getprop("/instrumentation/iess/alt-100") or 0;
		if(alt100!=0){
			me["alt.100"].show();
			me["alt.100"].setText(sprintf("%s", math.round((10*math.mod(alt100/10,1)))));
		}else{
			me["alt.100"].hide();
		}

		var ils_shown=getprop("/instrumentation/IESS/ILS-ind") or 0;
		if(ils_shown==0 and ILS_hidden==0){
			me["ILS"].hide();
			ILS_hidden=1;
		}else if(ils_shown==1 and ILS_hidden==1){
			me["ILS"].show();
			ILS_hidden=0;
		}
		
		settimer(func me.update(), 0.02);
	},
};

setlistener("sim/signals/fdm-initialized", func {
	IESS_display = canvas.new({
		"name": "IESS",
		"size": [1024, 1024],
		"view": [1024, 1024],
		"mipmapping": 1
	});
	IESS_display.addPlacement({"node": "IESS_screen"});
	var groupED = IESS_display.createGroup();

	ED_only = canvas_ED_only.new(groupED, "Aircraft/E-jet-family/Models/Primus-Epic/IESS.svg");

	ED_only.update();
	canvas_ED_base.update();
});

var showIESS = func {
	var dlg = canvas.Window.new([512, 512], "dialog").set("resize", 1);
	dlg.setCanvas(IESS_display);
}
