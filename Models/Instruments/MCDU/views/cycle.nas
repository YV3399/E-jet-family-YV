var CycleView = {
    new: func (x, y, flags, model, values = nil, labels = nil, wide = nil) {
        if (values == nil) { values = [0, 1]; }
        if (labels == nil) { labels = ["OFF", "ON"]; }
        if (wide == nil) { wide = 0; }

        var m = ModelView.new(x, y, flags, model);
        m.parents = prepended(CycleView, m.parents);
        m.values = values;
        m.labels = labels;
        m.wide = wide;
        if (m.wide) {
            m.w = cells_x;
            m.x = 0;
        }
        else {
            m.w = -1;
            foreach (var val; values) {
                var label = (typeof(labels) == "func") ? labels(val) : labels[val];
                m.w += size(label) + 1;
            }
        }
        return m;
    },

    draw: func (mcdu, val) {
        if (val == nil) {
            val = me.values[0];
        }
        if (me.wide) {
            if (size(me.values) == 2) {
                mcdu.print(cells_x / 2 - 1, me.y, "OR", mcdu_large | mcdu_white);
                if (val == me.values[0]) {
                    mcdu.print(1, me.y, sprintf("%-" ~ (cells_x / 2 - 2) ~ "s", me.labels[me.values[0]]), me.flags);
                    mcdu.print(cells_x / 2 + 2, me.y, sprintf("%-" ~ (cells_x / 2 - 3) ~ "s", me.labels[me.values[1]]), mcdu_white);
                }
                else {
                    mcdu.print(1, me.y, sprintf("%-" ~ (cells_x / 2 - 2) ~ "s", me.labels[me.values[1]]), me.flags);
                    mcdu.print(cells_x / 2 + 2, me.y, sprintf("%-" ~ (cells_x / 2 - 3) ~ "s", me.labels[me.values[0]]), mcdu_white);
                }
                mcdu.print(cells_x - 1, me.y, right_triangle, mcdu_large | mcdu_white);
            }
            else {
                mcdu.print(0, me.y, sprintf("%-" ~ (cells_x - 4) ~ "s", me.labels[val]), me.flags);
                mcdu.print(cells_x - 3, me.y, "OR" ~ right_triangle, mcdu_large | mcdu_white);
            }
        }
        else {
            var x = me.x;
            foreach (var v; me.values) {
                var label = (typeof(me.labels) == "func") ? me.labels(v) : me.labels[v];
                if (label == nil) { continue; }
                mcdu.print(x, me.y, label, (v == val) ? me.flags : 0);
                x += size(label) + 1;
            }
        }
    },
};
