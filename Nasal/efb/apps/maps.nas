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
            minZoom: 2,
            maxZoom: 18,
            center: [ 0, 0 ],
            centerOnAircraft: 1,
            numTiles: [9, 9],
            tileSize: 256,
            tileScale: 1,
            lastTile: [ nil, nil ],

            makeURL: string.compileTemplate('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
            makePath: string.compileTemplate(mapsBase ~ '/osm-tile/{z}/{x}/{y}.png'),

            # These are used to track in-flight requests, so that we can cancel
            # them later in case they are no longer needed.
            requests: {},
            nextRequestID: 0,
        };
        return m;
    },

    touch: func (x, y) {
        foreach (var clickSpot; me.clickSpots) {
            var where = clickSpot.where;
            var xy = [x, y];
            if (typeof(where) == 'hash' and contains(where, 'parents')) {
                xy = where.canvasToLocal(xy);
                where = where.getTightBoundingBox();
            }
            if ((xy[0] >= where[0]) and
                (xy[0] < where[2]) and
                (xy[1] >= where[1]) and
                (xy[1] < where[3])) {
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

    foreground: func () {
        me.updateTimer.start();
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

    makeClickable: func (elem, what) {
        append(me.clickSpots, {
            where: elem,
            what: what,
        });
    },

    makeClickableArea: func (area, what) {
        append(me.clickSpots, {
            where: area,
            what: what,
        });
    },

    cancelAllRequests: func {
        foreach (var k; keys(me.requests)) {
            me.requests[k].abort();
        }
        me.requests = {};
    },

    makeZoomScrollOverlay: func () {
        var self = me;
        me.overlay = me.masterGroup.createChild('group');
        canvas.parsesvg(me.overlay, "Aircraft/E-jet-family/Models/EFB/zoom-scroll-overlay.svg", {'font-mapper': font_mapper});
        var zoomDigital = me.overlay.getElementById('zoomPercent.digital');
        var zoomUnit = me.overlay.getElementById('zoomPercent.unit');
        var autoCenterMarker = me.overlay.getElementById('autoCenterMarker');
        var update = func () {
            zoomDigital.setText('LVL');
            zoomUnit.setText(sprintf("%1.0f", self.zoom));
            self.updateMap();
        };
        var zoomIn = func () {
            self.zoom = math.min(self.maxZoom, self.zoom + 1);
            self.cancelAllRequests();
            update();
        };
        var zoomOut = func () {
            self.zoom = math.max(self.minZoom, self.zoom - 1);
            self.cancelAllRequests();
            update();
        };
        var scroll = func (dx, dy) {
            self.center[0] = math.min(77.5, math.max(-77.5, self.center[0] - dy * math.pow(0.5, self.zoom) * 50));
            self.center[1] = self.center[1] + dx * math.pow(0.5, self.zoom) * 50;
            self.centerOnAircraft = 0;
            autoCenterMarker.hide();
            update();
        };
        var resetScroll = func () {
            var pos = geo.aircraft_position();
            self.center[0] = pos.lat();
            self.center[1] = pos.lon();
            self.centerOnAircraft = 1;
            autoCenterMarker.show();
            update();
        };
        me.makeClickable(me.overlay.getElementById('btnZoomIn'), zoomIn);
        me.makeClickable(me.overlay.getElementById('btnZoomOut'), zoomOut);
        me.makeClickable(me.overlay.getElementById('btnScrollN'), func { scroll(0, -1); });
        me.makeClickable(me.overlay.getElementById('btnScrollS'), func { scroll(0, 1); });
        me.makeClickable(me.overlay.getElementById('btnScrollE'), func { scroll(1, 0); });
        me.makeClickable(me.overlay.getElementById('btnScrollW'), func { scroll(-1, 0); });
        me.makeClickable(me.overlay.getElementById('btnScrollReset'), resetScroll);
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
            256 - math.mod(math.floor(slippyCenterFloat[0] * me.tileSize * me.tileScale + 0.5), me.tileSize * me.tileScale),
            384 - math.mod(math.floor(slippyCenterFloat[1] * me.tileSize * me.tileScale + 0.5), me.tileSize * me.tileScale),
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
                        s: (rand() >= 0.5) ? 'a' : 'b',
                        tms_y: ymax - int(me.tileIndex[1] + y) - 1,
                    };
                    while (pos.x < 0)
                        pos.x = pos.x + ymax;
                    while (pos.x >= ymax)
                        pos.x = pos.x - ymax;

                    (func (requestedZoom, requestedTileIndex) {
                        var imgPath = me.makePath(pos);
                        var tile = me.tiles[x][y];

                        if (pos.y < 0 or pos.y >= ymax) {
                            tile.hide();
                        }
                        elsif (io.stat(imgPath) == nil) {
                            tile.hide();
                            var imgURL = me.makeURL(pos);
                            var self = me;
                            var requestID = me.nextRequestID;
                            me.nextRequestID += 1;

                            # Download to a temporary filename, then move it
                            # into place.
                            # This is necessary because the HTTP request may
                            # get cancelled with the file half-written, which
                            # leads to incomplete files being loaded from the
                            # cache later.
                            var tmpPath = imgPath ~ '~' ~ requestID;
                            var request = http.save(imgURL, tmpPath);
                            me.requests[requestID] = request;
                            request
                                .done(func {
                                    delete(me.requests, requestID);
                                    # We may not need this file anymore, but
                                    # since we've already downloaded it,
                                    # there's no harm in keeping it.
                                    os.path.new(tmpPath).rename(imgPath);

                                    # If the zoom or scroll positions have
                                    # changed, then we should not set the tile;
                                    # some other request will do it instead.
                                    if (self.zoom == requestedZoom and
                                        self.tileIndex[0] == requestedTileIndex[0] and
                                        self.tileIndex[1] == requestedTileIndex[1]) {
                                        tile.set("src", imgPath);
                                        tile.show();
                                    }
                                })
                                .fail(func (r) {
                                    delete(me.requests, requestID);
                                    if (r.status != -1)
                                        print('Failed to get image ' ~ imgPath ~ ': ' ~ r.status ~ ': ' ~ r.reason);
                                    # Request aborted or failed, remove
                                    # temporary file - if it exists, it will be
                                    # incomplete, and thus useless.
                                    os.path.new(tmpPath).remove();
                                });
                        }
                        else {
                            # Re-use cached image
                            #print('loading ' ~ imgPath);
                            tile.set("src", imgPath);
                            tile.show();
                        }
                    })(me.zoom, subvec(me.tileIndex, 0, 2));
                }
            }

            me.lastTile = subvec(me.tileIndex, 0, 2);
        }
        me.tileContainer.setTranslation(shift[0], shift[1]);
    },

};

