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
