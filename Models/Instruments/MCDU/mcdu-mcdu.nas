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
            scratchpadBorderElem: nil,
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
        setlistener("/controls/keyboard/grabbed", func (node) {
            var have = (node.getValue() == n);
            if (have) {
                m.handleKeyboardGrab();
            }
            else {
                m.handleKeyboardRelease();
            }
        }, 1, 0);
        var unreadProp = props.globals.getNode('/cpdlc/incoming', 1);
        setlistener(unreadProp, func(node) {
            if (node.getBoolValue()) {
                m.setScratchpadMsg('ATC UPLINK', mcdu_yellow);
            }
        }, 1, 1);
        return m;
    },

    handleKeyboardGrab: func () {
        me.scratchpadBorderElem.show();
    },

    handleKeyboardRelease: func () {
        me.scratchpadBorderElem.hide();
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

        # CPDLC modules
        "CPDLC-LOGON": func (mcdu, parent) { return ATCLogonModule.new(mcdu, parent); },
        "CPDLC-LOG": func (mcdu, parent) { return CPDLCLogModule.new(mcdu, parent); },
        "CPDLC-DATALINK": func (mcdu, parent) { return CPDLCDatalinkSetupModule.new(mcdu, parent); },
        "CPDLC-NEWEST-UPLINK": func (mcdu, parent) {
            var newestMessage = getprop('/cpdlc/newest-unread');
            return CPDLCMessageModule.new(mcdu, parent, newestMessage);
        },

        # ACARS modules
        "ACARS-RCVD": func (mcdu, parent) { return ACARSLogModule.new(mcdu, parent, 'RECEIVED'); },
        "ACARS-SENT": func (mcdu, parent) { return ACARSLogModule.new(mcdu, parent, 'SENT'); },
        "ACARS-PDC": func (mcdu, parent) { return ACARSPDCModule.new(mcdu, parent); },
        "ACARS-TELEX": func (mcdu, parent) { return ACARSTelexModule.new(mcdu, parent); },
        "ACARS-METAR": func (mcdu, parent) { return ACARSInfoReqModule.new(mcdu, parent, 'metar'); },
        "ACARS-TAF": func (mcdu, parent) { return ACARSInfoReqModule.new(mcdu, parent, 'taf'); },
        "ACARS-SHORTTAF": func (mcdu, parent) { return ACARSInfoReqModule.new(mcdu, parent, 'shorttaf'); },
        "ACARS-ATIS": func (mcdu, parent) { return ACARSInfoReqModule.new(mcdu, parent, 'atis'); },
        "ACARS-CONFIG": func (mcdu, parent) { return ACARSConfigModule.new(mcdu, parent); },
        "ACARS-NEWEST-UNREAD": func (mcdu, parent) {
            var newestMessage = getprop('/acars/telex/newest-unread');
            return ACARSMessageModule.new(mcdu, parent, 'RECEIVED', newestMessage);
        },

        # Index modules
        "ATCINDEX": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "ATC INDEX",
                        "ATC INDEX",
                        [ # PAGE 1
                          [ "CPDLC-EMERGENCY", "EMERGENCY" ]
                        , [ "CPDLC-REQUEST", "REQUEST" ]
                        , [ "CPDLC-WHENCANWE", "WHEN CAN WE" ]
                        , [ "CPDLC-DOWNLINK-TXTD-1", "FREE TEXT" ]
                        , nil
                        , [ "CPDLC-LOGON", "LOGON/STATUS" ]

                        , [ "CPDLC-DOWNLINK-RTED-5", "POS REPORT" ]
                        , [ "CPDLC-REPORT", "REPORT" ]
                        , [ "CPDLC-DOWNLINK-COMD-1", "VOICE" ]
                        , [ "CPDLC-CLEARANCE", "CLEARANCE" ]
                        , nil
                        , [ "CPDLC-LOG", "LOG" ]

                          # PAGE 2
                        , [ "CPDLC-DATALINK", "DATALINK CFG" ]
                        , nil
                        , nil
                        , nil
                        , nil
                        , nil

                        , nil
                        , nil
                        , nil
                        , nil
                        , nil
                        , nil
                        ]); },
        "CPDLC-REPORT": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "REPORT",
                        "REPORT",
                        [ # PAGE 1
                          [ "CPDLC-DOWNLINK-LATD-3", "CLR/WEATHER" ]
                        , [ "CPDLC-DOWNLINK-LATD-4", "BACK ON RTE" ]
                        , [ "CPDLC-DOWNLINK-LATD-5", "DIVERTING" ]
                        , nil
                        , nil
                        , [ "ret", "ATC INDEX" ]

                        , [ "CPDLC-DOWNLINK-LATD-8", "PASSING WP" ]
                        , [ "CPDLC-DOWNLINK-ADVD-2", "TRAFFIC" ]
                        , [ "CPDLC-DOWNLINK-LVLD-18", "TOD" ]
                        , [ "CPDLC-DOWNLINK-COMD-2", "RELAY" ]
                        , nil
                        , nil

                          # PAGE 2

                        , [ "CPDLC-DOWNLINK-LATD-6", "OFFSETTING" ]
                        , nil
                        , [ "CPDLC-DOWNLINK-LVLD-12", "PREF FL" ]
                        , [ "CPDLC-DOWNLINK-LVLD-8", "LEAVING FL" ]
                        , [ "CPDLC-DOWNLINK-LVLD-9", "MAINT FL" ]
                        , [ "ret", "ATC INDEX" ]

                        , [ "CPDLC-DOWNLINK-LATD-7", "DEVIATING" ]
                        , nil
                        , [ "CPDLC-DOWNLINK-LVLD-10", "BLOCK FL" ]
                        , [ "CPDLC-DOWNLINK-LVLD-13", "CLIMBING" ]
                        , [ "CPDLC-DOWNLINK-LVLD-14", "DESCENDING" ]
                        , nil
                        ]); },
        "CPDLC-EMERGENCY": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "EMERGENCY",
                        "EMERGENCY",
                        [ # PAGE 1
                          [ "CPDLC-DOWNLINK-EMGD-1", "PAN PAN" ]
                        , [ "CPDLC-DOWNLINK-EMGD-2", "MAYDAY" ]
                        , nil
                        , nil
                        , nil
                        , [ "ret", "ATC INDEX" ]

                        , [ "CPDLC-DOWNLINK-EMGD-3", "ENDRNC/POB" ]
                        , [ "CPDLC-DOWNLINK-EMGD-4", "CANCEL EMG" ]
                        , nil
                        , nil
                        , nil
                        , nil
                        ]); },
        "CPDLC-REQUEST": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "REQUEST",
                        "REQUEST",
                        [ # PAGE 1
                          [ "CPDLC-DOWNLINK-RTED-2", "FREEFORM" ]
                        , [ "CPDLC-DOWNLINK-SPDD-1", "SPEED" ]
                        , [ "CPDLC-DOWNLINK-RTED-1", "DIRECT" ]
                        , [ "CPDLC-DOWNLINK-RTED-6", "HEADING" ]
                        , [ "CPDLC-DOWNLINK-RTED-7", "TRACK" ]
                        , [ "ret", "ATC INDEX" ]

                        , [ "CPDLC-DOWNLINK-LVLD-1", "LEVEL" ]
                        , [ "CPDLC-DOWNLINK-LVLD-2", "CLIMB" ]
                        , [ "CPDLC-DOWNLINK-LVLD-3", "DESCENT" ]
                        , [ "CPDLC-DOWNLINK-LVLD-4", "LVL AT WAYP" ]
                        , [ "CPDLC-DOWNLINK-LVLD-5", "LVL AT TIME" ]
                        , nil
                        ]); },
        "CPDLC-WHENCANWE": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "WHEN CAN WE",
                        "WHEN CAN",
                        [ # PAGE 1
                          [ "CPDLC-DOWNLINK-RTED-8", "BACK ON ROUTE" ]
                        , [ "CPDLC-DOWNLINK-LVLD-6", "LOWER" ]
                        , [ "CPDLC-DOWNLINK-LVLD-7", "HIGHER" ]
                        , [ "CPDLC-DOWNLINK-SPDD-2", "SPEED" ]
                        , nil
                        , [ "ret", "ATC INDEX" ]

                        , nil
                        , nil
                        , nil
                        , nil
                        , nil
                        , nil
                        ]); },
        "CPDLC-CLEARANCE": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "CLEARANCE",
                        "CLEARANCE",
                        [ # PAGE 1
                          [ "CPDLC-DOWNLINK-RTED-2", "ROUTE" ]
                        , [ "CPDLC-DOWNLINK-RTED-3", "TYPE" ]
                        , nil
                        , nil
                        , nil
                        , [ "ret", "ATC INDEX" ]

                        , nil
                        , nil
                        , nil
                        , nil
                        , nil
                        , nil
                        ]); },
        "DATALINK": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "DATALINK INDEX",
                        "DLK INDEX",
                        [ # PAGE 1
                            [ "ACARS-RCVD", "RCVD MSGS" ]
                          , [ "ACARS-SENT", "SENT MSGS" ]
                          , nil
                          , nil
                          , [ "ACARS-CONFIG", "ACARS CFG" ]
                          , nil

                          , [ "ACARS-TELEX", "FREEFORM" ]
                          , [ "ACARS-WEATHER", "WEATHER" ]
                          , [ "ACARS-ATIS", "ATIS" ]
                          , [ "ACARS-PDC", "PREDEP CLX" ]
                          , [ "ACARS-OCC", "OCEANIC CLX" ]
                          , [ "ACARS-NEWEST-UNREAD",
                              func(x, y, ralign) {
                                return FormatView.new(x - 11, y, mcdu_white | mcdu_large, "ACARS-NEWEST-UNREAD", 5,
                                    func (serial) {
                                        if (serial != nil and serial != 0)
                                            return "NEW MESSAGE" ~ right_triangle;
                                        else
                                            return "     ";
                                    });
                              }
                            ]
                        ]); },
        "ACARS-WEATHER": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "WEATHER RQ",
                        "WEATHER",
                        [ # PAGE 1
                            [ "ACARS-METAR", "METAR" ]
                          , [ "ACARS-TAF", "TAF" ]
                          , [ "ACARS-SHORTTAF", "SHORTTAF" ]
                          , nil
                          , nil
                          , [ "ret", "DLK INDEX" ]

                          , nil
                          , nil
                          , nil
                          , nil
                          , nil
                          , [ "ACARS-NEWEST-UNREAD",
                              func(x, y, ralign) {
                                return FormatView.new(x - 11, y, mcdu_white | mcdu_large, "ACARS-NEWEST-UNREAD", 5,
                                    func (serial) {
                                        if (serial != nil and serial != 0)
                                            return "NEW MESSAGE" ~ right_triangle;
                                        else
                                            return "     ";
                                    });
                              }
                            ]
                        ]); },
        "NAVINDEX": func(mcdu, parent) { return IndexModule.new(mcdu, parent,
                        "NAV INDEX",
                        "NAV INDEX",
                        [ # PAGE 1
                          [ "NAVIDENT", "NAV IDENT" ]
                        , [ nil, "WPT LIST" ]
                        , [ nil, "FPL LIST" ]
                        , [ nil, "POS SENSORS" ]
                        , [ nil, "FIX INFO" ]
                        , [ "DEPARTURE", "DEPARTURE" ]

                        , [ "ATCINDEX", "ATC" ]
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
                        "PERF IDX",
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
        "RTE": func (mcdu, parent) { return RouteModule.new(mcdu, parent); },
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
        # print("--- MODULE STACK ---");
        # foreach (var m; me.moduleStack) {
        #     print(m.getTitle());
        # }
        if (me.activeModule != nil) {
            me.activeModule.deactivate();
        }
        if (typeof(module) == "scalar") {
            var factory = me.makeModule[module];
            if (factory == nil) {
                printf('makeModule entry not found for %s', module);
                var prefix = 'CPDLC-DOWNLINK-';
                var l = size(prefix);
                if (substr(module, 0, l) == prefix) {
                    var type = substr(module, l, 6);
                    printf('Found CPDLC-DOWNLINK- prefix, type = %s', type);
                    var downlink = globals.cpdlc.downlink_messages[type];
                    if (downlink == nil) {
                        me.activeModule = PlaceholderModule.new(me, parent, module);
                    }
                    else {
                        var parts = [];
                        var args = [];
                        foreach (var a; downlink.args) {
                            append(args, '');
                        }
                        append(parts, { type: type, args: args });
                        if (substr(type, 0, 4) != 'TXTD') {
                            append(parts, { type: 'TXTD-1', args: [''] });
                        }
                        me.activeModule = CPDLCComposeDownlinkModule.new(me, parent, parts, nil);
                    }
                }
                else {
                    me.activeModule = PlaceholderModule.new(me, parent, module);
                }
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
        # Early abort so as to not remove a scratchpad message that may exist
        if (me.scratchpad == '') return '';
        var val = me.scratchpad;
        me.scratchpad = '';
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
            me.scratchpadElem.setColor(1, 1, 1);
        }
        else if (cmd == "SP") {
            me.scratchpad = me.scratchpad ~ ' ';
            me.scratchpadElem.setText(me.scratchpad);
            me.scratchpadElem.setColor(1, 1, 1);
        }
        else if (cmd == "CLR") {
            if (me.scratchpad == '*DELETE*') {
                me.scratchpad = '';
                me.scratchpadElem.setText(me.scratchpad);
                me.scratchpadElem.setColor(1, 1, 1);
            }
            else {
                var l = size(me.scratchpad);
                if (l > 0) {
                    me.scratchpad = substr(me.scratchpad, 0, l - 1);
                    me.scratchpadElem.setText(me.scratchpad);
                    me.scratchpadElem.setColor(1, 1, 1);
                }
            }
        }
        else if (cmd == "DEL") {
            me.handleDEL();
        }
        else if (cmd == "RADIO") {
            me.gotoModule("RADIO");
        }
        else if (cmd == "DLK") {
            me.gotoModule("DATALINK");
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

        me.scratchpadBorderElem = me.g.createChild("path", "scratchpad-border");
        me.scratchpadBorderElem.setColor(0, 1, 1);
        me.scratchpadBorderElem.setColorFill(0, 0.2, 0.2);
        me.scratchpadBorderElem.rect(
            -1, cells_y * cell_h + margin_top + 5, 
            510, cell_h + 2 - 5);
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


