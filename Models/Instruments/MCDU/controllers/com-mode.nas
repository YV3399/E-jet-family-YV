var ComModeController = {
    new: func (key) {
        var m = ModelController.new(key);
        m.parents = prepended(ComModeController, m.parents);
        return m;
    },

    parse: func (val) {
        if (val == '25') return '25';
        if (val == '833' or val == '8.33') return '8.33';
        if (val == '25/833' or val == '25/8.33' or val == '') return '25/8.33';
        return nil;
    },

    select: func (owner, boxed) {
        var val = me.model.get();
        if (val == '25')
            val = '8.33';
        elsif (val == '8.33')
            val = '25/8.33';
        else
            val = '25';
        me.model.set(val);
    },

    dial: func (owner, digit) {
        var val = me.model.get();
        if (digit > 0) {
            if (val == '25')
                val = '8.33';
            elsif (val == '8.33')
                val = '25/8.33';
            else
                val = '25';
        }
        elsif (digit < 0) {
            if (val == '8.33')
                val = '25';
            elsif (val == '25/8.33')
                val = '8.33';
            else
                val = '25/8.33';
        }
        me.model.set(val);
    },
};

