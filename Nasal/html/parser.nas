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

        lookahead: func (trace=0) {
            if (me.eof()) {
                if (trace)
                    printf("lookahead @%i: EOF", me.pos);
                return nil;
            }
            var c = me.data[me.pos];
            if (trace)
                printf("lookahead @%i: %i '%s'", me.pos, c, chr(c));
            return c;
        },

        consume: func (trace=0) {
            if (me.eof()) {
                if (trace)
                    printf("consume @%i: EOF", me.pos);
                return nil;
            }
            var c = me.data[me.pos];
            if (trace)
                printf("consume @%i: %i '%s'", me.pos, c, chr(c));
            me.pos += 1;
            return c;
        },

        save: func {
            return me.pos;
        },

        restore: func (pos) {
            me.pos = math.min(pos, size(me.data));
        },

        takeWhileP: func (cond, trace=0) {
            var start = me.save();
            while (!me.eof() and cond(me.lookahead(trace))) {
                me.consume(trace);
            }
            var end = me.save();
            if (trace)
                printf("takeWhileP: %i to %i", start, end);
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

        unexpected: func (expected, found=nil) {
            if (found == nil) {
                if (me.eof())
                    found = '<<end of input>>';
                else
                    found = substr(me.data, me.pos, 16);
            }
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

    module.many = func (f) {
        return func(s) {
            var result = [];
            while (!s.eof()) {
                var r = try(f)(s);
                if (r == nil)
                    return result;
                else
                    append(result, r);
            }
            return result;
        };
    };

    module.run = func (pfunc, input) {
        var s = Stream.new(input);
        return pfunc(s);
    };

    return module;
})();
