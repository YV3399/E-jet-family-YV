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

