include('util.nas');
include('dom.nas');

var makeDefaultRenderContext = func (group, fontMapper, left, top, width, height) {
    return {
        group: group,
        fontMapper: fontMapper,
        dpi: 96,
        debugLayout: 0,
        viewport: Box.new(left, top, width, height),
    };
};

var cascadeStyle = func (parentStyle, childStyle) {
    if (parentStyle == nil) {
        return childStyle;
    }
    var combinedStyle = {};
    foreach (var k; keys(parentStyle)) {
        if (childStyle[k] == nil or childStyle[k] == 'inherit') {
            combinedStyle[k] = parentStyle[k];
        }
    }
    return mergeDicts(childStyle, combinedStyle);
};

var rootStyle = mergeDicts(DOM.defaultStyle, {
    'font-size': '10pt',
    'font-family': 'sans',
    'font-weight': 'normal',
    'text-style': 'normal',
    'text-decoration': 'none',
    'text-align': 'left',
    'line-height': 1.25,
    'color': 'black',

    'padding-left': '1rem',
    'padding-top': '1rem',
    'padding-right': '1rem',
    'padding-bottom': '1rem',

    'background-color': 'none',
});

var dimensionalStyleKeys = [
    'font-size',

    'border-left-width',
    'border-right-width',
    'border-top-width',
    'border-bottom-width',

    'padding-left',
    'padding-right',
    'padding-top',
    'padding-bottom',

    'margin-left',
    'margin-right',
    'margin-top',
    'margin-bottom',

    'min-width',
    'max-width',
    'width',

    'min-height',
    'max-height',
    'height',
];

var verbatimStyleKeys = [
    'font-family',
    'font-weight',
    'text-style',
    'text-decoration',
    'line-height',

    'vertical-align',
    'text-align',
];

var colorStyleKeys = [
    'color',
    'border-color',
    'background-color',
    'border-left-color',
    'border-right-color',
    'border-top-color',
    'border-bottom-color',
];

var resolveUnit = func (renderContext, parentMetrics, valueKey, value, unit) {
    if (unit == 'px') {
        return value;
    }
    elsif (unit == 'em') {
        return value * parentMetrics['font-size'];
    }
    elsif (unit == 'rem') {
        return value * parentMetrics['font-size-base'];
    }
    elsif (unit == '%') {
        return value * parentMetrics[valueKey] / 100;
    }
    elsif (unit == 'mm') {
        return value * renderContext.dpi * M2IN / 1000;
    }
    elsif (unit == 'cm') {
        return value * renderContext.dpi * M2IN / 100;
    }
    elsif (unit == 'in') {
        return value * renderContext.dpi;
    }
    elsif (unit == 'pt') {
        return value * renderContext.dpi / 72;
    }
    elsif (unit == 'vw') {
        return value * renderContext.viewport.width() / 100;
    }
    elsif (unit == 'vh') {
        return value * renderContext.viewport.height() / 100;
    }
    else {
        return value;
    }
};

var defaultColors = {
    'background-color': [255, 255, 255, 0],
};

var namedColors = {
    'transparent': [0,0,0,0],
    'none':        [0,0,0,0],
    'black':   [0,0,0],
    'silver':  [192,192,192],
    'gray':    [128,128,128],
    'white':   [255,255,255],
    'maroon':  [128,0,0],
    'red':     [255,0,0],
    'purple':  [128,0,128],
    'fuchsia': [255,0,255],
    'green':   [0,128,0],
    'lime':    [0,255,0],
    'olive':   [128,128,0],
    'yellow':  [255,255,0],
    'navy':    [0,0,128],
    'blue':    [0,0,255],
    'teal':    [0,128,128],
    'aqua':    [0,255,255],
};

var resolveColor = func (key, color) {
    if (color == 'none' or color == nil) {
        return 'none';
    }
    var default = denull(defaultColors[key], [0,0,0,1]);

    if (typeof(color) == 'scalar') {
        color = denull(namedColors[color], default);
    }
    if (color == nil) {
        color = default;
    }

    if (typeof(color) == 'vector') {
        return
            [ size(color) > 0 ? (color[0] / 255) : 0
            , size(color) > 1 ? (color[1] / 255) : 0
            , size(color) > 2 ? (color[2] / 255) : 0
            , size(color) > 3 ? color[3] : 1
            ]
    }
    else {
        return [0,0,0,0];
    }
};

var splitDimensional = func (str) {
    if (str == nil or str == '')
        return [0, ''];
    var result = [];
    var i = 0;
    if (typeof(str) != 'scalar')
        debug.dump(str);
    str = str ~ '';
    while (i < size(str) and (string.isdigit(str[i]) or str[i] == '-'[0] or str[i] == '.'[0])) {
        i += 1;
    }
    var value = substr(str, 0, i);
    var unit = substr(str, i);
    return [value, unit];
};

