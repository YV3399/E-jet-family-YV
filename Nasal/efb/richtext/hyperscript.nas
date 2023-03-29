## Hyperscript-style helpers

include('util.nas');
include('richtext/dom.nas');

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
            foreach(var a; args) {
                if (isa(a, DOM.Node)) {
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
            return DOM.Element.new(tag, attribs, children);
        };
    };

    var module = {};
    module.p = makeElem('p');
    module.div = makeElem('div');
    module.h1 = makeElem('h1');
    module.h2 = makeElem('h2');
    module.h3 = makeElem('h3');
    module.h4 = makeElem('h4');
    module.h5 = makeElem('h5');
    module.h6 = makeElem('h6');

    module.a = makeElem('a');
    module.b = makeElem('b');
    module.i = makeElem('i');
    module.strong = makeElem('strong');
    module.em = makeElem('em');

    return module;
})();
