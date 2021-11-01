# Traffic layer
#

var colorByLevel = {
     # 0: other
     0: [0,1,1],
     # 1: proximity
     1: [0,1,1],
     # 2: traffic advisory (TA)
     2: [1,0.75,0],
     # 3: resolution advisory (RA)
     3: [1,0,0],
};

var colorDefault = [0.5, 0.5, 0.5];

var drawBlip = func(elem, threatLvl) {
    if (threatLvl == 3) {
        # resolution advisory
        elem.reset()
            .moveTo(-17,-17)
            .horiz(34)
            .vert(34)
            .horiz(-34)
            .close();
    }
    elsif (threatLvl == 2) {
        # traffic advisory
        elem.reset()
            .moveTo(-17,0)
            .arcSmallCW(17,17,0,34,0)
            .arcSmallCW(17,17,0,-34,0);
    }
    elsif (threatLvl == 1) {
        # proximate traffic
        elem.reset()
            .moveTo(-17,0)
            .lineTo(0,-17)
            .lineTo(17,0)
            .lineTo(0,17)
            .close();
    }
    else {
        # other traffic
        elem.reset()
            .moveTo(-17,0)
            .lineTo(0,-17)
            .lineTo(17,0)
            .lineTo(0,17)
            .lineTo(-17,0)
            .moveTo(-14,0)
            .lineTo(0,-14)
            .lineTo(14,0)
            .lineTo(0,14)
            .lineTo(-14,0)
            .close();
    }
};