var Box = {
    new: func(l, t, w=0, h=0) {
        return {
            parents: [me],
            l: l,
            t: t,
            w: w,
            h: h
        };
    },

    clone: func {
        return Box.new(me.l, me.t, me.w, me.h);
    },

    left: func me.l,
    right: func me.l + me.w,
    top: func me.t,
    bottom: func me.t + me.h,
    width: func me.w,
    height: func me.h,

    rect: func { return [ me.l, me.t, me.w, me.h ]; },

    draw: func (group) {
        return group.createChild('path')
                    .rect(me.l, me.t, me.w, me.h);
    },

    setLeft: func (v) { me.l = v; return me; },
    setRight: func (v) { me.w = v - me.l; return me; },
    setTop: func (v) { me.t = v; return me; },
    setBottom: func (v) { me.h = v - me.t; return me; },
    setWidth: func (v) { me.w = v; return me; },
    setHeight: func (v) { me.h = v; return me; },

    move: func (dx, dy) { me.l += dx; me.t += dy; return me; },

    resizeCentered: func (w, h) {
        me.l += (me.w - w) * 0.5;
        me.r += (me.h - h) * 0.5;
        me.w = w;
        me.h = h;
        return me;
    },

    resizeTopLeft: func (w, h) {
        me.w = w;
        me.h = h;
        return me;
    },

    resizeBottomRight: func (w, h) {
        me.l += me.w - w;
        me.r += me.h - h;
        me.w = w;
        me.h = h;
        return me;
    },

    growCentered: func (dw, dh) {
        dw = math.max(-me.w, dw);
        dh = math.max(-me.h, dh);
        me.l -= dw * 0.5;
        me.t -= dh * 0.5;
        me.w += dw;
        me.h += dh;
        return me;
    },

    extend: func (dl, dt, dr, db) {
        me.l -= dl;
        me.t -= dt;
        me.w += dl + dr;
        me.h += dt + db;
        return me;
    },
};

