var mergeDicts = func () {
    var dicts = arg;
    var result = {};
    foreach (var dict; dicts) {
        if (dict == nil)
            continue;
        foreach (var k; keys(result) ~ keys(dict)) {
            if (result[k] == nil)
                result[k] = dict[k];
            elsif (dict[k] == nil)
                result[k] = result[k];
            elsif (typeof(result[k]) == 'hash')
                result[k] = mergeDicts(result[k], dict[k]);
            else
                result[k] = dict[k];
        }
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

var nth = func(vector, n, def=nil) {
    if (n < 0 or n >= size(vector))
        return def;
    else
        return vector[n];
};
