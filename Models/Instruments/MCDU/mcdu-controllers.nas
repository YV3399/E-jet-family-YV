# -------------- CONTROLLERS -------------- 

var BaseController = {
    new: func () {
        return {
            parents: [BaseController]
        };
    },

    getKey: func () {
        return nil;
    },

    # Process a select event. The 'boxed' argument indicates that the
    # controller's key is currently boxed.
    select: func (owner, boxed) {
        return nil;
    },

    # Process a send event.
    # Scratchpad contents is sent as the value.
    # Return updated scratchpad contents to indicate acceptance, or nil to
    # keep scratchpad value unchanged and signal rejection.
    send: func (owner, val) {
        return nil;
    },

    # Process a delete event. This event is sent when the scratchpad contains
    # the magical "*DELETE*" message, and the controller is triggered. The
    # controller should respond by clearing its field, deleting it, or
    # resetting it to defaults. The 'boxed' argument indicates whether the
    # field was boxed at the time the controller was triggered.
    delete: func (owner, boxed) {
    },

    # Process a dialling event.
    dial: func (owner, digit) {
        return nil;
    },
};

var ModelController = {
    new: func (model, parseFunc = nil) {
        var m = BaseController.new();
        m.parents = prepended(ModelController, m.parents);
        if (typeof(model) == "scalar") {
            m.model = modelFactory(model);
        }
        else {
            m.model = model;
        }
        m.parseFunc = parseFunc;
        return m;
    },

    getKey: func () {
        if (me.model == nil) return nil;
        return me.model.getKey();
    },

    # Parse a raw string into a formatted value.
    # Return the parsed value, or nil if the parse failed.
    parse: func (val) {
        if (me.parseFunc != nil) {
            val = me.parseFunc(val);
        }
        return val;
    },

    # Pass a "set value" request to the underlying model.
    set: func (val) {
        val = me.parse(val);
        if (val != nil and me.model != nil) {
            me.model.set(val);
        }
        return val;
    },

    send: func (owner, val) {
        if (me.set(val) == nil) {
            # TODO: issue error message on scratchpad
        }
    },

    select: func (owner, boxed) {
        owner.mcdu.setScratchpad(me.model.get());
    },
};

var PopController = {
    new: func (value) {
        var m = BaseController.new();
        m.parents = prepended(PopController, m.parents);
        m.value = value;
        return m;
    },

    select: func (owner, boxed) {
        owner.mcdu.setScratchpad(me.value);
    },

    send: func (owner, val) {
        owner.mcdu.setScratchpad('');
    },
};

var MultiModelController = {
    new: func (models) {
        var m = BaseController.new();
        m.parents = prepended(MultiModelController, m.parents);
        m.models = [];
        foreach (var model; models) {
            if (typeof(model) == "scalar") {
                model = modelFactory(model);
            }
            if (model == nil) {
                model = BaseModel.new();
            }
            append(m.models, model);
        }
        return m;
    },

    parse: func (val) {
        return split("/", val);
    },

    set: func (val) {
        var vals = me.parse(val);
        if (vals != nil) {
            forindex (var i; me.models) {
                if (vals[i] != '') {
                    me.models[i].set(vals[i]);
                }
            }
        }
        return vals;
    },

    send: func (owner, val) {
        if (me.set(val) == nil) {
            # TODO: issue error message on scratchpad
        }
    },

    select: func (owner, boxed) {
        var scratchval = '';
        forindex (var i; me.models) {
            if (i > 0) {
                scratchval ~= "/";
            }
            scratchval ~= me.models[i].get();
        }
        owner.mcdu.setScratchpad(scratchval);
    },

};

var FuncController = {
    new: func (setFn, delFn = nil) {
        var m = BaseController.new();
        m.parents = prepended(FuncController, m.parents);
        m.setFn = setFn;
        m.delFn = delFn;
        return m;
    },

    send: func (owner, val) {
        if (me.setFn != nil) {
            me.setFn(owner, val);
        }
    },

    select: func (owner, boxed) {
        if (me.setFn != nil) {
            me.setFn(owner, nil);
        }
    },

    delete: func (owner, boxed) {
        if (me.delFn != nil) {
            me.delFn(owner);
        }
    },
};

var SubmodeController = {
    new: func (submode, pushStack = 1) {
        var m = BaseController.new();
        m.parents = prepended(SubmodeController, m.parents);
        m.submode = submode;
        m.pushStack = pushStack;
        return m;
    },

    select: func (owner, boxed) {
        if (me.submode == nil or me.submode == 'ret') {
            owner.ret();
        }
        else {
            if (me.pushStack) {
                owner.push(me.submode);
            }
            else {
                owner.goto(me.submode);
            }
        }
    },
};

