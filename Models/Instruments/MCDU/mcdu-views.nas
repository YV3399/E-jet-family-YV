# -------------- VIEWS -------------- 

var BaseView = {
    new: func (x, y, flags) {
        return {
            parents: [BaseView],
            x: x,
            y: y,
            w: 0,
            flags: flags
        };
    },

    getW: func () {
        return me.w;
    },

    getH: func () {
        return 1;
    },

    getL: func () {
        return me.x;
    },

    getT: func () {
        return me.y;
    },

    getKey: func () {
        return nil;
    },

    # Draw the widget to the given MCDU.
    draw: func (mcdu, val) {
    },

    # Fetch current value and draw the widget to the given MCDU.
    drawAuto: func (mcdu) {
    },

    activate: func (mcdu) {
    },

    deactivate: func () {
    },
};

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

var ModelView = {
    new: func (x, y, flags, model) {
        var m = BaseView.new(x, y, flags);
        m.parents = prepended(ModelView, m.parents);
        if (typeof(model) == "scalar") {
            m.model = modelFactory(model);
        }
        else {
            m.model = model;
        }
        m.listeners = [];
        return m;
    },

    getKey: func () {
        if (me.model == nil) return nil;
        return me.model.getKey();
    },

    drawAuto: func (mcdu) {
        var val = me.model.get();
        me.draw(mcdu, val);
    },


    activate: func (mcdu) {
        var listener = me.model.subscribe(func (val) {
            me.draw(mcdu, val);
        });
        if (listener != nil) {
            append(me.listeners, listener);
        }
    },

    deactivate: func () {
        foreach (listener; me.listeners) {
            me.model.unsubscribe(listener);
        }
        me.listeners = [];
    },
};

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

var TemperatureView = {
    new: func (x, y, flags, model) {
        var m = ModelView.new(x, y, flags, model);
        m.parents = prepended(TemperatureView, m.parents);
        m.w = 12;
        return m;
    },

    draw: func (mcdu, valC) {
        if (valC == nil) {
            mcdu.print(me.x, me.y, "---°C/---°F", me.flags);
        }
        else {
            var valF = celsiusToFahrenheit(valC);
            var fmt = "%+2.0f°C/%+2.0f°F";
            mcdu.print(me.x, me.y, sprintf(fmt, valC, valF), me.flags);
        }
    },
};

var GeoView = {
    new: func (x, y, flags, model, latlon) {
        var m = ModelView.new(x, y, flags, model);
        m.parents = prepended(GeoView, m.parents);
        if (latlon == "LAT") {
            m.w = 8;
            m.fmt = "%1s%02d°%04.1f";
            m.invalidFmt = "---°--.-";
            m.dirs = ["S", "N"];
        }
        else {
            m.w = 9;
            m.fmt = "%1s%03d°%04.1f";
            m.invalidFmt = "----°--.-";
            m.dirs = ["W", "E"];
        }
        return m;
    },

    draw: func (mcdu, val) {
        if (val == nil or val == '') {
            mcdu.print(me.x, me.y, me.invalidFmt, me.flags);
        }
        else {
            var dir = (val < 0) ? (me.dirs[0]) : (me.dirs[1]);
            var degs = math.abs(val);
            var mins = math.fmod(degs * 60, 60);
            mcdu.print(me.x, me.y, sprintf(me.fmt, dir, degs, mins), me.flags);
        }
    },
};

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



