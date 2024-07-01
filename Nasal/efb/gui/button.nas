include('gui/widget.nas');
include('util.nas');
include('eventSource.nas');

var Button = {
    new: func (parentGroup, label, x, y, w=nil, h=nil) {
        var m = Widget.new();
        m.parents = [me] ~ m.parents;
        m.metrics = {
            width: w,
            height: h,
            left: x,
            top: y,
            fontSize: 20,
            paddingY: 2,
            paddingX: 8,
        };
        m.label = label;

        m.initialize(parentGroup);
        return m;
    },

    initialize: func (parentGroup) {
        var self = me;
        me.group = parentGroup.createChild('group');
        me.group.setTranslation(me.metrics.left, me.metrics.top);
        me.box = me.group.createChild('path');
        me.textElem = me.group.createChild('text')
                              .setFont(font_mapper('sans', 'bold'))
                              .setFontSize(me.metrics.fontSize)
                              .setColor(1, 1, 1)
                              .setText(me.label)
                              .setAlignment('left-baseline');
        var textDimensions = me.textElem.getBoundingBox();
        var textWidth = textDimensions[2] - textDimensions[0];
        var textHeight = me.metrics.fontSize;
        if (me.metrics.width == nil)
            me.metrics.width = textWidth + me.metrics.paddingX * 2;
        if (me.metrics.height == nil)
            me.metrics.height = textHeight + me.metrics.paddingY * 2;
        var r = 4;
        me.box.moveTo(0, r)
              .arcSmallCW(r, r, 0, r, -r)
              .line(me.metrics.width - 2 * r, 0)
              .arcSmallCW(r, r, 0, r, r)
              .line(0, me.metrics.height - 2 * r)
              .arcSmallCW(r, r, 0, -r, r)
              .line(-me.metrics.width + 2 * r, 0)
              .arcSmallCW(r, r, 0, -r, -r)
              .line(0, -me.metrics.height + 2 * r)
              .setColorFill(0, 0, 0.5);
        me.where = me.box;
        me.textElem.setTranslation(
                (me.metrics.width - textWidth) * 0.5,
                me.metrics.height * 0.5 + textHeight * 0.3);
    },
};


