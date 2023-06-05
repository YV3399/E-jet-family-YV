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

