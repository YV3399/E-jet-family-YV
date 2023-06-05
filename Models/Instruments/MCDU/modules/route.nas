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
        me.unloadPage();
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

