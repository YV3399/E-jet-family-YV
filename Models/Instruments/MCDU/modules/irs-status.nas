var IRSStatusModule = {
    new: func (mcdu, parentModule, index) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(IRSStatusModule, m.parents);
        m.index = index;
        return m;
    },

    getTitle: func () { return "IRS " ~ me.index ~ " STATUS"; },
    getShortTitle: func () { return "IRS " ~ me.index; },
    getNumPages: func () { return 1; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                FormatView.new(2,  1, mcdu_large | mcdu_white, "IRU" ~ me.index ~ "-STATUS", 12, "%12s", iruStatusNames),
                StaticView.new(6,  2, "IAS POSITION", mcdu_large | mcdu_white),
                GeoView.new(2,  3, mcdu_large | mcdu_green, "IRU" ~ me.index ~ "-REFLAT",  "LAT"),
                GeoView.new(13,  3, mcdu_large | mcdu_green, "IRU" ~ me.index ~ "-REFLON",  "LON"),
                FormatView.new(3, 5, mcdu_large | mcdu_green, "IRU" ~ me.index ~ "-TIME-TO-NAV", 24, "TIME TO NAV %4.1fMIN",
                    func (secs) { return (secs or 0.0) / 60.0; },
                    func (secs) { return (secs != nil and secs > 0.0) ? 1 : -1; }),
            ];
            me.controllers = {
            };
            if (me.ptitle != nil) {
                me.controllers["L6"] = SubmodeController.new("ret");
                append(me.views,
                     StaticView.new(0, 12, left_triangle ~ me.ptitle, mcdu_large | mcdu_white));
            }
        }
    },
};

