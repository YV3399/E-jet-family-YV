var FreqView = {
    new: func (x, y, flags, model, ty = nil) {
        var m = ModelView.new(x, y, flags, model);
        m.parents = prepended(FreqView, m.parents);
        if (ty == nil) {
            var k = m.model.getKey();
            if (k != nil) {
                ty = substr(k, 0, 3);
            }
        }
        m.mode = ty;
        if (ty == "COM") {
            m.w = 7;
            m.fmt = "%7.3f";
        }
        else if (ty == "NAV") {
            m.w = 6;
            m.fmt = "%6.2f";
        }
        else if (ty == "ADF") {
            m.w = 5;
            m.fmt = "%5.1f";
        }
        else {
            m.w = 7;
            m.fmt = "%7.3f";
        }
        return m;
    },

    draw: func (mcdu, val) {
        mcdu.print(me.x, me.y, sprintf(me.fmt, val), me.flags);
    },

};
