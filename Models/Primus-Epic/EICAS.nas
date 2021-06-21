# E-jet-family EICAS by D-ECHO based on
# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

#sources: http://www.smartcockpit.com/docs/Embraer_190-Powerplant.pdf http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf http://www.smartcockpit.com/docs/Embraer_190-APU.pdf

var ED_only = nil;
var ED_display = nil;
var page = "only";

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

var engParam = {
    "N1L": props.globals.getNode("engines/engine[0]/n1"),
    "N1R": props.globals.getNode("engines/engine[1]/n1"),
    "N1L.target": props.globals.getNode("fadec/target[0]"),
    "N1R.target": props.globals.getNode("fadec/target[1]"),
    "N1L.trs-limit": props.globals.getNode("fadec/trs-limit"),
    "N1R.trs-limit": props.globals.getNode("fadec/trs-limit"),
    "N2L": props.globals.getNode("engines/engine[0]/n2"),
    "N2R": props.globals.getNode("engines/engine[1]/n2"),
    "offL": props.globals.getNode("controls/engines/engine[0]/cutoff-switch"),
    "offR": props.globals.getNode("controls/engines/engine[1]/cutoff-switch"),
};

var engLoff	=	props.globals.getNode("controls/engines/engine[0]/cutoff-switch", 1);
var engRoff	=	props.globals.getNode("controls/engines/engine[1]/cutoff-switch", 1);

setprop("/systems/electrical/outputs/eicas", 0);

var trsModeLabels = {
	0: "TO",
	1: "GA",
	2: "CLB",
	4: "CRZ",
	5: "CON",
	6: "TOGA-RES",
};

