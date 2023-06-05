var TakeoffPerfModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(TakeoffPerfModule, m.parents);
        return m;
    },

    getNumPages: func () { return 3; },
    getTitle: func () { return "TAKEOFF"; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(1, 1, "RWY HDG", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_green, "TO-RUNWAY-HEADING", 3, "%03.0f"),

                StaticView.new(cells_x - 9, 1, "T.O. WGT", mcdu_white),
                FormatView.new(14, 2, mcdu_large | mcdu_green, "WGT-TO", 8, "%6.0f KG"),

                StaticView.new(1, 3, "OAT<---SURFACE--->WIND", mcdu_white),
                TemperatureView.new(0, 4, mcdu_large | mcdu_green, "TO-OAT"),
                FormatView.new(17, 4, mcdu_large | mcdu_green, "TO-WIND-DIR", 4, "%03.0f°/"),
                FormatView.new(22, 4, mcdu_large | mcdu_green, "TO-WIND-SPEED", 2, "%02.0f"),

                StaticView.new(1, 5, "P ALT/B SET       ELEV", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_white, "TO-PRESSURE-ALT", 5, "%4.0f/"),
                FormatView.new(5, 6, mcdu_large | mcdu_green, "TO-QNH", 5, "%4.0f"),
                FormatView.new(20, 6, mcdu_large | mcdu_green, "TO-RUNWAY-ELEVATION", 5, "%4.0f"),

                StaticView.new(1, 7, "RWY SLOPE         WIND", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_white, "TO-RUNWAY-SLOPE", 5, "%+3.1f°"),

                StaticView.new(1, 9, "RWY CONDITION", mcdu_white),
                CycleView.new(0, 10, mcdu_large | mcdu_green, "TO-RUNWAY-CONDITION",
                    [0, 1, 2, 3], ['DRY', 'WET', 'SNOW', 'ICE'], 1),

                StaticView.new(0, 12, left_triangle ~ "PERF DATA", mcdu_white | mcdu_large),
                StaticView.new(14, 12, "T.O. DATA" ~ right_triangle, mcdu_white | mcdu_large),
            ];
            me.controllers = {
                "L1": ValueController.new("TO-RUNWAY-HEADING"),
                "L2": ValueController.new("TO-OAT"),
                "L3": ValueController.new("TO-QNH"),
                "L4": ValueController.new("TO-RUNWAY-SLOPE"),
                "R1": ValueController.new("WGT-TO"),
                "R2": MultiModelController.new(["TO-WIND-DIR", "TO-WIND-SPEED"]),
                "R3": ValueController.new("TO-RUNWAY-ELEVATION"),
                "R5": CycleController.new("TO-RUNWAY-CONDITION", [0, 1, 2, 3]),
            };
        }
        else if (n == 1) {
            me.views = [
                StaticView.new(1, 1, "FLAPS", mcdu_white),
                CycleView.new(0, 2, mcdu_large | mcdu_green, "TO-FLAPS",
                    [0.125, 0.250, 0.375, 0.500],
                    { 0: "CLEAN", 0.125: "FLAP-1", 0.250: "FLAP-2", 0.375: "FLAP-3", 0.500: "FLAP-4" }, 1),
                StaticView.new(1, 3, "MODE", mcdu_white),
                CycleView.new(0, 4, mcdu_large | mcdu_green, "TO-TRS-MODE",
                    [1, 2, 3], ['----', 'TO-1', 'TO-2', 'TO-3']),
            ];
            me.controllers = {
                "R1": CycleController.new("TO-FLAPS", [0.125, 0.250, 0.375, 0.500]),
                "R2": CycleController.new("TO-TRS-MODE", [1,2,3]),
            };
        }
        else if (n == 2) {
            fms.update_departure_vspeeds();
            me.views = [
                StaticView.new(1, 1, "V1", mcdu_white),
                FormatView.new(0, 2, mcdu_large | mcdu_magenta, "DEP-EFF-V1", 3),
                StaticView.new(1, 3, "VR", mcdu_white),
                FormatView.new(0, 4, mcdu_large | mcdu_cyan, "DEP-EFF-VR", 3),
                StaticView.new(1, 5, "V2", mcdu_white),
                FormatView.new(0, 6, mcdu_large | mcdu_yellow, "DEP-EFF-V2", 3),
                StaticView.new(1, 7, "VFS", mcdu_white),
                FormatView.new(0, 8, mcdu_large | mcdu_green, "DEP-EFF-VFS", 3),
                StaticView.new(0, 10,left_triangle ~ "LANDING", mcdu_large | mcdu_white),
                StaticView.new(14, 9, "T/O PITCH", mcdu_white),
                FormatView.new(18, 10, mcdu_large | mcdu_green, "DEP-EFF-PITCH", 5, "%4.1f°"),
            ];
            me.controllers = {
                "L1": ValueController.new("DEP-SEL-V1"),
                "L2": ValueController.new("DEP-SEL-VR"),
                "L3": ValueController.new("DEP-SEL-V2"),
                "L4": ValueController.new("DEP-SEL-VFS"),
                "L5": SubmodeController.new("PERF-LANDING"),
                "R5": ValueController.new("DEP-SEL-PITCH"),
            };
        }
    },
};

