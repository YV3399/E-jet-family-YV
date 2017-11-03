# E-jet-family EICAS by D-ECHO based on
# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

#sources: http://www.smartcockpit.com/docs/Embraer_190-Powerplant.pdf http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf http://www.smartcockpit.com/docs/Embraer_190-APU.pdf

var ED_only = nil;
var PFD_display = nil;
var page = "only";
var DC=0.01744;

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

setprop("/systems/elecrical/outputs/efis", 0);


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
		#if (getprop("systems/electrical/outputs/efis") >= 15) {
		#		ED_only.page.show();
		#} else {
		#	ED_only.page.hide();
		#}
		
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
		return ["horizon","compass","groundspeed","wind.pointer","wind.kt","heading.digital","nav1.act","nav1.sby","vhf1.act","vhf1.sby","alt.tape","altNumLow1","altNumHigh1","altNumHigh2","alt.rollingdigits","alt.10000","alt.1000","alt.100","asi.rollingdigits","asi.100","asi.10","asi.tape","roll.pointer","slip.pointer","vs.needle"];
	},
	update: func() {
			
		var pitch = (getprop("instrumentation/pfd/pitch-scale") or 0);
		var roll =  getprop("orientation/roll-deg") or 0;
		me.h_trans.setTranslation(0,pitch*8.05);
		me.h_rot.setRotation(-roll*DC,me["horizon"].getCenter());
		if(roll<=45){
			me["roll.pointer"].setRotation(roll*(-DC));
		}
		me["slip.pointer"].setTranslation(math.round(getprop("/instrumentation/slip-skid-ball/indicated-slip-skid") or 0)*5, 0);
		
		
		me["groundspeed"].setText(sprintf("%3d", getprop("/velocities/groundspeed-kt") or 0));
		
		me["wind.pointer"].setRotation((getprop("/environment/wind-from-heading-deg") or 0)*DC);
		me["wind.kt"].setText(sprintf("%u", math.round(getprop("/environment/wind-speed-kt") or 0)));
		
		me["compass"].setRotation((getprop("/orientation/heading-deg") or 0)*-DC);
		me["heading.digital"].setText(sprintf("%03d", getprop("/orientation/heading-deg") or 0));
		
		#COMM/NAV
		me["vhf1.act"].setText(sprintf("%.2f", getprop("/instrumentation/comm[0]/frequencies/selected-mhz")));
		me["vhf1.sby"].setText(sprintf("%.2f", getprop("/instrumentation/comm[0]/frequencies/standby-mhz")));
		me["nav1.act"].setText(sprintf("%.2f", getprop("/instrumentation/nav[0]/frequencies/selected-mhz")));
		me["nav1.sby"].setText(sprintf("%.2f", getprop("/instrumentation/nav[0]/frequencies/standby-mhz")));
		
		
		
		
		var alt=getprop("/instrumentation/altimeter/indicated-altitude-ft") or 0;

		me["alt.tape"].setTranslation(0,(alt - roundToNearest(alt, 1000))*0.45);
		if (roundToNearest(alt, 1000) == 0) {
			#me["altTextLowSmall1"].setText(sprintf("%0.0f",5));
			#me["altTextHighSmall2"].setText(sprintf("%0.0f",5));
			var altNumLow = "-1";
			var altNumHigh = "1";
			var altNumCenter = 0;
		} elsif (roundToNearest(alt, 1000) > 0) {
			#me["altTextLowSmall1"].setText(sprintf("%0.0f",5));
			#me["altTextHighSmall2"].setText(sprintf("%0.0f",5));
			var altNumLow = (roundToNearest(alt, 1000)/1000 - 1);
			var altNumHigh = (roundToNearest(alt, 1000)/1000 + 1);
			var altNumCenter = altNumHigh-1;
		} elsif (roundToNearest(alt, 1000) < 0) {
			#me["altTextLowSmall1"].setText(sprintf("%0.0f",5));
			#me["altTextHighSmall2"].setText(sprintf("%0.0f",5));
			var altNumLow = roundToNearest(alt, 1000)/1000-1;
			var altNumHigh = (roundToNearest(alt, 1000)/1000 + 1) ;
			var altNumCenter = altNumLow-1;
		}
		if ( altNumLow == 0 ) {
			altNumLow = "";
		}else if(altNumLow != nil){
			altNumLow=1000*altNumLow;
		}
		if ( altNumHigh == 0 and alt < 0) {
			altNumHigh = "-";
		}else if(altNumHigh != nil){
			altNumHigh=1000*altNumHigh;
		}
		
		if(altNumCenter != nil){
			altNumCenter=1000*altNumCenter;
		}
		
		
		
		var alt100=(getprop("/instrumentation/PFD/alt-1") or 0)/100;
		me["alt.rollingdigits"].setTranslation(0,math.round((10*math.mod(alt100,1))*18, 0.1));
		
		me["altNumLow1"].setText(sprintf("%s", altNumLow));
		me["altNumHigh1"].setText(sprintf("%4d", altNumCenter));
		me["altNumHigh2"].setText(sprintf("%s", altNumHigh));
		
		
		var alt10000=getprop("/instrumentation/PFD/alt-10000") or 0;
		if(alt10000!=0){
			me["alt.10000"].show();
			me["alt.10000"].setText(sprintf("%s", math.round(alt10000)));
		}else{
			me["alt.10000"].hide();
		}
		
		var alt1000=getprop("/instrumentation/PFD/alt-1000") or 0;
		if(alt1000!=0){
			me["alt.1000"].show();
			me["alt.1000"].setText(sprintf("%s", math.round((10*math.mod(alt1000/10,1)))));
		}else{
			me["alt.1000"].hide();
		}
		
		var alt100=getprop("/instrumentation/PFD/alt-100") or 0;
		me["alt.100"].setText(sprintf("%s", math.round((10*math.mod(alt100/10,1)))));

		
		
		var airspeed=getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
		me["asi.tape"].setTranslation(0,airspeed*6.6);
		me["asi.rollingdigits"].setTranslation(0,math.round((10*math.mod(airspeed/10,1))*50, 0.1));
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
		
		
		settimer(func me.update(), 0.02);
	},
};

setlistener("sim/signals/fdm-initialized", func {
	PFD_display = canvas.new({
		"name": "EICAS",
		"size": [1024, 1530],
		"view": [1024, 1530],
		"mipmapping": 1
	});
	PFD_display.addPlacement({"node": "PFD_screen"});
	var groupED = PFD_display.createGroup();

	ED_only = canvas_ED_only.new(groupED, "Aircraft/E-jet-family/Models/Primus-Epic/PFD.svg");

	ED_only.update();
	canvas_ED_base.update();
});

var showPFD = func {
	var dlg = canvas.Window.new([512, 765], "dialog").set("resize", 1);
	dlg.setCanvas(PFD_display);
}
