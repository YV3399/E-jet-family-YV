var DirectToModule = {
    new: func (mcdu, parentModule, fp, directTo, directFromIndex=nil) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(DirectToModule, m.parents);
        m.fp = fp;
        m.directToIndex = nil;
        m.directToWP = nil;
        if (typeof(directTo) == 'scalar') {
            # Manually entered
            m.directToID = directTo;
            # var wp = nil;
            # var fst = math.max(1, fp.current);
            # for (var i = fst; i < fp.getPlanSize(); i += 1) {
            #     wp = fp.getWP(i);
            #     if (wp.id == m.directToID) {
            #         m.directToWP = wp;
            #         m.directToIndex = i;
            #         break;
            #     }
            # }
        }
        else {
            m.directToID = directTo.wp.id;
            m.directToWP = directTo.wp;
            m.directToIndex = directTo.index;
        }
        m.directFromIndex = directFromIndex;
        return m;
    },

    getNumPages: func () { return 1; },
    getTitle: func () { return "DIRECT-TO"; },

    loadPageItems: func (p) {
        me.views = [];
        me.controllers = {};
        append(me.views, StaticView.new(0, 2, left_triangle ~ "DIRECT", mcdu_large | mcdu_white));
        me.controllers["L1"] = FuncController.new(func (owner, val) { owner.insertDirect(); });
        if (me.directToIndex != nil) {
            append(me.views, StaticView.new(0, 4, left_triangle ~ "ACTIVE", mcdu_large | mcdu_white));
            append(me.views, StaticView.new(0, 6, left_triangle ~ "MISSED APPROACH", mcdu_large | mcdu_white));
            me.controllers["L2"] = FuncController.new(func (owner, val) { owner.insertActive(); });
            me.controllers["L3"] = FuncController.new(func (owner, val) { owner.insertActive(); });
            # TODO: Alternate flight plan
            # "L4": FuncController.new(func (owner, val) { owner.insertAlternate(); owner.mcdu.popModule(); }),
        }
        # NOT IMPLEMENTED YET
        # StaticView.new(0, 8, left_triangle ~ "ALTERNATE", mcdu_large | mcdu_white),
    },

    insertActive: func () {
        if (me.directFromIndex == nil) {
            var directWP = createWP(geo.aircraft_position(), "DIRECT");
            me.fp.insertWP(directWP, me.directToIndex);
            for (var i = 0; i < me.directToIndex; i += 1) {
                me.fp.deleteWP(0);
            }
            me.fp.getWP(0).setAltitude(getprop("/instrumentation/altimeter/indicated-altitude-ft"), 'at');
            me.fp.current = 1;
        }
        else {
            for (var i = me.directFromIndex + 1; i < me.directToIndex; i += 1) {
                me.fp.deleteWP(me.directFromIndex + 1);
            }
        }
        fms.kickRouteManager();
        me.mcdu.popModule();
    },

    doInsertDirect: func (newWP) {
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
        if (ghosttype(newWP) != 'waypoint' and ghosttype(newWP) != 'flightplan-leg') {
            newWP = createWPFrom(newWP);
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
        me.mcdu.popModule();
    },

    insertDirect: func () {
        var self = me;
        if (me.directToWP != nil) {
            me.doInsertDirect(me.directToWP);
        }
        else {
            var candidates = parseWaypoint(me.directToID, nil, 0);
            # debug.dump(me.directFromIndex, me.directToID, candidates);
            if (size(candidates) == 1) {
                var newWP = candidates[0];
                me.doInsertDirect(newWP);
            }
            elsif (size(candidates) > 1) {
                me.push(func (mcdu, parent) {
                    return WaypointSelectModule.new(mcdu, parent, candidates,
                        func (newWP) {
                            self.doInsertDirect(newWP);
                        },
                        func {
                            self.mcdu.popModule();
                        });
                });
            }
            else {
                me.mcdu.setScratchpadMsg("NO WAYPOINT", mcdu_yellow);
                me.mcdu.popModule();
            }
        }
    },
};


