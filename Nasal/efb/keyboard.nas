include('widget.nas');
include('util.nas');
include('eventSource.nas');


var Keyboard = {
    new: func (parentGroup) {
        var m = Widget.new();
        m.parents = [me] ~ m.parents;
        m.keyPressed = EventSource.new();
        m.currentLayer = me.LAYER_LOWER;
        m.metrics = {
            width: 512,
            height: 256,
            fontSize: 24,
            keyMargin: 6,
            paddingBottom: 32,
            cornerRadius: 6,
        };
        m.initialize(parentGroup);
        return m;
    },

    initialize: func (parentGroup) {
        var self = me;
        me.masterGroup = parentGroup.createChild('group');
        me.masterGroup.setTranslation(0, 768 - me.metrics.height);
        me.layers = [
        ];
        for (var i = me.LAYER_LOWER; i < me.NUM_LAYERS; i += 1) {
            var layerGroup = me.masterGroup.createChild('group');
            var layerWidget = Widget.new();
            me.appendChild(layerWidget);
            layerGroup.createChild('path')
                      .rect(0, 0, me.metrics.width, me.metrics.height)
                      .setColorFill(0.7, 0.7, 0.7);
            var layer = me.layerDefs[i];
            # We will assume that the first row has the most keys, and thus
            # determines default key size.
            var numColumns = size(layer[0]);
            var numRows = size(layer);
            var keyWidth = (me.metrics.width - (numColumns + 1) * me.metrics.keyMargin) / numColumns;
            var keyHeight = (me.metrics.height - me.metrics.paddingBottom - (numRows + 1) * me.metrics.keyMargin) / numRows;
            var y = me.metrics.keyMargin;
            for (var j = 0; j < numRows; j += 1) {
                var row = layer[j];
                debug.dump(j, row);
                var rowWidth = 0;
                var hasSpace = 0;
                var spaceWidth = keyWidth;
                foreach (var key; row) {
                    if (key == 'space') {
                        hasSpace = 1;
                    }
                    elsif (key == 'backspace' or key == 'shift' or key == 'enter' or key == 'alpha' or key == 'symbols') {
                        rowWidth += keyWidth * 1.5;
                    }
                    else {
                        rowWidth += keyWidth;
                    }
                }
                rowWidth += (size(row) - 1) * me.metrics.keyMargin;
                if (hasSpace) {
                    var maxRowWidth = me.metrics.width - 2 * me.metrics.keyMargin;
                    spaceWidth = maxRowWidth - rowWidth;
                    rowWidth = maxRowWidth;
                }
                var x = (me.metrics.width - rowWidth) / 2;
                foreach (var key; row) {
                    var width = keyWidth;
                    if (key == 'space') {
                        width = spaceWidth;
                    }
                    elsif (key == 'backspace' or key == 'shift' or key == 'enter' or key == 'alpha' or key == 'symbols') {
                        width = keyWidth * 1.5;
                    }
                    else {
                        width = keyWidth;
                    }

                    var l = math.floor(x);
                    var r = math.ceil(x + width);
                    var t = math.floor(y);
                    var b = math.ceil(y + keyHeight);
                    var radius = me.metrics.cornerRadius;

                    var keyElem = layerGroup.createChild('path')
                                            .moveTo(l + radius, t)
                                            .lineTo(r - radius, t)
                                            .arcSmallCWTo(radius, radius, 0, r, t + radius)
                                            .lineTo(r, b - radius)
                                            .arcSmallCWTo(radius, radius, 0, r - radius, b)
                                            .lineTo(l + radius, b)
                                            .arcSmallCWTo(radius, radius, 0, l, b - radius)
                                            .lineTo(l, t + radius)
                                            .arcSmallCWTo(radius, radius, 0, l + radius, t)
                                            .setColorFill(0.9, 0.9, 0.9)
                                            .setColor(0.3, 0.3, 0.3);
                    var capElem = me.keycap(layerGroup, key, x + width / 2, y + keyHeight / 2);
                    capElem.setColor(0.1, 0.1, 0.1);
                    if (key == 'enter') {
                        keyElem.setColorFill(0.3, 0.85, 0.3);
                        capElem.setColorFill(0.9, 0.9, 0.9);
                    }
                    (func (key) {
                        layerWidget.appendChild(
                            Widget.new(keyElem)
                                .setHandler(func () {
                                    self.handleKey(key);
                                }));
                    })(key);
                    x += me.metrics.keyMargin + width;
                }
                y += me.metrics.keyMargin + keyHeight;
            }
            append(me.layers, {
                group: layerGroup,
                widget: layerWidget
            });
        }
        me.selectLayer(me.currentLayer);
    },

    selectLayer: func (l) {
        me.currentLayer = l;
        for (var i = 0; i < me.NUM_LAYERS; i += 1) {
            me.layers[i].group.setVisible(i == l);
            me.layers[i].widget.setActive(i == l);
        }
    },

    keycap: func (group, key, x, y) {
        var s = me.metrics.fontSize / 2;
        if (key == 'shift') {
            return group.createChild('path')
             .setTranslation(x, y)
             .move(0, -s)
             .line(s, s)
             .line(-0.5*s, 0)
             .line(0, s)
             .line(-s, 0)
             .line(0, -s)
             .line(-0.5*s, 0)
             .line(s, -s);
        }
        elsif (key == 'backspace') {
            return group.createChild('path')
             .setTranslation(x, y)
             .move(-1.25 * s, 0)
             .line(s, 0.75 * s)
             .line(0, -0.5 * s)
             .line(1.5 * s, 0)
             .line(0, -0.5 * s)
             .line(-1.5 * s, 0)
             .line(0, -0.5 * s)
             .line(-s, 0.75 * s);
        }
        elsif (key == 'enter') {
            return group.createChild('path')
             .setTranslation(x, y)
             .move(-1.5 * s, 0)
             .line(s, -0.75 * s)
             .line(0, 0.5 * s)
             .line(1.25 * s, 0)
             .line(0, -0.75 * s)
             .line(0.5 * s, 0)
             .line(0, 0.5 * s)
             .line(0, 0.75 * s)
             .line(-1.75 * s, 0)
             .line(0, 0.5 * s)
             .line(-s, -0.75 * s);
        }
        else {
            return group.createChild('text')
                    .setAlignment('center-baseline')
                    .setFont(font_mapper('sans', 'normal'))
                    .setFontSize(me.metrics.fontSize, 1)
                    .setTranslation(x, y + me.metrics.fontSize / 3)
                    .setText(me.keycapText(key));
        }
    },

    handleKey: func (key) {
        if (key == 'symbols') {
            me.selectLayer(me.LAYER_SYM1);
        }
        elsif (key == 'alpha') {
            me.selectLayer(me.LAYER_LOWER);
        }
        elsif (key == 'shift') {
            me.selectLayer(me.currentLayer ^ 1);
        }
        else {
            me.keyPressed.raise(key);
        }
    },

    keycapText: func (key) {
        if (key == 'space')
            return '';
        elsif (key == 'backspace')
            return '<-';
        elsif (key == 'shift') {
            return 'SHIFT';
        }
        elsif (key == 'alpha') {
            return 'ABC';
        }
        elsif (key == 'symbols') {
            return '#$%'
        }
        elsif (key == 'enter') {
            return 'ENTER';
        }
        else {
            return key;
        }
    },

    LAYER_LOWER: 0,
    LAYER_UPPER: 1,
    LAYER_SYM1: 2,
    LAYER_SYM2: 3,
    NUM_LAYERS: 4,

    layerDefs: [
        [ [ 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p' ]
        , [ 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l' ]
        , [ 'shift', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'backspace' ]
        , [ 'symbols', ',', 'space', '.', 'enter' ]
        ],
        [ [ 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P' ]
        , [ 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L' ]
        , [ 'shift', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'backspace' ]
        , [ 'symbols', ',', 'space', '.', 'enter' ]
        ],
        [ [ '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' ]
        , [ '@', '#', '$', '_', '&', '-', '+', '(', ')', '/' ]
        , [ 'shift', '*', '"', "'", ':', ';', '!', '?', 'backspace' ]
        , [ 'alpha', ',', 'space', '.', 'enter' ]
        ],
        [ [ '~', '`', '|', '·', '√', 'π', '÷', '×', '¶', 'Δ' ]
        , [ '£', '¢', '€', '¥', '^', '°', '=', '{', '}', "\\" ]
        , [ 'shift', '%', '©', '®', '™', '✓', '[', ']', 'backspace' ]
        , [ 'alpha', '<', 'space', '>', 'enter' ]
        ],
    ],
};
