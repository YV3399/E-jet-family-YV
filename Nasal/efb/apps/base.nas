include('gui/widget.nas');

var BaseApp = {
    new: func (masterGroup) {
        return {
            parents: [BaseApp],
            masterGroup: masterGroup,
            rootWidget: Widget.new(),
            assetDir: nil,
        }
    },

    setAssetDir: func (assetDir) {
        me.assetDir = assetDir;
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

    handleBack: func () {},
    handleMenu: func () {},
    foreground: func () {},
    background: func () {},

    initialize: func () {},
};
