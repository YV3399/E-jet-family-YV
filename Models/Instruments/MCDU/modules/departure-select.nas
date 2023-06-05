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

    getShortTitle: func () {
        if (me.mode == 0) {
            return "DEP RWY";
        }
        else if (me.mode == 1) {
            return "SIDS";
        }
        else if (me.mode == 2) {
            return "DEP TRANS";
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


