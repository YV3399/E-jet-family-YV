# Prop model that is linked to a prop key, allowing it to be boxed.
var KeyPropModel = {
    new: func (key, defval = nil) {
        var prop = props.globals.getNode(keyProps[key], 1);
        if (defval == nil) {
            defval = keyDefs[key];
        }
        var m = PropModel.new(prop, defval);
        m.parents = prepended(KeyPropModel, m.parents);
        m.key = key;
        return m;
    },
};


