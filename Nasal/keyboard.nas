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
            keyNode = props.globals.getNode('/input/keyboard').addChild('key', key, 0);
            keyNode.setValue('name', binding.name);
            keyNode.setValue('desc', 'VIEW ' ~ binding.name);
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
};

var setupMCDUKeys = func () {
    var ordA = utf8.strc('a', 0);
    var ordZ = utf8.strc('z', 0);
    var ord0 = utf8.strc('0', 0);
    var ord9 = utf8.strc('9', 0);
    var ordDot = utf8.strc('.', 0);
    var ordSlash = utf8.strc('/', 0);
    var ordDash = utf8.strc('-', 0);
    var ordSpace = utf8.strc(' ', 0);

    var registerKey = func (key, cmd) {
        # First, establish a <key> node with the right key number.
        var keyNode = props.globals.getNode('/input/keyboard/key[' ~ key ~ ']');
        if (keyNode == nil) {
            keyNode = props.globals.getNode('/input/keyboard').addChild('key', key, 0);
            keyNode.setValue('name', chr(key));
            keyNode.setValue('desc', 'MCDU ' ~ cmd);
        }

        # Now walk the existing bindings, if any, so they only fire when
        # keyboard mode is enabled.
        var existingBindings = keyNode.getChildren('binding');
        foreach (var existingBinding; existingBindings) {
            var existingConditionNode = existingBinding.getChild('condition');
            if (existingConditionNode == nil) {
                existingConditionNode = existingBinding.addChild('condition');
            }
            var equalsNode = existingConditionNode.addChild('equals');
            equalsNode.setValue('property', '/controls/keyboard/grabbed');
            equalsNode.setValue('value', -1);
        }

        # And now we append our own bindings.
        for (var i = 0; i < 2; i += 1) {
            var bindingNode = keyNode.addChild('binding');
            bindingNode.setValue('command', 'property-assign');
            bindingNode.setValue('property', '/instrumentation/mcdu[' ~ i ~ ']/command');
            bindingNode.setValue('value', cmd);
            var equalsNode = bindingNode.addChild('condition').addChild('equals');
            equalsNode.setValue('property', '/controls/keyboard/grabbed');
            equalsNode.setValue('value', i);
        }
    };

    for (var key = ordA; key <= ordZ; key += 1) { registerKey(key, string.uc(chr(key))); }
    for (var key = ord0; key <= ord9; key += 1) { registerKey(key, chr(key)); }
    registerKey(ordDot, '.');
    registerKey(ordSlash, '/');
    registerKey(ordDash, '-');
    registerKey(ordSpace, 'SP');
    registerKey(127, 'DEL');
    registerKey(8, 'CLR');
};

setupViewKeys();
setupMCDUKeys();
