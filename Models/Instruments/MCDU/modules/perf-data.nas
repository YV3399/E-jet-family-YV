# AOM p. 1929
var PerfDataModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(PerfDataModule, m.parents);
        return m;
    },

    getNumPages: func () { return 3; },
    getTitle: func () { return "PERF DATA"; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(1, 1, "CRZ/CEIL ALT", mcdu_white),
                StaticView.new(15, 1, "STEP INC", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_white, "CRZ-ALT", 5,
                    "FL%03.0f", func (ft) { return sprintf(ft / 100); }),
                StaticView.new(5, 2, "/FL410", mcdu_large | mcdu_white),
                # FormatView.new(5, 2, mcdu_large | mcdu_white, "CEILING-ALT", 5,
                #     "/FL%03.0f", func (ft) { return sprintf(ft / 1000); }),
                StaticView.new(20, 2, "4000", mcdu_large | mcdu_white),

                # TODO: draw the rest of the f*** owl
            ];
            me.controllers = {
            };
        }
        else if (n == 1) {
            me.views = [
            ];

            me.controllers = {
            };
        }
        else if (n == 2) {
            me.views = [
            ];

            me.controllers = {
            };
        }
        append(me.views, StaticView.new(0, 12, left_triangle ~ "PERF INIT", mcdu_large | mcdu_white));
        append(me.views, StaticView.new(16, 12, "TAKEOFF" ~ right_triangle, mcdu_large | mcdu_white));
        me.controllers["L6"] = SubmodeController.new("PERFINIT", 0);
        me.controllers["R6"] = SubmodeController.new("PERF-TAKEOFF", 0);
    },
};


