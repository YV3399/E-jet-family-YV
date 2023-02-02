## Parser Combinators for Nasal.

########## Parser results. ##########

var Result = {
    new: func(failed, valOrMsg) {
        var r = { parents: [Result] };
        r.className = 'Result';
        r.failed = failed;
        r.ok = !failed;

        if (failed) {
            r.error = valOrMsg;
        }
        else {
            r.val = valOrMsg;
        }
        r;
    },

    # Functor
    pure: func (val) { Result.new(0, val); },
    map: func (f) {
        if (me.ok)
            me.pure(f(me.val));
        else
            me
    },

    # Monad
    bind: func (next) {
        if (me.ok)
            next(me.val);
        else
            me
    },

    # Fail
    fail: func (msg) { Result.new(1, msg); },

    failToDie: func {
        if (me.failed)
            die(me.error)
        else
            me.val
    },
};

########## Parser type. ##########

var Parser = {
    new: func(run) {
        return {
            parents: [Parser],
            className: 'Parser',
            run: run,
        };
    },

    # Functor
    pure: func (val) {
        Parser.new(func (s) {
            Result.pure(val);
        });
    },
    map: func (f) {
        var p = me;
        Parser.new(func (s) {
            p.run(s).map(f);
        });
    },


    # Monad
    bind: func (f) {
        var p = me;
        Parser.new(func (s) {
            var r = p.run(s);
            if (r.failed)
                r;
            else
                f(r.val).run(s);
        });
    },

    # Fail
    fail: func (msg) {
        Parser.new(func (s) {
            Result.fail(msg);
        });
    },

    runOrDie: func (s) {
        me.run(s).failToDie();
    },
};

var TokenStream = {
    new: func (tokens) {
        return {
            parents: [TokenStream],
            tokens: tokens,
            numTokens: size(tokens),
            readpos: 0,
        };
    },

    eof: func {
        return (me.readpos >= me.numTokens);
    },

    peek: func (n=0) {
        if (me.readpos + n >= me.numTokens)
            Result.fail('Unexpected end of input');
        else
            Result.pure(me.tokens[me.readpos + n]);
    },

    consume: func {
        if (me.eof())
            return Result.fail('Unexpected end of input');
        me.readpos += 1;
        Result.pure(me.tokens[me.readpos - 1]);
    },

    consumeAll: func {
        var result = subvec(me.tokens, me.readpos);
        me.readpos = me.numTokens;
        Result.pure(result);
    },

    unconsumed: func {
        subvec(me.tokens, me.readpos);
    },

};

anyToken = Parser.new(func (s) {
    s.consume();
});

peekToken = Parser.new(func (s) {
    s.peek();
});

var eof = Parser.new(func (s) {
    if (s.eof())
        Result.pure(nil);
    else
        Result.fail('Expected EOF');
});


var satisfy = func (cond, expected=nil) {
    return
        peekToken.bind(func (token) {
            if (cond(token))
                anyToken;
            elsif (expected == nil)
                Parser.fail(sprintf('Unexpected %s', token));
            else
                Parser.fail(sprintf('Unexpected %s, expected %s', token, expected));
        });
};

var oneOf = func (items) {
    satisfy(func (token) { return contains(items, token); });
};

var exactly = func (item) {
    satisfy(func (token) { return token == item; }, item);
};

var tryParse = func (p, catch=nil) {
    Parser.new(func (s) {
        var readposBuf = s.readpos;
        var result = p.run(s);
        if (result.failed) {
            # parse failed: roll back
            s.readpos = readposBuf;
            if (catch == nil)
                result;
            else
                catch.run(s);
        }
        else {
            result;
        }
    }
)};

var optionally = func (p, def=nil) {
    tryParse(p, Parser.pure(def));
};


var manyTill = func (p, stop) {
    Parser.new(func (s) {
        var result = [];
        var val = nil;
        while (1) {
            var r = tryParse(stop).run(s);
            if (r.ok) {
                return Result.pure(result);
            }
            var inner = p.run(s);
            if (inner.failed) {
                return inner;
            }
            else {
                append(result, inner.val);
            }
        }
        Result.fail('This point cannot be reached');
    });
};

var many = func (p) {
    Parser.new(func (s) {
        var result = [];
        var val = nil;
        while (!s.eof()) {
            var inner = tryParse(p).run(s);
            if (inner.failed)
                return Result.pure(result);
            else
                append(result, inner.val);
        }
        Result.pure(result);
    });
};

var some = func (p) {
    many(p).bind(func (result) {
        if (size(result))
            Parser.pure(result);
        else
            Parser.fail("Expected at least one element");
    });
};

var choice = func (ps, expected=nil) {
    Parser.new(func (s) {
        foreach (var p; ps) {
            var r = tryParse(p).run(s);
            if (r.ok)
                return r;
        }
        Result.fail('Choice failed');
    });
};
