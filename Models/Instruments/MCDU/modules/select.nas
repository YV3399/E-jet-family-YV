var SelectModule = {
    new: func (mcdu, parentModule, title, items, onSelect = nil, labels = nil, selectedItem = nil) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(SelectModule, m.parents);
        m.items = (items == nil) ? [] : items;
        m.labels = labels;
        m.selectedItem = selectedItem;
        m.title = title;
        m.onSelect = onSelect;
        return m;
    },

    getLabel: func (item) {
        if (me.labels == nil) return item;
        if (typeof(me.labels) == 'func') return me.labels(item);
        if (typeof(me.labels) == 'scalar') return sprintf(me.labels, item);
        return me.labels[item];
    },

    getTitle: func () { return me.title; },
    getNumPages: func () {
        return math.max(1, math.ceil(size(me.items) / 10));
    },

    loadPageItems: func (n) {
        me.views = [];
        me.controllers = {};
        for (var i = 0; i < 10; i += 1) {
            var j = n * 10 + i;
            if (j >= size(me.items)) {
                break;
            }
            var x = (i < 5) ? 1 : 12;
            var xp = (i < 5) ? 0 : 23;
            var p = (i < 5) ? left_triangle : right_triangle;
            var y = (i < 5) ? ((i * 2) + 2) : ((i * 2) + 2 - 10);
            var fmt = (i < 5) ? "%-11s" : "%11s";
            var lsk = (i < 5) ? ("L" ~ (i + 1)) : ("R" ~ (i - 4));
            var lbl = me.getLabel(me.items[j]);
            append(me.views, StaticView.new(xp, y, p, mcdu_large | mcdu_white));
            append(me.views, StaticView.new(x, y, sprintf(fmt, lbl), mcdu_large | mcdu_green));
            me.controllers[lsk] =
            (func (val) {
                FuncController.new(func (owner, ignored) {
                    owner.onSelect(val);
                });
            })(me.items[j]);
        };
        if (me.ptitle != nil) {
            me.controllers["R6"] = SubmodeController.new("ret");
            append(me.views,
                 StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
        }
    },
};