var Node = {
    new: func (domNode, style=nil) {
        return {
            parents: [me],
            domNode: domNode,
            style: copyDict(style), # declared style
            metrics: {},
        };
    },

    wordSplit: func [],

    # Calculate the layout-agnostic base metrics. These are:
    # - style metrics: font properties, margins, paddings, borders, colors,
    #   alignment, and anything else that directly reflects CSS properties.
    # - size metrics (used for inline flow calculations):
    #   - inline-width (minimum width in an inline context, including padding)
    #   - above-baseline (size of minimum box above the baseline)
    #   - below-baseline (size of minimum box below the baseline)
    #   - min-spacing (minimum spacing between this and adjacent elements)
    # - child metrics: recurse into children, if any.
    # All other metrics, and particularly positions and actual box sizes, are
    # calculated as part of the layout step.
    # The reason for having a separate step here is so that we can pass the
    # render context in, which is needed so we can probe elements for their
    # actual rendered sizes.
    calcMetrics: func (renderContext, parentMetrics) {
        me.calcStyleMetrics(renderContext, parentMetrics);
        me.calcChildMetrics(renderContext);
        me.calcSizeMetrics(renderContext, parentMetrics);
    },

    calcStyleMetrics: func (renderContext, parentMetrics) {
        # The general idea here is:
        # - if the node's CSS style doesn't have a property, or if it is set to
        #   'inherit', then use the parent metric
        # - otherwise, calculate the effective metric from the node's CSS
        #   style, using the parent metric to resolve relative sizes.
        # We need to distinguish between "dimensional" style properties, which
        # specify lengths with units (and thus also support relative sizes);
        # "verbatim" style properties, which can only be inherited or
        # overridden wholesale; and "color" style properties, which, while only
        # inherited verbatim, need to be mapped from CSS colors (0..255 RGB) to
        # Canvas colors (0.0..1.0 RGB).

        # `font-size-base` is special though; this is not a real CSS property,
        # but we use it to thread 'rem' units throughout the document. The
        # rules are simple:
        # - if the parentMetrics defines this property, then we will use it
        #   unconditionally: this means we are not the root element, and should
        #   just use whatever the parent uses.
        # - if the parentMetrics does *not* define it, then this means we are
        #   the top-level element, and we will set it to our own font size.

        if (parentMetrics['font-size-base'] == nil) {
            var fontSizeCSS = denull(me.style['font-size'], '10pt');
            var (value, unit) = splitDimensional(fontSizeCSS);
            var pixelValue = resolveUnit(renderContext, parentMetrics, 'font-size-base', value, unit);
            me.metrics['font-size-base'] = pixelValue;
            parentMetrics['font-size-base'] = pixelValue;
        }
        else {
            me.metrics['font-size-base'] = parentMetrics['font-size-base'];
        }

        foreach (var k; dimensionalStyleKeys) {
            if (me.style[k] == nil or me.style[k] == 'inherit') {
                me.metrics[k] = parentMetrics[k];
            }
            elsif (me.style[k] == 'auto') {
                # 'auto' needs special treatment; we will check for it in
                # the `style` property, where it will be retained, and set it
                # to 0 in the `metrics`.
                me.metrics[k] = 0;
            }
            else {
                var (value, unit) = splitDimensional(me.style[k]);
                var pixelValue = resolveUnit(renderContext, parentMetrics, k, value, unit);
                me.metrics[k] = pixelValue;
            }
        }
        foreach (var k; verbatimStyleKeys) {
            if (me.style[k] == nil or me.style[k] == 'inherit') {
                me.metrics[k] = parentMetrics[k];
            }
            else {
                me.metrics[k] = me.style[k];
            }
        }
        foreach (var k; colorStyleKeys) {
            if (me.style[k] == nil or me.style[k] == 'inherit') {
                me.metrics[k] = parentMetrics[k];
            }
            else {
                me.metrics[k] = resolveColor(k, me.style[k]);
            }
        }
    },

    calcSizeMetrics: func (renderContext, parentMetrics) { },
    calcChildMetrics: func (renderContext) { },

    # The layout functions should populate the following metrics:
    # - 'content-box'
    # - 'padding-box'
    # - 'border-box'
    # - 'margin-box'
    # - 'baseline' (used for placing text inside the content-box)

    # Layout the element in an inline context. It is assumed that the parent
    # has calculated a suitable placement, so only the following parameters
    # are given:
    # - x: the left edge of the content box
    # - y: the reference line for the parent line box
    # - prevX: the right edge of the preceding node's sibling, if that node is
    #          part of the same DOM element. We need this to make underlines
    #          extend across whitespace within DOM elements.
    layoutInline: func (x, y, prevX) {
        me.metrics['content-box'] =
            Box.new(x, y - metrics['above-baseline'],
                me.metrics['inline-width'],
                me.metrics['above-baseline'] + me.metrics['below-baseline']);
        me.metrics['baseline'] = me.metrics['above-baseline'];
        me.metrics['previous-x'] = prevX;
        me.boxesFromContentBox();
    },

    # Layout the element in a block context.
    # The default implementation will fill the entire available space, which
    # is almost certainly not what you want.
    layoutBlock: func(parentBox) {
        me.metrics['margin-box'] = parentBox.clone();
        me.boxesFromMarginBox();
    },

    # Calculate all other boxes from the content-box
    boxesFromContentBox: func {
        me.metrics['padding-box'] =
            me.metrics['content-box'].clone()
              .extend(
                me.metrics['padding-left'],
                me.metrics['padding-top'],
                me.metrics['padding-right'],
                me.metrics['padding-bottom']);
        me.metrics['border-box'] =
            me.metrics['padding-box'].clone()
              .extend(
                me.metrics['border-left-width'],
                me.metrics['border-top-width'],
                me.metrics['border-right-width'],
                me.metrics['border-bottom-width']);
        me.metrics['margin-box'] =
            me.metrics['padding-box'].clone()
              .extend(
                me.metrics['margin-left'],
                me.metrics['margin-top'],
                me.metrics['margin-right'],
                me.metrics['margin-bottom']);
    },

    # Calculate all other boxes from the margin-box
    boxesFromMarginBox: func {
        me.metrics['border-box'] =
            me.metrics['margin-box'].clone()
              .extend(
                -me.metrics['margin-left'],
                -me.metrics['margin-top'],
                -me.metrics['margin-right'],
                -me.metrics['margin-bottom']);
        me.metrics['padding-box'] =
            me.metrics['border-box'].clone()
              .extend(
                -me.metrics['border-left-width'],
                -me.metrics['border-top-width'],
                -me.metrics['border-right-width'],
                -me.metrics['border-bottom-width']);
        me.metrics['content-box'] =
            me.metrics['padding-box'].clone()
              .extend(
                -me.metrics['padding-left'],
                -me.metrics['padding-top'],
                -me.metrics['padding-right'],
                -me.metrics['padding-bottom']);
    },


    render: func (renderContext) {
        me.renderBorderAndBackground(renderContext);
        if (renderContext['debugLayout']) {
            me.renderDebugLayout(renderContext);
        }
        me.renderListMarker(renderContext);
        me.renderContent(renderContext);
    },

    renderDebugLayout: func (renderContext) {
        me.metrics['margin-box']
            .draw(renderContext.group)
            .setColor([1, 1, 0])
            .setColorFill([1, 1, 0, 0.3]);
        me.metrics['padding-box']
            .draw(renderContext.group)
            .setColor([0, 0, 0.5])
            .setColorFill([0, 0, 0.5, 0.3]);
        me.metrics['content-box']
            .draw(renderContext.group)
            .setColor([0.5, 1, 1])
            .setColorFill([0.5, 1, 1, 0.3]);
        if (!me.isBlock()) {
            renderContext.group.createChild('path')
                .setColor(1, 0, 0)
                .moveTo(
                    me.metrics['content-box'].left(),
                    me.metrics['content-box'].top() + me.metrics['above-baseline'])
                .line(me.metrics['inline-width'], 0);
        }
    },

    renderBorderAndBackground: func (renderContext) {
        if (me.metrics['background-color'] != 'none') {
            var box = me.metrics['padding-box'].clone();
            if (me.metrics['previous-x']) {
                box.extend(me.metrics['content-box'].left() - me.metrics['previous-x'], 0, 0, 0);
            }
            box.draw(renderContext.group)
                .set('z-index', -1)
                .setStrokeLineWidth(1)
                .setColorFill(me.metrics['background-color']);
        }

        var getBorderWidth = func (direction) {
            var w = me.metrics['border-' ~ direction ~ '-width'];
            if (w == nil or w == 'none' or w <= 0 or
                (direction == 'left' and me.metrics['first-of-element']) or
                (direction == 'right' and me.metrics['last-of-element']))
                return 0;
            else
                return w;
        };

        var getBorderColor = func (direction) {
            var c = me.metrics['border-' ~ direction ~ '-color'];
            if (c == 'auto')
                c = me.metrics['color'];
            if (c == 'none')
                c = [0,0,0,0];
            return c;
        };

        var drawBorderSide = func (direction) {
            var borderWidth = getBorderWidth(direction);
            if (borderWidth <= 0) {
                return;
            }
            var borderColor = getBorderColor(direction);

            var path = renderContext.group.createChild('path')
                            .setColor(borderColor)
                            .setStrokeLineWidth(borderWidth);

            if (direction == 'left') {
                path.moveTo(
                    me.metrics['border-box'].left() + borderWidth * 0.5,
                    me.metrics['border-box'].top());
                path.line(0, me.metrics['border-box'].height());
            }
            elsif (direction == 'right') {
                path.moveTo(
                    me.metrics['border-box'].right() - borderWidth * 0.5,
                    me.metrics['border-box'].top());
                path.line(0, me.metrics['border-box'].height());
            }
            elsif (direction == 'top') {
                path.moveTo(
                    me.metrics['border-box'].left(),
                    me.metrics['border-box'].top() + borderWidth * 0.5);
                path.line(me.metrics['border-box'].width(), 0);
            }
            elsif (direction == 'bottom') {
                path.moveTo(
                    me.metrics['border-box'].left(),
                    me.metrics['border-box'].bottom() - borderWidth * 0.5);
                path.line(me.metrics['border-box'].width(), 0);
            }
        };
        drawBorderSide('left');
        drawBorderSide('right');
        drawBorderSide('top');
        drawBorderSide('bottom');
    },

    renderListMarker: func (renderContext) {
        if (me.style['display'] == 'list-item') {
            var type = me.style['list-style-type'];
            if (type != nil and type != 'none') {
                var fontSize = me.metrics['font-size'];
                var fontFamily = denull(me.metrics['font-family'], 'sans');
                var fontWeight = denull(me.metrics['font-weight'], 'regular');
                var x = me.metrics['content-box'].left() - fontSize * 0.5;
                var r = me.metrics['content-box'].left();
                var y = me.metrics['content-box'].top() + me.metrics['above-baseline'] * 0.5;
                var bl = me.metrics['content-box'].top() + me.metrics['above-baseline'];
                var h = fontSize * 0.3;
                var alignment = 'right-baseline';
                if (me.metrics['vertical-align'] == 'top') {
                    alignment = 'right-top';
                }
                elsif (me.metrics['vertical-align'] == 'bottom') {
                    alignment = 'right-bottom';
                }
                elsif (me.metrics['vertical-align'] == 'middle') {
                    alignment = 'right-center';
                }

                if (type == 'disc') {
                    renderContext.group.createChild('path')
                        .circle(h * 0.5, x, y)
                        .setColorFill(me.metrics['color']);
                }
                elsif (type == 'circle') {
                    renderContext.group.createChild('path')
                        .circle(h * 0.5, x, y)
                        .setColor(me.metrics['color']);
                }
                elsif (type == 'square') {
                    renderContext.group.createChild('path')
                        .rect(x - h * 0.5, y - h * 0.5, h, h)
                        .setColorFill(me.metrics['color']);
                }
                elsif (type == 'decimal') {
                    renderContext.group.createChild('text')
                        .setFont(renderContext.fontMapper(fontFamily, fontWeight))
                        .setFontSize(fontSize, 1)
                        .setAlignment(alignment)
                        .setTranslation(r, bl)
                        .setColor(me.metrics['color'])
                        .setText(sprintf('%i. ', me.domNode.siblingIndex + 1));
                }
            }
        }
    },
};

