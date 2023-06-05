var TransponderController = {
    new: func (model, goto = nil) {
        var m = ModelController.new(model);
        m.parents = prepended(TransponderController, m.parents);
        m.goto = goto;
        return m;
    },

    parse: func (val) {
        val = parseOctal(val);
        if (val == nil or val < 0 or val > 0o7777) { return nil; }
        val = sprintf("%04o", val);
        return val;
    },

    select: func (owner, boxed) {
        if (boxed) {
            if (me.goto == nil) {
                return nil;
            }
            else if (me.goto == "ret") {
                owner.ret();
            }
            else {
                owner.push(me.goto);
            }
        }
        else {
            owner.box(me.model.getKey());
        }
    },

    delete: func (owner, boxed) {
        me.model.reset();
    },

    dial: func (owner, digit) {
        var val = me.model.get();
        val = ('0o' ~ val) + 0;

        if (digit == 1) {
            val = (val & 0o7770) | ((val + 1) & 0o7)
        }
        else if (digit == 2) {
            val = (val & 0o7707) | ((val + 0o10) & 0o70)
        }
        else if (digit == 3) {
            val = (val & 0o7077) | ((val + 0o100) & 0o700)
        }
        else if (digit == 4) {
            val = (val & 0o0777) | ((val + 0o1000) & 0o7000)
        }
        else if (digit == -1) {
            val = (val & 0o7770) | ((val - 1) & 0o7)
        }
        else if (digit == -2) {
            val = (val & 0o7707) | ((val - 0o10) & 0o70)
        }
        else if (digit == -3) {
            val = (val & 0o7077) | ((val - 0o100) & 0o700)
        }
        else if (digit == -4) {
            val = (val & 0o0777) | ((val - 0o1000) & 0o7000)
        }

        me.model.set(sprintf("%04o", val));
    },
};

