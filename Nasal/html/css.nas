include('util.nas');

var CSS = (func {
    var module = {};

    var parse = func (selectorStr) {
        var i = 0;
        var eof = func { i >= size(selectorStr); }
        var lookahead = func { if (eof()) return nil; selectorStr[i]; }
        var consume = func { if (eof()) return nil; i += 1; return selectorStr[i-1]; }
        var takeWhile = func (cond) {
            var start = i;
            while (!eof() and cond(lookahead()))
                consume();
            if (start == i)
                return nil;
            else
                return substr(selectorStr, start, i-start);
        };

        var skipSpaces = func { takeWhile(string.isblank); };

        var unexpected = func (expected) {
            if (eof())
                found = 'end of input';
            else
                found = substr(selectorStr, i, 16);
            die(
                sprintf(
                    "Parser error at position %i: expected %s, but found %s",
                    i, expected, found));
        };

        var isClassNameChar = func (c) {
            return string.isalnum(c) or c == '-'[0] or c == '_'[0];
        };

        var isIdChar = func (c) {
            return string.isalnum(c) or c == '_'[0];
        };

        var isTagChar = func (c) {
            return string.isalnum(c) or c == '-'[0] or c == '_'[0];
        };


        var parseAlternatives = func {
            var alternatives = [];
            var alternative = parseAlternative();
            append(alternatives, alternative);
            while (lookahead() == ','[0]) {
                consume();
                skipSpaces();
                alternative = parseAlternative();
                append(alternatives, alternative);
            }
            return alternatives;
        };

        var parseAlternative = func {
            var steps = [];
            var test = parseCompound();
            var relation = 'is';
            append(steps, {relation: relation, test: test});
            while (!eof() and lookahead() != ','[0]) {
                relation = parseRelation();
                test = parseCompound();
                append(steps, {relation: relation, test: test});
            }
            return steps;
        };

        var relations = {};
        relations['>'[0]] = 'child';
        relations['~'[0]] = 'sibling';
        relations['+'[0]] = 'adjacent';

        var parseRelation = func {
            if (string.isblank(lookahead())) {
                skipSpaces();
                return 'descendant';
            }
            skipSpaces();
            if (eof()) {
                unexpected('relation (space, >, ~ or +)');
            }
            var c = lookahead();
            var relation = relations[c];
            if (relation == nil) {
                unexpected('relation (space, >, ~ or +)');
            }
            else {
                consume();
                skipSpaces();
                return relation;
            }
        };

        var parseCompound = func {
            var items = [];
            while (!eof()) {
                var item = parseCompoundItem();
                if (item == nil)
                    return items;
                else
                    append(items, item);
            }
            return items;
        };

        var parseCompoundItem = func {
            if (eof()) return nil;
            var c = lookahead();
            if (c == nil) {
                unexpected('compound item');
            }
            elsif (c == '.'[0]) {
                consume();
                var className = takeWhile(isClassNameChar);
                return ['class', className];
            }
            elsif (c == ':'[0]) {
                consume();
                if (lookahead() == ':'[0]) {
                    var pseudoName = takeWhile(isTagChar);
                    return ['pseudo-elem', pseudoName];
                }
                else {
                    var pseudoName = takeWhile(isClassNameChar);
                    return ['pseudo-class', pseudoName];
                }
            }
            elsif (c == '#'[0]) {
                consume();
                var idValue = takeWhile(isIdChar);
                return ['id', idValue];
            }
            elsif (c == '*'[0]) {
                consume();
                return ['any'];
            }
            elsif (c == '[') {
                die('Attribute selectors not supported yet');
            }
            elsif (isTagChar(c)) {
                var elemName = takeWhile(isTagChar);
                return ['tag', elemName];
            }
            else {
                return nil;
            }
        };

        return parseAlternatives();
    };

    var Selector = {
        new: func (selectorStr) {
            return {
                parents: [me],
                rules: parse(selectorStr),
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
                var classes = split(' ', node.getAttribute('class'));
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
                    printf("Failed");
                    return 0;
                }
                else {
                    printf("Passed");
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

    return module;
})();
