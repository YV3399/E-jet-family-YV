var PosInitModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(PosInitModule, m.parents);
        return m;
    },

    getTitle: func () { return "POSITION INIT"; },
    getShortTitle: func () { return "POS INIT"; },
    getNumPages: func () { return 1; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [];
            append(me.views,
                StaticView.new(1,  1, "LAST POS", mcdu_green),
                GeoView.new(0,  2, mcdu_large | mcdu_green, "LASTLAT",  "LAT"),
                GeoView.new(9,  2, mcdu_large | mcdu_green, "LASTLON",  "LON"),
                ToggleView.new(15, 1, mcdu_white, "POSLOADED", "(LOADED)", 0),
                ToggleView.new(19, 2, mcdu_large | mcdu_white, "LASTVALID", "LOAD" ~ right_triangle));

            append(me.views,
                FormatView.new(1,  3, mcdu_green, "REFID", 14, "%s REF WPT"),
                GeoView.new(0,  4, mcdu_large | mcdu_green, "REFLAT",  "LAT"),
                GeoView.new(9,  4, mcdu_large | mcdu_green, "REFLON",  "LON"),
                ToggleView.new(15, 3, mcdu_white, "POSLOADED", "(LOADED)", 1),
                ToggleView.new(19, 4, mcdu_large | mcdu_white, "REFVALID", "LOAD" ~ right_triangle));

            append(me.views,
                StaticView.new(        1,  5, "GPS1 POS",              mcdu_green),
                GeoView.new(0,  6, mcdu_large | mcdu_green, "GPSLAT",  "LAT"),
                GeoView.new(9,  6, mcdu_large | mcdu_green, "GPSLON",  "LON"),
                ToggleView.new(15, 5, mcdu_white, "POSLOADED", "(LOADED)", 2),
                StaticView.new(       19,  6, "LOAD" ~ right_triangle, mcdu_large | mcdu_white));

            me.controllers = {
                "L2": FuncController.new(func (mcdu, str) {
                            if (fms.findWaypointRef(str)) {
                                return 1;
                            }
                            else {
                                return nil;
                            }
                        }),
                "R1": SelectController.new("POSSELECTED", 0, 0),
                "R2": SelectController.new("POSSELECTED", 1, 0),
                "R3": SelectController.new("POSSELECTED", 2, 0),
            };

            if (me.ptitle != "POS SENSORS") {
                me.controllers["R6"] = SubmodeController.new("POS-SENSORS");
                append(me.views,
                     StaticView.new(23 - size("POS SENSORS"), 12, "POS SENSORS" ~ right_triangle, mcdu_large));
            }

            if (me.ptitle != nil) {
                me.controllers["L6"] = SubmodeController.new("ret");
                append(me.views,
                    StaticView.new(        0, 12, left_triangle ~ me.ptitle, mcdu_large | mcdu_white));
            }
        }
    },
};

