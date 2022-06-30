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

var specialKeyNames = {
    0: '<NUL>',
    9: '<TAB>',
    10: '<CR>',
    13: '<LF>',
    27: '<ESC>',
    32: '<SP>',
    127: '<DEL>',
};

#257    | F1               | nil
#258    | F2               | nil
#259    | F3               | Capture screen
#261    | F5               | nil
#262    | F6               | Toggle Autopilot Heading Mode
#263    | F7               | nil
#264    | F8               | 
#266    | F10              | Toggle menubar
#267    | F11              | Pop up autopilot dialog
#268    | F12              | Pop up radio settings dialog
#269    | Enter            | Move rudder right
#309    | Keypad 5         | Center aileron, elevator, and rudder
#356    | Left             | Move aileron left (or adjust AP heading.)
#357    | Up               | Elevator down or decrease autopilot altitude
#358    | Right            | Move aileron right (or adjust AP heading.)
#359    | Down             | Elevator up or increase autopilot altitude
#360    | PageUp           | Increase throttle or autopilot autothrottle
#361    | PageDown         | Decrease throttle or autopilot autothrottle
#362    | Home             | Increase elevator trim
#363    | End              | Decrease elevator trim
#364    | Insert           | Move rudder left

var keyName = func (c) {
    if (contains(specialKeyNames, c)) {
        return specialKeyNames[c];
    }
    elsif (c < 0x20) {
        return 'C-' ~ keyName(c + 0x40);
    }
    elsif (c == 0x20) {
        return '<SP>';
    }
    elsif (c == 0x7F) {
        return '<DEL>';
    }
    elsif (c < 0x80) {
        return chr(c);
    }
    elsif (c >= 257 and c <= 268) {
        return 'F' ~ (c - 256);
    }
    else {
        return 'N-' ~ keyName(c - 256);
    }
};

var dumpKeyBindings = func {
    foreach (var n; props.globals.getNode('input/keyboard').getChildren('key')) {
        var c = n.getIndex();
        printf('%3i | %-7s | %-16s | %s',
            c, keyName(c), n.getValue('name'), n.getValue('desc'));
    }
};

# dumpKeyBindings();