var InlineContainer = {
    new: func (domNode, children, style=nil) {
        var m = Node.new(domNode, style);
        m.parents = [me] ~ m.parents;
        m.children = children;
        return m;
    },

    wordSplit: func {
        var result = [];
        foreach (var child; me.children) {
            result = result ~ child.wordSplit();
        }
        if (me.domNode.getNodeType() == 'element' and result != []) {
            result[0].metrics['first-of-element'] = 1;
            result[size(result) - 1].metrics['last-of-element'] = 1;
        }
        return result;
    },

    calcChildMetrics: func (renderContext) {
        foreach (var child; me.children) {
            child.calcMetrics(renderContext, me.metrics);
        }
    },

    layoutInline: func (x, y, previousX) {
        die('Cannot layout InlineContainers directly; wordSplit them first.');
    },

    layoutBlock: func (parentBox) {
        die('Cannot layout InlineContainers directly; wordSplit them first.');
    },

    render: func (renderContext) {
        foreach (var child; me.children) {
            child.render(renderContext);
        }
    },

    isBlock: func 0,
};

var InlineText = {
    new: func (domNode, text, style=nil) {
        var m = Node.new(domNode, style);
        m.parents = [me] ~ m.parents;
        m.text = text;
        return m;
    },

    wordSplit: func {
        var result = [];
        var words = split(' ', me.text);
        foreach (var word; words) {
            if (word != '') {
                append(result, InlineText.new(me.domNode, word, me.style));
            }
        }
        return result;
    },

    calcSizeMetrics: func (renderContext, parentMetrics) {
        var fontSize = me.metrics['font-size'];
        var fontFamily = denull(me.metrics['font-family'], 'sans');
        var fontWeight = denull(me.metrics['font-weight'], 'regular');

        # Chop off borders, padding, and margin if this text node is the result
        # of splitting an element
        if (!me.metrics['first-of-element']) {
            me.metrics['border-left-width'] = 0;
            me.metrics['border-left-color'] = 'none';
            me.metrics['padding-left'] = 0;
            me.metrics['margin-left'] = 0;
        }
        if (!me.metrics['last-of-element']) {
            me.metrics['border-right-width'] = 0;
            me.metrics['border-right-color'] = 'none';
            me.metrics['padding-right'] = 0;
            me.metrics['margin-right'] = 0;
        }

        # Measure the text itself
        var textElem =
                renderContext.group.createChild('text')
                            .setFont(renderContext.fontMapper(fontFamily, fontWeight))
                            .setFontSize(fontSize)
                            .setText(me.text);
        var bounds = textElem.getBoundingBox();
        var above = 0;
        var below = 0;

        var width = bounds[2];

        # Measure space before/after
        textElem.setText('|');
        bounds = textElem.getBoundingBox();
        var pipeWidth = bounds[2];
        textElem.setText('| |');
        bounds = textElem.getBoundingBox();
        var minSpacing = bounds[2] - 2 * pipeWidth;

        if (me.metrics['vertical-align'] == 'top') {
            above = 0;
            below = fontSize;
        }
        elsif (me.metrics['vertical-align'] == 'bottom') {
            above = fontSize;
            below = 0;
        }
        elsif (me.metrics['vertical-align'] == 'middle') {
            above = fontSize * 0.5;
            below = fontSize * 0.5;
        }
        else { # 'baseline'
            # Wild guess, until we can come up with a better way of detecting
            # font metrics.
            above = fontSize * 0.7;
            below = fontSize * 0.3;
        }

        me.metrics['inline-width'] = width;
        me.metrics['min-spacing'] = minSpacing;
        me.metrics['above-baseline'] = above;
        me.metrics['below-baseline'] = below;
    },

    layoutInline: func(x, y, prevX) {
        # We need this to determine how far to the left the underline needs to
        # extend
        me.metrics['previous-x'] = prevX;

        me.metrics['content-box'] =
            Box.new(
                x,
                y - me.metrics['above-baseline'],
                me.metrics['inline-width'],
                me.metrics['above-baseline'] + me.metrics['below-baseline']);
        me.boxesFromContentBox();
    },

    layoutBlock: func (parentBox) {
        die("InlineText elements cannot be used in a block context");
    },

    renderContent: func (renderContext) {
        var fontSize = me.metrics['font-size'];
        var fontFamily = denull(me.metrics['font-family'], 'sans');
        var fontWeight = denull(me.metrics['font-weight'], 'regular');

        # horizontal alignment is taken care of in layout step
        var alignment = 'left-baseline';
        if (me.metrics['vertical-align'] == 'top') {
            alignment = 'left-top';
        }
        elsif (me.metrics['vertical-align'] == 'bottom') {
            alignment = 'left-bottom';
        }
        elsif (me.metrics['vertical-align'] == 'middle') {
            alignment = 'left-center';
        }

        var textElem =
                renderContext.group.createChild('text')
                            .setFont(renderContext.fontMapper(fontFamily, fontWeight))
                            .setFontSize(fontSize)
                            .setAlignment(alignment)
                            .setTranslation(
                                me.metrics['content-box'].left(),
                                me.metrics['content-box'].top() + me.metrics['above-baseline'])
                            .setColor(me.metrics['color'])
                            .setText(me.text);
        
        if (me.metrics['text-decoration'] == 'underline') {
            renderContext.group.createChild('path')
                .moveTo(me.metrics['previous-x'], me.metrics['content-box'].top() + me.metrics['above-baseline'] + 1)
                .line(me.metrics['inline-width'] - me.metrics['previous-x'] + me.metrics['content-box'].left(), 0)
                .setColor(me.metrics['color']);
        }
    },


    isBlock: func 0,
};

