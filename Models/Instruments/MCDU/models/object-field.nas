var ObjectFieldModel = {
    new: func (key, object, field) {
        var m = FuncModel.new(
                    key,
                    compile('object.' ~ field),
                    compile('object.' ~ field ~ ' = arg[0]'));
        m.parents = prepended(ObjectFieldModel, m.parents);
        return m;
    },
};

