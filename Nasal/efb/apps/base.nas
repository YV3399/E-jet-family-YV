var BaseApp = {
    new: func (masterGroup) {
        return {
            parents: [BaseApp],
            masterGroup: masterGroup,
            clickSpots: [],
        }
    },

    # Handles touch events.
    touch: func (x, y) {
        foreach (var clickSpot; me.clickSpots) {
            var where = clickSpot.where;
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

    makeClickable: func (elem, what) {
        append(me.clickSpots, {
            where: elem,
            what: what,
        });
    },

    makeClickableArea: func (area, what) {
        append(me.clickSpots, {
            where: area,
            what: what,
        });
    },

    handleBack: func () {},
    handleMenu: func () {},
    foreground: func () {},
    background: func () {},
    initialize: func () {},
};
