var FormatView = {
    new: func (x, y, flags, model, w, fmt = nil, mapping = nil, visible = 1) {
        var m = ModelView.new(x, y, flags, model);
        m.parents = prepended(FormatView, m.parents);
        m.mapping = mapping;
        m.w = w;
        if (fmt == nil) { fmt = "%" ~ w ~ "s"; }
        m.fmt = fmt;
        m.visible = visible;
        return m;
    },

    getFlags: func (val) {
        if (typeof(me.flags) == 'func') {
            return me.flags(val);
        }
        else {
            return me.flags;
        }
    },

    getFormat: func (val) {
        if (typeof(me.fmt) == 'func') {
            return me.fmt(val);
        }
        else {
            return me.fmt;
        }
    },

    draw: func (mcdu, val) {
        var format = me.getFormat(val);
        var flags = me.getFlags(val);
        var visibility = 1;
        if (typeof(me.visible) == "func") {
            visibility = me.visible(val);
        }
        elsif (typeof(me.visible) == "scalar") {
            visibility = me.visible;
        }
        if (!visibility) {
            # don't render anything
            return;
        }
        elsif (visibility < 0) {
            # erase
            mcdu.print(me.x, me.y, sprintf('%' ~ me.w ~ 's', ''), flags);
        }
        else {
            # render normally
            if (me.mapping != nil) {
                if (typeof(me.mapping) == "func") {
                    val = me.mapping(val);
                }
                else {
                    val = me.mapping[val];
                }
            }
            else {
                if (val == nil) val = '';
            }
            mcdu.print(me.x, me.y, sprintf(format, val), flags);
        }
    },
};
