include('gui/widget.nas');
include('util.nas');
include('eventSource.nas');

var Checkbox = {
    new: func (parentGroup, x, y) {
        var m = Widget.new();
        m.parents = [me] ~ m.parents;
        m.state = 0;
        m.stateAnim = 0;
        m.stateChanged = EventSource.new();
        m.knobRadius = 12;
        m.centerWidth = 16;
        m.position = { x: x, y: y };

        m.initialize(parentGroup, x, y);
        return m;
    },

    handleTouch: func (touchCoords) {
        me.setState(!me.state);
        return call(Widget.handleTouch, [touchCoords], me);
    },

    foreground: func {
        me.animationTimer.start();
    },

    background: func {
        me.animationTimer.stop();
    },

    setState: func (state) {
        var changed = state != me.state;
        me.state = state;
        if (changed) {
            me.stateChanged.raise({state: me.state});
        }
        me.animationTimer.start();
    },

    setAlignment: func (alignment) {
        var parts = split('-', alignment);
        if (size(parts) != 2) {
            logprint(4, "invalid alignment: " ~ debug.string(alignment));
            return;
        }

        var width = me.centerWidth + 2 * me.knobRadius;

        var dx = 0;
        if (parts[0] == 'left')
            dx = 0;
        elsif (parts[0] == 'center')
            dx = -width * 0.5;
        elsif (parts[0] == 'right')
            dx = -width;

        var dy = 0;
        if (parts[1] == 'top')
            dy = me.knobRadius;
        elsif (parts[1] == 'center' or parts[1] == 'baseline')
            dy = 0;
        elsif (parts[1] == 'bottom')
            dy = -me.knobRadius;

        me.group.setTranslation(me.position.x + dx, me.position.y + dy);

        return me;
    },

    initialize: func (parentGroup) {
        var self = me;
        me.group = parentGroup.createChild('group');
        me.setAlignment('center-center');

        # The base shape
        var r = me.knobRadius;
        var cw = me.centerWidth;

        me.where = me.group.createChild('path')
                            .rect(0, -r, 2 * r + cw, 2 * r)
                            # Set a very small nonzero alpha, otherwise weird
                            # things happen. Probably a bug in canvas, but I
                            # don't know for sure.
                            .setColorFill(0.5, 0.5, 0.5, 0.01);

        me.boxElem = me.group.createChild('path')
                           .moveTo(r, r)
                           .arcSmallCW(r, r, 0, 0, -2 * r)
                           .line(cw, 0)
                           .arcSmallCW(r, r, 0, 0, 2 * r)
                           .line(-cw, 0)
                           .setColorFill(0.6, 0.6, 0.6)
                           .setColor(0.3, 0.3, 0.3);
        # box shadow
        me.group.createChild('path')
                    .moveTo(0, 0)
                    .arcSmallCW(r, 0.75 * r, 0, r, -0.75 * r)
                    .line(cw, 0)
                    .arcSmallCW(r, 0.75 * r, 0, r, 0.75 * r)
                    .arcSmallCCW(r, r, 0, -r, -r)
                    .line(-cw, 0)
                    .arcSmallCCW(r, r, 0, -r, r)
                    .setColorFill(0, 0, 0, 0.2);

        # knob
        me.knobElem = me.group.createChild('group');

        me.knobElem.createChild('path')
                   .circle(r, r, 0)
                   .setColorFill(0.8, 0.8, 0.8)
                   .setColor(0.1, 0.1, 0.1);
        me.knobElem.createChild('path')
                   .circle(r * 0.8, r, -r * 0.2)
                   .setColorFill(0.9, 0.9, 0.9);

        # me.group.createChild('path')
        #         .setColor(1, 0, 0)
        #         .moveTo(0, -r)
        #         .line(0, 2 * r);
        # me.group.createChild('path')
        #         .setColor(1, 0, 0)
        #         .moveTo(-r, 0)
        #         .line(2 * r, 0);

        var animationDT = 0.025;
        me.animationTimer = maketimer(animationDT, func {
            if (me.stateAnim < me.state) {
                me.stateAnim += animationDT * 5;
                me.stateAnim = math.min(1, me.stateAnim);
                me.knobElem.setTranslation(me.stateAnim * cw, 0);
                me.boxElem.setColorFill(0.0, 0.75, 0.0)
            }
            elsif (me.stateAnim > me.state) {
                me.stateAnim -= animationDT * 5;
                me.stateAnim = math.max(0, me.stateAnim);
                me.knobElem.setTranslation(me.stateAnim * cw, 0);
                me.boxElem.setColorFill(0.6, 0.6, 0.6)
            }
            else {
                me.animationTimer.stop();
            }
        });
    },
};

