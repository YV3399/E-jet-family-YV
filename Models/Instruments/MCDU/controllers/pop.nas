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

