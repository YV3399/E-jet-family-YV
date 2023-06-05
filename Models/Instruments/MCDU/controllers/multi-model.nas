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
            owner.mcdu.setScratchpadMsg("INVALID", mcdu_yellow);
        }
        else {
            owner.mcdu.setScratchpad('');
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

