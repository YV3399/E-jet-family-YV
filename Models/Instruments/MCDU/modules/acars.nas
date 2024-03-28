var ACARSConfigModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ACARSConfigModule, m.parents);
        return m;
    },

    getTitle: func () { return 'DLK SETUP' },

    getNumPages: func () {
        return 1;
    },

    loadPageItems: func (n) {
        me.views = [
            StaticView.new(1, 1, 'WEATHER SOURCE', mcdu_white),
            FormatView.new(1, 2, mcdu_green | mcdu_large, 'ACARS-CONFIG-WEATHER', 12, "%-12s"),
            StaticView.new(1, 3, 'ATIS SOURCE', mcdu_white),
            FormatView.new(1, 4, mcdu_green | mcdu_large, 'ACARS-CONFIG-ATIS', 12, "%-12s"),
            StaticView.new(1, 5, 'PROGRESS', mcdu_white),
            FormatView.new(1, 6, mcdu_green | mcdu_large, 'ACARS-CONFIG-PROGRESS', 12, "%-12s"),
            FormatView.new(20, 6, mcdu_green | mcdu_large, 'ACARS-CONFIG-DISPATCH-CALLSIGN', 20, "%4s",
                func(val) { return (val == '') ? 'AUTO' : val; }),
        ];
        me.controllers = {
            'L1': CycleController.new('ACARS-CONFIG-WEATHER', ['AUTO', 'HOPPIE', 'NOAA', 'OFF']),
            'L2': CycleController.new('ACARS-CONFIG-ATIS', ['AUTO', 'HOPPIE', 'DATIS', 'OFF']),
            'L3': CycleController.new('ACARS-CONFIG-PROGRESS', ['AUTO', 'HOPPIE', 'OFF']),
            'R3': ModelController.new('ACARS-CONFIG-DISPATCH-CALLSIGN'),
        };
        append(me.views, StaticView.new( 0, 12, left_triangle ~ me.ptitle, mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ret");
    },
};

var ACARSLogModule = {
    new: func (mcdu, parentModule, dir) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ACARSLogModule, m.parents);
        m.listener = nil;
        m.title = dir ~ ' MSGS';
        m.shorttitle = dir;
        m.historyNode = props.globals.getNode('/acars/telex/' ~ (dir == 'SENT' ? 'sent' : 'received'));
        m.dir = dir;
        m.timer = nil;
        return m;
    },

    getTitle: func () { return me.title; },
    getShortTitle: func () { return me.shorttitle; },

    activate: func () {
        me.loadPage(me.page);
        me.timer = maketimer(1, me, func () {
            me.loadPage(me.page);
            me.fullRedraw();
        });
        me.timer.start();
    },

    deactivate: func () {
        if (me.timer != nil) {
            me.timer.stop();
            me.timer = nil;
        }
        me.unloadPage();
    },

    getNumPages: func () {
        var refs = me.historyNode.getChildren();
        return math.max(1, math.floor((size(refs) + 4) / 5));
    },

    loadPageItems: func (n) {
        var refs = me.historyNode.getChildren();
        me.views = [];
        me.controllers = {};
        var r = size(refs) - 1 - n * 5;
        var y = 1;
        for (var i = 0; i < 5; i += 1) {
            if (r < 0) break;
            var msgID = refs[r].getValue();
            var item = refs[-1-i];
            if (item == nil) {
                continue;
            }
            var msg = item.getValues();
            # debug.dump(item, msg);
            var summary = msg.text;
            if (size(summary) > 22) {
                summary = substr(summary, 0, 20) ~ '..';
            }
            var timestamp4 = substr(msg.timestamp or '---------------------------------------', 9, 4);
            append(me.views,
                StaticView.new(1, y, sprintf("%04sZ", timestamp4), mcdu_white));
            var flags = mcdu_white;
            var status = string.uc(msg.status or '');
            if (status == 'NEW')
                flags = mcdu_white | mcdu_reverse;
            append(me.views, StaticView.new(23 - size(status), y, status, flags));
            append(me.views, StaticView.new(1, y+1, summary, mcdu_green | mcdu_large));
            append(me.views, StaticView.new(23, y+1, right_triangle, mcdu_white | mcdu_large));
            var lsk = 'R' ~ (i + 1);
            var self = me;
            me.controllers[lsk] = (func(serial) {
                return SubmodeController.new(func (owner, parent) {
                    return ACARSMessageModule.new(owner, parent, self.dir, serial);
                });
            })(msg.serial);
            r -= 1;
            y += 2;
        }
        append(me.views, StaticView.new( 0, 12, left_triangle ~ "DLK INDEX", mcdu_white | mcdu_large));
        append(me.views, StaticView.new(14, 12, "CLEAR LOG" ~ right_triangle, mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ret");
        me.controllers['R6'] = FuncController.new(func (owner, val) {
            globals.acars.system.clearHistory();
            return nil;
        });
    },
};

var ACARSInfoReqModule = {
    new: func (mcdu, parentModule, what) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ACARSInfoReqModule, m.parents);
        m.what = what;
        return m;
    },

    getTitle: func () { return string.uc(me.what) ~ " RQ"; },

    getNumPages: func {
        return 1;
    },

    loadPageItems: func(n) {
        me.views = [
            StaticView.new(15, 1, "STATION", mcdu_white),
            FormatView.new(18, 2, mcdu_green | mcdu_large, "ACARS-INFOREQ-STATION", 6, orBoxes(6, 1)),

            StaticView.new( 0, 12, left_triangle ~ "DLK INDEX", mcdu_white | mcdu_large),
            FormatView.new(19, 12, mcdu_white | mcdu_large, "ACARS-INFOREQ-STATION", 5,
                func (station) {
                    if (station != nil and station != '')
                        return "SEND" ~ right_triangle;
                    else
                        return "     ";
                }),
        ];

        me.controllers = {
            'R1': ModelController.new('ACARS-INFOREQ-STATION'),

            'L6': SubmodeController.new('ret'),
            'R6': FuncController.new(func (owner, val) {
                        if (globals.acars.system.sendInfoRequest(owner.what))
                            owner.ret();
                    }),
        };
    },
};

var ACARSPDCModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ACARSPDCModule, m.parents);
        return m;
    },

    getTitle: func () { return "PREDEP CLX RQ"; },
    getShortTitle: func () { return "PDC RQ"; },

    getNumPages: func {
        return 1;
    },

    activate: func {
        var propDefaults = [
                    ["/acars/pdc-dialog/flight-id", "/sim/multiplay/callsign"],
                    ["/acars/pdc-dialog/departure-airport", "/autopilot/route-manager/departure/airport"],
                    ["/acars/pdc-dialog/destination-airport", "/autopilot/route-manager/destination/airport"],
                ];
        foreach (var pd; propDefaults) {
            var dprop = props.globals.getNode(pd[0]);
            if (dprop.getValue() == '')
                dprop.setValue(getprop(pd[1]));
        }
        setprop('/acars/pdc-dialog/aircraft-type', substr(getprop('instrumentation/mcdu/ident/model'), 0, 4));
        me.loadPage(me.page);
    },

    loadPageItems: func(n) {
        me.views = [
            StaticView.new(1, 1, "FLT ID", mcdu_white),
            FormatView.new(1, 2, mcdu_green | mcdu_large, "ACARS-PDC-FLIGHT-ID", 7, orBoxes(7)),

            StaticView.new(15, 1, "FACILITY", mcdu_white),
            FormatView.new(19, 2, mcdu_green | mcdu_large, "ACARS-PDC-FACILITY", 4, orBoxes(4, 1)),

            StaticView.new(1, 3, "A/C TYPE", mcdu_white),
            FormatView.new(1, 4, mcdu_green | mcdu_large, "ACARS-PDC-AIRCRAFT-TYPE", 4, orBoxes(4)),

            StaticView.new(19, 3, "ATIS", mcdu_white),
            FormatView.new(22, 4, mcdu_green | mcdu_large, "ACARS-PDC-ATIS", 1, orBoxes(1, 1)),

            StaticView.new(1, 5, "ORIG", mcdu_white),
            FormatView.new(1, 6, mcdu_green | mcdu_large, "ACARS-PDC-DEPARTURE-AIRPORT", 4, orBoxes(4)),

            StaticView.new(19, 5, "DEST", mcdu_white),
            FormatView.new(19, 6, mcdu_green | mcdu_large, "ACARS-PDC-DESTINATION-AIRPORT", 4, orBoxes(4, 1)),

            StaticView.new(1, 7, "GATE", mcdu_white),
            FormatView.new(1, 8, mcdu_green | mcdu_large, "ACARS-PDC-GATE", 8, orBoxes(8)),

            StaticView.new( 0, 12, left_triangle ~ "DLK INDEX", mcdu_white | mcdu_large),
            FormatView.new(19, 12, mcdu_white | mcdu_large, "ACARS-PDC-VALID", 5,
                func (valid) {
                    if (valid)
                        return "SEND" ~ right_triangle;
                    else
                        return "     ";
                }),
        ];

        me.controllers = {
            'L1': ModelController.new('ACARS-PDC-FLIGHT-ID'),
            'R1': ModelController.new('ACARS-PDC-FACILITY'),
            'L2': ModelController.new('ACARS-PDC-AIRCRAFT-TYPE'),
            'R2': ModelController.new('ACARS-PDC-ATIS'),
            'L3': ModelController.new('ACARS-PDC-DEPARTURE-AIRPORT'),
            'R3': ModelController.new('ACARS-PDC-DESTINATION-AIRPORT'),
            'L4': ModelController.new('ACARS-PDC-GATE'),

            'L6': SubmodeController.new('ret'),
            'R6': FuncController.new(func (owner, val) {
                        if (globals.acars.system.sendPDC())
                            owner.ret();
                    }),
        };
    },
};

var ACARSTelexModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ACARSTelexModule, m.parents);
        return m;
    },

    getTitle: func () { return "ACARS MSG"; },

    getNumPages: func {
        return 1;
    },

    loadPageItems: func(n) {
        me.views = [
            StaticView.new(1, 1, "FROM", mcdu_white),
            FormatView.new(1, 2, mcdu_green | mcdu_large, "CALLSIG", 7, orDashes(7)),

            StaticView.new(20, 1, "TO", mcdu_white),
            FormatView.new(16, 2, mcdu_green | mcdu_large, "ACARS-TELEX-TO", 7, orDashes(7, 1)),

            StaticView.new(1, 3, "TEXT", mcdu_white),
            FormatView.new(1, 4, mcdu_green | mcdu_large, "ACARS-TELEX-TEXT", 22, orDashes(22)),

            StaticView.new( 0, 12, left_triangle ~ "DLK INDEX", mcdu_white | mcdu_large),
            FormatView.new(19, 12, mcdu_white | mcdu_large, "ACARS-TELEX-TO", 5,
                func (to) {
                    if (to != nil and to != '')
                        return "SEND" ~ right_triangle;
                    else
                        return "     ";
                }),
        ];

        me.controllers = {
            'R1': ModelController.new('ACARS-TELEX-TO'),
            'L2': ModelController.new('ACARS-TELEX-TEXT'),

            'L6': SubmodeController.new('ret'),
            'R6': FuncController.new(func (owner, val) {
                        if (globals.acars.system.sendTelex()) {
                            globals.acars.system.clearTelexDialog();
                            owner.ret();
                        }
                    }),
        };
    },
};

