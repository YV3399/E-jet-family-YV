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
