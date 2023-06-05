var ATCLogonModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ATCLogonModule, m.parents);
        return m;
    },

    getTitle: func () { return "ATC LOGON/STATUS"; },
    getShortTitle: func () { return "ATC LOGON"; },
    getNumPages: func () { return 2; },

    activate: func () {
        me.loadPage(me.page);
        me.timer = maketimer(1, me, func () {
            globals.cpdlc.system.updateDatalinkStatus();
            me.loadPage(me.page);
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

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new( 1,  1, "LOGON TO", mcdu_white),
                FormatView.new( 0,  2, mcdu_green | mcdu_large, "CPDLC-LOGON-STATION", 12, "%-12s",
                    func (val) {
                        if (val == nil or val == '')
                            return left_triangle ~ "--------";
                        else
                            return val;
                    }),

                StaticView.new( 1,  3, "FLT ID", mcdu_white),
                FormatView.new( 8,  3, mcdu_green | mcdu_large, "CPDLC-DRIVER", 8, "%-8s"),
                FormatView.new( 0,  4, mcdu_green | mcdu_large, "FLTID", 8, "%-8s"),

                StaticView.new( 2,  5, "TAIL NO", mcdu_white),
                FormatView.new( 1,  6, mcdu_blue | mcdu_large, "TAIL", 8, "%-8s"),

                StaticView.new(17,  1, "LOGON", mcdu_white),
                FormatView.new(12,  2,
                    func(val) {
                        if (val == globals.cpdlc.LOGON_ACCEPTED)
                            return mcdu_green | mcdu_large;
                        elsif (val == globals.cpdlc.LOGON_OK)
                            return mcdu_white | mcdu_large;
                        elsif (val == globals.cpdlc.LOGON_FAILED)
                            return mcdu_yellow | mcdu_large;
                        elsif (val == globals.cpdlc.LOGON_SENT)
                            return mcdu_green;
                        else return mcdu_white;
                    },
                    "CPDLC-LOGON-STATUS", 12,
                    "%-12s",
                    func(val) {
                        if (val == globals.cpdlc.LOGON_ACCEPTED)
                            return "ACCEPTED";
                        elsif (val == globals.cpdlc.LOGON_OK)
                            return "    OPEN";
                        elsif (val == globals.cpdlc.LOGON_FAILED)
                            return "  FAILED";
                        elsif (val == globals.cpdlc.LOGON_SENT)
                            return "    SENT";
                        elsif (val == globals.cpdlc.LOGON_NOT_CONNECTED)
                            return "    SEND" ~ right_triangle;
                        else
                            return "        ";
                    }),

                StaticView.new(15,  3, "ACT CTR", mcdu_white),
                FormatView.new(12,  4, mcdu_green, "CPDLC-CURRENT-STATION", 12),

                StaticView.new(14,  5, "NEXT CTR", mcdu_white),
                FormatView.new(12,  6, mcdu_green | mcdu_large, "CPDLC-NEXT-STATION", 12),

                StaticView.new(17,  7, "ORIGIN", mcdu_white),
                FormatView.new(20,  8, mcdu_green | mcdu_large, "DEPARTURE-AIRPORT", 4),

                StaticView.new(20,  9, "DEST", mcdu_white),
                FormatView.new(20, 10, mcdu_green | mcdu_large, "ARRIVAL-AIRPORT", 4),

                StaticView.new(14, 11, "DLK INDEX", mcdu_white),
                FormatView.new(12, 12, mcdu_green | mcdu_large, "CPDLC-DATALINK-STATUS", 12, "%12s",
                    func(val) {
                        if (val)
                            return "READY";
                        else
                            return "DISCONNECTED";
                    }),
            ];

            me.controllers = {
                'L1': ModelController.new("CPDLC-LOGON-STATION"),
                'R1': FuncController.new(func {
                            if (getprop('/cpdlc/logon-station')) {
                                # A logon station has been selected: connect.
                                if (getprop('/cpdlc/logon-status') == cpdlc.LOGON_ACCEPTED) {
                                    # This is not how the real aircraft works, but
                                    # some controllers on VATSIM will not send the
                                    # CURRENT ATC UNIT message, which leaves the
                                    # CPDLC system in an "ACCEPTED" state.
                                    globals.cpdlc.system.setCurrentStation(getprop('/cpdlc/logon-station'))
                                }
                                else {
                                    globals.cpdlc.system.connect();
                                }
                            }
                            else {
                                # No logon station selected.
                                var status = getprop('/cpdlc/logon-status');
                                if (status == cpdlc.LOGON_OK or status == cpdlc.LOGON_ACCEPTED) {
                                    globals.cpdlc.system.disconnect();
                                }
                            }
                            return nil;
                        }),
            };
        }
        elsif (n == 1) {
            me.views = [];
        }
        else {
            me.views = [];
        }

        if (me.ptitle != nil) {
            me.controllers["L6"] = SubmodeController.new("ret");
            append(me.views,
                    StaticView.new(0, 12, left_triangle ~ me.ptitle, mcdu_white));
        }
    },
};


