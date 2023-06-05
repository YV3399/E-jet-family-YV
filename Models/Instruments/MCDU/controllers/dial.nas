var DialController = {
    new: func (key, min=nil, max=nil, step=1, stepMajor=10) {
        var m = ModelController.new(key);
        m.parents = prepended(me, m.parents);
        m.step = step;
        m.stepMajor = stepMajor;
        m.min = min;
        m.max = max;
        return m;
    },

    parse: func (val) {
        return math.min(math.max(val, me.min), me.max);
    },

    select: func (owner, boxed) {
        if (boxed) {
            owner.box(nil);
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
        if (digit == 1) val += me.step;
        elsif (digit == 2) val += me.stepMajor;
        elsif (digit == 3) val += me.stepMajor;
        elsif (digit == 4) val += me.stepMajor;
        elsif (digit == -1) val -= me.step;
        elsif (digit == -2) val -= me.stepMajor;
        elsif (digit == -3) val -= me.stepMajor;
        elsif (digit == -4) val -= me.stepMajor;
        if (val > me.max) val = me.max;
        if (val < me.min) val = me.min;
        me.model.set(val);
    },
};


