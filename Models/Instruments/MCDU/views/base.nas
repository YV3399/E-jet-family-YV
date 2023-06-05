var BaseView = {
    new: func (x, y, flags) {
        return {
            parents: [BaseView],
            x: x,
            y: y,
            w: 0,
            flags: flags
        };
    },

    getW: func () {
        return me.w;
    },

    getH: func () {
        return 1;
    },

    getL: func () {
        return me.x;
    },

    getT: func () {
        return me.y;
    },

    getKey: func () {
        return nil;
    },

    # Draw the widget to the given MCDU.
    draw: func (mcdu, val) {
    },

    # Fetch current value and draw the widget to the given MCDU.
    drawAuto: func (mcdu) {
    },

    activate: func (mcdu) {
    },

    deactivate: func () {
    },
};
