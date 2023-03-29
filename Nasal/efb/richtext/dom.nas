include('util.nas');

var DOM = (func {
    var module = {};

    var Node = {
        new: func () {
            return {
                parents: [me],
            };
        },

        getChildren: func [],
        getNodeName: func nil,
        getNodeType: func nil,
        getTextContent: func '',
        getStyle: func nil,
    };

    var Text = {
        new: func (text) {
            var m = Node.new();
            m.parents = [me] ~ m.parents;
            m.text = text;
            return m;
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
            m.children = children;
            return m;
        },

        getChildren: func me.children,
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

    return module;
})();
