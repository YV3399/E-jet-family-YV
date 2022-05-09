var CurrentGsFfMode = {
    new: func () {
        return {
            parents: [CurrentGsFfMode],
            groundspeed: 120,
            info: nil,
        };
    },

    init: func(info) {
        me.groundspeed = math.max(120, info.groundspeed);
        me.info = info;
    },

    estimateWaypoint: func(dist) {
        var delta_dist = dist - me.info.dist;
        var te = delta_dist / me.groundspeed * 3600;
        return {
            # ETA is current time +/- est. time to/from waypoint
            ta: me.info.time + te,

            # EFOB is current FOB +/- est. fuel burn to/from waypoint
            fob: me.info.fob - te * me.info.ff
        };
    },

};
