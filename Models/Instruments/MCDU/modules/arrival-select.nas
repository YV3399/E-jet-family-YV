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

