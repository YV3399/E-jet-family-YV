## Hyperscript-style helpers

include('util.nas');
include('dom.nas');

var H = (func {
    var makeElem = func (tag) {
        return func () {
            var args = arg;
            if (size(args) and typeof(args[0]) == 'hash' and !isa(args[0], DOM.Node)) {
                attribs = copyDict(args[0]);
                args = subvec(args, 1);
            }
            else {
                attribs = {};
            }
            var children = [];
            var addChildren = func (args) {
                foreach(var a; args) {
                    if (typeof(a) == 'vector') {
                        addChildren(a);
                    }
                    elsif (isa(a, DOM.Node)) {
                        append(children, a);
                    }
                    elsif (typeof(a) == 'scalar') {
                        append(children, DOM.Text.new(a));
                    }
                    else {
                        logprint(3, 'Invalid DOM child node');
                        debug.dump(a);
                    }
                }
            };
            addChildren(args);
            return DOM.Element.new(tag, attribs, children);
        };
    };

    var elementNames = [
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

        # Inline text
        'a', 'abbr', 'b', 'bdi', 'bdo', 'br', 'cite', 'code', 'data', 'dfn',
        'em', 'i', 'kbd', 'mark', 'q', 'rp', 'rt', 'ruby', 's', 'samp',
        'small', 'span', 'strong', 'sub', 'sup', 'time', 'u', 'var', 'wbr',

        # Images and Multimedia
        'area', 'audio', 'img', 'map', 'track', 'video',

        # Embedded content
        'embed', 'iframe', 'object', 'picture', 'portal', 'source',

        # SVG and MathML
        'svg', 'math',

        # Scripting
        'canvas', 'noscript', 'script',

        # Edits
        'del', 'ins',

        # Table Content
        'caption', 'col', 'colgroup', 'table', 'tbody', 'td', 'tfoot', 'th',
        'thead', 'tr',

        # Forms
        'button', 'datalist', 'fieldset', 'form', 'input', 'label', 'legend',
        'meter', 'optgroup', 'option', 'output', 'progress', 'select',
        'textarea',
    ];

    var module = {};

    foreach (var n; elementNames) {
        module[n] = makeElem(n);
    }

    return module;
})();
