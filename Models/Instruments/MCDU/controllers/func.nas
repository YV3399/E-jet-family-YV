var FuncController = {
    new: func (setFn, delFn = nil) {
        var m = BaseController.new();
        m.parents = prepended(FuncController, m.parents);
        m.setFn = setFn;
        m.delFn = delFn;
        return m;
    },

    send: func (owner, val) {
        if (me.setFn != nil) {
            return me.setFn(owner, val);
        }
        else {
            return nil;
        }
    },

    select: func (owner, boxed) {
        if (me.setFn != nil) {
            me.setFn(owner, nil);
        }
    },

    delete: func (owner, boxed) {
        if (me.delFn != nil) {
            me.delFn(owner);
        }
    },
};