var ACARSMessageModule = {
    new: func (mcdu, parentModule, dir, serial) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ACARSMessageModule, m.parents);
        m.title = dir;
        m.msgNode = props.globals.getNode('/acars/telex/' ~ (dir == 'SENT' ? 'sent' : 'received') ~ '/m' ~ serial);
        if (m.msgNode != nil)
            m.lines = me.splitLines(m.msgNode.getValue('text'));
        m.dir = dir;
        # debug.dump(m.lines);
        return m;
    },

    getTitle: func () { return me.title; },

    activate: func () {
        if (me.msgNode == nil) {
            me.mcdu.popModule();
            return;
        }
        if (me.msgNode.getValue('status') == 'new') {
            me.msgNode.setValue('status', '');
            globals.acars.system.updateUnread();
        }
        me.loadPage(me.page);
        me.timer = maketimer(1, me, func () {
            me.loadPage(me.page);
            me.fullRedraw();
        });
        me.timer.start();
    },

    deactivate: func () {
        if (me.timer != nil) {
            me.timer.stop();
            me.timer = nil;
        }
        me.unloadPage();
    },

    splitLines: func (text) {
        var lines = [];
        var origLines = split("\n", text);
        foreach (var origLine; origLines) {
            # debug.dump('LINE:', origLine);
            var words = split(' ', origLine);
            # debug.dump('WORDS:', words);
            var line = '';
            var freshLine = 1;
            foreach (var word; words) {
                if (freshLine)
                    freshLine = 0;
                else
                    line = line ~ ' ';
                if (size(line) + size(word) > 22) {
                    if (freshLine) {
                        append(lines, substr(word, 0, 20) ~ '..');
                    }
                    else {
                        append(lines, line);
                        if (size(word) > 22) {
                            append(lines, substr(word, 0, 20) ~ '..');
                            line = '';
                            freshLine = 1;
                        }
                        else {
                            line = word;
                            freshLine = 0;
                        }
                    }
                }
                else {
                    line = line ~ word;
                    freshLine = 0;
                }
            }
            if (line != '')
                append(lines, line);
        }
        return lines;
    },

    printMessage: func {
        if (me.msgNode == nil) return;
        var msgTxt = me.msgNode.getValue('text');
        var wrapped = lineWrap(msgTxt, printer.paperWidth, '...');
        logprint(1, 'PRINT MESSAGE:', debug.string(msgTxt) ~ ' -> ' ~ debug.string(wrapped));
        var lines =
                [ "--- ACARS BEGIN ---"
                , sprintf("%s %s %s",
                    me.msgNode.getValue('timestamp'),
                    me.msgNode.getValue('from'),
                    me.msgNode.getValue('to') or getprop('/sim/multiplay/callsign'))
                , ''
                ] ~
                wrapped ~
                [ "--- ACARS END ---"
                , ''
                ];
        printer.newJob(string.join("\n", lines));
    },


    getNumPages: func () {
        return math.max(1, math.ceil((size(me.lines) + 2) / 9));
    },

    loadPageItems: func (n) {
        me.views = [];
        me.controllers = {};
        var i = 0;
        var y = 2;
        if (n == 0) {
            i = 0;
            var timestamp4 = substr(me.msgNode.getValue('timestamp') or '---------------------------------------', 9, 4);
            append(me.views,
                StaticView.new(1, y, sprintf("%04sZ", timestamp4), mcdu_white));
            if (me.dir == 'SENT') {
                append(me.views, StaticView.new( 7, y, 'TO', mcdu_white));
                append(me.views, StaticView.new(12, y, me.msgNode.getValue('to'), mcdu_white | mcdu_large));
            }
            else {
                append(me.views, StaticView.new( 7, y, 'FROM', mcdu_white));
                append(me.views, StaticView.new(12, y, me.msgNode.getValue('from'), mcdu_white | mcdu_large));
            }
            append(me.views, StaticView.new(18, y, sprintf("%6s", string.uc(me.msgNode.getValue('status'))), mcdu_green | mcdu_large));
            y += 2;
        }
        else {
            i = n * 9 - 2;
        }
        while (y < 11 and i < size(me.lines)) {
            append(me.views, StaticView.new( 0, y, me.lines[i], mcdu_green | mcdu_large));
            i += 1;
            y += 1;
        }
        append(me.views, StaticView.new( 0, 12, left_triangle ~ me.ptitle, mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ret");
        append(me.views, StaticView.new(12, 12, sprintf("%11s", 'PRINT') ~ right_triangle, mcdu_white));
        me.controllers['R6'] = FuncController.new(func (owner, val) { return owner.printMessage(); });
    },
};

