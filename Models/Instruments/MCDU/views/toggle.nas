var ToggleView = {
    new: func (x, y, flags, model, txt, condition=nil) {
        var m = ModelView.new(x, y, flags, model);
        m.parents = prepended(ToggleView, m.parents);
        m.w = size(txt);
        m.txt = txt;
        m.clear = "";
        m.condition = condition;
        while (size(m.clear) < size(txt)) {
            m.clear ~= " ";
        }
        return m;
    },

    draw: func (mcdu, val) {
        var cond = 1;
        if (me.condition == nil) {
            cond = val;
        }
        elsif (typeof(me.condition) == 'func') {
            cond = me.condition(val);
        }
        elsif (typeof(me.condition) == 'scalar') {
            cond = (val == me.condition);
        }
        mcdu.print(me.x, me.y, cond ? me.txt : me.clear, me.flags);
    },
};
