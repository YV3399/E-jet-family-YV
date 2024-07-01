include('util.nas');

var Widget = {
    new: func (where=nil) {
        return {
            parents: [Widget],
            where: where,
            onClick: nil,
            onFocus: nil,
            children: [],
            parentWidget: nil,
            active: 1,
            options: {
            }
        }
    },

    setOption: func (key, val) {
        me.options[key] = val;
        return me;
    },

    setClickHandler: func (onClick) {
        me.onClick = onClick;
        return me;
    },

    setFocusHandler: func (onFocus) {
        me.onFocus = onFocus;
        return me;
    },

    setActive: func (active) {
        me.active = active;
        me.handleFocus(active);
        if (me.onFocus != nil) me.onFocus(active);
        return me;
    },

    setParent: func (p) {
        me.parentWidget = p;
    },

    appendChild: func (child) {
        child.setParent(me);
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
        if (me.onClick == nil) {
            # We don't have a handler of our own; bubble.
            return 1;
        }
        else {
            var result = me.onClick(touchCoords);
            if (result == nil)
                return 0;
            else
                return result;
        }
    },

    handleRotate: func (rotationNorm, hard=0) {
        # Override to implement "own" rotation behavior.
        return 1;
    },

    handleKey: func (key) {
        # Override to implement "own" key processing.
        return 1;
    },

    handleWheel: func (axis, amount) {
        # Override to implement "own" scroll wheel handling.
        return 1;
    },

    handleFocus: func (active) {
        # Override to implement custom responses to gaining/losing focus
    },

    wantWheel: func {
        # Override if you want to capture scroll wheel events
        return 0;
    },

    wantKey: func {
        # Override if you want to capture keyboard events
        return 0;
    },

    touch: func (x, y) {
        return me._event({type: 'touch', data: {x: x, y: y}});
    },

    rotate: func (rotationNorm, hard=0) {
        return me._event({type: 'rotate', data: {rotationNorm: rotationNorm, hard: hard}});
    },

    wheel: func (axis, amount) {
        return me._event({type: 'wheel', data: {axis: axis, amount: amount}});
    },

    key: func (key) {
        return me._event({type: 'key', data: {'key': key}});
    },

    _handleEvent: func (event) {
        if (event.type == 'touch') {
            var touchCoords = me.checkTouch(event.data.x, event.data.y);
            if (touchCoords != nil) {
                return me.handleTouch(touchCoords);
            }
        }
        elsif (event.type == 'wheel') {
            if (me.wantWheel()) {
                return me.handleWheel(event.data.axis, event.data.amount);
            }
        }
        elsif (event.type == 'rotate') {
            me.handleRotate(event.data.rotationNorm, event.data.hard);
            # Always bubble rotation events.
        }
        elsif (event.type == 'key') {
            if (me.wantKey()) {
                return me.handleKey(event.data.key);
            }
        }

        return 1;
    },

    _event: func (event) {
        if (!me.active)
            return 1; # keep going
        foreach (var child; me.children) {
            # If child handles event, stop.
            var childResult = child._event(event);
            if (typeof(childResult) != 'scalar')
                # We'll assume that the child has handled the event, even
                # though it has not explicitly returned a result.
                return 0;
            if (!childResult)
                return 0;
        }
        return me._handleEvent(event);
    },

};
