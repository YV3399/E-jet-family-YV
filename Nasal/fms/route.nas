var currentRoute = nil;
var modifiedRoute = nil;

var findWaypoint = func (wpID, near=nil) {
    var candidates = [];
    if (near == nil) {
        near = geo.aircraft_position();
    }
    candidates = findFixesByID(near, wpID);
    if (candidates != nil and size(candidates) > 0) return candidates[0];
    candidates = findNavaidsByID(near, wpID, 'vor');
    if (candidates != nil and size(candidates) > 0) return candidates[0];
    candidates = findNavaidsByID(near, wpID, 'dme');
    if (candidates != nil and size(candidates) > 0) return candidates[0];
    candidates = findNavaidsByID(near, wpID, 'ndb');
    if (candidates != nil and size(candidates) > 0) return candidates[0];
    candidates = findAirportsByICAO(wpID);
    if (candidates != nil and size(candidates) > 0) return candidates[0];
    return nil;
};

var Route = {
    new: func (departureAirport=nil, destinationAirport=nil, routing=nil) {
        var m = {
            parents: [Route],
            legs: [],
            departureAirport: nil,
            destinationAirport: nil,
            sid: nil,
            sid_trans: nil,
            star: nil,
            star_trans: nil,
            closed: 0,
        };

        m.setDepartureAirport(departureAirport);
        m.setDestinationAirport(destinationAirport);

        if (routing != nil) {
            var first = 1;
            foreach (var pair; routing) {
                m.appendLeg(pair[0], pair[1]);
            }
        }

        return m;
    },

    setAirport: func(what, apt) {
        if (typeof(apt) == 'scalar') {
            var airports = findAirportsByICAO(apt);
            if (size(airports) > 0) {
                me[what] = airports[0];
                return me[what];
            }
            else {
                return nil;
            }
        }
        elsif (typeof(apt) == 'ghost') {
            me[what] = apt;
            return me[what];
        }
        else {
            return nil;
        }
    },

    setDepartureAirport: func(apt) {
        me.sid = nil;
        return me.setAirport('departureAirport', apt);
    },

    setDestinationAirport: func(apt) {
        me.star = nil;
        var airport = me.setAirport('destinationAirport', apt);
        if (airport != nil and size(me.legs) > 0) {
            var leg = me.legs[size(me.legs) - 1];
            me.closed = (leg.toID == airport.id);
        }
        else {
            closed = 0;
        }
    },

    clone: func () {
        var m = {
            parents: [Route],
            legs: [],
            departureAirport: me.departureAirport,
            destinationAirport: me.destinationAirport,
            sid: me.sid,
            sid_trans: me.sid_trans,
            star: me.star,
            star_trans: me.star_trans,
            closed: me.closed,
        };
        foreach (var leg; me.legs) {
            append(m.legs, leg);
        }
        return m;
    },

    isClosed: func () {
        if (size(me.legs) < 1) return 0;
        var lastLeg = me.legs[size(me.legs) - 1];
        if (lastLeg == nil) return 0;
        if (me.destinationAirport == nil) return 0;
        return (me.destinationAirport.id == lastLeg.toID);
    },

    makeLeg: func (airwayID, fromID, toID) {
        # debug.dump(airwayID, fromID, toID);
        var m = {
            airwayID: airwayID,
            fromID: fromID,
            from: nil,
            toID: toID,
            to: nil,
            segments: nil,
        };
        if (airwayID == nil) {
            # direct routing
            printf("%s DCT %s", fromID, toID);
            m.from = findWaypoint(fromID);
            # debug.dump('FROM', m.from);
            if (m.from == nil) return 'NO ROUTE';
            m.to = findWaypoint(toID, m.from);
            # debug.dump('TO', m.to);
            if (m.to == nil) return 'NO WAYPOINT';
            m.segments = [];
            m.airwayID = 'DCT';
        }
        else {
            var routing = fms.airwaysDB.findSegmentsFromTo(airwayID, fromID, toID);
            if (routing == nil or size(routing) == 0) {
                # Routing not found
                return 'NO ROUTE';
            }
            var last = size(routing) - 1;
            m.from = routing[0];
            m.to = routing[last];
            m.segments = subvec(routing, 1, size(routing) - 2);
        }
        # debug.dump('Created Leg', m);
        return m;
    },

    appendLeg: func (airwayID, toID) {
        var fromID = nil;
        var last = size(me.legs) - 1;
        # debug.dump(me.legs);
        printf("#legs = %i", last + 1);
        if (last >= 0) {
            fromID = me.legs[last].to.id;
        }
        elsif (me.departureAirport != nil) {
            fromID = me.departureAirport.id;
        }
        var leg = me.makeLeg(airwayID, fromID, toID);
        if (typeof(leg) == 'scalar') {
            return leg;
        }
        elsif (leg != nil) {
            append(me.legs, leg);
            if (me.destinationAirport != nil and toID == me.destinationAirport.id) {
                me.closed = 1;
            }
            return 'OK';
        }
        else {
            return 'NO ROUTE';
        }
    },

    deleteLeg: func (legi) {
        var legsOld = me.legs;
        me.legs = [];
        for (var i = 0; i < size(legsOld); i += 1) {
            if (i != legi) {
                append(me.legs, legsOld[i]);
            }
        }
    },

    toFlightplan: func(fp=nil) {
        if (fp == nil) {
            fp = createFlightplan();
        }
        fp.cleanPlan();

        var lastWPID = nil;

        fp.departure = me.departureAirport;
        fp.destination = nil;

        if (me.departureAirport != nil) {
            lastWPID = me.departureAirport.id;
        }
        foreach (var leg; me.legs) {
            printf("LEG: %s %s %s", leg.from.id, leg.airwayID, leg.to.id);
            if (leg.from.id != lastWPID) {
                printf("  -- DISCONTINUITY --");
                fp.appendWP(createDiscontinuity());
                printf("  WP: %s", leg.from.id);
                fp.appendWP(createWP(leg.from, leg.from.id));
                lastWPID = leg.from.id;
            }
            foreach (var segment; leg.segments) {
                printf("  WP: %s", segment.id);
                fp.appendWP(createWP(segment, segment.id));
            }
            if (me.destinationAirport != nil and leg.to.id != me.destinationAirport.id) {
                printf("  WP: %s", leg.to.id);
                fp.appendWP(createWP(leg.to, leg.to.id));
            }
            lastWPID = leg.to.id;
        }

        if (me.destinationAirport != nil and lastWPID != me.destinationAirport.id) {
            printf("  -- DISCONTINUITY --");
            fp.appendWP(createDiscontinuity());
        }

        fp.destination = me.destinationAirport;

        fp.sid = me.sid;
        fp.star = me.star;

        return fp;
    },

    getRouteString: func () {
        var items = [];
        var lastWPID = nil;

        if (me.departureAirport != nil) {
            append(items, me.departureAirport.id);
            lastWPID = me.departureAirport.id;
        }
        # TODO: SID

        foreach (var leg; me.legs) {
            if (leg.from.id != lastWPID) {
                append(items, '*DISCONTINUITY*', leg.from.id);
                lastWPID = leg.from.id;
            }
            if (leg.airwayID == nil) {
                append(items, 'DCT');
            }
            else {
                append(items, leg.airwayID);
            }
            append(items, leg.to.id);
            lastWPID = leg.to.id;
        }

        # TODO: STAR, transition, approach
        if (me.destinationAirport != nil) {
            if (me.destinationAirport.id != lastWPID) {
                append(items, '*DISCONTINUITY*');
                append(items, me.destinationAirport.id);
            }
        }
        return string.join(' ', items);
    },
};

