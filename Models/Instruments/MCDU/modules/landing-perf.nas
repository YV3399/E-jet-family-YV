var LandingPerfModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(LandingPerfModule, m.parents);
        return m;
    },

    getNumPages: func () { return 2; },
    getTitle: func () { return "LANDING"; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(1, 1, "RWY OAT", mcdu_white),
                TemperatureView.new(0, 2, mcdu_large | mcdu_green, "LANDING-OAT"),
                StaticView.new(cells_x - 8, 1, "LND WGT", mcdu_white),
                FormatView.new(14, 2, mcdu_large | mcdu_green, "WGT-LND", 8, "%-6.0f KG"),
                StaticView.new(1, 3, "APPROACH FLAP", mcdu_white),
                CycleView.new(0, 4, mcdu_large | mcdu_green, "APPR-FLAPS",
                    [0.250, 0.500], { 0.250: "FLAP-2", 0.500: "FLAP-4" }, 1),
                StaticView.new(1, 5, "LANDING FLAP", mcdu_white),
                CycleView.new(0, 6, mcdu_large | mcdu_green, "LANDING-FLAPS",
                    [0.625, 0.750], { 0.625: "FLAP-5", 0.750: "FLAP-FULL" }, 1),
                StaticView.new(1, 7, "ICE", mcdu_white),
                CycleView.new(0, 8, mcdu_large | mcdu_green, "LANDING-ICE",
                    [0, 1], ["NO", "YES"], 1),
                StaticView.new(1, 9, "APPROACH TYPE", mcdu_white),
                CycleView.new(0, 10, mcdu_large | mcdu_green, "APPROACH-CAT",
                    [0, 1, 2], ["NON-PRECISION", "CAT-I", "CAT-II", "CAT-III"], 1),
                StaticView.new(0, 12, left_triangle ~ "PERF DATA", mcdu_white | mcdu_large),
                StaticView.new(14, 12, "T.O. DATA" ~ right_triangle, mcdu_white | mcdu_large),
            ];
            me.controllers = {
                "L1": ModelController.new("LANDING-OAT"),
                "R1": ValueController.new("WGT-LND"),
                "R2": CycleController.new("APPR-FLAPS", [0.250, 0.500]),
                "R3": CycleController.new("LANDING-FLAPS", [0.625, 0.750]),
                "R4": CycleController.new("LANDING-ICE"),
                "R5": CycleController.new("APPROACH-CAT", [0,1,2]),
            };
        }
        else if (n == 1) {
            fms.update_approach_vspeeds();
            me.views = [
                StaticView.new(1, 1, "VREF", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_yellow, "APP-EFF-VREF", 3),
                StaticView.new(1, 3, "VAP", mcdu_white),
                FormatView.new(0, 4, mcdu_large | mcdu_cyan, "APP-EFF-VAPPR", 3),
                StaticView.new(1, 5, "VAC", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_magenta, "APP-EFF-VAC", 3),
                StaticView.new(1, 7, "VFS", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "APP-EFF-VFS", 3),
            ];
            me.controllers = {
                "L1": ValueController.new("APP-SEL-VREF"),
                "L2": ValueController.new("APP-SEL-VAPPR"),
                "L3": ValueController.new("APP-SEL-VAC"),
                "L4": ValueController.new("APP-SEL-VFS"),
            };
        }
    },
};

