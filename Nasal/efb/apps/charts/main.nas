include('baseApp.nas');
include('eventSource.nas');
include('gui/pager.nas');
include('gui/zoomScroll.nas');
include('gui/textbox.nas');
include('/html/main.nas');

var geoMap = func (georef, latDeg, lonDeg) {
    var r = 6378137.0;
    var geoX = r * lonDeg * D2R;
    var geoY = r * math.ln(math.tan(math.pi / 4 + latDeg * D2R / 2));
    var xAbs = geoX - georef.tx;
    var yAbs = geoY - georef.ty;
    var s = math.sin(-georef.ta);
    var c = math.cos(-georef.ta);
    var x = (xAbs * c - yAbs * s) / georef.k;
    var y = -(yAbs * c + xAbs * s) / georef.k;
    return [x, y];
};

var ChartsApp = {
    new: func(masterGroup) {
        var m = BaseApp.new(masterGroup);
        m.parents = [me] ~ m.parents;
        m.contentGroup = nil;
        m.currentListing = nil;
        m.currentPage = 0;
        m.numPages = nil;
        m.searchPath = nil;
        m.currentPath = "";
        m.currentQuery = nil;
        m.currentTitle = "Charts";
        m.currentPageURL = nil;
        m.currentPageMetaURL = nil;
        m.history = [];
        m.zoomLevel = 0;
        m.img = nil;
        m.img = nil;
        m.zoomScroll = nil;
        m.aircraftMarker = nil;
        m.aircraftMarkerTimer = nil;
        m.centerOnAircraft = 0;
        m.favorites = [];
        m.xhr = nil;
        m.rotation = 0;
        m.baseURL = 'http://localhost:7675/';
        m.chartfoxTokenProp = props.globals.getNode('/chartfox/oauth/access-token', 1);
        return m;
    },

    handleBack: func () {
        var popped = pop(me.history);
        if (popped != nil) {
            if (popped[0] == "*FAVS*")
                me.loadFavorites(popped[2], 0);
            else
                me.loadListing(popped[0], popped[1], popped[2], 0, popped[3]);
        }
    },

    initialize: func () {
        var self = me;

        me.stylesheet = html.CSS.loadStylesheet(me.assetDir ~ 'style.css');
        me.baseURL = getprop('/instrumentation/efb/flightbag-companion-uri') or 'http://localhost:7675/';
        me.bgfill = me.masterGroup.createChild('path')
                        .rect(0, 0, 512, 768)
                        .setColorFill(128, 128, 128);
        me.bglogo = me.masterGroup.createChild('image')
                        .set('src', me.assetDir ~ 'flightbag-large.png')
                        .setTranslation(256 - 128, 384 - 128);
        me.bgfog = me.masterGroup.createChild('path')
                        .rect(0, 0, 512, 768)
                        .setColorFill(255, 255, 255, 0.8);
        me.contentGroup = me.masterGroup.createChild('group');

        me.loadListing("", "Charts", 0, 0);
        me.aircraftMarkerTimer = maketimer(0.1, func {
            self.updateScroll();
        });

    },

    clear: func {
        me.rootWidget.removeAllChildren();
        me.zoomScroll = nil;
        me.zoomLevel = 0;
        me.sx = 0.0;
        me.sy = 0.0;
        me.img = nil;
        me.contentGroup.removeAllChildren();
        me.aircraftMarker = nil;
        if (me.aircraftMarkerTimer != nil)
            me.aircraftMarkerTimer.stop();
        me.hideKeyboard();
    },

    showLoadingScreen: func (url=nil) {
        me.clear();
        me.contentGroup.createChild('text')
            .setText('Loading...')
            .setColor(0, 0, 0)
            .setAlignment('center-center')
            .setTranslation(256, 384)
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setFontSize(48);
        if (url != nil) {
            me.contentGroup.createChild('text')
                .setText(url)
                .setColor(0, 0, 0)
                .setAlignment('left-bottom')
                .setTranslation(0, 768 - 32)
                .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                .setFontSize(12);
        }
    },

    showInfoScreen: func (msgs) {
        me.clear();
        var y = 64;
        foreach (var msg; msgs) {
            me.contentGroup.createChild('text')
                .setText(msg)
                .setColor(0, 0, 0)
                .setAlignment('center-center')
                .setTranslation(256, y)
                .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                .setFontSize(24);
            y += 32;
        }
    },

    showErrorScreen: func (errs) {
        me.clear();

        var renderContext =
                html.makeDefaultRenderContext(
                    me.contentGroup,
                    font_mapper,
                    0, 64, 512, 704);
        var errorItems = [];
        foreach (var err; errs) {
            if (typeof(err) == 'scalar') {
                err = err ~ ''; # Make sure it's really a string
                if (substr(err, 0, 7) == 'http://' or
                    substr(err, 0, 8) == 'https://') {
                    append(errorItems, H.p(H.a({'href': err}, err)));
                }
                else {
                    append(errorItems, H.p(err));
                }
            }
            elsif (isa(err, html.DOM.Node)) {
                append(errorItems, err);
            }
            else {
                debug.dump(err);
            }
        }
        var doc = H.html(
                    H.body({class: 'error'},
                        H.h1('Error'),
                        H.div({class: 'error-details'},
                            errorItems)));
        me.stylesheet.apply(doc);
        html.showDOM(doc, renderContext);
    },

    parseListing: func (xml) {
        var currentListing = [];
        var listingNode = xml.getNode('listing');
        var meta = {"numPages": 0, "page": nil, searchPath: nil};
        var entries = [];
        if (listingNode != nil)
            entries = listingNode.getChildren();
        foreach (var n; entries) {
            if (n.getName() == 'directory') {
                var entry = {
                        'path': n.getChild('path').getValue(),
                        'name': n.getChild('name').getValue(),
                    };
                entry.type = 'dir';
                append(currentListing, entry);
            }
            elsif (n.getName() == 'file') {
                var entry = {
                        'path': n.getChild('path').getValue(),
                        'name': n.getChild('name').getValue(),
                    };
                var typeNode = n.getChild('type');
                entry.type = typeNode.getValue();
                var metaNode = n.getChild('meta');
                if (metaNode == nil)
                    entry.meta = nil;
                else
                    entry.meta = metaNode.getValue();
                append(currentListing, entry);
            }
            elsif (n.getName() == 'meta') {
                var page = n.getValue('page');
                var numPages = n.getValue('numPages');
                var searchPath = n.getValue('searchPath');
                if (page != nil)
                    meta.page = page;
                if (numPages != nil)
                    meta.numPages = numPages;
                if (searchPath != nil)
                    meta.searchPath = searchPath;
            }
        }
        return {
            "files": currentListing,
            "meta": meta
        };
    },

    showListing: func () {
        var self = me;
        var lineHeight = 132;
        var hSpacing = 128;
        var perRow = math.floor(512 / hSpacing);
        var perColumn = math.floor((768 - 192) / lineHeight);
        var perPage = 12;
        var actualEntries = me.currentListing;
        me.contentGroup.removeAllChildren();
        me.rootWidget.removeAllChildren();
        me.hideKeyboard();

        if (me.searchPath != nil) {
            var doSearch = func (searchQuery) {
                if (self.searchPath != nil) {
                    self.loadListing(self.searchPath, 'Search Results', 0, 1, searchQuery);
                }
            };

            var searchBox = Textbox.new(me.contentGroup, 10, 100, 400);
            searchBox.onStartEntry = func { self.showKeyboard(func (key) { self.rootWidget.key(key); }); return 0; };
            searchBox.onEndEntry = func { self.hideKeyboard(); return 0; };
            searchBox.onConfirm = doSearch;
            me.rootWidget.appendChild(searchBox);

            var searchButton = Button.new(me.contentGroup, "Search", 414, 100, 90, 28);
            searchButton.setClickHandler(func {
                self.hideKeyboard();
                doSearch(searchBox.text);
                return 0;
            });
            me.rootWidget.appendChild(searchButton);
        }

        me.pager = Pager.new(me.contentGroup, 1);
        me.rootWidget.appendChild(me.pager);
        me.pager.setCurrentPage(me.currentPage);
        me.pager.setNumPages(me.numPages);
        me.pager.pageChanged.addListener(func (data) {
            self.currentPage = data.page;
            self.reloadListing(); # this deletes and recreates the pager
        });

        var x = 0;
        var y = 32;
        var title = me.currentTitle;
        var alignment = 'left-top';
        var titleX = 8;
        if (size(title) > 32) {
            title = '…' ~ utf8.substr(title, utf8.size(title) - 31, 31);
            alignment = 'right-top';
            titleX = 512 - 8;
        }
        me.contentGroup.createChild('text')
            .setText(title)
            .setColor(0, 0, 0)
            .setAlignment(alignment)
            .setTranslation(titleX, y + 8)
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setFontSize(32);
        y += 64;

        y += 30; # make room for search bar

        y += 16;
        var iconNames = {
            'dir': 'folder.png',
            'pdf': 'chart.png',
            'home': 'home.png',
            'favorites': 'star.png',
            'up': 'up.png',
        };
        var entries = [
                {
                    type: 'home',
                    name: 'Home',
                },
                {
                    type: 'favorites',
                    name: 'Favorites',
                },
            ];
        while (size(entries) < perRow) {
            append(entries, nil);
        }
        foreach (var entry; actualEntries) {
            append(entries, entry);
        }
        foreach (var entry; entries) {
            (func (entry) {
                if (entry == nil) return;
                var iconName = iconNames[entry.type];
                var icon = me.contentGroup.createChild('image')
                    .set('src', acdir ~ '/Models/EFB/icons/' ~ iconName)
                    .setTranslation(x + hSpacing / 2 - 32, y);
                var labelLines = lineSplitStr(entry.name, 14);
                var label1 = (size(labelLines) > 0) ? labelLines[0] : "---";
                var label2 = (size(labelLines) > 1) ? labelLines[1] : "";
                var label3 = (size(labelLines) > 2) ? labelLines[size(labelLines) - 1] : "";
                if (utf8.size(label1) > 14) { label1 = utf8.substr(label1, 0, 13) ~ '…'; }
                if ((utf8.size(label2) > 14)) { label2 = utf8.substr(label2, 0, 13) ~ '…'; }
                if (utf8.size(label3) > 14) { label3 = '…' ~ utf8.substr(label3, utf8.size(label3) - 13, 13); }
                me.contentGroup.createChild('text')
                    .setText(label1)
                    .setColor(0, 0, 0)
                    .setAlignment('center-top')
                    .setTranslation(x + hSpacing / 2, y + 72)
                    .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                    .setFontSize(16);
                me.contentGroup.createChild('text')
                    .setText(label2)
                    .setColor(0, 0, 0)
                    .setAlignment('center-top')
                    .setTranslation(x + hSpacing / 2, y + 72 + 22)
                    .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                    .setFontSize(16);
                me.contentGroup.createChild('text')
                    .setText(label3)
                    .setColor(0, 0, 0)
                    .setAlignment('center-top')
                    .setTranslation(x + hSpacing / 2, y + 72 + 44)
                    .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                    .setFontSize(16);
                var what = nil;
                if (entry.type == 'home') {
                    what = func () { self.goHome(); return 0; };
                }
                else if (entry.type == 'favorites') {
                    what = func () { self.loadFavorites(); return 0; };
                }
                else if (entry.type == 'dir') {
                    what = func () { self.loadListing(entry.path, entry.name, 0, 1); return 0; };
                }
                else {
                    what = func () { self.loadChart(entry.path, entry['meta'], entry.name, 0, 1); return 0; };
                }
                me.makeClickable([ x, y, x + hSpacing, y + lineHeight ], what, self.rootWidget);
            })(entry);
            x += hSpacing;
            if (x > 512 - hSpacing) {
                x = 0;
                y += lineHeight;
            }
        }
        me.makeReloadIcon(func () { self.reloadListing(); }, 'Refresh');
    },

    makeReloadIcon: func (what) {
        var refreshIcon = me.contentGroup.createChild('image')
                .set('src', acdir ~ '/Models/EFB/icons/reload.png')
                .setScale(0.5, 0.5)
                .setTranslation(512 - 32, 32);
        me.makeClickable([512 - 32, 32, 512, 64], what);
    },

    makeFavoriteIcon: func (type, path, title, meta) {
        var self = me;
        var img = me.contentGroup.createChild('image')
                .setScale(0.5, 0.5)
                .setTranslation(512 - 32, 32);
        var starOnIcon = acdir ~ '/Models/EFB/icons/star.png';
        var starOffIcon = acdir ~ '/Models/EFB/icons/staroff.png';

        if (me.isFavorite(path)) {
            img.set('src', starOnIcon);
        }
        else {
            img.set('src', starOffIcon);
        }

        var what = func () {
            if (self.isFavorite(path)) {
                self.removeFromFavorites(path);
                img.set('src', starOffIcon);
            }
            else {
                self.addToFavorites(type, path, title, meta);
                img.set('src', starOnIcon);
            }
            return 0;
        };
        me.makeClickable([512 - 32, 32, 512, 64], what);
    },

    rotate: func (rotationNorm, hard=0) {
        call(BaseApp.rotate, [rotationNorm, hard], me);
        me.rotation = rotationNorm;
    },

    getZoom: func {
        return math.pow(2.0, me.zoomLevel);
    },

    updateAircraftMarker: func () {
        if (me.aircraftMarker == nil) {
            # Not in a chart view
            return;
        }

        if (me.geoRefs == nil) {
            # no georef data entirely
            me.aircraftMarker.hide();
            return;
        }
        var index = (me.currentPage + 1) ~ '';
        var geoRef = me.geoRefs[index];
        # debug.dump(geoRef, me.geoRefs);
        if (geoRef == nil) {
            # no georef data for this page
            # debug.dump(me.geoRefs, index);
            me.aircraftMarker.hide();
            return;
        }
        (var x, var y) = geoMap(geoRef,
                            getprop('/position/latitude-deg'),
                            getprop('/position/longitude-deg'));
        var dx = x * me.imgDimensions[1];
        var dy = y * me.imgDimensions[1];

        debug.dump(me.imgDimensions);

        if (me.centerOnAircraft) {
            me.sx = dx - me.imgDimensions[0] * 0.5;
            me.sy = dy - me.imgDimensions[1] * 0.5;
        }

        me.aircraftMarker
            .setTranslation(
                256 - (me.imgDimensions[0] * 0.5 + me.sx - dx) * me.getZoom(),
                384 - (me.imgDimensions[1] * 0.5 + me.sy - dy) * me.getZoom())
            .setRotation(getprop('/orientation/heading-deg') * D2R + geoRef.ta)
            .show();
    },

    updateScroll: func () {
        if (me.img == nil)
            return;
        me.zoomScroll.setAutoCenter(me.centerOnAircraft);
        me.updateAircraftMarker();
        me.img.setTranslation(
            256 - (me.imgDimensions[0] * 0.5 + me.sx) * me.getZoom(),
            384 - (me.imgDimensions[1] * 0.5 + me.sy) * me.getZoom());
    },

    updateZoom: func () {
        var zoom = me.getZoom();
        if (me.img != nil)
            me.img.setScale(zoom, zoom);
        if (me.zoomScroll != nil)
            me.zoomScroll.setZoom(zoom);
        me.updateScroll();
    },


    makeZoomScrollOverlay: func () {
        var self = me;

        me.zoomScroll = ZoomScroll.new(me.contentGroup, 1);
        me.zoomScroll.rotate(me.rotation, 1);
        me.zoomScroll.setZoom(me.getZoom());
        me.zoomScroll.setAutoCenter(me.centerOnAircraft);
        me.zoomScroll.setZoomFormat(
            func (zoom) {
                return sprintf("%i", 100 * zoom);
            },
            func () "%"
        );

        me.zoomScroll.onScroll.addListener(func (data) {
            if (me.rotation) {
                self.sx += data.y * 16;
                self.sy -= data.x * 16;
            }
            else {
                self.sx += data.x * 16;
                self.sy += data.y * 16;
            }
            me.centerOnAircraft = 0;
            self.updateScroll();
        });
        me.zoomScroll.onZoom.addListener(func (data) {
            self.zoomLevel += data.amount * 0.25;
            self.zoomScroll.setZoom(me.getZoom());
            self.updateZoom();
        });
        me.zoomScroll.onReset.addListener(func {
            self.sx = 0.0;
            self.sy = 0.0;
            me.centerOnAircraft = !me.centerOnAircraft;
            self.updateScroll();
        });

        me.rootWidget.appendChild(me.zoomScroll);

        me.updateZoom();
    },

    loadChart: func (path, metaPath, title, page, pushHistory = 1) {
        var self = me;
        if (metaPath == nil) {
            me.numPages = nil;
            me.searchPath = nil;
            me.geoRefs = nil;
            me.aspectRatio = 1.0;
            me.loadChartRaw(path, metaPath, title, page, pushHistory);
        }
        else {
            me.loadMeta(metaPath, page, func (numPages, geoRefs, aspectRatio) {
                self.numPages = numPages;
                self.searchPath = nil;
                self.geoRefs = geoRefs;
                self.aspectRatio = aspectRatio;
                self.loadChartRaw(path, metaPath, title, page, pushHistory);
            });
        }
    },

    loadChartRaw: func (path, metaPath, title, page, pushHistory = 1) {
        var self = me;
        var chartfoxToken = me.chartfoxTokenProp.getValue() or '';
        var url = me.baseURL ~ urlencode(path) ~ "?p=" ~ page ~ "&chartfoxToken=" ~ chartfoxToken;
        logprint(1, 'EFB loadChart:', url);

        # In case we're already downloading a page: cancel the download.
        if (me.currentPageURL != nil) {
            downloadManager.cancel(me.currentPageURL);
        }
        me.currentPageURL = url;

        me.contentGroup.removeAllChildren();
        me.showLoadingScreen(url);
        if (pushHistory)
            append(me.history, [me.currentPath, me.currentTitle, me.currentPage, me.currentQuery]);
        me.currentPath = path;
        me.currentTitle = title;
        me.currentPage = page;

        downloadManager.get(url, '/efb-charts/' ~ md5(path ~ '$' ~ page) ~ '.jpg',
            func (path) {
                me.contentGroup.removeAllChildren();
                var imageGroup = me.contentGroup.createChild('group');

                me.aircraftMarker = imageGroup.createChild('path')
                                                   .moveTo(0, -10)
                                                   .lineTo(8, 10)
                                                   .lineTo(0, 5)
                                                   .lineTo(-8, 10)
                                                   .close()
                                                   .setColor(0, 0, 0)
                                                   .setColorFill(1, 0, 0)
                                                   .set('z-index', 1);
                # me.aircraftMarker = imageGroup.createChild('path')
                #                                    .circle(4, 0, 0)
                #                                    .setColor(1, 0, 0)
                #                                    .set('z-index', 1);

                var makePager = func {
                    self.pager = Pager.new(self.contentGroup, 1);
                    self.pager.rotate(me.rotation, 1);
                    self.rootWidget.appendChild(self.pager);
                    self.pager.setCurrentPage(self.currentPage);
                    self.pager.setNumPages(self.numPages);
                    self.pager.pageChanged.addListener(func (data) {
                        self.currentPage = data.page;
                        self.loadChart(self.currentPath, metaPath, self.currentTitle, data.page, 0); # this will remove the pager
                    });
                };

                makePager();

                var w = 768;
                var h = 768;
                if (self.aspectRatio > 1.0)
                    h /= self.aspectRatio;
                else
                    w *= self.aspectRatio;
                self.imgDimensions = [w, h];
                self.img = imageGroup.createChild('image')
                    .set('size[0]', w)
                    .set('size[1]', h)
                    .set('src', path);
                self.img.setTranslation(
                    256 - w * 0.5,
                    384 - h * 0.5);
                self.makeFavoriteIcon('pdf', self.currentPath, self.currentTitle, metaPath);
                self.makeZoomScrollOverlay();
                if (self.geoRefs != nil) {
                    self.aircraftMarkerTimer.start();
                }
            },
            func (r) {
                self.showErrorScreen([
                    sprintf('Failed to load PDF page %i', page + 1),
                    r.reason
                ]);
                makePager();
            }
        );
    },

    goHome: func () {
        me.history = [];
        me.loadListing("", "Flight Bag", 0, 0);
    },

    reloadListing: func () {
        me.loadListing(me.currentPath, me.currentTitle, me.currentPage, 0, me.currentQuery);
    },

    addToFavorites: func (type, path, title, meta) {
        append(me.favorites,
            {
                type: type,
                path: path,
                name: title,
                meta: meta,
            });
    },

    removeFromFavorites: func (path) {
        var newFavorites = [];
        foreach (var favorite; me.favorites) {
            if (favorite.path != path) {
                append(newFavorites, favorite);
            }
        }
        me.favorites = newFavorites;
    },

    isFavorite: func (path) {
        foreach (var favorite; me.favorites) {
            if (favorite.path == path) {
                return 1;
            }
        }
        return 0;
    },

    loadFavorites: func (page = 0, pushHistory = 1) {
        var path = "*FAVS*";
        var perPage = 12;
        me.showLoadingScreen('Favorites');
        if (pushHistory and path != me.currentPath)
            append(me.history, [me.currentPath, me.currentTitle, me.currentPage, me.currentQuery]);
        me.currentPath = path;
        me.currentTitle = 'Favorites';
        me.currentPage = page;
        me.pager.setCurrentPage(page);
        me.currentListing = subvec(me.favorites, perPage * page, perPage);
        me.numPages = math.ceil(size(me.favorites) / perPage);
        me.searchPath = nil;
        me.showListing();
    },

    loadMeta: func (metaPath, page, then) {
        var self = me;
        var chartfoxToken = me.chartfoxTokenProp.getValue() or '';
        var queryString = 'chartfoxToken=' ~ urlencode(chartfoxToken);
        var url = me.baseURL ~ urlencode(metaPath) ~ '?' ~ queryString;

        # In case we're already downloading page metadata: cancel the download.
        if (me.currentPageMetaURL != nil) {
            downloadManager.cancel(me.currentPageMetaURL);
        }
        me.currentPageMetaURL = url;

        var metaKey = md5(metaPath);
        downloadManager.get(url, '/efb-charts/' ~ metaKey ~ '.xml',
            func (xmlFilename) {
                var err = [];
                var xmlDocument = call(io.readxml, [xmlFilename], io, {}, err);
                if (size(err)) {
                    debug.printerror(err);
                    then(nil, nil, 1.0);
                }
                elsif (xmlDocument == nil) {
                    logprint(4, "EFB: Malformed XML document.");
                }
                else {
                    var metaNode = xmlDocument.getNode('/meta');
                    if (metaNode == nil) {
                        logprint(4, "EFB: XML error: no <meta> found.");
                        then(nil, nil, 1.0);
                        return;
                    }
                    var properties = {};
                    foreach (var propNode; xmlDocument.getNode('/meta').getChildren('property')) {
                        var key = propNode.getValue('___name');
                        var val = propNode.getValue('___value');
                        properties[key] = val;
                        printf("%s: %s", key, val);
                    }
                    var numPages = properties['Pages'];
                    var geoRefs = {};
                    var pageRot = properties['Page rot'];
                    var origSizeStr = properties['Page size'];
                    var origSizeParts = split(' ', origSizeStr);
                    var origWidth = origSizeParts[0];
                    var origHeight = origSizeParts[2];
                    var aspectRatio = (pageRot == 90 or pageRot == 270) ? (origHeight / origWidth) : (origWidth / origHeight);
                    printf("Aspect: %f x %f (%f:1)", origWidth, origHeight, aspectRatio);
                    foreach (var propNode; xmlDocument.getNode('/meta').getChildren('georef')) {
                        var geoRef = {
                            'tx': propNode.getValue('tx'),
                            'ty': propNode.getValue('ty'),
                            'k': propNode.getValue('k'),
                            'ta': propNode.getValue('ta'),
                            'pageRotation': propNode.getValue('pageRotation'),
                        };
                        var refPage = propNode.getValue('page');
                        geoRefs[refPage] = geoRef;
                    }
                    then(numPages, geoRefs, aspectRatio);
                }
            },
            func (r) {
                if (r.status >= 300) {
                    # Not-found, client error, or server error: carry on
                    # without metadata. Most likely this means the companion
                    # server doesn't serve metadata yet.
                    then(nil, nil, 1.0);
                }
            });
    },

    loadListing: func (path, title, page, pushHistory = 1, searchQuery = nil) {
        if (path == '*FAVS*') {
            return me.loadFavorites(page, pushHistory);
        }
        var self = me;
        var chartfoxToken = me.chartfoxTokenProp.getValue() or '';
        var queryString = 'chartfoxToken=' ~ urlencode(chartfoxToken) ~ '&p=' ~ page;
        if (searchQuery != nil) {
            queryString = queryString ~ '&q=' ~ urlencode(searchQuery);
        }
        var url = me.baseURL ~ urlencode(path) ~ '?' ~ queryString;
        debug.dump(url);
        me.showLoadingScreen(url);
        if (pushHistory and path != me.currentPath) append(me.history, [me.currentPath, me.currentTitle, me.currentPage, me.currentQuery]);
        me.currentPath = path;
        me.currentTitle = title;
        me.currentPage = page;
        me.currentQuery = searchQuery;

        var filename = getprop('/sim/fg-home') ~ "/Export/efb_listing.xml";
        var onFailure = func (r) {
            logprint(4, 'EFB: HTTP error:', debug.string(r.status));
            var companionURL = getprop('/instrumentation/efb/flightbag-companion-uri');
            var companionDownloadURL = 'https://github.com/tdammers/fg-efb-server/';
            if (r.status < 100) {
                self.showErrorScreen(
                    [ "Download from"
                    , url
                    , "failed"
                    , sprintf("Error code: %s", r.status)
                    , "Please check the following:"
                    , H.ul(
                        H.li(
                            "Have you installed the ",
                            H.b("fg-efb-server companion app?"),
                        ),
                        H.li(
                            "Is the companion app running on ",
                            H.a({href: companionURL}, companionURL)))
                    , H.h5("Note:")
                    , H.p(
                        "The companion app can be downloaded from here:",
                        H.a({href: companionDownloadURL}, companionDownloadURL))
                    ]);
                self.makeReloadIcon(func () { self.reloadListing(); }, 'Retry');
            }
            else if (r.status > 399) {
                self.showErrorScreen(
                    [ "Download from " ~ url ~ "failed"
                    , sprintf("HTTP status: %s", r.status)
                    ]);
                self.makeReloadIcon(func () { self.reloadListing(); }, 'Retry');
            }
        };
        var onSuccess = func (f) {
            var listingNode = io.readxml(filename);
            if (listingNode == nil) {
                print("Error loading listing");
                self.showErrorScreen(
                    [ "Invalid listing:"
                    , "Malformed XML"
                    ]);
            }
            else {
                listing = self.parseListing(listingNode);
                self.currentListing = listing.files;
                self.page = listing.meta.page;
                self.numPages = listing.meta.numPages;
                self.searchPath = listing.meta.searchPath;
                self.showListing();
            }
        };
        if (me.xhr != nil) {
            me.xhr.abort();
            me.xhr = nil;
        }
        me.xhr = http.save(url, filename)
            .done(func (r) {
                    var errs = [];
                    call(onSuccess, [filename], nil, {}, errs);
                    if (size(errs) > 0) {
                        debug.printerror(errs);
                        self.showErrorScreen(errs);
                    }
                    else {
                    }
                })
            .fail(onFailure)
            .always(func {
            });
        },
};

registerApp('charts', 'Charts', 'flightbag.png', ChartsApp);
