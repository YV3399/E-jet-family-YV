# -------------- MODULES -------------- 

var BaseModule = {
    new: func (mcdu, parentModule) {
        var m = { parents: [BaseModule] };
        m.page = 0;
        m.parentModule = parentModule;
        var maxw = math.round(cells_x / 2) - 1;
        m.ptitle = nil;
        if (parentModule != nil) {
            m.ptitle = sprintf("%s %d/%d",
                parentModule.getTitle(),
                parentModule.page + 1,
                parentModule.getNumPages());
        }
        if (m.ptitle != nil and size(m.ptitle) > maxw) {
            m.ptitle = parentModule.getTitle();
        }
        if (m.ptitle != nil and size(m.ptitle) > maxw) {
            m.ptitle = substr(m.ptitle, 0, maxw);
        }
        m.mcdu = mcdu;

        m.views = [];
        m.controllers = {};
        m.dividers = [];
        m.boxedController = nil;
        m.boxedView = nil;

        return m;
    },

    getNumPages: func () {
        return 1;
    },

    getTitle: func() {
        return "MODULE";
    },

    loadPage: func (n) {
        me.loadPageItems(n);
        foreach (var view; me.views) {
            view.activate(me.mcdu);
        }
    },

    unloadPage: func () {
        me.boxedView = nil;
        me.boxedController = nil;
        foreach (var view; me.views) {
            view.deactivate();
        }
        me.views = [];
        me.controllers = {};
    },

    loadPageItems: func (n) {
        # Override to load the views and controllers and dividers for the current page
    },

    findView: func (key) {
        if (key == nil) {
            return nil;
        }
        foreach (var view; me.views) {
            if (view.getKey() == key) {
                return view;
            }
        }
        return nil;
    },

    findController: func (key) {
        if (key == nil) {
            return nil;
        }
        foreach (var i; keys(me.controllers)) {
            var controller = me.controllers[i];
            if (controller != nil and controller.getKey() == key) {
                return controller;
            }
        }
        return nil;
    },

    drawFocusBox: func () {
        if (me.boxedView == nil) {
            me.mcdu.clearFocusBox();
        }
        else {
            me.mcdu.setFocusBox(
                me.boxedView.getL(),
                me.boxedView.getT(),
                me.boxedView.getW());
        }
    },

    drawPager: func () {
        me.mcdu.print(21, 0, sprintf("%1d/%1d", me.page + 1, me.getNumPages()), 0);
    },

    drawTitle: func () {
        var title = me.getTitle();
        var x = math.floor((cells_x - 3 - size(title)) / 2);
        me.mcdu.print(x, 0, title, mcdu_large | mcdu_white);
    },

    redraw: func () {
        foreach (var view; me.views) {
            view.drawAuto(me.mcdu);
        }
        var dividers = me.dividers;
        if (dividers == nil) { dividers = [] };
        for (var d = 0; d < 7; d += 1) {
            if (vecfind(d, dividers) == -1) {
                me.mcdu.hideDivider(d);
            }
            else {
                me.mcdu.showDivider(d);
            }
        }
        me.drawFocusBox();
    },


    fullRedraw: func () {
        me.mcdu.clear();
        me.drawTitle();
        me.drawPager();
        me.redraw();
    },

    gotoPage: func (p) {
        me.unloadPage();
        me.page = math.min(me.getNumPages() - 1, math.max(0, p));
        me.loadPage(me.page);
        me.fullRedraw();
    },

    nextPage: func () {
        if (me.page < me.getNumPages() - 1) {
            me.unloadPage();
            me.page += 1;
            me.loadPage(me.page);
            me.fullRedraw();
        }
    },

    prevPage: func () {
        if (me.page > 0) {
            me.unloadPage();
            me.page -= 1;
            me.loadPage(me.page);
            me.selectedKey = nil;
            me.fullRedraw();
        }
    },

    push: func (target) {
        me.mcdu.pushModule(target);
    },

    goto: func (target) {
        me.mcdu.gotoModule(target);
    },

    sidestep: func (target) {
        me.mcdu.sidestepModule(target);
    },

    ret: func () {
        me.mcdu.popModule();
    },

    activate: func () {
        me.loadPage(me.page);
    },

    deactivate: func () {
        me.unloadPage();
    },

    box: func (key) {
        me.boxedController = me.findController(key);
        me.boxedView = me.findView(key);
        me.drawFocusBox();
    },

    handleCommand: func (cmd) {
        var controller = me.controllers[cmd];
        if (isLSK(cmd)) {
            var scratch = me.mcdu.popScratchpad();
            if (controller == nil) {
                me.mcdu.setScratchpad(scratch);
            }
            else {
                var boxed = (me.boxedController != nil and
                             me.boxedController.getKey() == controller.getKey());
                if (scratch == '') {
                    controller.select(me, boxed);
                }
                else if (scratch == '*DELETE*') {
                    controller.delete(me, boxed);
                }
                else {
                    controller.send(me, scratch);
                }
            }
        }
        else if (isDial(cmd)) {
            var digit = dialIndex(cmd);
            if (me.boxedController != nil) {
                me.boxedController.dial(me, digit);
            }
        }
    },

};

var PlaceholderModule = {
    new: func (mcdu, parentModule, name) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(PlaceholderModule, m.parents);
        m.name = name;
        return m;
    },

    getNumPages: func () { return 1; },
    getTitle: func () { return me.name; },

    loadPageItems: func (p) {
        me.views = [
            StaticView.new(1, 6, "MODULE NOT IMPLEMENTED", mcdu_red | mcdu_large),
        ];
        me.controllers = {};
        if (me.ptitle != nil) {
            me.controllers["R6"] = SubmodeController.new("ret");
            append(me.views,
                 StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
        }
    },
};

var RouteModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(RouteModule, m.parents);
        if (fms.modifiedRoute != nil) {
            m.route = fms.modifiedRoute;
            m.routeStatus = 'MOD';
        }
        else {
            m.route = fms.getActiveRoute();
            m.routeStatus = 'ACT';
        }
        m.timer = nil;
        return m;
    },

    startEditing: func () {
        if (me.routeStatus == 'ACT') {
            me.route = fms.getModifyableRoute();
            me.routeStatus = 'MOD';
        }
    },

    finishEditing: func () {
        if (me.routeStatus != 'ACT') {
            me.route = fms.commitRoute();
            me.routeStatus = 'ACT';
        }
    },

    cancelEditing: func () {
        if (me.routeStatus != 'ACT') {
            me.route = fms.discardRoute();
            me.routeStatus = 'ACT';
        }
    },

    getNumPages: func () {
        var legs = me.route.legs;
        var numEntries = size(legs);
        # one extra page at the beginning, one extra entry for the
        # destination.
        return math.max(1, math.ceil((numEntries + 1) / 5)) + 1;
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
    },

    getTitle: func () {
        return me.routeStatus ~ " RTE";
    },

    deleteLeg: func (deleteIndex) {
        me.startEditing();
        me.route.deleteLeg(deleteIndex);
        fms.updateModifiedFlightplanFromRoute();
    },

    appendViaTo: func (viaTo, appendIndex = nil) {
        # printf("Append VIA-TO: %s", viaTo);
        var s = split('.', viaTo);
        # debug.dump(s);
        var newWaypoints = [];
        var targetFix = nil;
        # printf("Append after: %i (%s)", appendIndex, (refWP == nil) ? "<nil>" : refWP.id);

        if (size(s) == 0) {
            return 'INVALID';
        }

        # No route entered yet? Let's first check if the first element is a
        # SID.
        if (size(me.route.legs) == 0 and me.route.departureAirport != nil) {
            var sid = me.route.departureAirport.getSid(s[0]);
            if (typeof(sid) == 'ghost') {
                me.route.sid = sid;
                s = subvec(s, 1);
            }
        }

        var result = 'INVALID';
        while (size(s) > 0) {
            # If this is the last bit, and ends at the destination airport,
            # then try for a STAR

            if (size(s) == 2 and
                me.route.destinationAirport != nil and
                s[1] == me.route.destinationAirport.id) {
                var star = me.route.destinationAirport.getStar(s[0]);
                if (typeof(star) == 'ghost') {
                    me.route.star = star;
                    me.route.closed = 1;
                    result = 'OK';
                    break;
                }
            }

            # Attempt to interpret as airway.fix....
            if (size(s) > 1) {
                result = me.route.appendLeg(s[0], s[1]);
                if (result == 'OK') {
                    s = subvec(s, 2);
                    continue;
                }
            }

            # If that doesn't work, interpret as fix....
            result = me.route.appendLeg(nil, s[0]);
            if (result == 'OK') {
                s = subvec(s, 1);
                continue;
            }

            break;
        }

        if (result == 'OK') {
            me.startEditing();
            fms.updateModifiedFlightplanFromRoute();
        }
        else {
            me.mcdu.setScratchpadMsg(result, mcdu_yellow);
        }
    },

    loadPageItems: func (p) {
        var departureModel = makeAirportModel(me, "DEPARTURE-AIRPORT");
        var destinationModel = makeAirportModel(me, "DESTINATION-AIRPORT");

        if (p == 0) {
            me.views = [
                StaticView.new(1, 1, "ORIGIN/ETD", mcdu_white),
                FormatView.new(1, 2, mcdu_green | mcdu_large, departureModel, 4),
                StaticView.new(cells_x - 5, 1, "DEST", mcdu_white),
                FormatView.new(cells_x - 5, 2, mcdu_green | mcdu_large, destinationModel, 4),
                StaticView.new(1, 3, "RUNWAY", mcdu_white),
                StaticView.new(cells_x - 9, 3, "CO ROUTE", mcdu_white),
                StaticView.new(1, 5, "FPL REQST", mcdu_white),
                StaticView.new(cells_x - 11, 5, "FPL REPORT", mcdu_white),
                StaticView.new(1, 6, "DATA LINK UNAVAILABLE", mcdu_white | mcdu_large),
                StaticView.new(1, 7, "CALL SIGN", mcdu_white),
                StaticView.new(cells_x - 10, 7, "FLIGHT ID", mcdu_white),
                FormatView.new(1, 8, mcdu_green | mcdu_large, "CALLSIG", 6),
                FormatView.new(12, 8, mcdu_green | mcdu_large, "FLTID", 11),
            ];

            me.controllers = {
                "L1": ModelController.new(departureModel),
                "R1": ModelController.new(destinationModel),
                "L5": ModelController.new("CALLSIG"),
                "R5": ModelController.new("FLTID"),
            };
        }
        else {
            me.views = [];
            me.controllers = {};
            append(me.views, StaticView.new(1, 1, "VIA", mcdu_white));
            append(me.views, StaticView.new(21, 1, "TO", mcdu_white));
            var y = 2;
            var firstEntry = (p - 1) * 5;
            for (var i = 0; i < 5; i += 1) {
                var j = firstEntry + i;
                var lsk = sprintf("R%i", i + 1);
                var leg = (j < size(me.route.legs)) ? me.route.legs[j] : nil;
                if (leg == nil) {
                    if (!me.route.isClosed()) {
                        append(me.views, StaticView.new(0, y, "-----", mcdu_green | mcdu_large));
                        me.controllers[lsk] =
                            FuncController.new(func (owner, val) { owner.appendViaTo(val); });
                    }
                    break;
                }
                else {
                    append(me.views, StaticView.new(0, y, leg.airwayID, mcdu_green | mcdu_large));
                    append(me.views, StaticView.new(16, y, leg.toID, mcdu_green | mcdu_large));
                    if (j == size(me.route.legs) - 1) {
                        me.controllers[lsk] =
                            (func (i) {
                                return FuncController.new(
                                    func (owner, val) {
                                        # printf("Append before WP %i", j);
                                        owner.setScratchpadMsg("NOT ALLOWED", mcdu_yellow);
                                    },
                                    func (owner) {
                                        # printf("Delete WP %i", j);
                                        owner.startEditing();
                                        owner.deleteLeg(i);
                                    });
                            })(j);
                    }
                }
                y += 2;
            }
        }
        if (me.routeStatus != 'ACT') {
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

};

var FlightPlanModule = {
    new: func (mcdu, parentModule, specialMode=nil) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(FlightPlanModule, m.parents);
        m.specialMode = specialMode;
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
    },

    getTitle: func () {
        return me.fpStatus ~ " FLT PLAN";
    },

    deleteWP: func (wpi) {
        if (wpi > 0) {
            me.fp.deleteWP(wpi);
            fms.kickRouteManager();
        }
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
                    else if (wp.fly_type == 'hold') {
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
                    if (wp.wp_type != "discontinuity") {
                        # TODO
                        me.mcdu.setScratchpadMsg("NOT IMPLEMENTED", mcdu_red);
                    }
                }
                else if (wpi == firstEntry) {
                    var this = me;
                    me.controllers[lsk] = FuncController.new(func(owner, val) {
                        owner.startEditing();
                        var directToModule = func (mcdu, parent) {
                            return DirectToModule.new(mcdu, parent, this.fp, val);
                        };
                        owner.mcdu.pushModule(directToModule);
                        me.mcdu.setScratchpad('');
                    });
                }
                else {
                    var this = me;
                    me.controllers[lsk] = (func (wp, directFromIndex) {
                        return FuncController.new(
                            func (owner, val) {
                                if (val == nil) {
                                    owner.mcdu.setScratchpad(wp.id);
                                }
                                else {
                                    owner.startEditing();
                                    var directToModule = func (mcdu, parent) {
                                        return DirectToModule.new(mcdu, parent, this.fp, val, directFromIndex);
                                    };
                                    owner.mcdu.pushModule(directToModule);
                                    me.mcdu.setScratchpad('');
                                }
                            },
                            func (owner) {
                                var wpi = owner.fp.indexOfWP(wp);
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
                                    owner.mcdu.setScratchpad(formatRestrictions(wp, transitionAlt, 0));
                                }
                                else {
                                    var parsed = parseRestrictions(val);
                                    var wpi = owner.fp.indexOfWP(wp);
                                    if (parsed == nil) {
                                        owner.mcdu.setScratchpadMsg("INVALID", mcdu_yellow);
                                    }
                                    else {
                                        owner.startEditing();
                                        var wpx = owner.fp.getWP(wpi);
                                        if (wpx == nil) {
                                            owner.mcdu.setScratchpadMsg("NO WAYPOINT", mcdu_yellow);
                                        }
                                        else {
                                            if (parsed.speed != nil) {
                                                wpx.setSpeed(parsed.speed.val, parsed.speed.ty);
                                            }
                                            if (parsed.alt != nil) {
                                                wpx.setAltitude(parsed.alt.val, parsed.alt.ty);
                                            }
                                            me.mcdu.setScratchpad('');
                                        }
                                    }
                                }
                            },
                            func (owner) {
                                var wpi = owner.fp.indexOfWP(wp);
                                owner.startEditing();
                                var wpx = owner.fp.getWP(wpi);
                                if (wpx == nil) {
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
            me.mcdu.setScratchpadMsg("*FLYOVER*", mcdu_yellow);
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

        if (!getprop("/fms/performance-initialized")) {
            label = "PERF INIT";
            key = "PERFINIT";
        }
        else if (fms.vnav.desNowAvailable) {
            label = "DES NOW";
            key = FuncController.new(func (owner, val) {
                if (!vnav.desNow()) {
                    owner.mcdu.setScratchpadMsg("NO DES NOW");
                }
            });
        }
        else if (me.fp.departure_runway == nil or me.fp.sid == nil) {
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

var DirectToModule = {
    new: func (mcdu, parentModule, fp, directToID, directFromIndex=nil) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(DirectToModule, m.parents);
        m.fp = fp;
        m.directToID = directToID;
        m.directToIndex = nil;
        m.directFromIndex = directFromIndex;
        var wp = nil;
        var fst = math.max(1, fp.current);
        for (var i = fst; i < fp.getPlanSize(); i += 1) {
            wp = fp.getWP(i);
            if (wp.id == directToID) {
                m.directToWP = wp;
                m.directToIndex = i;
                break;
            }
        }
        return m;
    },

    getNumPages: func () { return 1; },
    getTitle: func () { return "DIRECT-TO"; },

    loadPageItems: func (p) {
        me.views = [];
        append(me.views, StaticView.new(0, 2, left_triangle ~ "DIRECT", mcdu_large | mcdu_white));
        if (me.directToIndex != nil) {
            append(me.views, StaticView.new(0, 4, left_triangle ~ "ACTIVE", mcdu_large | mcdu_white));
            append(me.views, StaticView.new(0, 6, left_triangle ~ "MISSED APPROACH", mcdu_large | mcdu_white));
        }
        # NOT IMPLEMENTED YET
        # StaticView.new(0, 8, left_triangle ~ "ALTERNATE", mcdu_large | mcdu_white),


        me.controllers = {
            "L1": FuncController.new(func (owner, val) { owner.insertDirect(); owner.mcdu.popModule(); }),
            "L2": FuncController.new(func (owner, val) { owner.insertActive(); owner.mcdu.popModule(); }),
            "L3": FuncController.new(func (owner, val) { owner.insertActive(); owner.mcdu.popModule(); }),
            # TODO: Alternate flight plan
            # "L4": FuncController.new(func (owner, val) { owner.insertAlternate(); owner.mcdu.popModule(); }),
        };
    },

    insertActive: func () {
        var directWP = createWP(geo.aircraft_position(), "DIRECT");
        me.fp.insertWP(directWP, me.directToIndex);
        for (var i = 0; i < me.directToIndex; i += 1) {
            me.fp.deleteWP(0);
        }
        me.fp.getWP(0).setAltitude(getprop("/instrumentation/altimeter/indicated-altitude-ft"), 'at');
        me.fp.current = 1;
        fms.kickRouteManager();
    },

    insertDirect: func () {
        var candidates = parseWaypoint(me.directToID);
        # debug.dump(me.directFromIndex, me.directToID, candidates);
        if (size(candidates) > 0) {
            var newWP = candidates[0];
            var index = 1;
            if (me.directFromIndex == nil) {
                # max(1, ...) needed in order to avoid inserting the DIRECT before
                # the departure waypoint
                index = math.max(1, me.fp.current);
                var directWP = createWP(geo.aircraft_position(), "DIRECT");
                me.fp.insertWP(directWP, index);
            }
            else {
                index = me.directFromIndex + 1;
                me.fp.insertWP(createDiscontinuity(), index);
            }
            me.fp.insertWP(newWP, index + 1);
            me.fp.insertWP(createDiscontinuity(), index + 2);
            if (me.directFromIndex == nil) {
                # if the direct-from index isn't given, then we're going direct
                # from wherever we are right now; otherwise, it's a route
                # amendment that's just sandwiched between two disconts.
                me.fp.current = index + 1;
            }
            fms.kickRouteManager();
        }
        else {
            me.mcdu.setScratchpadMsg("NO WAYPOINT", mcdu_yellow);
        }
    },
};

var PerfInitModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(PerfInitModule, m.parents);
        return m;
    },

    getNumPages: func () { return 3; },
    getTitle: func () {
        return "PERFORMANCE INIT-KG";
    },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(1, 1, "ACFT TYPE", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_green, "ACMODEL", 11, "%-11s"),
                StaticView.new(17, 1, "TAIL #", mcdu_white),
                FormatView.new(12, 2, mcdu_large | mcdu_green, "TAIL", 11, "%11s"),

                StaticView.new(1, 3, "PERF MODE", mcdu_white),
                CycleView.new(0, 4, mcdu_large | mcdu_green, "PERF-MODE",
                    [1, 2, 0], ["FULL PERF", "CURRENT GS/FF", "PILOT SPD/FF"], 1),
                StaticView.new(1, 5, "CLIMB", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_green, "VCLB", 3, "%3.0f/"),
                FormatView.new(4, 6, mcdu_large | mcdu_green, "MCLB", 3, "%3.2fM"),
                StaticView.new(1, 7, "CRUISE", mcdu_white),
                CycleView.new(0, 8, mcdu_large | mcdu_green, "CRZ-MODE",
                    [0, 1, 2, 3], ["LRC", "MAX SPD", "MAX END", "MXR SPD"], 1),
                StaticView.new(1, 9, "DESCENT", mcdu_white),
                FormatView.new(0, 10, mcdu_large | mcdu_green, "VDES", 3, "%3.0f/"),
                FormatView.new(4, 10, mcdu_large | mcdu_green, "MDES", 3, "%3.2fM/"),
                FormatView.new(10, 10, mcdu_large | mcdu_green, "DES-FPA", 3, "%3.1f"),

                StaticView.new(0, 12, left_triangle ~ "DEP/APP SPD", mcdu_large | mcdu_white),
            ];

            me.controllers = {
                "R2": CycleController.new("PERF-MODE", [1, 2, 0]),
                "L3": MultiModelController.new(["VCLB", "MCLB"]),
                "R4": CycleController.new("CRZ-MODE", [0, 1, 2, 3]),
                "L5": MultiModelController.new(["VDES", "MDES", "DES-FPA"]),
                # "L6": SubmodeController.new("DEP-APP-SPD"),
            };
        }
        else if (n == 1) {
            me.views = [
                StaticView.new(1, 1, "STEP INCREMENT", mcdu_white),
                StaticView.new(1, 2, "4000", mcdu_large | mcdu_white),

                StaticView.new(1, 3, "FUEL RESERVE", mcdu_white),
                FormatView.new(0, 4, mcdu_large | mcdu_green, "FUEL-RESERVE", 3, "%3.0f KG"),
                StaticView.new(1, 5, "TO/LDG FUEL", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_green, "FUEL-TAKEOFF", 3, "%3.0f/"),
                FormatView.new(4, 6, mcdu_large | mcdu_green, "FUEL-LANDING", 3, "%1.0f KG"),
                StaticView.new(1, 7, "CONTINGENCY FUEL", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "FUEL-CONTINGENCY", 3, "%3.0f KG"),
            ];

            me.controllers = {
                "L2": ModelController.new("FUEL-RESERVE"),
                "L3": MultiModelController.new(["FUEL-TAKEOFF", "FUEL-LANDING"]),
                "L4": ModelController.new("FUEL-CONTINGENCY"),
            };
        }
        else if (n == 2) {
            me.views = [
                StaticView.new(1, 1, "TRANS ALT", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_green, "TRANSALT", 5, "%5.0f"),
                StaticView.new(12, 1, "SPD/ALT LIM", mcdu_white),
                FormatView.new(15, 2, mcdu_large | mcdu_green, "VCLBLO", 3, "%3.0f/"),
                FormatView.new(19, 2, mcdu_large | mcdu_green, "CLBLOALT", 3, "%5.0f"),
                StaticView.new(1, 3, "INIT CRZ ALT", mcdu_white),
                FormatView.new(0, 4, mcdu_large | mcdu_green, "CRZ-ALT",
                    5, "FL%03.0f", func(val) { return val / 100; }),
                StaticView.new(16, 3, "ISA DEV", mcdu_white),
                StaticView.new(20, 4, "+0°C", mcdu_large | mcdu_white),
                StaticView.new(1, 5, "CRZ WINDS", mcdu_white),
                StaticView.new(12, 5, "AT ALTITUDE", mcdu_white),
                StaticView.new(1, 7, "ZFW", mcdu_white),
                StaticView.new(11, 7, "(GAUGE) FUEL", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "WGT-ZF", 5, "%5.0f"),
                FormatView.new(11, 8, mcdu_green, "FUEL-CUR", 7, "(%1.0f)"),
                FormatView.new(19, 8, mcdu_large | mcdu_green, "FUEL-CUR", 5, "%5.0f"),
                StaticView.new(15, 9, "GROSS WT", mcdu_white),
                FormatView.new(19, 10, mcdu_large | mcdu_green, "WGT-CUR", 5, "%5.0f", func (lbs) { return lbs * LB2KG; }),

                StaticView.new(0, 12, left_triangle ~ "DEP/APP", mcdu_large | mcdu_white),
                StaticView.new(11, 12, "CONFIRM INIT" ~ right_triangle, mcdu_large | mcdu_white),
            ];

            me.controllers = {
                "L1": ModelController.new("TRANSALT"),
                "L2": ModelController.new("CRZ-ALT", func (val) {
                    if (val < 1000) {
                        return val * 100;
                    }
                    else {
                        return val;
                    }
                }),
                "R6": FuncController.new(func (owner, val) {
                    setprop("/fms/performance-initialized", 1);
                    owner.mcdu.sidestepModule("PERFDATA");
                }),
            };
        }
    },
};

var TakeoffPerfModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(TakeoffPerfModule, m.parents);
        return m;
    },

    getNumPages: func () { return 3; },
    getTitle: func () { return "TAKEOFF"; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(1, 1, "RWY HDG", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_green, "TO-RUNWAY-HEADING", 3, "%03.0f"),

                StaticView.new(cells_x - 9, 1, "T.O. WGT", mcdu_white),
                FormatView.new(14, 2, mcdu_large | mcdu_green, "WGT-TO", 8, "%6.0f KG"),

                StaticView.new(1, 3, "OAT<---SURFACE--->WIND", mcdu_white),
                TemperatureView.new(0, 4, mcdu_large | mcdu_green, "TO-OAT"),
                FormatView.new(17, 4, mcdu_large | mcdu_green, "TO-WIND-DIR", 4, "%03.0f°/"),
                FormatView.new(22, 4, mcdu_large | mcdu_green, "TO-WIND-SPEED", 2, "%02.0f"),

                StaticView.new(1, 5, "P ALT/B SET       ELEV", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_white, "TO-PRESSURE-ALT", 5, "%4.0f/"),
                FormatView.new(5, 6, mcdu_large | mcdu_green, "TO-QNH", 5, "%4.0f"),
                FormatView.new(20, 6, mcdu_large | mcdu_green, "TO-RUNWAY-ELEVATION", 5, "%4.0f"),

                StaticView.new(1, 7, "RWY SLOPE         WIND", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_white, "TO-RUNWAY-SLOPE", 5, "%+3.1f°"),

                StaticView.new(1, 9, "RWY CONDITION", mcdu_white),
                CycleView.new(0, 10, mcdu_large | mcdu_green, "TO-RUNWAY-CONDITION",
                    [0, 1, 2, 3], ['DRY', 'WET', 'SNOW', 'ICE'], 1),

                StaticView.new(0, 12, left_triangle ~ "PERF DATA", mcdu_white | mcdu_large),
                StaticView.new(14, 12, "T.O. DATA" ~ right_triangle, mcdu_white | mcdu_large),
            ];
            me.controllers = {
                "L1": ValueController.new("TO-RUNWAY-HEADING"),
                "L2": ValueController.new("TO-OAT"),
                "L3": ValueController.new("TO-QNH"),
                "L4": ValueController.new("TO-RUNWAY-SLOPE"),
                "R1": ValueController.new("WGT-TO"),
                "R2": MultiModelController.new(["TO-WIND-DIR", "TO-WIND-SPEED"]),
                "R3": ValueController.new("TO-RUNWAY-ELEVATION"),
                "R5": CycleController.new("TO-RUNWAY-CONDITION", [0, 1, 2, 3]),
            };
        }
        else if (n == 1) {
            me.views = [
                StaticView.new(1, 1, "FLAPS", mcdu_white),
                CycleView.new(0, 2, mcdu_large | mcdu_green, "TO-FLAPS",
                    [0.125, 0.250, 0.375, 0.500],
                    { 0: "CLEAN", 0.125: "FLAP-1", 0.250: "FLAP-2", 0.375: "FLAP-3", 0.500: "FLAP-4" }, 1),
                StaticView.new(1, 3, "MODE", mcdu_white),
                CycleView.new(0, 4, mcdu_large | mcdu_green, "TO-TRS-MODE",
                    [1, 2, 3], ['----', 'TO-1', 'TO-2', 'TO-3']),
            ];
            me.controllers = {
                "R1": CycleController.new("TO-FLAPS", [0.125, 0.250, 0.375, 0.500]),
                "R2": CycleController.new("TO-TRS-MODE", [1,2,3]),
            };
        }
        else if (n == 2) {
            fms.update_departure_vspeeds();
            me.views = [
                StaticView.new(1, 1, "V1", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_magenta, "DEP-EFF-V1", 3),
                StaticView.new(1, 3, "VR", mcdu_white),
                FormatView.new(0, 4, mcdu_large | mcdu_cyan, "DEP-EFF-VR", 3),
                StaticView.new(1, 5, "V2", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_yellow, "DEP-EFF-V2", 3),
                StaticView.new(1, 7, "VFS", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "DEP-EFF-VFS", 3),
                StaticView.new(0, 10,left_triangle ~ "LANDING", mcdu_large | mcdu_white),
            ];
            me.controllers = {
                "L1": ValueController.new("DEP-SEL-V1"),
                "L2": ValueController.new("DEP-SEL-VR"),
                "L3": ValueController.new("DEP-SEL-V2"),
                "L4": ValueController.new("DEP-SEL-VFS"),
                "L5": SubmodeController.new("PERF-LANDING"),
            };
        }
    },
};

var LandingPerfModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(LandingPerfModule, m.parents);
        return m;
    },

    getNumPages: func () { return 2; },
    getTitle: func () { return "LANDING"; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(1, 1, "RWY OAT", mcdu_white),
                TemperatureView.new(0, 2, mcdu_large | mcdu_green, "LANDING-OAT"),
                StaticView.new(cells_x - 8, 1, "LND WGT", mcdu_white),
                FormatView.new(14, 2, mcdu_large | mcdu_green, "WGT-LND", 8, "%-6.0f KG"),
                StaticView.new(1, 3, "APPROACH FLAP", mcdu_white),
                CycleView.new(0, 4, mcdu_large | mcdu_green, "APPR-FLAPS",
                    [0.250, 0.500], { 0.250: "FLAP-2", 0.500: "FLAP-4" }, 1),
                StaticView.new(1, 5, "LANDING FLAP", mcdu_white),
                CycleView.new(0, 6, mcdu_large | mcdu_green, "LANDING-FLAPS",
                    [0.625, 0.750], { 0.625: "FLAP-5", 0.750: "FLAP-FULL" }, 1),
                StaticView.new(1, 7, "ICE", mcdu_white),
                CycleView.new(0, 8, mcdu_large | mcdu_green, "LANDING-ICE",
                    [0, 1], ["NO", "YES"], 1),
                StaticView.new(1, 9, "APPROACH TYPE", mcdu_white),
                CycleView.new(0, 10, mcdu_large | mcdu_green, "APPROACH-CAT",
                    [0, 1, 2], ["NON-PRECISION", "CAT-I", "CAT-II", "CAT-III"], 1),
                StaticView.new(0, 12, left_triangle ~ "PERF DATA", mcdu_white | mcdu_large),
                StaticView.new(14, 12, "T.O. DATA" ~ right_triangle, mcdu_white | mcdu_large),
            ];
            me.controllers = {
                "L1": ModelController.new("LANDING-OAT"),
                "R1": ValueController.new("WGT-LND"),
                "R2": CycleController.new("APPR-FLAPS", [0.250, 0.500]),
                "R3": CycleController.new("LANDING-FLAPS", [0.625, 0.750]),
                "R4": CycleController.new("LANDING-ICE"),
                "R5": CycleController.new("APPROACH-CAT", [0,1,2]),
            };
        }
        else if (n == 1) {
            fms.update_approach_vspeeds();
            me.views = [
                StaticView.new(1, 1, "VREF", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_yellow, "APP-EFF-VREF", 3),
                StaticView.new(1, 3, "VAP", mcdu_white),
                FormatView.new(0, 4, mcdu_large | mcdu_cyan, "APP-EFF-VAPPR", 3),
                StaticView.new(1, 5, "VAC", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_magenta, "APP-EFF-VAC", 3),
                StaticView.new(1, 7, "VFS", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "APP-EFF-VFS", 3),
            ];
            me.controllers = {
                "L1": ValueController.new("APP-SEL-VREF"),
                "L2": ValueController.new("APP-SEL-VAPPR"),
                "L3": ValueController.new("APP-SEL-VAC"),
                "L4": ValueController.new("APP-SEL-VFS"),
            };
        }
    },
};

# AOM p. 1929
var PerfDataModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(PerfDataModule, m.parents);
        return m;
    },

    getNumPages: func () { return 3; },
    getTitle: func () { return "PERF DATA"; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(1, 1, "CRZ/CEIL ALT", mcdu_white),
                StaticView.new(15, 1, "STEP INC", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_white, "CRZ-ALT", 5,
                    "FL%03.0f", func (ft) { return sprintf(ft / 100); }),
                StaticView.new(5, 2, "/FL410", mcdu_large | mcdu_white),
                # FormatView.new(5, 2, mcdu_large | mcdu_white, "CEILING-ALT", 5,
                #     "/FL%03.0f", func (ft) { return sprintf(ft / 1000); }),
                StaticView.new(20, 2, "4000", mcdu_large | mcdu_white),

                # TODO: draw the rest of the f*** owl
            ];
            me.controllers = {
            };
        }
        else if (n == 1) {
            me.views = [
            ];

            me.controllers = {
            };
        }
        else if (n == 2) {
            me.views = [
            ];

            me.controllers = {
            };
        }
        append(me.views, StaticView.new(0, 12, left_triangle ~ "PERF INIT", mcdu_large | mcdu_white));
        append(me.views, StaticView.new(16, 12, "TAKEOFF" ~ right_triangle, mcdu_large | mcdu_white));
        me.controllers["L6"] = SubmodeController.new("PERFINIT", 0);
        me.controllers["R6"] = SubmodeController.new("PERF-TAKEOFF", 0);
    },
};


var IndexModule = {
    new: func (mcdu, parentModule, title, items) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(IndexModule, m.parents);
        m.items = items;
        m.title = title;
        return m;
    },

    getNumPages: func () {
        return math.ceil(size(me.items) / 12);
    },

    getTitle: func () { return me.title; },

    loadPageItems: func (n) {
        var items = subvec(me.items, n * 12, 12);
        var i = 0;
        me.views = [];
        me.controllers = {};
        # left side
        for (i = 0; i < 6; i += 1) {
            var item = items[i];
            var lsk = "L" ~ (i + 1);
            if (item != nil) {
                append(me.views,
                    StaticView.new(0, 2 + i * 2, left_triangle ~ item[1], mcdu_large | mcdu_white));
                if (item[0] != nil) {
                    me.controllers[lsk] =
                        SubmodeController.new(item[0]);
                }
            }
        }
        # right side
        for (i = 0; i < 6; i += 1) {
            var item = items[i + 6];
            var lsk = "R" ~ (i + 1);
            if (item != nil) {
                append(me.views,
                    StaticView.new(23 - size(item[1]), 2 + i * 2, item[1] ~ right_triangle, mcdu_large | mcdu_white));
                if (item[0] != nil) {
                    me.controllers[lsk] =
                        SubmodeController.new(item[0]);
                }
            }
        }
    },
};

var SelectModule = {
    new: func (mcdu, parentModule, title, items, onSelect = nil, labels = nil, selectedItem = nil) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(SelectModule, m.parents);
        m.items = (items == nil) ? [] : items;
        m.labels = labels;
        m.selectedItem = selectedItem;
        m.title = title;
        m.onSelect = onSelect;
        return m;
    },

    getLabel: func (item) {
        if (me.labels == nil) return item;
        if (typeof(me.labels) == 'func') return me.labels(item);
        if (typeof(me.labels) == 'scalar') return sprintf(me.labels, item);
        return me.labels[item];
    },

    getTitle: func () { return me.title; },
    getNumPages: func () {
        return math.max(1, math.ceil(size(me.items) / 10));
    },

    loadPageItems: func (n) {
        me.views = [];
        me.controllers = {};
        for (var i = 0; i < 10; i += 1) {
            var j = n * 10 + i;
            if (j >= size(me.items)) {
                break;
            }
            var x = (i < 5) ? 1 : 12;
            var xp = (i < 5) ? 0 : 23;
            var p = (i < 5) ? left_triangle : right_triangle;
            var y = (i < 5) ? ((i * 2) + 2) : ((i * 2) + 2 - 10);
            var fmt = (i < 5) ? "%-11s" : "%11s";
            var lsk = (i < 5) ? ("L" ~ (i + 1)) : ("R" ~ (i - 4));
            var lbl = me.getLabel(me.items[j]);
            append(me.views, StaticView.new(xp, y, p, mcdu_large | mcdu_white));
            append(me.views, StaticView.new(x, y, sprintf(fmt, lbl), mcdu_large | mcdu_green));
            me.controllers[lsk] =
            (func (val) {
                FuncController.new(func (owner, ignored) {
                    owner.onSelect(val);
                });
            })(me.items[j]);
        };
        if (me.ptitle != nil) {
            me.controllers["R6"] = SubmodeController.new("ret");
            append(me.views,
                 StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
        }
    },
};

var ArrivalSelectModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ArrivalSelectModule, m.parents);
        return m;
    },

    getTitle: func () { return "ARRIVAL"; },
    getNumPages: func () { return 1; },

    selectRunway: func (rwyID) {
        var fp = fms.getModifyableFlightplan();
        var current = fp.current;
        var airport = fp.destination;
        if (airport == nil) {
            me.mcdu.setScratchpadMsg("NO AIRPORT", mcdu_yellow);
        }
        else if (rwyID == nil) {
            fp.destination_runway = nil;
        }
        else {
            var runway = fp.destination.runways[rwyID];
            if (runway == nil) {
                me.mcdu.setScratchpadMsg("NO RUNWAY", mcdu_yellow);
            }
            else {
                fp.destination_runway = runway;
                me.mcdu.setScratchpad('');
            }
        }
        if (fp.current <= 1) { fp.current = current; }
        fms.kickRouteManager();
        me.fullRedraw();
    },

    selectApproach: func (approachID) {
        var fp = fms.getModifyableFlightplan();
        var current = fp.current;
        if (fp.destination == nil) {
            me.mcdu.setScratchpadMsg("NO DESTINATION", mcdu_yellow);
        }
        else if (approachID == nil) {
            fp.approach = nil;
        }
        else {
            var approach = fp.destination.getIAP(approachID);
            if (approach == nil) {
                me.mcdu.setScratchpadMsg("NO APPROACH", mcdu_yellow);
            }
            else {
                fp.approach = approach;
                me.mcdu.setScratchpad('');
            }
        }
        if (fp.current <= 1) { fp.current = current; }
        fms.kickRouteManager();
        me.fullRedraw();
    },

    selectApproachTransition: func (transitionID) {
        var fp = fms.getModifyableFlightplan();
        var current = fp.current;
        if (fp.destination == nil) {
            me.mcdu.setScratchpadMsg("NO DESTINATION", mcdu_yellow);
        }
        else if (transitionID == nil) {
            fp.approach_trans = nil;
        }
        else if (fp.approach == nil) {
            me.mcdu.setScratchpadMsg("NO APPROACH", mcdu_yellow);
        }
        else {
            fp.approach_trans = transitionID;
            me.mcdu.setScratchpad('');
        }
        if (fp.current <= 1) { fp.current = current; }
        fms.kickRouteManager();
        me.fullRedraw();
    },

    selectStar: func (starID) {
        var fp = fms.getModifyableFlightplan();
        var current = fp.current;
        if (fp.destination == nil) {
            me.mcdu.setScratchpadMsg("NO DESTINATION", mcdu_yellow);
        }
        else if (starID == nil) {
            fp.star = nil;
        }
        else {
            var star = fp.destination.getStar(starID);
            if (star == nil) {
                me.mcdu.setScratchpadMsg("NO STAR", mcdu_yellow);
            }
            else {
                fp.star = star;
                me.mcdu.setScratchpad('');
            }
        }
        if (fp.current <= 1) { fp.current = current; }
        fms.kickRouteManager();
        me.fullRedraw();
    },

    selectStarTransition: func (transitionID) {
        var fp = fms.getModifyableFlightplan();
        var current = fp.current;
        if (fp.destination == nil) {
            me.mcdu.setScratchpadMsg("NO DESTINATION", mcdu_yellow);
        }
        else if (transitionID == nil) {
            fp.star_trans = nil;
        }
        else if (fp.star == nil) {
            me.mcdu.setScratchpadMsg("NO STAR", mcdu_yellow);
        }
        else {
            fp.star_trans = transitionID;
            me.mcdu.setScratchpad('');
        }
        if (fp.current <= 1) { fp.current = current; }
        fms.kickRouteManager();
        me.fullRedraw();
    },

    loadPageItems: func (n) {
        var airportModel = FuncModel.new("ARRIVAL-AIRPORT", func () {
                var fp = fms.getVisibleFlightplan();
                var apt = fp.destination;
                if (apt == nil) {
                    return "----";
                }
                else {
                    return apt.id;
                }
            }, nil);
        var runwayModel = FuncModel.new("ARRIVAL-RUNWAY", func () {
                var fp = fms.getVisibleFlightplan();
                var rwy = fp.destination_runway;
                if (rwy == nil) {
                    return "---";
                }
                else {
                    return rwy.id;
                }
            }, nil);
        var starModel = FuncModel.new("ARRIVAL-STAR", func () {
                var fp = fms.getVisibleFlightplan();
                var star = fp.star;
                if (star == nil) {
                    return "<<NONE>>";
                }
                else {
                    return star.id;
                }
            }, nil);
        var starTransitionModel = FuncModel.new("ARRIVAL-STAR-TRANS", func () {
                var fp = fms.getVisibleFlightplan();
                var trans = fp.star_trans;
                if (trans == nil) {
                    return "<<NONE>>";
                }
                else {
                    return trans.id;
                }
            }, nil);
        var approachModel = FuncModel.new("ARRIVAL-APPROACH", func () {
                var fp = fms.getVisibleFlightplan();
                var appr = fp.approach;
                if (appr == nil) {
                    return "<<NONE>>";
                }
                else {
                    return appr.id;
                }
            }, nil);
        var approachTransModel = FuncModel.new("ARRIVAL-APPROACH-TRANS", func () {
                var fp = fms.getVisibleFlightplan();
                var trans = fms.getApproachTrans(fp);
                if (trans == nil) {
                    return "<<NONE>>";
                }
                else {
                    return trans.id;
                }
            }, nil);


        me.views = [
            StaticView.new(16, 1, "AIRPORT", mcdu_white),
            FormatView.new(20, 2, mcdu_large | mcdu_green, airportModel, 4),
            StaticView.new(0, 2, left_triangle ~ "RUNWAY", mcdu_white),
            FormatView.new(1, 3, mcdu_large | mcdu_green, runwayModel, 4, "%-4s"),
            StaticView.new(0, 4, left_triangle ~ "APPROACH", mcdu_white),
            FormatView.new(1, 5, mcdu_large | mcdu_green, approachModel, 12, "%-12s"),
            StaticView.new(0, 6, left_triangle ~ "TRANSITION", mcdu_white),
            FormatView.new(1, 7, mcdu_large | mcdu_green, approachTransModel, 12, "%-12s"),
            StaticView.new(0, 8, left_triangle ~ "STAR", mcdu_white),
            FormatView.new(1, 9, mcdu_large | mcdu_green, starModel, 12, "%-12s"),
            StaticView.new(0, 10, left_triangle ~ "TRANSITION", mcdu_white),
            FormatView.new(1, 11, mcdu_large | mcdu_green, starTransitionModel, 12, "%-12s"),
            StaticView.new(17, 12, "INSERT" ~ right_triangle, mcdu_large | mcdu_white),
        ];
        me.controllers = {
            "R6": SubmodeController.new("FPL"),
            "L1": FuncController.new(
                    func (owner, val) {
                        var fp = fms.getVisibleFlightplan();
                        var airport = fp.destination;
                        var runway = fp.destination_runway;
                        var runwayID = (runway == nil) ? nil : runway.id;
                        var runways = (airport == nil) ? [] : keys(airport.runways);
                        if (val == '' or val == nil) {
                            owner.push(func (mcdu, parent) {
                                return SelectModule.new(mcdu, parent,
                                    airport.id ~ " RUNWAY", runways,
                                    func (rwy) {
                                        parent.selectRunway(rwy);
                                        mcdu.popModule();
                                    }, nil, runwayID);
                            });
                        }
                        else {
                            owner.selectRunway(val);
                        }
                    },
                    func (owner) {
                        owner.selectRunway(nil);
                    }),
            "L2": FuncController.new(
                    func (owner, val) {
                        var fp = fms.getVisibleFlightplan();
                        var airport = fp.destination;
                        var runway = fp.destination_runway;
                        var approach = fp.approach;
                        var approachID = (approach == nil) ? nil : approach.id;
                        var approaches = (runway == nil) ? airport.getApproachList() : airport.getApproachList(runway.id);
                        if (val == '' or val == nil) {
                            owner.push(func (mcdu, parent) {
                                return SelectModule.new(mcdu, parent,
                                    airport.id ~ " APPROACH", approaches,
                                    func (appr) {
                                        parent.selectApproach(appr);
                                        mcdu.popModule();
                                    }, nil, approachID);
                            });
                        }
                        else {
                            owner.selectApproach(val);
                        }
                    },
                    func (owner) {
                        owner.selectApproach(nil);
                    }),
            "L3": FuncController.new(
                    func (owner, val) {
                        var fp = fms.getVisibleFlightplan();
                        var airport = fp.destination;
                        var approach = fp.approach;
                        var transition = fms.getApproachTrans(fp);
                        var transitionID = (transition == nil) ? nil : transition.id;
                        var transitions = (approach == nil) ? [] : approach.transitions;
                        if (val == '' or val == nil) {
                            owner.push(func (mcdu, parent) {
                                return SelectModule.new(mcdu, parent,
                                    airport.id ~ " TRANSITION", transitions,
                                    func (trans) {
                                        parent.selectApproachTransition(trans);
                                        mcdu.popModule();
                                    }, nil, transitionID);
                            });
                        }
                        else {
                            owner.selectApproachTransition(val);
                        }
                    },
                    func (owner) {
                        owner.selectApproachTransition(nil);
                    }),
            "L4": FuncController.new(
                    func (owner, val) {
                        var fp = fms.getVisibleFlightplan();
                        var airport = fp.destination;
                        var runway = fp.destination_runway;
                        var star = fp.star;
                        var starID = (star == nil) ? nil : star.id;
                        var stars = (runway == nil) ? airport.stars() : airport.stars(runway.id);
                        if (val == '' or val == nil) {
                            owner.push(func (mcdu, parent) {
                                return SelectModule.new(mcdu, parent,
                                    airport.id ~ " STAR", stars,
                                    func (appr) {
                                        parent.selectStar(appr);
                                        mcdu.popModule();
                                    }, nil, starID);
                            });
                        }
                        else {
                            owner.selectStar(val);
                        }
                    },
                    func (owner) {
                        owner.selectStar(nil);
                    }),
            "L5": FuncController.new(
                    func (owner, val) {
                        var fp = fms.getVisibleFlightplan();
                        var airport = fp.destination;
                        var star = fp.star;
                        var transition = fp.star_trans;
                        var transitionID = (fp.star_trans == nil) ? nil : fp.star_trans.id;
                        var transitions = (star == nil) ? [] : star.transitions;
                        if (val == '' or val == nil) {
                            owner.push(func (mcdu, parent) {
                                return SelectModule.new(mcdu, parent,
                                    airport.id ~ " STAR TRANS", transitions,
                                    func (trans) {
                                        parent.selectStarTransition(trans);
                                        mcdu.popModule();
                                    }, nil, transitionID);
                            });
                        }
                        else {
                            owner.selectStarTransition(val);
                        }
                    },
                    func (owner) {
                        owner.selectStarTransition(nil);
                    }),
        };
    },
};

var DepartureSelectModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(DepartureSelectModule, m.parents);
        # 0 = runway select
        # 1 = SID select
        # 2 = SID trans select
        # 3 = review procedure
        # 4 = no departure airport selected
        m.mode = 0;
        m.items = [];
        m.selectedItem = nil;
        m.subtitle = nil;
        me.loadItems(0);
        return m;
    },

    getTitle: func () {
        if (me.mode == 0) {
            return "DEPARTURE RUNWAYS";
        }
        else if (me.mode == 1) {
            return "SIDS";
        }
        else if (me.mode == 2) {
            return "DEPARTURE TRANS";
        }
        else if (me.mode == 3) {
            return "PROCEDURE";
        }
        else {
            return "DEPARTURE";
        }
    },

    setMode: func (mode) {
        me.mode = mode;
        me.loadItems(mode);
        me.gotoPage(0);
    },

    loadItems: func (mode) {
        if (mode == 0) {
            var fp = fms.getModifyableFlightplan();
            var apt = fp.departure;
            var currentRunway = fp.departure_runway;
            me.items = [];
            if (apt != nil) {
                foreach (var runway; keys(apt.runways)) {
                    append(me.items, runway);
                }
                me.subtitle = apt.id;
                if (currentRunway == nil) {
                    me.selectedItem = nil;
                }
                else {
                    me.selectedItem = currentRunway.id;
                }
            }
            else {
                me.subtitle = "NO DEPARTURE";
            }
        }
        else if (mode == 1) {
            var fp = fms.getModifyableFlightplan();
            var apt = fp.departure;
            var runway = fp.departure_runway;
            var currentSid = fp.sid;
            me.items = [];
            if (apt != nil and runway != nil) {
                foreach (var sid; apt.sids(runway.id)) {
                    append(me.items, sid);
                }
                me.subtitle = apt.id ~ " RWY" ~ runway.id;
                if (currentSid == nil) {
                    me.selectedItem = nil;
                }
                else {
                    me.selectedItem = currentSid.id;
                }
            }
            else {
                me.subtitle = "NO RUNWAYS";
            }
        }
        else if (mode == 2) {
            var fp = fms.getModifyableFlightplan();
            var apt = fp.departure;
            var runway = fp.departure_runway;
            var sid = fp.sid;
            # TODO: this will only work on FG 2020.2 and beyond
            var currentTrans = (fp.sid_trans == nil) ? nil : fp.sid_trans.id;
            me.items = [];
            if (sid != nil and apt != nil and runway != nil) {
                foreach (var transition; sid.transitions) {
                    append(me.items, transition);
                }
                me.subtitle = apt.id ~ " RWY" ~ runway.id ~ " " ~ sid.id;
                if (currentTrans == nil) {
                    me.selectedItem = nil;
                }
                else {
                    me.selectedItem = currentTrans;
                }
            }
            else {
                me.subtitle = "NO SIDS";
            }
        }
        else if (mode == 3) {
            var fp = fms.getModifyableFlightplan();
            var apt = fp.departure;
            var runway = fp.departure_runway;
            var sid = fp.sid;
            me.items = [];
            if (apt != nil and runway != nil) {
                me.subtitle = apt.id ~ " RWY" ~ runway.id;
                if (sid != nil) {
                    me.subtitle = me.subtitle ~ " " ~ sid.id;
                }
                # TODO: this will only work on FG 2020.2 and beyond
                var transition = fp.sid_trans;
                if (transition != nil) {
                    me.subtitle = me.subtitle ~ "." ~ transition.id;
                }
            }
            else {
                me.subtitle = "NO DEPARTURE";
            }
        }
    },

    getNumPages: func () {
        return math.max(1, math.ceil(size(me.items) / 8));
    },

    loadPageItems: func (n) {
        me.loadItems(me.mode);
        me.views = [
            StaticView.new(0, 2, me.subtitle, mcdu_large | mcdu_green),
            StaticView.new(17, 12, "INSERT" ~ right_triangle, mcdu_large | mcdu_white),
        ];
        me.controllers = {
            "R6": SubmodeController.new("FPL"),
        };

        if (n < 0) {
            # empty list
            return;
        }

        var firstItem = n * 8;
        var x = 0;
        var y = 4;
        var fmt = "";
        var lsk = "";

        for (var i = 0; i < 8; i += 1) {
            var j = firstItem + i;
            if (j >= size(me.items)) {
                break;
            }
            val = me.items[j];
            xp = (i < 4) ? 0 : 23;
            x = (i < 4) ? 1 : 12;
            y = (i < 4) ? (4 + i * 2) : (4 + i * 2 - 8);
            p = (i < 4) ? left_triangle : right_triangle;
            fmt = (i < 4) ? "%-11s" : "%11s";
            lsk = (i < 4) ? ("L" ~ (i + 2)) : ("R" ~ (i - 2));

            append(me.views, StaticView.new(xp, y, p, mcdu_large | mcdu_white));
            append(me.views, StaticView.new(x, y, sprintf(fmt, val), mcdu_large | mcdu_green));

            # function wrapper needed because nasal's scoping rules are weird
            (func (capturedValue) {
                if (me.mode == 0) {
                    me.controllers[lsk] = FuncController.new(func (owner, ignored) {
                        owner.setDepartureRunway(capturedValue);
                        owner.setMode(1);
                    });
                }
                else if (me.mode == 1) {
                    me.controllers[lsk] = FuncController.new(func (owner, ignored) {
                        owner.setSid(capturedValue);
                        owner.setMode(2);
                    });
                }
                else if (me.mode == 2) {
                    me.controllers[lsk] = FuncController.new(func (owner, ignored) {
                        owner.setTransition(capturedValue);
                        owner.setMode(3);
                    });
                }
            })(val);
        }
    },

    setDepartureRunway: func (rwyID) {
        if (rwyID == nil) return;
        var fp = fms.getModifyableFlightplan();
        var apt = fp.departure;
        if (apt == nil) return;
        var runway = apt.runways[rwyID];
        if (runway == nil) return;
        fp.departure_runway = runway;
        fms.kickRouteManager();
    },

    setSid: func (sidID) {
        var fp = fms.getModifyableFlightplan();
        var apt = fp.departure;
        if (apt == nil) return;
        var sid = apt.getSid(sidID);
        if (sid == nil) return;
        fp.sid = sid;
        fms.kickRouteManager();
    },

    setTransition: func (transitionID) {
        # TODO: this will only work on FG 2020.2 and beyond
        var fp = fms.getModifyableFlightplan();
        fp.sid_trans = transitionID;
        fms.kickRouteManager();
    },
};

var TransponderModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(TransponderModule, m.parents);
        return m;
    },

    getNumPages: func () { return 2; },
    getTitle: func () { return "TCAS/XPDR"; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                FormatView.new(1, 2, mcdu_large |  mcdu_green, "XPDRA", 4),
                FormatView.new(1, 4, mcdu_large | mcdu_yellow, "XPDRS", 4),
                FormatView.new(18, 2, mcdu_large | mcdu_green, "PALT", 5, "%5.0f"),
                StringView.new(17, 4, mcdu_large | mcdu_green, "FLTID", 6),
                StaticView.new(  1,  1, "ACTIVE",                 mcdu_white ),
                StaticView.new(  0,  2, up_down_arrow,            mcdu_large | mcdu_white ),
                StaticView.new(  1,  3, "PRESET",                 mcdu_white ),
                StaticView.new(  0,  4, left_triangle,            mcdu_large | mcdu_white ),
                StaticView.new( 11,  1, "PRESSURE ALT",           mcdu_white ),
                StaticView.new( 17,  3, "FLT ID",                 mcdu_white ),
                StaticView.new( 23,  4, right_triangle,           mcdu_large | mcdu_white ),
                StaticView.new( 19,  5, "FREQ",                   mcdu_white ),
                StaticView.new(  1,  9, "XPDR SEL",               mcdu_large | mcdu_white ),
                StaticView.new(  1, 10, "XPDR 1",                 mcdu_large | mcdu_green ),
                StaticView.new(  8, 10, "XPDR 2",                 mcdu_white ),
                StaticView.new( 18, 10, "IDENT",                  mcdu_large | mcdu_white ),
                StaticView.new( 23, 10, black_square,             mcdu_large | mcdu_white ),
                StaticView.new( 23 - size(me.ptitle), 12, me.ptitle, mcdu_large | mcdu_white ),
                StaticView.new( 23, 12, right_triangle,           mcdu_large | mcdu_white ),
            ];
            me.controllers = {
                "L1": PropSwapController.new("XPDRA", "XPDRS"),
                "L2": TransponderController.new("XPDRS"),
                "R2": ModelController.new("FLTID"),
                "R5": TriggerController.new("XPDRID"),
                "R6": SubmodeController.new("ret"),
            };
        }
        else if (n == 1) {
            me.views = [
                CycleView.new(1, 2, mcdu_large | mcdu_green, "XPDRMD", [4,3,2,1], xpdrModeLabels),
                StaticView.new(  1,  1, "TCAS/XPDR MODE",         mcdu_white ),
                StaticView.new(  0,  2, black_square,             mcdu_large | mcdu_white ),
                StaticView.new(  1,  4, "ALT RANGE",              mcdu_white ),
                StaticView.new( 14, 12, "RADIO 1/2",              mcdu_large | mcdu_white ),
                StaticView.new( 23, 12, right_triangle,           mcdu_large | mcdu_white ),
            ];
            me.controllers = {
                "L1": CycleController.new("XPDRMD", [4,3,2,1]),
                "R6": SubmodeController.new("ret"),
            };
        }
    },
};

var RadioModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(RadioModule, m.parents);
        return m;
    },

    getNumPages: func () { return 2; },
    getTitle: func () { return "RADIOS"; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                FreqView.new(1, 2, mcdu_large | mcdu_green, "COM1A"),
                FreqView.new(1, 4, mcdu_large | mcdu_yellow, "COM1S"),
                FreqView.new(16, 2, mcdu_large | mcdu_green, "COM2A"),
                FreqView.new(16, 4, mcdu_large | mcdu_yellow, "COM2S"),

                FreqView.new(1, 6, mcdu_large | mcdu_green, "NAV1A"),
                FreqView.new(1, 8, mcdu_large | mcdu_yellow, "NAV1S"),
                FreqView.new(17, 6, mcdu_large | mcdu_green, "NAV2A"),
                FreqView.new(17, 8, mcdu_large | mcdu_yellow, "NAV2S"),

                FormatView.new(19, 10, mcdu_large | mcdu_green, "XPDRA", 4),

                ToggleView.new(8, 5, mcdu_large | mcdu_blue, "NAV1AUTO", "FMS"),
                ToggleView.new(8, 6, mcdu_large | mcdu_blue, "NAV1AUTO", "AUTO"),
                ToggleView.new(12, 5, mcdu_large | mcdu_blue, "NAV2AUTO", "FMS"),
                ToggleView.new(12, 6, mcdu_large | mcdu_blue, "NAV2AUTO", "AUTO"),

                CycleView.new(1, 12, mcdu_large | mcdu_green, "XPDRON",
                    [0, 1],
                    func (n) { return (n ? xpdrModeLabels[getprop(keyProps["XPDRMD"])] : "STBY"); }),

                StaticView.new(  1,  1, "COM1",                   mcdu_white ),
                StaticView.new(  0,  2, up_down_arrow,            mcdu_large | mcdu_white ),
                StaticView.new(  0,  4, left_triangle,            mcdu_large | mcdu_white ),

                StaticView.new( 19,  1, "COM2",                   mcdu_white ),
                StaticView.new( 23,  2, up_down_arrow,            mcdu_large | mcdu_white ),
                StaticView.new( 23,  4, right_triangle,           mcdu_large | mcdu_white ),

                StaticView.new(  1,  5, "NAV1",                   mcdu_white ),
                StaticView.new(  0,  6, up_down_arrow,            mcdu_large | mcdu_white ),
                StaticView.new(  0,  8, left_triangle,            mcdu_large | mcdu_white ),

                StaticView.new( 19,  5, "NAV2",                   mcdu_white ),
                StaticView.new( 23,  6, up_down_arrow,            mcdu_large | mcdu_white ),
                StaticView.new( 23,  8, right_triangle,           mcdu_large | mcdu_white ),

                StaticView.new( 19,  9, "XPDR",                   mcdu_white ),
                StaticView.new( 23, 10, right_triangle,           mcdu_large | mcdu_white ),
                StaticView.new( 18, 11, "IDENT",                  mcdu_white ),
                StaticView.new( 18, 12, "IDENT",                  mcdu_large | mcdu_white ),
                StaticView.new( 23, 12, black_square,             mcdu_large | mcdu_white ),

                StaticView.new(  0, 10, left_triangle ~ "TCAS/XPDR",              mcdu_large | mcdu_white ),
                StaticView.new(  0, 12, left_right_arrow,         mcdu_large | mcdu_white ),
            ];
            me.dividers = [0, 1, 3, 4];
            me.controllers = {
                "L1": PropSwapController.new("COM1A", "COM1S"),
                "L2": FreqController.new("COM1S", "COM1"),
                "L3": PropSwapController.new("NAV1A", "NAV1S"),
                "L4": FreqController.new("NAV1S", "NAV1"),
                "L5": SubmodeController.new("XPDR"),
                "L6": CycleController.new("XPDRON"),
                "R1": PropSwapController.new("COM2A", "COM2S"),
                "R2": FreqController.new("COM2S", "COM2"),
                "R3": PropSwapController.new("NAV2A", "NAV2S"),
                "R4": FreqController.new("NAV2S", "NAV2"),
                "R5": TransponderController.new("XPDRA", "XPDR"),
                "R6": TriggerController.new("XPDRID"),
            };
        }
        else if (n == 1) {
            me.views = [
                FreqView.new(1, 2, mcdu_large | mcdu_green, "ADF1A"),
                FreqView.new(1, 4, mcdu_large | mcdu_yellow, "ADF1S"),
                FreqView.new(18, 2, mcdu_large | mcdu_green, "ADF2A"),
                FreqView.new(18, 4, mcdu_large | mcdu_yellow, "ADF2S"),
                StaticView.new( 1, 1, "ADF1", mcdu_white ),
                StaticView.new( 0, 4, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new(19, 1, "ADF2", mcdu_white ),
                StaticView.new(23, 4, right_triangle, mcdu_white ),
            ];
            me.dividers = [0, 1, 2, 3, 4];
            me.controllers = {
                "L1": PropSwapController.new("ADF1A", "ADF1S"),
                "R1": PropSwapController.new("ADF2A", "ADF2S"),
                "L2": FreqController.new("ADF1S"),
                "R2": FreqController.new("ADF2S"),
            };
        }
    },
};

var NavIdentModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(NavIdentModule, m.parents);
        return m;
    },

    getTitle: func () { return "NAV IDENT"; },
    getNumPages: func () { return 1; },

    loadPageItems: func (n) {
        if (n == 0) { 
            me.views = [
                StaticView.new( 2,  1, "DATE", mcdu_white),
                FormatView.new( 1, 2, mcdu_large | mcdu_cyan, "ZDAY", 2, "%02d"),
                FormatView.new( 3, 2, mcdu_large | mcdu_cyan, "ZMON", 3, "%3s", datetime.monthName3),
                FormatView.new( 6, 2, mcdu_large | mcdu_cyan, "ZYEAR", 2, "%02d",
                    func (y) { return math.mod(y, 100); }),

                StaticView.new(12, 1, "ACTIVE NDB", mcdu_white),

                FormatView.new(10, 2, mcdu_large | mcdu_green, "NDBFROM_DAY", 2, "%02d"),
                FormatView.new(12, 2, mcdu_large | mcdu_green, "NDBFROM_MON", 3, "%3s", datetime.monthName3),
                FormatView.new(16, 2, mcdu_large | mcdu_green, "NDBUNTIL_DAY", 2, "%02d"),
                FormatView.new(18, 2, mcdu_large | mcdu_green, "NDBUNTIL_MON", 3, "%3s", datetime.monthName3),
                StaticView.new(21, 2, "/", mcdu_large | mcdu_green),
                FormatView.new(22, 2, mcdu_large | mcdu_green, "NDBUNTIL_YEAR", 2, "%02d",
                    func (y) { return math.mod(y or 0, 100); }),

                StaticView.new( 2,  3, "UTC", mcdu_white),
                FormatView.new( 1, 4, mcdu_large | mcdu_cyan, "ZHOUR", 2, "%02d"),
                FormatView.new( 3, 4, mcdu_large | mcdu_cyan, "ZMIN", 2, "%02d"),
                StaticView.new( 5,  4, "Z", mcdu_cyan),
                StaticView.new( 2,  5, "SW", mcdu_white),
                FormatView.new( 1,  6, mcdu_large | mcdu_green, "FGVER", 10, "%-10s"),
                StaticView.new(11,  5, "NDS", mcdu_white),
                FormatView.new(15,  5, mcdu_green, "NDBVERSION", 9),
                FormatView.new(12,  6, mcdu_large | mcdu_green, "NDBSOURCE", 12),
                StaticView.new( 0, 12, left_triangle ~ "MAINTENANCE", mcdu_large | mcdu_white),
                StaticView.new(12, 12, "   POS INIT" ~ right_triangle, mcdu_large | mcdu_white),
            ];
            me.controllers = {
                "R6": SubmodeController.new("POSINIT", 0),
            };
        }
    },
};

var PosInitModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(PosInitModule, m.parents);
        return m;
    },

    getTitle: func () { return "POSITION INIT"; },
    getNumPages: func () { return 1; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(1,  1, "LAST POS",              mcdu_white),
                GeoView.new(0,  2, mcdu_large | mcdu_green, "RAWLAT",  "LAT"),
                GeoView.new(9,  2, mcdu_large | mcdu_green, "RAWLON",  "LON"),
                ToggleView.new(15, 1, mcdu_white, "POSLOADED1", "(LOADED)"),
                StaticView.new(       19,  2, "LOAD" ~ right_triangle, mcdu_large | mcdu_white),

                StaticView.new(        1,  5, "GPS1 POS",              mcdu_white),
                GeoView.new(0,  6, mcdu_large | mcdu_green, "GPSLAT",  "LAT"),
                GeoView.new(9,  6, mcdu_large | mcdu_green, "GPSLON",  "LON"),
                ToggleView.new(15, 5, mcdu_white, "POSLOADED3", "(LOADED)"),
                StaticView.new(       19,  6, "LOAD" ~ right_triangle, mcdu_large | mcdu_white),
                StaticView.new(        0, 12, left_triangle ~ "POS SENSORS", mcdu_large | mcdu_white),
            ];
            me.controllers = {
                "R1": TriggerController.new("POSLOADED1"),
                "R3": TriggerController.new("POSLOADED3"),
            };
            if (me.ptitle != nil) {
                me.controllers["R6"] = SubmodeController.new("ret");
                append(me.views,
                     StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
            }
            else {
                append(me.views,
                    StaticView.new(       20, 12, "RTE" ~ right_triangle, mcdu_large | mcdu_white));
                me.controllers["R6"] = SubmodeController.new("RTE");
            }
        }
    },
};

var NavRadioDetailsModule = {
    new: func (mcdu, parentModule, radioNum) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(NavRadioDetailsModule, m.parents);
        m.radioNum = radioNum;
        return m;
    },

    getNumPages: func () { return 1; },
    getTitle: func () { return "NAV" ~ me.radioNum; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                FreqView.new(1, 2, mcdu_large |  mcdu_green, "NAV" ~ me.radioNum ~ "A"),
                FreqView.new(1, 4, mcdu_large |  mcdu_yellow, "NAV" ~ me.radioNum ~ "S"),
                CycleView.new(17, 4, mcdu_large | mcdu_green, "DME" ~ me.radioNum ~ "H"),
                CycleView.new(17, 10, mcdu_large | mcdu_green, "NAV" ~ me.radioNum ~ "AUTO"),
                StaticView.new(  1,  1, "ACTIVE",                 mcdu_white ),
                StaticView.new(  0,  2, up_down_arrow, mcdu_large | mcdu_white ),
                StaticView.new(  1,  3, "PRESET",                 mcdu_white ),
                StaticView.new(  0,  4, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new( 15,  3, "DME HOLD",               mcdu_white ),
                StaticView.new( 15,  9, "FMS AUTO",               mcdu_white ),
                StaticView.new(  0, 12, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new(  1, 12, "MEMORY", mcdu_large | mcdu_white ),
            ];
            me.controllers = {
                "L1": PropSwapController.new("NAV" ~ me.radioNum ~ "S", "NAV" ~ me.radioNum ~ "A"),
                "L2": FreqController.new("NAV" ~ me.radioNum ~ "S"),
                "R2": CycleController.new("DME" ~ me.radioNum ~ "H"),
                "R5": CycleController.new("NAV" ~ me.radioNum ~ "AUTO"),
            };
            if (me.ptitle != nil) {
                me.controllers["R6"] = SubmodeController.new("ret");
                append(me.views,
                     StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
            }
        }
    },
};

var ComRadioDetailsModule = {
    new: func (mcdu, parentModule, radioNum) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ComRadioDetailsModule, m.parents);
        m.radioNum = radioNum;
        return m;
    },

    getNumPages: func () { return 1; },
    getTitle: func () { return "COM" ~ me.radioNum; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                FreqView.new(1, 2, mcdu_large |  mcdu_green, "COM" ~ me.radioNum ~ "A"),
                FreqView.new(1, 4, mcdu_large |  mcdu_yellow, "COM" ~ me.radioNum ~ "S"),
                StaticView.new(  1,  1, "ACTIVE",                 mcdu_white ),
                StaticView.new(  0,  2, up_down_arrow, mcdu_large | mcdu_white ),
                StaticView.new(  1,  3, "PRESET",                 mcdu_white ),
                StaticView.new(  0,  4, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new(  1,  5, "MEM TUNE",               mcdu_white ),
                StaticView.new( 16,  1, "SQUELCH",                mcdu_white ),
                StaticView.new( 19,  3, "MODE",                   mcdu_white ),
                StaticView.new( 19,  5, "FREQ",                   mcdu_white ),
                FormatView.new( 17,  6, mcdu_large | mcdu_green, "COM" ~ me.radioNum ~ "FS", 7),
                StaticView.new(  0, 12, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new(  1, 12, "MEMORY", mcdu_large | mcdu_white ),
            ];
            me.controllers = {
                "L1": PropSwapController.new("COM" ~ me.radioNum ~ "S", "COM" ~ me.radioNum ~ "A"),
                "L2": FreqController.new("COM" ~ me.radioNum ~ "S"),
                "R3": ComModeController.new("COM" ~ me.radioNum ~ "FS"),
            };
            if (me.ptitle != nil) {
                me.controllers["R6"] = SubmodeController.new("ret");
                append(me.views,
                     StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
            }
        }
    },
};

var ProgressModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ProgressModule, m.parents);
        return m;
    },

    getTitle: func () { return "PROGRESS"; },
    getNumPages: func () { return 3; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new( 8,  1, "DIST", mcdu_white),
                StaticView.new(14,  1, "ETE", mcdu_white),
                StaticView.new(19,  1, "FUEL", mcdu_white),
                StaticView.new( 1,  1, "TO", mcdu_white),
                FormatView.new( 0,  2, mcdu_large | mcdu_green, "ID-WP0", 6, "%-6s"),
                FormatView.new( 6,  2, mcdu_large | mcdu_green, "DIST-WP0", 6, "%4s", formatDist),
                FormatView.new(13,  2, mcdu_large | mcdu_green, "ETA-WP0", 6, "%5s", formatZulu),
                FormatView.new(18,  2, mcdu_large | mcdu_green, "FUEL-WP0", 6, "%5.1f", func (fuel) { return fuel * LB2KG / 1000.0; }),
                StaticView.new( 1,  3, "NEXT", mcdu_white),
                FormatView.new( 0,  4, mcdu_large | mcdu_green, "ID-WP1", 6, "%-6s"),
                FormatView.new( 6,  4, mcdu_large | mcdu_green, "DIST-WP1", 6, "%4s", formatDist),
                FormatView.new(13,  4, mcdu_large | mcdu_green, "ETA-WP1", 6, "%5s", formatZulu),
                FormatView.new(18,  4, mcdu_large | mcdu_green, "FUEL-WP1", 6, "%5.1f", func (fuel) { return fuel * LB2KG / 1000.0; }),
                StaticView.new( 1,  5, "DEST", mcdu_white),
                FormatView.new( 0,  6, mcdu_large | mcdu_green, "ID-DEST", 6, "%-6s"),
                FormatView.new( 6,  6, mcdu_large | mcdu_green, "DIST-DEST", 6, "%4s", formatDist),
                FormatView.new(13,  6, mcdu_large | mcdu_green, "ETA-DEST", 6, "%5s", formatZulu),
                FormatView.new(18,  6, mcdu_large | mcdu_green, "FUEL-DEST", 6, "%5.1f", func (fuel) { return fuel * LB2KG / 1000.0; }),
                StaticView.new( 1,  9, "GPS RNP=", mcdu_white),
                StaticView.new( 9, 9, "1.00", mcdu_green),
                StaticView.new(14, 9, "EPU=N/A", mcdu_white),
                StringView.new(0, 10, mcdu_large |  mcdu_green, "NAV1ID", 5),
                FreqView.new(6, 10, mcdu_large |  mcdu_green, "NAV1A"),
                StringView.new(12, 10, mcdu_large |  mcdu_green, "NAV2ID", 5),
                FreqView.new(18, 10, mcdu_large |  mcdu_green, "NAV2A"),

                StaticView.new(        0, 12, left_triangle ~ "NAV1 <--SELECT--> NAV2" ~ right_triangle, mcdu_large | mcdu_white),
            ];
            me.controllers = {
                "L6": SubmodeController.new("PROG-NAV1"),
                "R6": SubmodeController.new("PROG-NAV2"),
            };
        }
        else if (n == 1) {
            me.views = [
                StaticView.new(  1, 3, "TOC", mcdu_white),
                FormatView.new(  1, 4, mcdu_green | mcdu_large, "VNAV-DIST-TOC", 4, "%4s", formatDist),
                StaticView.new(  5, 4, "NM/", mcdu_white),
                FormatView.new(  8, 4, mcdu_green | mcdu_large, "VNAV-ETE-TOC", 5, "%5s", formatETE),

                StaticView.new(  1, 5, "TOD", mcdu_white),
                FormatView.new(  1, 6, mcdu_green | mcdu_large, "VNAV-DIST-TOD", 7, "%4s", formatDist),
                StaticView.new(  5, 6, "NM/", mcdu_white),
                FormatView.new(  8, 6, mcdu_green | mcdu_large, "VNAV-ETE-TOD", 5, "%5s", formatETE),

                StaticView.new( 16, 3, "FUEL QTY", mcdu_white),
                FormatView.new( 19, 4, mcdu_green | mcdu_large, "FUEL-CUR", 5, "%5.0f"),
                StaticView.new( 16, 5, "GROSS WT", mcdu_white),
                FormatView.new( 19, 6, mcdu_green | mcdu_large, "WGT-CUR", 5, "%5.0f", func (lbs) { return lbs * LB2KG; }),
            ];
        }
        else if (n == 2) {
            me.views = [
                StaticView.new(  1, 1, "XTK ERROR", mcdu_white),
                # TODO
                # FormatView.new(  1, 2, mcdu_green | mcdu_large, "XTK-ERROR", 4, "%4s", formatDist),
                StaticView.new(  17, 1, "OFFSET", mcdu_white),
                # TODO
                # FormatView.new(  1, 2, mcdu_green | mcdu_large, "NAV-LAT-OFFSET", 4, "%4s", formatDist),
                StaticView.new(   1, 3, "TRACK", mcdu_white),
                StaticView.new(  10, 3, "DRIFT", mcdu_white),
                StaticView.new(  20, 3, "HDG", mcdu_white),
                FormatView.new(   1, 4, mcdu_green | mcdu_large, "TRACK", 4, "%4.0f°"),
                FormatView.new(  10, 4, mcdu_green | mcdu_large, "DRIFT", 4, "%4.0f°"),
                FormatView.new(  18, 4, mcdu_green | mcdu_large, "HDG", 4, "%4.0f°"),

                StaticView.new(   1, 5, "WIND", mcdu_white),
                StaticView.new(  21, 5, "GS", mcdu_white),

                FormatView.new(   0, 6, mcdu_green | mcdu_large, "WIND-HDG", 4, "%4.0f°"),
                StaticView.new(   5, 6, "/", mcdu_white | mcdu_large),
                FormatView.new(   6, 6, mcdu_green | mcdu_large, "WIND-SPD", 3, "%-3.0f"),

                FormatView.new(   9, 6, mcdu_cyan | mcdu_large, "WIND-HEAD", 1, "%1s", func (x) { if (x >= 0) return "↓" else return "↑"; }),
                FormatView.new(  10, 6, mcdu_cyan | mcdu_large, "WIND-HEAD", 3, "%-3.0f", math.abs),
                FormatView.new(  14, 5, mcdu_cyan | mcdu_large, "WIND-CROSS", 3, "%3s", func (x) { if (x >= 0) return "-->" else return "<--"; }),
                FormatView.new(  14, 6, mcdu_cyan | mcdu_large, "WIND-CROSS", 3, "%-3.0f", math.abs),
                FormatView.new(  20, 6, mcdu_green | mcdu_large, "GS", 3, "%3.0f"),
            ];
        }
    },
};

