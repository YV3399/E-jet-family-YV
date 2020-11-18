# Route layer for MFD map

var RouteLayer = {
    new: func (camera, group) {
        var m = {
            parents: [RouteLayer],
            camera: camera,
            group: group,
            flightplans: {},
            currentWPI: 0,
        };
        return m;
    },

    setCurrentWaypoint: func (wpi) {
        me.currentWPI = wpi;
    },

    setCamera: func (cam) {
        me.camera = cam;
    },

    # type can be one of:
    # - 'active'
    # - 'modified'
    # - 'alternate'
    setFlightplan: func (key, type, fp) {
        var entry = me.flightplans[key];
        if (entry == nil) entry = {
            elem: me.group.createChild("group"),
        };
        entry['type'] = type;
        entry['waypoints'] = [];

        me.delFlightplan(key);

        var fpSize = fp.getPlanSize();
        var missed = 0;
        me.currentWPI = fp.current;

        for (var i = 0; i < fpSize; i += 1) {
            var wp = fp.getWP(i);
            var coords = geo.Coord.new();
            coords.set_latlon(wp.lat, wp.lon);
            var wpElem = entry.elem.createChild("group");
            var wpIcon = wpElem.createChild("path")
                        .setStrokeLineWidth(2)
                        .setColor(1, 0.5, 0)
                        .moveTo(0,-25)
                        .lineTo(-5,-5)
                        .lineTo(-25,0)
                        .lineTo(-5,5)
                        .lineTo(0,25)
                        .lineTo(5,5)
                        .lineTo(25,0)
                        .lineTo(5,-5)
                        .close();
            var wpLabel = wpElem.createChild("text")
                        .setAlignment('left-center')
                        .setFontSize(28)
                        .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                        .setColor(1, 0.5, 0)
                        .setTranslation(30, 0)
                        .setText(wp.wp_name);
            var wpPath = entry.elem.createChild("path")
                        .setStrokeLineWidth(2)
                        .setColor(1, 0.5, 0);
            append(entry.waypoints, {
                'name': wp.wp_name,
                'coords': coords,
                'flyType': wp.fly_type,
                'missed': missed,
                'path': wp.path(),
                'elems': {
                    'master': wpElem,
                    'icon': wpIcon,
                    'label': wpLabel,
                    'path': wpPath,
                }
            });
            if (i > 1 and wp.wp_type == "runway") {
                missed = 1;
            }
        }
        me.flightplans[key] = entry;
    },

    delFlightplan: func (key) {
        var fp = me.flightplans[key];
        if (fp == nil) return;

        var elem = me.flightplans[key].elem;
        if (elem != nil) {
            elem.removeAllChildren();
        }
        delete(me.flightplans, key);
    },

    redraw: func() {
        foreach (var key; keys(me.flightplans)) {
            me.redrawFlightplan(me.flightplans[key]);
        }
    },

    redrawFlightplan: func(fp) {
        var color = [1, 1, 0];
        var xPrev = nil;
        var yPrev = nil;
        forindex (var i; fp.waypoints) {
            var wp = fp.waypoints[i];
            var (x, y) = me.camera.project(wp.coords);
            wp.elems['master'].setTranslation(x, y);
            if (i == me.currentWPI) {
                color = [1, 0, 1];
            }
            elsif (wp.missed) {
                color = [0, 1, 1];
            }
            else {
                color = [1, 1, 1];
            }
            wp.elems['path'].reset();
            if (xPrev != nil and yPrev != nil) {
                wp.elems['path']
                    .moveTo(xPrev, yPrev)
                    .lineTo(x, y);
            }
            if (x != nil and y != nil) {
                xPrev = x;
                yPrev = y;
            }
            # var first = 1;
            # foreach (var latlon; wp.path) {
            #     var (x, y) = me.camera.projectLatLon(latlon);
            #     if (first) {
            #         wp.elems['path'].moveTo(x, y);
            #         first = 0;
            #     }
            #     else {
            #         wp.elems['path'].lineTo(x, y);
            #     }
            # }
            wp.elems['icon'].setColor(color[0], color[1], color[2]);
            wp.elems['label'].setColor(color[0], color[1], color[2]);
            wp.elems['path'].setColor(color[0], color[1], color[2]);
        }
    },
};
