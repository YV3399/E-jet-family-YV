var TakeoffDatasetModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(me, m.parents);
        return m;
    },

    getTitle: func () { return "T/O DATASET MENU"; },
    getNumPages: func () { return 1; },

    loadPageItems: func (n) {
        me.views = [
            FormatView.new(1, 1, mcdu_white, "TRS-TO1-NOMINAL", 4, "%02iK", func (val) { return math.floor((val + 0.5) / 1000); }),
            FormatView.new(4, 1, mcdu_white, "TRS-TO1-NOMINAL", 1, "%01i", func (val) { return math.floor(math.fmod((val + 0.5), 1000) / 100); }),
            RadioItemView.new(0,  2, "TO-TRS-MODE", "TO-1", 1),

            FormatView.new(1, 3, mcdu_white, "TRS-TO2-NOMINAL", 4, "%02iK", func (val) { return math.floor((val + 0.5) / 1000); }),
            FormatView.new(4, 3, mcdu_white, "TRS-TO2-NOMINAL", 1, "%01i", func (val) { return math.floor(math.fmod((val + 0.5), 1000) / 100); }),
            RadioItemView.new(0,  4, "TO-TRS-MODE", "TO-2", 2),

            FormatView.new(1, 5, mcdu_white, "TRS-TO3-NOMINAL", 4, "%02iK", func (val) { return math.floor((val + 0.5) / 1000); }),
            FormatView.new(4, 5, mcdu_white, "TRS-TO3-NOMINAL", 1, "%01i", func (val) { return math.floor(math.fmod((val + 0.5), 1000) / 100); }),
            RadioItemView.new(0,  6, "TO-TRS-MODE", "TO-3", 3),

            StaticView.new(1, 7, "T/O TEMP", mcdu_white),
            FormatView.new(1, 8, mcdu_white | mcdu_large, "TO-OAT", 5, "%3i C"),

            StaticView.new(18, 1, "ATTCS", mcdu_white),
            CycleView.new(17, 2, mcdu_green | mcdu_large, "TO-ATTCS", [0, 1], ['OFF', 'ON']),
            StaticView.new(23, 2, left_right_arrow, mcdu_white | mcdu_large),

            StaticView.new(16, 3, "REF ECS", mcdu_white),
            CycleView.new(17, 4, mcdu_green | mcdu_large, "TO-REF-ECS", [0, 1], ['OFF', 'ON']),
            StaticView.new(23, 4, left_right_arrow, mcdu_white | mcdu_large),

            StaticView.new(16, 5, "REF A/I", mcdu_white),
            CycleView.new(12, 6, mcdu_green | mcdu_large, "TO-REF-AI", [0, 1, 2], ['OFF', 'ENG', 'ALL']),
            StaticView.new(23, 6, left_right_arrow, mcdu_white | mcdu_large),

            StaticView.new(15, 7, "FLEX T/O", mcdu_white),
            CycleView.new(17, 8, mcdu_green | mcdu_large, "TO-FLEX", [0, 1], ['OFF', 'ON']),
            StaticView.new(23, 8, left_right_arrow, mcdu_white | mcdu_large),

            StaticView.new(14, 9, "FLEX TEMP", mcdu_white),
            FormatView.new(19, 10, mcdu_white | mcdu_large, "TO-FLEX-TEMP", 5, "%3i C"),

            StaticView.new(6, 12, "THRUST RATING SEL" ~ right_triangle, mcdu_white | mcdu_large),
        ];
        me.controllers = {
            "L1": SelectController.new("TO-TRS-MODE", 1, 0),
            "L2": SelectController.new("TO-TRS-MODE", 2, 0),
            "L3": SelectController.new("TO-TRS-MODE", 3, 0),
            "L4": DialController.new("TO-OAT", -50, 99, 1, 5),

            "R1": CycleController.new("TO-ATTCS", [0, 1]),
            "R2": CycleController.new("TO-REF-ECS", [0, 1]),
            "R3": CycleController.new("TO-REF-AI", [0, 1, 2]),
            "R4": CycleController.new("TO-FLEX", [0, 1]),
            "R5": DialController.new("TO-FLEX-TEMP", -50, 99, 1, 5),
            "R6": SubmodeController.new("TRS", 0),
        };
    },
};