var TriggerController = {
    new: func (model) {
        var m = ModelController.new(model);
        m.parents = prepended(TriggerController, m.parents);
        return m;
    },

    select: func (owner, ignore) {
        if (me.model != nil) {
            me.model.set(1);
        }
    },

    send: func (owner, scratch) {
        if (scratch != '') {
            # TODO: warning
        }
        me.select(owner, nil);
    },
};

var CycleController = {
    new: func (model, values = nil) {
        var m = ModelController.new(model);
        m.parents = prepended(CycleController, m.parents);
        if (values == nil) {
            values = [0, 1];
        }
        m.values = values;
        return m;
    },

    cycle: func () {
        var val = me.model.get();
        # find the value in our values vector
        var index = 0;
        while (index < size(me.values) and me.values[index] != val) {
            index += 1;
        }
        index += 1;

        if (index >= size(me.values)) {
            # wrap around
            index = 0;
        }

        val = me.values[index];
        me.model.set(val);
    },

    select: func (owner, ignore) {
        me.cycle();
    },

    send: func (owner, scratch) {
        if (scratch != '') {
            # TODO: warning
        }
        me.cycle();
    },
};

var TransponderController = {
    new: func (model, goto = nil) {
        var m = ModelController.new(model);
        m.parents = prepended(TransponderController, m.parents);
        m.goto = goto;
        return m;
    },

    parse: func (val) {
        val = parseOctal(val);
        if (val == nil or val < 0 or val > 0o7777) { return nil; }
        val = sprintf("%04o", val);
        return val;
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

    delete: func (owner, boxed) {
        me.model.reset();
    },

    dial: func (owner, digit) {
        var val = me.model.get();
        val = ('0o' ~ val) + 0;

        if (digit == 1) {
            val = (val & 0o7770) | ((val + 1) & 0o7)
        }
        else if (digit == 2) {
            val = (val & 0o7707) | ((val + 0o10) & 0o70)
        }
        else if (digit == 3) {
            val = (val & 0o7077) | ((val + 0o100) & 0o700)
        }
        else if (digit == 4) {
            val = (val & 0o0777) | ((val + 0o1000) & 0o7000)
        }
        else if (digit == -1) {
            val = (val & 0o7770) | ((val - 1) & 0o7)
        }
        else if (digit == -2) {
            val = (val & 0o7707) | ((val - 0o10) & 0o70)
        }
        else if (digit == -3) {
            val = (val & 0o7077) | ((val - 0o100) & 0o700)
        }
        else if (digit == -4) {
            val = (val & 0o0777) | ((val - 0o1000) & 0o7000)
        }

        me.model.set(sprintf("%04o", val));
    },
};

var PropSwapController = {
    new: func (key1, key2) {
        var m = BaseController.new();
        m.parents = prepended(PropSwapController, m.parents);
        m.key1 = key1;
        m.key2 = key2;
        m.prop1 = keyProps[key1];
        m.prop2 = keyProps[key2];
        return m;
    },

    getKey: func () {
        return me.key1;
    },

    select: func (owner, boxed) {
        swapProps(me.prop1, me.prop2);
    },
};

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
        m.max = contains(options, "max") ? options["max"] : 500;
        m.goto = contains(options, "goto") ? options["goto"] : nil;
        m.boxable = contains(options, "boxable") ? options["boxable"] : 0;
        return m;
    },

    parse: func (val) {
        if (val >= me.min and val <= me.max) { return val; }
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
            m.amounts = [0.01, 0.1, 1.0, 10.0];
            m.min = 118.0;
            m.max = 137.0;
        }
        else if (ty == "NAV") {
            m.amounts = [0.01, 0.1, 1.0, 10.0];
            m.min = 108.0;
            m.max = 118.0;
        }
        else if (ty == "ADF") {
            m.amounts = [1, 1, 10, 100];
            m.min = 190.0;
            m.max = 999.0;
        }
        else {
            m.amounts = [0.01, 0.1, 1.0, 10.0];
            m.min = 0.0;
            m.max = 999.99;
        }
        return m;
    },

    parse: func (val) {
        if (val >= me.min and val <= me.max) { return val; }
        if (val + 100 >= me.min and val + 100 <= me.max and me.mode != "ADF") { return val + 100; }
        if (val / 10.0 >= me.min and val / 10.0 <= me.max) { return val / 10.0; }
        if (val / 100.0 >= me.min and val / 100.0 <= me.max) { return val / 100.0; }
        if (val / 10.0 + 100 >= me.min and val / 10.0 + 100 <= me.max and me.mode != "ADF") { return val / 10.0 + 100.0; }
        if (val / 100.0 + 100 >= me.min and val / 100.0 + 100 <= me.max and me.mode != "ADF") { return val / 100.0 + 100.0; }
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
            owner.box(me.model.getKey());
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


