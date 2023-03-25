var EventSource = {
    new: func () {
        return {
            parents: [me],
            listeners: [],
            availableListeners: [],
        };
    },

    raise: func (data) {
        foreach (var listener; me.listeners) {
            if (listener != nil)
                listener(data);
        }
    },

    addListener: func (what) {
        if (size(me.availableListeners) > 0) {
            var index = pop(me.availableListeners);
            me.listeners[index] = what;
            return index;
        }
        else {
            append(me.listeners, what);
            return size(me.listeners) - 1;
        }
    },

    removeListener: func (listenerID) {
        me.listeners[listenerID] = nil;
        append(me.availableListeners, listenerID);
    },

    removeAllListeners: func () {
        me.listeners = [];
        me.availableListeners = [];
    },
};
