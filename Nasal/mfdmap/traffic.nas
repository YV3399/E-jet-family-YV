# Traffic layer

var TrafficLayer = {
    new: func(camera, group) {
        var m = {
            parents: [TrafficLayer],
            camera: camera,
            group: group,
            items: {},
            updateKeys: [],
            addListener: nil,
            delListener: nil,
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
        elems['arrow_up'] = elems.master.createChild("text")
            .setDrawMode(canvas.Text.TEXT)
            .setText(sprintf("↑"))
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setColor(1,1,1)
            .setFontSize(40)
            .setTranslation(16, 0)
            .setAlignment("left-center");
        elems['arrow_down'] = elems.master.createChild("text")
            .setDrawMode(canvas.Text.TEXT)
            .setText(sprintf("↓"))
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setColor(1,1,1)
            .setFontSize(40)
            .setTranslation(16, 0)
            .setAlignment("left-center");
            return elems;
    },

    start: func() {
        me.stop();
        var self = me;
        me.addListener = setlistener('/ai/models/model-added', func(changed, listen, mode, is_child) {
            var path = changed.getValue();
            if (path == nil) return;
            debug.dump("ADD", path);
            var masterProp = props.globals.getNode(path);
            var prop = {
                'master': masterProp,
            };
            if (me.items[path] == nil) {
                me.items[path] = {
                    prop: prop,
                    elems: me.makeElems(),
                    data: {},
                };
            }
            else {
                me.items[path].prop = prop;
                me.items[path].data = {};
            }
        }, 1, 1);
        me.delListener = setlistener('/ai/models/model-removed', func(changed, listen, mode, is_child) {
            var path = changed.getValue();
            if (path == nil) return;
            debug.dump("DEL", path);
            if (me.items[path] == nil) return;
            if (me.items[path] != nil) {
                me.items[path].prop = nil;
                me.items[path].elems.master.hide();
                me.items[path].data = {};
            }
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

        # this item has a prop associated with it
        if (item.elems == nil) {
            item.elems = me.makeElems();
        }
        item.data['lat'] = item.prop.lat.getValue();
        item.data['lon'] = item.prop.lon.getValue();
    },

    redrawItem: func (item) {
        item.elems.blip.reset()
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
        var color = canvas._getColor([1, 0.5, 0]);
        item.elems.blip.setColorFill(color);
        item.elems.text.setColor(color);
        item.elems.arrow_up.setColor(color);
        item.elems.arrow_down.setColor(color);

        var lat = item.data['lat'];
        var lon = item.data['lon'];
        if (lat != nil and lon != nil) {
            var coords = geo.Coord.new();
            coords.set_latlon(lat, lon);
            var (x, y) = me.camera.project(coords);
            item.elems.master.setTranslation(x, y);
            # printf("%s %f %f", path, x, y);
            item.elems.master.show();
        }
        else {
            item.elems.master.hide();
        }
    },

};
