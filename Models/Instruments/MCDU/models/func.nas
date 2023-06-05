# Model backed by a set of functions.
var FuncModel = {
    new: func (key, getter, setter, resetter = nil) {
        var m = BaseModel.new();
        m.parents = prepended(FuncModel, m.parents);
        m.getter = getter;
        m.setter = setter;
        m.resetter = resetter;
        m.subscribers = {};
        m.key = key;
        m.nextSubscriberID = 1;
        return m;
    },

    getKey: func () { return me.key; },

    get: func () {
        if (typeof(me.getter) == "func") {
            return me.getter();
        }
        else {
            return nil;
        }
    },

    set: func (val) {
        if (typeof(me.setter) == "func") {
            me.setter(val);
            me.raise(val);
        }
    },

    reset: func () {
        if (typeof(me.resetter) == "func") {
            me.resetter();
            me.raise(me.get());
        }
    },

    subscribe: func (f) {
        var k = me.nextSubscriberID;
        me.nextSubscriberID += 1;
        me.subscribers[k] = f;
        return k;
    },

    unsubscribe: func (k) {
        delete(me.subscribers, k);
    },

    raise: func (val) {
        foreach (var k; keys(me.subscribers)) {
            var f = me.subscribers[k];
            if (typeof(f) == 'func') {
                f(val);
            }
        }
    },
};

