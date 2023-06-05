var NavIdentModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(NavIdentModule, m.parents);
        return m;
    },

    getTitle: func () { return "NAV IDENT"; },
    getNumPages: func () { return 1; },

    loadPageItems: func (n) {
        if (n == 0) { 
            me.views = [
                StaticView.new( 2,  1, "DATE", mcdu_white),
                FormatView.new( 1, 2, mcdu_large | mcdu_cyan, "ZDAY", 2, "%02d"),
                FormatView.new( 3, 2, mcdu_large | mcdu_cyan, "ZMON", 3, "%3s", datetime.monthName3),
                FormatView.new( 6, 2, mcdu_large | mcdu_cyan, "ZYEAR", 2, "%02d",
                    func (y) { return math.mod(y, 100); }),

                StaticView.new(12, 1, "ACTIVE NDB", mcdu_white),

                FormatView.new(10, 2, mcdu_large | mcdu_green, "NDBFROM_DAY", 2, "%02d"),
                FormatView.new(12, 2, mcdu_large | mcdu_green, "NDBFROM_MON", 3, "%3s", datetime.monthName3),
                FormatView.new(16, 2, mcdu_large | mcdu_green, "NDBUNTIL_DAY", 2, "%02d"),
                FormatView.new(18, 2, mcdu_large | mcdu_green, "NDBUNTIL_MON", 3, "%3s", datetime.monthName3),
                StaticView.new(21, 2, "/", mcdu_large | mcdu_green),
                FormatView.new(22, 2, mcdu_large | mcdu_green, "NDBUNTIL_YEAR", 2, "%02d",
                    func (y) { return math.mod(y or 0, 100); }),

                StaticView.new( 2,  3, "UTC", mcdu_white),
                FormatView.new( 1, 4, mcdu_large | mcdu_cyan, "ZHOUR", 2, "%02d"),
                FormatView.new( 3, 4, mcdu_large | mcdu_cyan, "ZMIN", 2, "%02d"),
                StaticView.new( 5,  4, "Z", mcdu_cyan),
                StaticView.new( 2,  5, "SW", mcdu_white),
                FormatView.new( 1,  6, mcdu_large | mcdu_green, "FGVER", 10, "%-10s"),
                StaticView.new(11,  5, "NDS", mcdu_white),
                FormatView.new(15,  5, mcdu_green, "NDBVERSION", 9),
                FormatView.new(12,  6, mcdu_large | mcdu_green, "NDBSOURCE", 12),
                StaticView.new( 0, 12, left_triangle ~ "MAINTENANCE", mcdu_large | mcdu_white),
                StaticView.new(12, 12, "   POS INIT" ~ right_triangle, mcdu_large | mcdu_white),
            ];
            me.controllers = {
                "R6": SubmodeController.new("POSINIT", 0),
            };
        }
    },
};

