# Various stuff for making more complex keyboard interactions possible

var viewKeyBindings = [
    { key: 96, view: 201, name: '`' }, # EFB
    { key: 49, view:   0, name: '1' }, # Captain
    { key: 50, view: 103, name: '2' }, # FO
    { key: 51, view: 197, name: '3' }, # OHP
    { key: 52, view: 198, name: '4' }, # GSP
    { key: 53, view: 199, name: '5' }, # MCDU
    { key: 54, view: 200, name: '6' }, # Center Pedestal
    { key: 55, view:   1, name: '7' }, # Helicopter
    { key: 56, view:   7, name: '8' }, # Tower AGL
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

        # First, establish a <key> node with the right key number.
        var keyNode = props.globals.getNode('/input/keyboard/key[' ~ key ~ ']');
        if (keyNode == nil) {
            keyNode = props.globals.getNode('/input/keyboard').addChild('key', key);
            keyNode.setValue('name', binding.name);
        }

        # Now walk the existing bindings, if any, so they only fire when
        # keyboard mode is enabled.
        var existingBindings = keyNode.getChildren('binding');
        foreach (var existingBinding; existingBindings) {
            var existingConditionNode = existingBinding.getChild('condition');
            if (existingConditionNode == nil) {
                existingBinding.setValue('condition/property', '/options/system/keyboard-mode');
            }
            else {
                existingConditionNode.addChild('property').setValue('/options/system/keyboard-mode');
            }
        }

        # And now we append our own binding.
        var bindingNode = keyNode.addChild('binding');
        bindingNode.setValue('command', 'property-assign');
        bindingNode.setValue('property', '/sim/current-view/view-number');
        bindingNode.setValue('value', viewNum);
        bindingNode.setValue('condition/not/property', '/options/system/keyboard-mode');
    }
}

setupViewKeys();
