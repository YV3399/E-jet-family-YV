var setupEFBKeys = func () {
    var ord = func (str) utf8.strc(str, 0);

    props.globals.getNode('/instrumentation/efb/keyboard-grabbed', 1).setValue(0);
    props.globals.getNode('/instrumentation/efb/input/keyboard', 1).setValue('');

    var registerKey = func (key, cmd, includeShift=0) {
        # First, establish a <key> node with the right key number.
        var keyNode = props.globals.getNode('/input/keyboard/key[' ~ key ~ ']');
        if (keyNode == nil) {
            keyNode = props.globals.getNode('/input/keyboard').addChild('key', key, 0);
            keyNode.setValue('name', chr(key));
            keyNode.setValue('desc', 'EFB ' ~ cmd);
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
            equalsNode.setValue('property', '/instrumentation/efb/keyboard-grabbed');
            equalsNode.setValue('value', 0);
        }

        # And now we append our own bindings.
        var bindingNode = keyNode.addChild('binding');
        bindingNode.setValue('command', 'property-assign');
        bindingNode.setValue('property', '/instrumentation/efb/input/keyboard');
        bindingNode.setValue('value', cmd);
        var equalsNode = bindingNode.addChild('condition').addChild('equals');
        equalsNode.setValue('property', '/instrumentation/efb/keyboard-grabbed');
        equalsNode.setValue('value', 1);

        if (includeShift) {
            var modShiftNode = keyNode.addChild('mod-shift');
            var bindingNode = modShiftNode.addChild('binding');
            bindingNode.setValue('command', 'property-assign');
            bindingNode.setValue('property', '/instrumentation/efb/input/keyboard');
            bindingNode.setValue('value', cmd);
            var equalsNode = bindingNode.addChild('condition').addChild('equals');
            equalsNode.setValue('property', '/instrumentation/efb/keyboard-grabbed');
            equalsNode.setValue('value', 1);
        }
    };

    var normalKeys = [
        "'", "\\" , '!', '"', '#', '%', '&', '(', ')', '*', '+', ',', '-', '.',
        '/' , ':', ';', '<', '=', '>', '?', '@', '[', ']', '^', '_', '`', '{',
        '|', '}', '~', '$', '€',
        '0' , '1', '2', '3', '4', '5', '6', '7', '8', '9',
        'a', 'A', 'b', 'B', 'c', 'C', 'd', 'D', 'e', 'E', 'f', 'F', 'g',
        'G', 'h', 'H', 'i', 'I', 'j', 'J', 'k', 'K', 'l' , 'L' , 'm', 'M', 'n',
        'N', 'o', 'O', 'p' , 'P' , 'q', 'Q', 'r', 'R', 's', 'S', 't', 'T', 'u',
        'U', 'v', 'V', 'w', 'W', 'x', 'X', 'y', 'Y', 'z', 'Z'
    ];

    foreach (var char; normalKeys)
        registerKey(ord(char), char);
    registerKey(ord(' '), 'space', 1);
    registerKey(127, 'delete');
    registerKey(8, 'backspace', 1);
    registerKey(10, 'enter', 1);
    registerKey(13, 'enter', 1);
    registerKey(27, 'esc', 1);
    registerKey(356, 'left', 1);
    registerKey(357, 'up', 1);
    registerKey(358, 'right', 1);
    registerKey(359, 'down', 1);
    registerKey(360, 'pgup', 1);
    registerKey(361, 'pgdn', 1);
    registerKey(362, 'home', 1);
    registerKey(363, 'end', 1);
    registerKey(364, 'insert', 1);
};

setupEFBKeys();
