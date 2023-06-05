var ProgressModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ProgressModule, m.parents);
        return m;
    },

    getTitle: func () { return "PROGRESS"; },
    getNumPages: func () { return 3; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new( 8,  1, "DIST", mcdu_white),
                StaticView.new(14,  1, "ETE", mcdu_white),
                StaticView.new(19,  1, "FUEL", mcdu_white),
                StaticView.new( 1,  1, "TO", mcdu_white),
                FormatView.new( 0,  2, mcdu_large | mcdu_green, "ID-WP0", 6, "%-6s"),
                FormatView.new( 6,  2, mcdu_large | mcdu_green, "DIST-WP0", 6, "%4s", formatDist),
                FormatView.new(13,  2, mcdu_large | mcdu_green, "ETA-WP0", 6, "%5s", formatZulu),
                FormatView.new(18,  2, mcdu_large | mcdu_green, "FUEL-WP0", 6, "%5.1f", func (fuel) { return fuel * LB2KG / 1000.0; }),
                StaticView.new( 1,  3, "NEXT", mcdu_white),
                FormatView.new( 0,  4, mcdu_large | mcdu_green, "ID-WP1", 6, "%-6s"),
                FormatView.new( 6,  4, mcdu_large | mcdu_green, "DIST-WP1", 6, "%4s", formatDist),
                FormatView.new(13,  4, mcdu_large | mcdu_green, "ETA-WP1", 6, "%5s", formatZulu),
                FormatView.new(18,  4, mcdu_large | mcdu_green, "FUEL-WP1", 6, "%5.1f", func (fuel) { return fuel * LB2KG / 1000.0; }),
                StaticView.new( 1,  5, "DEST", mcdu_white),
                FormatView.new( 0,  6, mcdu_large | mcdu_green, "ID-DEST", 6, "%-6s"),
                FormatView.new( 6,  6, mcdu_large | mcdu_green, "DIST-DEST", 6, "%4s", formatDist),
                FormatView.new(13,  6, mcdu_large | mcdu_green, "ETA-DEST", 6, "%5s", formatZulu),
                FormatView.new(18,  6, mcdu_large | mcdu_green, "FUEL-DEST", 6, "%5.1f", func (fuel) { return fuel * LB2KG / 1000.0; }),
                StaticView.new( 1,  9, "GPS RNP=", mcdu_white),
                StaticView.new( 9, 9, "1.00", mcdu_green),
                StaticView.new(14, 9, "EPU=N/A", mcdu_white),
                StringView.new(0, 10, mcdu_large |  mcdu_green, "NAV1ID", 5),
                FreqView.new(6, 10, mcdu_large |  mcdu_green, "NAV1A"),
                StringView.new(12, 10, mcdu_large |  mcdu_green, "NAV2ID", 5),
                FreqView.new(18, 10, mcdu_large |  mcdu_green, "NAV2A"),

                StaticView.new(        0, 12, left_triangle ~ "NAV1 <--SELECT--> NAV2" ~ right_triangle, mcdu_large | mcdu_white),
            ];
            me.controllers = {
                "L6": SubmodeController.new("PROG-NAV1"),
                "R6": SubmodeController.new("PROG-NAV2"),
            };
        }
        else if (n == 1) {
            me.views = [
                StaticView.new(  1, 3, "TOC", mcdu_white),
                FormatView.new(  1, 4, mcdu_green | mcdu_large, "VNAV-DIST-TOC", 4, "%4s", formatDist),
                StaticView.new(  5, 4, "NM/", mcdu_white),
                FormatView.new(  8, 4, mcdu_green | mcdu_large, "VNAV-ETE-TOC", 5, "%5s", formatETE),

                StaticView.new(  1, 5, "TOD", mcdu_white),
                FormatView.new(  1, 6, mcdu_green | mcdu_large, "VNAV-DIST-TOD", 7, "%4s", formatDist),
                StaticView.new(  5, 6, "NM/", mcdu_white),
                FormatView.new(  8, 6, mcdu_green | mcdu_large, "VNAV-ETE-TOD", 5, "%5s", formatETE),

                StaticView.new( 16, 3, "FUEL QTY", mcdu_white),
                FormatView.new( 19, 4, mcdu_green | mcdu_large, "FUEL-CUR", 5, "%5.0f"),
                StaticView.new( 16, 5, "GROSS WT", mcdu_white),
                FormatView.new( 19, 6, mcdu_green | mcdu_large, "WGT-CUR", 5, "%5.0f", func (lbs) { return lbs * LB2KG; }),
            ];
        }
        else if (n == 2) {
            me.views = [
                StaticView.new(  1, 1, "XTK ERROR", mcdu_white),
                # TODO
                # FormatView.new(  1, 2, mcdu_green | mcdu_large, "XTK-ERROR", 4, "%4s", formatDist),
                StaticView.new(  17, 1, "OFFSET", mcdu_white),
                # TODO
                # FormatView.new(  1, 2, mcdu_green | mcdu_large, "NAV-LAT-OFFSET", 4, "%4s", formatDist),
                StaticView.new(   1, 3, "TRACK", mcdu_white),
                StaticView.new(  10, 3, "DRIFT", mcdu_white),
                StaticView.new(  20, 3, "HDG", mcdu_white),
                FormatView.new(   1, 4, mcdu_green | mcdu_large, "TRACK", 4, "%4.0f°"),
                FormatView.new(  10, 4, mcdu_green | mcdu_large, "DRIFT", 4, "%4.0f°"),
                FormatView.new(  18, 4, mcdu_green | mcdu_large, "HDG", 4, "%4.0f°"),

                StaticView.new(   1, 5, "WIND", mcdu_white),
                StaticView.new(  21, 5, "GS", mcdu_white),

                FormatView.new(   0, 6, mcdu_green | mcdu_large, "WIND-HDG", 4, "%4.0f°"),
                StaticView.new(   5, 6, "/", mcdu_white | mcdu_large),
                FormatView.new(   6, 6, mcdu_green | mcdu_large, "WIND-SPD", 3, "%-3.0f"),

                FormatView.new(   9, 6, mcdu_cyan | mcdu_large, "WIND-HEAD", 1, "%1s", func (x) { if (x >= 0) return "↓" else return "↑"; }),
                FormatView.new(  10, 6, mcdu_cyan | mcdu_large, "WIND-HEAD", 3, "%-3.0f", math.abs),
                FormatView.new(  14, 5, mcdu_cyan | mcdu_large, "WIND-CROSS", 3, "%3s", func (x) { if (x >= 0) return "-->" else return "<--"; }),
                FormatView.new(  14, 6, mcdu_cyan | mcdu_large, "WIND-CROSS", 3, "%-3.0f", math.abs),
                FormatView.new(  20, 6, mcdu_green | mcdu_large, "GS", 3, "%3.0f"),
            ];
        }
    },
};

