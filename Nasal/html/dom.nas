include('util.nas');
include('css.nas');

var DOM = (func {
    var module = {};

    var Node = {
        new: func () {
            return {
                parents: [me],
                parentNode: nil,
                siblingIndex: 0,
                cssStyle: {},
            };
        },

        applyCSSStyle: func (style) {
            me.cssStyle = mergeDicts(me.cssStyle, style);
        },

        cloneRaw: func {
            return Node.new();
        },

        clone: func (parentNode, siblingIndex) {
            var cloned = me.cloneRaw();
            cloned.cssStyle = copyDict(me.cssStyle);
            cloned.parentNode = parentNode;
            cloned.siblingIndex = siblingIndex;
            return cloned;
        },

        getChildren: func [],
        getChild: func (i) { return nil; },
        getAttribute: func (n) { return nil; },
        getNodeName: func nil,
        getNodeType: func nil,
        getTextContent: func '',
        getStyle: func me.cssStyle,
        getParentNode: func me.parentNode,
        getAncestry: func {
            var result = [];
            var n = me.getParentNode();
            while (n != nil) {
                append(result, n);
                n = n.getParentNode();
            }
            return result;
        },
        getNextSibling: func {
            if (me.parentNode == nil) return nil;
            return me.parentNode.getChild(me.siblingIndex + 1);
        },
        getPreviousSibling: func {
            if (me.parentNode == nil) return nil;
            return me.parentNode.getChild(me.siblingIndex - 1);
        },
        getSiblings: func {
            if (me.parentNode == nil) return [];
            var siblings = [];
            var parentChildren = me.parentNode.getChildren();
            for (var i = 0; i < size(parentChildren); i += 1) {
                if (i != me.siblingIndex) {
                    append(siblings, parentChildren[i]);
                }
            }
            return siblings;
        },
    };

    var Text = {
        new: func (text) {
            var m = Node.new();
            m.parents = [me] ~ m.parents;
            m.text = text;
            return m;
        },

        cloneRaw: func {
            return Text.new(me.text);
        },

        getNodeName: func '$Text',
        getNodeType: func 'text',
        getTextContent: func me.text,
    };

    var Element = {
        new: func (elemName, attribs, children) {
            var m = Node.new();
            m.parents = [me] ~ m.parents;
            m.elemName = elemName;
            m.attribs = attribs;
            m.children = [];
            var i = 0;
            foreach (var child; children) {
                var importedChild = child.clone(m, i);
                append(m.children, importedChild);
                i += 1;
            }
            return m;
        },

        cloneRaw: func {
            return Element.new(me.elemName, me.attribs, me.children);
        },

        getChildren: func me.children,
        getChild: func (i) {
            if (i >= size(me.children) or i < 0)
                return nil;
            else
                return me.children[i];
        },
        getAttribute: func (n) { return me.attribs[n]; },
        getNodeName: func me.elemName,
        getNodeType: func 'element',
        getTextContent: func {
            var result = '';
            foreach (var child; me.children) {
                result = result ~ child.getTextContent();
            }
            return result;
        },

        # TODO: parse attribs for style properties
        getStyle: func {
            var styleAttrib = me.attribs['style'] or '';
            var elemStyle = CSS.parseStyleAttrib(styleAttrib);
            var baseStyle = baseStyles[me.elemName] or {'display': 'inline'};
            var style = mergeDicts(baseStyle, me.cssStyle);
            style = mergeDicts(style, elemStyle);
            return style;
        },
    };

    var baseStyles = {
        'p': { 'margin-bottom': '1em' },
        'h1': { 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '150%', 'font-weight': 'bold' },
        'h2': { 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '130%', 'font-weight': 'bold' },
        'h3': { 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '120%', 'font-weight': 'bold' },
        'h4': { 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '110%', 'font-weight': 'bold' },
        'h5': { 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '105%', 'font-weight': 'bold' },
        'h6': { 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '100%', 'font-weight': 'bold' },

        'a': { 'color': 'blue', 'text-decoration': 'underline' },
        'b': { 'font-weight': 'bold' },
        'strong': { 'font-weight': 'bold' },
        'i': { 'font-style': 'italic' },
        'em': { 'font-style': 'italic' },
    };

    var blockElements = [
        'html',

        # Metadata
        'base',
        'head',
        'link',
        'meta',
        'style',
        'title',

        # Content root
        'body',

        # Sectioning
        'address',
        'article',
        'aside',
        'footer',
        'header',
        'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'h1', 'h6',
        'hgroup',
        'main',
        'nav',
        'section',

        # Text content
        'blockquote', 'cite', 'dd', 'div', 'dl', 'dt', 'figcaption', 'figure',
        'hr', 'li', 'menu', 'ol', 'p', 'pre', 'ul',

        # Table Content
        'caption', 'col', 'colgroup', 'table', 'tbody', 'td', 'tfoot', 'th',
        'thead', 'tr',

        # Images and Multimedia
        'area', 'audio', 'img', 'map', 'track', 'video',

        # Embedded content
        'embed', 'iframe', 'object', 'picture', 'portal', 'source',

        # SVG and MathML
        'svg', 'math',

        # Scripting
        'canvas', 'noscript', 'script',

        # Forms
        'datalist',
        'fieldset',
        'form',
        'optgroup',
        'textarea',
    ];

    var inlineElements = [
        # Inline text
        'a', 'abbr', 'b', 'bdi', 'bdo', 'br', 'cite', 'code', 'data', 'dfn',
        'em', 'i', 'kbd', 'mark', 'q', 'rp', 'rt', 'ruby', 's', 'samp',
        'small', 'span', 'strong', 'sub', 'sup', 'time', 'u', 'var', 'wbr',

        # Edits
        'del', 'ins',

        # Forms
        'button',
        'input',
        'label',
        'legend',
        'meter',
        'option',
        'output',
        'progress',
        'select',
    ];

    foreach (var e; inlineElements) {
        baseStyles[e] = mergeDicts(baseStyles[e], { 'display': 'inline' });
    };
    foreach (var e; blockElements) {
        baseStyles[e] = mergeDicts(baseStyles[e], { 'display': 'block' });
    };

    module.Node = Node;
    module.Element = Element;
    module.Text = Text;

    return module;
})();
