var Parser = (func {
    var module = {};

    var Stream = {
        new: func (input) {
            return {
                parents: [me],
                data: input,
                pos: 0,
            };
        },

        eof: func { return me.pos >= size(me.data); },

        lookahead: func {
            if (me.eof()) return nil;
            return me.data[me.pos];
        },

        consume: func () {
            if (me.eof()) return nil;
            me.pos += 1;
            return me.data[me.pos - 1];
        },

        save: func {
            return me.pos;
        },

        restore: func (pos) {
            me.pos = math.min(pos, size(me.data));
        },

        takeWhileP: func (cond) {
            var start = me.save();
            while (!me.eof() and cond(me.lookahead())) {
                me.consume();
            }
            var end = me.save();
            if (start == end) {
                # Condition didn't match
                return nil;
            }
            else {
                return substr(me.data, start, end - start);
            }
        },

        matchStr: func (str) {
            var candidate = substr(me.data, me.pos, size(str));
            if (candidate == str) {
                me.pos += size(candidate);
                return str;
            }
            else {
                return nil;
            }
        },

        unexpected: func (expected) {
            if (me.eof())
                found = '<<end of input>>';
            else
                found = substr(me.data, me.pos, 16);
            die(
                sprintf(
                    "Parser error at position %i: expected %s, but found %s",
                    me.pos, expected, found));
        },

    };

    module.Stream = Stream;

    module.try = func (f) {
        return func(s) {
            var savepoint = s.save();
            var result = f(s);
            if (result == nil) {
                s.restore(savepoint);
            }
            return result;
        };
    };

    module.choice = func (choices) {
        return func (s) {
            foreach (var p; choices) {
                var r = module.try(p)(s);
                if (r != nil)
                    return r;
            }
            return nil;
        }
    };

    module.run = func (pfunc, input) {
        var s = Stream.new(input);
        return pfunc(s);
    };

    return module;
})();
