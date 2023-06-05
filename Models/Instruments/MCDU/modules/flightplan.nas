var FlightPlanModule = {
    new: func (mcdu, parentModule, specialMode=nil) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(FlightPlanModule, m.parents);
        m.specialMode = specialMode;
        m.selectedWP = nil;
        if (fms.modifiedFlightplan != nil) {
            m.fp = fms.modifiedFlightplan;
            m.fpStatus = 'MOD';
        }
        else {
            m.fp = flightplan();
            if (m.fp == nil) {
                m.fpStatus = '';
                m.fp = fms.getModifyableFlightplan();
            }
            else {
                m.fpStatus = 'ACT';
            }
        }
        m.timer = nil;
        return m;
    },

    startEditing: func () {
        if (me.fpStatus == 'ACT') {
            me.fp = fms.getModifyableFlightplan();
            me.fpStatus = 'MOD';
        }
    },

    finishEditing: func (fromRoute=0) {
        if (me.fpStatus != 'ACT') {
            me.fp = fms.commitFlightplan();
            me.fpStatus = 'ACT';
        }
    },

    cancelEditing: func () {
        if (me.fpStatus != 'ACT') {
            me.fp = fms.discardFlightplan();
            me.fpStatus = 'ACT';
        }
    },

    getNumPages: func () {
        var numEntries = me.fp.getPlanSize();
        var firstEntry = me.fp.current - 1;
        return math.max(1, math.ceil((numEntries - firstEntry) / 5));
    },

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

    getTitle: func () {
        return me.fpStatus ~ " FLT PLAN";
    },

    getShortTitle: func () {
        return me.fpStatus ~ " FPL";
    },

    deleteWP: func (wpi) {
        if (wpi > 0) {
            me.fp.deleteWP(wpi);
            fms.kickRouteManager();
        }
    },

    openDirectToModule: func (val, directFromIndex) {
        var this = me;
        me.startEditing();
        # debug.dump('Selected WP', me.selectedWP);
        if (me.selectedWP != nil and me.selectedWP.wp.id == val) {
            me.mcdu.pushModule(func (mcdu, parent) {
                return DirectToModule.new(mcdu, parent, this.fp, me.selectedWP, directFromIndex);
            });
        }
        else {
            me.mcdu.pushModule(func (mcdu, parent) {
                return DirectToModule.new(mcdu, parent, this.fp, val, directFromIndex);
            });
        }
        me.selectedWP = nil;
        me.mcdu.setScratchpad('');
    },

    loadPageItems: func (p) {
        var numWaypoints = me.fp.getPlanSize();
        var firstEntry = math.max(0, me.fp.current - 1);
        var firstWP = p * 5 + firstEntry;
        var transitionAlt = getprop("/controls/flight/transition-alt");
        me.views = [];
        me.controllers = {};
        var y = 1;
        if (p == 0) {
            append(me.views, StaticView.new(16, y, "SPD/ALT", mcdu_white));
            append(me.views, StaticView.new(1, y, "ORIGIN/ETD", mcdu_white));
        }
        for (var i = 0; i < 5; i += 1) {
            var wpi = firstWP + i;
            var wp = me.fp.getWP(wpi);
            var lsk = "L" ~ (i + 1);
            var rsk = "R" ~ (i + 1);
            if (wp == nil) {
                break;
            }
            else {
                if (wpi == 0) {
                    append(me.views, StaticView.new(0, y + 1, sprintf("%-6s", wp.wp_name),
                        mcdu_yellow | mcdu_large));
                }
                else if (wp.wp_type == "discontinuity") {
                    append(me.views, StaticView.new(0, y, ">> DISCONTINUITY <<",
                        mcdu_white));
                    append(me.views, StaticView.new(0, y + 1, "----",
                        mcdu_white | mcdu_large));
                }
                else {
                    var color = mcdu_yellow;
                    if (wpi != firstEntry) {
                        color = mcdu_green;
                        append(me.views, StaticView.new(1, y, sprintf("%3d°", wp.leg_bearing), mcdu_green));
                        var distFormat = (wp.leg_distance < 100) ? "%5.1fNM" : "%5.0fNM";
                        append(me.views, StaticView.new(6, y, sprintf(distFormat, wp.leg_distance), mcdu_green));
                        if (fms.performanceProfile != nil and wpi < size(fms.performanceProfile.estimated)) {
                            var eta = fms.performanceProfile.estimated[wpi].ta;
                            append(me.views, StaticView.new(8, y + 1, formatZulu(eta), mcdu_green));
                        }
                    }
                    append(me.views, StaticView.new(0, y + 1, sprintf("%-6s", wp.wp_name),
                        color | mcdu_large));
                    if (wp.fly_type == 'flyOver') {
                        append(me.views,
                            StaticView.new(
                                math.max(6, size(wp.wp_name)), y + 1,
                                "F", color | mcdu_large | mcdu_reverse));
                    }
                    else if (wp.fly_type == 'Hold') {
                        append(me.views,
                            StaticView.new(
                                math.max(6, size(wp.wp_name)), y + 1,
                                "H", color | mcdu_large | mcdu_reverse));
                    }
                }

                if (wp.wp_type != "discontinuity") {
                    append(me.views,
                        StaticView.new(
                            13, y + 1,
                            formatRestrictions(wp, transitionAlt, 1),
                            mcdu_cyan | mcdu_large));
                }

                if (me.specialMode == "FLYOVER") {
                    if (wp.wp_type != "discontinuity") {
                        var f = func (wp) {
                                    me.controllers[lsk] = FuncController.new(func(owner, val) {
                                        print("Activate FLYOVER on " ~ wp.id);
                                        owner.specialMode = nil;
                                        owner.startEditing();
                                        if (wp.fly_type == 'flyOver') {
                                            wp.fly_type = 'flyBy';
                                        }
                                        else {
                                            wp.fly_type = 'flyOver';
                                        }
                                        owner.fullRedraw();
                                    });
                                };
                        f(wp);
                    }
                }
                else if (me.specialMode == "HOLD") {
                    var this = me;
                    if (wp.wp_type != "discontinuity") {
                        (func (index) {
                            me.controllers[lsk] = FuncController.new(
                                func (owner, val) {
                                    var holdModule = func (mcdu, parent) {
                                        return HoldModule.new(mcdu, parent, index);
                                    };
                                    owner.mcdu.pushModule(holdModule);
                                    owner.selectedWP = nil;
                                    owner.mcdu.setScratchpad('');
                                });
                        })(wpi);
                    }
                }
                else if (wpi == firstEntry) {
                    var this = me;
                    me.controllers[lsk] = (func (wp, wpi) {
                        return FuncController.new(func(owner, val) {
                                    if (val != nil)
                                        owner.openDirectToModule(val, nil);
                                });
                    })(wp, wpi);
                }
                else {
                    var this = me;
                    me.controllers[lsk] = (func (wp, wpi) {
                        return FuncController.new(
                            func (owner, val) {
                                if (val == nil) {
                                    owner.selectedWP = { wp: wp, index: wpi };
                                    owner.mcdu.setScratchpad(wp.id);
                                }
                                else {
                                    owner.openDirectToModule(val, wpi);
                                }
                            },
                            func (owner) {
                                owner.startEditing();
                                owner.deleteWP(wpi);
                            }
                        );
                    })(wp, wpi);
                    PopController.new(wp.id);
                    me.controllers[rsk] = (func (wp) {
                        return FuncController.new(
                            func (owner, val) {
                                if (val == nil) {
                                    owner.selectedWP = nil;
                                    owner.mcdu.setScratchpad(formatRestrictions(wp, transitionAlt, 0));
                                }
                                else {
                                    var parsed = parseRestrictions(val);
                                    var wpi = owner.fp.indexOfWP(wp);
                                    if (parsed == nil) {
                                        owner.selectedWP = nil;
                                        owner.mcdu.setScratchpadMsg("INVALID", mcdu_yellow);
                                    }
                                    else {
                                        owner.startEditing();
                                        var wpx = owner.fp.getWP(wpi);
                                        if (wpx == nil) {
                                            owner.selectedWP = nil;
                                            owner.mcdu.setScratchpadMsg("NO WAYPOINT", mcdu_yellow);
                                        }
                                        else {
                                            if (parsed.speed != nil) {
                                                wpx.setSpeed(parsed.speed.val, parsed.speed.ty);
                                            }
                                            if (parsed.alt != nil) {
                                                wpx.setAltitude(parsed.alt.val, parsed.alt.ty);
                                            }
                                            owner.selectedWP = nil;
                                            owner.mcdu.setScratchpad('');
                                        }
                                    }
                                }
                            },
                            func (owner) {
                                var wpi = owner.fp.indexOfWP(wp);
                                owner.startEditing();
                                var wpx = owner.fp.getWP(wpi);
                                if (wpx == nil) {
                                    owner.selectedWP = nil;
                                    owner.mcdu.setScratchpadMsg("NO WAYPOINT", mcdu_yellow);
                                }
                                else {
                                    wpx.setSpeed(nil, '');
                                    wpx.setAltitude(nil, '');
                                }
                            });
                    })(wp);
                }
            }
            y += 2;
        }
        if (me.specialMode == "FLYOVER") {
            me.selectedWP = nil;
            me.mcdu.setScratchpadMsg("*FLYOVER*", mcdu_yellow);
        }
        elsif (me.specialMode == "HOLD") {
            me.selectedWP = nil;
            me.mcdu.setScratchpadMsg("*HOLD*", mcdu_yellow);
        }
        if (me.fpStatus == 'ACT') {
            me.appendR6Item();
        }
        else {
            append(me.views,
                StaticView.new(0, 12, left_triangle ~ "CANCEL", mcdu_white | mcdu_large));
            me.controllers["L6"] = FuncController.new(func (owner, val) {
                owner.cancelEditing();
            });
            append(me.views,
                StaticView.new(15, 12, "ACTIVATE" ~ right_triangle, mcdu_white | mcdu_large));
            me.controllers["R6"] = FuncController.new(func (owner, val) {
                owner.finishEditing();
            });
        }
    },

    appendR6Item: func () {
        var label = "";
        var key = nil;

        if (getprop("/cpdlc/unread")) {
            label = "ATC UPLINK";
            key = "CPDLC-NEWEST-UPLINK";
        }
        elsif (getprop("/acars/telex/newest-unread") != 0) {
            label = "DLK MSG";
            key = "ACARS-NEWEST-UNREAD";
        }
        elsif (!getprop("/fms/performance-initialized")) {
            label = "PERF INIT";
            key = "PERFINIT";
        }
        elsif (fms.vnav.desNowAvailable) {
            label = "DES NOW";
            key = FuncController.new(func (owner, val) {
                if (!vnav.desNow()) {
                    owner.mcdu.setScratchpadMsg("NO DES NOW");
                }
            });
        }
        elsif (me.fp.departure_runway == nil or me.fp.sid == nil) {
            label = "DEPARTURE";
            key = "DEPARTURE";
        }
        else {
            label = "ARRIVAL";
            key = "ARRIVAL";
        }

        append(me.views,
            StaticView.new(12, 12, sprintf("%11s", label) ~ right_triangle, mcdu_white | mcdu_large));
        if (key == nil) {
            # do nothing
        }
        if (typeof(key) == 'scalar') {
            me.controllers["R6"] = SubmodeController.new(key);
        }
        else {
            # assume it's a controller
            me.controllers["R6"] = key;
        }
    },

};

