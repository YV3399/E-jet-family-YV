include('gui/widget.nas');
include('gui/keyboard.nas');

var BaseApp = {
    new: func (masterGroup) {
        return {
            parents: [BaseApp],
            masterGroup: masterGroup,
            rootWidget: Widget.new(),
            assetDir: nil,
            keyboard: nil,
            keyboardGroup: nil,
            efb: nil, # will be set by the EFB itself
        }
    },

    setAssetDir: func (assetDir) {
        me.assetDir = assetDir;
    },

    # Handles touch events.
    touch: func (x, y) {
        return me.rootWidget.touch(x, y);
    },

    # Handles wheel events.
    wheel: func (axis, amount) {
    },

    # Handles screen rotation events (0 = portrait, 1 = landscape)
    # The 'hard' argument suggests a sharp flip instead of a smooth (animated)
    # transition; 'hard' will be set when an app is first started or woken up,
    # but unset when it is active while the device rotation is ongoing.
    rotate: func (rotationNorm, hard=0) {
        me.rootWidget.rotate(rotationNorm, hard);
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
                  .setClickHandler(what)
        );
    },

    handleBack: func () {},
    handleMenu: func () {},
    foreground: func () {},
    background: func () {},

    initialize: func () {},

    showKeyboard: func (handler) {
        if (me.keyboardGroup == nil) {
            me.keyboardGroup = me.masterGroup.createChild('group');
        }
        if (me.keyboard == nil) {
            me.keyboard = Keyboard.new(me.keyboardGroup, 0);
            me.rootWidget.appendChild(me.keyboard);
        }
        me.keyboardListenerID = me.keyboard.keyPressed.addListener(handler);
        me.keyboard.setActive(1);
    },

    hideKeyboard: func {
        if (me.keyboard != nil) {
            me.keyboard.keyPressed.removeListener(me.keyboardListenerID);
            me.keyboard.setActive(0);
        }
    },
};
