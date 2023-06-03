var doors = {
    toggle: func (name) {
        doors[name].toggle();
    },
    open: func (name) {
        doors[name].open();
    },
    close: func (name) {
        doors[name].close();
    },
    stop: func (name) {
        doors[name].stop();
    },
};

var Door = {
    new: func(name, transit_time) {
        var node = props.globals.getNode('sim/model/door-positions/' ~ name, 1);
        node.setValues({
                'position-norm': 0,
                'target-position': 0,
                'transit-time': transit_time,
            });
        var m = {
            parents: [Door],
            node: node,
        };
        return m;
    },

    open: func {
        me.node.setValue('target-position', 1);
        return me;
    },

    close: func {
        me.node.setValue('target-position', 0);
        return me;
    },

    toggle: func {
        me.node.setValue('target-position',
            !me.node.getValue('target-position'));
    },

    stop: func {
        me.node.setValue('target-position', me.node.getValue('position-norm'));
        return me;
    },
};

var makeDoor = func(name, transit_time) {
    doors[name] = Door.new(name, transit_time);
};

makeDoor("l1", 10);
makeDoor("l2", 10);
makeDoor("r1", 10);
makeDoor("r2", 10);
makeDoor("cockpit-door", 3);
makeDoor("l1-stairs", 20);
makeDoor("l2-stairs", 20);
makeDoor("eng1-control",2);
makeDoor("eng2-control",2);
makeDoor("fcm-elevator",1);
makeDoor("fcm-rudder",1);
makeDoor("fcm-spoilers",1);
