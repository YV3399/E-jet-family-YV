var TestModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(TestModule, m.parents);
        return m;
    },

    getNumPages: func {
        return 2;
    },

    loadPageItems: func (n) {
        me.views = [];
        if (n == 1) {
            for (var c = 0; c < 7; c += 1) {
                append(me.views, StaticView.new(0, c * 2, sprintf("Color #%i", c), c));
                append(me.views, StaticView.new(8, c * 2, "REGULAR", c));
                append(me.views, StaticView.new(0, c * 2 + 1, "LARGE", mcdu_large | c));
                append(me.views, StaticView.new(8, c * 2 + 1, "REVERSE", mcdu_reverse | c));
                append(me.views, StaticView.new(16, c * 2 + 1, "BOTH", mcdu_large | mcdu_reverse | c));
            }
        }
        elsif (n == 0) {
            for (var c = 32; c < 128; c += 1) {
                append(me.views, StaticView.new(c & 15, math.floor((c - 32) / 16) + 1, utf8.chstr(c), mcdu_large | mcdu_white));
            }
            var specialChars = [
                    left_triangle,
                    right_triangle,
                    left_right_arrow,
                    up_down_arrow,
                    black_square,
                    hollow_square,
                    radio_selected,
                    radio_empty,
                ];
            for (var p = 0; p < size(specialChars); p += 1) {
                append(me.views, StaticView.new(p & 15, math.floor(p / 16) + 7, specialChars[p], mcdu_large | mcdu_white));
            }
        }
    },
};

