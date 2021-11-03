var currentRoute = nil;
var modifiedRoute = nil;

var findWaypoint = func (wpID, near=nil) {
    var candidates = [];
    if (near == nil) {
        near = geo.aircraft_position();
    }
    candidates = findFixesByID(near, wpID);
    if (candidates != nil and size(candidates) > 0) return candidates[0];
    candidates = findNavaidsByID(near, wpID);
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
        };

        if (typeof(departureAirport) == 'scalar') {
            var airports = findAirportsByICAO(departureAirport);
            if (size(airports) > 0) {
                m.departureAirport = airports[0];
            }
        }
        elsif (typeof(departureAirport) == 'ghost') {
            m.departureAirport = departureAirport;
        }
        if (typeof(destinationAirport) == 'scalar') {
            var airports = findAirportsByICAO(destinationAirport);
            if (size(airports) > 0) {
                m.destinationAirport = airports[0];
            }
        }
        elsif (typeof(destinationAirport) == 'ghost') {
            m.destinationAirport = destinationAirport;
        }

        if (routing != nil) {
            var first = 1;
            foreach (var pair; routing) {
                m.appendLeg(pair[0], pair[1]);
            }
        }

        return m;
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
            debug.dump('FROM', m.from);
            if (m.from == nil) return nil;
            m.to = findWaypoint(toID, m.from);
            debug.dump('TO', m.to);
            if (m.to == nil) return nil;
            m.segments = [];
            m.airwayID = 'DCT';
        }
        else {
            var routing = fms.airwaysDB.findSegmentsFromTo(airwayID, fromID, toID);
            if (routing == nil or size(routing) == 0) {
                # Routing not found
                return nil;
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
        printf("Append leg: %s %s %s", fromID, airwayID, toID);
        var leg = me.makeLeg(airwayID, fromID, toID);
        if (leg != nil) {
            append(me.legs, leg);
        }
        printf("Appended leg: %s %s %s", fromID, airwayID, toID);
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
    print("ROUTE TEST");
    if (airwaysDB == nil) {
        print("ROUTE TEST: AIRWAYS NOT LOADED YET");
    }
    else {
        print("ROUTE TEST: AIRWAYS LOADED, MAKING TEST ROUTE");
        var testRoute =
            Route.new(
                    'EHAM',
                    'EDDM',
                    [
                        [nil, 'ARNEM'],
                        ['L620', 'SONEB'],
                        ['Z841', 'BIGSU'],
                        ['L603', 'BOMBI'],
                        ['T104', 'ROKIL'],
                        [nil, 'EDDM'],
                    ]
                );
        print("ROUTE TEST: TEST ROUTE DONE");
        print('TEST ROUTE: ' ~ testRoute.getRouteString());
        var fp = testRoute.toFlightplan();
        printf("%3i waypoints", fp.getPlanSize());
        for (var i = 0; i < fp.getPlanSize(); i += 1) {
            var wp = fp.getWP(i);
            printf('%3i %s', i, wp.id);
        }
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
