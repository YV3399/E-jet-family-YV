var StaticView = {
    new: func (x, y, txt, flags, visible=1) {
        if (x < 0)
            x = cells_x - utf8.size(txt) + x + 1;
        var m = BaseView.new(x, y, flags);
        m.parents = prepended(StaticView, m.parents);
        m.w = size(txt or '');
        m.txt = txt or '';
        m.visible = visible;
        return m;
    },

    drawAuto: func (mcdu) {
        var visibility = 1;
        if (typeof(me.visible) == "func") {
            visibility = me.visible(val);
        }
        elsif (typeof(me.visible) == "scalar") {
            visibility = me.visible;
        }
        if (!visibility) {
            return;
        }
        elsif (visibility < 0) {
            # erase
            mcdu.print(me.x, me.y, sprintf('%' ~ me.w ~ 's', ''), me.flags);
        }
        else {
            mcdu.print(me.x, me.y, me.txt, me.flags);
        }
    },

    draw: func (mcdu, ignored) {
        me.drawAuto(mcdu);
    },
};
