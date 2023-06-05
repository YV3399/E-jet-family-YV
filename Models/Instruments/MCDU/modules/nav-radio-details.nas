var NavRadioDetailsModule = {
    new: func (mcdu, parentModule, radioNum) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(NavRadioDetailsModule, m.parents);
        m.radioNum = radioNum;
        return m;
    },

    getNumPages: func () { return 1; },
    getTitle: func () { return "NAV" ~ me.radioNum; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                FreqView.new(1, 2, mcdu_large |  mcdu_green, "NAV" ~ me.radioNum ~ "A"),
                FreqView.new(1, 4, mcdu_large |  mcdu_yellow, "NAV" ~ me.radioNum ~ "S"),
                CycleView.new(17, 4, mcdu_large | mcdu_green, "DME" ~ me.radioNum ~ "H"),
                CycleView.new(17, 10, mcdu_large | mcdu_green, "NAV" ~ me.radioNum ~ "AUTO"),
                StaticView.new(  1,  1, "ACTIVE",                 mcdu_white ),
                StaticView.new(  0,  2, up_down_arrow, mcdu_large | mcdu_white ),
                StaticView.new(  1,  3, "PRESET",                 mcdu_white ),
                StaticView.new(  0,  4, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new( 15,  3, "DME HOLD",               mcdu_white ),
                StaticView.new( 15,  9, "FMS AUTO",               mcdu_white ),
                StaticView.new(  0, 12, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new(  1, 12, "MEMORY", mcdu_large | mcdu_white ),
            ];
            me.controllers = {
                "L1": PropSwapController.new("NAV" ~ me.radioNum ~ "S", "NAV" ~ me.radioNum ~ "A"),
                "L2": FreqController.new("NAV" ~ me.radioNum ~ "S"),
                "R2": CycleController.new("DME" ~ me.radioNum ~ "H"),
                "R5": CycleController.new("NAV" ~ me.radioNum ~ "AUTO"),
            };
            if (me.ptitle != nil) {
                me.controllers["R6"] = SubmodeController.new("ret");
                append(me.views,
                     StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
            }
        }
    },
};


