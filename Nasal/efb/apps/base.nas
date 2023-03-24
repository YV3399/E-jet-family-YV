var Widget = {
    new: func (where=nil) {
        return {
            parents: [Widget],
            where: where,
            what: nil,
            children: [],
            active: 1,
            options: {
            }
        }
    },

    setOption: func (key, val) {
        me.options[key] = val;
        return me;
    },

    setHandler: func (what) {
        me.what = what;
        return me;
    },

    setActive: func (active) {
        me.active = active;
        return me;
    },

    appendChild: func (child) {
        append(me.children, child);
        return me;
    },

    removeAllChildren: func () {
        me.children = [];
        return me;
    },

    checkTouch: func (x, y) {
        if (!me.active)
            return 0;
        var where = me.where;
        var xy = [x, y];
        if (typeof(where) == 'nil')
            return 0;
        if (typeof(where) == 'hash' and contains(where, 'parents')) {
            # This is probably a canvas element, or so we hope...
            xy = where.canvasToLocal(xy);
            where = where.getTightBoundingBox();
        }
        if ((xy[0] >= where[0]) and
            (xy[0] < where[2]) and
            (xy[1] >= where[1]) and
            (xy[1] < where[3])) {
            return [xy[0] - where[0], xy[1] - where[1], where[2] - where[0], where[3] - where[1]];
        }
        else {
            return nil;
        }
    },

    touch: func (x, y) {
        if (!me.active)
            return 1; # keep going
        foreach (var child; me.children) {
            # If child handles event, stop.
            if (!child.touch(x, y))
                return 0;
        }
        var touchCoords = me.checkTouch(x, y);
        if (touchCoords != nil) {
            if (me.what == nil) {
                # We don't have a handler of our own; bubble.
                return 1;
            }
            else {
                return me.what(touchCoords) or 0;
            }
        }
        else {
            return 1;
        }
    },

};

var BaseApp = {
    new: func (masterGroup) {
        return {
            parents: [BaseApp],
            masterGroup: masterGroup,
            currentPage: 0,
            rootWidget: Widget.new()
        }
    },

    # Handles touch events.
    touch: func (x, y) {
        me.rootWidget.touch(x, y);
    },

    # Make an element or area clickable.
    # If given an element, the clickable area will automatically move
    # with the element.
    # Arguments:
    # - where: clickable element or area ([left, top, right, bottom])
    # - what: click handler (func (relCoords[x, y, width, height]); return 0 to stop propagating, or 1 to propagate))
    # - parentWidget: defaults to the root widget
    makeClickable: func (elem, what, parentWidget=nil) {
        if (parentWidget == nil)
            parentWidget = me.rootWidget;

        return parentWidget.appendChild(
            Widget.new(elem)
                  .setHandler(what)
        );
    },

    makePager: func (numPages, what, parentGroup = nil, parentWidget = nil) {
        if (parentGroup == nil)
            parentGroup = me.masterGroup;
        if (numPages != nil and numPages < 2) return;
        var pager = parentGroup.createChild('group');
        canvas.parsesvg(pager, "Aircraft/E-jet-family/Models/EFB/pager-overlay.svg", {'font-mapper': font_mapper});
        var btnPgUp = pager.getElementById('btnPgUp');
        var btnPgDn = pager.getElementById('btnPgDn');
        var self = me;
        var currentPageIndicator = pager.getElementById('pager.digital');
        var updatePageIndicator = func () {
                currentPageIndicator
                        .setText(
                            (numPages == nil)
                                ? sprintf("%i", self.currentPage + 1)
                                : sprintf("%i/%i", self.currentPage + 1, numPages)
                         );
        };
        updatePageIndicator();
        me.makeClickable(btnPgUp, func () {
            if (self.currentPage > 0) {
                self.currentPage = self.currentPage - 1;
                updatePageIndicator();
                what();
            }
        }, parentWidget);
        me.makeClickable(btnPgDn, func () {
            if (numPages == nil or self.currentPage < numPages - 1) {
                self.currentPage = self.currentPage + 1;
                updatePageIndicator();
                what();
            }
        }, parentWidget);
        return pager;
    },


    handleBack: func () {},
    handleMenu: func () {},
    foreground: func () {},
    background: func () {},
    initialize: func () {},
};