var TrafficLayer = {
    new: func(camera, group) {
        var m = {
            parents: [TrafficLayer],
            camera: camera,
            refAlt: 0,
            group: group,
            items: {},
            numItems: 0,
            updateKeys: [],
            addListener: nil,
            delListener: nil,
            masterProp: props.globals.getNode('/ai/models/'),
        };
        return m;
    },

    makeElems: func () {
        if (me.group == nil) return nil;
        var elems = {};
        elems['master'] = me.group.createChild('group');
        elems['blip'] = elems.master.createChild('path')
            .setStrokeLineWidth(0);
        elems['text'] = elems.master.createChild('text')
            .setDrawMode(canvas.Text.TEXT)
            .setText(sprintf("0"))
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setColor(1,1,1)
            .setFontSize(20)
            .setAlignment("center-center");
        elems['master'].hide();
        elems['arrowUp'] = elems.master.createChild("text")
            .setDrawMode(canvas.Text.TEXT)
            .setText(sprintf("↑"))
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setColor(1,1,1)
            .setFontSize(40)
            .setTranslation(16, 0)
            .setAlignment("left-center");
        elems['arrowDown'] = elems.master.createChild("text")
            .setDrawMode(canvas.Text.TEXT)
            .setText(sprintf("↓"))
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setColor(1,1,1)
            .setFontSize(40)
            .setTranslation(16, 0)
            .setAlignment("left-center");
            return elems;
    },

    addNode: func(path, node) {
        printf("ADD: %s", path);
        var prop = {
            'master': node,
        };
        if (me.items[path] == nil) {
            me.items[path] = {
                prop: prop,
                elems: me.makeElems(),
                data: {'threatLevel': -2},
            };
            me.numItems += 1;
        }
        else {
            me.items[path].prop = prop;
            me.items[path].data = {'threatLevel': -2};
        }
        printf('Added %s, %i/%i items', path, me.numItems, size(me.items));
    },

    removeNode: func(path) {
        printf("DEL: %s", path);
        if (contains(me.items, path)) {
            me.items[path].elems.master._node.remove();
            delete(me.items, path);
            me.numItems -= 1;
        }
        printf('Removed %s, %i/%i items', path, me.numItems, size(me.items));
    },

    start: func() {
        me.stop();
        var self = me;
        me.resync(1);
        me.addListener = setlistener('/ai/models/model-added', func(changed, listen, mode, is_child) {
            var path = changed.getValue();
            if (path == nil) return;
            var acftMasterProp = props.globals.getNode(path);
            self.addNode(path, acftMasterProp);
        }, 1, 1);
        me.delListener = setlistener('/ai/models/model-removed', func(changed, listen, mode, is_child) {
            var path = changed.getValue();
            if (path == nil) return;
            self.removeNode(path);
        }, 1, 1);
    },

    stop: func() {
        if (me.addListener != nil) {
            removelistener(me.addListener);
            me.addListener = nil;
        }
        if (me.delListener != nil) {
            removelistener(me.delListener);
            me.delListener = nil;
        }
        me.items = {};
        if (me.group != nil) {
            me.group.removeAllChildren();
        }
    },

    resync: func (hard=0) {
        if (hard) {
            me.items = {};
            if (me.group != nil) {
                me.group.removeAllChildren();
            }
        }
        var nodes = nil;
        foreach (var what; ['carrier', 'aircraft', 'swift', 'multiplayer']) {
            nodes = me.masterProp.getChildren(what);
            foreach (var node; nodes) {
                var path = '/ai[0]/models[0]/' ~ what ~ '[' ~ node.getIndex() ~ ']';
                if (node.getValue('valid')) {
                    me.addNode(path, node);
                }
                else {
                    me.removeNode(path);
                }
            }
        }
    },

    update: func() {
        if (size(me.updateKeys) == 0) {
            me.updateKeys = keys(me.items);
        }
        var path = pop(me.updateKeys);
        foreach (var path; keys(me.items)) {
            me.updateItem(path);
        }
    },

    redraw: func() {
        foreach (var path; keys(me.items)) {
            me.redrawItem(me.items[path]);
        }
    },

    setRefAlt: func(alt) {
        me.refAlt = alt;
    },

    updateItem: func(path) {
        var item = me.items[path];
        if (item == nil) return;
        if (item.prop == nil) {
            if (item.elems != nil) {
                item.elems.master.hide();
            }
            return;
        }

        if (item.prop['lat'] == nil) {
            item.prop['lat'] = item.prop.master.getNode('position/latitude-deg');
        }
        if (item.prop['lon'] == nil) {
            item.prop['lon'] = item.prop.master.getNode('position/longitude-deg');
        }
        if (item.prop['alt'] == nil) {
            item.prop['alt'] = item.prop.master.getNode('position/altitude-ft');
        }
        if (item.prop['threatLevel'] == nil) {
            item.prop['threatLevel'] = item.prop.master.getNode('tcas/threat-level');
        }
        if (item.prop['callsign'] == nil) {
            item.prop['callsign'] = item.prop.master.getNode('callsign');
        }
        if (item.prop['vspeed'] == nil) {
            item.prop['vspeed'] = item.prop.master.getNode('velocities/vertical-speed-fps');
        }

        # this item has a prop associated with it
        if (item.elems == nil) {
            item.elems = me.makeElems();
        }
        var oldThreatLevel = item.data['threatLevel'];
        foreach (var k; ['lat', 'lon', 'alt', 'threatLevel', 'callsign', 'vspeed']) {
            if (item.prop[k] != nil) {
                item.data[k] = item.prop[k].getValue();
            }
        }
        if (oldThreatLevel != item.data['threatLevel']) {
            item.data['threatLevelDirty'] = 1;
        }
    },

    redrawItem: func (item) {
        # debug.dump("REDRAW ", item.data);
        var lat = item.data['lat'];
        var lon = item.data['lon'];
        var alt = item.data['alt'];
        var vspeed = item.data['vspeed'];
        var threatLevelDirty = item.data['threatLevelDirty'];
        if (lat != nil and lon != nil and vspeed != nil) {
            var coords = geo.Coord.new();
            coords.set_latlon(lat, lon);
            var (x, y) = me.camera.project(coords);
            item.elems.master.setTranslation(x, y);
            # printf("%s %f %f", path, x, y);
            if (threatLevelDirty) {
                # printf('%s THREAT LVL: %i', item.data['callsign'] or '???', item.data['threatLevel']);
                var threatLevel = item.data['threatLevel'];
                # debug.dump(item.data, threatLevel);
                drawBlip(item.elems.blip, threatLevel);
                var rgb = colorByLevel[threatLevel];
                if (rgb == nil) rgb = colorDefault;
                var color = canvas._getColor(rgb);
                var (r, g, b) = rgb;
                item.elems.blip.setColorFill(r, g, b);
                item.elems.text.setColor(r, g, b);
                item.elems.arrowUp.setColor(r, g, b);
                item.elems.arrowDown.setColor(r, g, b);
                item.elems.master.set('z-index', threatLevel + 2);
                item.data['threatLevelDirty'] = 0;
            }

            item.elems.arrowUp.setVisible(vspeed * 60 > 500);
            item.elems.arrowDown.setVisible(vspeed * 60 < -500);

            var altDiff100 = ((item.data['alt'] or me.refAlt) - me.refAlt) / 100;
            item.elems.text.setVisible(math.abs(altDiff100) > 0.5);
            item.elems.text.setText(sprintf("%+02.0f", altDiff100));
            if (altDiff100 < 0) {
                item.elems.text.setTranslation(0, 30);
                item.elems.arrowUp.setTranslation(16, 30);
                item.elems.arrowDown.setTranslation(16, 30);
            }
            else {
                item.elems.text.setTranslation(0, -30);
                item.elems.arrowUp.setTranslation(16, -30);
                item.elems.arrowDown.setTranslation(16, -30);
            }

            item.elems.master.show();
        }
        else {
            item.elems.master.hide();
        }
    },

};
