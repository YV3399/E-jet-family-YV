include('util.nas');
include('dom.nas');

var makeDefaultRenderContext = func (group, fontMapper, left, top, width, height) {
    return {
        group: group,
        fontMapper: fontMapper,
        dpi: 96,
        debugLayout: 1,
        viewport: {
            left: left,
            top: top,
            width: width,
            height: height,
            right: left + width,
            bottom: top + height,
        },
    };
};

var makeDefaultMetrics = func (left, top, width, height) {
    return {
        left: left,
        top: top,
        width: width,
        height: height,
        'line-height': 1.25,
        'font-size': 12,
        'font-size-base': 12,
        'padding-left': 0,
        'padding-right': 0,
        'padding-top': 0,
        'padding-bottom': 0,
    };
};

var defaultStyle = {
    'font-size': '10pt',
    'font-size-base': '10pt',
    'border-width': 0,

    'padding-left': 0,
    'padding-right': 0,
    'padding-top': 0,
    'padding-bottom': 0,

    'margin-left': 0,
    'margin-right': 0,
    'margin-top': 0,
    'margin-bottom': 0,

    'font-family': 'sans',
    'font-weight': 'normal',
    'text-style': 'normal',
    'text-decoration': 'none',

    'vertical-align': 'baseline',
    'text-align': 'left',

    'color': [0, 0, 0],
    'border-color': 'none',
    'border-width': 0,
    'background-color': 'none',
};

var dimensionalStyleKeys = [
    'font-size',
    'font-size-base',
    'border-width',

    'padding-left',
    'padding-right',
    'padding-top',
    'padding-bottom',

    'margin-left',
    'margin-right',
    'margin-top',
    'margin-bottom',
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
        return value * renderContext.viewport.width / 100;
    }
    elsif (unit == 'vh') {
        return value * renderContext.viewport.height / 100;
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
    var default = defaultColors[key] or [0,0,0,1];

    if (typeof(color) == 'scalar') {
        color = namedColors[color] or default;
    }
    if (color == nil) {
        color = default;
    }

    if (typeof(color) == 'vector') {
        color = subvec(color, 0, 4);
        return
            [ size(color) > 0 ? (color[0] / 255) : 0
            , size(color) > 1 ? (color[1] / 255) : 0
            , size(color) > 2 ? (color[2] / 255) : 0
            , size(color) > 3 ? color[3] : default[3]
            ]
    }
    else {
        return [0,0,0,0];
    }
};

