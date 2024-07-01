include('gui/widget.nas');
include('util.nas');
include('eventSource.nas');

var Textbox = {
    new: func (parentGroup, x, y, w=nil, h=nil) {
        var m = Widget.new();
        m.parents = [me] ~ m.parents;
        m.metrics = {
            width: w,
            height: h,
            left: x,
            top: y,
            fontSize: 20,
            paddingY: 4,
            paddingX: 4,
            font: 'sans',
        };
        m.text = '';
        m.originalText = '';
        m.cursor = 0;
        m.cursorBlinkState = 0;
        m.editing = 0;
        m.onStartEntry = nil;
        m.onEndEntry = nil;
        m.onConfirm = nil;

        m.initialize(parentGroup);
        return m;
    },

    initialize: func (parentGroup) {
        var self = me;
        var textHeight = me.metrics.fontSize;
        if (me.metrics.width == nil)
            me.metrics.width = 512;
        if (me.metrics.height == nil)
            me.metrics.height = textHeight + me.metrics.paddingY * 2;
        me.group = parentGroup.createChild('group');
        me.group.setTranslation(me.metrics.left, me.metrics.top);

        me.box = me.group.createChild('path');
        var r = 2;
        me.box.moveTo(0, r)
              .arcSmallCW(r, r, 0, r, -r)
              .line(me.metrics.width - 2 * r, 0)
              .arcSmallCW(r, r, 0, r, r)
              .line(0, me.metrics.height - 2 * r)
              .arcSmallCW(r, r, 0, -r, r)
              .line(-me.metrics.width + 2 * r, 0)
              .arcSmallCW(r, r, 0, -r, -r)
              .line(0, -me.metrics.height + 2 * r)
              .setColorFill(1, 1, 1)
              .setStrokeLineWidth(1)
              .setColor(0.5, 0.5, 0.5);
        me.where = me.box;

        me.dummyGroup = me.group.createChild('group')
                          .setTranslation(-1000, -1000);
        me.dummyText = me.dummyGroup.createChild('text')
                         .setFont(font_mapper(me.metrics.font, 'normal'))
                         .setFontSize(me.metrics.fontSize)
                         .setAlignment('left-baseline');
        me.textElem = me.group.createChild('text')
                              .setFont(font_mapper(me.metrics.font, 'normal'))
                              .setFontSize(me.metrics.fontSize)
                              .setColor(0, 0, 0)
                              .setText(me.text)
                              .setAlignment('left-baseline');
        me.textElem.setTranslation(me.metrics.paddingX, me.metrics.height * 0.5 + textHeight * 0.4);

        me.cursorElem = me.group.createChild('path')
                        .setColorFill(0, 0, 0)
                        .rect(0, 0, 1, me.metrics.fontSize)
                        .setTranslation(me.metrics.paddingX, me.metrics.paddingY);
        me.cursorBlinkTimer = maketimer(0.5, func {
            if (me.editing) {
                me.cursorBlinkState = !me.cursorBlinkState;
                me.cursorElem.setVisible(me.cursorBlinkState);
            }
        });
        me.cursorElem.setVisible(0);
        if (me.editing)
            me.cursorBlinkTimer.start();
    },

    handleFocus: func (active) {
        if (active and me.editing) {
            me.cursorBlinkTimer.start();
        }
        else {
            me.cursorBlinkTimer.stop();
            me.stopEntry();
        }
    },

    handleTouch: func {
        print("Textbox.handleTouch");
        if (!me.editing)
            me.startEntry();
        return 1;
    },

    startEntry: func {
        me.editing = 1;
        me.originalText = me.text;
        if (me.active) {
            me.cursorBlinkTimer.start();
        }
        if (me.onStartEntry) me.onStartEntry();
    },

    cancelEntry: func {
        me.editing = 0;
        me.text = me.originalText;
        if (me.onEndEntry) me.onEndEntry();
    },

    endEntry: func {
        me.editing = 0;
        if (me.onEndEntry) me.onEndEntry();
    },

    confirmEntry: func {
        me.editing = 0;
        if (me.onEndEntry) me.onEndEntry();
        if (me.onConfirm) me.onConfirm(me.text);
    },

    wantKey: func {
        return me.active and me.editing;
    },

    handleKey: func (key) {
        if (key == 'enter') {
            me.confirmEntry();
        }
        elsif (key == 'backspace') {
            me.backspace();
        }
        elsif (key == 'delete') {
            me.del();
        }
        elsif (key == 'space') {
            me.insertChar(' ');
        }
        elsif (key == 'esc') {
            me.endEntry();
        }
        elsif (key == 'up') {
            me.moveCursorTo(0);
        }
        elsif (key == 'down') {
            me.moveCursorTo(999999999);
        }
        elsif (key == 'left') {
            me.moveCursor(-1);
        }
        elsif (key == 'right') {
            me.moveCursor(1);
        }
        elsif (key == 'home') {
            me.moveCursorTo(0);
        }
        elsif (key == 'end') {
            me.moveCursorTo(999999999);
        }
        elsif (utf8.size(key) == 1) {
            me.insertChar(key);
        }
        else {
            printf("Key not handled: %s", key);
        }
    },

    measureText: func (txt) {
        me.dummyText.setText(txt ~ '|');
        var box = me.dummyText.getBoundingBox();
        var width = box[2] - box[0];
        me.dummyText.setText('|');
        box = me.dummyText.getBoundingBox();
        width -= box[2] - box[0];
        return width;
    },

    cursorToXY: func (cursor=nil) {
        if (cursor == nil)
            cursor = me.cursor;
        var x = me.metrics.paddingX;
        var y = me.metrics.paddingY;
        var box = nil;

        var txt = me.text;
        if (txt == nil or cursor == 0) {
            # just keep the left margin.
        }
        elsif (cursor >= utf8.size(txt)) {
            x += me.measureText(txt);
        }
        else {
            x += me.measureText(utf8.substr(txt, 0, cursor));
        }
        return { x: x, y: y };
    },

    cursorFromXY: func (x, y) {
        var text = me.text;
        var col = utf8.size(text);
        var prevX = me.metrics.marginLeft;
        for (var i = 0; i < utf8.size(text); i += 1) {
            var curX = me.metrics.marginLeft + me.measureText(utf8.substr(text, 0, i + 1));
            if (prevX <= x and curX >= x) {
                col = i;
                break;
            }
            prevX = curX;
        }
        return math.max(col);
    },


    updateCursor: func {
        if (me.editing) {
            var xy = me.cursorToXY();
            me.cursorElem
                    .setTranslation(xy.x, xy.y)
                    .show();
        }
        else {
            me.cursorElem.hide();
        }
    },

    clearText: func {
        me.text = '';
        me.textElem.setText(me.text);
        me.cursor = 0;
        me.updateCursor();
    },

    insertChar: func (c) {
        if (me.cursor >= utf8.size(me.text))
            me.cursor = utf8.size(me.text);
        me.text =
            utf8.substr(me.text, 0, me.cursor) ~
            c ~
            utf8.substr(me.text, me.cursor);
        me.textElem.setText(me.text);
        me.cursor += 1;
        me.updateCursor();
    },

    backspace: func {
        if (size(me.text) == 0)
            return;

        if (me.cursor == 0) {
            # Already at leftmost position; stop.
        }
        else {
            # Delete to left
            me.text =
                utf8.substr(me.text, 0, math.max(0, me.cursor - 1)) ~
                utf8.substr(me.text, me.cursor);
            me.textElem.setText(me.text);
            me.cursor -= 1;
        }
        me.updateCursor();
    },

    del: func {
        if (me.cursor >= utf8.size(me.text)) {
            # At end of line: do nothing
        }
        else {
            # Delete from current line.
            me.text =
                utf8.substr(me.text, 0, me.cursor) ~
                utf8.substr(me.text, me.cursor + 1);
            me.textElem.setText(me.text);
        }
        me.updateCursor();
    },

    moveCursorTo: func (col) {
        me.cursor = math.max(0, math.min(utf8.size(me.text), col));
        me.updateCursor();
    },

    moveCursor: func (dx) {
        me.cursor += dx;
        me.cursor = math.max(0, math.min(me.cursor, utf8.size(me.text)));
        me.updateCursor();
    },

};
