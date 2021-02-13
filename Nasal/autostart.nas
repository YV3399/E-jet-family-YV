var SetPropStep = {
    new: func(prop, val) {
        var m = {
            parents: [SetPropStep],
            prop: prop,
            val: val,
            cancelTarget: nil,
        };
    },

    run: func(cont) {
        me.prop.setValue(me.val);
        me.cancelTarget = cont();
        return me;
    },

    cancel: func () {
        if (me.cancelTarget != nil) {
            me.cancelTarget.cancel();
        }
    },
};

var WaitPropStep = {
    new: func(prop, cond) {
        var m = {
            parents: [WaitPropStep],
            prop: prop,
            cond: cond,
            cancelTarget: nil,
            listener: nil,
        };
    },

    run: func(cont) {
        var self = me;
        me.listener = setlistener(me.prop, func (node) {
            if (self.cond(node.getValue())) {
                self.cancelTarget = cont();
                removelistener(self.listener);
                self.listener = nil;
            }
        }
        return me;
    },

    cancel: func () {
        if (me.cancelTarget != nil) { me.cancelTarget.cancel(); }
        if (me.listener != nil) { removelistener(self.listener); self.listener = nil; }
    },
};

var setTarget = func (target) {
    if (target == 0) {
    }
    elsif (target == 1) {
    }
    else {
        printf("Invalid target %i", target);
    }
};

setlistener("/controls/autostart/target", func (node) { setTarget(node.getValue()); });
