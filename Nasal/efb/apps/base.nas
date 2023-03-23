var BaseApp = {
    new: func (masterGroup) {
        return {
            parents: [BaseApp],
            masterGroup: masterGroup,
            currentPage: 0,
            clickSpots: [],
        }
    },

    # Handles touch events.
    touch: func (x, y) {
        foreach (var clickSpot; me.clickSpots) {
            var where = clickSpot.where;
            if (contains(clickSpot, 'page') and clickSpot.page != nil and clickSpot.page != me.currentPage) {
                continue;
            }
            var xy = [x, y];
            if (typeof(where) == 'hash' and contains(where, 'parents')) {
                # This is probably a canvas element, or so we hope...
                xy = where.canvasToLocal(xy);
                where = where.getTightBoundingBox();
            }
            if ((xy[0] >= where[0]) and
                (xy[0] < where[2]) and
                (xy[1] >= where[1]) and
                (xy[1] < where[3])) {
                    clickSpot.what();
                    break;
            }
        }
    },

    # Make an element clickable. The clickable area will automatically move
    # with the element.
    # Arguments:
    # - elem: clickable element
    # - what: click handler (func ())
    # - page: if integer, the page number on which the clickspot is active.
    makeClickable: func (elem, what, page=nil) {
        append(me.clickSpots, {
            where: elem,
            what: what,
            page: page,
        });
    },

    # Make a clickable area. Arguments:
    # - area: clickable area ([left, top, right, bottom])
    # - what: click handler (func ())
    # - page: if integer, the page number on which the clickspot is active.
    makeClickableArea: func (area, what, page=nil) {
        append(me.clickSpots, {
            where: area,
            what: what,
            page: page,
        });
    },

    makePager: func (numPages, what, parentGroup = nil) {
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
        });
        me.makeClickable(btnPgDn, func () {
            if (numPages == nil or self.currentPage < numPages - 1) {
                self.currentPage = self.currentPage + 1;
                updatePageIndicator();
                what();
            }
        });
        return pager;
    },


    handleBack: func () {},
    handleMenu: func () {},
    foreground: func () {},
    background: func () {},
    initialize: func () {},
};