var Block = {
    new: func (domNode, children=nil, style=nil) {
        var m = Node.new(domNode, style);
        m.parents = [me] ~ m.parents;
        m.children = [];

        var inlineChildren = [];
        foreach (var child; denull(children, [])) {
            if (child.isBlock()) {
                if (size(inlineChildren)) {
                    append(m.children, Block.new(domNode, inlineChildren));
                    inlineChildren = [];
                }
                append(m.children, child);
            }
            else {
                append(inlineChildren, child);
            }
        }
        if (size(inlineChildren)) {
            if (size(m.children)) {
                # We have at least one block child, so we need to wrap
                # remaining inline children in a new block.
                append(m.children, Block.new(domNode, inlineChildren));
            }
            else {
                # All children collected so far are inlines, so we can
                # just use the list as-is.
                m.children = inlineChildren;
            }
        }
        return m;
    },

    wordSplit: func {
        var childrenNew = [];
        foreach (var child; me.children) {
            childrenNew = childrenNew ~ child.wordSplit();
        }
        return [Block.new(me.domNode, childrenNew, me.style)];
    },

    calcSizeMetrics: func (renderContext, parentMetrics) {
        # NB: We have to cater for the block being laid out in as inline-block.

        var boxSizing = denull(me.metrics['box-sizing'], 'content-box');
        var paddingX = me.metrics['padding-left'] + me.metrics['padding-right'];
        var borderX = me.metrics['border-left-width'] + me.metrics['border-right-width'];

        # content box width
        var desiredContentWidth = 0;
        # width as per box-sizing
        var desiredWidth = 0;
        var boxSizingCorrection = 0;

        if (boxSizing == 'content-box') {
            boxSizingCorrection = 0;
        }
        elsif (boxSizing == 'padding-box') {
            boxSizingCorrection = paddingX;
        }
        elsif (boxSizing == 'border-box') {
            boxSizingCorrection = paddingX + borderX;
        }

        if (me.metrics['width'] == 'auto' or me.metrics['width'] == nil) {
            # Calculate desired width from children.
            var previousMargin = 0;
            desiredWidth = boxSizingCorrection;
            foreach (var child; me.children) {
                var collapsedMargin = math.max(
                        math.max(previousMargin, child.metrics['margin-left']),
                        child.metrics['min-spacing']);
                desiredWidth += collapsedMargin - previousMargin;
                desiredWidth += child.metrics['inline-width'];
                previousMargin = child.metrics['margin-right'];
                desiredWidth += previousMargin;
            }
        }
        else {
            desiredWidth = me.metrics['width'];
        }

        if (me.metrics['max-width'] != nil and me.metrics['max-width'] != 'auto') {
            desiredWidth = math.min(me.metrics['max-width'], desiredWidth);
            me.metrics['max-content-width'] = me.metrics['max-width'] - boxSizingCorrection;
        }
        if (me.metrics['min-width'] != nil and me.metrics['min-width'] != 'auto') {
            desiredWidth = math.max(me.metrics['min-width'], desiredWidth);
            me.metrics['min-content-width'] = me.metrics['min-width'] - boxSizingCorrection;
        }
        desiredContentWidth = desiredWidth - boxSizingCorrection;

        # Inline width for block-level elements is only used for inline-block
        # layout, where it must include padding and border.
        me.metrics['inline-width'] =
            desiredContentWidth + paddingX + borderX;

        # Spacing does not apply to inline-block elements.
        me.metrics['min-spacing'] = 0;

        # We can't fully determine baseline yet; this will have to wait until
        # the layout phase.
        me.metrics['above-baseline'] = 0;
        me.metrics['below-baseline'] = 0;
    },

    calcChildMetrics: func (renderContext) {
        foreach (var child; me.children) {
            child.calcMetrics(renderContext, me.metrics);
        }
    },

    layoutInline: func (x, y, prevX) {
        # Preliminary calculation of border box; we will amend the height
        # while laying out child elements.
        me.metrics['content-box'] = Box.new(
            x + me.metrics['border-left-width'] + me.metrics['padding-left'],
            y + me.metrics['border-top-width'] + me.metrics['padding-top'],
            me.metrics['inline-width']
                - me.metrics['border-left-width']
                - me.metrics['border-right-width']
                - me.metrics['padding-left']
                - me.metrics['padding-right'],
            0);

        if (size(me.children) == 0) {
        }
        elsif (me.children[0].isBlock()) {
            me.layoutChildBlocks();
        }
        else {
            me.layoutChildInlines();
        }

        me.boxesFromContentBox();
    },

    layoutBlock: func (parentBox) {
        # Preliminary calculation of border box; we will amend the height
        # while laying out child elements.

        # At this point, the margin box 

        var leftMarginIsAuto = me.style['margin-left'] == 'auto';
        var rightMarginIsAuto = me.style['margin-right'] == 'auto';

        # The remaining space that we need to distribute over auto margins.
        # inline-width = desired border-box width
        var remainingSpace = math.max(0, parentBox.width() - me.metrics['inline-width']);

        # TODO: handle cases where remaining space is negative.
        # For now: clip to 0.

        if (leftMarginIsAuto and rightMarginIsAuto) {
            # Both margins are 'auto': distribute space equally.
            me.metrics['margin-left'] = remainingSpace * 0.5;
            me.metrics['margin-right'] = remainingSpace * 0.5;
        }
        elsif (leftMarginIsAuto) {
            remainingSpace -= me.metrics['margin-right'];
            me.metrics['margin-left'] = remainingSpace;
        }
        elsif (rightMarginIsAuto) {
            remainingSpace -= me.metrics['margin-left'];
            me.metrics['margin-right'] = remainingSpace;
        }

        me.metrics['margin-box'] = parentBox.clone();
        me.boxesFromMarginBox();
        me.metrics['content-box'].setHeight(0);

        # TODO: re-check min-width and max-width.

        if (size(me.children) == 0) {
        }
        elsif (me.children[0].isBlock()) {
            me.layoutChildBlocks();
        }
        else {
            me.layoutChildInlines();
        }
        me.boxesFromContentBox();
    },

    layoutChildBlocks: func () {
        # TODO: collapse margins
        var firstChild = 1;
        var runningBox = me.metrics['content-box'].clone();
        var prevMargin = 0;
        var extendHeight = func (dy) {
            runningBox.move(0, dy);
            me.metrics['content-box'].extend(0, 0, 0, dy);
        };
        foreach (var child; me.children) {
            # Collapse adjacent siblings' margins
            extendHeight(-(math.min(prevMargin, child.metrics['margin-top'])));

            child.layoutBlock(runningBox);

            # Collapse child's own margins if it has no height
            if (child.metrics['border-box'].height() == 0) {
                extendHeight(-(math.min(child.metrics['margin-bottom'], child.metrics['margin-top'])));
            }

            extendHeight(child.metrics['margin-top']);
            extendHeight(child.metrics['border-box'].height());
            extendHeight(child.metrics['margin-bottom']);
            prevMargin = child.metrics['margin-bottom'];

            if (firstChild) {
                me.metrics['above-baseline'] = child.metrics['above-baseline'];
            }
            firstChild = 0;
            # We only care for the last one, but it's easier to just overwrite
            # each time than to figure out whether the current child is the
            # last.
            me.metrics['below-baseline'] = child.metrics['below-baseline'];
        }
    },

    layoutChildInlines: func() {
        var currentLine = [];
        var currentLineWidth = 0;

        # For now, vertical-align on block elements is not supported.
        var spacing = 0;
        var maxFontSize = me.metrics['font-size'];
        var baselineOffset = 0;
        var below = 0;

        var y = me.metrics['content-box'].top();

        var firstLine = 1;

        # We need to track this so that the child knows whether it belongs to
        # the same DOM node as the previous one; we use this to draw underlines
        # across individual inlines.
        var previousDOMNodeID = nil;

        var pushLine = func (lastLine) {
            var remainingWidth = me.metrics['content-box'].width() - currentLineWidth;
            var x = me.metrics['content-box'].left();
            var numSpaces = math.max(0, size(currentLine) - 1);
            var lineFeed = me.metrics['line-height'] * maxFontSize;
            if (baselineOffset + below < lineFeed) {
                baselineOffset = lineFeed - below;
            }
            if (firstLine) {
                me.metrics['above-baseline'] = baselineOffset;
            }
            if (lastLine) {
                me.metrics['below-baseline'] = below;
            }

            if (me.metrics['text-align'] == 'right') {
                x += remainingWidth;
            }
            elsif (me.metrics['text-align'] == 'center') {
                x += remainingWidth * 0.5;
            }
            else {
                # 'fill' or 'left': start on the left.
            }
            var baseline = y + baselineOffset;
            var firstInLine = 1;
            var previousX = 0;
            foreach (var child; currentLine) {
                var currentDOMNodeID = id(child.domNode);
                child.layoutInline(x, baseline, (currentDOMNodeID == previousDOMNodeID) ? previousX : x);
                x += child.metrics['inline-width'];
                previousX = x;
                if (me.metrics['text-align'] == 'fill' and numSpaces and !lastLine) {
                    x += remainingWidth / numSpaces;
                }
                x += child.metrics['min-spacing'];
                firstInLine = 0;
                previousDOMNodeID = currentDOMNodeID;
            }
            spacing = 0;
            baselineOffset = 0;
            below = 0;
            y += me.metrics['line-height'] * maxFontSize;
            maxFontSize = me.metrics['font-size'];
            currentLine = [];
            currentLineWidth = 0;
            firstLine = 0;
        }

        foreach (var child; me.children) {
            # Check if we would exceed the maximum width if we appended the
            # next inline; however, if the current line is still empty, then
            # this would lead to an infinite loop, so we accept defeat and
            # carry on, accepting the resulting overflow.
            if (size(currentLine) and currentLineWidth + child.metrics['inline-width'] + spacing > me.metrics['content-box'].width()) {
                # This will reset currentLine, currentLineWidth, spacing,
                # maxFontSize, and baselineOffset.
                pushLine(0);
            }

            currentLineWidth += child.metrics['inline-width'] + spacing;
            # Remember spacing for next inline on the same line, since we
            # apply the spacing based on the inline left of the gap.
            spacing = child.metrics['min-spacing'];

            # We need to track font size to calculate effective line
            # height, based on the largest font size found on this line.
            maxFontSize = math.max(maxFontSize, child.metrics['font-size']);

            # Baseline offset determines where we put the baseline for this
            # line. We find the inline with the largest ascenders, and
            # shift everything down from there so that the topmost
            # ascenders are at the Y position.
            baselineOffset = math.max(baselineOffset, child.metrics['above-baseline']);

            # Track descenders; this is needed to calculate the height of the
            # block element.
            below = math.max(below, child.metrics['below-baseline']);

            append(currentLine, child);
        }
        pushLine(1);
        me.metrics['content-box'].setBottom(y);
        me.boxesFromContentBox();
    },

    renderContent: func (renderContext) {
        foreach (var child; me.children) {
            child.render(renderContext);
        }
    },

    isBlock: func 1,
};

