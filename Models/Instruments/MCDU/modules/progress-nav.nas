var ProgressNavModule = {
    new: func (mcdu, navNum, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(ProgressNavModule, m.parents);
        m.navNum = navNum;
        return m;
    },

    getTitle: func () { return "NAV " ~ me.navNum; },
    getNumPages: func () { return 1; },

    loadPageItems: func (n) {
        if (n == 0) {
            me.views = [
                StaticView.new(        0, 12, left_triangle ~ "PROGRESS", mcdu_large | mcdu_white),
            ];
            me.controllers = {
                "L6": SubmodeController.new("ret"),
            };
            var x = 0;
            var y = 2;
            var ki = 1;
            var k = "";
            var navaids = findNavaidsWithinRange(250, 'VOR');
            var navs = [];
            var prop = "NAV" ~ me.navNum ~ "A";
            foreach (var nav; navaids) {
                if (nav.type == 'VOR') {
                    var str = sprintf("%-4s %5.1f", nav.id, nav.frequency / 100.0);
                    if (x) {
                        k = 'R' ~ ki;
                        append(me.views,
                            StaticView.new(13, y, str ~ right_triangle, mcdu_large | mcdu_white));
                    }
                    else {
                        k = 'L' ~ ki;
                        append(me.views,
                            StaticView.new(0, y, left_triangle ~ str, mcdu_large | mcdu_white));
                    }
                    me.controllers[k] = SelectController.new(prop, nav.frequency / 100.0);
                    x += 1;
                    if (x > 1) {
                        x = 0;
                        y += 2;
                        ki += 1;
                    }
                    if (ki > 5) break;
                }
            }
        }
    },
};

