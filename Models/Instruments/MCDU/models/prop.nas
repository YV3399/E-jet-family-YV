# Model backed by a property
var PropModel = {
    new: func (prop, key = nil, defval = '') {
        var m = BaseModel.new();
        m.parents = prepended(PropModel, m.parents);
        m.key = key;
        m.prop = (typeof(prop) == 'scalar') ?
                    props.globals.getNode(prop) :
                    prop;
        if (defval == nil) {
            m.defval = '';
        }
        else {
            m.defval = defval;
        }
        return m;
    },

    getKey: func () {
        return me.key;
    },

    get: func () {
        if (me.prop != nil) {
            return me.prop.getValue();
        }
        else {
            return nil;
        }
    },

    set: func (val) {
        if (me.prop != nil) {
            me.prop.setValue(val);
        }
    },

    reset: func () {
        var val = me.defval;
        if (typeof(me.defval) == 'func') {
            val = me.defval();
        }
        me.set(val);
    },

    subscribe: func (f) {
        if (me.prop != nil) {
            return setlistener(me.prop, func () {
                var val = me.prop.getValue();
                f(val);
            });
        }
    },

    unsubscribe: func (l) {
        removelistener(l);
    },
};

