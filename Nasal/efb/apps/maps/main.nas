include('baseApp.nas');

var mapsBase = getprop("/sim/fg-home") ~ '/cache/maps';

var errorTilePath = acdir ~ '/Models/EFB/error-tile.png';

var MapsApp = {
    new: func(masterGroup) {
        var m = BaseApp.new(masterGroup);
        m.parents = [me] ~ m.parents;

        m.zoom = 12;
        m.minZoom = 2;
        m.maxZoom = 18;
        m.center = [ 0, 0 ];
        m.centerOnAircraft = 1;
        m.numTiles = [9, 9];
        m.tileSize = 256;
        m.tileScale = 1;
        m.lastTile = [ nil, nil ];

        m.makeURL = string.compileTemplate('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png');
        m.makePath = string.compileTemplate('maps/osm-tile/{z}/{x}/{y}.png');

        m.requestedURLs = {};

        return m;
    },

    handleBack: func () {
    },

    background: func () {
        me.updateTimer.stop();
    },

    foreground: func () {
        me.updateTimer.start();
    },

    cancelAllRequests: func () {
        foreach (var url; keys(me.requestedURLs)) {
            downloadManager.cancel(url, 0);
        }
        me.requestedURLs = {};
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
                me.tiles[x][y].setTranslation(
                    int((x - me.centerTileOffset[0]) * me.tileSize * me.tileScale + 0.5),
                    int((y - me.centerTileOffset[1]) * me.tileSize * me.tileScale + 0.5)
                )
                .setScale(me.tileScale, me.tileScale);
            }
        }
        # Uncomment to show tile grid (for debugging)
        # for (var x = 0; x < me.numTiles[0]; x += 1) {
        #     for(var y = 0; y < me.numTiles[1]; y += 1) {
        #         me.tileContainer.createChild('path')
        #           .rect(
        #             int((x - me.centerTileOffset[0]) * me.tileSize * me.tileScale + 0.5),
        #             int((y - me.centerTileOffset[1]) * me.tileSize * me.tileScale + 0.5),
        #             me.tileSize - 0.5,
        #             me.tileSize - 0.5)
        #           .setColor(0, 0, 1);
        #     }
        # }
        me.infoText = me.contentGroup.createChild('text')
            .setText('')
            .setFont(font_mapper('sans', 'normal'))
            .setFontSize(12, 1)
            .setAlignment('left-bottom')
            .setTranslation(10, 730)
            .setColor(0, 0, 0);

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
        me.updateTimer = maketimer(0.1, func {
            self.updateMap();
        });
        me.updateTimer.start();
    },

    updateZoomScroll: func () {
        me.zoomDigital.setText('LVL');
        me.zoomUnit.setText(sprintf("%1.0f", me.zoom));
        me.updateMap();
    },
    zoomIn: func () {
        me.zoom = math.min(me.maxZoom, me.zoom + 1);
        me.cancelAllRequests();
        me.updateZoomScroll();
    },
    zoomOut: func () {
        me.zoom = math.max(me.minZoom, me.zoom - 1);
        me.cancelAllRequests();
        me.updateZoomScroll();
    },
    scroll: func (dx, dy) {
        me.center[0] = math.min(77.5, math.max(-77.5, me.center[0] - dy * math.pow(0.5, me.zoom) * 50));
        me.center[1] = me.center[1] + dx * math.pow(0.5, me.zoom) * 50;
        me.centerOnAircraft = 0;
        me.autoCenterMarker.hide();
        me.updateZoomScroll();
    },
    resetScroll: func () {
        var pos = geo.aircraft_position();
        me.center[0] = pos.lat();
        me.center[1] = pos.lon();
        me.centerOnAircraft = 1;
        me.autoCenterMarker.show();
        me.updateZoomScroll();
    },

    makeZoomScrollOverlay: func () {
        var self = me;
        me.overlay = me.masterGroup.createChild('group');
        canvas.parsesvg(me.overlay, acdir ~ "/Models/EFB/zoom-scroll-overlay.svg", {'font-mapper': font_mapper});
        me.zoomDigital = me.overlay.getElementById('zoomPercent.digital');
        me.zoomUnit = me.overlay.getElementById('zoomPercent.unit');
        me.autoCenterMarker = me.overlay.getElementById('autoCenterMarker');

        me.makeClickable(me.overlay.getElementById('btnZoomIn'), func { self.zoomIn(); });
        me.makeClickable(me.overlay.getElementById('btnZoomOut'), func { self.zoomOut(); } );
        me.makeClickable(me.overlay.getElementById('btnScrollN'), func { self.scroll(0, -1); });
        me.makeClickable(me.overlay.getElementById('btnScrollS'), func { self.scroll(0, 1); });
        me.makeClickable(me.overlay.getElementById('btnScrollE'), func { self.scroll(1, 0); });
        me.makeClickable(me.overlay.getElementById('btnScrollW'), func { self.scroll(-1, 0); });
        me.makeClickable(me.overlay.getElementById('btnScrollReset'), func { self.resetScroll(); });
        me.updateZoomScroll();
    },

    wheel: func (axis, amount) {
        if (axis == 0) {
            if (amount > 0)
                me.zoomOut();
            elsif (amount < 0)
                me.zoomIn();
        }
    },

    updateMap: func () {
        var self = me;
        var acpos = geo.aircraft_position();

        if (me.centerOnAircraft) {
            me.center[0] = acpos.lat();
            me.center[1] = acpos.lon();
        }

        var lat = me.center[0];
        var lon = me.center[1];

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
            256 - math.mod(math.floor(slippyCenterFloat[0] * me.tileSize * me.tileScale), me.tileSize * me.tileScale),
            384 - math.mod(math.floor(slippyCenterFloat[1] * me.tileSize * me.tileScale), me.tileSize * me.tileScale),
        ];

        var acCenterFloat = [
            ymax * ((acpos.lon() + 180.0) / 360.0),
            (1 - math.ln(math.tan(acpos.lat() * math.pi/180.0) + 1 / math.cos(acpos.lat() * math.pi/180.0)) / math.pi) / 2.0 * ymax
        ];
        var acOffset = [
            256 + (acCenterFloat[0] - slippyCenterFloat[0]) * me.tileSize * me.tileScale + 0.5,
            384 + (acCenterFloat[1] - slippyCenterFloat[1]) * me.tileSize * me.tileScale + 0.5,
        ];

        me.aircraftMarker.setRotation(getprop('/orientation/true-heading-deg') * D2R);
        me.aircraftMarker.setTranslation(acOffset[0], acOffset[1]);

        # This is the Slippy Map location of the 0,0 tile
        var offset = [
            slippyCenter[0] - me.centerTileOffset[0],
            slippyCenter[1] - me.centerTileOffset[1]
        ];

        me.tileIndex = [math.floor(offset[0]), math.floor(offset[1])];
        me.contentGroup.setCenter(256, 384).setRotation(getprop('/instrumentation/efb/orientation-norm') * math.pi * -0.5);
        me.overlay.setCenter(360, 360).setRotation(getprop('/instrumentation/efb/orientation-norm') * math.pi * -0.5);

        if (me.tileIndex[0] != me.lastTile[0] or
            me.tileIndex[1] != me.lastTile[1]) {
            for(var x = 0; x < me.numTiles[0]; x += 1) {
                for(var y = 0; y < me.numTiles[1]; y += 1) {
                    var pos = {
                        z: me.zoom,
                        x: int(me.tileIndex[0] + x),
                        y: int(me.tileIndex[1] + y),
                        tms_y: ymax - int(me.tileIndex[1] + y) - 1,
                    };
                    # We're so poor we can't even afford a real hashing
                    # function.
                    pos.s = ((pos.x + pos.y + pos.z) & 1) ? 'a' : 'b';
                    while (pos.x < 0)
                        pos.x = pos.x + ymax;
                    while (pos.x >= ymax)
                        pos.x = pos.x - ymax;

                    (func () {
                        var imgPath = me.makePath(pos);
                        var imgURL = me.makeURL(pos);
                        var tile = me.tiles[x][y];

                        if (pos.y < 0 or pos.y >= ymax) {
                            tile.hide();
                        }
                        else {
                            self.requestedURLs[imgURL] = 1;
                            tile.hide();
                            downloadManager.get(imgURL, imgPath,
                                func (path) {
                                    delete(self.requestedURLs, imgURL);
                                    tile.set("src", path);
                                    tile.show();
                                },
                                func (r) {
                                    delete(self.requestedURLs, imgURL);
                                    logprint(4, 'Failed to get image ' ~ imgURL ~ ': ' ~ r.status ~ ': ' ~ r.reason);
                                    tile.set("src", errorTilePath);
                                    tile.show();
                                },
                                1 # replace previous subscribers
                            );
                        }
                    })();
                }
            }

            me.lastTile = subvec(me.tileIndex, 0, 2);
        }
        me.tileContainer.setTranslation(shift[0], shift[1]);
        me.infoText.setText(formatLatLon(lat, lon));
    },

};

registerApp('maps', 'Maps', 'maps.png', MapsApp);

