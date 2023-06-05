var ComRadioDetailsModule = {
    new: func (mcdu, parentModule, radioNum) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ComRadioDetailsModule, m.parents);
        m.radioNum = radioNum;
        return m;
    },

    getNumPages: func () { return 1; },
    getTitle: func () { return "COM" ~ me.radioNum; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                FreqView.new(1, 2, mcdu_large |  mcdu_green, "COM" ~ me.radioNum ~ "A"),
                FreqView.new(1, 4, mcdu_large |  mcdu_yellow, "COM" ~ me.radioNum ~ "S"),
                StaticView.new(  1,  1, "ACTIVE",                 mcdu_white ),
                StaticView.new(  0,  2, up_down_arrow, mcdu_large | mcdu_white ),
                StaticView.new(  1,  3, "PRESET",                 mcdu_white ),
                StaticView.new(  0,  4, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new(  1,  5, "MEM TUNE",               mcdu_white ),
                StaticView.new( 16,  1, "SQUELCH",                mcdu_white ),
                StaticView.new( 19,  3, "MODE",                   mcdu_white ),
                StaticView.new( 19,  5, "FREQ",                   mcdu_white ),
                FormatView.new( 17,  6, mcdu_large | mcdu_green, "COM" ~ me.radioNum ~ "FS", 7),
                StaticView.new(  0, 12, left_triangle, mcdu_large | mcdu_white ),
                StaticView.new(  1, 12, "MEMORY", mcdu_large | mcdu_white ),
            ];
            me.controllers = {
                "L1": PropSwapController.new("COM" ~ me.radioNum ~ "S", "COM" ~ me.radioNum ~ "A"),
                "L2": FreqController.new("COM" ~ me.radioNum ~ "S"),
                "R3": ComModeController.new("COM" ~ me.radioNum ~ "FS"),
            };
            if (me.ptitle != nil) {
                me.controllers["R6"] = SubmodeController.new("ret");
                append(me.views,
                     StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
            }
        }
    },
};