var domNodeToRenderNode = func (node, path=nil) {
    if (path == nil)
        path = [];

    if (isa(node, DOM.Element)) {
        var children = [];
        foreach (var domChild; node.getChildren()) {
            append(children, domNodeToRenderNode(domChild, path ~ [node]));
        }
        if (node.effectiveStyle['display'] == 'inline') {
            return InlineContainer.new(node, children, node.effectiveStyle);
        }
        else {
            return Block.new(node, children, node.effectiveStyle);
        }
    }
    elsif (isa(node, DOM.Text)) {
        return InlineText.new(node, node.getTextContent(), node.effectiveStyle);
    }
    elsif (typeof(node) == 'scalar') {
        return InlineText.new(DOM.Text.new(node), node, node.effectiveStyle);
    }
};

var showDOM = func (dom, renderContext) {
    renderContext.group.removeAllChildren();
    renderContext.group.hide();
    dom.calcEffectiveStyle(rootStyle);
    var doc = domNodeToRenderNode(dom);
    doc = doc.wordSplit()[0];
    doc.calcMetrics(renderContext, {});
    doc.layoutBlock(renderContext.viewport);
    renderContext.group.removeAllChildren();
    doc.render(renderContext);
    renderContext.group.show();
    return {
        docPaddingBox: doc.metrics['padding-box'],
    };
};


var toInlines = func (items) {
    var result = [];
    foreach (var item; items) {
        var inline = toInline(item);
        append(result, toInline(item));
    }
    return result;
};

var toInline = func (item) {
    if (typeof(item) == 'scalar') {
        return InlineText.new(item);
    }
    elsif (typeof(item) == 'vector') {
        return InlineContainer.new(toInlines(item));
    }
    else {
        # Assume that it's an inline node, and hope for the best.
        return item;
    }
};

