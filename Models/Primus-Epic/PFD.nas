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
		return [
			"horizon",
			"compass",
			"groundspeed",
            "mach.digital",
            "airspeed.bug",
            "speedtrend.vector",
			"wind.pointer",
			"wind.kt",
			"heading.digital",
			"selectedheading.digital",
			"selectedcourse.digital",
			"selectedheading.pointer",
			"nav1.act",
			"nav1.sby",
			"vhf1.act",
			"vhf1.sby",
			"ils.locneedle",
			"ils.gsneedle",
			"alt.tape",
			"altNumLow1",
			"altNumHigh1",
			"altNumHigh2",
			"alt.rollingdigits",
			"alt.10000",
			"alt.1000",
			"alt.100",
			"asi.rollingdigits",
			"asi.100",
			"asi.10",
			"asi.tape",
			"hsi.nav1",
			"hsi.nav1track",
			"hsi.dots",
			"hsi.to",
			"hsi.from",
			"selectedspeed.digital",
			"selectedalt.digital100",
			"selectedvspeed.digital",
			"roll.pointer",
			"slip.pointer",
			"vs.needle",
			"VS.digital",
			"fma.appr",
			"fma.apprarmed",
			"fma.spd",
			"fma.spdarmed",
			"fma.ap",
			"fma.at",
			"fma.lat",
			"fma.latarmed",
			"fma.vert",
			"fma.vertarmed"
		];
	},
	update: func() {
			
		var pitch = (getprop("instrumentation/pfd/pitch-scale") or 0);
		var roll =  getprop("orientation/roll-deg") or 0;
		me.h_trans.setTranslation(0,pitch*8.05);
		me.h_rot.setRotation(-roll*DC,me["horizon"].getCenter());
		if(math.abs(roll)<=45){
			me["roll.pointer"].setRotation(roll*(-DC));
		}
		me["slip.pointer"].setTranslation(math.round((getprop("/instrumentation/slip-skid-ball/indicated-slip-skid") or 0)*50), 0);
		
		
		me["groundspeed"].setText(sprintf("%3d", getprop("/velocities/groundspeed-kt") or 0));
		
		var heading = getprop("/orientation/heading-deg") or 0;
		var selectedheading = getprop("/it-autoflight/input/hdg") or 0;
		var selectedcourse = getprop("/instrumentation/nav[0]/radials/selected-deg") or 0;
		
		me["wind.pointer"].setRotation(((getprop("/environment/wind-from-heading-deg") or 0) - heading + 180) * DC);
        if (getprop("/environment/wind-speed-kt") > 1) {
            me["wind.pointer"].show();
        }
        else {
            me["wind.pointer"].hide();
        }
		me["wind.kt"].setText(sprintf("%u", math.round(getprop("/environment/wind-speed-kt") or 0)));

		me["compass"].setRotation(heading * -DC);
		me["heading.digital"].setText(sprintf("%03d", heading));
		me["selectedheading.digital"].setText(sprintf("%03d", selectedheading));
		me["selectedheading.pointer"].setRotation((selectedheading - heading) * DC);
		me["selectedcourse.digital"].setText(sprintf("%03d", selectedcourse));
		
		# HSI NAV1
		var nav1heading = getprop("/instrumentation/nav[0]/radials/selected-deg") or 0;
		var nav1error = getprop("/instrumentation/nav[0]/heading-needle-deflection-norm") or 0;
		me["hsi.nav1"].setRotation((nav1heading - heading) * DC);
		me["hsi.dots"].setRotation((nav1heading - heading) * DC);
		me["hsi.nav1track"].setTranslation(nav1error * 120, 0);
		if (getprop("/instrumentation/nav[0]/from-flag")) {
			me["hsi.from"].show();
			me["hsi.to"].hide();
		}
		else {
			me["hsi.from"].hide();
			me["hsi.to"].show();
		}


		me["selectedalt.digital100"].setText(sprintf("%02d", (getprop("/it-autoflight/input/alt") or 0) * 0.01));

		#COMM/NAV
		me["vhf1.act"].setText(sprintf("%.2f", getprop("/instrumentation/comm[0]/frequencies/selected-mhz") or 0));
		me["vhf1.sby"].setText(sprintf("%.2f", getprop("/instrumentation/comm[0]/frequencies/standby-mhz") or 0));
		me["nav1.act"].setText(sprintf("%.2f", getprop("/instrumentation/nav[0]/frequencies/selected-mhz") or 0));
		me["nav1.sby"].setText(sprintf("%.2f", getprop("/instrumentation/nav[0]/frequencies/standby-mhz") or 0));
		if (getprop("/instrumentation/nav[0]/gs-in-range")) {
			me["ils.gsneedle"].setTranslation(0, math.round((getprop("/instrumentation/nav[0]/gs-needle-deflection-norm") or 0) * -100.0));
		}
		else {
			me["ils.gsneedle"].setTranslation(0, 0);
		}
		if (getprop("/instrumentation/nav[0]/in-range")) {
			me["ils.locneedle"].setTranslation(math.round((getprop("/instrumentation/nav[0]/heading-needle-deflection-norm") or 0) * 100.0), 0);
		}
		else {
			me["ils.locneedle"].setTranslation(0, 0);
		}
		

		var vspeed = getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm") or 0;
		me["VS.digital"].setText(sprintf("%04d", vspeed));
		me["vs.needle"].setRotation(vspeed * math.pi * 0.25 / 4000.0);
		
		# Altitude
		var alt = getprop("/instrumentation/altimeter/indicated-altitude-ft") or 0;
		if (roundToNearest(alt, 1000) == 0) {
			var altNumLow = "-1";
			var altNumHigh = "1";
			var altNumCenter = 0;
		}
		elsif (roundToNearest(alt, 1000) > 0) {
			var altNumLow = (roundToNearest(alt, 1000)/1000 - 1);
			var altNumHigh = (roundToNearest(alt, 1000)/1000 + 1);
			var altNumCenter = altNumHigh-1;
		}
		elsif (roundToNearest(alt, 1000) < 0) {
			var altNumLow = roundToNearest(alt, 1000)/1000-1;
			var altNumHigh = (roundToNearest(alt, 1000)/1000 + 1) ;
			var altNumCenter = altNumLow-1;
		}
		if ( altNumLow == 0 ) {
			altNumLow = "";
		}
		elsif(altNumLow != nil) {
			altNumLow=1000*altNumLow;
		}
		if ( altNumHigh == 0 and alt < 0) {
			altNumHigh = "-";
		}
		elsif(altNumHigh != nil) {
			altNumHigh=1000*altNumHigh;
		}
		if(altNumCenter != nil){
			altNumCenter=1000*altNumCenter;
		}

		me["alt.tape"].setTranslation(0,(alt - roundToNearest(alt, 1000))*0.45);

		var alt100 = alt / 100;
		var alt100Abs = math.abs(math.floor(alt100));
		var altStr = "  0";
		if (alt100Abs >= 1) {
			altStr = sprintf("%3.0d", alt100Abs) or "  0";
		}
		me["alt.rollingdigits"].setTranslation(0,math.round((10*math.mod(alt100,1))*18, 0.1));
		
		me["alt.100"].setText(substr(altStr, 2, 1));
		me["alt.1000"].setText(substr(altStr, 1, 1));
		if (alt < 0) {
			me["alt.10000"].setText("-" ~ substr(altStr, 0, 1));
		}
		else {
			me["alt.10000"].setText(substr(altStr, 0, 1));
		}

		# if (alt100Abs >= 10000) {
		# 	me["alt.10000"].show();
		# 	me["alt.1000"].show();
		# }
		# else if (alt100Abs >= 1000) {
		# 	me["alt.10000"].hide();
		# 	me["alt.1000"].show();
		# }
		# else {
		# 	me["alt.10000"].hide();
		# 	me["alt.1000"].hide();
		# }
		
		# Airspeed
		var airspeed = getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
        var currentMach = getprop("/instrumentation/airspeed-indicator/indicated-mach") or 0;
        var selectedKts = 0;

		if (getprop("/it-autoflight/input/kts-mach")) {
            var selectedMach = (getprop("/it-autoflight/input/spd-mach") or 0);
			me["selectedspeed.digital"].setText(sprintf(".%03dM", selectedMach * 1000));
            if (currentMach > 0.001) {
                selectedKts = selectedMach * airspeed / currentMach;
            }
            else {
                # this shouldn't happen in practice, but when it does, use the
                # least objectionable default.
                selectedKts = getprop("/it-autoflight/input/spd-kts");
            }
		}
		else {
            selectedKts = (getprop("/it-autoflight/input/spd-kts") or 0);
			me["selectedspeed.digital"].setText(sprintf("%03d", selectedKts));
		}
        me["mach.digital"].setText(sprintf(".%03d", currentMach * 1000));

		me["selectedvspeed.digital"].setText(sprintf("%-05d", (getprop("/it-autoflight/input/vs") or 0)));
		
		me["asi.tape"].setTranslation(0,airspeed * 6.42);
        me["airspeed.bug"].setTranslation(0, (airspeed-selectedKts) * 6.42);
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
		
		# FMA
		if (getprop("/it-autoflight/output/ap1") or getprop("/it-autoflight/output/ap2")) {
			me["fma.ap"].show();
		}
		else {
			me["fma.ap"].hide();
		}
		if (getprop("/it-autoflight/output/athr")) {
			me["fma.at"].show();
		}
		else {
			me["fma.at"].hide();
		}

		var latModeMap = {
			"HDG": "HDG",
			"HDG HLD": "ROLL",
			"HDG SEL": "HDG",
			"LNAV": "LNAV",
			"LOC": "LOC",
			"ALGN": "ROLL",
			"RLOU": "ROLL",
			"T/O": "TRACK"
		};
		var latModeArmedMap = {
			"LNV": "LNAV",
			"LOC": "LOC",
			"ILS": "LOC",
			"HDG": "HDG",
			"HDG HLD": "ROLL",
			"HDG SEL": "HDG",
			"T/O": "TRACK"
		};
		var vertModeMap = {
			"ALT HLD": "ALT",
			"V/S": "VS",
			"G/S": "GS",
			"ALT CAP": "ASEL",
			"SPD DES": "FLCH",
			"SPD CLB": "FLCH",
			"FPA": "FPA",
			"LAND 3": "LAND",
			"FLARE": "FLARE",
			"ROLLOUT": "ROLLOUT",
			"T/O CLB": "TO",
			"G/A CLB": "GA"
		};
		var vertModeArmedMap = {
			"V/S": "ASEL",
			"G/S": "ASEL",
			"ALT CAP": "ALT",
			"SPD DES": "ASEL",
			"SPD CLB": "ASEL",
			"FPA": "ASEL",
			"T/O CLB": "FLCH",
			"G/A CLB": "FLCH"
		};
		var spdModeMap = {
			"THRUST": "SPDt",
			"PITCH": "SPDe",
			" PITCH": "SPDe", # yes, this is correct, ITAF 4.0 is buggy here
			"RETARD": "SPDe",
			"T/O CLB": "TO",
			"G/A CLB": "GA"
		};
		var spdModeArmedMap = {
			"THRUST": "",
			"PITCH": "SPDt",
			" PITCH": "SPDt",
			"RETARD": "SPDt",
			"T/O CLB": "SPDt",
			"G/A CLB": "SPDt"
		};

		me["fma.lat"].setText(latModeMap[getprop("/it-autoflight/mode/lat") or ""] or "");
		me["fma.vert"].setText(vertModeMap[getprop("/it-autoflight/mode/vert") or ""] or "");
		me["fma.vertarmed"].setText(vertModeArmedMap[getprop("/it-autoflight/mode/vert") or ""] or "");
		me["fma.spd"].setText(
				spdModeMap[getprop("/it-autoflight/mode/vert") or ""] or
				spdModeMap[getprop("/it-autoflight/mode/thr") or ""] or
				"");
		me["fma.spdarmed"].setText(
				spdModeArmedMap[getprop("/it-autoflight/mode/vert") or ""] or
				spdModeArmedMap[getprop("/it-autoflight/mode/thr") or ""] or
				"");

		if (getprop("/it-autoflight/output/lnav-armed")) {
			me["fma.latarmed"].setText("LNAV");
		}
		else if (getprop("/it-autoflight/output/loc-armed") or getprop("/it-autoflight/output/appr-armed")) {
			me["fma.latarmed"].setText("LOC");
		}
		else if (getprop("/it-autoflight/mode/lat") == "T/O") {
			# In T/O mode, if LNAV wasn't armed, the A/P will transition to HDG mode.
			me["fma.latarmed"].setText("HDG");
		}
		else {
			me["fma.latarmed"].setText(latModeArmedMap[getprop("/it-autoflight/mode/arm")]);
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
