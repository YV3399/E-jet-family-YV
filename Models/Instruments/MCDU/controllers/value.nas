var ValueController = {
    new: func (key, options = nil) {
        var m = ModelController.new(key);
        m.parents = prepended(ValueController, m.parents);

        if (options == nil) {
            options = {};
        }
        var scale = contains(options, "scale") ? options["scale"] : 1;
        m.amounts = [ scale, scale * 10, scale * 100, scale * 1000 ];
        m.min = contains(options, "min") ? options["min"] : 0;
        m.max = contains(options, "max") ? options["max"] : nil;
        m.goto = contains(options, "goto") ? options["goto"] : nil;
        m.boxable = contains(options, "boxable") ? options["boxable"] : 0;
        return m;
    },

    parse: func (val) {
        if ((me.min == nil or val >= me.min) and (me.max == nil or val <= me.max)) { return val; }
        return nil;
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
            if (me.boxable) {
                owner.box(me.model.getKey());
            }
            else {
                owner.mcdu.setScratchpad(me.model.get());
            }
        }
    },

    dial: func (owner, digit) {
        if (digit == 0) {
            return;
        }
        var adigit = math.abs(digit) - 1;
        var amount = me.amounts[adigit];
        var val = me.model.get();
        if (digit > 0) {
            val = math.min(me.max, val + amount);
        }
        else {
            val = math.max(me.min, val - amount);
        }
        me.model.set(val);
    },
};