setlistener('/fms/airways/loaded', func(node) {
    if (airwaysDB != nil) {
        print("AIRWAYS LOADED");
    }
});

var getRouteLegs = func (fp = nil) {
    if (fp == nil) {
        fp = flightplan();
    }
    var legs = [];
    var i = 1;
    var legName = nil;
    var legTarget = nil;

    var reportWaypoint = func (wp) {
        var pname = (wp.wp_parent == nil) ? '---' : wp.wp_parent.id;
        var ptype = (wp.wp_parent == nil) ? 'n/a' : wp.wp_parent.tp_type;
        var role = (wp.wp_role == nil) ? '---' : wp.wp_role;
        var type = (wp.wp_type == nil) ? '---' : wp.wp_type;

        printf("via %4s %-8s to %-6s (%s, %s)", ptype, pname, wp.id, role, type);
    };

    # first, walk through the departure procedures, if any.

    if (fp.sid != nil) {
        # forward to first waypoint on SID
        while (fp.getWP(i).wp_role != 'sid') {
            legTarget = fp.getWP(i);
            # reportWaypoint(fp.getWP(i));
            i += 1;
        }
        # forward to first waypoint after SID
        while (fp.getWP(i).wp_role == 'sid') {
            legTarget = fp.getWP(i);
            # reportWaypoint(fp.getWP(i));
            i += 1;
        }
        legName = fp.sid.id;
        if (fp.sid_trans != nil) {
            legName = legName ~ "." ~ fp.sid_trans.id;
        }
        append(legs, [legName, legTarget]);
        legName = nil;
        legTarget = nil;
    }

    for (; i < fp.getPlanSize(); i += 1) {
        var wp = fp.getWP(i);
        # reportWaypoint(wp);
        if (wp.wp_role == 'star' or wp.wp_role == 'approach' or wp.wp_role == 'missed' or wp.wp_role == 'runway') {
            break;
        }
        if (wp.wp_parent == nil) {
            if (legTarget != nil) {
                append(legs, [legName, legTarget]);
            }
            append(legs, ["DCT", wp]);
            legName = nil;
            legTarget = nil;
        }
        else if (wp.wp_parent.id != legName) {
            if (legTarget != nil) {
                append(legs, [legName, legTarget]);
            }
            legName = wp.wp_parent.id;
            legTarget = wp;
        }
        else {
            legTarget = wp;
        }
    }
    while (fp.getWP(i) != nil and fp.getWP(i).wp_type != 'runway') {
        i += 1;
        if (fp.getWP(i) != nil) {
            # reportWaypoint(fp.getWP(i));
        }
    }
    legName = '';
    if (fp.star != nil) {
        legName = legName ~ "." ~ fp.star.id;
    }
    else if (fp.star_trans != nil) {
        legName = legName ~ "." ~ fp.star_trans.id;
    }
    if (getApproachTrans(fp) != nil) {
        legName = legName ~ "." ~ getApproachTrans(fp).id;
    }
    if (fp.approach != nil) {
        legName = legName ~ "." ~ fp.approach.id;
    }
    if (legName == '') {
        legName = 'DCT';
    }
    else {
        legName = substr(legName, 1);
    }
    if (fp.getWP(i) != nil) {
        append(legs, [legName, fp.getWP(i)]);
    }
    return legs;
};

# Compatibility shim: approach_trans doesn't exist until FG 2020.2. We
# feature-test the presence of that ghost property by trying to read from it
# in a `call()`; if that fails, we just return nil.
var getApproachTrans = func (fp) {
    var result = nil;
    var err = [];
    call(
        func (fp) { result = fp.approach_trans; },
        [fp], nil, err);
    return result;
};
