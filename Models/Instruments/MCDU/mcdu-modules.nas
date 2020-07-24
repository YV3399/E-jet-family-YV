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
            if (controller != nil) {
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

var FlightPlanModule = {
    new: func (mcdu, parentModule, specialMode = nil) {
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

    finishEditing: func () {
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

    getRoute: func () {
        return fms.Route.new(me.fp);
    },

    getNumPages: func () {
        if (me.specialMode == 'ROUTE') {
            var numEntries = size(me.getRoute().getLegs());
            # one extra page at the beginning, one extra entry for the
            # destination.
            return math.max(1, math.ceil((numEntries + 1) / 5)) + 1;
        }
        else {
            var numEntries = me.fp.getPlanSize();
            var firstEntry = me.fp.current - 1;
            return math.max(1, math.ceil((numEntries - firstEntry) / 5));
        }
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
        return me.fpStatus ~ ((me.specialMode == 'ROUTE') ? " RTE" : " FLT PLAN");
    },

    findWaypointByID: func (wpid) {
        var fst = math.max(0, me.fp.current);

        for (var i = fst; i < me.fp.getPlanSize(); i += 1) {
            var wp = me.fp.getWP(i);
            if (wp.id == wpid) {
                return wp;
            }
        }
        return nil;
    },

    findLastEnrouteWP: func () {
        if (me.fp == nil) return 0;
        var result = 0;
        for (var i = 1; i < me.fp.getPlanSize(); i += 1) {
            var wp = me.fp.getWP(i);
            if (wp.wp_parent == nil and wp.wp_type != "runway") {
                result = i;
            }
        }
        return result;
    },

    appendViaTo: func (viaTo) {
        printf("Append VIA-TO: %s", viaTo);
        var s = split('.', viaTo);
        debug.dump(s);
        var newWaypoints = [];
        var appendIndex = me.findLastEnrouteWP();
        var refWP = me.fp.getWP(appendIndex);
        var ref = geo.aircraft_position();
        printf("Append after: %i (%s)", appendIndex, (refWP == nil) ? "<nil>" : refWP.id);
        if (refWP != nil) {
            ref = refWP;
        }
        if (size(s) == 1) {
            var candidates = findNavaidsByID(ref, s[0]);
            if (size(candidates) > 0) {
                me.startEditing();
                var wp = createWP(candidates[0], candidates[0].id);
                me.fp.insertWP(wp, appendIndex);
                printf("Insert %s at %i", candidates[0].id, appendIndex);
            }
            else {
                me.mcdu.setScratchpadMsg("NO WAYPOINT", mcdu_yellow);
            }
        }
        else if (size(s) == 2) {
            # TODO: figure out via-to routing
            var awy = airway(s[0], ref);
        }
    },

    deleteWP: func (wpi) {
        if (wpi > 0) {
            me.fp.deleteWP(wpi);
        }
    },

    loadPageItems: func (p) {
        if (me.specialMode == 'ROUTE') {
            me.loadPageItemsRTE(p);
        }
        else {
            me.loadPageItemsFPL(p);
        }
    },

    loadPageItemsRTE: func (p) {
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
            var route = me.getRoute();
            var waypoints = route.getLegs();
            var numWaypoints = size(waypoints);
            var firstWP = (p - 1) * 5;
            me.views = [];
            me.controllers = {};
            append(me.views, StaticView.new(1, 1, "VIA", mcdu_white));
            append(me.views, StaticView.new(21, 1, "TO", mcdu_white));
            var y = 2;
            for (var i = 0; i < 5; i += 1) {
                var lsk = sprintf("R%i", i + 1);
                var wp = nil;
                var j = firstWP + i;
                if (j < size(waypoints)) {
                    wp = waypoints[j];
                }
                if (wp == nil) {
                    append(me.views, StaticView.new(0, y, "-----", mcdu_green | mcdu_large));
                    me.controllers[lsk] =
                        FuncController.new(
                            func (owner, val) { owner.appendViaTo(val); });
                    break;
                }
                else {
                    append(me.views, StaticView.new(0, y, (wp[0] == "DCT") ? "DIRECT" : wp[0], mcdu_green | mcdu_large));
                    append(me.views, StaticView.new(12, y, sprintf("%12s", wp[1].id), mcdu_green | mcdu_large));
                }
                y += 2;
            }
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

    loadPageItemsFPL: func (p) {
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
                else {
                    var color = mcdu_yellow;
                    if (wpi != firstEntry) {
                        color = mcdu_green;
                        append(me.views, StaticView.new(1, y, sprintf("%3d°", wp.leg_bearing), mcdu_green));
                        var distFormat = (wp.leg_distance < 100) ? "%5.1fNM" : "%5.0fNM";
                        append(me.views, StaticView.new(6, y, sprintf(distFormat, wp.leg_distance), mcdu_green));
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

                append(me.views,
                    StaticView.new(
                        13, y + 1,
                        formatRestrictions(wp, transitionAlt, 1),
                        mcdu_cyan | mcdu_large));

                if (me.specialMode == "FLYOVER") {
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
                else if (me.specialMode == "HOLD") {
                    # TODO
                    me.mcdu.setScratchpadMsg("NOT IMPLEMENTED", mcdu_red);
                }
                else if (wpi == firstEntry) {
                    var this = me;
                    me.controllers[lsk] = FuncController.new(func(owner, val) {
                        owner.startEditing();
                        var directToModule = func (mcdu, parent) {
                            return DirectToModule.new(mcdu, parent, this.fp, val);
                        };
                        owner.mcdu.pushModule(directToModule);
                    });
                }
                else {
                    me.controllers[lsk] = (func (wp) {
                        return FuncController.new(
                            func (owner, val) {
                                if (val == nil) {
                                    owner.mcdu.setScratchpad(wp.id);
                                }
                            },
                            func (owner) {
                                var wpi = owner.fp.indexOfWP(wp);
                                owner.startEditing();
                                owner.deleteWP(wpi);
                            }
                        );
                    })(wp);
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
    new: func (mcdu, parentModule, fp, directToID) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(DirectToModule, m.parents);
        m.fp = fp;
        m.directToID = directToID;
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
        me.views = [
            StaticView.new(0, 2, left_triangle ~ "DIRECT", mcdu_large | mcdu_white),
            StaticView.new(0, 4, left_triangle ~ "ACTIVE", mcdu_large | mcdu_white),
            StaticView.new(0, 6, left_triangle ~ "MISSED APPROACH", mcdu_large | mcdu_white),
            StaticView.new(0, 8, left_triangle ~ "ALTERNATE", mcdu_large | mcdu_white),
        ];

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
        me.fp.current = 1;
    },

    insertDirect: func () {
        var candidates = findNavaidsByID(me.directToID);
        # debug.dump(me.directToID, candidates);
        if (size(candidates) > 0) {
            var directWP = createWP(geo.aircraft_position(), "DIRECT");
            var newWP = candidates[0];
            me.fp.insertWP(directWP, me.directToIndex);
            me.fp.insertWP(newWP, me.directToIndex + 1);
            me.fp.insertWP(createDiscontinuity(), me.directToIndex + 2);
            for (var i = 0; i < me.directToIndex; i += 1) {
                me.fp.deleteWP(0);
            }
            me.fp.current = 1;
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
        if (me.page == 1) {
            return "PERFORMANCE INIT-KG";
        }
        else {
            return "PERFORMANCE INIT   ";
        }
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
                FormatView.new(4, 6, mcdu_large | mcdu_green, "FUEL-LANDING", 3, "%-3.0fKG"),
                StaticView.new(1, 7, "CONTINGENCY FUEL", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "FUEL-CONTINGENCY", 3, "%3.0fKG"),
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
                FormatView.new(15, 2, mcdu_white, "WGT-TO", 8, "%6.0fLB"),

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
                    { 0.124: "FLAP-1", 0.250: "FLAP-2", 0.375: "FLAP-3", 0.500: "FLAP-4" }, 1),
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
            me.views = [
                StaticView.new(1, 1, "V1", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_magenta, "V1", 3),
                StaticView.new(1, 3, "VR", mcdu_white),
                FormatView.new(0, 4, mcdu_large | mcdu_cyan, "VR", 3),
                StaticView.new(1, 5, "V2", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_yellow, "V2", 3),
                StaticView.new(1, 7, "VFS", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "VFS", 3),
                StaticView.new(0, 10,left_triangle ~ "LANDING", mcdu_large | mcdu_white),
            ];
            me.controllers = {
                "L1": ValueController.new("V1"),
                "L2": ValueController.new("VR"),
                "L3": ValueController.new("V2"),
                "L4": ValueController.new("VFS"),
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
                # TemperatureView.new(0, 2, "OAT-TO", mcdu_white),
                StaticView.new(0, 2, "+??°C/+??°F", mcdu_white),
                StaticView.new(cells_x - 8, 1, "LND WGT", mcdu_white),
                FormatView.new(15, 2, mcdu_white, "WGT-LND", 8, "%6.0fLB"),
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
                "R2": CycleController.new("APPR-FLAPS", [0.250, 0.500]),
                "R3": CycleController.new("LANDING-FLAPS", [0.625, 0.750]),
                "R4": CycleController.new("LANDING-ICE"),
                "R5": CycleController.new("APPROACH-CAT", [0,1,2]),
            };
        }
        else if (n == 1) {
            me.views = [
                StaticView.new(1, 1, "VREF", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_yellow, "VREF", 3),
                StaticView.new(1, 3, "VAP", mcdu_white),
                FormatView.new(0, 4, mcdu_large | mcdu_cyan, "VAP", 3),
                StaticView.new(1, 5, "VAC", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_magenta, "VAC", 3),
                StaticView.new(1, 7, "VFS", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "VFS", 3),
            ];
            me.controllers = {
                "L1": ValueController.new("VREF"),
                "L2": ValueController.new("VAP"),
                "L3": ValueController.new("VAC"),
                "L4": ValueController.new("VFS"),
            };
        }
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
        m.items = items;
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
        var airport = fp.destination;
        if (airport == nil) {
            me.mcdu.setScratchpadMsg("NO AIRPORT", mcdu_yellow);
        }
        else {
            var runway = fp.destination.runways[rwyID];
            if (runway == nil) {
                me.mcdu.setScratchpadMsg("NO RUNWAY", mcdu_yellow);
            }
            else {
                fp.destination_runway = runway;
            }
        }
        me.fullRedraw();
    },

    selectApproach: func (approachID) {
        var fp = fms.getModifyableFlightplan();
        if (fp.destination == nil) {
            me.mcdu.setScratchpadMsg("NO DESTINATION", mcdu_yellow);
        }
        else {
            var approach = fp.destination.getIAP(approachID);
            if (approach == nil) {
                me.mcdu.setScratchpadMsg("NO APPROACH", mcdu_yellow);
            }
            else {
                fp.approach = approach;
            }
        }
        me.fullRedraw();
    },

    selectStar: func (starID) {
        var fp = fms.getModifyableFlightplan();
        if (fp.destination == nil) {
            me.mcdu.setScratchpadMsg("NO DESTINATION", mcdu_yellow);
        }
        else {
            var star = fp.destination.getStar(starID);
            if (star == nil) {
                me.mcdu.setScratchpadMsg("NO STAR", mcdu_yellow);
            }
            else {
                fp.star = star;
            }
        }
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
                var appr = fp.star;
                if (appr == nil) {
                    return "<<NONE>>";
                }
                else {
                    return appr.id;
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


        me.views = [
            StaticView.new(16, 1, "AIRPORT", mcdu_white),
            FormatView.new(20, 2, mcdu_large | mcdu_green, airportModel, 4),
            StaticView.new(0, 2, left_triangle ~ "RUNWAY", mcdu_white),
            FormatView.new(1, 3, mcdu_large | mcdu_green, runwayModel, 4, "%-4s"),
            StaticView.new(0, 4, left_triangle ~ "APPROACH", mcdu_white),
            FormatView.new(1, 5, mcdu_large | mcdu_green, approachModel, 12, "%-12s"),
            StaticView.new(0, 6, left_triangle ~ "STAR", mcdu_white),
            FormatView.new(1, 7, mcdu_large | mcdu_green, starModel, 12, "%-12s"),
            StaticView.new(17, 12, "INSERT" ~ right_triangle, mcdu_large | mcdu_white),
        ];
        me.controllers = {
            "R6": SubmodeController.new("FPL"),
            "L1": SubmodeController.new(
                    func (mcdu, parent) {
                        var fp = fms.getVisibleFlightplan();
                        var airport = fp.destination;
                        var runway = fp.destination_runway;
                        var runwayID = (runway == nil) ? nil : runway.id;
                        var runways = (airport == nil) ? [] : keys(airport.runways);
                        return SelectModule.new(mcdu, parent,
                            airport.id ~ " RUNWAY", runways,
                            func (rwy) {
                                parent.selectRunway(rwy);
                                mcdu.popModule();
                            }, nil, runwayID);
                        },
                    1),
            "L2": SubmodeController.new(
                    func (mcdu, parent) {
                        var fp = fms.getVisibleFlightplan();
                        var airport = fp.destination;
                        var runway = fp.destination_runway;
                        var approach = fp.approach;
                        var approachID = (approach == nil) ? nil : approach.id;
                        var approaches = (runway == nil) ? airport.getApproachList() : airport.getApproachList(runway.id);
                        return SelectModule.new(mcdu, parent,
                            airport.id ~ " APPROACH", approaches,
                            func (appr) {
                                parent.selectApproach(appr);
                                mcdu.popModule();
                            }, nil, approachID);
                        },
                    1),
            "L3": SubmodeController.new(
                    func (mcdu, parent) {
                        var fp = fms.getVisibleFlightplan();
                        var airport = fp.destination;
                        var runway = fp.destination_runway;
                        var star = fp.star;
                        var starID = (star == nil) ? nil : star.id;
                        var stars = (runway == nil) ? airport.stars() : airport.stars(runway.id);
                        return SelectModule.new(mcdu, parent,
                            airport.id ~ " STAR", stars,
                            func (appr) {
                                parent.selectStar(appr);
                                mcdu.popModule();
                            }, nil, starID);
                        },
                    1),
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
            var currentTrans = nil;
            me.items = [];
            if (sid != nil and apt != nil and runway != nil) {
                foreach (var transition; sid.transitions) {
                    append(me.items, transition.id);
                }
                me.subtitle = apt.id ~ " RWY" ~ runway.id ~ " " ~ sid.id;
                if (currentTrans == nil) {
                    me.selectedItem = nil;
                }
                else {
                    me.selectedItem = currentTrans.id;
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
    },

    setSid: func (sidID) {
        var fp = fms.getModifyableFlightplan();
        var apt = fp.departure;
        if (apt == nil) return;
        var sid = apt.getSid(sidID);
        if (sid == nil) return;
        fp.sid = sid;
    },

    setTransition: func (transitionID) {
        # TODO: this will only work on FG 2020.2 and beyond
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
                FormatView.new( 3, 2, mcdu_large | mcdu_cyan, "ZMON", 3, "%3s",
                    [ "XXX", "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" ]),
                FormatView.new( 6, 2, mcdu_large | mcdu_cyan, "ZYEAR", 2, "%02d",
                    func (y) { return math.mod(y, 100); }),
                StaticView.new( 2,  3, "UTC", mcdu_white),
                FormatView.new( 1, 4, mcdu_large | mcdu_cyan, "ZHOUR", 2, "%02d"),
                FormatView.new( 3, 4, mcdu_large | mcdu_cyan, "ZMIN", 2, "%02d"),
                StaticView.new( 5,  4, "Z", mcdu_cyan),
                StaticView.new( 2,  5, "SW", mcdu_white),
                FormatView.new( 1,  6, mcdu_large | mcdu_green, "FGVER", 10, "%-10s"),
                StaticView.new(11,  5, "NDS", mcdu_white),
                StaticView.new(15,  5, "V3.01 16M", mcdu_green),
                StaticView.new(12,  6, "WORLD3-301", mcdu_large | mcdu_green),
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
                StaticView.new(  0, 12, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new(  1, 12, "MEMORY", mcdu_large | mcdu_white ),
            ];
            me.controllers = {
                "L1": PropSwapController.new("COM" ~ me.radioNum ~ "S", "COM" ~ me.radioNum ~ "A"),
                "L2": FreqController.new("COM" ~ me.radioNum ~ "S"),
            };
            if (me.ptitle != nil) {
                me.controllers["R6"] = SubmodeController.new("ret");
                append(me.views,
                     StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
            }
        }
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
