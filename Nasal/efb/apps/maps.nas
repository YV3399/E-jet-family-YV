include('apps/base.nas');

var mapsBase = getprop("/sim/fg-home") ~ '/cache/maps';

var MapsApp = {
    new: func(masterGroup) {
        var m = {
            parents: [MapsApp, BaseApp],
            masterGroup: masterGroup,
            currentTitle: "Maps",
            clickSpots: [],
            zoom: 12,
            center: [ 0, 0 ],
            centerOnAircraft: 1,
            numTiles: [5, 5],
            tileSize: 256,
            lastTile: [ nil, nil ],
            # makeURL: string.compileTemplate('https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png'),
            # makePath: string.compileTemplate(mapsBase ~ '/osm-intl/{z}/{x}/{y}.png'),
            makeURL: string.compileTemplate('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
            makePath: string.compileTemplate(mapsBase ~ '/osm-tile/{z}/{x}/{y}.png'),
        };
        return m;
    },
    # https://a.tile.openstreetmap.org/12/2093/1352.png

    touch: func (x, y) {
        foreach (var clickSpot; me.clickSpots) {
            if ((x >= clickSpot.where[0]) and
                (x < clickSpot.where[2]) and
                (y >= clickSpot.where[1]) and
                (y < clickSpot.where[3])) {
                clickSpot.what();
                break;
            }
        }
    },

    handleBack: func () {
    },

    background: func () {
        me.updateTimer.stop();
    },

    initializeTiles: func {
        me.tileContainer = me.contentGroup.createChild('group');
		me.tiles = setsize([], me.numTiles[0]);
        me.centerTileOffset = [
            (me.numTiles[0] - 1.0) / 2.0,
            (me.numTiles[1] - 1.0) / 2.0
        ];
        for (var x = 0; x < me.numTiles[0]; x += 1) {
            me.tiles[x] = setsize([], me.numTiles[1]);
            for(var y = 0; y < me.numTiles[1]; y += 1) {
                me.tiles[x][y] = me.tileContainer.createChild("image", "map-tile");
            }
        }
        me.aircraftMarker = me.contentGroup.createChild('path')
                                           .moveTo(0, -10)
                                           .lineTo(8, 10)
                                           .lineTo(0, 5)
                                           .lineTo(-8, 10)
                                           .close()
                                           .setColor(1, 0, 0).setColorFill(0, 0, 0, 0);
    },

    initialize: func () {
        var self = me;
        me.bgfill = me.masterGroup.createChild('path')
                        .rect(0, 0, 512, 768)
                        .setColorFill(128, 128, 192);
        me.contentGroup = me.masterGroup.createChild('group');
        me.initializeTiles();
        me.makeZoomScrollOverlay();
        me.updateTimer = maketimer(0.25, func {
            self.updateMap();
        });
        me.updateTimer.start();
    },

    makeClickable: func (elem, what) {
        append(me.clickSpots, {
            where: elem.getTransformedBounds(),
            what: what,
        });
    },

    makeClickableArea: func (area, what) {
        append(me.clickSpots, {
            where: area,
            what: what,
        });
    },

    makeZoomScrollOverlay: func () {
        var self = me;
        var overlay = me.masterGroup.createChild('group');
        canvas.parsesvg(overlay, "Aircraft/E-jet-family/Models/EFB/zoom-scroll-overlay.svg", {'font-mapper': font_mapper});
        var zoomDigital = overlay.getElementById('zoomPercent.digital');
        var zoomUnit = overlay.getElementById('zoomPercent.unit');
        var update = func () {
            zoomDigital.setText('LVL');
            zoomUnit.setText(sprintf("%1.0f", self.zoom));
            self.updateMap();
        };
        var zoomIn = func () { self.zoom = self.zoom + 1; update(); };
        var zoomOut = func () { self.zoom = self.zoom - 1; update(); };
        var scroll = func (dx, dy) {
            self.center[0] = self.center[0] - dy * math.pow(0.5, self.zoom) * 50;
            self.center[1] = self.center[1] + dx * math.pow(0.5, self.zoom) * 50;
            self.centerOnAircraft = 0;
            update();
        };
        var resetScroll = func () {
            var pos = geo.aircraft_position();
            self.center[0] = pos.lat();
            self.center[1] = pos.lon();
            self.centerOnAircraft = 1;
            update();
        };
        me.makeClickable(overlay.getElementById('btnZoomIn'), zoomIn);
        me.makeClickable(overlay.getElementById('btnZoomOut'), zoomOut);
        me.makeClickable(overlay.getElementById('btnScrollN'), func { scroll(0, -1); });
        me.makeClickable(overlay.getElementById('btnScrollS'), func { scroll(0, 1); });
        me.makeClickable(overlay.getElementById('btnScrollE'), func { scroll(1, 0); });
        me.makeClickable(overlay.getElementById('btnScrollW'), func { scroll(-1, 0); });
        me.makeClickable(overlay.getElementById('btnScrollReset'), resetScroll);
        update();
    },

    updateMap: func () {
        var acpos = geo.aircraft_position();

        if (me.centerOnAircraft) {
            me.center[0] = acpos.lat();
            me.center[1] = acpos.lon();
        }

        var lat = me.center[0];
        var lon = me.center[1];

        for (var x = 0; x < me.numTiles[0]; x += 1) {
            for (var y = 0; y < me.numTiles[1]; y += 1) {
                me.tiles[x][y].setTranslation(
                    int((x - me.centerTileOffset[0]) * me.tileSize + 0.5),
                    int((y - me.centerTileOffset[1]) * me.tileSize + 0.5)
                );
            }
        }

        var ymax = math.pow(2, me.zoom);

        #  Slippy map location of center point
        var slippyCenterFloat = [
            ymax * ((lon + 180.0) / 360.0),
            (1 - math.ln(math.tan(lat * math.pi/180.0) + 1 / math.cos(lat * math.pi/180.0)) / math.pi) / 2.0 * ymax
        ];
        var slippyCenter = [
            math.floor(slippyCenterFloat[0]),
            math.floor(slippyCenterFloat[1]),
        ];
        # This is the sub-tile correction we need to apply
        var shift = [
            256 - math.mod(math.floor(slippyCenterFloat[0] * me.tileSize + 0.5), me.tileSize),
            384 - math.mod(math.floor(slippyCenterFloat[1] * me.tileSize + 0.5), me.tileSize),
        ];
        me.tileContainer.setTranslation(shift[0], shift[1]);

        var acCenterFloat = [
            ymax * ((acpos.lon() + 180.0) / 360.0),
            (1 - math.ln(math.tan(acpos.lat() * math.pi/180.0) + 1 / math.cos(acpos.lat() * math.pi/180.0)) / math.pi) / 2.0 * ymax
        ];
        var acOffset = [
            256 + (acCenterFloat[0] - slippyCenterFloat[0]) * me.tileSize + 0.5,
            384 + (acCenterFloat[1] - slippyCenterFloat[1]) * me.tileSize + 0.5,
        ];

        me.aircraftMarker.setRotation(getprop('/orientation/true-heading-deg') * D2R);
        me.aircraftMarker.setTranslation(acOffset[0], acOffset[1]);

        # This is the Slippy Map location of the 0,0 tile
        var offset = [
            slippyCenter[0] - me.centerTileOffset[0],
            slippyCenter[1] - me.centerTileOffset[1]
        ];

        var tileIndex = [math.floor(offset[0]), math.floor(offset[1])];

        if (tileIndex[0] != me.lastTile[0] or
            tileIndex[1] != me.lastTile[1]) {
            for(var x = 0; x < me.numTiles[0]; x += 1) {
                for(var y = 0; y < me.numTiles[1]; y += 1) {
                    var pos = {
                         z: me.zoom,
                         x: int(tileIndex[0] + x),
                         y: int(tileIndex[1] + y),
                         s: (rand() >= 0.5) ? 'a' : 'b',
                         tms_y: ymax - int(tileIndex[1] + y) - 1,
                    };

                    (func {
                         var imgPath = me.makePath(pos);
                         var tile = me.tiles[x][y];

                         if (io.stat(imgPath) == nil) {
                             # image not found, save in $FG_HOME
                             var imgURL = me.makeURL(pos);
                             #print('requesting ' ~ imgURL);
                             http.save(imgURL, imgPath)
                                 .done(func { tile.set("src", imgPath);})
                                 .fail(func (r) print('Failed to get image ' ~ imgPath ~ ' ' ~ r.status ~ ': ' ~ r.reason));
                         }
                         else {
                             # Re-use cached image
                             #print('loading ' ~ imgPath);
                             tile.set("src", imgPath)
                         }
                    })();
                }
            }

            me.lastTile = tileIndex;
       }
    },

};

