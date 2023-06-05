var SubmodeController = {
    new: func (submode, pushStack = 1) {
        var m = BaseController.new();
        m.parents = prepended(SubmodeController, m.parents);
        m.submode = submode;
        m.pushStack = pushStack;
        return m;
    },

    select: func (owner, boxed) {
        if (me.submode == nil or me.submode == 'ret') {
            owner.ret();
        }
        else {
            if (me.pushStack == 1) {
                owner.push(me.submode);
            }
            elsif (me.pushStack == 2) {
                owner.sidestep(me.submode);
            }
            else {
                owner.goto(me.submode);
            }
        }
    },
};