var ProgressNavModule = {
    new: func (mcdu, navNum, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ProgressNavModule, m.parents);
        m.navNum = navNum;
        return m;
    },

    getTitle: func () { return "NAV " ~ me.navNum; },
    getNumPages: func () { return 1; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(        0, 12, left_triangle ~ "PROGRESS", mcdu_large | mcdu_white),
            ];
            me.controllers = {
                "L6": SubmodeController.new("ret"),
            };
            var x = 0;
            var y = 2;
            var ki = 1;
            var k = "";
            var navaids = findNavaidsWithinRange(250, 'VOR');
            var navs = [];
            var prop = "NAV" ~ me.navNum ~ "A";
            foreach (var nav; navaids) {
                if (nav.type == 'VOR') {
                    var str = sprintf("%-4s %5.1f", nav.id, nav.frequency / 100.0);
                    if (x) {
                        k = 'R' ~ ki;
                        append(me.views,
                            StaticView.new(13, y, str ~ right_triangle, mcdu_large | mcdu_white));
                    }
                    else {
                        k = 'L' ~ ki;
                        append(me.views,
                            StaticView.new(0, y, left_triangle ~ str, mcdu_large | mcdu_white));
                    }
                    me.controllers[k] = SelectController.new(prop, nav.frequency / 100.0);
                    x += 1;
                    if (x > 1) {
                        x = 0;
                        y += 2;
                        ki += 1;
                    }
                    if (ki > 5) break;
                }
            }
        }
    },
};

var ATCLogonModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ATCLogonModule, m.parents);
        return m;
    },

    getTitle: func () { return "ATC LOGON/STATUS"; },
    getNumPages: func () { return 2; },

    activate: func () {
        me.loadPage(me.page);
        me.timer = maketimer(1, me, func () {
            globals.cpdlc.system.updateDatalinkStatus();
        });
        me.timer.start();
    },

    deactivate: func () {
        if (me.timer != nil) {
            me.timer.stop();
            me.timer = nil;
        }
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
                    "%12s",
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

                StaticView.new(14, 11, "DATALINK", mcdu_white),
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
                            if (!getprop('/cpdlc/logon-station')) return nil;
                            globals.cpdlc.system.connect();
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

var CPDLCDatalinkSetupModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(CPDLCDatalinkSetupModule, m.parents);
        m.loadOptions();
        return m;
    },

    loadOptions: func () {
        me.options = [];
        foreach (var k; globals.cpdlc.system.listDrivers()) {
            append(me.options, k);
        }
        # debug.dump(me.options);
    },

    getTitle: func () {
        return "DATALINK SETUP";
    },

    activate: func () {
        me.loadOptions();
        me.loadPage(me.page);
    },

    getNumPages: func () {
        return math.ceil(size(me.options) / 5);
    },

    loadPageItems: func (n) {
        # debug.dump('LOAD PAGE', n);
        me.views = [];
        me.controllers = {};
        for (var i = 0; i < 5; i += 1) {
            if (i + n * 5 >= size(me.options)) break;
            var item = me.options[i + n * 5];
            append(me.views, StaticView.new(0, i * 2 + 2, left_triangle, mcdu_large | mcdu_white));
            append(me.views, StaticView.new(1, i * 2 + 2, item,
                (item == globals.cpdlc.system.getDriver()) ?
                    (mcdu_large | mcdu_green) :
                    mcdu_white));
            me.controllers['L' ~ (i + 1)] =
                (func (k) { return FuncController.new(func (owner, val) {
                    globals.cpdlc.system.setDriver(k);
                    owner.loadPage(owner.page);
                    owner.fullRedraw();
                    return nil;
                }); })(item);
        }
        if (me.ptitle != nil) {
            me.controllers["L6"] = SubmodeController.new("ret");
            append(me.views,
                 StaticView.new(0, 12, left_triangle ~ me.ptitle, mcdu_large));
        }
    },
};

var CPDLCLogModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(CPDLCLogModule, m.parents);
        m.listener = nil;
        m.historyNode = props.globals.getNode('/cpdlc/history');
        return m;
    },

    getTitle: func () {
        return "ATC LOG";
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
    },

    getNumPages: func () {
        var refs = props.globals.getNode('/cpdlc/history', 1).getChildren('item');
        return math.max(1, math.floor((size(refs) + 4) / 5));
    },

    loadPageItems: func (n) {
        var refs = props.globals.getNode('/cpdlc/history', 1).getChildren('item');
        me.views = [];
        me.controllers = {};
        var r = size(refs) - 1 - n * 5;
        var y = 1;
        for (var i = 0; i < 5; i += 1) {
            if (r < 0) break;
            var msgID = refs[r].getValue();
            var item = props.globals.getNode('/cpdlc/messages/' ~ msgID);
            if (item == nil) {
                continue;
            }
            var msg = cpdlc.Message.fromNode(item);
            var dir = msg.dir;
            # debug.dump(item, msg);
            var summary = cpdlc.formatMessage(msg.parts);
            if (size(summary) > 22) {
                summary = substr(summary, 0, 20) ~ '..';
            }
            append(me.views,
                StaticView.new(1, y, sprintf("%04sZ", item.getValue('timestamp') or '----'), mcdu_white));
            var flags = mcdu_white;
            var status = item.getValue('status') or '';
            if (status == 'NEW')
                flags = mcdu_white | mcdu_reverse;
            if (status == 'SENT')
                statusText = item.getValue('response-status') or 'OLD';
            else
                statusText = status or 'OLD';
            append(me.views,
                StaticView.new(23 - size(statusText), y, statusText, flags));
            if (dir != 'pseudo') {
                append(me.views,
                    StaticView.new(0, y+1, (dir == 'up') ? '↑' : '↓', mcdu_white | mcdu_large));
            }
            append(me.views,
                StaticView.new(1, y+1, summary,
                    ((dir == 'up') ? mcdu_green : (dir == 'pseudo' ? mcdu_white : mcdu_blue)) | mcdu_large));
            append(me.views,
                StaticView.new(23, y+1, right_triangle, mcdu_white | mcdu_large));
            var lsk = 'R' ~ (i + 1);
            me.controllers[lsk] = (func(mid) {
                return SubmodeController.new(func (owner, parent) {
                    return CPDLCMessageModule.new(owner, parent, mid);
                });
            })(msgID);
            r -= 1;
            y += 2;
        }
        append(me.views, StaticView.new( 0, 12, left_triangle ~ "ATC INDEX", mcdu_white | mcdu_large));
        append(me.views, StaticView.new(14, 12, "CLEAR LOG" ~ right_triangle, mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ret");
        me.controllers['R6'] = FuncController.new(func (owner, val) {
            globals.cpdlc.system.clearHistory();
            return nil;
        });
    },
};

var CPDLCComposeDownlinkModule = {
    new: func (mcdu, parentModule, parts, mrn = nil, to = nil) {
        # debug.dump(parts);
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(CPDLCComposeDownlinkModule, m.parents);
        m.parts = parts;
        m.mrn = mrn;
        m.makeElems();
        m.dir = 'down';
        m.makePages();
        if (mrn != nil) {
            m.ptitle = 'UPLINK';
        }
        elsif (parentModule != nil) {
            m.ptitle = parentModule.getTitle();
        }
        m.to = to;
        return m;
    },

    makeElems: func () {
        # debug.dump(me.parts);
        me.elems = cpdlc.formatMessageFancy(me.parts);
        # debug.dump('makeElems:', me.parts, me.elems);
    },

    getTitle: func () {
        if (me.mrn == nil)
            return "VERIFY REQUEST";
        else
            return "VERIFY RESPONSE";
    },

    getNumPages: func () {
        return size(me.pages);
    },

    loadPageItems: func (n) {
        var self = me;

        if (n < size(me.pages)) {
            me.views = me.pages[n].views;
            me.controllers = me.pages[n].controllers;
        }
        else {
            me.views = [];
            me.controllers = {};
        }

        append(me.views, StaticView.new( 0, 12, left_triangle ~ me.ptitle, mcdu_white | mcdu_large));
        append(me.views, StaticView.new(19, 12, "SEND" ~ right_triangle, mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ret");
        me.controllers['R6'] = FuncController.new(func (owner, val) {
                                    var msg = globals.cpdlc.Message.new();
                                    msg.mrn = self.mrn;
                                    msg.parts = [];
                                    foreach (var part; self.parts) {
                                        # don't send empty text parts
                                        if ((substr(part.type, 0, 3) == 'TXT' or
                                             substr(part.type, 0, 3) == 'SUP') and
                                            (size(part.args) == 0 or
                                             part.args[0] == nil or
                                             part.args[0] == ''))
                                            continue;
                                        append(msg.parts, part);
                                    }
                                    msg.dir = 'down';
                                    msg.to = owner.to;
                                    var mid = globals.cpdlc.system.send(msg);
                                    if (mid != nil) owner.ret();
                                });
    },

    makePages: func () {
        var y = 1;
        me.pages = [];
        var views = [];
        var controllers = {};
        var nextPage = func () {
            append(me.pages, { 'views': views, 'controllers': controllers });
            y = 1;
            views = [];
            controllers = {};
        };
        var nextLine = func(limit=10) {
            y += 1;
            if (y > limit) {
                nextPage();
            }
        };
        var evenLine = func(limit=10) {
            if (y > limit) {
                nextPage();
                evenLine();
            }
            elsif (y & 1) {
                nextLine(limit);
            }
        };
        var unevenLine = func(limit=10) {
            if (y > limit) {
                nextPage();
                unevenLine();
            }
            elsif (!(y & 1)) {
                nextLine(limit);
            }
        };
        var lsk = func(which) {
            var i = math.floor((y + 1) / 2);
            return which ~ i;
        };

        var color = mcdu_white;
        var lineSel = unevenLine;
        var partIndex = 0;

        foreach (var part; me.elems) {
            var first = 1;
            var argIndex = 0;
            foreach (var elem; part) {
                var val = elem.value;
                if (first) {
                    first = 0;
                    if (elem.type == 0) {
                        val = '/' ~ val;
                    }
                    else {
                        unevenLine();
                        append(views, StaticView.new(0, y, '/', mcdu_white));
                        nextLine();
                    }
                }

                if (elem.type == 0) {
                    lineSel = unevenLine;
                    color = mcdu_white;
                }
                else {
                    lineSel = evenLine;
                    color = mcdu_green | mcdu_large;
                }

                var words = split(' ', val);
                var line = '';
                lineSel();
                if (elem.type != 0) {
                    controllers[lsk('L')] = (func(partIndex, argIndex) { return FuncController.new(
                        func (owner, val) {
                            printf('parts[%i].args[%i] := %s', partIndex, argIndex, val);
                            owner.parts[partIndex].args[argIndex] = val;
                            owner.makeElems();
                            owner.makePages();
                            owner.loadPage(owner.page);
                            owner.fullRedraw();
                            return val;
                        },
                        func (owner) {
                            printf('parts[%i].args[%i] := %s', partIndex, argIndex, nil);
                            owner.parts[partIndex].args[argIndex] = nil;
                            owner.makeElems();
                            owner.makePages();
                            owner.loadPage(owner.page);
                            owner.fullRedraw();
                        },
                    ); })(partIndex, argIndex);
                    argIndex += 1;
                }
                foreach (var word; words) {
                    if (size(line) == 0) {
                        while (size(word) > 24) {
                            lineSel();
                            append(views, StaticView.new(0, y, substr(word, 0, 22) ~ '..', color));
                            nextLine();
                            word = substr(word, 22);
                        }
                        line = word;
                    }
                    else {
                        if (size(line) + 1 + size(word) > 24) {
                            lineSel();
                            append(views, StaticView.new(0, y, line, color));
                            nextLine();
                            line = word;
                        }
                        else {
                            line = line ~ ' ' ~ word;
                        }
                    }
                }
                if (size(line) > 0) {
                    lineSel();
                    append(views, StaticView.new(0, y, line, color));
                    nextLine();
                }
            }
            partIndex += 1;
        }

        if (size(views))
            nextPage();
    },
};

var CPDLCMessageModule = {
    new: func (mcdu, parentModule, msgID) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(CPDLCMessageModule, m.parents);
        m.msgID = msgID;
        m.loadMessage();
        return m;
    },

    activate: func () {
        me.loadPage(me.page);
        me.timer = maketimer(1, me, func () {
            me.loadMessage();
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
    },


    loadMessage: func () {
        var messageNode = props.globals.getNode('/cpdlc/messages/' ~ me.msgID);
        if (messageNode == nil) {
            me.elems = [];
            me.dir = 'up';
            me.status = 'INVALID';
            me.station = '----';
            me.timestamp = '----';
            me.ra = nil;
            me.replies = [];
            me.replyTimestamp = nil;
            me.replyID = nil;
            me.parentTimestamp = nil;
            me.parentID = nil;
            me.min = nil;
            me.pages = [];
            me.parts = [];
        }
        else {
            var message = cpdlc.Message.fromNode(messageNode);
            me.elems = cpdlc.formatMessageFancy(message.parts);
            me.dir = message.dir;
            me.status = message['status'] or 'OLD';
            me.station = (me.dir == 'down') ? message.to : message.from;
            me.timestamp = messageNode.getValue('timestamp');
            me.parts = message.parts;

            # Mark as read *after* loading the message, so that the status
            # still shows as 'NEW'
            cpdlc.system.markMessageRead(me.msgID);

            var replyID = messageNode.getValue('reply');
            var replyNode = (replyID == nil) ? nil : props.globals.getNode('/cpdlc/messages/' ~ replyID);
            if (replyNode == nil) {
                me.replyID = nil;
                me.replyTimestamp = nil;
            }
            else {
                me.replyID = replyID;
                me.replyTimestamp = replyNode.getValue('timestamp');
            }
            var parentID = messageNode.getValue('parent');
            var parentNode = (parentID == nil) ? nil : props.globals.getNode('/cpdlc/messages/' ~ parentID);
            if (parentNode == nil) {
                me.parentID = nil;
                me.parentTimestamp = nil;
            }
            else {
                me.parentID = parentID;
                me.parentTimestamp = parentNode.getValue('timestamp');
            }

            if (me.dir == 'up') {
                me.ra = message.getRA() or '';
                me.replies = [];
                var ty = cpdlc.uplink_messages[message.parts[0].type];
                if (ty != nil and ty['replies'] != nil) {
                    me.replies = ty['replies'];
                }
            }
            else {
                me.ra = '';
            }
            me.min = message.min;
            me.makePages();
        }
    },

    makePages: func () {
        var self = me;
        var y = 1;
        me.pages = [];
        var views = [];
        var controllers = {};
        var nextPage = func () {
            append(me.pages, { 'views': views, 'controllers': controllers });
            y = 1;
            views = [];
            controllers = {};
        };
        var nextLine = func(limit=10) {
            y += 1;
            if (y > limit) {
                nextPage();
            }
        };
        var evenLine = func(limit=10) {
            if (y > limit) {
                nextPage();
                evenLine();
            }
            elsif (y & 1) {
                nextLine(limit);
            }
        };
        var unevenLine = func(limit=10) {
            if (y > limit) {
                nextPage();
                unevenLine();
            }
            elsif (!(y & 1)) {
                nextLine(limit);
            }
        };
        var lsk = func(which) {
            var i = math.floor((y + 1) / 2);
            return which ~ i;
        };

        unevenLine();
        append(views, StaticView.new(1, y, me.station, mcdu_green));
        append(views, StaticView.new(12, y, sprintf("%11s", me.status or 'OLD'), mcdu_green | mcdu_large));
        nextLine();

        evenLine();
        if (me.dir != 'pseudo') {
            if (me.replyID != nil and me.dir == 'down') {
                append(views, StaticView.new(0, y, left_triangle ~ "UPLINK", mcdu_white | mcdu_large));
                controllers[lsk('L')] = (func(mid) {
                        return SubmodeController.new(func (owner, parent) {
                            return CPDLCMessageModule.new(owner, parent, mid);
                        }, 2);
                })(me.replyID);
            }
            elsif (me.parentID != nil) {
                append(views, StaticView.new(0, y, left_triangle ~ "REQUEST", mcdu_white | mcdu_large));
                controllers[lsk('L')] = (func(mid) {
                        return SubmodeController.new(func (owner, parent) {
                            return CPDLCMessageModule.new(owner, parent, mid);
                        }, 2);
                })(me.parentID);
            }
            elsif (me.replyID != nil and me.dir == 'up') {
                append(views, StaticView.new(0, y, left_triangle ~ "RESPONSE", mcdu_white | mcdu_large));
                controllers[lsk('L')] = (func(mid) {
                        return SubmodeController.new(func (owner, parent) {
                            return CPDLCMessageModule.new(owner, parent, mid);
                        }, 2);
                })(me.replyID);
            }
            nextLine();
        }

        var color = mcdu_white;
        var lineSel = unevenLine;

        foreach (var part; me.elems) {
            var first = 1;
            foreach (var elem; part) {
                var val = elem.value;
                if (first) {
                    first = 0;
                    if (elem.type != 0) {
                        unevenLine();
                        append(views, StaticView.new(0, y, '/', mcdu_white));
                        nextLine();
                    }
                    else {
                        val = '/' ~ val;
                    }
                }

                if (elem.type == 0) {
                    lineSel = unevenLine;
                    color = mcdu_white;
                }
                else {
                    lineSel = evenLine;
                    color = mcdu_green | mcdu_large;
                }

                if (val == '') val = '----------------';
                var words = split(' ', val);
                var line = '';
                foreach (var word; words) {
                    if (size(line) == 0) {
                        while (size(word) > 24) {
                            lineSel();
                            append(views, StaticView.new(0, y, substr(word, 0, 22) ~ '..', color));
                            nextLine();
                            word = substr(word, 22);
                        }
                        line = word;
                    }
                    else {
                        if (size(line) + 1 + size(word) > 24) {
                            lineSel();
                            append(views, StaticView.new(0, y, line, color));
                            nextLine();
                            line = word;
                        }
                        else {
                            line = line ~ ' ' ~ word;
                        }
                    }
                }
                if (size(line) > 0) {
                    lineSel();
                    append(views, StaticView.new(0, y, line, color));
                    nextLine();
                }
            }
        }

        evenLine();
        if (me.replyID != nil and me.dir == 'down') {
            append(views, StaticView.new( 0, y, ">>>> RESPONSE ", mcdu_white | mcdu_large));
            append(views, StaticView.new(14, y, me.replyTimestamp, mcdu_green | mcdu_large));
            append(views, StaticView.new(18, y, "Z", mcdu_green));
            append(views, StaticView.new(19, y, " <<<<", mcdu_white | mcdu_large));
            nextLine();
        }

        if (me.ra != '' and me.status == 'OPEN') {
            evenLine(8);
            # The RA page
            if (me.ra == 'R') {
                append(views, StaticView.new( 0, y, left_triangle ~ 'UNABLE     ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-2', args: []}
                            , {type: 'SUPD-1', args: ['']}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                append(views, StaticView.new(12, y, '      ROGER' ~ right_triangle, mcdu_white));
                controllers[lsk('R')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-4', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                nextLine(); evenLine();
                append(views, StaticView.new( 0, y, left_triangle ~ 'STAND BY   ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-3', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });
            }
            elsif (me.ra == 'WU') {
                append(views, StaticView.new( 0, y, left_triangle ~ 'UNABLE     ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-2', args: []}
                            , {type: 'SUPD-1', args: ['']}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                append(views, StaticView.new(12, y, '      WILCO' ~ right_triangle, mcdu_white));
                controllers[lsk('R')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-1', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                nextLine(); evenLine();
                append(views, StaticView.new( 0, y, left_triangle ~ 'STAND BY   ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-3', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });
            }
            elsif (me.ra == 'AN') {
                append(views, StaticView.new( 0, y, left_triangle ~ 'NEGATIVE   ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-6', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                append(views, StaticView.new(12, y, 'AFFIRMATIVE' ~ right_triangle, mcdu_white));
                controllers[lsk('R')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-5', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                nextLine(); evenLine();
                append(views, StaticView.new( 0, y, left_triangle ~ 'STAND BY   ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-3', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });
            }
            elsif (me.ra == 'Y') {
                var left = 1;
                foreach (var reply; me.replies ~ [{type:'TXTD-1'}]) {
                    var replySpec = cpdlc.downlink_messages[reply.type];
                    if (replySpec == nil) continue;
                    var words = [];
                    if (reply.type == 'TXTD-1')
                        words = ['FREE', 'TEXT'];
                    else
                        words = split(' ', replySpec.txt);
                    var title = '';
                    foreach (var word; words) {
                        if (title != '')
                            title = title ~ ' ';
                        if (word[0] == '$')
                            word = '..';
                        if (size(title) + size(word) > 10) {
                            if (title == '')
                                title = substr(word, 0, 8) ~ '..';
                            break;
                        }
                        title = title ~ word;
                    }
                    var args = [];
                    if (reply['args'] == nil) {
                        foreach (var a; replySpec.args) {
                            append(args, '');
                        }
                    }
                    else {
                        foreach (var dnarg; reply.args) {
                            var a = dnarg;
                            var i = 1;
                            foreach (var uparg; me.parts[0].args) {
                                a = string.replace(a, '$' ~ i, uparg);
                                i += 1;
                            }
                            append(args, a);
                        }
                    }
                    var ctrl = (func (reply, args) { return SubmodeController.new(func (owner, parent) {
                            var parts = [{type: reply.type, args: args}];
                            if (substr(reply.type, 0, 3) != 'TXT')
                                append(parts, {type: 'TXTD-1', args: ['']});
                            return CPDLCComposeDownlinkModule.new(owner, parent, parts, self.min, self.station);
                        }); })(reply, args);
                    if (left) {
                        append(views, StaticView.new( 0, y, left_triangle ~ title, mcdu_white));
                        controllers[lsk('L')] = ctrl;
                        left = 0;
                    }
                    else {
                        append(views, StaticView.new(12, y, sprintf("%11s", title) ~ right_triangle, mcdu_white));
                        controllers[lsk('R')] = ctrl;
                        left = 1;
                        nextLine(); evenLine();
                    }
                }
            }
            # append(views, StaticView.new(12, y, '      APPLY' ~ right_triangle, mcdu_white));
            nextLine();
        }

        if (size(views))
            nextPage();
    },

    getTitle: func () {
        # spaces left to fit green timestamp
        if (me.dir == 'up') {
            return "        ATC UPLINK";
        }
        elsif (me.dir == 'pseudo') {
            return "        SYS MSG   ";
        }
        else {
            return "        REQUEST   ";
        }
    },

    getNumPages: func () {
        return size(me.pages);
    },

    loadPageItems: func (n) {
        if (n < size(me.pages)) {
            me.views = me.pages[n].views;
            me.controllers = me.pages[n].controllers;
        }
        else {
            me.views = [];
            me.controllers = {};
        }

        append(me.views, StaticView.new(3, 0, me.timestamp or '----', mcdu_green | mcdu_large));
        append(me.views, StaticView.new(7, 0, 'Z', mcdu_green));
        append(me.views, StaticView.new( 0, 12, left_triangle ~ "ATC INDEX", mcdu_white | mcdu_large));
        append(me.views, StaticView.new(20, 12, "LOG" ~ right_triangle, mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ATCINDEX", 0);
        me.controllers['R6'] = SubmodeController.new("ret");
    },
};

var ACARSLogModule = {
    new: func (mcdu, parentModule, dir) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ACARSLogModule, m.parents);
        m.listener = nil;
        m.title = dir ~ ' MSGS';
        m.historyNode = props.globals.getNode('/acars/telex/' ~ (dir == 'SENT' ? 'sent' : 'received'));
        m.dir = dir;
        return m;
    },

    getTitle: func () {
        return me.title;
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
            var item = refs[i];
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
        append(me.views, StaticView.new( 0, 12, left_triangle ~ "DATALINK", mcdu_white | mcdu_large));
        append(me.views, StaticView.new(14, 12, "CLEAR LOG" ~ right_triangle, mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ret");
        me.controllers['R6'] = FuncController.new(func (owner, val) {
            globals.hoppieAcars.system.clearHistory();
            return nil;
        });
    },
};

var ACARSPDCModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ACARSPDCModule, m.parents);
        return m;
    },

    getTitle: func () {
        return "PREDEP CLX RQ";
    },

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

            StaticView.new( 0, 12, left_triangle ~ "DATALINK", mcdu_white | mcdu_large),
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

    getTitle: func () {
        return "ACARS MSG";
    },

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

            StaticView.new( 0, 12, left_triangle ~ "DATALINK", mcdu_white | mcdu_large),
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
        m.lines = me.splitLines(m.msgNode.getValue('text'));
        m.dir = dir;
        debug.dump(m.lines);
        return m;
    },

    getTitle: func () {
        return me.title;
    },

    activate: func () {
        if (me.msgNode.getValue('status') == 'new')
            me.msgNode.setValue('status', '');
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
    },

    splitLines: func (text) {
        var words = split(' ', text);
        var lines = [];
        var line = '';
        foreach (var word; words) {
            if (line != '')
                line = line ~ ' ';
            if (size(line) + size(word) > 22) {
                if (line == '') {
                    append(lines, substr(word, 0, 20) ~ '..');
                }
                else {
                    append(lines, line);
                    if (size(word) > 22) {
                        append(lines, substr(word, 0, 20) ~ '..');
                        line = '';
                    }
                    else {
                        line = word;
                    }
                }
            }
            else {
                line = line ~ word;
            }
        }
        if (line != '')
            append(lines, line);
        return lines;
    },

    getNumPages: func () {
        return math.max(1, math.floor((size(me.lines) + 4) / 5));
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
            i = n * 5 - 1;
        }
        while (y < 11 and i < size(me.lines)) {
            append(me.views, StaticView.new( 0, y, me.lines[i], mcdu_green | mcdu_large));
            i += 1;
            y += 2;
        }
        append(me.views, StaticView.new( 0, 12, left_triangle ~ "LOG", mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ret");
    },
};

var TestModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(TestModule, m.parents);
        return m;
    },

    loadPageItems: func (n) {
        me.views = [];
        for (var c = 0; c < 7; c += 1) {
            append(me.views, StaticView.new(0, c * 2, sprintf("Color #%i", c), c));
            append(me.views, StaticView.new(8, c * 2, "REGULAR", c));
            append(me.views, StaticView.new(0, c * 2 + 1, "LARGE", mcdu_large | c));
            append(me.views, StaticView.new(8, c * 2 + 1, "REVERSE", mcdu_reverse | c));
            append(me.views, StaticView.new(16, c * 2 + 1, "BOTH", mcdu_large | mcdu_reverse | c));
        }
    },
};
