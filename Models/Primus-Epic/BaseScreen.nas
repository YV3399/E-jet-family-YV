var BaseScreen = {

    # Args:
    # - canvas_group: the root canvas group to bind to.
    # - side: 0 = captain side, 1 = fo side. Determines which CCD to listen to,
    #         and can also be used to map registered properties to the
    #         corresponding cockpit side (e.g. radios)
    # - ccdIndex: which CCD screen selector key to grab: 0 = left screen,
    #             1 = middle screen, 2 = right screen, -1 no CCD support.
    new: func(side=0, ccdIndex=-1) {
        var m = {
                parents: [BaseScreen],
                side: side,
                ccdIndex: ccdIndex,
            };
        return m;
    },

    ############### Initialization hooks. ############### 

    # Override to register additional properties.
    registerProps: func () {
        me.registerProp('ccd.rel-x', 'controls/ccd[' ~ me.side ~ ']/rel-x');
        me.registerProp('ccd.rel-y', 'controls/ccd[' ~ me.side ~ ']/rel-y');
        me.registerProp('ccd.rel-inner', 'controls/ccd[' ~ me.side ~ ']/rel-inner');
        me.registerProp('ccd.rel-outer', 'controls/ccd[' ~ me.side ~ ']/rel-outer');
        me.registerProp('ccd.screen-select', 'controls/ccd[' ~ me.side ~ ']/screen-select');
        me.registerProp('ccd.click', 'controls/ccd[' ~ me.side ~ ']/click');
    },

    # Override to register additional elements. Use registerElemsFrom(), or add
    # dynamic elements to me.elems manually.
    registerElems: func () {
    },


    font_mapper: func(family, weight) {
        return "LiberationFonts/LiberationSans-Regular.ttf";
    },

    makeMasterGroup: func (group) {
    },

    # Override to create any canvas groups you may need. An empty me.guiOverlay
    # group is created by default; you can load an SVG into it, or fill it
    # dynamically, but it needs to exist because the CCD cursor will also go
    # into it.
    makeGroups: func () {
        me.guiOverlay = me.master.createChild("group");
    },

    # Override to add GUI widgets.
    makeWidgets: func () {
    },

    # Override to register additional listeners.
    registerListeners: func () {
        var self = me;
        me.addListener('main', '@ccd.screen-select', func (node) {
            var activeScreen = node.getValue();
            if (activeScreen == self.ccdIndex) {
                # Acquire CCD focus
                self.addListener('ccd', '@ccd.rel-x', func(node) {
                    var delta = node.getDoubleValue();
                    var p = self.props['cursor.x'];
                    p.setValue(math.min(1024, math.max(0, p.getValue() + delta)));
                });
                self.addListener('ccd', '@ccd.rel-y', func (node) {
                    var delta = node.getDoubleValue();
                    var p = self.props['cursor.y'];
                    p.setValue(math.min(1560, math.max(0, p.getValue() + delta)));
                });
                self.addListener('ccd', '@ccd.click', func(node) {
                    if (node.getBoolValue()) {
                        self.click();
                    }
                });
                self.addListener('ccd', '@ccd.rel-outer', func(node) {
                    self.scroll(node.getValue(), 0);
                });
                self.addListener('ccd', '@ccd.rel-inner', func(node) {
                    self.scroll(node.getValue(), 1);
                });
                self.cursor.show();
            }
            else {
                # Lose CCD focus
                self.clearListeners('ccd');
                self.cursor.hide();
            }
        }, 1, 0);
    },

    ############### Interaction hooks ############### 

    # Override to handle scroll events that weren't accepted by any widgets.
    masterScroll: func (direction, knob=0) {},

    ############### Update hooks ############### 

    # Low-frequency updates (on the order of 1 Hz)
    updateSlow: func () {},

    # High-frequency updates (at frame rate or similar)
    update: func () {},

    ############### Lifecycle hooks ############### 
    preRegisterListeners: func () {},
    postRegisterListeners: func () {},
    preDeinit: func () {},
    postDeinit: func () {},


    ############### Listeners. Do not override. ############### 

    addListenerGroup: func (name) {
        if (!contains(me.listeners, name)) {
            me.listeners[name] = [];
        }
    },

    clearListeners: func (group=nil) {
        if (group == nil) {
            foreach (var name; keys(me.listeners))
                me.clearListeners(name);
        }
        else {
            if (contains(me.listeners, group)) {
                foreach (var l; me.listeners[group]) {
                    removelistener(l);
                }
                me.listeners[group] = [];
            }
        }
    },

    addListener: func (group, prop, fn, init=0, type=1) {
        me.addListenerGroup(group);
        if (typeof(prop) == 'scalar' and substr(prop, 0, 1) == '@') {
            prop = me.props[substr(prop, 1)];
        }
        append(me.listeners[group], setlistener(prop, fn, init, type));
    },

    ############### Registered properties. Do not override. ############### 

    # Register a property under a given key.
    # pathOrNode may be one of:
    # - a string, representing a property path
    # - a Node
    # - a vector, where each element is either a string or a Node.
    registerProp: func (key, pathOrNode) {
        if (typeof(pathOrNode) == 'vector') {
            items = [];
            foreach (var k; pathOrNode) {
                if (typeof(k) == 'scalar') {
                    append(items, props.globals.getNode(k));
                }
                else {
                    append(items, k);
                }
            }
            me.props[key] = items;
        }
        elsif (typeof(pathOrNode) == 'scalar') {
            me.props[key] = props.globals.getNode(pathOrNode);
        }
        else {
            me.props[key] = pathOrNode;
        }
    },

    ############### Widgets. Do not override. ############### 

    addWidget: func (key, options) {
        var widget = { key: key };
        if (contains(options, 'active')) widget.active = options.active;
        if (contains(options, 'onclick')) widget.onclick = options.onclick;
        if (contains(options, 'onscroll')) widget.onscroll = options.onscroll;

        var elem = me.guiOverlay.getElementById(widget.key);
        var boxElem = me.guiOverlay.getElementById(widget.key ~ ".clickbox");
        if (boxElem == nil) {
            widget.box = elem.getTransformedBounds();
        }
        else {
            widget.box = boxElem.getTransformedBounds();
        }
        widget.elem = elem;
        if (widget['visible'] != nil and widget.visible == 0) {
            elem.hide();
        }

        append(me.widgets, widget);
    },

    ############### Registered elements. Do not override. ############### 

    registerElemsFrom: func (elemKeys, group=nil) {
        if (group == nil) group = me.master;
        foreach (var key; elemKeys) {
            me.elems[key] = group.getElementById(key);
            if (me.elems[key] == nil) {
                debug.warn("Element does not exist: " ~ key);
            }
        }
    },

    ############### Input handling. Do not override. ############### 

    touch: func(args) {
        var x = args.x * 1024;
        var y = 1560 - args.y * 1560;

        me.props['cursor.x'].setValue(x);
        me.props['cursor.y'].setValue(y);

        me.click(x, y);
    },

    click: func(x=nil, y=nil) {
        if (x == nil) x = me.props['cursor.x'].getValue();
        if (y == nil) y = me.props['cursor.y'].getValue();
        var activeCond = nil;
        foreach (var widget; me.widgets) {
            if (widget['visible'] == 0) {
                continue;
            }
            activeCond = widget['active'];
            if (isfunc(activeCond) and !activeCond()) {
                continue;
            }
            var box = widget.box;
            if (x >= box[0] and x <= box[2] and
                y >= box[1] and y <= box[3]) {
                var f = widget['onclick'];
                if (f != nil) {
                    f();
                    return;
                }
            }
        }
    },

    # direction: -1 = decrease, 1 = increase
    # knob: 0 = outer ring, 1 = inner ring
    scroll: func(direction, knob=0, x=0, y=0) {
        if (x == nil) x = me.props['cursor.x'].getValue();
        if (y == nil) y = me.props['cursor.y'].getValue();
        var activeCond = nil;
        foreach (var widget; me.widgets) {
            if (widget['visible'] == 0) {
                continue;
            }
            activeCond = widget['active'];
            if (isfunc(activeCond) and !activeCond()) {
                continue;
            }
            var box = widget.box;
            if (x >= box[0] and x <= box[2] and
                y >= box[1] and y <= box[3]) {
                var f = widget['onscroll'];
                if (f != nil) {
                    f(direction, knob);
                    return;
                }
            }
        }
        # No widget wants this event; process as master scroll.
        me.masterScroll(direction, knob);
    },


    ############### Lifecycle management. Do not override. ############### 

    init: func (canvas_group) {
        var self = me; # for listeners

        me.listeners = {};
        me.listeners.ccd = [];
        me.listeners.main = [];
        me.elems = {};
        me.props = {};
        me.widgets = [];

        me.registerProps();
        me.master = canvas_group;
        me.makeMasterGroup(canvas_group);
        me.makeGroups();
        me.registerElems();
        me.makeWidgets();
        me.cursor = me.guiOverlay.createChild("group");
        if (me.ccdIndex >= 0)
            canvas.parsesvg(me.cursor, "Aircraft/E-jet-family/Models/Primus-Epic/cursor.svg", {'font-mapper': me.font_mapper});

        me.preRegisterListeners();
        me.registerListeners();
        me.postRegisterListeners();

        return me;
    },

    deinit: func {
        me.preDeinit();
        me.clearListeners();
        me.postDeinit();
    },

};

