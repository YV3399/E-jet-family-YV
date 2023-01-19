# E-jet-family EICAS by D-ECHO based on
# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

#sources: http://www.smartcockpit.com/docs/Embraer_190-Powerplant.pdf http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf http://www.smartcockpit.com/docs/Embraer_190-APU.pdf

var trsModeLabels = {
	0: "TO",
	1: "GA",
	2: "CLB",
	4: "CRZ",
	5: "CON",
	6: "TOGA-RES",
};

var msgColors = [
    [0, 1, 1], # MAINTENANCE: BLUE
    [1, 1, 1], # STATUS: WHITE
    [0, 1, 1], # ADVISORY: CYAN
    [1, 1, 0], # CAUTION: AMBER
    [1, 0, 0], # WARNING: RED
];

var EICAS = {
    new: func () {
        # TODO: make EICAS available from both sides.
        var m = canvas_base.BaseScreen.new(0, 2);
        m.parents = [EICAS] ~ m.parents;
        m.timer = nil;
        return m;
    },

    postInit: func () {
        var self = me;
        me.timer = maketimer(0.1, func() { self.update(0.1); });
    },

    postActivate: func () {
        me.timer.start();
    },

    preDeactivate: func {
        me.timer.stop();
    },

    registerProps: func () {
        call(canvas_base.BaseScreen.registerProps, [], me);
        me.registerProp('cursor', "/instrumentation/eicas/cursor");
        me.registerProp('cursor.x', "/instrumentation/eicas/cursor/x");
        me.registerProp('cursor.y', "/instrumentation/eicas/cursor/y");
        me.registerProp('cursor.visible', "/instrumentation/eicas/cursor/visible");
        me.registerProp("N1L", "engines/engine[0]/n1");
        me.registerProp("N1R", "engines/engine[1]/n1");
        me.registerProp("N1L.target", "fadec/target[0]");
        me.registerProp("N1R.target", "fadec/target[1]");
        me.registerProp("N1L.trs-limit", "fadec/trs-limit");
        me.registerProp("N1R.trs-limit", "fadec/trs-limit");
        me.registerProp("N1L.lever", "fadec/lever[0]");
        me.registerProp("N1R.lever", "fadec/lever[1]");
        me.registerProp("N2L", "engines/engine[0]/n2");
        me.registerProp("N2R", "engines/engine[1]/n2");
        me.registerProp("offL", "controls/engines/engine[0]/cutoff-switch");
        me.registerProp("offR", "controls/engines/engine[1]/cutoff-switch");
        me.registerProp("ITTL", "engines/engine[0]/itt-degc", 1);
        me.registerProp("ITTR", "engines/engine[1]/itt-degc", 1);
        me.registerProp("/autopilot/autobrake/step");
        me.registerProp("/consumables/fuel/tank[0]/level-kg");
        me.registerProp("/consumables/fuel/tank[1]/level-kg");
        me.registerProp("/consumables/fuel/total-fuel-kg");
        me.registerProp("/controls/flight/aileron-trim");
        me.registerProp("/controls/flight/elevator-trim");
        me.registerProp("/controls/flight/flaps");
        me.registerProp("/controls/flight/ground-spoilers");
        me.registerProp("/controls/flight/rudder-trim");
        me.registerProp("/controls/flight/speedbrake-lever");
        me.registerProp("/controls/flight/trs/flex-to");
        me.registerProp("/engines/apu/rpm");
        me.registerProp("/engines/apu/temp-c");
        me.registerProp("/engines/engine[0]/fuel-flow_pph");
        me.registerProp("/engines/engine[0]/oil-pressure-psi");
        me.registerProp("/engines/engine[0]/oil-temperature-degc");
        me.registerProp("/engines/engine[0]/reverser-pos-norm");
        me.registerProp("/engines/engine[1]/fuel-flow_pph");
        me.registerProp("/engines/engine[1]/oil-pressure-psi");
        me.registerProp("/engines/engine[1]/oil-temperature-degc");
        me.registerProp("/fadec/trs-limit");
        me.registerProp("/fdm/jsbsim/fcs/flap-cmd-int-deg");
        me.registerProp("/fdm/jsbsim/fcs/flap-pos-deg");
        me.registerProp("/fdm/jsbsim/fcs/slat-cmd-int-deg");
        me.registerProp("/fdm/jsbsim/fcs/slat-pos-deg");
        me.registerProp("/gear/gear[0]/position-norm");
        me.registerProp("/gear/gear[1]/position-norm");
        me.registerProp("/gear/gear[2]/position-norm");
        me.registerProp("/surface-positions/speedbrake-pos-norm");
        me.registerProp("/trs/mode");
        me.registerProp("/trs/thrust/climb-submode");
        me.registerProp("/trs/thrust/to-submode");
        me.registerProp("blink", "/instrumentation/eicas/blink-state");
        me.registerProp("messages-changed", "/instrumentation/eicas/signals/messages-changed");
        me.registerProp("declutter", "/instrumentation/eicas/declutter/active");
    },

    makeMasterGroup: func (group) {
        call(canvas_base.BaseScreen.makeMasterGroup, [group], me);
        canvas.parsesvg(group, "Aircraft/E-jet-family/Models/Primus-Epic/eicas.svg", { 'font-mapper': me.font_mapper });
    },

    registerElems: func () {
        call(canvas_base.BaseScreen.registerElems, [], me);
        me.registerElemsFrom([
            "flaps.UP",
            "flaps.IND",
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
            "ITTL.needle",
            "ITTR.needle",
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
            "N1L.lever",
            "N1R.lever",
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
        ]);

        me.registerElem("N1L.target", func (group) { return group.createChild('path'); })
            .set('z-index', -20)
            .setColor(1.0, 1.0, 1.0)
            .setStrokeLineWidth(3);
        me.registerElem("N1R.target", func (group) { return group.createChild('path'); })
            .set('z-index', -20)
            .setColor(1.0, 1.0, 1.0)
            .setStrokeLineWidth(3);

        me.registerElem("N1L.shade", func (group) { return group.createChild('path'); })
            .set('z-index', -10)
            .setColorFill(0.5, 0.5, 0.5);
        me.registerElem("N1R.shade", func (group) { return group.createChild('path'); })
            .set('z-index', -10)
            .setColorFill(0.5, 0.5, 0.5);

        me.registerElem("ITTL.shade", func (group) { return group.createChild('path');; })
            .set('z-index', -10)
            .setColorFill(0.5, 0.5, 0.5);
        me.registerElem("ITTR.shade", func (group) { return group.createChild('path');; })
            .set('z-index', -10)
            .setColorFill(0.5, 0.5, 0.5);

        me.registerElem("flaps.shade", func (group) { return group.createChild('path');; })
            .set('z-index', -10)
            .setColorFill(0.5, 0.5, 0.5);
    },

    registerListeners: func () {
        call(canvas_base.BaseScreen.registerListeners, [], me);

        var self = me;

        me.addListener('main', '@blink', func { self.updateBlinks(); });
        me.addListener('main', '@messages-changed', func { self.updateMessages(); });
        me.addListener('main', '@declutter', func (node) { self.updateDeclutter(node.getBoolValue()); });
    },

    updateDeclutter: func (active) {
        me.elems["flaps-spoilers.section"].setVisible(!active);
        me.elems["vib.section"].setVisible(!active);
        me.elems["oil.section"].setVisible(!active);
        me.elems["gear.section"].setVisible(!active);
        me.elems["apu.section"].setVisible(!active);
    },

    updateBlinks: func () {
        var (r, g, b) = [0, 0, 0];
        var i = 0;
        var elem = nil;
        var blink = me.props['blink'].getBoolValue();
        foreach (var msg; messages.messages) {
            (r, g, b) = msgColors[msg.level];
            elem = me.elems['msg.' ~ i];
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
    },

    updateMessages: func () {
        me.updateBlinks();
        var i = 0;
        var elem = nil;
        foreach (var msg; messages.messages) {
            elem = me.elems['msg.' ~ i];
            if (elem != nil) {
                elem.setText(msg.text);
            }
            i += 1;
        }
        while (i < 16) {
            elem = me.elems['msg.' ~ i];
            if (elem != nil) {
                elem.setText("");
            }
            i += 1;
        }
    },

	update: func() {
		var flap_pos = me.props["/fdm/jsbsim/fcs/flap-pos-deg"].getValue() or 0;
		var flap_cmd = me.props["/fdm/jsbsim/fcs/flap-cmd-int-deg"].getValue() or 0;
		
		if (flap_pos == 0) {
			me.elems["flaps.IND"].hide();
			me.elems["flaps.SCALE"].hide();
			me.elems["flaps.TGT"].hide();
			me.elems["flaps.UP"].show();
			me.elems["flaps.shade"].hide();
		}
        else {
			me.elems["flaps.IND"].show();
			me.elems["flaps.shade"].show();
			me.elems["flaps.SCALE"].show();
			me.elems["flaps.TGT"].show();
			me.elems["flaps.UP"].hide();
			me.elems["flaps.TGT"].setRotation(flap_cmd * D2R);
			me.elems["flaps.IND"].setRotation(flap_pos * D2R);
            var shade = me.elems["flaps.shade"];
            var (cx, cy) = me.elems["flaps.IND"].getCenter();
            var sf = math.sin(flap_pos * D2R);
            var cf = math.cos(flap_pos * D2R);
            var r = 128.0;
            var h = 16.0;
            shade.reset();
            shade
                .moveTo(cx, cy)
                .line(0, -h)
                .line(r, h)
                .arcSmallCWTo(r, r, 0, cx + r * cf, cy + r * sf)
                .lineTo(cx, cy);
		}
		
		var slat_pos = me.props["/fdm/jsbsim/fcs/slat-pos-deg"].getValue() or 0;
		var slat_cmd = me.props["/fdm/jsbsim/fcs/slat-cmd-int-deg"].getValue() or 0;

		if (slat_pos == 0) {
			me.elems["slat.IND"].hide();
			me.elems["slat.SCALE"].hide();
			me.elems["slat.TGT"].hide();
		}
        else {
			me.elems["slat.IND"].show();
			me.elems["slat.SCALE"].show();
			me.elems["slat.TGT"].show();
			me.elems["slat.TGT"].setRotation(slat_cmd*(-D2R));
			me.elems["slat.IND"].setRotation(slat_pos*(-D2R));
		}

        var gndspl_extension = me.props["/controls/flight/ground-spoilers"].getValue();
        var spdbrk_extension = me.props["/controls/flight/speedbrake-lever"].getValue();
        var extension = me.props["/surface-positions/speedbrake-pos-norm"].getValue() or 0;
        if (extension > 0.001) {
            me.elems["spoilers.IND"].show();
            me.elems["spoilers.IND"].setRotation(-30 * D2R * extension);
            me.elems["spoilers.DOWN"].hide();
        }
        else {
            me.elems["spoilers.IND"].hide();
            me.elems["spoilers.IND"].setRotation(0);
            me.elems["spoilers.DOWN"].show();
        }

        if (gndspl_extension > 0.001) {
            me.elems["spoilers.ANN"].show();
            me.elems["spoilers.ANN"].setText("GND SPL");
        }
        else if (spdbrk_extension > 0.001) {
            me.elems["spoilers.ANN"].show();
            me.elems["spoilers.ANN"].setText("SPDBRK");
        }
        else {
            me.elems["spoilers.ANN"].hide();
        }
		
        var flap_cmd_raw = math.round((me.props["/controls/flight/flaps"].getValue() or 0) / 0.125);
		me.elems["fs"].setText(sprintf("%u", flap_cmd_raw));

        me.elems["pitchtrim.digital"].setText(sprintf("%3.1f", (me.props["/controls/flight/elevator-trim"].getValue() or 0.0) * -10));
        me.elems["pitchtrim.pointer"].setTranslation(0, math.round((me.props["/controls/flight/elevator-trim"].getValue() or 0) * 60));
        me.elems["ruddertrim.pointer"].setTranslation(math.round((me.props["/controls/flight/rudder-trim"].getValue() or 0) * 60), 0);
        me.elems["ailerontrim.pointer"].setRotation(math.round((me.props["/controls/flight/aileron-trim"].getValue() or 0) * 30));
		
		var ln2 = me.props["N2L"].getValue();
		var rn2 = me.props["N2R"].getValue();

		var lff = me.props["/engines/engine[0]/fuel-flow_pph"].getValue() * LB2KG;
		var rff = me.props["/engines/engine[1]/fuel-flow_pph"].getValue() * LB2KG;
		var fq = me.props["/consumables/fuel/total-fuel-kg"].getValue();
		var lfq = me.props["/consumables/fuel/tank[0]/level-kg"].getValue();
		var rfq = me.props["/consumables/fuel/tank[1]/level-kg"].getValue();
		var lop = me.props["/engines/engine[0]/oil-pressure-psi"].getValue();
		var rop = me.props["/engines/engine[1]/oil-pressure-psi"].getValue();
		var lot = me.props["/engines/engine[0]/oil-temperature-degc"].getValue();
		var rot = me.props["/engines/engine[1]/oil-temperature-degc"].getValue();

        # TRS
        var mode = me.props["/trs/mode"].getValue() or 0;
        var modeLabel = trsModeLabels[mode] or "---";
        if (modeLabel == "TO" or modeLabel == "GA") {
            if (modeLabel == "TO") {
                if (me.props["/controls/flight/trs/flex-to"].getValue()) {
                    modeLabel = "FLEX-TO";
                }
            }
            var submode = me.props["/trs/thrust/to-submode"].getValue() or 1;
            modeLabel = modeLabel ~ "-" ~ submode;
        }
        else if (modeLabel == "CLB") {
            var submode = me.props["/trs/thrust/climb-submode"].getValue() or 1;
            modeLabel = modeLabel ~ "-" ~ submode;
        }
        me.elems["trsMode"].setText(modeLabel);
        var limit = me.props["/fadec/trs-limit"].getValue();
        if (limit == nil) {
            me.elems["limitL.digital"].setText("+++++");
            me.elems["limitR.digital"].setText("+++++");
        }
        else {
            me.elems["limitL.digital"].setText(sprintf("%5.1f", limit));
            me.elems["limitR.digital"].setText(sprintf("%5.1f", limit));
        }
		
		#Engine off
		me.elems["engL.off"].setVisible(me.props["offL"].getBoolValue());
		me.elems["engR.off"].setVisible(me.props["offR"].getBoolValue());

        foreach (var gauge; ["N1L", "N1R"]) {
            var n1 = me.props[gauge].getValue();
            var tgt = me.props[gauge ~ ".target"].getValue();
            var trs = me.props[gauge ~ ".trs-limit"].getValue();
            var lvr = me.props[gauge ~ ".lever"].getValue();
            me.elems[gauge ~ ".needle"].setRotation(n1*D2R*2.568);
            me.elems[gauge ~ ".rated-max"].setRotation(trs*D2R*2.568);
            me.elems[gauge ~ ".lever"].setRotation(lvr*D2R*2.568);

            me.elems[gauge].setText(sprintf("%.1f", n1));

            var r = 110;
            var ri = 90;
            var rd = r - ri;
            var sc45 = math.sin(45 * D2R);
            var (cx, cy) = me.elems[gauge ~ ".needle"].getCenter();

            var dn1 = n1 * 2.568 - 45;
            var rn1 = dn1 * D2R;
            var sn1 = math.sin(rn1);
            var cn1 = math.cos(rn1);
		
            var shade = me.elems[gauge ~ ".shade"];
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

            var target = me.elems[gauge ~ ".target"];
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
        foreach (var gauge; ["ITTL", "ITTR"]) {
            var temp = me.props[gauge].getValue();
            var degs = math.max(0, math.min(270, (temp - 130) / 890 * 270)); # 120°C - 1000°C, wild guess
            me.elems[gauge ~ ".needle"].setRotation(degs*D2R);
            me.elems[gauge].setText(sprintf("%-i", temp));

            var r = 80;
            var sc45 = math.sin(45 * D2R);
            var (cx, cy) = me.elems[gauge ~ ".needle"].getCenter();

            var ddegs = degs - 45;
            var rdegs = ddegs * D2R;
            var sdegs = math.sin(rdegs);
            var cdegs = math.cos(rdegs);
		
            var shade = me.elems[gauge ~ ".shade"];
            shade.reset();
            if (temp >= 100) {
                shade
                    .moveTo(cx, cy)
                    .line(-r * sc45, r * sc45);
                if (ddegs > 135) {
                    shade.arcLargeCWTo(r, r, 0, cx - r * cdegs, cy - r * sdegs);
                }
                else {
                    shade.arcSmallCWTo(r, r, 0, cx - r * cdegs, cy - r * sdegs);
                } 
                shade.lineTo(cx, cy);
            }
        }

		me.elems["N2L"].setText(sprintf("%.1f", ln2));
		me.elems["N2R"].setText(sprintf("%.1f", rn2));
		me.elems["FFL"].setText(sprintf("%u", math.round(lff, 10)));
		me.elems["FFR"].setText(sprintf("%u", math.round(rff, 10)));
		me.elems["FQL"].setText(sprintf("%u", math.round(lfq, 10)));
		me.elems["FQR"].setText(sprintf("%u", math.round(rfq, 10)));
		me.elems["FQC"].setText(sprintf("%u", math.round(fq, 10)));
		me.elems["OPL"].setText(sprintf("%u", lop));
		me.elems["OPR"].setText(sprintf("%u", rop));
		me.elems["OTL"].setText(sprintf("%-i", lot));
		me.elems["OTR"].setText(sprintf("%-i", rot));

		var lrvs = me.props["/engines/engine[0]/reverser-pos-norm"].getValue();
		var rrvs = me.props["/engines/engine[0]/reverser-pos-norm"].getValue();
		if (lrvs == 0) {
			me.elems["revL"].hide();
		}
        else if (lrvs > 0 and lrvs < 1) {
			me.elems["revL"].show();
			me.elems["revL"].setColor(1,1,0);
		}
        else {
			me.elems["revL"].show();
			me.elems["revL"].setColor(0,1,0);
		}
		if (rrvs == 0) {
			me.elems["revR"].hide();
		}
        else if (rrvs > 0 and rrvs < 1) {
			me.elems["revR"].show();
			me.elems["revR"].setColor(1,1,0);
		}
        else {
			me.elems["revR"].show();
			me.elems["revR"].setColor(0,1,0);
		}
		
		var fg = me.props["/gear/gear[0]/position-norm"].getValue();
		var lg = me.props["/gear/gear[1]/position-norm"].getValue();
		var rg = me.props["/gear/gear[2]/position-norm"].getValue();
		
		if (fg > 0) {
			me.elems["gearF.C"].show();
			me.elems["gearF.T"].show();
			if (fg == 1) {
				me.elems["gearF.C"].setColor(0,1,0);
				me.elems["gearF.T"].setColor(0,1,0);
				me.elems["gearF.T"].setText("DN");
			}
            else {
				me.elems["gearF.C"].setColor(1,1,0);
				me.elems["gearF.T"].setColor(1,1,0);
				me.elems["gearF.T"].setText("TR");
			}
		}
        else {
			me.elems["gearF.C"].hide();
			me.elems["gearF.T"].hide();
		}
        if (lg > 0) {
			me.elems["gearL.C"].show();
			me.elems["gearL.T"].show();
			if (lg == 1) {
				me.elems["gearL.C"].setColor(0,1,0);
				me.elems["gearL.T"].setColor(0,1,0);
				me.elems["gearL.T"].setText("DN");
			}
            else {
				me.elems["gearL.C"].setColor(1,1,0);
				me.elems["gearL.T"].setColor(1,1,0);
				me.elems["gearL.T"].setText("TR");
			}
		}
        else {
			me.elems["gearL.C"].hide();
			me.elems["gearL.T"].hide();
		}
        if (rg > 0) {
			me.elems["gearR.C"].show();
			me.elems["gearR.T"].show();
			if (rg == 1) {
				me.elems["gearR.C"].setColor(0,1,0);
				me.elems["gearR.T"].setColor(0,1,0);
				me.elems["gearR.T"].setText("DN");
			}
            else {
				me.elems["gearR.C"].setColor(1,1,0);
				me.elems["gearR.T"].setColor(1,1,0);
				me.elems["gearR.T"].setText("TR");
			}
		}
        else {
			me.elems["gearR.C"].hide();
			me.elems["gearR.T"].hide();
		}
		
		var autobrake = me.props["/autopilot/autobrake/step"].getValue();
		if (autobrake == 0) {
			me.elems["AB"].setText("OFF");
		}
        else if (autobrake == 1) {
			me.elems["AB"].setText("LO");
		}
        else if (autobrake == 2) {
			me.elems["AB"].setText("MED");
		}
        else if (autobrake == 3) {
			me.elems["AB"].setText("HI");
		}
        else if (autobrake == -1) {
			me.elems["AB"].setText("RTO");
		}
		
		var apurpm = me.props["/engines/apu/rpm"].getValue();
		var aputmp = me.props["/engines/apu/temp-c"].getValue() or 0;
		me.elems["apu.PCT"].setText(sprintf("%3i", apurpm));
		me.elems["apu.DEGC"].setText(sprintf("%3i", aputmp));
		
	},
};

var initialized = 0;
var eicas_display = nil;
var eicas_master = nil;
var eicas = nil;

var listeners = [];

var teardown = func {
    initialized = 0;
    foreach (var l; listeners) {
        removelistener(l);
    }
    listeners = [];
    eicas.deinit();
    eicas = nil;
    eicas_display.del();
    eicas_display = nil;
};

var initialize = func {
    if (initialized) { teardown(); }
    initialized = 1;
    eicas_display = canvas.new({
        "name": "EICAS",
        "size": [1024, 2048],
        "view": [1024, 1404],
        "mipmapping": 1
    });
    eicas_display.addPlacement({"node": "EICAS.face"});
    eicas_master = eicas_display.createGroup();
    eicas = EICAS.new().init(eicas_master);
    outputProp = props.globals.getNode("systems/electrical/outputs/eicas");
    enabledProp = props.globals.getNode("instrumentation/eicas/enabled");
    var check = func {
        var visible = ((outputProp.getValue() or 0) >= 15) and enabledProp.getBoolValue();
        eicas_master.setVisible(visible);
        if (visible) {
            eicas.activate();
        }
        else {
            eicas.deactivate();
        }
    };
    append(listeners, setlistener(outputProp, check, 1, 0));
    append(listeners, setlistener(enabledProp, check, 1, 0));
};

setlistener("sim/signals/fdm-initialized", initialize);
