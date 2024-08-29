include('baseApp.nas');
include('gui/pager.nas');

var KneepadApp = {
    new: func(masterGroup) {
        var m = BaseApp.new(masterGroup);
        m.parents = [me] ~ m.parents;
        m.scrollY = 0;
        m.maxScrollY = 0;
        m.text = [];
        m.editing = 0;
        m.cursor = { row: 0, col: 0 };
        m.cursorBlinkState = 0;
        return m;
    },

    handleBack: func () {
    },

    initialize: func () {
        var self = me;
        me.metrics = {
            fontSize: 24,
            lineHeight: 38,
            font: 'sans',
            marginTop: 40,
            marginLeft: 5,
            screenW: me.efb.metrics.screenW,
            screenH: me.efb.metrics.screenH,
            menuHeight: 96,
            verticalScrollMargin: 256,
        };

        me.pageWidgets = [];

        me.bgfill = me.masterGroup.createChild('path')
                        .rect(0, 0, me.metrics.screenW, me.metrics.screenH)
                        .setColorFill(1, 0.95, 0.8);
        me.textGroup = me.masterGroup.createChild('group')
                         .setTranslation(0, 0);
        me.dummyGroup = me.masterGroup.createChild('group')
                          .setTranslation(-4100, -4100);
        me.dummyText = me.dummyGroup.createChild('text')
                         .setFont(font_mapper(me.metrics.font, 'normal'))
                         .setFontSize(me.metrics.fontSize)
                         .setAlignment('left-baseline');
        
        me.menuGroup = me.masterGroup.createChild('group')
                         .setTranslation(0, me.metrics.screenH - me.metrics.menuHeight);
        var menuBox = me.menuGroup.createChild('path')
                    .rect(-1, 0, me.metrics.screenW + 2, me.metrics.menuHeight + 2)
                    .setColorFill(0.9, 0.9, 0.9)
                    .setColor(0.5, 0.5, 0.5);

        # Menu widget eats clicks on the menu area.
        me.menu = Widget.new(menuBox).setClickHandler(func {
            return 0;
        });

        me.menu.appendChild(
            Widget.new(
                me.menuGroup.createChild('image')
                         .set('src', acdir ~ '/Models/EFB/icons/trash.png')
                         .setScale(0.75, 0.75)
                         .setTranslation(10, 10)
            ).setClickHandler(func self.clearText()));

        me.cursorElem = me.textGroup.createChild('path')
                        .setColorFill(0, 0, 0)
                        .rect(0, 0, 1, me.metrics.fontSize + 4);
        me.cursorInfo = me.masterGroup.createChild('text')
                         .setFont(font_mapper(me.metrics.font, 'normal'))
                         .setFontSize(16)
                         .setColor(0, 0, 0)
                         .setText('')
                         .setTranslation(me.metrics.screenW - 2, 60)
                         .setAlignment('right-baseline');

        me.textElems = [];

        me.rootWidget.appendChild(me.menu);
        me.cursorBlinkTimer = maketimer(0.5, func {
            if (me.editing) {
                me.cursorBlinkState = !me.cursorBlinkState;
                me.cursorElem.setVisible(me.cursorBlinkState);
            }
        });
        me.cursorBlinkTimer.start();
    },

    startEditing: func () {
        var self = me;
        me.showKeyboard(func (key) { self.handleKey(key); });
        me.editing = 1;
        me.updateCursor();
    },

    stopEditing: func () {
        me.hideKeyboard();
        me.editing = 0;
        me.updateCursor();
    },

    background: func {
        me.stopEditing();
        me.cursorBlinkTimer.stop();
    },

    foreground: func {
        me.cursorBlinkTimer.start();
    },

    rowToY: func (row) {
        # This gives the baseline Y coordinate.
        return (row + 1) * me.metrics.lineHeight + me.metrics.marginTop;
    },

    rowFromY: func (y) {
        return math.floor((y - me.metrics.marginTop) / me.metrics.lineHeight - 0.5);
    },

    confineScroll: func {
        var scrollLimit = me.metrics.screenH - me.metrics.verticalScrollMargin;
        me.maxScrollY = (size(me.text) + 1) * me.metrics.lineHeight - scrollLimit;
        me.scrollY = math.min(me.maxScrollY, me.scrollY);
        me.scrollY = math.max(0, me.scrollY);
    },

    wheel: func (axis, amount) {
        if (axis == 0) {
            me.scrollY += me.metrics.lineHeight * amount;
            me.confineScroll();
            me.textGroup.setTranslation(0, -me.scrollY);
            me.updateCursor();
        }
    },

    scrollToRow: func (row) {
        var scrollLimit = me.metrics.screenH - me.metrics.verticalScrollMargin - me.metrics.fontSize - 4; # WHY?
        var y = me.rowToY(row);
        if (y - me.scrollY < me.metrics.marginTop + me.metrics.lineHeight) {
            me.scrollY = y;
        }
        if (y - me.scrollY >= scrollLimit - me.metrics.lineHeight) {
            me.scrollY = y - scrollLimit + me.metrics.lineHeight;
        }
        me.confineScroll();
        me.textGroup.setTranslation(0, -me.scrollY);
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
        var y = me.rowToY(cursor.row);
        var x = me.metrics.marginLeft;
        var box = nil;

        var txt = '';
        if (cursor.row < size(me.text)) {
            txt = me.text[cursor.row];
        }
        if (txt == nil or cursor.col == 0) {
            # just keep the left margin.
        }
        elsif (cursor.col >= utf8.size(txt)) {
            x += me.measureText(txt);
        }
        else {
            x += me.measureText(utf8.substr(txt, 0, cursor.col));
        }
        return { x: x, y: y };
    },

    cursorFromXY: func (x, y) {
        var row = me.rowFromY(y);
        var text = '';
        if (row < size(me.text)) {
            text = me.text[row];
        }
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
        return { row: math.max(0, row), col: math.max(col) };
    },

    updateCursor: func {
        var scrollPercent = 0;
        if (me.maxScrollY > 0)
            scrollPercent = me.scrollY / me.maxScrollY * 100;
        me.cursorInfo.setText(sprintf("%3i:%3i", me.cursor.row, me.cursor.col));
        if (me.editing) {
            var xy = me.cursorToXY();
            me.cursorElem
                    .setTranslation(xy.x, xy.y - me.metrics.fontSize)
                    .show();
            me.cursorInfo.setColor(0, 0, 0);
        }
        else {
            me.cursorElem.hide();
            me.cursorInfo.setColor(0.6, 0.6, 0.6);
        }
    },

    clearText: func {
        me.text = [];
        foreach (var elem; me.textElems) {
            elem.setText('');
        }
        me.cursor.row = 0;
        me.cursor.col = 0;
        me.scrollToRow(0);
        me.updateCursor();
    },

    insertChar: func (c) {
        if (size(me.text) == 0) {
            me.insertNewline();
            me.cursor.row = 0;
            me.cursor.col = 0;
        }
        if (me.cursor.row >= size(me.text))
            me.cursor.row = size(me.text) - 1;
        if (me.cursor.col >= utf8.size(me.text[me.cursor.row]))
            me.cursor.col = utf8.size(me.text[me.cursor.row]);
        me.text[me.cursor.row] =
            utf8.substr(me.text[me.cursor.row], 0, me.cursor.col) ~
            c ~
            utf8.substr(me.text[me.cursor.row], me.cursor.col);
        me.textElems[me.cursor.row].setText(me.text[me.cursor.row]);
        me.cursor.col += 1;
        me.scrollToRow(me.cursor.row);
        me.updateCursor();
    },

    insertNewline: func {
        while (me.cursor.row >= size(me.text)) {
            append(me.text, '');
        }
        var linesBefore = subvec(me.text, 0, me.cursor.row);
        var linesAfter = subvec(me.text, me.cursor.row + 1);
        var currentLine = me.text[me.cursor.row];
        var linesMiddle = [
            utf8.substr(me.text[me.cursor.row], 0, me.cursor.col),
            utf8.substr(me.text[me.cursor.row], me.cursor.col),
        ];

        me.text = linesBefore ~ linesMiddle ~ linesAfter;

        while (size(me.textElems) < size(me.text)) {
            var y = me.rowToY(size(me.textElems));
            append(me.textElems,
                me.textGroup.createChild('text')
                  .setFont(font_mapper('sans', 'normal'))
                  .setFontSize(me.metrics.fontSize)
                  .setAlignment('left-baseline')
                  .setTranslation(me.metrics.marginLeft, y)
                  .setColor(0,0,0)
                  .setText(''));
        }

        for (var row = me.cursor.row; row < size(me.text); row += 1) {
            me.textElems[row].setText(me.text[row]);
        }

        me.cursor.row += 1;
        me.cursor.col = 0;

        me.scrollToRow(me.cursor.row);
        me.updateCursor();
    },

    backspace: func {
        if (size(me.text) == 0)
            return;

        if (me.cursor.row > size(me.text)) {
            me.cursor.row = size(me.text);
            if (me.cursor.row >= size(me.text))
                me.cursor.col = 0;
            else
                me.cursor.col = utf8.size(me.text[me.cursor.row]);
        }

        if (me.cursor.col == 0 and me.cursor.row == 0) {
            # Already at top-left position; stop.
        }
        elsif (me.cursor.col == 0 and me.cursor.row > 0) {
            # Merge this row with the previous one
            var linesBefore = subvec(me.text, 0, me.cursor.row - 1);
            var linesMiddle = subvec(me.text, me.cursor.row - 1, 2);
            var linesAfter = subvec(me.text, math.min(size(me.text), me.cursor.row + 1));
            me.text = linesBefore ~ [ string.join('', linesMiddle) ] ~ linesAfter;
            me.cursor.row -= 1;
            me.cursor.col = utf8.size(linesMiddle[0]);
            me.syncTextElems();
        }
        elsif (me.cursor.col > 0) {
            # Delete from this row
            me.text[me.cursor.row] =
                utf8.substr(me.text[me.cursor.row], 0, math.max(0, me.cursor.col - 1)) ~
                utf8.substr(me.text[me.cursor.row], me.cursor.col);
            me.textElems[me.cursor.row].setText(me.text[me.cursor.row]);
            me.cursor.col -= 1;
        }
        me.scrollToRow(me.cursor.row);
        me.updateCursor();
    },

    del: func {
        if (size(me.text) == 0)
            return;
        if (me.cursor.row >= size(me.text)) {
            # At end of document: nothing to do.
            return;
        }
        if (me.cursor.col >= utf8.size(me.text[me.cursor.row])) {
            # At end of line: merge this row with the next one.
            var linesBefore = subvec(me.text, 0, me.cursor.row);
            var linesMiddle = subvec(me.text, me.cursor.row, 2);
            var linesAfter = subvec(me.text, math.min(size(me.text), me.cursor.row + 2));
            me.text = linesBefore ~ [ string.join('', linesMiddle) ] ~ linesAfter;
            me.syncTextElems();
        }
        else {
            # Delete from current line.
            var currentLine = me.text[me.cursor.row];
            me.text[me.cursor.row] =
                utf8.substr(currentLine, 0, me.cursor.col) ~
                utf8.substr(currentLine, me.cursor.col + 1);
            me.textElems[me.cursor.row].setText(me.text[me.cursor.row]);
        }
        me.updateCursor();
    },

    # Helper function: make sure the text elements shown on screen match our
    # internal text buffer after a larger edit.
    syncTextElems: func {
        for (var row = 0; row < size(me.textElems); row += 1) {
            if (row < size(me.text))
                me.textElems[row].setText(me.text[row]);
            else
                me.textElems[row].setText('');
        }
    },

    moveCursorColTo: func (col) {
        if (size(me.text) == 0) {
            me.cursor.col = 0;
        }
        else {
            me.cursor.col = math.max(0, math.min(utf8.size(me.text[me.cursor.row]), col));
        }
        me.updateCursor();
    },

    moveCursorCol: func (dx) {
        me.cursor.col += dx;
        if (me.cursor.col < 0) {
            if (me.cursor.row == 0) {
                # Already at start of document, nothing to do
                me.cursor.col = 0;
                return;
            }
            else {
                # Jump one line up
                me.cursor.row -= 1;
                me.cursor.col = utf8.size(me.text[me.cursor.row]);
                me.scrollToRow(me.cursor.row);
            }
        }
        else {
            if (size(me.text) == 0) {
                me.cursor.row = 0;
                me.cursor.col = 0;
            }
            elsif (me.cursor.col > utf8.size(me.text[me.cursor.row])) {
                me.cursor.row += 1;
                if (me.cursor.row >= size(me.text)) {
                    me.cursor.row = size(me.text) - 1;
                    me.scrollToRow(me.cursor.row);
                }
                else {
                    me.cursor.col = 0;
                }
            }
        }
        me.updateCursor();
    },

    moveCursorRow: func (dy) {
        me.cursor.row += dy;
        if (size(me.text) == 0 or me.cursor.row < 0) {
            me.cursor.row = 0;
            me.cursor.col = 0;
        }
        elsif (me.cursor.row >= size(me.text)) {
            me.cursor.row = size(me.text) - 1;
            me.cursor.col = utf8.size(me.text[me.cursor.row]);
        }
        else {
            me.cursor.col = math.max(0, math.min(utf8.size(me.text[me.cursor.row]), me.cursor.col));
        }
        me.updateCursor();
        me.scrollToRow(me.cursor.row);
    },

    handleKey: func (key) {
        if (key == 'enter') {
            me.insertNewline();
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
            me.stopEditing();
        }
        elsif (key == 'up') {
            me.moveCursorRow(-1);
        }
        elsif (key == 'down') {
            me.moveCursorRow(1);
        }
        elsif (key == 'left') {
            me.moveCursorCol(-1);
        }
        elsif (key == 'right') {
            me.moveCursorCol(1);
        }
        elsif (key == 'home') {
            me.moveCursorColTo(0);
        }
        elsif (key == 'end') {
            me.moveCursorColTo(999999999);
        }
        elsif (utf8.size(key) == 1) {
            me.insertChar(key);
        }
        else {
            printf("Key not handled: %s", key);
        }
    },

    handleBack: func {
        if (me.editing) {
            me.stopEditing();
        }
    },

    touch: func (x, y) {
        if (!call(BaseApp.touch, [x, y], me))
            return 0;

        var clickpos = me.cursorFromXY(x, y + me.scrollY);
        me.cursor.row = clickpos.row;
        me.cursor.col = clickpos.col;
        if (me.cursor.row >= size(me.text)) {
            me.cursor.row = math.max(0, size(me.text) - 1);
            if (me.cursor.row < size(me.text)) {
                me.cursor.col = utf8.size(me.text[me.cursor.row]);
            }
            else {
                me.cursor.col = 0;
            }
        }
        if (me.editing) {
            me.updateCursor();
        }
        else {
            me.startEditing();
        }
    },
};

registerApp('kneepad', 'Kneepad', 'kneepad.png', KneepadApp);
