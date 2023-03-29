var mergeDicts = func (lhs, rhs) {
    var result = {};
    if (lhs == nil)
        return copyDict(rhs);
    if (rhs == nil)
        return copyDict(lhs);
    foreach (var k; keys(lhs) ~ keys(rhs)) {
        if (lhs[k] == nil)
            result[k] = rhs[k];
        elsif (rhs[k] == nil)
            result[k] = lhs[k];
        elsif (typeof(lhs[k]) == 'hash')
            result[k] = mergeDicts(lhs[k], rhs[k]);
        else
            result[k] = rhs[k];
    }
    return result;
};

var copyDict = func (lhs) {
    if (lhs == nil)
        return {};
    var result = {};
    foreach (var k; keys(lhs)) {
        result[k] = lhs[k];
    }
    return result;
};

