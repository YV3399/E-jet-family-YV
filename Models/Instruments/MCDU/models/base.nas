var BaseModel = {
    new: func () {
        return {
            parents: [BaseModel]
        };
    },

    get: func () { return nil; },
    set: func (val) { },
    reset: func () { },
    getKey: func () { return nil; },
    subscribe: func (f) { return nil; },
    unsubscribe: func (l) { },
};