var HoldModule = {
    new: func (mcdu, parentModule, holdFixIndex) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(HoldModule, m.parents);
        m.holdFixIndex = holdFixIndex;
        m.holdFix = m.parentModule.fp.getWP(m.holdFixIndex);
        m.holdParams = {
            hold_heading_radial_deg: math.round(m.holdFix.leg_bearing),
            hold_is_left_handed: 0,
            hold_is_distance: 0,
            hold_distance: 0,
            hold_time: 90,
            speed_cstr: 230,
        };
        if (m.holdFix.speed_cstr) {
            m.holdParams.speed_cstr = m.holdFix.speed_cstr;
        }
        if (m.holdFix.fly_type == 'Hold') {
            m.holdParams.hold_heading_radial_deg = m.holdFix.hold_heading_radial_deg;
            m.holdParams.hold_is_left_handed = m.holdFix.hold_is_left_handed;
            m.holdParams.hold_is_distance = m.holdFix.hold_is_distance;
            if (m.holdParams.hold_is_distance) {
                m.holdParams.hold_distance = m.holdFix.hold_time_or_distance;
            }
            else {
                m.holdParams.hold_time = m.holdFix.hold_time_or_distance;
            }
        }
        m.setHoldSpeed(m.holdParams.speed_cstr);
        # debug.dump(m.holdFix);
        return m;
    },

    setHoldTime: func (t) {
        me.holdParams.hold_is_distance = 0;
        me.holdParams.hold_time = t;
        me.holdParams.hold_distance = me.holdParams.speed_cstr * t / 3600;
    },

    setHoldDistance: func (d) {
        me.holdParams.hold_is_distance = 1;
        me.holdParams.hold_distance = d;
        me.holdParams.hold_time = d / me.holdParams.speed_cstr * 3600;
    },

    setHoldSpeed: func (s) {
        me.holdParams.speed_cstr = s;
        if (me.holdParams.hold_is_distance) {
            me.holdParams.hold_time = me.holdParams.hold_distance / me.holdParams.speed_cstr * 3600;
        }
        else {
            me.holdParams.hold_distance = me.holdParams.speed_cstr * me.holdParams.hold_time / 3600;
        }
    },

    apply: func () {
        me.parentModule.startEditing();
        me.holdFix = me.parentModule.fp.getWP(me.holdFixIndex);
        me.holdFix.hold_count = 999;
        me.holdFix.hold_is_left_handed = me.holdParams.hold_is_left_handed;
        if (me.holdParams.hold_is_distance)
            me.holdFix.setHoldDistance(me.holdParams.hold_distance);
        else
            me.holdFix.setHoldTime(me.holdParams.hold_time);
        me.holdFix.setSpeed(me.holdParams.speed_cstr, 'at');
        me.holdFix.hold_heading_radial_deg = me.holdParams.hold_heading_radial_deg;
    },

    clear: func () {
        me.parentModule.startEditing();
        me.holdFix = me.parentModule.fp.getWP(me.holdFixIndex);
        me.holdFix.hold_count = nil;
        me.holdFix.fly_type = 'flyBy';
        me.holdFix.wp_type = 'basic';
    },

    getNumPages: func () { return 1; },
    getTitle: func () { return "HOLDING PATTERN"; },

    loadPageItems: func (p) {
        var self = me;

        me.views = [
            StaticView.new(2, 1, "HOLD FIX", mcdu_white),
            StaticView.new(1, 2, me.holdFix.wp_name, mcdu_green | mcdu_large),

            StaticView.new(-2, 1, "SPEED", mcdu_white),
            FormatView.new(21, 2, mcdu_cyan | mcdu_large,
                ObjectFieldModel.new("HOLD-SPEED", me.holdParams, 'speed_cstr'),
                3, "%3.0f"),

            StaticView.new(2, 3, "QUAD ENTRY", mcdu_white),

            FormatView.new(15, 3, mcdu_white,
                ObjectFieldModel.new("HOLD-IS-DIST", me.holdParams, 'hold_is_distance'),
                8, "%8s", func(is_dist) { return (is_dist ? "EST TIME" : "LEG TIME"); }),
            FormatView.new(18, 4,
                func(val) { (self.holdParams.hold_is_distance ? mcdu_cyan : (mcdu_green | mcdu_large)) },
                ObjectFieldModel.new("HOLD-TIME", me.holdParams, 'hold_time'),
                6, "%3.1fMIN", func(t) { return t / 60; }),

            StaticView.new(2, 5, "INBD CRS/DIR", mcdu_white),
            FormatView.new(1, 6, mcdu_green | mcdu_large,
                ObjectFieldModel.new("HOLD-RADIAL", me.holdParams, 'hold_heading_radial_deg'),
                3, "%3.0f°"),
            StaticView.new(5, 6, "/", mcdu_green | mcdu_large),
            FormatView.new(6, 6, mcdu_green | mcdu_large,
                ObjectFieldModel.new("HOLD-DIR", me.holdParams, 'hold_is_left_handed'),
                3, "%6s", ["R TURN", "L TURN"]),

            FormatView.new(15, 5, mcdu_white,
                ObjectFieldModel.new("HOLD-IS-DIST", me.holdParams, 'hold_is_distance'),
                8, "%8s", func(is_dist) { return (is_dist ? "LEG DIST" : "EST DIST"); }),
            FormatView.new(19, 6,
                func(val) { (self.holdParams.hold_is_distance ? (mcdu_green | mcdu_large) : mcdu_cyan) },
                ObjectFieldModel.new("HOLD-DIST", me.holdParams, 'hold_distance'),
                5, "%3.1fNM"),

            StaticView.new(-2, 7, "EFC TIME", mcdu_white),

            StaticView.new(0, 12, left_triangle ~ "CLEAR", mcdu_white | mcdu_large),
            StaticView.new(-1, 12, "INSERT" ~ right_triangle, mcdu_white | mcdu_large),
        ];

        me.controllers = {
            'R1': FuncController.new(
                    func (owner, val) {
                        if (val == nil) {
                            return owner.holdParams.speed_cstr;
                        }
                        else {
                            val = math.max(100, num(val));
                            owner.setHoldSpeed(val);
                            owner.redraw();
                            return val;
                        }
                    },
                    func (owner) {
                        owner.setHoldSpeed(230);
                        owner.redraw();
                        return val;
                    }
                  ),
            'R2': FuncController.new(
                    func (owner, val) {
                        if (val == nil) {
                            return owner.holdParams.hold_time / 60;
                        }
                        else {
                            val = math.max(30, num(val) * 60);
                            owner.setHoldTime(val);
                            owner.redraw();
                            return val;
                        }
                    },
                    func (owner) {
                        owner.setHoldTime(90);
                        owner.redraw();
                        return val;
                    }
                  ),
            'L3': FuncController.new(
                    func (owner, val) {
                        if (val != nil) {
                            var parts = split('/', val);
                            if (size(parts) != 2) return nil;
                            if (parts[0] != '') {
                                owner.holdParams.hold_heading_radial_deg = geo.normdeg(num(parts[0]));
                            }
                            if (parts[1] == 'L') {
                                owner.holdParams.hold_is_left_handed = 1;
                            }
                            elsif (parts[1] == 'R') {
                                owner.holdParams.hold_is_left_handed = 0;
                            }
                        }
                        owner.redraw();
                        return sprintf('%0.0f/%s',
                            owner.holdParams.hold_heading_radial_deg,
                            owner.holdParams.hold_is_left_handed ? 'L' : 'R');
                    }),
            'R3': FuncController.new(
                    func (owner, val) {
                        if (val == nil) {
                            return owner.holdParams.hold_distance;
                        }
                        else {
                            val = math.max(1, num(val));
                            owner.setHoldDistance(val);
                            owner.redraw();
                            return val;
                        }
                    },
                    func (owner) {
                        owner.setHoldDistance(4);
                        owner.redraw();
                        return val;
                    }
                  ),
            'L6': FuncController.new(
                    func (owner, val) {
                        owner.clear();
                        owner.mcdu.gotoModule('FPL');
                    }
                  ),
            'R6': FuncController.new(
                    func(owner, val) {
                        owner.apply();
                        owner.mcdu.gotoModule('FPL');
                    }
                  ),
        };
    },
};


