var RadioModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(RadioModule, m.parents);
        return m;
    },

    getNumPages: func () { return 2; },
    getTitle: func () { return "RADIOS"; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                FreqView.new(1, 2, mcdu_large | mcdu_green, "COM1A"),
                FreqView.new(1, 4, mcdu_large | mcdu_yellow, "COM1S"),
                FreqView.new(16, 2, mcdu_large | mcdu_green, "COM2A"),
                FreqView.new(16, 4, mcdu_large | mcdu_yellow, "COM2S"),

                FreqView.new(1, 6, mcdu_large | mcdu_green, "NAV1A"),
                FreqView.new(1, 8, mcdu_large | mcdu_yellow, "NAV1S"),
                FreqView.new(17, 6, mcdu_large | mcdu_green, "NAV2A"),
                FreqView.new(17, 8, mcdu_large | mcdu_yellow, "NAV2S"),

                FormatView.new(19, 10, mcdu_large | mcdu_green, "XPDRA", 4),

                ToggleView.new(8, 5, mcdu_large | mcdu_blue, "NAV1AUTO", "FMS"),
                ToggleView.new(8, 6, mcdu_large | mcdu_blue, "NAV1AUTO", "AUTO"),
                ToggleView.new(12, 5, mcdu_large | mcdu_blue, "NAV2AUTO", "FMS"),
                ToggleView.new(12, 6, mcdu_large | mcdu_blue, "NAV2AUTO", "AUTO"),

                CycleView.new(1, 12, mcdu_large | mcdu_green, "XPDRON",
                    [0, 1],
                    func (n) { return (n ? xpdrModeLabels[getprop(keyProps["XPDRMD"])] : "STBY"); }),

                StaticView.new(  1,  1, "COM1",                   mcdu_white ),
                StaticView.new(  0,  2, up_down_arrow,            mcdu_large | mcdu_white ),
                StaticView.new(  0,  4, left_triangle,            mcdu_large | mcdu_white ),

                StaticView.new( 19,  1, "COM2",                   mcdu_white ),
                StaticView.new( 23,  2, up_down_arrow,            mcdu_large | mcdu_white ),
                StaticView.new( 23,  4, right_triangle,           mcdu_large | mcdu_white ),

                StaticView.new(  1,  5, "NAV1",                   mcdu_white ),
                StaticView.new(  0,  6, up_down_arrow,            mcdu_large | mcdu_white ),
                StaticView.new(  0,  8, left_triangle,            mcdu_large | mcdu_white ),

                StaticView.new( 19,  5, "NAV2",                   mcdu_white ),
                StaticView.new( 23,  6, up_down_arrow,            mcdu_large | mcdu_white ),
                StaticView.new( 23,  8, right_triangle,           mcdu_large | mcdu_white ),

                StaticView.new( 19,  9, "XPDR",                   mcdu_white ),
                StaticView.new( 23, 10, right_triangle,           mcdu_large | mcdu_white ),
                StaticView.new( 18, 11, "IDENT",                  mcdu_white ),
                StaticView.new( 18, 12, "IDENT",                  mcdu_large | mcdu_white ),
                StaticView.new( 23, 12, black_square,             mcdu_large | mcdu_white ),

                StaticView.new(  0, 10, left_triangle ~ "TCAS/XPDR",              mcdu_large | mcdu_white ),
                StaticView.new(  0, 12, left_right_arrow,         mcdu_large | mcdu_white ),
            ];
            me.dividers = [0, 1, 3, 4];
            me.controllers = {
                "L1": PropSwapController.new("COM1A", "COM1S"),
                "L2": FreqController.new("COM1S", "COM1"),
                "L3": PropSwapController.new("NAV1A", "NAV1S"),
                "L4": FreqController.new("NAV1S", "NAV1"),
                "L5": SubmodeController.new("XPDR"),
                "L6": CycleController.new("XPDRON"),
                "R1": PropSwapController.new("COM2A", "COM2S"),
                "R2": FreqController.new("COM2S", "COM2"),
                "R3": PropSwapController.new("NAV2A", "NAV2S"),
                "R4": FreqController.new("NAV2S", "NAV2"),
                "R5": TransponderController.new("XPDRA", "XPDR"),
                "R6": TriggerController.new("XPDRID"),
            };
        }
        else if (n == 1) {
            me.views = [
                FreqView.new(1, 2, mcdu_large | mcdu_green, "ADF1A"),
                FreqView.new(1, 4, mcdu_large | mcdu_yellow, "ADF1S"),
                FreqView.new(18, 2, mcdu_large | mcdu_green, "ADF2A"),
                FreqView.new(18, 4, mcdu_large | mcdu_yellow, "ADF2S"),
                StaticView.new( 1, 1, "ADF1", mcdu_white ),
                StaticView.new( 0, 4, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new(19, 1, "ADF2", mcdu_white ),
                StaticView.new(23, 4, right_triangle, mcdu_white ),
            ];
            me.dividers = [0, 1, 2, 3, 4];
            me.controllers = {
                "L1": PropSwapController.new("ADF1A", "ADF1S"),
                "R1": PropSwapController.new("ADF2A", "ADF2S"),
                "L2": FreqController.new("ADF1S"),
                "R2": FreqController.new("ADF2S"),
            };
        }
    },
};

