include('util.nas');

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
        # We actually *prepend* the child node, so that it is inspected earlier
        # in the event handling sequence.
        me.children = [child] ~ me.children;
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

    handleTouch: func(touchCoords) {
        if (me.what == nil) {
            # We don't have a handler of our own; bubble.
            return 1;
        }
        else {
            var result = me.what(touchCoords);
            if (result == nil)
                return 0;
            else
                return result;
        }
    },

    touch: func (x, y) {
        if (!me.active)
            return 1; # keep going
        foreach (var child; me.children) {
            # If child handles event, stop.
            var childResult = child.touch(x, y);
            if (typeof(childResult) != 'scalar') {
                return 0;
            }
            if (!childResult)
                return 0;
        }
        var touchCoords = me.checkTouch(x, y);
        if (touchCoords != nil) {
            me.handleTouch(touchCoords);
        }
        else {
            return 1;
        }
    },

    handleRotate: func (rotationNorm, hard=0) {
        # Override to implement "own" rotation behavior.
    },

    rotate: func (rotationNorm, hard=0) {
        if (!me.active)
            return;
        foreach (var child; me.children) {
            child.rotate(rotationNorm);
        }
        me.handleRotate(rotationNorm);
    },

};
