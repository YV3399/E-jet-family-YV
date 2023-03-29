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
            };
        },

        cloneRaw: func {
            return Node.new();
        },

        clone: func (parentNode, siblingIndex) {
            var cloned = me.cloneRaw();
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
        getStyle: func nil,
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
            var style = baseStyles[me.elemName] or { 'display': 'block' };
            var styleAttrib = me.attribs['style'] or {};
            style = mergeDicts(style, parseStyleAttrib(styleAttrib));

            return style;
        },
    };

    var baseStyles = {
        'div': { 'display': 'block' },
        'p': { 'display': 'block', 'margin-bottom': '1em' },
        'h1': { 'display': 'block', 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '150%', 'font-weight': 'bold' },
        'h2': { 'display': 'block', 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '130%', 'font-weight': 'bold' },
        'h3': { 'display': 'block', 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '120%', 'font-weight': 'bold' },
        'h4': { 'display': 'block', 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '110%', 'font-weight': 'bold' },
        'h5': { 'display': 'block', 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '105%', 'font-weight': 'bold' },
        'h6': { 'display': 'block', 'margin-top': '0.5em', 'margin-bottom': '0.5em', 'text-align': 'center', 'font-size': '100%', 'font-weight': 'bold' },

        'a': { 'display': 'inline', 'color': [0,0,1], 'text-decoration': 'underline' },
        'b': { 'display': 'inline', 'font-weight': 'bold' },
        'strong': { 'display': 'inline', 'font-weight': 'bold' },
        'i': { 'display': 'inline', 'font-style': 'italic' },
        'em': { 'display': 'inline', 'font-style': 'italic' },
    };

    var parseStyleAttrib = func (str) {
        var style = {};
        if (typeof(str) != 'scalar')
            return style;
        var rules = split(';', str);
        foreach (var rule; rules) {
            rule = string.trim(rule);
            var parts = split(':', rule);
            if (size(parts) < 2) {
                logprint(2, 'Invalid CSS style rule: ' ~ rule);
                continue;
            }
            var key = string.trim(parts[0]);
            var val = string.trim(string.join(':', subvec(parts, 1)));
            style[key] = val;
        }
        return style;
    };

    module.Node = Node;
    module.Element = Element;
    module.Text = Text;

    # var selector = CSS.Selector.new('foo bar');
    # selector.dump();
    # var dom = Element.new('foo', {}, [
    #             Element.new('bar', {}, []),
    #             Element.new('baz', {}, [])
    #           ]);
    # debug.dump(selector.test(dom.getChild(0)));

    return module;
})();
