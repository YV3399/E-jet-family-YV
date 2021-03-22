# Various stuff for making more complex keyboard interactions possible

var viewKeyBindings = [
    { key: 96, view: 201 }, # EFB
    { key: 49, view:   0 }, # Captain
    { key: 50, view: 103 }, # FO
    { key: 51, view: 197 }, # OHP
    { key: 52, view: 198 }, # GSP
    { key: 53, view: 199 }, # MCDU
    { key: 54, view: 200 }, # Center Pedestal
    { key: 55, view:   1 }, # Helicopter
    { key: 56, view:   7 }, # Tower AGL
];

var setupViewKeys = func () {
    var views = props.globals.getNode('/sim').getChildren('view');
    var mapping = {};
    for (var i = 0; i < size(views); i += 1) {
        var viewNode = views[i];
        mapping[viewNode.getIndex()] = i;
    }
    foreach (var binding; viewKeyBindings) {
        var key = binding.key;
        var viewNumRaw = binding.view;
        var viewNum = mapping[viewNumRaw];
        printf("Bind key %i -> %i = #%i\n", key, viewNumRaw, viewNum);
        setprop('/input/keyboard/key[' ~ key ~ ']/binding/value', viewNum);
    }
}

setupViewKeys();
