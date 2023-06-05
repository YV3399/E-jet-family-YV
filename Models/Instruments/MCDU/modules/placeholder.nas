var PlaceholderModule = {
    new: func (mcdu, parentModule, name) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(PlaceholderModule, m.parents);
        m.name = name;
        return m;
    },

    getNumPages: func () { return 1; },
    getTitle: func () { return me.name; },

    loadPageItems: func (p) {
        me.views = [
            StaticView.new(1, 6, "MODULE NOT IMPLEMENTED", mcdu_red | mcdu_large),
        ];
        me.controllers = {};
        if (me.ptitle != nil) {
            me.controllers["R6"] = SubmodeController.new("ret");
            append(me.views,
                 StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
        }
    },
};


