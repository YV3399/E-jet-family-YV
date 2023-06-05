var RadioItemView = {
    new: func (x, y, model, txt, condition=nil) {
        var m = ModelView.new(x, y, mcdu_large | mcdu_white, model);
        m.parents = prepended(me, m.parents);
        m.w = size(txt) + 1;
        m.txt = txt;
        m.condition = condition;
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
        if (cond) {
            mcdu.print(me.x, me.y, radio_selected ~ me.txt, mcdu_green | mcdu_large);
        }
        else {
            mcdu.print(me.x, me.y, radio_empty ~ me.txt, mcdu_white | mcdu_large);
        }
    },
};

