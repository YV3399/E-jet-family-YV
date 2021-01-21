# -------------- MCDU -------------- 

var MCDU = {
    new: func (n) {
        var m = {
            parents: [MCDU],
            num: n,
            commandprop: props.globals.getNode("/instrumentation/mcdu[" ~ n ~ "]/command"),
            display: nil,
            scratchpad: "",
            scratchpadElem: nil,
            scratchpadMsg: "",
            scratchpadMsgColor: mcdu_white,
            dividers: [],
            screenbuf: [],
            screenbufElems: {fg: [], bg: []},
            activeModule: nil,
            moduleStack: [],
            powered: 0,
            g: nil
        };
        m.initCanvas();
        setlistener("/instrumentation/mcdu[" ~ n ~ "]/command", func () {
            m.handleCommand();
        });
        return m;
    },

    powerOn: func () {
        if (!me.powered) {
            me.powered = 1;
            me.gotoModule("RADIO");
        }
    },

    powerOff: func () {
        if (me.powered) {
            me.powered = 0;
            me.gotoModule(nil);
        }
    },

    makeModule: {
        "TEST": func (mcdu, parent) { return TestModule.new(mcdu, parent); },

        # Radio modules
        "RADIO": func(mcdu, parent) { return RadioModule.new(mcdu, parent); },
        "NAV1": func (mcdu, parent) { return NavRadioDetailsModule.new(mcdu, parent, 1); },
        "NAV2": func (mcdu, parent) { return NavRadioDetailsModule.new(mcdu, parent, 2); },
        "COM1": func (mcdu, parent) { return ComRadioDetailsModule.new(mcdu, parent, 1); },
        "COM2": func (mcdu, parent) { return ComRadioDetailsModule.new(mcdu, parent, 2); },
        "XPDR": func (mcdu, parent) { return TransponderModule.new(mcdu, parent); },

        # Index modules
        "NAVINDEX": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "NAV INDEX",
                        [ # PAGE 1
                          [ "NAVIDENT", "NAV IDENT" ]
                        , [ nil, "WPT LIST" ]
                        , [ nil, "FPL LIST" ]
                        , [ nil, "POS SENSORS" ]
                        , [ nil, "FIX INFO" ]
                        , [ "DEPARTURE", "DEPARTURE" ]

                        , nil
                        , nil
                        , [ nil, "FLT SUM" ]
                        , nil
                        , [ nil, "HOLD" ]
                        , [ "ARRIVAL", "ARRIVAL" ]

                          # PAGE 2
                        , [ "POSINIT", "POS INIT" ]
                        , [ nil, "DATA LOAD" ]
                        , [ "PATTERNS", "PATTERNS" ]
                        , nil
                        , nil
                        , nil

                        , [ nil, "CONVERSION" ]
                        , [ nil, "MAINTENANCE" ]
                        , [ nil, "CROSS PTS" ]
                        , nil
                        , nil
                        , nil
                        ]); },
        "PATTERNS": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "PATTERNS",
                        [ # PAGE 1
                          [ "PATTERN-HOLD", "HOLD" ],
                          [ "PATTERN-FLYOVER", "FLYOVER" ],
                          nil,
                          nil,
                          nil,
                          [ "ret", "REVIEW" ],

                          [ "PATTERN-PTURN", "PCDR TURN" ],
                          nil,
                          nil,
                          nil,
                          nil,
                          nil,
                        ]); },
        "PERFINDEX": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "PERF INDEX",
                        [ # PAGE 1
                          [ "PERFINIT", "PERF INIT" ],
                          [ "PERF-PLAN", "PERF PLAN" ],
                          [ "PERF-CLIMB", "CLIMB" ],
                          [ "PERF-DESCENT", "DESCENT" ],
                          [ nil, "INIT<--WHAT" ],
                          [ nil, "INIT<-STORE" ],

                          [ "PERF-DATA", "PERF DATA" ],
                          [ "PERF-TAKEOFF", "TAKEOFF" ],
                          [ "PERF-CRUISE", "CRUISE" ],
                          [ "PERF-LANDING", "LANDING" ],
                          [ nil, "-IF -->DATA" ],
                          [ nil, "D FPL->DATA" ],

                          # PAGE 2
                        ]); },

        # Perf
        "PERF-TAKEOFF": func (mcdu, parent) { return TakeoffPerfModule.new(mcdu, parent); },
        "PERF-LANDING": func (mcdu, parent) { return LandingPerfModule.new(mcdu, parent); },
        "PERFINIT": func (mcdu, parent) { return PerfInitModule.new(mcdu, parent); },
        "PERFDATA": func (mcdu, parent) { return PerfDataModule.new(mcdu, parent); },

        # Nav
        "NAVIDENT": func (mcdu, parent) { return NavIdentModule.new(mcdu, parent); },
        "RTE": func (mcdu, parent) { return FlightPlanModule.new(mcdu, parent, "ROUTE"); },
        "DEPARTURE": func (mcdu, parent) { return DepartureSelectModule.new(mcdu, parent); },
        "ARRIVAL": func (mcdu, parent) { return ArrivalSelectModule.new(mcdu, parent); },
        "FPL": func (mcdu, parent) { return FlightPlanModule.new(mcdu, parent); },
        "POSINIT": func (mcdu, parent) { return PosInitModule.new(mcdu, parent); },
        "PATTERN-FLYOVER": func (mcdu, parent) { return FlightPlanModule.new(mcdu, parent, "FLYOVER"); },
        "PATTERN-HOLD": func (mcdu, parent) { return FlightPlanModule.new(mcdu, parent, "HOLD"); },

        # Progress
        "PROG": func (mcdu, parent) { return ProgressModule.new(mcdu, parent); },
        "PROG-NAV1": func (mcdu, parent) { return ProgressNavModule.new(mcdu, 1, parent); },
        "PROG-NAV2": func (mcdu, parent) { return ProgressNavModule.new(mcdu, 2, parent); },
    },

    # Activate a module, pushing the current one onto the module stack.
    # Returning from the active module to the parent pops the previously
    # active module from the stack.
    pushModule: func (moduleName) {
        if (me.activeModule != nil) {
            append(me.moduleStack, me.activeModule);
        }
        me.activateModule(moduleName, me.activeModule);
    },

    # Activate a module, keeping the module stack unchanged. Returning from
    # the active module pops the same parent from the module stack as the
    # previously active module would have.
    sidestepModule: func (moduleName) {
        me.activateModule(moduleName);
    },

    # Activate a module, clearing the module stack. Returning from the
    # active module will not work, because the module stack is now empty.
    gotoModule: func (moduleName) {
        me.moduleStack = [];
        me.activateModule(moduleName);
    },

    # Pop a module from the module stack and activate it.
    popModule: func () {
        var target = pop(me.moduleStack);
        me.activateModule(target);
    },

    activateModule: func (module, parent = nil) {
        if (me.activeModule != nil) {
            me.activeModule.deactivate();
        }
        if (typeof(module) == "scalar") {
            var factory = me.makeModule[module];
            if (factory == nil) {
                me.activeModule = PlaceholderModule.new(me, parent, module);
            }
            else {
                me.activeModule = factory(me, parent);
            }
        }
        else if (typeof(module) == "func") {
            me.activeModule = module(me, parent);
        }
        else {
            me.activeModule = module;
        }
        if (me.activeModule != nil) {
            me.activeModule.activate();
            me.activeModule.fullRedraw();
        }
        else {
            me.clear();
        }
    },

    peekScratchpad: func () {
        return me.scratchpad;
    },

    popScratchpad: func () {
        var val = me.scratchpad;
        me.scratchpad = "";
        me.scratchpadElem.setText(me.scratchpad);
        return val;
    },

    setScratchpad: func (str) {
        if (typeof(str) != 'scalar') {
            print("Warning: trying to fill scratchpad with non-scalar");
            debug.dump(str);
            str = '';
        }
        me.scratchpad = str ~ '';
        me.scratchpadElem.setText(me.scratchpad);
        me.scratchpadElem.setColor(1, 1, 1);
        me.scratchpadMsg = '';
    },

    setScratchpadMsg: func (str, color = 0) {
        me.scratchpadMsgColor = color;
        var c = mcdu_colors[me.scratchpadMsgColor];

        me.scratchpadMsg = str ~ '';
        me.scratchpadElem.setText(me.scratchpadMsg);
        me.scratchpadElem.setColor(c[0], c[1], c[2]);
    },

    handleDEL: func () {
        var sp = me.peekScratchpad();
        var spm = me.scratchpadMsg;
        if (spm != '') {
            me.setScratchpadMsg('', mcdu_white);
        }
        else if (sp == '') {
            me.setScratchpad('*DELETE*');
        }
        else if (substr(sp, 0, 1) == '*' or substr(sp, -1, 1) == '-') {
            me.popScratchpad();
        }
    },

    handleCommand: func () {
        if (!me.powered) {
            # if not powered, don't do anything
            return;
        }
        var cmd = me.commandprop.getValue();
        if (size(cmd) == 1) {
            # this is a "char" command
            me.scratchpad = me.scratchpad ~ cmd;
            me.scratchpadElem.setText(me.scratchpad);
        }
        else if (cmd == "CLR") {
            var l = size(me.scratchpad);
            if (l > 0) {
                me.scratchpad = substr(me.scratchpad, 0, l - 1);
                me.scratchpadElem.setText(me.scratchpad);
            }
        }
        else if (cmd == "DEL") {
            me.handleDEL();
        }
        else if (cmd == "RADIO") {
            me.gotoModule("RADIO");
        }
        else if (cmd == "DLK") {
            me.gotoModule("DLK");
        }
        else if (cmd == "TRS") {
            me.gotoModule("TRS");
        }
        else if (cmd == "PROG") {
            me.gotoModule("PROG");
        }
        else if (cmd == "MENU") {
            me.gotoModule("MENU");
        }
        else if (cmd == "CB") {
            me.gotoModule("CB");
        }
        else if (cmd == "RTE") {
            me.gotoModule("RTE");
        }
        else if (cmd == "FPL") {
            me.gotoModule("FPL");
        }
        else if (cmd == "PERF") {
            me.gotoModule("PERFINDEX");
        }
        else if (cmd == "NAV") {
            me.gotoModule("NAVINDEX");
        }
        else if (cmd == "NEXT") {
            if (me.activeModule != nil) {
                me.activeModule.nextPage();
            }
        }
        else if (cmd == "PREV") {
            if (me.activeModule != nil) {
                me.activeModule.prevPage();
            }
        }
        else if (cmd == "EASTEREGG") {
            me.gotoModule("TEST");
        }
        else {
            if (me.activeModule != nil) {
                me.activeModule.handleCommand(cmd);
            }
        }
    },

    initCanvas: func () {
        me.display = canvas.new({
            "name": "MCDU" ~ me.num,
            "size": [512,512],
            "view": [512,512],
            "mipmapping": 1
        });
        me.display.addPlacement({"node": "MCDU" ~ me.num});
        me.g = me.display.createGroup();

        var x = 0;
        var y = 0;
        var i = 0;
        for (y = 0; y < cells_y; y += 1) {
            for (x = 0; x < cells_x; x += 1) {
                var bgElem = me.g.createChild("path", "screenbuf_bg_" ~ i);

                bgElem.rect(
                    x * cell_w + margin_left + 1,
                    y * cell_h + margin_top + 3,
                    cell_w,
                    cell_h);
                bgElem.setColorFill(0, 0, 0);
                append(me.screenbufElems.bg, bgElem);

                var fgElem = me.g.createChild("text", "screenbuf_fg_" ~ i);

                fgElem.setText("X");
                fgElem.setColor(1,1,1);
                fgElem.setFontSize(font_size_large);
                fgElem.setFont("LiberationFonts/LiberationMono-Regular.ttf");
                fgElem.setTranslation(x * cell_w + margin_left + cell_w * 0.5, y * cell_h + margin_top + cell_h);
                fgElem.setAlignment('center-baseline');
                append(me.screenbufElems.fg, fgElem);

                append(me.screenbuf, [" ", 0]);

                i += 1;
            }
        }

        me.repaintScreen();

        me.scratchpadElem = me.g.createChild("text", "scratchpad");
        me.scratchpadElem.setText("");
        me.scratchpadElem.setFontSize(font_size_large);
        me.scratchpadElem.setFont("LiberationFonts/LiberationMono-Regular.ttf");
        me.scratchpadElem.setColor(1,1,1);
        me.scratchpadElem.setTranslation(margin_left, (cells_y + 1) * cell_h + margin_top);

        # Dividers
        # Vertical
        var d = nil;
        var cx = margin_left + cells_x * cell_w / 2;

        d = me.g.createChild("path");
        d.moveTo(cx, margin_top + cell_h + 4);
        d.vertTo(margin_top + cell_h * 5 + 4);
        d.setColor(1,1,1);
        d.setStrokeLineWidth(2);
        d.hide();
        append(me.dividers, d);

        d = me.g.createChild("path");
        d.moveTo(cx, margin_top + cell_h * 5 + 4);
        d.vertTo(margin_top + cell_h * 9 + 4);
        d.setColor(1,1,1);
        d.setStrokeLineWidth(2);
        d.hide();
        append(me.dividers, d);

        d = me.g.createChild("path");
        d.moveTo(cx, margin_top + cell_h * 9 + 4);
        d.vertTo(margin_top + cell_h * 13 + 4);
        d.setColor(1,1,1);
        d.setStrokeLineWidth(2);
        d.hide();
        append(me.dividers, d);

        # Horizontal
        d = me.g.createChild("path");
        d.moveTo(margin_left, margin_top + cell_h * 5 + 4);
        d.horizTo(margin_left + cells_x * cell_w);
        d.setColor(1,1,1);
        d.setStrokeLineWidth(2);
        d.hide();
        append(me.dividers, d);

        d = me.g.createChild("path");
        d.moveTo(margin_left, margin_top + cell_h * 9 + 4);
        d.horizTo(margin_left + cells_x * cell_w);
        d.setColor(1,1,1);
        d.setStrokeLineWidth(2);
        d.hide();
        append(me.dividers, d);

        # Focus box
        me.focusBoxElem = me.g.createChild("path");
        me.focusBoxElem.setColor(1,1,1);
        me.focusBoxElem.setStrokeLineWidth(2);
        me.focusBoxElem.hide();
    },

    setFocusBox: func (x, y, w) {
        me.focusBoxElem.reset();
        me.focusBoxElem.rect(
            margin_left + x * cell_w,
            margin_top + y * cell_h + 4,
            cell_w * w, cell_h);
        me.focusBoxElem.setColor(1,1,1);
        me.focusBoxElem.setStrokeLineWidth(2);
        me.focusBoxElem.show();
    },

    clearFocusBox: func () {
        me.focusBoxElem.hide();
    },

    clear: func () {
        var i = 0;
        for (i = 0; i < num_cells; i += 1) {
            me.screenbuf[i] = [" ", 0];
            me.repaintCell(i);
        }
        for (i = 0; i < size(me.dividers); i += 1) {
            me.dividers[i].hide();
        }
        me.clearFocusBox();
    },

    showDivider: func (i) {
        if (i >= 0 and i < size(me.dividers)) {
            me.dividers[i].show();
        }
    },

    hideDivider: func (i) {
        if (i >= 0 and i < size(me.dividers)) {
            me.dividers[i].hide();
        }
    },

    repaintScreen: func () {
        var i = 0;
        for (i = 0; i < num_cells; i += 1) {
            me.repaintCell(i);
        }
    },

    repaintCell: func (i) {
        var fgElem = me.screenbufElems.fg[i];
        var bgElem = me.screenbufElems.bg[i];
        var flags = me.screenbuf[i][1];
        var colorIndex = flags & 0x07;
        var largeSize = flags & mcdu_large;
        var inverted = flags & mcdu_reverse;
        var color = mcdu_colors[colorIndex];

        fgElem.setText(me.screenbuf[i][0]);
        if (inverted) {
            fgElem.setColor(0, 0, 0);
            bgElem.setColorFill(color[0], color[1], color[2]);
        }
        else {
            fgElem.setColor(color[0], color[1], color[2]);
            bgElem.setColorFill(0, 0, 0);
        }

        if (largeSize) {
            fgElem.setFontSize(font_size_large);
        }
        else {
            fgElem.setFontSize(font_size_small);
        }
    },

    print: func (x, y, str, flags) {
        if (typeof(str) != "scalar") {
            printf("Warning: tried to print object of type %s", typeof(str));
            return;
        }
        str = str ~ '';
        var i = y * cells_x + x;
        if (y < 0 or y >= cells_y) {
            return;
        }
        for (var p = 0; p < size(str); ) {
            var q = utf8NumBytes(str[p]);
            var c = substr(str, p, q);
            p += q;
            if (x >= 0) {
                me.screenbuf[i] = [c, flags];
                me.repaintCell(i);
            }
            i += 1;
            x += 1;
            if (x >= cells_x) {
                break;
            }
        }
    }
};


