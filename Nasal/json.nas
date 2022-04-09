# json.nas
#
# Nasal JSON Parser
#
# Copyright (c) 2022 Tobias Dammers
#
# SDPX: MIT

# The guts of the parser. You will not normally need to use this class
# directly; the `parse()` function has everything you need.
var Parser = {
    new: func(src) {
        return {
            parents: [Parser],
            src: src
        };
    },

    eof: func {
        return size(me.src) == 0;
    },

    peekOne: func {
        if (size(me.src) == 0)
            die('Unexpected end of input');
        return substr(me.src, 0, 1);
    },

    consumeOne: func {
        if (size(me.src) == 0)
            die('Unexpected end of input');
        var result = substr(me.src, 0, 1);
        me.src = substr(me.src, 1);
        return result;
    },

    test: func (what) {
        var len = size(what);
        return (substr(me.src, 0, len) == what);
    },

    consume: func(what) {
        var len = size(what);
        var testee = substr(me.src, 0, len);
        if (testee != what)
            die('Expected "' ~ debug.string(what) ~ '", but found "' ~ debug.string(testee) ~ '"');
        me.src = substr(me.src, len);
        return testee;
    },

    tryConsume: func(what) {
        var len = size(what);
        var testee = substr(me.src, 0, len);
        if (testee != what)
            return nil;
        me.src = substr(me.src, len);
        return testee;
    },

    skipSpaces: func {
        while (!me.eof() and me.src[0] <= 32)
            me.consumeOne();
    },

    value: func {
        me.skipSpaces();
        var t = me.peekOne();
        var c = t[0];
        if (t == '{')
            return me.object();
        elsif (t == '[')
            return me.array();
        elsif (t == '"' or t == "'")
            return me.string();
        elsif (string.isdigit(c) or t == '-' or t == '.')
            me.number();
        elsif (me.tryConsume('null') == 'null')
            return nil;
        elsif (me.tryConsume('true') == 'true')
            return 1;
        elsif (me.tryConsume('false') == 'false')
            return 0;
        else
            die('Syntax error: expected JSON value, but found "' ~ debug.string(t) ~ '"');
    },

    object: func {
        me.consume('{');
        var result = {};
        while (me.peekOne() != '}') {
            me.skipSpaces();
            var k = me.string();
            me.skipSpaces();
            me.consume(':');
            var v = me.value();
            result[k] = v;
            me.skipSpaces();
            var t = me.peekOne();
            if (t != '}') {
                me.consume(',');
            }
        }
        me.skipSpaces();
        me.consume('}');
        return result;
    },

    array: func {
        me.consume('[');
        me.skipSpaces();
        var result = [];
        while (me.peekOne() != ']') {
            var v = me.value();
            append(result, v);
            me.skipSpaces();
            if (me.tryConsume(',') != ',')
                break;
        }
        me.skipSpaces();
        me.consume(']');
        return result;
    },

    string: func {
        var delim = me.consumeOne();
        var result = '';
        while (me.peekOne() != delim) {
            var c = me.consumeOne();
            if (c == "\\") {
                c = me.consumeOne();
                if (c == 'n')
                    c = "\n";
                elsif (c == 'r')
                    c = "\r";
                elsif (c == 't')
                    c = "\t";
                elsif (c == 'b')
                    c = "\b";
                elsif (c == 'u')
                    die('Unicode escapes not supported yet');
            }
            result = result ~ c;
        }
        me.consume(delim);
        return result;
    },

    number: func {
        var str = '';
        if (!me.eof() and me.peekOne() == '-')
            str = me.consumeOne();
        while (!me.eof() and string.isdigit(me.peekOne()[0]))
            str = str ~ me.consumeOne();
        if (!me.eof() and me.peekOne() == '.') {
            str = str ~ me.consume('.');
            while (!me.eof() and string.isdigit(me.peekOne()[0]))
                str = str ~ me.consumeOne();
        }
        if (!me.eof() and string.lc(me.peekOne()) == 'e') {
            str = str ~ me.consumeOne();
            if (!me.eof() and (me.peekOne() == '-' or me.peekOne() == '+'))
                str = str ~ me.consumeOne();
            while (!me.eof() and string.isdigit(me.peekOne()[0]))
                str = str ~ me.consumeOne();
        }
        if (str == '') die('Expected number, but found "' ~ me.peekOne() ~ '"');
        return num(str);
    },

    json: func {
        var v = me.value();
        me.skipSpaces();
        if (!me.eof())
            debug.warn('Excess data at end of JSON document');
        return v;
    },

};

var parse = func (src) {
    var p = Parser.new(src);
    return p.json();
};

# var testDocuments = [
#     'null',
#     'true',
#     'false',
#     '123',
#     '123.45',
#     '-123.45',
#     '-1.0E-10',
#     '-1e-2',
#     '-1e+5',
#     '"hello"',
#     '[]',
#     '{}',
#     '[1,2,3]',
#     '[ 1, 2, 3 ]',
#     '{"foo":"bar"}',
#     '{"foo":"bar", "baz": "quux"}',
#     '{"foo": 123, "baz": \'quux\'}',
# ];
# foreach (var testDocument; testDocuments)
#     debug.dump(testDocument, parse(testDocument));
