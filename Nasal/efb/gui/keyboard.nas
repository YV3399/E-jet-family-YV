include('gui/widget.nas');
include('util.nas');
include('eventSource.nas');


var Keyboard = {
    new: func (parentGroup, active) {
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
        m.slideState = 1;
        m.slideRate = 4;
        m.active = active;
        m.keyGlows = [];
        m.keyGlowRate = 10;
        m.keyboardGrabbedProp = props.globals.getNode('instrumentation/efb/keyboard-grabbed', 1);
        m.allowKeyboardGrabbingProp = props.globals.getNode('instrumentation/efb/allow-keyboard-grabbing', 1);
        m.keyboardInputProp = props.globals.getNode('instrumentation/efb/input/keyboard', 1);
        m.inputListener = nil;
        m.initialize(parentGroup);
        return m;
    },

    updateKeyGlows: func (dt) {
        foreach (var keyGlow; me.keyGlows) {
            keyGlow.counter -= dt * me.keyGlowRate;
            var f = math.min(1, math.max(0, 1 - keyGlow.counter));
            keyGlow.elem.setColorFill(
                keyGlow.color.r * f,
                keyGlow.color.g * f,
                keyGlow.color.b * f
            );
        }
        while (size(me.keyGlows) > 0 and me.keyGlows[0].counter <= 0)
            me.keyGlows = subvec(me.keyGlows, 1);
        if (size(me.keyGlows) == 0)
            me.keyGlowTimer.stop();
    },

    startKeyGlow: func (elem, r, g, b) {
        append(me.keyGlows, {
            elem: elem,
            color: {
                r: r,
                g: g,
                b: b,
            },
            counter: 1,
        });
        me.keyGlowTimer.start();
    },

    updateSlide: func (dt) {
        if (me.active) {
            if (me.slideState < 1) {
                me.slideState += dt * me.slideRate;
                me.slideState = math.min(1, me.slideState);
                me.masterGroup.setTranslation(0, 768 - me.metrics.height * me.slideState);
            }
            else {
                me.slideTimer.stop();
            }
        }
        else {
            if (me.slideState > 0) {
                me.slideState -= dt * me.slideRate;
                me.slideState = math.max(0, me.slideState);
                me.masterGroup.setTranslation(0, 768 - me.metrics.height * me.slideState);
            }
            else {
                me.slideTimer.stop();
            }
        }
    },

    grabKeyboard: func {
        var self = me;
        me.inputListener = setlistener(me.keyboardInputProp, func (node) {
            self.handleKey(node.getValue());
        }, 0, 1);
        me.keyboardGrabbedProp.setValue(1);
    },

    releaseKeyboard: func {
        if (me.inputListener != nil) {
            removelistener(me.inputListener);
            me.inputListener = nil;
        }
        me.keyboardGrabbedProp.setValue(0);
    },

    updateKeyboardGrab: func {
        if (me.active and me.allowKeyboardGrabbingProp.getBoolValue()) {
            me.grabKeyboard();
        }
        else {
            me.releaseKeyboard();
        }
    },

    setActive: func (active) {
        call(Widget.setActive, [active], me);
        me.slideTimer.start();
        me.updateKeyboardGrab();
        return me;
    },

    initialize: func (parentGroup) {
        var self = me;
        var animationDT = 0.025;
        me.masterGroup = parentGroup.createChild('group').set('z-index', 1000);
        me.slideState = me.active;
        if (me.active) {
            me.masterGroup.setTranslation(0, 768 - me.metrics.height);
        }
        else {
            me.masterGroup.setTranslation(0, 768);
        }
        me.layers = [
        ];
        me.keyGlowTimer = maketimer(animationDT, func {
            self.updateKeyGlows(animationDT);
        });
        for (var i = me.LAYER_LOWER; i < me.NUM_LAYERS; i += 1) {
            var layerGroup = me.masterGroup.createChild('group');
            var frame = layerGroup.createChild('path')
                      .rect(0, 0, me.metrics.width, me.metrics.height)
                      .setColorFill(0.7, 0.7, 0.7);
            var layerWidget = Widget.new(frame).setClickHandler(func 0);
            me.appendChild(layerWidget);
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
                var rowWidth = 0;
                var hasSpace = 0;
                var spaceWidth = keyWidth;
                foreach (var key; row) {
                    if (key == 'space') {
                        hasSpace = 1;
                    }
                    elsif (key == 'backspace' or key == 'caps' or key == 'enter' or key == 'alpha' or key == 'symbols') {
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
                    elsif (key == 'backspace' or key == 'caps' or key == 'enter' or key == 'alpha' or key == 'symbols') {
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

                    var keyColor = [0.9, 0.9, 0.9];

                    if (key == 'enter') {
                        keyColor = [0.3, 0.85, 0.3];
                    }

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
                                            .setColorFill(keyColor[0], keyColor[1], keyColor[2])
                                            .setColor(0.3, 0.3, 0.3);
                    var capElem = me.keycap(layerGroup, key, x + width / 2, y + keyHeight / 2);
                    capElem.setColor(0.1, 0.1, 0.1);
                    if (key == 'enter') {
                        capElem.setColorFill(0.9, 0.9, 0.9);
                    }
                    (func (key, keyElem, keyColor) {
                        layerWidget.appendChild(
                            Widget.new(keyElem)
                                .setClickHandler(func () {
                                    self.startKeyGlow(keyElem, keyColor[0], keyColor[1], keyColor[2]);
                                    self.handleKey(key);
                                }));
                    })(key, keyElem, keyColor);
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
        me.slideTimer = maketimer(animationDT, func {
            self.updateSlide(animationDT);
        });
        me.updateKeyboardGrab();
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
        if (key == 'caps') {
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

    handleKey: func (key, up=0) {
        if (up) {
            if (key == 'shift') {
                me.selectLayer(me.currentLayer & 0xFE);
            }
        }
        else {
            if (key == 'symbols') {
                me.selectLayer(me.LAYER_SYM1);
            }
            elsif (key == 'alpha') {
                me.selectLayer(me.LAYER_LOWER);
            }
            elsif (key == 'caps') {
                me.selectLayer(me.currentLayer ^ 0x01);
            }
            elsif (key == 'shift') {
                me.selectLayer(me.currentLayer | 0x01);
            }
            else {
                me.keyPressed.raise(key);
            }
        }
    },

    keycapText: func (key) {
        if (key == 'space')
            return '';
        elsif (key == 'backspace')
            return '<-';
        elsif (key == 'caps') {
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
        , [ 'caps', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'backspace' ]
        , [ 'symbols', ',', 'space', '.', 'enter' ]
        ],
        [ [ 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P' ]
        , [ 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L' ]
        , [ 'caps', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'backspace' ]
        , [ 'symbols', ',', 'space', '.', 'enter' ]
        ],
        [ [ '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' ]
        , [ '@', '#', '$', '_', '&', '-', '+', '(', ')', '/' ]
        , [ 'caps', '*', '"', "'", ':', ';', '!', '?', 'backspace' ]
        , [ 'alpha', ',', 'space', '.', 'enter' ]
        ],
        [ [ '~', '`', '|', '·', '√', 'π', '÷', '×', '¶', 'Δ' ]
        , [ '£', '¢', '€', '¥', '^', '°', '=', '{', '}', "\\" ]
        , [ 'caps', '%', '©', '®', '™', '✓', '[', ']', 'backspace' ]
        , [ 'alpha', '<', 'space', '>', 'enter' ]
        ],
    ],
};
