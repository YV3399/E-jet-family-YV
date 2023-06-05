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

    delete: func (owner, boxed) {
        if (me.model != nil) {
            me.model.reset();
        }
    },

    send: func (owner, val) {
        if (me.set(val) == nil) {
            owner.mcdu.setScratchpadMsg("INVALID", mcdu_yellow);
        }
        else {
            owner.mcdu.setScratchpad('');
        }
    },

    select: func (owner, boxed) {
        owner.mcdu.setScratchpad(me.model.get());
    },
};

