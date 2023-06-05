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

