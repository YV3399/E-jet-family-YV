var TRSModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(me, m.parents);
        return m;
    },

    getTitle: func () { return "THRUST RATING SELECT"; },
    getNumPages: func () { return 1; },

    loadPageItems: func (n) {
        me.views = [
            RadioItemView.new(0,  2, "TRS-MODE-SEL", "AUTO", "AUTO"),
            FormatView.new(6, 2, mcdu_white | mcdu_large, "TRS-THRUST-LIMIT", 6, "%5.1f%%"),

            RadioItemView.new(0,  4, "TRS-MODE-SEL", "TOGA", func (val) { return (val == "TO" or val == "GA"); }),
            FormatView.new(6, 4, mcdu_white | mcdu_large, "TRS-THRUST-TO", 6, "%5.1f%%"),

            RadioItemView.new(0,  6, "TRS-MODE-SEL", "CON", "CON"),
            FormatView.new(6, 6, mcdu_white | mcdu_large, "TRS-THRUST-CON", 6, "%5.1f%%"),

            RadioItemView.new(0,  8, "TRS-MODE-SEL", "CLB", "CLB"),
            FormatView.new(6, 8, mcdu_white | mcdu_large, "TRS-THRUST-CLB", 6, "%5.1f%%"),

            RadioItemView.new(0, 10, "TRS-MODE-SEL", "CRZ", "CRZ"),
            FormatView.new(6, 10, mcdu_white | mcdu_large, "TRS-THRUST-CRZ", 6, "%5.1f%%"),

            FormatView.new(13, 2, mcdu_green | mcdu_large, "TRS-MODE", 6, "[%-4s]", getTRSModeName),

            CycleView.new(14, 4, mcdu_green | mcdu_large, "TRS-CLIMB-MODE-SEL", [1, 2], ['', 'CLB1', 'CLB2']),
            StaticView.new(23, 4, left_right_arrow, mcdu_white | mcdu_large),
            CycleView.new(14, 6, mcdu_green | mcdu_large, "TRS-CLIMB-MODE-SEL", [1, 2],
                [
                    '',
                    sprintf('%4.1f', getprop('/trs/thrust/climb1')),
                    sprintf('%4.1f', getprop('/trs/thrust/climb2')),
                ]),

            StaticView.new(12, 12, "TO DATA SET" ~ right_triangle, mcdu_white | mcdu_large),
        ];
        me.controllers = {
            "L1": SelectController.new("TRS-MODE-SEL", "AUTO", 0),
            "L2": SelectController.new("TRS-MODE-SEL", "TO", 0),
            "L3": SelectController.new("TRS-MODE-SEL", "CON", 0),
            "L4": SelectController.new("TRS-MODE-SEL", "CLB", 0),
            "L5": SelectController.new("TRS-MODE-SEL", "CRZ", 0),

            "R2": CycleController.new("TRS-CLIMB-MODE-SEL", [1, 2]),
        };
    },
};
