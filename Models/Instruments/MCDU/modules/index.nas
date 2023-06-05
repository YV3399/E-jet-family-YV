var IndexModule = {
    new: func (mcdu, parentModule, title, shorttitle, items) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(IndexModule, m.parents);
        m.items = items;
        m.title = title;
        m.shorttitle = shorttitle or title;
        return m;
    },

    getNumPages: func () {
        return math.ceil(size(me.items) / 12);
    },

    getTitle: func () { return me.title; },
    getShortTitle: func () { return me.shorttitle; },

    loadPageItems: func (n) {
        var items = subvec(me.items, n * 12, 12);
        var i = 0;
        me.views = [];
        me.controllers = {};

        var renderItem = func (item, side, y, lsk) {
            if (item != nil) {
                var conditionModel = nil;
                if (size(item) > 2) {
                    conditionModel = item[2];
                }
                if (item[0] == 'ret') {
                    if (me.ptitle != nil and me.ptitle != '')
                        # we have something to return to, so let's just use
                        # that
                        item[1] = me.ptitle;
                    else
                        # there is no parent module, so don't render anything
                        return;
                }
                if (typeof(item[1]) == 'scalar') {
                    var title = item[1];
                    var x = 0;
                    if (side) {
                        title = title ~ right_triangle;
                        x = 24 - utf8.size(title);
                    }
                    else {
                        title = left_triangle ~ title;
                        x = 0;
                    }
                    if (conditionModel == nil) {
                        append(me.views, StaticView.new(x, y, title, mcdu_large | mcdu_white));
                    }
                    else {
                        append(me.views,
                            FormatView.new(x, y, mcdu_large | mcdu_white, conditionModel,
                                utf8.size(title), func (val) {
                                    if (val)
                                        return title;
                                    else
                                        return utf8.substr('                        ', 0, utf8.size(title))
                                }));
                    }
                }
                elsif (typeof(item[1]) == 'func') {
                    var x = 0;
                    if (side) x = 23;
                    append(me.views, item[1](x, y, side));
                }

                if (typeof(item[0]) == 'scalar') {
                    me.controllers[lsk] =
                        SubmodeController.new(item[0]);
                }
                elsif (typeof(item[0]) == 'func') {
                    me.controllers[lsk] = item[0](me);
                }
            }
        }

        # left side
        for (i = 0; i < 6; i += 1) {
            if (i >= size(items)) break;
            var item = items[i];
            renderItem(item, 0, 2 + i * 2, 'L' ~ (i + 1));
        }
        # right side
        for (i = 0; i < 6; i += 1) {
            if (i + 6 >= size(items)) break;
            var item = items[i + 6];
            renderItem(item, 1, 2 + i * 2, 'R' ~ (i + 1));
        }
    },
};