var canvas_ED_only = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_ED_only] };
		m.init(canvas_group, file);

		return m;
	},

	init: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			return "LiberationFonts/LiberationSans-Regular.ttf";
		};


		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});
        setlistener("/systems/electrical/outputs/eicas", func (node) {
            canvas_group.setVisible(node.getValue() > 18);
        }, 1, 0);

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

        me["N1L.target"] = canvas_group.createChild('path');
        me["N1L.target"]
            .set('z-index', -20)
            .setColor(1.0, 1.0, 1.0)
            .setStrokeLineWidth(3);
        me["N1R.target"] = canvas_group.createChild('path');
        me["N1R.target"]
            .set('z-index', -20)
            .setColor(1.0, 1.0, 1.0)
            .setStrokeLineWidth(3);

        me["N1L.shade"] = canvas_group.createChild('path');
        me["N1L.shade"].set('z-index', -10).setColorFill(0.5, 0.5, 0.5);
        me["N1R.shade"] = canvas_group.createChild('path');
        me["N1R.shade"].set('z-index', -10).setColorFill(0.5, 0.5, 0.5);

		me.page = canvas_group;

        var self = me;
        var msgColors = [
            [0, 1, 1], # MAINTENANCE: BLUE
            [1, 1, 1], # STATUS: WHITE
            [0, 1, 1], # ADVISORY: CYAN
            [1, 1, 0], # CAUTION: AMBER
            [1, 0, 0], # WARNING: RED
        ];
        var blinkProp = props.globals.getNode("/instrumentation/eicas/blink-state");
        var updateBlinks = func () {
            var (r, g, b) = [0, 0, 0];
            var i = 0;
            var elem = nil;
            var blink = blinkProp.getBoolValue();
            foreach (var msg; messages.messages) {
                (r, g, b) = msgColors[msg.level];
                elem = self['msg.' ~ i];
                if (elem != nil) {
                    if (blink and (msg.blink != 0)) {
                        elem.setColorFill(r, g, b, 1);
                        elem.setColor(0, 0, 0);
                        elem.setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX);
                    }
                    else {
                        elem.setColorFill(0, 0, 0, 1);
                        elem.setColor(r, g, b);
                        elem.setDrawMode(canvas.Text.TEXT);
                    }
                }
                i += 1;
            }
        };
        setlistener(blinkProp, updateBlinks);
        setlistener("/instrumentation/eicas/signals/messages-changed", func () {
            updateBlinks();
            var (r, g, b) = [0, 0, 0];
            var i = 0;
            var elem = nil;
            foreach (var msg; messages.messages) {
                elem = self['msg.' ~ i];
                if (elem != nil) {
                    elem.setText(msg.text);
                }
                i += 1;
            }
            while (i < 16) {
                elem = self['msg.' ~ i];
                if (elem != nil) {
                    elem.setText("");
                }
                i += 1;
            }
        });
        setlistener('/instrumentation/eicas/declutter/active', func (node) {
            var visible = !(node.getBoolValue());
            self["flaps-spoilers.section"].setVisible(visible);
            self["vib.section"].setVisible(visible);
            self["oil.section"].setVisible(visible);
            self["gear.section"].setVisible(visible);
            self["apu.section"].setVisible(visible);
        }, 1, 0);

		return me;
    },

	getKeys: func() {
		return [
            "flaps.UP",
            "flaps.IND",
            "flaps.SHADE",
            "flaps.SCALE",
            "flaps.TGT",
            "slat.IND",
            "slat.TGT",
            "slat.SCALE",
            "spoilers.IND",
            "spoilers.ANN",
            "spoilers.DOWN",
            "fs",
            "N1L",
            "N1R",
            "N2L",
            "N2R",
            "ITTL",
            "ITTR",
            "FFL",
            "FFR",
            "FQL",
            "FQR",
            "FQC",
            "OPL",
            "OPR",
            "OTL",
            "OTR",
            "revL",
            "revR",
            "gearL.T",
            "gearL.C",
            "gearR.T",
            "gearR.C",
            "gearF.C",
            "gearF.T",
            "AB",
            "apu.PCT",
            "apu.DEGC",
            "N1L.needle",
            "N1R.needle",
            "N1L.rated-max",
            "N1R.rated-max",
            "parkbrake",
            "engL.off",
            "engR.off",
            "pitchtrim.digital",
            "pitchtrim.pointer",
            "ailerontrim.pointer",
            "ruddertrim.pointer",
            "limitL.digital",
            "limitR.digital",
            "trsMode",
            "msg.0",
            "msg.1",
            "msg.2",
            "msg.3",
            "msg.4",
            "msg.5",
            "msg.6",
            "msg.7",
            "msg.8",
            "msg.9",
            "msg.10",
            "msg.11",
            "msg.12",
            "msg.13",
            "msg.14",
            "msg.15",
            "flaps-spoilers.section",
            "vib.section",
            "oil.section",
            "gear.section",
            "apu.section",
        ];
	},
	update: func() {
			
		var flap_pos=getprop("/fdm/jsbsim/fcs/flap-pos-deg") or 0;
		var flap_cmd=getprop("/fdm/jsbsim/fcs/flap-cmd-int-deg") or 0;
		
		if(flap_pos==0){
			me["flaps.IND"].hide();
			me["flaps.SHADE"].hide();
			me["flaps.SCALE"].hide();
			me["flaps.TGT"].hide();
			me["flaps.UP"].show();
		}else{
			me["flaps.IND"].show();
			me["flaps.SHADE"].show();
			me["flaps.SCALE"].show();
			me["flaps.TGT"].show();
			me["flaps.UP"].hide();
			me["flaps.TGT"].setRotation(flap_cmd * D2R);
			me["flaps.IND"].setRotation(flap_pos * D2R);
		}
		
		var slat_pos=getprop("/fdm/jsbsim/fcs/slat-pos-deg") or 0;
		var slat_cmd=getprop("/fdm/jsbsim/fcs/slat-cmd-int-deg") or 0;
		if(slat_pos==0){
			me["slat.IND"].hide();
			me["slat.SCALE"].hide();
			me["slat.TGT"].hide();
		}else{
			me["slat.IND"].show();
			me["slat.SCALE"].show();
			me["slat.TGT"].show();
			me["slat.TGT"].setRotation(slat_cmd*(-D2R));
			me["slat.IND"].setRotation(slat_pos*(-D2R));
		}

        var gndspl_extension = getprop("/controls/flight/ground-spoilers");
        var spdbrk_extension = getprop("/controls/flight/speedbrake-lever");
        var extension = getprop("/surface-positions/speedbrake-pos-norm") or 0;
        if (extension > 0.001) {
            me["spoilers.IND"].show();
            me["spoilers.IND"].setRotation(-30 * D2R * extension);
            me["spoilers.DOWN"].hide();
        }
        else {
            me["spoilers.IND"].hide();
            me["spoilers.IND"].setRotation(0);
            me["spoilers.DOWN"].show();
        }

        if (gndspl_extension > 0.001) {
            me["spoilers.ANN"].show();
            me["spoilers.ANN"].setText("GND SPL");
        }
        else if (spdbrk_extension > 0.001) {
            me["spoilers.ANN"].show();
            me["spoilers.ANN"].setText("SPDBRK");
        }
        else {
            me["spoilers.ANN"].hide();
        }
		
        var flap_cmd_raw = math.round((getprop("/controls/flight/flaps") or 0) / 0.125);
		me["fs"].setText(sprintf("%u", flap_cmd_raw));

        me["pitchtrim.digital"].setText(sprintf("%3.1f", (getprop("/controls/flight/elevator-trim") or 0.0) * -10));
        me["pitchtrim.pointer"].setTranslation(0, math.round((getprop("/controls/flight/elevator-trim") or 0) * 60));
        me["ruddertrim.pointer"].setTranslation(math.round((getprop("/controls/flight/rudder-trim") or 0) * 60), 0);
        me["ailerontrim.pointer"].setRotation(math.round((getprop("/controls/flight/aileron-trim") or 0) * 30));
		
		var ln2=engParam["N2L"].getValue();
		var rn2=engParam["N2R"].getValue();

		var litt=getprop("/engines/engine[0]/itt_degc");
		var ritt=getprop("/engines/engine[1]/itt_degc");
		var lff=getprop("/engines/engine[0]/fuel-flow_pph") * LB2KG;
		var rff=getprop("/engines/engine[1]/fuel-flow_pph") * LB2KG;
		var fq=getprop("/consumables/fuel/total-fuel-kg");
		var lfq=getprop("/consumables/fuel/tank[0]/level-kg");
		var rfq=getprop("/consumables/fuel/tank[1]/level-kg");
		var lop=getprop("/engines/engine[0]/oil-pressure-psi");
		var rop=getprop("/engines/engine[1]/oil-pressure-psi");
		var lot=getprop("/engines/engine[0]/oil-temperature-degc");
		var rot=getprop("/engines/engine[1]/oil-temperature-degc");

        # TRS
        var mode = getprop("/trs/mode") or 0;
        var modeLabel = trsModeLabels[mode] or "---";
        if (modeLabel == "TO" or modeLabel == "GA") {
            if (modeLabel == "TO") {
                if (getprop("/controls/flight/trs/flex-to")) {
                    modeLabel = "FLEX-TO";
                }
            }
            var submode = getprop("/trs/thrust/to-submode") or 1;
            modeLabel = modeLabel ~ "-" ~ submode;
        }
        else if (modeLabel == "CLB") {
            var submode = getprop("/trs/thrust/climb-submode") or 1;
            modeLabel = modeLabel ~ "-" ~ submode;
        }
        me["trsMode"].setText(modeLabel);
        var limit = getprop("/fadec/trs-limit");
        if (limit == nil) {
            me["limitL.digital"].setText("+++++");
            me["limitR.digital"].setText("+++++");
        }
        else {
            me["limitL.digital"].setText(sprintf("%5.1f", limit));
            me["limitR.digital"].setText(sprintf("%5.1f", limit));
        }
		
		#Engine off
		me["engL.off"].setVisible(engParam["offL"].getBoolValue());
		me["engR.off"].setVisible(engParam["offR"].getBoolValue());

        foreach (var gauge; ["N1L", "N1R"]) {
            var n1 = engParam[gauge].getValue();
            var tgt = engParam[gauge ~ ".target"].getValue();
            var trs = engParam[gauge ~ ".trs-limit"].getValue();
            me[gauge ~ ".needle"].setRotation(n1*D2R*2.568);
            me[gauge ~ ".rated-max"].setRotation(trs*D2R*2.568);

            me[gauge].setText(sprintf("%.1f", n1));

            var r = 110;
            var ri = 90;
            var rd = r - ri;
            var sc45 = math.sin(45 * D2R);
            var (cx, cy) = me[gauge ~ ".needle"].getCenter();

            var dn1 = n1 * 2.568 - 45;
            var rn1 = dn1 * D2R;
            var sn1 = math.sin(rn1);
            var cn1 = math.cos(rn1);
		
            var shade = me[gauge ~ ".shade"];
            shade.reset();
            if (n1 >= 0.05) {
                shade
                    .moveTo(cx, cy)
                    .line(-r * sc45, r * sc45);
                if (dn1 > 135) {
                    shade.arcLargeCWTo(r, r, 0, cx - r * cn1, cy - r * sn1);
                }
                else {
                    shade.arcSmallCWTo(r, r, 0, cx - r * cn1, cy - r * sn1);
                } 
                shade.lineTo(cx, cy);
            }

            var dtgt = tgt * 2.568 - 45;
            var rtgt = dtgt * D2R;
            var stgt = math.sin(rtgt);
            var ctgt = math.cos(rtgt);

            var target = me[gauge ~ ".target"];
            target.reset();
            if (tgt >= 0.05) {
                target.moveTo(cx - ri * sc45, cy + ri * sc45);

                if (dtgt > 135) {
                    target.arcLargeCWTo(ri, ri, 0, cx - ri * ctgt, cy - ri * stgt);
                }
                else {
                    target.arcSmallCWTo(ri, ri, 0, cx - ri * ctgt, cy - ri * stgt);
                } 
                target.line(-rd * ctgt, -rd * stgt);
            }
        }

		me["N2L"].setText(sprintf("%.1f", ln2));
		me["N2R"].setText(sprintf("%.1f", rn2));
		me["ITTL"].setText(sprintf("%u", litt));
		me["ITTR"].setText(sprintf("%u", ritt));
		me["FFL"].setText(sprintf("%u", math.round(lff, 10)));
		me["FFR"].setText(sprintf("%u", math.round(rff, 10)));
		me["FQL"].setText(sprintf("%u", math.round(lfq, 10)));
		me["FQR"].setText(sprintf("%u", math.round(rfq, 10)));
		me["FQC"].setText(sprintf("%u", math.round(fq, 10)));
		me["OPL"].setText(sprintf("%u", lop));
		me["OPR"].setText(sprintf("%u", rop));
		me["OTL"].setText(sprintf("%u", lot));
		me["OTR"].setText(sprintf("%u", rot));

		var lrvs=getprop("/engines/engine[0]/reverser-pos-norm");
		var rrvs=getprop("/engines/engine[0]/reverser-pos-norm");
		if(lrvs==0){
			me["revL"].hide();
		}else if(lrvs>0 and lrvs<1){
			me["revL"].show();
			me["revL"].setColor(1,1,0);
		}else{
			me["revL"].show();
			me["revL"].setColor(0,1,0);
		}
		if(rrvs==0){
			me["revR"].hide();
		}else if(rrvs>0 and rrvs<1){
			me["revR"].show();
			me["revR"].setColor(1,1,0);
		}else{
			me["revR"].show();
			me["revR"].setColor(0,1,0);
		}
		
		var fg=getprop("/gear/gear[0]/position-norm");
		var lg=getprop("/gear/gear[1]/position-norm");
		var rg=getprop("/gear/gear[2]/position-norm");
		
		if(fg>0){
			me["gearF.C"].show();
			me["gearF.T"].show();
			if(fg==1){
				me["gearF.C"].setColor(0,1,0);
				me["gearF.T"].setColor(0,1,0);
				me["gearF.T"].setText("DN");
			}else{
				me["gearF.C"].setColor(1,1,0);
				me["gearF.T"].setColor(1,1,0);
				me["gearF.T"].setText("TR");
			}
		}else{
			me["gearF.C"].hide();
			me["gearF.T"].hide();
		}if(lg>0){
			me["gearL.C"].show();
			me["gearL.T"].show();
			if(lg==1){
				me["gearL.C"].setColor(0,1,0);
				me["gearL.T"].setColor(0,1,0);
				me["gearL.T"].setText("DN");
			}else{
				me["gearL.C"].setColor(1,1,0);
				me["gearL.T"].setColor(1,1,0);
				me["gearL.T"].setText("TR");
			}
		}else{
			me["gearL.C"].hide();
			me["gearL.T"].hide();
		}if(rg>0){
			me["gearR.C"].show();
			me["gearR.T"].show();
			if(rg==1){
				me["gearR.C"].setColor(0,1,0);
				me["gearR.T"].setColor(0,1,0);
				me["gearR.T"].setText("DN");
			}else{
				me["gearR.C"].setColor(1,1,0);
				me["gearR.T"].setColor(1,1,0);
				me["gearR.T"].setText("TR");
			}
		}else{
			me["gearR.C"].hide();
			me["gearR.T"].hide();
		}
		
		var autobrake=getprop("/autopilot/autobrake/step");
		if(autobrake==0){
			me["AB"].setText("OFF");
		}else if(autobrake==1){
			me["AB"].setText("LO");
		}else if(autobrake==2){
			me["AB"].setText("MED");
		}else if(autobrake==3){
			me["AB"].setText("HI");
		}else if(autobrake==-1){
			me["AB"].setText("RTO");
		}
		
		var apurpm=getprop("/engines/apu/rpm");
		#var aputmp=getprop("/engines/apu/temp") or 0;
		me["apu.PCT"].setText(sprintf("%u", apurpm));
		#me["apu.DEGC"].setText(sprintf("%u", aputmp));
		
	},
};

setlistener("sim/signals/fdm-initialized", func {
	ED_display = canvas.new({
		"name": "EICAS",
		"size": [2048, 2808],
		"view": [1024, 1404],
		"mipmapping": 1
	});
	ED_display.addPlacement({"node": "EICAS.face"});
	var groupED = ED_display.createGroup();

	ED_only = canvas_ED_only.new(groupED, "Aircraft/E-jet-family/Models/Primus-Epic/eicas.svg");

	var timer = maketimer(0.1, func { ED_only.update(); });
    setlistener("/systems/electrical/outputs/eicas", func (node) {
        if (node.getBoolValue()) {
            timer.start();
            groupED.show();
        }
        else {
            timer.stop();
            groupED.hide();
        }
    }, 1, 0);
});

var showED = func {
	var dlg = canvas.Window.new([512, 768], "dialog").set("resize", 1);
	dlg.setCanvas(ED_display);
}
