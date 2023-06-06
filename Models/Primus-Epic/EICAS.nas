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
};

var msgColors = [
    [0, 1, 1], # MAINTENANCE: BLUE
    [1, 1, 1], # STATUS: WHITE
    [0, 1, 1], # ADVISORY: CYAN
    [1, 1, 0], # CAUTION: AMBER
    [1, 0, 0], # WARNING: RED
];

var msgKeys = [
    'maintenance',
    'status',
    'advisory',
    'caution',
    'warning',
];

var EICAS = {
    new: func () {
        # TODO: make EICAS available from both sides.
        var m = canvas_base.BaseScreen.new(0, 2);
        m.parents = [EICAS] ~ m.parents;
        m.timer = nil;
        m.messageMap = [];
        m.messageCounts = {
            cautionAbove: 0,
            cautionBelow: 0,
            advisoryAbove: 0,
            advisoryBelow: 0,
            statusAbove: 0,
            statusBelow: 0,
        };
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
        me.registerProp('message-list.selected', "/instrumentation/eicas/message-list/selected");
        me.registerProp('message-list.scroll-pos', "/instrumentation/eicas/message-list/scroll-pos");
        me.registerProp('message-list.min-scroll', "/instrumentation/eicas/message-list/min-scroll");
        me.registerProp('message-list.max-scroll', "/instrumentation/eicas/message-list/max-scroll");
        me.registerProp('message-list.counts.caution', "/instrumentation/eicas/message-list/counts/caution");
        me.registerProp('message-list.counts.warning', "/instrumentation/eicas/message-list/counts/warning");
        me.registerProp('message-list.counts.advisory', "/instrumentation/eicas/message-list/counts/advisory");
        me.registerProp('message-list.counts.status', "/instrumentation/eicas/message-list/counts/status");
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
        me.registerProp("/fadec/attcs/armed");
        me.registerProp("/fadec/attcs/engaged");
        me.registerProp("/fdm/jsbsim/fcs/flap-cmd-int-deg");
        me.registerProp("/fdm/jsbsim/fcs/flap-pos-deg");
        me.registerProp("/fdm/jsbsim/fcs/slat-cmd-int-deg");
        me.registerProp("/fdm/jsbsim/fcs/slat-pos-deg");
        me.registerProp("/fms/takeoff-conditions/oat");
        me.registerProp("/gear/gear[0]/position-norm");
        me.registerProp("/gear/gear[1]/position-norm");
        me.registerProp("/gear/gear[2]/position-norm");
        me.registerProp("/surface-positions/speedbrake-pos-norm");
        me.registerProp("/trs/mode");
        me.registerProp("/trs/rsv");
        me.registerProp("/trs/thrust/climb-submode");
        me.registerProp("/trs/thrust/to-submode");
        me.registerProp("blink", "/instrumentation/eicas/blink-state");
        me.registerProp("messages-changed", "/instrumentation/eicas/signals/messages-changed");
        me.registerProp("declutter", "/instrumentation/eicas/declutter/active");
        me.registerProp("/systems/pressurization/pressures/diff-psi");
        me.registerProp("/systems/pressurization/pressures/cabin-ft");
        me.registerProp("/systems/pressurization/pressures/rate-fpm");
        me.registerProp("/systems/pressurization/pressures/lfe-ft");
        me.registerProp("/systems/pressurization/pressures/lfe-from-fms");
        me.registerProp("/systems/pressurization/signals/cabin-ft-caution");
        me.registerProp("/systems/pressurization/signals/cabin-ft-warning");
        me.registerProp("/systems/pressurization/signals/diff-psi-caution");
        me.registerProp("/systems/pressurization/signals/diff-psi-warning");
        me.registerProp("/systems/pressurization/signals/rate-fpm-caution");
    },

    makeMasterGroup: func (group) {
        call(canvas_base.BaseScreen.makeMasterGroup, [group], me);
        canvas.parsesvg(group, "Aircraft/E-jet-family/Models/Primus-Epic/eicas.svg", { 'font-mapper': me.font_mapper });
    },

    registerElems: func () {
        call(canvas_base.BaseScreen.registerElems, [], me);
        me.registerElemsFrom([
            "AB",
            "ailerontrim.pointer",
            "apu.DEGC",
            "apu.PCT",
            "apu.section",
            "attcs",
            "engL.off",
            "engR.off",
            "FFL",
            "FFR",
            "flaps.IND",
            "flaps.SCALE",
            "flaps-spoilers.section",
            "flaps.TGT",
            "flaps.UP",
            "FQC",
            "FQL",
            "FQR",
            "fs",
            "gearF.C",
            "gearF.T",
            "gearL.C",
            "gearL.T",
            "gearR.C",
            "gearR.T",
            "gear.section",
            "ITTL",
            "ITTL.needle",
            "ITTR",
            "ITTR.needle",
            "limitL.digital",
            "limitR.digital",
            "msg.0",
            "msg.0.bg",
            "msg.1",
            "msg.10",
            "msg.10.bg",
            "msg.11",
            "msg.11.bg",
            "msg.12",
            "msg.12.bg",
            "msg.13",
            "msg.13.bg",
            "msg.14",
            "msg.14.bg",
            "msg.1.bg",
            "msg.2",
            "msg.2.bg",
            "msg.3",
            "msg.3.bg",
            "msg.4",
            "msg.4.bg",
            "msg.5",
            "msg.5.bg",
            "msg.6",
            "msg.6.bg",
            "msg.7",
            "msg.7.bg",
            "msg.8",
            "msg.8.bg",
            "msg.9",
            "msg.9.bg",
            "msg.count-above.advisory",
            "msg.count-above.advisory.bg",
            "msg.count-above.advisory.ptr",
            "msg.count-above.advisory.text",
            "msg.count-above.caution",
            "msg.count-above.caution.bg",
            "msg.count-above.caution.ptr",
            "msg.count-above.caution.text",
            "msg.count-above.status",
            "msg.count-above.status.bg",
            "msg.count-above.status.ptr",
            "msg.count-above.status.text",
            "msg.count-below.advisory",
            "msg.count-below.advisory.bg",
            "msg.count-below.advisory.ptr",
            "msg.count-below.advisory.text",
            "msg.count-below.caution",
            "msg.count-below.caution.bg",
            "msg.count-below.caution.ptr",
            "msg.count-below.caution.text",
            "msg.count-below.status",
            "msg.count-below.status.bg",
            "msg.count-below.status.ptr",
            "msg.count-below.status.text",
            "msg.highlight",
            "msg.status",
            "msg.status.highlight",
            "N1L",
            "N1L.lever",
            "N1L.needle",
            "N1L.rated-max",
            "N1R",
            "N1R.lever",
            "N1R.needle",
            "N1R.rated-max",
            "N2L",
            "N2R",
            "oil.section",
            "OPL",
            "OPR",
            "OTL",
            "OTR",
            "pitchtrim.digital",
            "pitchtrim.pointer",
            "pressure.cabinalt.text",
            "pressure.diff.text",
            "pressure.lfe.text",
            "pressure.rate.text",
            "revL",
            "revR",
            "ruddertrim.pointer",
            "slat.IND",
            "slat.SCALE",
            "slat.TGT",
            "spoilers.ANN",
            "spoilers.DOWN",
            "spoilers.IND",
            "trsMode",
            "trsTemp",
            "vib.section",
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
        me.addListener('main', '@message-list.selected', func (node) {
            var visible = node.getBoolValue();
            self.elems['msg.highlight'].setVisible(visible);
            self.elems['msg.status.highlight'].setVisible(visible);
        }, 1, 0);
        me.addListener('main', '/systems/pressurization/pressures/lfe-ft', func { self.updateLFE(); });
        me.addListener('main', '/systems/pressurization/pressures/lfe-from-fms', func { self.updateLFE(); }, 1);
        me.addListener('main', '/systems/pressurization/signals/cabin-ft-caution', func { self.updateCabinFtColor(); }, 1);
        me.addListener('main', '/systems/pressurization/signals/cabin-ft-warning', func { self.updateCabinFtColor(); }, 1);
        me.addListener('main', '/systems/pressurization/signals/diff-psi-caution', func { self.updateDiffPsiColor(); }, 1);
        me.addListener('main', '/systems/pressurization/signals/diff-psi-warning', func { self.updateDiffPsiColor(); }, 1);
        me.addListener('main', '/systems/pressurization/signals/rate-fpm-caution', func { self.updateRateFpmColor(); }, 1);
    },

    updateLFE: func () {
        var fromFMS = me.props["/systems/pressurization/pressures/lfe-from-fms"].getBoolValue();
        var lfe = me.props["/systems/pressurization/pressures/lfe-ft"].getValue();
        if (fromFMS) {
            me.elems["pressure.lfe.text"]
                .setText(sprintf("%5.0f", me.props["/systems/pressurization/pressures/lfe-ft"].getValue() or 0))
                .setColor(0, 1, 0);
        }
        else {
            me.elems["pressure.lfe.text"]
                .setText(sprintf("M%5.0f", me.props["/systems/pressurization/pressures/lfe-ft"].getValue() or 0))
                .setColor(0, 1, 1);
        }
    },

    updateCabinFtColor: func () {
        var e = me.elems["pressure.cabinalt.text"];
        if (me.props["/systems/pressurization/signals/cabin-ft-warning"].getBoolValue()) {
            e.setColor(1, 0, 0);
        }
        elsif (me.props["/systems/pressurization/signals/cabin-ft-caution"].getBoolValue()) {
            e.setColor(1, 1, 0);
        }
        else {
            e.setColor(0, 1, 0);
        }
    },

    updateDiffPsiColor: func () {
        var e = me.elems["pressure.diff.text"];
        if (me.props["/systems/pressurization/signals/diff-psi-warning"].getBoolValue()) {
            e.setColor(1, 0, 0);
        }
        elsif (me.props["/systems/pressurization/signals/diff-psi-caution"].getBoolValue()) {
            e.setColor(1, 1, 0);
        }
        else {
            e.setColor(0, 1, 0);
        }
    },

    updateRateFpmColor: func () {
        var e = me.elems["pressure.rate.text"];
        if (me.props["/systems/pressurization/signals/rate-fpm-caution"].getBoolValue()) {
            e.setColor(1, 1, 0);
        }
        else {
            e.setColor(0, 1, 0);
        }
    },

    makeWidgets: func () {
        call(canvas_base.BaseScreen.makeWidgets, [], me);
        var self = me;

        me.addWidget('msg.highlight', { onclick: func { self.clickMessages(); } });
    },

    clickMessages: func () {
        me.props['message-list.selected'].setBoolValue(1);
    },

    masterClick: func (x, y) {
        me.props['message-list.selected'].setBoolValue(0);
    },

    masterScroll: func (amount, which) {
        if (me.props['message-list.selected'].getBoolValue()) {
            me.scrollMessages(amount);
        }
    },

    scrollMessages: func (amount) {
        var minScroll = me.props['message-list.min-scroll'].getValue() or 0;
        var maxScroll = me.props['message-list.max-scroll'].getValue() or 0;
        var scrollPos = me.props['message-list.scroll-pos'].getValue() or 0;
        scrollPos = math.min(maxScroll, math.max(minScroll, scrollPos + amount));
        me.props['message-list.scroll-pos'].setValue(scrollPos);
        me.updateMessages();
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
        var scrollPos = me.props['message-list.scroll-pos'].getValue();
        foreach (var msg; me.messageMap) {
            txt = me.elems['msg.' ~ i];
            bg = me.elems['msg.' ~ i ~ '.bg'];
            if (msg == nil) {
                bg.setColorFill(0, 0, 0, 1);
                txt.setColor(0, 0, 0);
            }
            else {
                (r, g, b) = msgColors[msg.level];
                if (blink and (msg.blink != 0)) {
                    bg.setColorFill(r, g, b, 1);
                    txt.setColor(0, 0, 0);
                }
                else {
                    bg.setColorFill(0, 0, 0, 1);
                    txt.setColor(r, g, b);
                }
            }
            i += 1;
        }
        var counts = {
            'caution': { 'above': 0, 'below': 0 },
            'advisory': { 'above': 0, 'below': 0 },
            'status': { 'above': 0, 'below': 0 },
        };
        
        var firstScrolled = messages.messageCounts[messages.MSG_WARNING] + scrollPos;
        var firstBelow = scrollPos + 15;
        var blinkingCounts = {
            above: [0,0,0,0,0],
            below: [0,0,0,0,0],
        };

        for (i = 0; i < firstScrolled; i += 1) {
            var msg = messages.messages[i];
            if (msg == nil) break;
            if (msg.blink != 0)
                blinkingCounts.above[msg.level] = 1;
        }
        for (i = firstBelow; i < size(messages.messages); i += 1) {
            var msg = messages.messages[i];
            if (msg == nil) break;
            if (msg.blink != 0)
                blinkingCounts.below[msg.level] = 1;
        }

        foreach (var level; [messages.MSG_CAUTION, messages.MSG_ADVISORY, messages.MSG_STATUS]) {
            (r, g, b) = msgColors[level];
            foreach (var where; ['above', 'below']) {
                var key = 'msg.count-' ~ where ~ '.' ~ msgKeys[level];
                if (blinkingCounts[where][level] and blink) {
                    me.elems[key ~ '.text'].setColor(0, 0, 0);
                    me.elems[key ~ '.ptr'].setColorFill(0, 0, 0, 1);
                    me.elems[key ~ '.bg'].setColorFill(r, g, b, 1);
                }
                else {
                    me.elems[key ~ '.text'].setColor(r, g, b);
                    me.elems[key ~ '.ptr'].setColorFill(r, g, b, 1);
                    me.elems[key ~ '.bg'].setColorFill(0, 0, 0, 1);
                }
            }
        }
    },

    updateMessages: func () {
        var scrollPos = me.props['message-list.scroll-pos'].getValue() or 0;
        var maxScroll = me.props['message-list.max-scroll'].getValue() or 0;

        var i = 0;
        var m = 0;
        var level = messages.MSG_WARNING;
        var msg = nil;
        var counts = {
                warning: 0,
                caution: 0,
                advisory: 0,
                status: 0,
            };

        me.messageMap = [];

        foreach (msg; messages.messages) {
            if (msg.level == messages.MSG_WARNING)
                counts.warning += 1;
            elsif (msg.level == messages.MSG_CAUTION)
                counts.caution += 1;
            elsif (msg.level == messages.MSG_ADVISORY)
                counts.advisory += 1;
            elsif (msg.level == messages.MSG_STATUS)
                counts.status += 1;
        }

        me.props['message-list.counts.warning'].setValue(counts.warning);
        me.props['message-list.counts.caution'].setValue(counts.caution);
        me.props['message-list.counts.advisory'].setValue(counts.advisory);
        me.props['message-list.counts.status'].setValue(counts.status);

        var firstVisibleOf = [0, 0, 0, 0, 0];
        var lastVisibleOf = [0, 0, 0, 0, 0];

        for (i = 0; i < 15; i += 1) {
            if (m >= size(messages.messages)) {
                msg = nil;
            }
            else {
                msg = messages.messages[m];
                if (level == messages.MSG_WARNING and msg.level != messages.MSG_WARNING) {
                    maxScroll = math.max(size(messages.messages) - 15, 0);
                    scrollPos = math.min(maxScroll, scrollPos);
                    me.props['message-list.scroll-pos'].setValue(scrollPos);
                    me.props['message-list.max-scroll'].setValue(maxScroll);
                    m += scrollPos;
                    if (m >= size(messages.messages)) {
                        msg = nil;
                    }
                    else {
                        msg = messages.messages[m];
                    }
                }
            }
            if (msg != nil) {
                if (level != msg.level)
                    firstVisibleOf[msg.level] = m;
                level = msg.level;
                lastVisibleOf[level] = m;
            }
            append(me.messageMap, msg);

            m += 1;
        }

        var elem = nil;

        i = 0;
        foreach (msg; me.messageMap) {
            elem = me.elems['msg.' ~ i];
            bg = me.elems['msg.' ~ i];
            if (elem != nil) {
                if (msg == nil) {
                    elem.setText("");
                }
                elsif (msg.rootEicas) {
                    elem.setText(">" ~ msg.text ~ "  ");
                }
                else {
                    elem.setText("  " ~ msg.text ~ "  ");
                }
            }
            i += 1;
        }

        if (maxScroll > 0) {
            me.messageCounts.cautionAbove = math.min(counts.caution, scrollPos);
            me.messageCounts.cautionBelow = math.max(0, math.min(counts.caution, counts.caution - scrollPos - 15 + counts.warning));
            me.messageCounts.advisoryAbove = math.max(0, math.min(counts.advisory, scrollPos - counts.caution));
            me.messageCounts.advisoryBelow = math.max(0, math.min(counts.advisory, counts.advisory - scrollPos - 15 + counts.warning + counts.caution));
            me.messageCounts.statusAbove = math.max(0, math.min(counts.status, scrollPos - counts.caution - counts.advisory));
            me.messageCounts.statusBelow = math.max(0, math.min(counts.status, counts.status - scrollPos - 15 + counts.warning + counts.caution + counts.advisory));
            me.elems['msg.count-above.caution.text'].setText(sprintf("%2i", me.messageCounts.cautionAbove));
            me.elems['msg.count-above.caution'].setVisible(me.messageCounts.cautionAbove > 0);
            me.elems['msg.count-below.caution.text'].setText(sprintf("%2i", me.messageCounts.cautionBelow));
            me.elems['msg.count-below.caution'].setVisible(me.messageCounts.cautionBelow > 0);
            me.elems['msg.count-above.advisory.text'].setText(sprintf("%2i", me.messageCounts.advisoryAbove));
            me.elems['msg.count-above.advisory'].setVisible(me.messageCounts.advisoryAbove > 0);
            me.elems['msg.count-below.advisory.text'].setText(sprintf("%2i", me.messageCounts.advisoryBelow));
            me.elems['msg.count-below.advisory'].setVisible(me.messageCounts.advisoryBelow > 0);
            me.elems['msg.count-above.status.text'].setText(sprintf("%2i", me.messageCounts.statusAbove));
            me.elems['msg.count-above.status'].setVisible(me.messageCounts.statusAbove > 0);
            me.elems['msg.count-below.status.text'].setText(sprintf("%2i", me.messageCounts.statusBelow));
            me.elems['msg.count-below.status'].setVisible(me.messageCounts.statusBelow > 0);
            me.elems['msg.status'].show();
        }
        else {
            me.elems['msg.status'].hide();
        }

        me.updateBlinks();
    },

	update: func (dt) {
        call(canvas_base.BaseScreen.update, [dt], me);
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
            if (me.props["/trs/rsv"].getBoolValue()) {
                modeLabel = modeLabel ~ "-RSV";
            }
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

        if (me.props["/fadec/attcs/engaged"].getBoolValue()) {
            me.elems["attcs"].setColor(0, 1, 0).show();
        }
        elsif (me.props["/fadec/attcs/armed"].getBoolValue()) {
            me.elems["attcs"].setColor(1, 1, 1).show();
        }
        else {
            me.elems["attcs"].hide();
        }

        me.elems["trsTemp"].setText(sprintf("%2i°", me.props["/fms/takeoff-conditions/oat"].getValue()));
		
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

        me.elems["pressure.cabinalt.text"].setText(sprintf("%5.0f", me.props["/systems/pressurization/pressures/cabin-ft"].getValue() or 0));
        me.elems["pressure.rate.text"].setText(sprintf("%+1.0f", me.props["/systems/pressurization/pressures/rate-fpm"].getValue() or 0));
        me.elems["pressure.diff.text"].setText(sprintf("%4.1f", me.props["/systems/pressurization/pressures/diff-psi"].getValue() or 0));
		
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
    eicas_display.addPlacement({"node": "EICAS"});
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
