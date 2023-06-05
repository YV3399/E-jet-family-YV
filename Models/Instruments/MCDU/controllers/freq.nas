var FreqController = {
    new: func (key, goto = nil, ty = nil) {
        var m = ModelController.new(key);
        m.parents = prepended(FreqController, m.parents);
        m.goto = goto;
        if (ty == nil) {
            ty = substr(key, 0, 3);
        }
        m.mode = ty;
        if (ty == "COM") {
            m.modeProp = props.globals.getNode(keyProps[substr(key, 0, 4) ~ "FS"], 1);
            m.min = 118.0;
            m.max = 137.0;
            m.nearest = func (f) {
                var mode = m.modeProp.getValue();
                frequencies.nearestComChannel(f, mode);
            }
            m.nextXS = func (f) {
                var mode = m.modeProp.getValue();
                return frequencies.nextComChannel(f, mode);
            }
            m.prevXS = func (f) {
                var mode = m.modeProp.getValue();
                return frequencies.prevComChannel(f, mode);
            }
            m.nextS = func (f) { return f + 0.1; }
            m.prevS = func (f) { return f - 0.1; }
            m.nextL = func (f) { return f + 1; }
            m.prevL = func (f) { return f - 1; }
            m.nextXL = func (f) { return f + 10; }
            m.prevXL = func (f) { return f - 10; }
        }
        else if (ty == "NAV") {
            m.min = 108.00;
            m.max = 117.95;
            m.nearest = func (f) { return math.round(f / 0.005) * 0.005; }
            m.nextXS = func (f) { return f + 0.05; }
            m.prevXS = func (f) { return f - 0.05; }
            m.nextS = func (f) { return f + 0.1; }
            m.prevS = func (f) { return f - 0.1; }
            m.nextL = func (f) { return f + 1; }
            m.prevL = func (f) { return f - 1; }
            m.nextXL = func (f) { return f + 10; }
            m.prevXL = func (f) { return f - 10; }
        }
        else if (ty == "ADF") {
            m.min = 190.0;
            m.max = 535.0;
            # The granularity should actually be 0.5 kHz, but FG automatically
            # rounds to full kHz values, so that wouldn't fly.
            m.nearest = math.round;
            m.nextXS = func (f) { return f + 1; }
            m.prevXS = func (f) { return f - 1; }
            m.nextS = func (f) { return f + 1; }
            m.prevS = func (f) { return f - 1; }
            m.nextL = func (f) { return f + 10; }
            m.prevL = func (f) { return f - 10; }
            m.nextXL = func (f) { return f + 100; }
            m.prevXL = func (f) { return f - 100; }
        }
        else {
            m.min = 0.0;
            m.max = 999.99;
            m.nearest = math.round;
            m.nextXS = func (f) { return f + 0.5; }
            m.prevXS = func (f) { return f - 0.5; }
            m.nextS = func (f) { return f + 1; }
            m.prevS = func (f) { return f - 1; }
            m.nextL = func (f) { return f + 10; }
            m.prevL = func (f) { return f - 10; }
            m.nextXL = func (f) { return f + 100; }
            m.prevXL = func (f) { return f - 100; }
        }
        return m;
    },

    parse: func (val) {
        if (val >= me.min and val <= me.max) {}
        elsif (val + 100 >= me.min and val + 100 <= me.max and me.mode != "ADF") { val = val + 100; }
        elsif (val / 10.0 >= me.min and val / 10.0 <= me.max) { val = val / 10.0; }
        elsif (val / 100.0 >= me.min and val / 100.0 <= me.max) { val = val / 100.0; }
        elsif (val / 10.0 + 100 >= me.min and val / 10.0 + 100 <= me.max and me.mode != "ADF") { val = val / 10.0 + 100.0; }
        elsif (val / 100.0 + 100 >= me.min and val / 100.0 + 100 <= me.max and me.mode != "ADF") { val = val / 100.0 + 100.0; }
        else return nil;
        return me.nearest(val);
    },

    select: func (owner, boxed) {
        if (boxed) {
            if (me.goto == nil) {
                return nil;
            }
            else if (me.goto == "ret") {
                owner.ret();
            }
            else {
                owner.push(me.goto);
            }
        }
        else {
            owner.box(me.model.getKey());
        }
    },

    dial: func (owner, digit) {
        if (digit == 0) {
            return;
        }

        var val = me.model.get();
        if (digit == 1) val = me.nextXS(val);
        elsif (digit == 2) val = me.nextS(val);
        elsif (digit == 3) val = me.nextL(val);
        elsif (digit == 4) val = me.nextXL(val);
        elsif (digit == -1) val = me.prevXS(val);
        elsif (digit == -2) val = me.prevS(val);
        elsif (digit == -3) val = me.prevL(val);
        elsif (digit == -4) val = me.prevXL(val);
        if (val > me.max) val = me.max;
        if (val < me.min) val = me.min;
        me.model.set(val);
    },
};

