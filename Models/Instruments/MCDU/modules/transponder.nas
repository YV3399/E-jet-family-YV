var TransponderModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(TransponderModule, m.parents);
        return m;
    },

    getNumPages: func () { return 2; },
    getTitle: func () { return "TCAS/XPDR"; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                FormatView.new(1, 2, mcdu_large |  mcdu_green, "XPDRA", 4),
                FormatView.new(1, 4, mcdu_large | mcdu_yellow, "XPDRS", 4),
                FormatView.new(18, 2, mcdu_large | mcdu_green, "PALT", 5, "%5.0f"),
                StringView.new(17, 4, mcdu_large | mcdu_green, "FLTID", 6),
                StaticView.new(  1,  1, "ACTIVE",                 mcdu_white ),
                StaticView.new(  0,  2, up_down_arrow,            mcdu_large | mcdu_white ),
                StaticView.new(  1,  3, "PRESET",                 mcdu_white ),
                StaticView.new(  0,  4, left_triangle,            mcdu_large | mcdu_white ),
                StaticView.new( 11,  1, "PRESSURE ALT",           mcdu_white ),
                StaticView.new( 17,  3, "FLT ID",                 mcdu_white ),
                StaticView.new( 23,  4, right_triangle,           mcdu_large | mcdu_white ),
                StaticView.new( 19,  5, "FREQ",                   mcdu_white ),
                StaticView.new(  1,  9, "XPDR SEL",               mcdu_large | mcdu_white ),
                StaticView.new(  1, 10, "XPDR 1",                 mcdu_large | mcdu_green ),
                StaticView.new(  8, 10, "XPDR 2",                 mcdu_white ),
                StaticView.new( 18, 10, "IDENT",                  mcdu_large | mcdu_white ),
                StaticView.new( 23, 10, black_square,             mcdu_large | mcdu_white ),
                StaticView.new( 23 - size(me.ptitle), 12, me.ptitle, mcdu_large | mcdu_white ),
                StaticView.new( 23, 12, right_triangle,           mcdu_large | mcdu_white ),
            ];
            me.controllers = {
                "L1": PropSwapController.new("XPDRA", "XPDRS"),
                "L2": TransponderController.new("XPDRS"),
                "R2": ModelController.new("FLTID"),
                "R5": TriggerController.new("XPDRID"),
                "R6": SubmodeController.new("ret"),
            };
        }
        else if (n == 1) {
            me.views = [
                CycleView.new(1, 2, mcdu_large | mcdu_green, "XPDRMD", [4,3,2,1], xpdrModeLabels),
                StaticView.new(  1,  1, "TCAS/XPDR MODE",         mcdu_white ),
                StaticView.new(  0,  2, black_square,             mcdu_large | mcdu_white ),
                StaticView.new(  1,  4, "ALT RANGE",              mcdu_white ),
                StaticView.new( 14, 12, "RADIO 1/2",              mcdu_large | mcdu_white ),
                StaticView.new( 23, 12, right_triangle,           mcdu_large | mcdu_white ),
            ];
            me.controllers = {
                "L1": CycleController.new("XPDRMD", [4,3,2,1]),
                "R6": SubmodeController.new("ret"),
            };
        }
    },
};

