include('util.nas');
include('parser.nas');

var CSS = (func {
    var module = {};

    var try = Parser.try;
    var choice = Parser.choice;
    var many = Parser.many;

    var isWhitespace = func (c) {
        return c <= 32;
    };

    var skipSpaces = func (s) {
        return s.takeWhileP(isWhitespace);
    };

    # Parsing stuff
    var isClassNameChar = func (c) {
        return string.isalnum(c) or c == '-'[0] or c == '_'[0];
    };

    var isIdChar = func (c) {
        return string.isalnum(c) or c == '_'[0];
    };

    var isTagChar = func (c) {
        return string.isalnum(c) or c == '-'[0] or c == '_'[0];
    };

    var isStyleKeyChar = func (c) {
        return string.isalnum(c) or c == '-'[0];
    };

    var isStyleValueChar = func (c) {
        return string.isalnum(c) or c == '-'[0] or c == '.'[0] or c == '_'[0] or c == '%'[0];
    };

    var isHexDigit = func (c) {
        return (string.isdigit(c) or
                   (c >= 'a'[0] and c <= 'z'[0]) or
                   (c >= 'A'[0] and c <= 'Z'[0]));
    };

    var expandShorthand = func (key, vals) {
        if (key == 'padding' or key == 'margin') {
            var top = nth(vals, 0);
            var right = nth(vals, 1, top);
            var bottom = nth(vals, 2, top);
            var left = nth(vals, 3, right);
            return [
                [ key ~ '-top', top ],
                [ key ~ '-right', right ],
                [ key ~ '-bottom', bottom ],
                [ key ~ '-left', left ],
            ];
        }
        elsif (key == 'border' or key == 'border-left' or key == 'border-right' or key == 'border-top' or key == 'border-bottom') {
            var borderWidth = '1px'; # should be 'medium'
            var borderStyle = 'none';
            var borderColor = nil; # should be 'currentcolor'
            foreach (var val; vals) {
                if (typeof(val) == 'vector' or contains(namedColors, val)) {
                    # it's a color
                    borderColor = val;
                }
                elsif (val == 'solid' or val == 'dotted' or val == 'dashed' or
                       val == 'inset' or val == 'outset' or val == 'none' or
                       val == 'hidden' or val == 'double' or val == 'ridge' or
                       val == 'groove') {
                    # it's a line style
                    borderStyle = val;
                }
                else {
                    borderWidth = val;
                }
            }
            var directions = [];
            if (key == 'border')
                directions = ['left', 'right', 'top', 'bottom'];
            else
                directions = [substr(key, 7)];
            var result = [];
            foreach (var direction; directions) {
                append(result, [ 'border-' ~ direction ~ '-width', borderWidth ]);
                append(result, [ 'border-' ~ direction ~ '-style', borderStyle ]);
                if (borderColor != nil)
                    append(result, [ 'border-' ~ direction ~ '-color', borderColor ]);
            }
            return result;
        }
        elsif (key == 'border-width' or key == 'border-color' or key == 'border-style') {
            var parts = split('-', key);
            var prefix = nth(parts, 0);
            var suffix = nth(parts, 1);
            var top = nth(vals, 0);
            var right = nth(vals, 1, top);
            var bottom = nth(vals, 2, top);
            var left = nth(vals, 3, right);
            return [
                [ prefix ~ '-top-' ~ suffix, top ],
                [ prefix ~ '-right-' ~ suffix, right ],
                [ prefix ~ '-bottom-' ~ suffix, bottom ],
                [ prefix ~ '-left-' ~ suffix, left ],
            ];
        }
        elsif (key == 'list-style') {
            var result = [];
            var position = nil;
            var type = nil;
            var image = nil; # not supported yet
            foreach (var val; vals) {
                if (val == 'inside' or val == 'outside') {
                    position = val;
                }
                elsif (substr(val, 0, 4) == 'url') {
                    image = val;
                }
                else {
                    type = val;
                }
            }
            if (position != nil)
                append(result, ['list-style-position', position]);
            if (type != nil)
                append(result, ['list-style-type', type]);
            if (image != nil)
                append(result, ['list-style-image', image]);
        }
        else {
            return [ [key, nth(vals, 0) ] ];
        }
    };

    var pAlternatives = func (s) {
        var alternatives = [];
        var alternative = pAlternative(s);
        append(alternatives, alternative);
        while (s.lookahead() == ','[0]) {
            s.consume();
            skipSpaces(s);
            alternative = pAlternative(s);
            append(alternatives, alternative);
        }
        return alternatives;
    };

    var pAlternative = func (s) {
        var steps = [];
        var test = pCompound(s);
        var relation = 'is';
        append(steps, {relation: relation, test: test});
        while (!s.eof() and s.lookahead() != ','[0] and s.lookahead() != '{'[0]) {
            relation = pRelation(s);
            if (relation == nil) {
                break;
            }
            test = pCompound(s);
            append(steps, {relation: relation, test: test});
        }
        return steps;
    };

    var pRelation = func (s) {
        var relations = {};
        relations['>'[0]] = 'child';
        relations['~'[0]] = 'sibling';
        relations['+'[0]] = 'adjacent';

        skipSpaces(s);
        if (s.eof()) {
            return nil;
        }
        var c = s.lookahead();
        if (c == '{'[0]) {
            return nil;
        }
        var relation = relations[c];
        if (relation == nil) {
            return 'descendant';
        }
        else {
            s.consume();
            skipSpaces(s);
            return relation;
        }
    };

    var pCompound = func (s) {
        var items = [];
        while (!s.eof()) {
            var item = pCompoundItem(s);
            if (item == nil)
                return items;
            else
                append(items, item);
        }
        return items;
    };

    var pCompoundItem = func (s) {
        if (s.eof()) return nil;
        var c = s.lookahead();
        if (c == nil) {
            s.unexpected('compound item');
        }
        elsif (c == '.'[0]) {
            s.consume();
            var className = s.takeWhileP(isClassNameChar);
            return ['class', className];
        }
        elsif (c == ':'[0]) {
            s.consume();
            if (s.lookahead() == ':'[0]) {
                var pseudoName = s.takeWhileP(isTagChar);
                return ['pseudo-elem', pseudoName];
            }
            else {
                var pseudoName = s.takeWhileP(isClassNameChar);
                return ['pseudo-class', pseudoName];
            }
        }
        elsif (c == '#'[0]) {
            s.consume();
            var idValue = s.takeWhileP(isIdChar);
            return ['id', idValue];
        }
        elsif (c == '*'[0]) {
            s.consume();
            return ['any'];
        }
        elsif (c == '[') {
            die('Attribute selectors not supported yet');
        }
        elsif (isTagChar(c)) {
            var elemName = s.takeWhileP(isTagChar);
            return ['tag', elemName];
        }
        else {
            return nil;
        }
    };

    var pUnquotedPropertyValue = func (s) {
        var lead = s.takeWhileP(string.isalnum);
        if (lead == 'rgb')
            return pRGB(s);
        elsif (lead == 'rgba')
            return pRGBA(s);
        else
            return lead;
    };

    var pRGB = func (s) {
        skipSpaces(s);
        s.matchStr('(') or s.unexpected('(');
        skipSpaces(s);
        var r = s.takeWhileP(string.isdigit);
        skipSpaces(s);
        s.matchStr(',') or s.unexpected(',');
        skipSpaces(s);
        var g = s.takeWhileP(string.isdigit);
        skipSpaces(s);
        s.matchStr(',') or s.unexpected(',');
        skipSpaces(s);
        var b = s.takeWhileP(string.isdigit);
        skipSpaces(s);
        s.matchStr(')') or s.unexpected(')');
        skipSpaces(s);
        return [r, g, b, 1];
    };

    var pRGBA = func (s) {
        skipSpaces(s);
        s.matchStr('(') or s.unexpected('(');
        skipSpaces(s);
        var r = s.takeWhileP(string.isdigit);
        skipSpaces(s);
        s.matchStr(',') or s.unexpected(',');
        skipSpaces(s);
        var g = s.takeWhileP(string.isdigit);
        skipSpaces(s);
        s.matchStr(',') or s.unexpected(',');
        skipSpaces(s);
        var b = s.takeWhileP(string.isdigit);
        skipSpaces(s);
        s.matchStr(',') or s.unexpected(',');
        skipSpaces(s);
        var a = pFloat(s);
        skipSpaces(s);
        s.matchStr(')') or s.unexpected(')');
        skipSpaces(s);
        return [r, g, b, a];
    };

    var pHexColor = func (s) {
        s.matchStr('#') or s.unexpected('#');
        var digits = s.takeWhileP(isHexDigit);
        var l = size(digits);
        var rgba = [];
        var result = 0;
        var raw = [];
        if (l == 3) {
            raw = [
                substr(digits, 0, 1) ~ substr(digits, 0, 1),
                substr(digits, 1, 1) ~ substr(digits, 1, 1),
                substr(digits, 2, 1) ~ substr(digits, 2, 1)
            ];
        }
        elsif (l == 4) {
            raw = [
                substr(digits, 0, 1) ~ substr(digits, 0, 1),
                substr(digits, 1, 1) ~ substr(digits, 1, 1),
                substr(digits, 2, 1) ~ substr(digits, 2, 1),
                substr(digits, 3, 1) ~ substr(digits, 3, 1)
            ];
        }
        elsif (l == 6) {
            raw = [
                substr(digits, 0, 2),
                substr(digits, 2, 2),
                substr(digits, 4, 2)
            ];
        }
        elsif (l == 8) {
            raw = [
                substr(digits, 0, 2),
                substr(digits, 2, 2),
                substr(digits, 4, 2),
                substr(digits, 6, 2),
            ];
        }
        else {
            s.unexpected('hexadecimal digits');
        }
        for (var i = 0; i < size(raw); i += 1) {
            append(rgba, int('0x' ~ raw[i]));
        }
        if (size(rgba) == 4) {
            rgba[4] /= 255;
        }
        return rgba;
    };

    var pFloat = try(func (s) {
        var sign = s.matchStr('-') or '';
        var intpart = s.takeWhileP(string.isdigit);
        var decimalSign = s.matchStr('.') or '';
        var fracpart = '';
        if (decimalSign == '.') {
            fracpart = s.takeWhileP(string.isdigit);
        }
        if (intpart == nil and fracpart == nil)
            s.unexpected('numeric value');
        if (intpart == nil)
            intpart = '';
        if (fracpart == nil)
            fracpart = '';
        return sign ~ intpart ~ decimalSign ~ fracpart;
    });

    var pDimensionedPropertyValue = func (s) {
        var numpart = pFloat(s);
        if (numpart == nil) {
            s.unexpected('numeric value');
        }
        skipSpaces(s);
        var unit = choice([
            # relative units
            func (s) s.matchStr('%'),
            func (s) s.matchStr('rem'),
            func (s) s.matchStr('em'),
            func (s) s.matchStr('vw'),
            func (s) s.matchStr('vh'),

            # absolute units
            func (s) s.matchStr('px'),
            func (s) s.matchStr('pt'),
            func (s) s.matchStr('mm'),
            func (s) s.matchStr('cm'),
            func (s) s.matchStr('in'),
        ])(s) or '';
        skipSpaces(s);
        return (numpart ~ unit);
    };

    var pStyleRule = func (s) {
        var key = s.takeWhileP(isStyleKeyChar);
        if (key == '' or key == nil)
            s.unexpected('property name', debug.string(key));
        skipSpaces(s);
        s.matchStr(':') or s.unexpected(':');
        var val = nil;
        skipSpaces(s);
        while (!s.eof() and s.lookahead() != ';'[0] and s.lookahead != '}'[0]) {
            var v = nil;
            if (s.lookahead() == '"'[0]) {
                s.consume();
                v = s.takeWhileP(func (c) { return c != '"'[0]; });
                s.matchStr('"') or s.unexpected('"');
            }
            elsif (s.lookahead() == "'"[0]) {
                s.consume();
                v = s.takeWhileP(func (c) { return c !="'"[0]; });
                s.matchStr("'") or s.unexpected("'");
            }
            elsif (s.lookahead() == '#'[0]) {
                v = pHexColor(s);
                if (v == '' or v == nil) {
                    s.unexpected("hexadecimal color");
                }
            }
            elsif (string.isdigit(s.lookahead()) or s.lookahead() == '-'[0]) {
                v = pDimensionedPropertyValue(s);
            }
            else {
                v = pUnquotedPropertyValue(s);
            }
            if (v == '' or v == nil) {
                s.unexpected("property value");
            }
            skipSpaces(s);
            if (val == nil)
                val = [v];
            else
                append(val, v);
        }
        if (s.lookahead() == ';'[0]) {
            s.consume();
            skipSpaces(s);
        }
        elsif (!s.eof() and s.lookahead() != '}'[0]) {
            s.unexpected('semicolon or end of input');
        }
        return expandShorthand(key, val);
    };

    var pStyleRules = func (s) {
        var style = {};
        while (!s.eof() and s.lookahead() != '}'[0]) {
            var result = pStyleRule(s);
            if (result == nil) {
                break;
            }
            foreach (var kv; result) {
                (key, value) = kv;
                style[key] = value;
            }
        }
        return style;
    };

    var pRuleBlock = func (s) {
        var selector = Selector.new(pAlternatives(s));
        skipSpaces(s);
        s.matchStr('{') or s.unexpected('{');
        skipSpaces(s);
        var style = pStyleRules(s);
        s.matchStr('}') or s.unexpected('}');
        skipSpaces(s);
        return { selector: selector, style: style };
    };

    var pStylesheet = func (s) {
        var result = [];
        while (!s.eof()) {
            var block = pRuleBlock(s);
            if (block != nil) {
                append(result, block);
            }
        }
        return result;
    };

    var Stylesheet = {
        new: func (blocks) {
            return {
                parents: [me],
                blocks: blocks,
            };
        },

        dump: func {
            foreach (var block; me.blocks) {
                debug.dump(block);
            }
        },

        apply: func (node) {
            me.applyNode(node);
            foreach (var child; node.getChildren()) {
                me.apply(child);
            }
        },

        applyNode: func (node) {
            foreach (var block; me.blocks) {
                var matched = 0;
                if (block.selector.test(node)) {
                    var ancestry = node.getAncestry();
                    var path = '';
                    for (var i = size(ancestry) - 1; i >= 0; i -= 1) {
                        path ~= ancestry[i].getNodeName() ~ ' > ';
                    }
                    path ~= node.getNodeName();
                    matched = 1;
                }
                if (matched) {
                    node.applyCSSStyle(block.style);
                }
            }
        },
    };

    var Selector = {
        new: func (rules) {
            return {
                parents: [me],
                rules: rules,
            };
        },

        dump: func {
            foreach (var rule; me.rules) {
                debug.dump(rule);
            }
        },

        test: func (node) {
            foreach (var rule; me.rules) {
                if (me.testRule(rule, node)) {
                    return 1;
                }
            }
            return 0;
        },

        testSimple: func (simple, node) {
            if (simple[0] == 'class') {
                var classes = split(' ', node.getAttribute('class') or '');
                foreach (var class; classes) {
                    if (class != '' and class == simple[1]) {
                        return 1;
                    }
                }
                return 0;
            }
            elsif (simple[0] == 'tag') {
                return (node.getNodeName() == simple[1]);
            }
            elsif (simple[0] == 'id') {
                return node.getAttribute('id') == simple[1];
            }
            elsif (simple[0] == 'any') {
                return 1;
            }
            else {
                die('Selector type ' ~ simple[0] ~ ' not supported.');
            }
        },

        testCompound: func (compound, node) {
            foreach (var item; compound) {
                if (!me.testSimple(item, node)) {
                    return 0;
                }
            }
            return 1;
        },

        testRule: func (rule, node) {
            var axis = [node];


            # Process rule backwards
            for (var i = size(rule) - 1; i >= 0; i -= 1) {
                var step = rule[i];
                var passedNodes = [];

                # Test the step's compound condition
                foreach (var testNode; axis) {
                    if (me.testCompound(step.test, testNode)) {
                        append(passedNodes, testNode);
                    }
                }
                if (size(passedNodes) == 0) {
                    # None of the axis nodes passed.
                    return 0;
                }

                # Test has passed; determine the next axis to inspect.
                if (step.relation == 'is') {
                    # We just need the current node to pass; this should
                    # generally be the first item in each rule, so we can
                    # short-circuit here.
                    return 1;
                }
                elsif (step.relation == 'child') {
                    var parentNode = node.getParentNode();
                    axis = parentNode == nil ? [] : [parentNode];
                }
                elsif (step.relation == 'descendant') {
                    axis = node.getAncestry();
                }
                elsif (step.relation == 'adjacent') {
                    var prev = node.getPreviousSibling();
                    axis = prev == nil ? [] : [prev];
                }
                elsif (step.relation == 'sibling') {
                    axis = node.getSiblings();
                }
                else {
                    die("Invalid axis: " ~ step.relation);
                }
            }
        },

    };

    module.Selector = Selector;
    module.Stylesheet = Stylesheet;

    module.parseSelector = func (str) {
        var rules = Parser.run(pAlternatives, str);
        return Selector.new(rules);
    };

    module.parseStylesheet = func (str) {
        var rules = Parser.run(pStylesheet, str);
        return Stylesheet.new(rules);
    };

    module.parseStyleAttrib = func (str) {
        return Parser.run(pStyleRules, str);
    };

    module.loadStylesheet = func (path) {
        var str = io.readfile(path);
        return module.parseStylesheet(str);
    };

    return module;
})();
