var calculateLimits = func {
    var limitsNode = props.globals.getNode('/limits/mass-and-balance');
    var keys = [
        'maximum-takeoff-mass',
        'maximum-landing-mass',
        'maximum-payload',
        'maximum-ramp-mass',
        'maximum-zero-fuel-mass',
    ];
    foreach (var key; keys) {
        limitsNode.setValue(key ~ '-kg',
            (limitsNode.getValue(key ~ '-lbs') or 0) * LB2KG);
    }
};


var checkCG = func {
    var val = getprop('/weight-and-balance/mac-position-percent') or 0;
    foreach (var when; ['takeoff', 'landing', 'clean']) {
        var min = getprop('/weight-and-balance/mac-percent-min-' ~ when) or 0;
        var max = getprop('/weight-and-balance/mac-percent-max-' ~ when) or 100;
        setprop(
            '/weight-and-balance/mac-' ~ when ~ '-ok',
            val >= min and val <= max);
        setprop(
            '/weight-and-balance/mac-' ~ when ~ '-check-text',
            (val < min) ? '---' :
            (val > max) ? '+++' :
            'OK');
    }
};

var weightsInitialized = 0;
var initializeWeights = func {
    if (weightsInitialized) return;

    calculateLimits();

    var payloadNode = props.globals.getNode('/payload');
    foreach (var weightNode; payloadNode.getChildren('weight')) {
        (func {
            var weightLBNode = weightNode.getNode('weight-lb', 1).getAliasTarget();
            var weightKGNode = weightNode.getNode('weight-kg', 1);
            setlistener(weightLBNode, func (node) {
                weightKGNode.setValue(node.getValue() * LB2KG);
            }, 1, 0);
            if (weightNode.getValue('unit-lb')) {
                weightNode.setValue('max-unit',
                    math.floor(
                        weightNode.getValue('max-lb') /
                        weightNode.getValue('unit-lb')));
                weightNode.setValue('min-unit',
                    math.floor(
                        weightNode.getValue('min-lb') /
                        weightNode.getValue('unit-lb')));
                var unitLBNode = weightNode.getChild('unit-lb');
                var unitCountNode = weightNode.getChild('unit-count');
                setlistener(weightLBNode, func (node) {
                    unitCountNode.setValue(node.getValue() / unitLBNode.getValue());
                }, 1, 0);
            }
        })();
    }

    setlistener('/weight-and-balance/mac-position-percent', checkCG, 1, 0);
    weightsInitialized = 1;
};

setlistener("sim/signals/fdm-initialized", initializeWeights);
