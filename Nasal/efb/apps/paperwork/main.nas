include('baseApp.nas');
include('gui/pager.nas');
include('gui/keyboard.nas');

var PaperworkApp = {
    new: func(masterGroup) {
        var m = BaseApp.new(masterGroup);
        m.parents = [me] ~ m.parents;
        m.ofp = nil;
        m.pages = [];
        m.tocVisible = 0;
        m.tocAnimState = 0;
        m.tocAnimTimer = nil;
        m.entryMode = nil;
        m.zoomScrollPane = nil;
        m.zoom = 1;
        m.sx = 0;
        m.sy = 0;
        return m;
    },

    handleBack: func () {
    },

    initialize: func () {
        var self = me;
        me.metrics = {
            pageWidth: 414,
            pageHeight: 670,
            fontSize: 10,
            charWidth: 5.935,
            lineHeight: 10.5,
            headerHeight: 22,
            rows: 61,
            columns: 68,
            tocPaneWidth: 250,
            tocPaneTop: 32,
            tocPaneHeight: 768 - 64,
            tocPadding: 10,
            tocFontSize: 14,
            tocLineHeight: 20,
            inputPadding: 1,
            menuFontSize: 16,
            menuLineHeight: 32,
            menuItemPadding: 4,
        };
        me.metrics.marginLeft = (512 - me.metrics.pageWidth) / 2;
        me.metrics.marginTop = (738 - me.metrics.pageHeight) / 2;
        me.metrics.paddingTop = (me.metrics.pageHeight - me.metrics.headerHeight - me.metrics.lineHeight * me.metrics.rows) / 2;
        me.metrics.paddingLeft = (me.metrics.pageWidth - me.metrics.charWidth * me.metrics.columns) / 2;

        me.mainWidget = Widget.new();
        me.rootWidget.appendChild(me.mainWidget);
        me.pageWidgets = [];

        me.tocWidget = Widget.new();
        me.rootWidget.appendChild(me.tocWidget);

        me.tocContentsWidget = Widget.new();
        me.tocWidget.appendChild(me.tocContentsWidget);

        me.simbriefUsernameProp = props.globals.getNode('/sim/simbrief/username');
        me.bgfill = me.masterGroup.createChild('path')
                        .rect(0, 0, 512, 768)
                        .setColorFill(0.8, 0.9, 1.0);
        me.contentGroup = me.masterGroup.createChild('group');

        me.pagerGroup = me.masterGroup.createChild('group');

        me.pager = Pager.new(me.pagerGroup);
        me.rootWidget.appendChild(me.pager);
        me.pager.pageChanged.addListener(func (data) {
            foreach (var p; self.pages) {
                p.hide();
            }
            if (data.page < size(self.pages)) {
                self.pages[data.page].show();
            }
        });

        me.keyboardGroup = me.masterGroup.createChild('group');
        me.keyboard = Keyboard.new(me.keyboardGroup, 0);
        me.keyboard.keyPressed.addListener(func (key) {
            self.handleKey(key);
        });
        me.rootWidget.appendChild(me.keyboard);

        me.tocPaneGroup = me.masterGroup.createChild('group');
        me.tocPaneGroup.createChild('path')
                .rect(0, me.metrics.tocPaneTop, me.metrics.tocPaneWidth, me.metrics.tocPaneHeight)
                .setColor(0.5, 0.5, 0.5)
                .setColorFill(1, 1, 1);
        me.tocPaneButton = me.tocPaneGroup.createChild('group');
        me.tocPaneButton.createChild('path')
                .moveTo(me.metrics.tocPaneWidth - 1, me.metrics.tocPaneTop + me.metrics.tocPaneHeight / 2 - 32)
                .arcLargeCW(32, 32, 0, 0, 64)
                .setColor(0.5, 0.5, 0.5)
                .setColorFill(1, 1, 1);
        me.tocPaneButtonArrow = me.tocPaneButton.createChild('path')
                .setTranslation(me.metrics.tocPaneWidth + 12, me.metrics.tocPaneTop + me.metrics.tocPaneHeight / 2)
                .moveTo(-16, 0)
                .line(16, -12)
                .line(0, 8)
                .line(12, 0)
                .line(0, 8)
                .line(-12, 0)
                .line(0, 8)
                .line(-16, -12)
                .setColorFill(0.3, 0.3, 0.3);
        me.tocContentsGroup = me.tocPaneGroup.createChild('group').setTranslation(0, me.metrics.tocPaneTop);
        me.makeClickable(me.tocPaneButton, func {
            self.toggleTOC();
        }, me.tocWidget);
        me.updateTocViz();
        me.tocAnimTimer = maketimer(1/30, func {
            if (self.tocAnimState < self.tocVisible) {
                self.tocAnimState += 0.1;
                self.tocAnimState = math.min(self.tocAnimState, self.tocVisible);
                self.updateTocViz();
            }
            elsif (self.tocAnimState > self.tocVisible) {
                self.tocAnimState -= 0.1;
                self.tocAnimState = math.max(self.tocAnimState, self.tocVisible);
                self.updateTocViz();
            }
        });
        me.tocAnimTimer.simulatedTime = 1;
        me.hideKeyboard();
        me.tocAnimTimer.start();

        me.showStartMenu();
    },

    scrollIntoView: func(elem) {
        var pos = elem.getBoundingBox();

        var left = (pos[0] + me.metrics.marginLeft) * 1.5;
        var right = (pos[2] + me.metrics.marginLeft) * 1.5;
        var top = (pos[1] + me.metrics.marginTop) * 1.5;
        var bottom = (pos[3] + me.metrics.marginTop) * 1.5;

        var dx = 0;
        var dy = 0;

        if (left < 0)
            dx = -left;
        elsif (right > 498)
            dx = 498 - right;
        if (top < 32)
            dy = 32-top;
        elsif (bottom > 450)
            dy = 450 - bottom;
        me.contentGroup.setTranslation(dx, dy)
                       .setScale(1.5, 1.5);
    },

    resetScroll: func() {
        me.contentGroup.setTranslation(0, 0)
                       .setScale(1, 1);
    },

    showKeyboard: func (mode=nil) {
        if (mode == nil)
            mode = Keyboard.LAYER_UPPER;
        me.keyboard.setActive(1);
        me.keyboard.selectLayer(mode);
    },

    hideKeyboard: func () {
        me.keyboard.setActive(0);
    },

    showPager: func {
        me.pager.setActive(1);
        me.pagerGroup.show();
    },

    hidePager: func {
        me.pager.setActive(0);
        me.pagerGroup.hide();
    },

    enableTOC: func {
        me.tocPaneGroup.show();
    },

    disableTOC: func {
        me.tocPaneGroup.hide();
        me.hideTOC();
    },

    startEntry: func (ident, elem, box, node, exitFunc, datatype=nil) {
        var kbmode = Keyboard.LAYER_LOWER;
        if (datatype == 'numeric')
            kbmode = Keyboard.LAYER_SYM2;
        elsif (datatype == 'uppercase')
            kbmode = Keyboard.LAYER_UPPER;
        me.showKeyboard(kbmode);
        me.scrollIntoView(box);
        if (typeof(node) == 'scalar') {
            var nodePath = node;
            node = me.ofp.getNode(nodePath, 1);
        }
        var value = node.getValue();
        if (typeof(value) == 'scalar')
            value = value ~ '';
        else
            value = '';
        me.entryMode = {
            ident: ident,
            elem: elem,
            node: node,
            value: value,
            datatype: datatype or 'text',
            exit: exitFunc
        };
    },

    confirmEntry: func () {
        me.resetScroll();
        me.hideKeyboard();
        if (me.entryMode == nil) {
            return;
        }
        me.entryMode.node.setValue(me.entryMode.value);
        me.entryMode.elem.setText(me.entryMode.value);
        me.entryMode.exit();
        me.entryMode = nil;
    },

    cancelEntry: func () {
        me.resetScroll();
        me.hideKeyboard();
        if (me.entryMode == nil) {
            return;
        }
        var value = me.entryMode.node.getValue();
        if (typeof(value) == 'scalar')
            value = value ~ '';
        else
            value = '';
        me.entryMode.elem.setText(value);
        me.entryMode.exit();
        me.entryMode = nil;
    },

    updateEntry: func () {
        me.entryMode.elem.setText(me.entryMode.value);
    },

    handleKey: func (key) {
        if (me.entryMode == nil) {
            # Keyboard shouldn't even be visible!
            me.hideKeyboard();
            return 1;
        }
        if (key == 'enter') {
            me.confirmEntry();
        }
        elsif (key == 'backspace') {
            me.entryMode.value = substr(me.entryMode.value, 0, size(me.entryMode.value) - 1);
            me.updateEntry();
        }
        elsif (key == 'space') {
            me.entryMode.value = me.entryMode.value ~ ' ';
            me.updateEntry();
        }
        elsif (key == 'esc') {
            me.cancelEntry();
        }
        else {
            if (me.entryMode.datatype == 'numeric') {
                if (!isint(key))
                    return;
            }
            elsif (me.entryMode.datatype == 'uppercase') {
                key = string.uc(key);
            }
            me.entryMode.value = me.entryMode.value ~ key;
            me.updateEntry();
        }
    },

    foreground: func {
        me.tocAnimTimer.start();
    },

    background: func {
        me.tocAnimTimer.stop();
    },

    hideTOC: func () {
        me.setTocViz(0);
    },

    showTOC: func () {
        me.setTocViz(1);
    },

    toggleTOC: func () {
        me.setTocViz(!me.tocVisible);
    },

    setTocViz: func (viz) {
        me.tocVisible = viz;
        me.updateTocViz();
    },

    updateTocViz: func {
        if (me.tocVisible) {
            me.tocPaneButtonArrow.setScale(1, 1);
        }
        else {
            me.tocPaneButtonArrow.setScale(-1, 1);
        }
        me.tocPaneGroup.setTranslation((-1 + me.tocAnimState) * me.metrics.tocPaneWidth, 0);
    },

    loadSimbriefOFP: func () {
        var filename = getprop('/sim/fg-home') ~ "/Export/simbrief.xml";
        return me.loadOFPFile(filename);
    },

    loadOFPFile: func (filename) {
        var err = [];
        me.ofp = call(io.readxml, [filename], io, {}, err);
        return me.ofp != nil;
    },

    getOFPNode: func(path) {
        return me.ofp.getNode(path, 1);
    },

    getOFPValue: func(path, default='') {
        var value = me.ofp.getValue('OFP/' ~ path);
        if (value == nil)
            value = default;
        return value;
    },

    getOFPValues: func(path, subkey=nil, forceVector=1) {
        var node = me.ofp.getNode('OFP/' ~ path);
        if (node == nil)
            return nil;
        var val = node.getValues();
        if (val == nil)
            return nil;
        if (subkey != nil) {
            if (!contains(val, subkey))
                val = nil;
            else
                val = val[subkey];
        }
        if (typeof(val) != 'vector' and forceVector)
            val = [val];
        return val;
    },

    collectOFPItems: func () {
        var items = [];
        var newline = func () {
            append(items, { type: 'blank' });
        };
        var plain = func (text, centerW=0) {
            if (centerW > 0) {
                var paddingSize = math.floor((centerW - size(text)) / 2);
                var padding = substr('                                                                    ', 0, paddingSize);
                text = padding ~ text;
            }
            append(items, { type: 'text', text: text });
        };
        var pageBreak = func () {
            append(items, { type: 'page-break' });
        };
        var separator = func (length=nil) {
            if (length == nil)
                length = me.metrics.columns;
            append(items, { type: 'separator', length: length });
        };
        var format = func (fmt, args) {
            append(items, { type: 'formatted', format: fmt, args: args });
        };
        var toc = func (title) {
            append(items, { type: 'toc-entry', title: title });
        };
        var multi = func (subItems) {
            append(items, { type: 'multi', items: subItems });
        };
        var subText = func (x, w, text, centerW=0) {
            if (centerW > 0) {
                var paddingSize = math.floor((centerW - size(text)) / 2);
                var padding = substr('                                                                    ', 0, paddingSize);
                text = padding ~ text;
            }
            return {
                x: x,
                w: w,
                type: 'text',
                text: text
            };
        };
        var subFmt = func (x, w, fmt, args) {
            return {
                x: x,
                w: w,
                type: 'formatted',
                format: fmt,
                args: args
            };
        };
        var subEntry = func (x, w, path, validate=nil) {
            var datatype = 'text';
            if (typeof(validate) == 'scalar') {
                datatype = validate;
                validate = nil;
            }
            return {
                x: x,
                w: w,
                type: 'entry',
                path: path,
                validate: validate,
                datatype: datatype,
            };
        };

        # for (var i = 1; i <= me.metrics.rows; i += 1) {
        #     plain(sprintf('--- TEST LINE %2i ---', i), me.metrics.columns);
        # }
        # pageBreak();

        plain('[ OFP ]');
        separator();

        var generated = unixToDateTime(me.getOFPValue('params/time_generated'));
        var schedOut = unixToDateTime(me.getOFPValue('times/sched_out'));
        var schedOff = unixToDateTime(me.getOFPValue('times/sched_off'));
        var schedOn = unixToDateTime(me.getOFPValue('times/sched_on'));
        var schedIn = unixToDateTime(me.getOFPValue('times/sched_in'));
        var estOn = unixToDateTime(me.getOFPValue('times/est_on'));
        var estIn = unixToDateTime(me.getOFPValue('times/est_in'));
        var schedOutLocal = unixToDateTime(me.getOFPValue('times/sched_out') + math.floor(me.getOFPValue('times/orig_timezone') * 3600));
        var schedOffLocal = unixToDateTime(me.getOFPValue('times/sched_off') + math.floor(me.getOFPValue('times/orig_timezone') * 3600));
        var schedOnLocal = unixToDateTime(me.getOFPValue('times/sched_on') + math.floor(me.getOFPValue('times/dest_timezone') * 3600));
        var schedInLocal = unixToDateTime(me.getOFPValue('times/sched_in') + math.floor(me.getOFPValue('times/dest_timezone') * 3600));
        var estOnLocal = unixToDateTime(me.getOFPValue('times/est_on') + math.floor(me.getOFPValue('times/dest_timezone') * 3600));
        var estInLocal = unixToDateTime(me.getOFPValue('times/est_in') + math.floor(me.getOFPValue('times/dest_timezone') * 3600));
        var isEtops = me.getOFPValue('general/is_etops');

        # Page 1

        toc('Summary and Fuel');
        format('%-3s%-6s %02i%3s%04i    %-4s-%-4s   %-4s %-7s RELEASE %02i%02i %02i%3s%02i',
            [ 'OFP:general/icao_airline'
            , 'OFP:general/flight_number'
            , schedOut.day, monthNames3[schedOut.month], schedOut.year
            , 'OFP:origin/icao_code'
            , 'OFP:destination/icao_code'
            , 'OFP:aircraft/icaocode'
            , 'OFP:aircraft/reg'
            , generated.hour, generated.minute
            , generated.day, monthNames3[generated.month], math.mod(generated.year, 100)
            ]);
        format('OFP %-3i         %s-%s',
            [ 'OFP:general/release'
            , 'OFP:origin/name'
            , 'OFP:destination/name'
            ]);
        newline(); # TODO: figure out the WX PROG ... OBS ... line
        newline();
        multi([
            subText(2, 7, "ATC C/S"),
            subFmt(12, 12, '%s', ['OFP:atc/callsign']),
            subFmt(25, 8, '%s/%s', ['OFP:origin/icao_code', 'OFP:origin/iata_code']),
            subFmt(36, 8, '%s/%s', ['OFP:destination/icao_code', 'OFP:destination/iata_code']),
            subText(50, 7, 'CRZ SYS'),
            subFmt(58, 10, '%10s', ['OFP:general/cruise_profile']),
        ]);
        multi([
            subFmt(0, 9, '%02i%s%4i', [ schedOut.day, monthNames3[schedOut.month], schedOut.year ]),
            subFmt(12, 12, '%s', ['OFP:aircraft/reg']),
            subFmt(25, 9, '%02i%02i/%02i%02i', [schedOut.hour, schedOut.minute, schedOff.hour, schedOff.minute]),
            subFmt(36, 9, '%02i%02i/%02i%02i', [estOn.hour, estOn.minute, estIn.hour, estIn.minute]),
            subText(50, 8, 'GND DIST'),
            subFmt(59, 9, '%9s', ['OFP:general/route_distance']),
        ]);
        multi([
            subFmt(0, 21, '%s / %s', [ 'OFP:aircraft/name', 'N/A' ]),
            subFmt(36, 9, 'STA  %02i%02i', [schedIn.hour, schedIn.minute]),
            subText(50, 8, 'AIR DIST'),
            subFmt(59, 9, '%9s', ['OFP:general/air_distance']),
        ]);
        multi([
            subText(25, 5, 'CTOT:'),
            subEntry(30, 4, 'OFP:times/ctot', 'numeric'),
            subText(50, 8, 'G/C DIST'),
            subFmt(59, 9, '%9s', ['OFP:general/gc_distance']),
        ]);
        multi([
            subText(50, 8, 'AVG WIND'),
            subFmt(61, 7, '%03i/%03i', ['OFP:general/avg_wind_dir', 'OFP:general/avg_wind_spd']),
        ]);
        multi([
            subFmt(0, 21, 'MAXIMUM    TOW %6i', [ 'OFP:weights/max_tow' ]),
            subFmt(23, 10, 'LAW %6i', [ 'OFP:weights/max_ldw' ]),
            subFmt(35, 10, 'ZFW %6i', [ 'OFP:weights/max_zfw' ]),
            subText(50, 8, 'AVG W/C'),
            subFmt(64, 4,formatPM(3), ['OFP:general/avg_wind_comp']),
        ]);
        multi([
            subFmt(0, 21, 'ESTIMATED  TOW %6i', [ 'OFP:weights/est_tow' ]),
            subFmt(23, 10, 'LAW %6i', [ 'OFP:weights/est_ldw' ]),
            subFmt(35, 10, 'ZFW %6i', [ 'OFP:weights/est_zfw' ]),
            subText(50, 8, 'AVG ISA'),
            subFmt(64, 4, formatPM(3), ['OFP:general/avg_temp_dev']),
        ]);
        multi([
            subText(50, 13, 'AVG FF KGS/HR'),
            subFmt(64, 4, '%4i', ['OFP:fuel/avg_fuel_flow']),
        ]);
        multi([
            subText(50, 13, 'FUEL BIAS'),
            subFmt(63, 5, formatPM(2,1), [0]),
        ]);
        multi([
            subFmt(0, 9, 'ALTN %-4s', ['OFP:alternate/icao_code']),
            subText(50, 9, 'TKOF ALTN'),
            subEntry(61, 7, 'OFP:takeoff_altn/icao_code', 'uppercase')
        ]);
        multi([
            subText(0, 9, 'FL STEPS'),
            subFmt(10, 60, func(str) { str ~ '/'; }, ['OFP:general/stepclimb_string']),
        ]);
        separator();
        if (isEtops) {
            plain('*** ETOPS/ETP FLIGHT ***', me.metrics.columns);
            separator();
        }
        var remarks = (me.getOFPValues('general', 'dx_rmk') or []) ~
                      (me.getOFPValues('general', 'sys_rmk') or []);
        if (size(remarks) == 0)
            remarks = ['NIL'];
        var first = 1;
        foreach (var rmk; remarks) {
            multi([
                subText(0, 12, first ? 'DISP RMKS' : ''),
                subText(13, 56, rmk)
            ]);
            first = 0;
        }
        newline();
        separator();

        plain('PLANNED FUEL', 31);
        separator(31);
        multi([
            subText(0, 15, 'FUEL'),
            subText(13, 4, 'ARPT'),
            subText(20, 4, 'FUEL'),
            subText(27, 4, 'TIME'),
        ]);
        separator(31);
        multi([
            subText(0, 15, 'TRIP'),
            subFmt(13, 4, '%4s', ['OFP:origin/iata_code']),
            subFmt(19, 5, '%5s', ['OFP:fuel/enroute_burn']),
            subFmt(27, 4, formatFuelTime0202, ['OFP:fuel/avg_fuel_flow', 'OFP:fuel/enroute_burn']),
        ]);
        multi([
            subFmt(0, 18, 'CONT %s', ['OFP:general/cont_rule']),
            subFmt(19, 5, '%5s', ['OFP:fuel/contingency']),
            subFmt(27, 4, formatSeconds0202, ['OFP:times/contfuel_time']),
        ]);
        multi([
            subText(0, 15, 'ALTN'),
            subFmt(13, 4, '%4s', ['OFP:alternate/iata_code']),
            subFmt(19, 5, '%5s', ['OFP:fuel/alternate_burn']),
            subFmt(27, 4, formatSeconds0202, ['OFP:alternate/ete']),
        ]);
        multi([
            subText(0, 15, 'FINRES'),
            subFmt(19, 5, '%5s', ['OFP:fuel/reserve']),
            subFmt(27, 4, formatSeconds0202, ['OFP:times/reserve_time']),
        ]);
        if (isEtops) {
            multi([
                subText(0, 15, 'ETOPS/ETP'),
                subFmt(19, 5, '%5s', ['OFP:fuel/etops']),
                subFmt(27, 4, formatSeconds0202, ['OFP:times/etopsfuel_time']),
            ]);
        }
        separator(31);
        multi([
            subText(0, 18, 'MINIMUM T/OFF FUEL'),
            subFmt(19, 5, '%5s', ['OFP:fuel/min_takeoff']),
            subFmt(27, 4,
                func (flow, enrouteFuel, contTime, alternateTime, reserveTime) {
                    return formatSeconds0202(
                        fuelToSeconds(flow, enrouteFuel) +
                        (contTime or 0) +
                        (alternateTime or 0) +
                        (reserveTime or 0)
                    );
                },
                [ 'OFP:fuel/avg_fuel_flow'
                , 'OFP:fuel/enroute_burn'
                , 'OFP:times/contfuel_time'
                , 'OFP:alternate/ete'
                , 'OFP:times/reserve_time'
                ]),
        ]);
        separator(31);
        multi([
            subText(0, 15, 'EXTRA'),
            subFmt(19, 5, '%5s', ['OFP:fuel/extra']),
            subFmt(27, 4, formatSeconds0202, ['OFP:times/extrafuel_time']),
        ]);
        separator(31);
        multi([
            subText(0, 18, 'T/OFF FUEL'),
            subFmt(19, 5, '%5s', ['OFP:fuel/plan_takeoff']),
            subFmt(27, 4,
                func (flow, enrouteFuel, contTime, alternateTime, reserveTime, extraTime) {
                    return formatSeconds0202(
                        fuelToSeconds(flow, enrouteFuel) +
                        (contTime or 0) +
                        (alternateTime or 0) +
                        (reserveTime or 0) +
                        (extraTime or 0)
                    );
                },
                [ 'OFP:fuel/avg_fuel_flow'
                , 'OFP:fuel/enroute_burn'
                , 'OFP:times/contfuel_time'
                , 'OFP:alternate/ete'
                , 'OFP:times/reserve_time'
                , 'OFP:times/extrafuel_time'
                ]),
        ]);
        multi([
            subText(0, 15, 'TAXI'),
            subFmt(13, 4, '%4s', ['OFP:origin/iata_code']),
            subFmt(19, 5, '%5s', ['OFP:fuel/taxi']),
            subFmt(27, 4, formatSeconds0202, ['OFP:times/taxi_out']),
        ]);
        separator(31);
        multi([
            subText(0, 18, 'BLOCK FUEL'),
            subFmt(19, 5, '%5s', ['OFP:fuel/plan_ramp']),
            subFmt(27, 4,
                func (flow, enrouteFuel, contTime, alternateTime, reserveTime, extraTime, taxiTime) {
                    return formatSeconds0202(
                        fuelToSeconds(flow, enrouteFuel) +
                        (contTime or 0) +
                        (alternateTime or 0) +
                        (reserveTime or 0) +
                        (extraTime or 0) +
                        (taxiTime or 0)
                    );
                },
                [ 'OFP:fuel/avg_fuel_flow'
                , 'OFP:fuel/enroute_burn'
                , 'OFP:times/contfuel_time'
                , 'OFP:alternate/ete'
                , 'OFP:times/reserve_time'
                , 'OFP:times/extrafuel_time'
                , 'OFP:times/taxi_out'
                ]),
        ]);
        multi([
            subText(0, 18, 'PIC EXTRA'),
            subEntry(19, 5, 'OFP:fuel/pic_extra', 'numeric'),
        ]);
        multi([
            subText(0, 18, 'TOTAL FUEL'),
            subEntry(19, 5, 'OFP:fuel/total', 'numeric'),
        ]);
        multi([
            subText(0, 18, 'REASON FOR PIC EXTRA'),
            subEntry(19, 12, 'OFP:fuel/pic_extra_reason'),
        ]);
        separator();
        plain('FMC INFO:');
        multi([
            subText(0, 18, 'FINRES+ALTN'),
            subFmt(19, 5, func (finres, extra) {
                return sprintf('%5s', finres + extra);
            }, ['OFP:fuel/reserve', 'OFP:fuel/alternate_burn'])
        ]);
        multi([
            subText(0, 18, 'TRIP+TAXI'),
            subFmt(19, 5, func (trip, taxi) {
                return sprintf('%5s', trip + taxi);
            }, ['OFP:fuel/enroute_burn', 'OFP:fuel/taxi'])
        ]);
        separator();
        plain('NO TANKERING RECOMMENDED (P)');
        separator();
        plain('I HEREWITH CONFIRM THAT I HAVE PERFORMED A THOROUGH SELF BRIEFING');
        plain('ABOUT THE DESTINATION AND ALTERNATE AIRPORTS OF THIS FLIGHT');
        plain('INCLUDING THE APPLICABLE INSTRUMENT APPROACH PROCEDURES, AIRPORT');
        plain('FACILITIES, NOTAMS AND ALL OTHER RELEVANT PARTICULAR INFORMATION.');
        newline();
        multi([
            subFmt(0, 30, 'DISPATCHER: %s', ['OFP:crew/dx']),
            subFmt(32, 33, func (name) {
                return sprintf('%33s', 'PIC NAME: ' ~ string.uc(name));
            }, ['OFP:crew/cpt'])
        ]);
        newline();
        plain('TEL: +1 800 555 0199                 PIC SIGNATURE: .............');

        pageBreak();

        # Page 2
        toc('Routing and Impacts');
        multi([
            subText(0, 30, 'ALTERNATE ROUTE TO:'),
            subText(55, 6, 'FINRES'),
            subFmt(62, 6, '%6i', ['OFP:fuel/reserve']),
        ]);
        multi([
            subText(0, 8, 'APT'),
            subText(9, 3, 'TRK'),
            subText(13, 3, 'DST'),
            subText(18, 28, 'VIA', 28),
            subText(50, 3, ' FL'),
            subText(54, 4, 'WC', 4),
            subText(59, 4, 'TIME'),
            subText(64, 4, 'FUEL'),
        ]);
        separator();
        var alternates = me.getOFPValues('/', 'alternate');
        foreach (var alternate; alternates) {
            var route = lineSplitStr(alternate.route, 28);
            var first = 1;
            foreach (var routeStr; route) {
                if (first)
                    multi([
                        subFmt(0, 8, '%4s/%-3s', [alternate.icao_code, alternate.plan_rwy]),
                        subFmt(9, 3, '%03i', [alternate.track_true]),
                        subFmt(13, 3, '%3i', [alternate.distance]),
                        subText(18, 28, routeStr),
                        subText(50, 3, sprintf('%3i', alternate.cruise_altitude / 100 + 0.5)),
                        subFmt(54, 4, '%s', [alternate.avg_wind_comp]),
                        subFmt(59, 4, formatSeconds0202, [alternate.ete]),
                        subFmt(64, 4, '%4i', [alternate.burn]),
                    ]);
                else
                    multi([
                        subText(18, 28, routeStr),
                    ]);
                first = 0;
            }
        }
        separator();
        plain('MEL/CDL ITEMS DESCRIPTION');
        plain('------------- -----------');
        newline();
        separator();
        newline();
        plain('ROUTING:');
        newline();
        plain('ROUTE ID: DEFRTE');
        newline();
        var route =
                me.getOFPValue('origin/icao_code') ~ '/' ~ me.getOFPValue('origin/plan_rwy') ~ ' ' ~
                me.getOFPValue('general/route') ~
                me.getOFPValue('destination/icao_code') ~ '/' ~ me.getOFPValue('destination/plan_rwy');
        routeLines = lineSplitStr(route, 68);
        foreach (var routeLine; routeLines) {
            plain(routeLine);
        }
        newline();
        separator();
        plain('DEPARTURE ATC CLEARANCE:');
        plain('.');
        plain('.');
        plain('.');
        separator();
        plain('OPERATIONAL IMPACTS', 68);
        plain('-------------------', 68);
        var impactTypes = [
            [ 'WEIGHT CHANGE UP 1.0', 'impacts/zfw_plus_1000', 0 ],
            [ 'WEIGHT CHANGE DN 1.0', 'impacts/zfw_minus_1000', 0 ],
            [ 'FL CHANGE     UP FL2', 'impacts/plus_4000ft', 1 ],
            [ 'FL CHANGE     UP FL1', 'impacts/plus_2000ft', 0 ],
            [ 'FL CHANGE     DN FL1', 'impacts/minus_2000ft', 0 ],
            [ 'FL CHANGE     DN FL2', 'impacts/minus_4000ft', 1 ],
            [ 'SPD CHANGE    CI ' ~ me.getOFPValue('impacts/lower_ci/cost_index'), 'impacts/lower_ci', 1 ],
            [ 'SPD CHANGE    CI ' ~ me.getOFPValue('impacts/higher_ci/cost_index'), 'impacts/higher_ci', 1 ],
        ];
        var impact = nil;
        foreach (var impactType; impactTypes) {
            impact = me.getOFPValues(impactType[1], nil, 0);
            if (impact == nil) {
                if (impactType[2]) {
                    # skippable
                    continue;
                }
                multi([
                    subText(0, 20, impactType[0]),
                    subText(37, 17, 'NOT AVAILABLE', 17)
                ]);
            }
            else {
                multi([
                    subText(0, 20, impactType[0]),
                    subText(31, 4, 'TRIP'),
                    subFmt(37, 6, formatPM(4, 0, 1), [impact.burn_difference]),
                    subText(44, 4, 'KGS'),
                    subText(50, 4, 'TIME'),
                    subFmt(55, 6, formatSeconds0202PM(1), [impact.time_difference]),
                ]);
            }
        }
        separator();
        pageBreak();

        # Page 3
        toc('Times and Weights');
        separator();
        plain('ATIS:');
        plain('.');
        plain('.');
        plain('--------- ---------- ------------ ----- ------------ ------ --------');
        plain('RVSM: ALT SYS  LEFT:              STBY:              RIGHT:');
        newline();
        plain('--------- ---------- ------------ ----- ------------ ------ --------');
        separator();
        plain('TIMES', 68);
        plain('-----', 68);
        newline();
        multi([
            subText(16, 11, 'ESTIMATED'),
            subText(34, 11, 'SKED'),
            subText(52, 11, 'ACTUAL'),
        ]);
        newline();
        multi([
            subText(0, 11, 'OUT'),
            subFmt(16, 11, '%02i%02iZ/%02i%02iL',
                [schedOut.hour, schedOut.minute, 
                schedOutLocal.hour, schedOutLocal.minute]),
            subFmt(34, 11, '%02i%02iZ/%02i%02iL',
                [schedOut.hour, schedOut.minute, 
                schedOutLocal.hour, schedOutLocal.minute]),
            subEntry(52, 6, 'OFP:times/actual_out', 'numeric'),
            subText(58, 1, 'Z'),
        ]);
        newline();
        multi([
            subText(0, 11, 'OFF'),
            subFmt(16, 11, '%02i%02iZ/%02i%02iL',
                [schedOff.hour, schedOff.minute, 
                schedOffLocal.hour, schedOffLocal.minute]),
            subFmt(34, 11, '%02i%02iZ/%02i%02iL',
                [schedOff.hour, schedOff.minute, 
                schedOffLocal.hour, schedOffLocal.minute]),
            subEntry(52, 6, 'OFP:times/actual_off', 'numeric'),
            subText(58, 1, 'Z'),
        ]);
        newline();
        multi([
            subText(0, 11, 'ON'),
            subFmt(16, 11, '%02i%02iZ/%02i%02iL',
                [estOn.hour, estOn.minute, 
                estOnLocal.hour, estOnLocal.minute]),
            subFmt(34, 11, '%02i%02iZ/%02i%02iL',
                [schedOn.hour, schedOn.minute, 
                schedOnLocal.hour, schedOnLocal.minute]),
            subEntry(52, 6, 'OFP:times/actual_on', 'numeric'),
            subText(58, 1, 'Z'),
        ]);
        newline();
        multi([
            subText(0, 11, 'IN'),
            subFmt(16, 11, '%02i%02iZ/%02i%02iL',
                [estIn.hour, estIn.minute, 
                estInLocal.hour, estInLocal.minute]),
            subFmt(34, 11, '%02i%02iZ/%02i%02iL',
                [schedIn.hour, schedIn.minute, 
                schedInLocal.hour, schedInLocal.minute]),
            subEntry(52, 6, 'OFP:times/actual_in', 'numeric'),
            subText(58, 1, 'Z'),
        ]);
        newline();
        multi([
            subText(0, 11, 'BLOCK TIME'),
            subFmt(16, 11, formatSeconds0202, ['OFP:times/est_block']),
            subFmt(34, 11, formatSeconds0202, ['OFP:times/sched_block']),
            subEntry(52, 6, 'OFP:times/actual_block', 'numeric'),
        ]);
        newline();
        separator();

        plain('WEIGHTS', 68);
        plain('-------', 68);
        newline();
        multi([
            subText(0, 10, ''),
            subFmt(10, 10, '%10s', ['EST']),
            subFmt(20, 10, '%10s', ['MAX']),
            subFmt(35, 6, '%6s', ['ACTUAL'])
        ]);
        newline();
        multi([
            subText(0, 10, 'PAX'),
            subFmt(10, 10, '%10i', ['#OFP:weights/pax_count']),
            subEntry(35, 6, 'OFP:weights/pax_count_actual'),
        ]);
        newline();
        multi([
            subText(0, 10, 'CARGO'),
            subFmt(10, 10, '%10i', ['#OFP:weights/cargo']),
            subEntry(35, 6, 'OFP:weights/cargo_actual'),
        ]);
        newline();
        multi([
            subText(0, 10, 'PAYLOAD'),
            subFmt(10, 10, '%10i', ['#OFP:weights/payload']),
            subEntry(35, 6, 'OFP:weights/payload_actual'),
        ]);
        newline();
        multi([
            subText(0, 10, 'ZFW'),
            subFmt(10, 10, '%10i', ['#OFP:weights/est_zfw']),
            subFmt(20, 10, '%10i', ['#OFP:weights/max_zfw']),
            subEntry(35, 6, 'OFP:weights/actual_zfw'),
        ]);
        var maxRampFuel = me.getOFPValue('fuel/plan_ramp', 0) +
                          me.getOFPValue('weights/max_tow', 0) -
                          me.getOFPValue('weights/est_tow', 0);
        var possibleExtraFuel =
                          me.getOFPValue('weights/max_tow', 0) -
                          me.getOFPValue('weights/est_tow', 0);
        newline();
        multi([
            subText(0, 10, 'FUEL'),
            subFmt(10, 10, '%10i', ['#OFP:fuel/plan_ramp']),
            subFmt(20, 10, '%10i', [maxRampFuel]),
            subEntry(35, 6, 'OFP:fuel/actual_ramp'),
            subFmt(43, 20, 'POSS EXTRA %i', [possibleExtraFuel]),
        ]);
        newline();
        multi([
            subText(0, 10, 'TOW'),
            subFmt(10, 10, '%10i', ['#OFP:weights/est_tow']),
            subFmt(20, 10, '%10i', ['#OFP:weights/max_tow']),
            subEntry(35, 6, 'OFP:fuel/actual_tow'),
        ]);
        newline();
        multi([
            subText(0, 10, 'STAB TRIM'),
            subEntry(35, 6, 'OFP:general/stab_trim'),
        ]);
        newline();
        multi([
            subText(0, 10, 'LAW'),
            subFmt(10, 10, '%10i', ['#OFP:weights/est_ldw']),
            subFmt(20, 10, '%10i', ['#OFP:weights/max_ldw']),
            subEntry(35, 6, 'OFP:fuel/actual_ldw'),
        ]);
        newline();
        separator();

        plain('TERRAIN CLEARANCE CHECK', 68);
        plain('-----------------------', 68);
        plain('DD CHECK - TERRAIN CLEARANCE CHECK DISABLED');
        newline();
        plain('DP CHECK - TERRAIN CLEARANCE CHECK DISABLED');
        separator();
        pageBreak();

        # Page 4
        toc('Flight Log');
        plain('FLIGHT LOG', 68);
        plain('----------', 68);
        newline();
        plain('MOST CRITICAL MORA N/A');
        separator();
        var flightLogHeader = func {
            multi([
                subText(0, 12, 'AWY'),
                subText(30, 4, ' FL '),
                subText(35, 4, ' IMT'),
                subText(41, 4, ' MN'),
                subText(46, 7, '   WIND'),
                subText(55, 3, 'OAT'),
                subText(59, 4, 'EFOB'),
                subText(64, 4, 'PBRN'),
            ]);
            multi([
                subText(0, 12, 'POSITION'),
                subText(12, 8, ' LAT'),
                subText(21, 4, ' EET'),
                subText(26, 3, 'ETO'),
                subText(30, 4, 'MORA'),
                subText(35, 4, ' ITT'),
                subText(41, 4, 'TAS'),
                subText(46, 7, '   COMP'),
                subText(55, 3, 'TDV'),
            ]);
            multi([
                subText(0, 12, 'IDENT'),
                subText(12, 8, ' LONG'),
                subText(21, 4, 'TTLT'),
                subText(26, 3, 'ATO'),
                subText(30, 4, 'DIS'),
                subText(35, 4, 'RDIS'),
                subText(41, 4, ' GS'),
                subText(46, 7, '    SHR'),
                subText(55, 3, 'TRP'),
                subText(59, 4, 'AFOB'),
                subText(64, 4, 'ABRN'),
            ]);
            multi([
                subText(0, 12, 'FREQ'),
            ]);
            separator();
        }

        flightLogHeader();

        var navlog = me.getOFPNode('OFP/navlog');
        var fixes = navlog.getChildren('fix');
        var remainingDistance = me.getOFPValue('general/route_distance');
        var row = 10;

        var reserveLines = func (n) {
            if (row + n > me.metrics.rows) {
                pageBreak();
                flightLogHeader();
                row = 4;
            }
            row += n;
        };

        reserveLines(4);
        var fixName = me.getOFPValue('origin/name');
        var fixIdent = me.getOFPValue('origin/icao_code');
        multi([
            subFmt(35, 4, ' %03i', [fixes[0].getValue('track_mag')]),
            subFmt(59, 4, '%2.1f', [me.getOFPValue('fuel/plan_takeoff') / 1000]),
            subFmt(64, 4, '%2.1f', [me.getOFPValue('fuel/taxi') / 1000]),
        ]);
        multi([
            subFmt(0, 12, '%s', [fixName]),
            subFmt(12, 8, formatGeoCoordLog, [me.getOFPValue('origin/pos_lat'), 'lat']),
            subEntry(26, 3, 'OFP:origin/eto'),
            subFmt(31, 3, '%3i', [fixes[0].getValue('mora') / 100]),
            subFmt(35, 4, ' %03i', [fixes[0].getValue('track_true')]),
            subFmt(50, 3, formatPM(3), [fixes[0].getValue('wind_component')]),
        ]);
        multi([
            subFmt(0, 12, '%s', [fixIdent]),
            subFmt(12, 8, formatGeoCoordLog, [me.getOFPValue('origin/pos_long'), 'lon']),
            subFmt(21, 4, formatSeconds0202, [0]),
            subEntry(26, 3, 'OFP:origin/ato'),
            subFmt(35, 4, '%4i', [remainingDistance]),
            subFmt(41, 4, '%3i', [fixes[0].getValue('groundspeed')]),
            subFmt(50, 3, formatPM(3), [fixes[0].getValue('shear')]),
            subEntry(59, 4, 'OFP:origin/fuel_actual_onboard'),
            subEntry(64, 4, 'OFP:origin/fuel_actual_totalused'),
        ]);
        newline();

        var i = 0;
        foreach (var fix; fixes) {
            i += 1;
            var nextFix = (i < size(fixes)) ? fixes[i] : fix;
            foreach (var fir; fix.getChild('fir_crossing').getChildren('fir')) {
                reserveLines(4);
                plain(fir.getValue('fir_name'));
                multi([
                    subFmt(0, 12, '-%4s', [fir.getValue('fir_icao')]),
                    subFmt(12, 8, formatGeoCoordLog, [fir.getValue('pos_lat_entry'), 'lat']),
                    # subFmt(21, 4, formatSeconds0202, [fir.getValue('time_leg')]),
                    subEntry(26, 3, 'OFP:' ~ fir.getPath() ~ '/eto'),
                ]);
                multi([
                    subFmt(12, 8, formatGeoCoordLog, [fir.getValue('pos_long_entry'), 'lon']),
                    # subFmt(21, 4, formatSeconds0202, [fir.getValue('time_leg')]),
                    subEntry(26, 3, 'OFP:' ~ fir.getPath() ~ '/ato'),
                ]);
                newline();
            }

            var freq = fix.getValue('frequency');
            if (freq == nil)
                reserveLines(4);
            else
                reserveLines(5);
            remainingDistance -= fix.getValue('distance');
            var fixName = fix.getValue('name');
            if (fixName == 'TOP OF CLIMB')
                fixName = 'T O C';
            if (fixName == 'TOP OF DESCENT')
                fixName = 'T O D';
            var fixIdent = fix.getValue('ident');
            if (fixIdent == 'TOC' or fixIdent == 'TOD')
                fixIdent = '';
            multi([
                subFmt(0, 12, '%s', [fix.getValue('via_airway') or '']),
                subFmt(30, 4, ' %03i', [fix.getValue('altitude_feet') / 100]),
                subFmt(35, 4, ' %03i', [nextFix.getValue('track_mag')]),
                subFmt(41, 4, '.%02i', [fix.getValue('mach') * 100]),
                subFmt(46, 7, "%03i/%03i", [fix.getValue('wind_dir'), fix.getValue('wind_spd')]),
                subFmt(55, 3, formatPM(2, 0, 0, 1), [fix.getValue('oat')]),
                subFmt(59, 4, '%2.1f', [fix.getValue('fuel_plan_onboard') / 1000]),
                subFmt(64, 4, '%2.1f', [fix.getValue('fuel_totalused') / 1000]),
            ]);
            multi([
                subFmt(0, 12, '%s', [fixName]),
                subFmt(12, 8, formatGeoCoordLog, [fix.getValue('pos_lat'), 'lat']),
                subFmt(21, 4, formatSeconds0202, [fix.getValue('time_leg')]),
                subEntry(26, 3, 'OFP:' ~ fix.getPath() ~ '/eto'),
                subFmt(31, 3, '%3i', [nextFix.getValue('mora') / 100]),
                subFmt(35, 4, ' %03i', [nextFix.getValue('track_true')]),
                subFmt(41, 4, '%3i', [fix.getValue('true_airspeed')]),
                subFmt(50, 3, formatPM(3), [fix.getValue('wind_component')]),
                subFmt(55, 3, formatPM(2, 0, 0, 1), [fix.getValue('oat_isa_dev')]),
            ]);
            multi([
                subFmt(0, 12, '%s', [fixIdent]),
                subFmt(12, 8, formatGeoCoordLog, [fix.getValue('pos_long'), 'lon']),
                subFmt(21, 4, formatSeconds0202, [fix.getValue('time_total')]),
                subEntry(26, 3, 'OFP:' ~ fix.getPath() ~ '/ato'),
                subFmt(30, 4, '%4i', [fix.getValue('distance')]),
                subFmt(35, 4, '%4i', [remainingDistance]),
                subFmt(41, 4, '%3i', [fix.getValue('groundspeed')]),
                subFmt(50, 3, formatPM(3), [fix.getValue('shear')]),
                subFmt(55, 3, '%3i', [fix.getValue('tropopause_feet') / 100]),
                subEntry(59, 4, 'OFP:' ~ fix.getPath() ~ '/fuel_actual_onboard'),
                subEntry(64, 4, 'OFP:' ~ fix.getPath() ~ '/fuel_actual_totalused'),
            ]);
            if (freq != nil) {
                multi([
                    subFmt(0, 12, '%s', [freq]),
                ]);
            }
            newline();
        }

        return items;
    },

    paginate: func (items, pageSize=nil) {
        if (pageSize == nil)
            pageSize = me.metrics.rows;
        var pages = [];
        var page = [];
        var pushPage = func {
            append(pages, page);
            page = [];
        };
        var toc = [];
        foreach (var item; items) {
            if (item.type == 'page-break') {
                pushPage();
                continue;
            }
            if (size(page) >= pageSize) {
                pushPage();
            }
            if (item.type == 'toc-entry') {
                append(toc, { title: item.title, page: size(pages) });
            }
            else {
                append(page, item);
            }
        }
        if (size(page) > 0) {
            pushPage();
        }
        return [pages, toc];
    },

    renderSubItem: func (pageGroup, y, item, pageWidget) {
        var self = me;
        var renderText = func (text) {
            if (text == nil)
                text = '';
            pageGroup
                .createChild('text')
                .setText(substr(text, 0, item.w))
                .setFontSize(me.metrics.fontSize, 1)
                .setFont(font_mapper('mono'))
                .setColor(0, 0, 0)
                .setColorFill(0, 0, 0, 0)
                .setDrawMode(canvas.Text.TEXT)
                .setTranslation(me.metrics.paddingLeft + item.x * me.metrics.charWidth, y);
        };
        var renderEntryText = func (path, datatype=nil) {
            var node = me.getFormatNode(path);
            var val = node.getValue() or '';
            var box = pageGroup.createChild('path')
                        .rect(
                            me.metrics.paddingLeft + item.x * me.metrics.charWidth - me.metrics.inputPadding,
                            y - me.metrics.lineHeight,
                            item.w * me.metrics.charWidth + 2 * me.metrics.inputPadding,
                            me.metrics.lineHeight)
                        .setColorFill(0.0, 0.0, 0.0, 0.1);
            var frame = pageGroup.createChild('path')
                        .rect(
                            me.metrics.paddingLeft + item.x * me.metrics.charWidth - me.metrics.inputPadding - 1,
                            y - me.metrics.lineHeight - 1,
                            item.w * me.metrics.charWidth + 2 * me.metrics.inputPadding + 2,
                            me.metrics.lineHeight + 2)
                        .setColor(0.1, 0.1, 0.5)
                        .hide();
            var text = pageGroup
                .createChild('text')
                .setText(substr(val, 0, item.w))
                .setFontSize(me.metrics.fontSize, 1)
                .setFont(font_mapper('script'))
                .setColor(0, 0, 1)
                .setTranslation(me.metrics.paddingLeft + item.x * me.metrics.charWidth, y - 1);
            var ident = rand();
            me.makeClickable(box, func {
                if (self.entryMode == nil or self.entryMode.ident != ident) {
                    frame.show();
                    self.cancelEntry();
                    self.startEntry(ident, text, box, node, func {
                        frame.hide();
                    });
                }
                else if (self.entryMode != nil and self.entryMode.ident == ident) {
                    self.cancelEntry();
                }
            }, pageWidget);
        };
        if (item.type == 'text') {
            renderText(item.text);
        }
        elsif (item.type == 'formatted') {
            var args = [];
            foreach (var argSpec; item.args) {
                append(args, me.getFormatArg(argSpec));
            }
            if (typeof(item.format) == 'func')
                renderText(call(item.format, args));
            else
                renderText(call(sprintf, [item.format] ~ args));
        }
        elsif (item.type == 'entry') {
            renderText('.................................');
            renderEntryText(item.path, item.datatype);
        }
    },

    getFormatArg: func(argSpec) {
        var default = '';
        if (typeof(argSpec) == 'scalar' and substr(argSpec ~ '', 0, 1) == '#') {
            default = 0;
            argSpec = substr(argSpec, 1);
        }
        if (typeof(argSpec) == 'scalar' and substr(argSpec ~ '', 0, 4) == 'OFP:') {
            return me.getOFPValue(substr(argSpec, 4), default);
        }
        else {
            return argSpec;
        }
    },

    getFormatNode: func(argSpec) {
        if (typeof(argSpec) == 'scalar' and substr(argSpec ~ '', 0, 4) == 'OFP:') {
            return me.getOFPNode(substr(argSpec, 4));
        }
        else {
            # Dummy, just so we have a node
            return props.Node.new().setValue(argSpec);
        }
    },


    renderItem: func (pageGroup, y, item, pageWidget) {
        var renderText = func (text) {
            pageGroup
                .createChild('text')
                .setText(text)
                .setFontSize(me.metrics.fontSize, 1)
                .setFont(font_mapper('mono'))
                .setColor(0, 0, 0)
                .setTranslation(me.metrics.paddingLeft, y);
        };
        if (item.type == 'text') {
            renderText(item.text);
        }
        elsif (item.type == 'separator') {
            renderText(
                substr(
                    '--------------------------------------------------------------------',
                    0, item.length));
        }
        elsif (item.type == 'formatted') {
            var args = [];
            foreach (var argSpec; item.args) {
                append(args, me.getFormatArg(argSpec));
            }
            renderText(call(sprintf, [item.format] ~ args));
        }
        elsif (item.type == 'multi') {
            foreach (var subItem; item.items) {
                me.renderSubItem(pageGroup, y, subItem, pageWidget);
            }
        }
    },

    pageHeading: func (ofp) {
        var schedOut = unixToDateTime(ofp.getValue('OFP/times/sched_out'));
        return sprintf(
            '%s %s/%02i %s/%s-%s',
            ofp.getValue('OFP/general/icao_airline') or '',
            ofp.getValue('OFP/general/flight_number'),
            schedOut.day,
            monthNames3[schedOut.month],
            ofp.getValue('OFP/origin/iata_code'),
            ofp.getValue('OFP/destination/iata_code'));
    },

    renderPage: func(pageGroup, pageNumber, pageData, pageWidget) {
        var y = me.metrics.headerHeight + me.metrics.paddingTop + me.metrics.lineHeight;
        var pageHeading = me.pageHeading(me.ofp);

        pageGroup.createChild('path')
                 .rect(0, 0, me.metrics.pageWidth, me.metrics.headerHeight)
                 .setColor(0, 0, 0,)
                 .setColorFill(0.9, 0.9, 0.9);
        pageGroup.createChild('text')
                 .setAlignment('center-top')
                 .setMaxWidth(me.metrics.pageWidth)
                 .setText(pageHeading)
                 .setFont(font_mapper('sans', 'bold'))
                 .setFontSize(16, 1)
                 .setColor(0, 0, 0)
                 .setTranslation(me.metrics.pageWidth / 2, (me.metrics.headerHeight - 13) / 2);
        pageGroup.createChild('text')
                 .setAlignment('right-top')
                 .setMaxWidth(me.metrics.pageWidth)
                 .setText(sprintf('Page %i', pageNumber))
                 .setFont(font_mapper('sans', 'normal'))
                 .setFontSize(12, 1)
                 .setColor(0, 0, 0)
                 .setTranslation(me.metrics.pageWidth - me.metrics.paddingLeft, (me.metrics.headerHeight - 10) / 2);
        foreach (var item; pageData) {
            me.renderItem(pageGroup, y, item, pageWidget);
            y += me.metrics.lineHeight;
        }
    },

    renderOFP: func () {
        var self = me;
        me.clear();
        me.pageWidgets = [];

        me.zoomScrollPane =
                me.contentGroup.createChild('group')
                    .setTranslation(256, 384)
                    .setScale(1, 1);
        me.zoomScrollPane.createChild('path')
                       .rect(-me.metrics.pageWidth / 2, -me.metrics.pageHeight / 2, me.metrics.pageWidth, me.metrics.pageHeight)
                       .setColor(0.2, 0.2, 0.2)
                       .setColorFill(1.0, 1.0, 1.0);
        me.pages = [];
        var pagesData = [];
        var toc = [];
        (pagesData, toc) = me.paginate(me.collectOFPItems());
        var pageNumber = 1;
        foreach (var pageData; pagesData) {
            var pageGroup = me.zoomScrollPane
                                .createChild('group')
                                .setTranslation(-me.metrics.pageWidth / 2, -me.metrics.pageHeight / 2);
            var pageWidget = Widget.new();
            append(me.pageWidgets, pageWidget);
            me.mainWidget.appendChild(pageWidget);
            me.renderPage(pageGroup, pageNumber, pageData, pageWidget);
            pageGroup.hide();
            append(me.pages, pageGroup);
            pageNumber += 1;
        }
        me.pager.setNumPages(size(me.pages));
        me.pager.setCurrentPage(0);
        me.showPager();
        me.tocContentsWidget.removeAllChildren();
        var y = me.metrics.tocPadding;
        foreach (var tocEntry; toc) {
            var elem = me.tocContentsGroup.createChild('path')
                         .rect(0, y, me.metrics.tocPaneWidth, me.metrics.tocLineHeight);
            var textElem = me.tocContentsGroup.createChild('text')
                         .setFont(font_mapper('sans', 'normal'))
                         .setFontSize(me.metrics.tocFontSize, 1)
                         .setAlignment('left-top')
                         .setColor(0, 0, 0.8)
                         .setText(tocEntry.title)
                         .setTranslation(me.metrics.tocPadding, y + (me.metrics.tocLineHeight - me.metrics.tocFontSize) / 2);
            (func (page, elem) {
                self.makeClickable(elem, func {
                    self.cancelEntry();
                    self.pager.setCurrentPage(page);
                    self.hideTOC();
                }, self.tocContentsWidget);
            })(tocEntry.page, elem);
            y += me.metrics.tocLineHeight;
        }
        me.enableTOC();
    },

    clear: func {
        me.hideKeyboard();
        me.hidePager();
        me.disableTOC();
        me.mainWidget.removeAllChildren();
        me.resetScroll();
        me.contentGroup.removeAllChildren();
        me.zoomScrollPane = nil;
    },

    showSimbriefHelp: func () {
        var self = me;
        var args = arg;
        me.clear();

        var y = me.metrics.marginTop + me.metrics.paddingTop;
        var helpLines = [
            'Failed to load SimBrief OFP.',
            'The SimBrief OFP should be saved in the following location:',
            getprop('/sim/fg-home') ~ "/Export/simbrief.xml",
        ];
        if (globals['simbrief']) {
            append(helpLines,
                '',
                'It looks like you have the SimBrief importer plugin installed.',
                'Select "Equipment" > "SimBrief Import" from the main menu',
                'to download your SimBrief flightplan into the correct',
                'location, and try again.'
            );
        }
        else {
            append(helpLines,
                '',
                'It looks like you do not have the SimBrief importer plugin',
                'installed. You can find it here:',
                'https://github.com/tdammers/fg-simbrief-addon',
                '',
                'You can also manually download your OFP from this URL:',
                'https://www.simbrief.com/api/xml.fetcher.php?username={username}',
                '(replace {username} with your SimBrief username)'
            );
        }
        me.contentGroup.createChild('text')
                       .setColor(1, 0, 0)
                       .setFont(font_mapper('sans', 'bold'))
                       .setFontSize(me.metrics.menuFontSize * 1.5, 1)
                       .setText('SimBrief OFP Not Found')
                       .setAlignment('center-top')
                       .setTranslation(256, y);

        y += me.metrics.menuFontSize * 2.5 + me.metrics.menuItemPadding;
        foreach (var h; helpLines) {
            if (substr(h, 0, 6) == 'https:') {
                var box = me.contentGroup.createChild('path')
                        .rect(2, y, 508, me.metrics.menuLineHeight)
                        .setColorFill(1, 1, 1, 0.5);
                me.contentGroup.createChild('text')
                               .setColor(0, 0, 1)
                               .setFont(font_mapper('sans', 'normal'))
                               .setFontSize(me.metrics.menuFontSize, 1)
                               .setText(h)
                               .setAlignment('center-top')
                               .setTranslation(256, y + (me.metrics.menuLineHeight - me.metrics.menuFontSize) * 0.5);
                (func (url) {
                    me.makeClickable(box, func { fgcommand('open-browser', props.Node.new({url: url})); },
                        me.mainWidget);
                })(h);
            }
            else {
                var text = me.contentGroup.createChild('text')
                               .setColor(0, 0, 0)
                               .setFont(font_mapper('sans', 'normal'))
                               .setFontSize(me.metrics.menuFontSize, 1)
                               .setText(h)
                               .setAlignment('center-top')
                               .setTranslation(256, y + (me.metrics.menuLineHeight - me.metrics.menuFontSize) * 0.5);
            }
            y += me.metrics.menuLineHeight + me.metrics.menuItemPadding;
        }
    },

    showError: func () {
        var self = me;
        var args = arg;
        me.clear();

        var y = me.metrics.marginTop + me.metrics.paddingTop;

        me.contentGroup.createChild('text')
                       .setColor(1, 0, 0)
                       .setFont(font_mapper('sans', 'bold'))
                       .setFontSize(me.metrics.menuFontSize * 1.5, 1)
                       .setText('ERROR')
                       .setAlignment('center-top')
                       .setTranslation(256, y);
        y += me.metrics.menuFontSize * 1.5 + me.metrics.menuItemPadding;
        foreach (var msg; args) {
            me.contentGroup.createChild('text')
                           .setColor(1, 0, 0)
                           .setFont(font_mapper('sans', 'bold'))
                           .setFontSize(me.metrics.menuFontSize, 1)
                           .setText(msg)
                           .setAlignment('center-top')
                           .setTranslation(256, y);
            y += me.metrics.menuFontSize + me.metrics.menuItemPadding;
        }
    },

    showStartMenu: func {
        var self = me;
        me.clear();

        var y = me.metrics.marginTop + me.metrics.paddingTop;

        var makeMenuItem = func (label, what) {
            var box = me.contentGroup.createChild('path')
                    .rect(me.metrics.marginLeft, y, me.metrics.pageWidth, me.metrics.menuLineHeight, {'border-radius': 6})
                    .setColorFill(0.2, 0.4, 0.8, 1);
            me.contentGroup.createChild('text')
                    .setColor(0.9, 0.9, 1)
                    .setText(label)
                    .setFont(font_mapper('sans', 'bold'))
                    .setFontSize(me.metrics.menuFontSize, 1)
                    .setAlignment('center-top')
                    .setTranslation(
                        me.metrics.marginLeft + me.metrics.pageWidth / 2,
                        y + (me.metrics.menuLineHeight - me.metrics.menuFontSize) / 2);
            me.makeClickable(box, what, me.mainWidget);

            y += me.metrics.menuLineHeight + me.metrics.menuItemPadding;
        };

        var makeMenuHeading = func (label) {
            me.contentGroup.createChild('text')
                    .setColor(0, 0, 0)
                    .setText(label)
                    .setFont(font_mapper('sans', 'bold'))
                    .setFontSize(me.metrics.menuFontSize * 1.25, 1)
                    .setAlignment('center-top')
                    .setTranslation(
                        me.metrics.marginLeft + me.metrics.pageWidth / 2,
                        y + (me.metrics.menuLineHeight - me.metrics.menuFontSize) / 2);

            y += me.metrics.menuLineHeight + me.metrics.menuItemPadding;
        }

        var makeMenuStatic = func (label) {
            me.contentGroup.createChild('text')
                    .setColor(0, 0, 0)
                    .setText(label)
                    .setFont(font_mapper('sans', 'normal'))
                    .setFontSize(me.metrics.menuFontSize, 1)
                    .setAlignment('center-top')
                    .setTranslation(
                        me.metrics.marginLeft + me.metrics.pageWidth / 2,
                        y + (me.metrics.menuLineHeight - me.metrics.menuFontSize) / 2);

            y += me.metrics.menuLineHeight + me.metrics.menuItemPadding;
        }

        makeMenuHeading("Current OFP");
        if (me.ofp == nil) {
            makeMenuStatic('No OFP loaded');
        }
        else {
            var name = me.pageHeading(me.ofp);
            makeMenuItem(name, func { self.renderOFP(); });
        }
        makeMenuHeading("Available OFP");
        makeMenuItem("Load from SimBrief", func {
            if (self.loadSimbriefOFP()) {
                self.showStartMenu();
            }
            else {
                self.showSimbriefHelp();
            }
        });
        var ofpDir = getprop("/sim/fg-home") ~ '/Export/OFP/';
        var ofpList = directory(ofpDir);
        foreach (var ofpCandidate; ofpList) {
            if (substr(ofpCandidate, -4) == '.xml') {
                makeMenuItem(ofpCandidate, func {
                    if (self.loadOFPFile(ofpDir ~ ofpCandidate)) {
                        self.showStartMenu();
                    }
                    else {
                        self.showError('Something went wrong');
                    }
                });
            }
        }
    },

    handleBack: func {
        me.showStartMenu();
    },

};

registerApp('paperwork', 'Paperwork', 'paperwork.png', PaperworkApp);