var splitDimensional = func (str) {
    if (str == nil)
        return [0, ''];
    var result = [];
    var i = 0;
    while (i < size(str) and (string.isdigit(str[i]) or str[i] == '-' or str[i] == '.')) {
        i += 1;
    }
    var value = substr(str, 0, i);
    var unit = substr(str, i);
    return [value, unit];
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

    calcMetrics: func (renderContext, parentMetrics) {
        me.calcStyleMetrics(renderContext, parentMetrics);
        me.calcSizeMetrics(renderContext, parentMetrics);
        me.calcChildMetrics(renderContext);
    },

    calcStyleMetrics: func (renderContext, parentMetrics) {
        foreach (var k; dimensionalStyleKeys) {
            if (me.style[k] == nil or me.style[k] == 'inherit') {
                me.metrics[k] = parentMetrics[k];
            }
            else {
                var (value, unit) = splitDimensional(me.style[k] or nil);
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

    render: func (renderContext) {
        me.renderBorderAndBackground(renderContext);
        if (renderContext['debugLayout']) {
            me.renderDebugLayout(renderContext);
        }
        me.renderContent(renderContext);
    },

    renderDebugLayout: func (renderContext) {
        if (me.metrics['display'] == 'block') {
            renderContext.group.createChild('path')
                .rect(me.metrics['border-box-left'] - me.metrics['margin-left'],
                      me.metrics['border-box-top'] - me.metrics['margin-top'],
                      me.metrics['border-box-width'] + me.metrics['margin-left'] + me.metrics['margin-right'],
                      me.metrics['border-box-height'] + me.metrics['margin-top'] + me.metrics['margin-bottom'])
                .setColor([1, 1, 0, 1]);
        }
        renderContext.group.createChild('path')
            .rect(me.metrics['border-box-left'],
                  me.metrics['border-box-top'],
                  me.metrics['border-box-width'],
                  me.metrics['border-box-height'])
            .setColor([0.5, 0, 1, 1]);
        renderContext.group.createChild('path')
            .rect(me.metrics['left'],
                  me.metrics['top'],
                  me.metrics['width'],
                  me.metrics['height'])
            .setColor([0.5, 1, 1, 1]);
    },

    renderBorderAndBackground: func (renderContext) {
        if (me.metrics['background-color'] != 'none') {
            var backgroundBox =
                    renderContext.group.createChild('path')
                        .rect(me.metrics.left,
                              me.metrics.top,
                              me.metrics.right - me.metrics.left,
                              me.metrics.bottom - me.metrics.top)
                        .setColorFill(me.metrics['background-color']);
            if (me.metrics['border-width'] != 'none' and me.metrics['border-width'] > 0) {
                var borderColor = me.metrics['border-color'];
                if (borderColor == 'auto')
                    borderColor = me.metrics['color'];
                backgroundBox.setColor(borderColor).setStrokeLineWidth(me.metrics['border-width']);
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
        return result;
    },

    calcChildMetrics: func (renderContext) {
        foreach (var child; me.children) {
            child.calcMetrics(renderContext, me.metrics);
        }
    },

    layout: func (x, y) {
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
        var fontFamily = me.metrics['font-family'] or 'sans';
        var fontWeight = me.metrics['font-weight'] or 'regular';

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
        me.metrics.width = width;
        me.metrics.height = fontSize;

        me.metrics.minSpacing = minSpacing;
        me.metrics.aboveBaseline = above;
        me.metrics.belowBaseline = below;

        me.metrics['padding-box-width'] = width + me.metrics['padding-left'] + me.metrics['padding-right'];
        me.metrics['padding-box-height'] = me.metrics.height + me.metrics['padding-top'] + me.metrics['padding-bottom'];
        me.metrics['border-box-width'] = me.metrics['padding-box-width'] +  me.metrics['border-width'];
        me.metrics['border-box-height'] = me.metrics['padding-box-height'] +  me.metrics['border-width'];
    },

    layout: func(x, y, previousX) {
        me.metrics.x = x;
        me.metrics.y = y;
        me.metrics['previous-x'] = previousX;

        me.metrics.left = x;
        me.metrics.right = x + me.metrics.width;
        me.metrics.top = y - me.metrics.aboveBaseline;
        me.metrics.bottom = y + me.metrics.belowBaseline;

        me.metrics['padding-box-left'] = me.metrics.left - me.metrics['padding-left'];
        me.metrics['padding-box-right'] = me.metrics.right + me.metrics['padding-right'];
        me.metrics['padding-box-top'] = me.metrics.top - me.metrics['padding-top'];
        me.metrics['padding-box-bottom'] = me.metrics.bottom + me.metrics['padding-bottom'];

        me.metrics['border-box-left'] = me.metrics['padding-box-left'] - me.metrics['border-width'] * 0.5;
        me.metrics['border-box-right'] = me.metrics['padding-box-right'] - me.metrics['border-width'] * 0.5;
        me.metrics['border-box-top'] = me.metrics['padding-box-top'] - me.metrics['border-width'] * 0.5;
        me.metrics['border-box-bottom'] = me.metrics['padding-box-bottom'] - me.metrics['border-width'] * 0.5;
    },

    renderContent: func (renderContext) {
        var fontSize = me.metrics['font-size'];
        var fontFamily = me.metrics['font-family'] or 'sans';
        var fontWeight = me.metrics['font-weight'] or 'regular';

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
                            .setTranslation(me.metrics.x, me.metrics.y)
                            .setColor(me.metrics['color'])
                            .setText(me.text);
        
        if (me.metrics['text-decoration'] == 'underline') {
            renderContext.group.createChild('path')
                .moveTo(me.metrics['previous-x'], me.metrics.top + me.metrics.aboveBaseline + 1)
                .line(me.metrics.width - me.metrics['previous-x'] + me.metrics.x, 0)
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
        foreach (var child; children or []) {
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
        # Pre-fill with defaults - `layout()` will override some of these.
        me.metrics.width = parentMetrics.width - me.metrics['padding-left'] - me.metrics['padding-right'] - me.metrics['border-width'];
        me.metrics.height = 0;
        me.metrics.minSpacing = 0;
        me.metrics.aboveBaseline = 0;
        me.metrics.belowBaseline = 0;

        me.metrics['padding-box-width'] = me.metrics.width + me.metrics['padding-left'] + me.metrics['padding-right'];
        me.metrics['padding-box-height'] = me.metrics['padding-top'] + me.metrics['padding-bottom'];
        me.metrics['border-box-width'] = me.metrics['padding-box-width'] +  me.metrics['border-width'];
        me.metrics['border-box-height'] = me.metrics['padding-box-height'] +  me.metrics['border-width'];
    },

    calcChildMetrics: func (renderContext) {
        foreach (var child; me.children) {
            child.calcMetrics(renderContext, me.metrics);
        }
    },

    layout: func (x, y) {
        # Set defaults from parent rect
        me.metrics.left = x + me.metrics['padding-left'] + me.metrics['border-width'] * 0.5;
        me.metrics.right = me.metrics.left + me.metrics.width;
        me.metrics.top = y + me.metrics['padding-top'] + me.metrics['border-width'] + 0.5;
        me.metrics.bottom = me.metrics.top + me.metrics['padding-bottom'] + me.metrics['border-width'];

        if (size(me.children) == 0) {
        }
        elsif (me.children[0].isBlock()) {
            me.layoutBlocks();
        }
        else {
            me.layoutInlines();
        }

        me.metrics['padding-box-left'] = me.metrics.left - me.metrics['padding-left'];
        me.metrics['padding-box-right'] = me.metrics.right + me.metrics['padding-right'];
        me.metrics['padding-box-top'] = me.metrics.top - me.metrics['padding-top'];
        me.metrics['padding-box-bottom'] = me.metrics.bottom + me.metrics['padding-bottom'];
        me.metrics['padding-box-width'] = me.metrics['padding-box-right'] - me.metrics['padding-box-left'];
        me.metrics['padding-box-height'] = me.metrics['padding-box-bottom'] - me.metrics['padding-box-top'];

        me.metrics['border-box-left'] = me.metrics['padding-box-left'] - me.metrics['border-width'] * 0.5;
        me.metrics['border-box-right'] = me.metrics['padding-box-right'] - me.metrics['border-width'] * 0.5;
        me.metrics['border-box-top'] = me.metrics['padding-box-top'] - me.metrics['border-width'] * 0.5;
        me.metrics['border-box-bottom'] = me.metrics['padding-box-bottom'] - me.metrics['border-width'] * 0.5;
        me.metrics['border-box-width'] = me.metrics['border-box-right'] - me.metrics['border-box-left'];
        me.metrics['border-box-height'] = me.metrics['border-box-bottom'] - me.metrics['border-box-top'];
    },

    layoutBlocks: func () {
        var firstChild = 1;
        var margin = 0;
        var x = me.metrics.left;
        var y = me.metrics.top;
        foreach (var child; me.children) {
            if (!firstChild) {
                margin = math.max(child.metrics['margin-top'], margin);
                y += margin;
                me.metrics.height += margin;
                me.metrics.bottom += margin;
            }
            margin = child.metrics['margin-bottom'];

            child.layout(x, y);

            y += child.metrics['border-box-height'];
            me.metrics.height += child.metrics['border-box-height'];
            me.metrics.bottom += child.metrics['border-box-height'];
            if (firstChild) {
                me.metrics.aboveBaseline = child.metrics.aboveBaseline;
            }
            firstChild = 0;
            # We only care for the last one, but it's easier to just overwrite
            # each time than to figure out whether the current child is the
            # last.
            me.metrics.belowBaseline = child.metrics.belowBaseline;
        }
    },

    layoutInlines: func() {
        var currentLine = [];
        var currentLineWidth = 0;

        # For now, vertical-align on block elements is not supported.
        var spacing = 0;
        var maxFontSize = me.metrics['font-size'];
        var baselineOffset = 0;
        var below = 0;

        var y = me.metrics.top;

        var firstLine = 1;

        # We need to track this so that the child knows whether it belongs to
        # the same DOM node as the previous one; we use this to draw underlines
        # across individual inlines.
        var previousDOMNodeID = nil;

        var pushLine = func (lastLine) {
            var remainingWidth = me.metrics.width - currentLineWidth;
            var x = me.metrics.left;
            var numSpaces = math.max(0, size(currentLine) - 1);
            if (firstLine) {
                me.metrics.aboveBaseline = baselineOffset;
            }
            if (lastLine) {
                me.metrics.belowBaseline = below;
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
                child.layout(x, baseline, (currentDOMNodeID == previousDOMNodeID) ? previousX : x);
                x += child.metrics.width;
                previousX = x;
                if (me.metrics['text-align'] == 'fill' and numSpaces and !lastLine) {
                    x += remainingWidth / numSpaces;
                }
                x += child.metrics.minSpacing;
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
            if (size(currentLine) and currentLineWidth + child.metrics.width + spacing > me.metrics.width) {
                # This will reset currentLine, currentLineWidth, spacing,
                # maxFontSize, and baselineOffset.
                pushLine(0);
            }

            currentLineWidth += child.metrics.width + spacing;
            # Remember spacing for next inline on the same line, since we
            # apply the spacing based on the inline left of the gap.
            spacing = child.metrics.minSpacing;

            # We need to track font size to calculate effective line
            # height, based on the largest font size found on this line.
            maxFontSize = math.max(maxFontSize, child.metrics['font-size']);

            # Baseline offset determines where we put the baseline for this
            # line. We find the inline with the largest ascenders, and
            # shift everything down from there so that the topmost
            # ascenders are at the Y position.
            baselineOffset = math.max(baselineOffset, child.metrics.aboveBaseline);

            # Track descenders; this is needed to calculate the height of the
            # block element.
            below = math.max(below, child.metrics.belowBaseline);

            append(currentLine, child);
        }
        pushLine(1);
        me.metrics.bottom = y;
        me.metrics.height = me.metrics.bottom - me.metrics.top;
    },

    renderContent: func (renderContext) {
        foreach (var child; me.children) {
            child.render(renderContext);
        }
    },

    isBlock: func 1,
};

var domNodeToRenderNode = func (node, path=nil, style=nil) {
    if (path == nil)
        path = [];
    if (style == nil)
        style = defaultStyle;
    if (isa(node, DOM.Element)) {
        var children = [];
        var style = mergeDicts(defaultStyle, node.getStyle());
        foreach (var domChild; node.getChildren()) {
            append(children, domNodeToRenderNode(domChild, path ~ [node], style));
        }
        if (style['display'] == 'inline') {
            return InlineContainer.new(node, children, style);
        }
        else {
            return Block.new(node, children, style);
        }
    }
    elsif (isa(node, DOM.Text)) {
        return InlineText.new(node, node.getTextContent(), style);
    }
    elsif (typeof(node) == 'scalar') {
        return InlineText.new(DOM.Text.new(node), node, style);
    }
};

var showDOM = func (dom, group, fontMapper, x, y, w, h) {
    var renderContext = makeDefaultRenderContext(group, fontMapper, x, y, w, h);
    group.removeAllChildren();
    group.hide();
    var doc = domNodeToRenderNode(dom);
    doc = doc.wordSplit()[0];
    doc.calcMetrics(renderContext, makeDefaultMetrics(x, y, w, h));
    doc.layout(x, y);
    group.removeAllChildren();
    doc.render(renderContext);
    group.show();
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

