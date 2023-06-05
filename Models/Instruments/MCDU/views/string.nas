var StringView = {
    new: func (x, y, flags, model, w) {
        var m = ModelView.new(x, y, flags, model);
        m.parents = prepended(StringView, m.parents);
        m.w = w;
        return m;
    },

    draw: func (mcdu, val) {
        if (size(val) > me.w) {
            val = substr(val, 0, me.w);
        }
        if (size(val) < me.w) {
            if (me.x >= cells_x / 2) {
                # right-align
                val = sprintf("%" ~ me.w ~ "s", val);
            }
            else {
                # left-align
                val = sprintf("%-" ~ me.w ~ "s", val);
            }
        }
        mcdu.print(me.x, me.y, val, me.flags);
    },
};
