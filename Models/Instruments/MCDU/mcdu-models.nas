# 

var modelFactory = func (key) {
    # for now, only PropModel can be loaded
    if (contains(keyProps, key)) {
        return PropModel.new(key);
    }
    else {
        return BaseModel.new();
    }
};

# -------------- MODELS -------------- 

var BaseModel = {
    new: func () {
        return {
            parents: [BaseModel]
        };
    },

    get: func () { return nil; },
    set: func (val) { },
    reset: func () { },
    getKey: func () { return nil; },
    subscribe: func (f) { return nil; },
    unsubscribe: func (l) { },
};

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

var ObjectFieldModel = {
    new: func (key, object, field) {
        var m = FuncModel.new(
                    key,
                    func() { return object[field]; },
                    func(val) { object[field] = val; });
        m.parents = prepended(ObjectFieldModel, m.parents);
        return m;
    },
};

var PropModel = {
    new: func (key, defval = '') {
        var m = BaseModel.new();
        m.parents = prepended(PropModel, m.parents);
        m.key = key;
        m.prop = props.globals.getNode(keyProps[key], 1);
        if (defval == nil) {
            m.defval = keyDefs[key];
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

var departureLens = {
    get: func (owner) { return owner.route.departureAirport; },
    set: func (owner, val) { return owner.route.departureAirport = val; }
};

var destinationLens = {
    get: func (owner) { return owner.route.destinationAirport; },
    set: func (owner, val) { return owner.alternateRoute.departureAirport = owner.route.destinationAirport = val; }
};

var alternateLens = {
    get: func (owner) { return owner.alternateRoute.destinationAirport; },
    set: func (owner, val) { return owner.alternateRoute.destinationAirport = val; }
};

var routeLenses = {
    'DEPARTURE-AIRPORT': departureLens,
    'DESTINATION-AIRPORT': destinationLens,
    'ALTERNATE-AIRPORT': alternateLens,
};

var makeAirportModel = func(owner, key) {
    return FuncModel.new(key,
        func () {
            var lens = routeLenses[key];
            var ap = lens.get(owner);
            if (ap == nil) return "▯▯▯▯";
            return ap.id;
        },
        func (icao) {
            if (size(icao) != 4) return nil;
            var lens = routeLenses[key];
            var aps = findAirportsByICAO(icao);
            if (size(aps) == 1) {
                owner.startEditing();
                lens.set(owner, aps[0]);
                fms.kickRouteManager();
                owner.fullRedraw();
            }
            else {
                owner.mcdu.setScratchpadMsg('NO AIRPORT', mcdu_yellow);
            }
        },
        func () {
            var lens = routeLenses[key];
            owner.startEditing();
            lens.set(owner, nil);
            fms.kickRouteManager();
            owner.fullRedraw();
        });
};


