var SelectController = {
    new: func (model, value, ret=1) {
        var m = BaseController.new();
        m.parents = prepended(SelectController, m.parents);
        if (typeof(model) == "scalar") {
            m.model = modelFactory(model);
        }
        else {
            m.model = model;
        }
        m.value = value;
        m.ret = ret;
        return m;
    },

    select: func (owner, boxed) {
        me.model.set(me.value);
        if (me.ret) owner.ret();
    },
};

