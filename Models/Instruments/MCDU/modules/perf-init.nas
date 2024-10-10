var PerfInitModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(PerfInitModule, m.parents);
        return m;
    },

    getNumPages: func () { return 3; },
    getTitle: func () {
        return "PERFORMANCE INIT-KG";
    },
    getShortTitle: func () {
        return "PERF INIT";
    },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(1, 1, "ACFT TYPE", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_green, "ACMODEL", 11, "%-11s"),
                StaticView.new(17, 1, "TAIL #", mcdu_white),
                FormatView.new(12, 2, mcdu_large | mcdu_green, "TAIL", 11, "%11s"),

                StaticView.new(1, 3, "PERF MODE", mcdu_white),
                CycleView.new(0, 4, mcdu_large | mcdu_green, "PERF-MODE",
                    [1, 2, 0], ["FULL PERF", "CURRENT GS/FF", "PILOT SPD/FF"], 1),
                StaticView.new(1, 5, "CLIMB", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_green, "VCLB", 3, "%3.0f/"),
                FormatView.new(4, 6, mcdu_large | mcdu_green, "MCLB", 3, "%3.2fM"),
                StaticView.new(1, 7, "CRUISE", mcdu_white),
                CycleView.new(0, 8, mcdu_large | mcdu_green, "CRZ-MODE",
                    [0, 1, 2, 3], ["LRC", "MAX SPD", "MAX END", "MXR SPD"], 1),
                StaticView.new(1, 9, "DESCENT", mcdu_white),
                FormatView.new(0, 10, mcdu_large | mcdu_green, "VDES", 3, "%3.0f/"),
                FormatView.new(4, 10, mcdu_large | mcdu_green, "MDES", 3, "%3.2fM/"),
                FormatView.new(10, 10, mcdu_large | mcdu_green, "DES-FPA", 3, "%3.1f"),

                StaticView.new(0, 12, left_triangle ~ "DEP/APP SPD", mcdu_large | mcdu_white),
            ];

            me.controllers = {
                "R2": CycleController.new("PERF-MODE", [1, 2, 0]),
                "L3": MultiModelController.new(["VCLB", "MCLB"]),
                "R4": CycleController.new("CRZ-MODE", [0, 1, 2, 3]),
                "L5": MultiModelController.new(["VDES", "MDES", "DES-FPA"]),
                # "L6": SubmodeController.new("DEP-APP-SPD"),
            };
        }
        else if (n == 1) {
            me.views = [
                StaticView.new(1, 1, "STEP INCREMENT", mcdu_white),
                StaticView.new(1, 2, "4000", mcdu_large | mcdu_white),

                StaticView.new(1, 3, "FUEL RESERVE", mcdu_white),
                FormatView.new(0, 4, mcdu_large | mcdu_green, "FUEL-RESERVE", 3, "%4.0f KG"),
                StaticView.new(1, 5, "TO/LDG FUEL", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_green, "FUEL-TAKEOFF", 3, "%4.0f/"),
                FormatView.new(5, 6, mcdu_large | mcdu_green, "FUEL-LANDING", 3, "%1.0f KG"),
                StaticView.new(1, 7, "CONTINGENCY FUEL", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "FUEL-CONTINGENCY", 3, "%4.0f KG"),
            ];

            me.controllers = {
                "L2": ModelController.new("FUEL-RESERVE"),
                "L3": MultiModelController.new(["FUEL-TAKEOFF", "FUEL-LANDING"]),
                "L4": ModelController.new("FUEL-CONTINGENCY"),
            };
        }
        else if (n == 2) {
            me.views = [
                StaticView.new(1, 1, "TRANS ALT", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_green, "TRANSALT", 5, "%5.0f"),
                StaticView.new(12, 1, "SPD/ALT LIM", mcdu_white),
                FormatView.new(15, 2, mcdu_large | mcdu_green, "VCLBLO", 3, "%3.0f/"),
                FormatView.new(19, 2, mcdu_large | mcdu_green, "CLBLOALT", 3, "%5.0f"),
                StaticView.new(1, 3, "INIT CRZ ALT", mcdu_white),
                FormatView.new(0, 4, mcdu_large | mcdu_green, "CRZ-ALT",
                    5, "FL%03.0f", func(val) { return val / 100; }),
                StaticView.new(16, 3, "ISA DEV", mcdu_white),
                StaticView.new(20, 4, "+0°C", mcdu_large | mcdu_white),
                StaticView.new(1, 5, "CRZ WINDS", mcdu_white),
                StaticView.new(12, 5, "AT ALTITUDE", mcdu_white),
                StaticView.new(1, 7, "ZFW", mcdu_white),
                StaticView.new(11, 7, "(GAUGE) FUEL", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "WGT-ZF", 5, "%5.0f"),
                FormatView.new(11, 8, mcdu_green, "FUEL-CUR", 7, "(%1.0f)"),
                FormatView.new(19, 8, mcdu_large | mcdu_green, "FUEL-CUR", 5, "%5.0f"),
                StaticView.new(15, 9, "GROSS WT", mcdu_white),
                FormatView.new(19, 10, mcdu_large | mcdu_green, "WGT-CUR", 5, "%5.0f", func (lbs) { return lbs * LB2KG; }),

                StaticView.new(0, 12, left_triangle ~ "DEP/APP", mcdu_large | mcdu_white),
                StaticView.new(11, 12, "CONFIRM INIT" ~ right_triangle, mcdu_large | mcdu_white),
            ];

            me.controllers = {
                "L1": ModelController.new("TRANSALT"),
                "L2": ModelController.new("CRZ-ALT", func (val) {
                    if (val < 1000) {
                        return val * 100;
                    }
                    else {
                        return val;
                    }
                }),
                "R1": MultiModelController.new(["VCLBLO", "CLBLOALT"]),
                "R6": FuncController.new(func (owner, val) {
                    setprop("/fms/performance-initialized", 1);
                    owner.mcdu.sidestepModule("PERFDATA");
                }),
            };
        }
    },
};


