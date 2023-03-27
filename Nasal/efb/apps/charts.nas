include('apps/base.nas');
include('gui/pager.nas');

var ChartsApp = {
    new: func(masterGroup) {
        var m = BaseApp.new(masterGroup);
        m.parents = [me] ~ m.parents;
        m.contentGroup = nil;
        m.currentListing = nil;
        m.currentPage = 0;
        m.numPages = nil;
        m.currentPath = "";
        m.currentTitle = "Charts";
        m.currentPageURL = nil;
        m.currentPageMetaURL = nil;
        m.history = [];
        m.favorites = [];
        m.xhr = nil;
        m.baseURL = 'http://localhost:7675/';
        return m;
    },

    handleBack: func () {
        var popped = pop(me.history);
        if (popped != nil) {
            if (popped[0] == "*FAVS*")
                me.loadFavorites(popped[2], 0);
            else
                me.loadListing(popped[0], popped[1], popped[2], 0);
        }
    },

    initialize: func () {
        me.baseURL = getprop('/instrumentation/efb/flightbag-companion-uri') or 'http://localhost:7675/';
        me.bgfill = me.masterGroup.createChild('path')
                        .rect(0, 0, 512, 768)
                        .setColorFill(128, 128, 128);
        me.bglogo = me.masterGroup.createChild('image')
                        .set('src', 'Aircraft/E-jet-family/Models/EFB/icons/flightbag-large.png')
                        .setTranslation(256 - 128, 384 - 128);
        me.bgfog = me.masterGroup.createChild('path')
                        .rect(0, 0, 512, 768)
                        .setColorFill(255, 255, 255, 0.8);
        me.contentGroup = me.masterGroup.createChild('group');

        me.loadListing("", "Charts", 0, 0);
    },

    showLoadingScreen: func (url=nil) {
        me.rootWidget.removeAllChildren();
        me.contentGroup.removeAllChildren();
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
        me.rootWidget.removeAllChildren();
        me.contentGroup.removeAllChildren();
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

    showErrorScreen: func (errs, clearExisting=1) {
        if (clearExisting) {
            me.rootWidget.removeAllChildren();
            me.contentGroup.removeAllChildren();
        }
        var y = 64;
        me.contentGroup.createChild('text')
            .setText('Error')
            .setColor(128, 0, 0)
            .setAlignment('center-center')
            .setTranslation(256, y)
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setFontSize(48);
        y += 64;
        foreach (var err; errs) {
            me.contentGroup.createChild('text')
                .setText(err)
                .setColor(128, 0, 0)
                .setAlignment('center-center')
                .setTranslation(256, y)
                .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                .setFontSize(24);
            y += 32;
        }
    },

    parseListing: func (listingNode) {
        var currentListing = [];
        foreach (var n; listingNode.getNode('listing').getChildren()) {
            var entry = {
                    'path': n.getChild('path').getValue(),
                    'name': n.getChild('name').getValue(),
                };
            if (n.getName() == 'directory') {
                entry.type = 'dir';
            }
            else {
                var typeNode = n.getChild('type');
                entry.type = typeNode.getValue();
                var metaNode = n.getChild('meta');
                if (metaNode == nil)
                    entry.meta = nil;
                else
                    entry.meta = metaNode.getValue();
            }
            append(currentListing, entry);
        }
        return currentListing;
    },

    showListing: func () {
        var self = me;
        var lineHeight = 144;
        var hSpacing = 128;
        var perRow = math.floor(512 / hSpacing);
        var perColumn = math.floor((768 - 192) / lineHeight);
        var perPage = perRow * (perColumn - 1);
        var actualEntries = subvec(me.currentListing, me.currentPage * perPage, perPage);
        me.numPages = math.ceil(size(me.currentListing) / perPage);
        me.contentGroup.removeAllChildren();
        me.rootWidget.removeAllChildren();
        me.pager = Pager.new(me.contentGroup);
        me.rootWidget.appendChild(me.pager);
        me.pager.setCurrentPage(me.currentPage);
        me.pager.setNumPages(me.numPages);
        me.pager.pageChanged.addListener(func (data) {
            self.currentPage = data.page;
            self.showListing(); # this deletes and recreates the pager
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
                    .set('src', 'Aircraft/E-jet-family/Models/EFB/icons/' ~ iconName)
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
                    what = func () { self.goHome(); };
                }
                else if (entry.type == 'favorites') {
                    what = func () { self.loadFavorites(); };
                }
                else if (entry.type == 'dir') {
                    what = func () { self.loadListing(entry.path, entry.name, 0, 1); };
                }
                else {
                    what = func () { self.loadChart(entry.path, entry['meta'], entry.name, 0, 1); };
                }
                me.makeClickable([ x, y, x + hSpacing, y + lineHeight ], what);
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
                .set('src', 'Aircraft/E-jet-family/Models/EFB/icons/reload.png')
                .setScale(0.5, 0.5)
                .setTranslation(512 - 32, 32);
        me.makeClickable([512 - 32, 32, 512, 64], what);
    },

    makeFavoriteIcon: func (type, path, title) {
        var self = me;
        var what = nil;
        var img = me.contentGroup.createChild('image')
                .setScale(0.5, 0.5)
                .setTranslation(512 - 32, 32);
        var starOnIcon = 'Aircraft/E-jet-family/Models/EFB/icons/star.png';
        var starOffIcon = 'Aircraft/E-jet-family/Models/EFB/icons/staroff.png';
        if (me.isFavorite(path)) {
            img.set('src', starOnIcon);
            what = func () {
                self.removeFromFavorites(path);
                img.set('src', starOffIcon);
            };
        }
        else {
            img.set('src', starOffIcon);
            what = func () {
                self.addToFavorites(type, path, title);
                img.set('src', starOnIcon);
            };
        }
        me.makeClickable([512 - 32, 32, 512, 64], what);
    },

    makeZoomScrollOverlay: func (img) {
        var overlay = me.contentGroup.createChild('group');
        canvas.parsesvg(overlay, "Aircraft/E-jet-family/Models/EFB/zoom-scroll-overlay.svg", {'font-mapper': font_mapper});
        # We will not use the auto-center marker
        overlay.getElementById('autoCenterMarker').hide();
        var zoomDigital = overlay.getElementById('zoomPercent.digital');
        var zoom = 1.0;
        var sx = 0.0;
        var sy = 0.0;
        var update = func () {
            img.setScale(zoom, zoom);
            img.setTranslation(
                256 - (384 + sx) * zoom,
                384 - (384 + sy) * zoom);
            zoomDigital.setText(sprintf("%1.0f", zoom * 100));
        };
        var zoomIn = func () { zoom = zoom * math.sqrt(2.0); update(); };
        var zoomOut = func () { zoom = zoom / math.sqrt(2.0); update(); };
        var scroll = func (dx, dy) { sx = sx + dx; sy = sy + dy; update(); };
        var resetScroll = func () { sx = 0.0; sy = 0.0; update(); };
        me.makeClickable(overlay.getElementById('btnZoomIn'), zoomIn);
        me.makeClickable(overlay.getElementById('btnZoomOut'), zoomOut);
        me.makeClickable(overlay.getElementById('btnScrollN'), func { scroll(0, -16); });
        me.makeClickable(overlay.getElementById('btnScrollS'), func { scroll(0, 16); });
        me.makeClickable(overlay.getElementById('btnScrollE'), func { scroll(16, 0); });
        me.makeClickable(overlay.getElementById('btnScrollW'), func { scroll(-16, 0); });
        me.makeClickable(overlay.getElementById('btnScrollReset'), resetScroll);
        update();
    },

    loadChart: func (path, metaPath, title, page, pushHistory = 1) {
        var self = me;
        if (metaPath == nil) {
            me.numPages = nil;
            me.loadChartRaw(path, title, page, pushHistory);
        }
        else {
            me.loadMeta(metaPath, page, func (numPages) {
                self.numPages = numPages;
                self.loadChartRaw(path, title, page, pushHistory);
            });
        }
    },

    loadChartRaw: func (path, title, page, pushHistory = 1) {
        var self = me;
        var url = me.baseURL ~ urlencode(path) ~ "?p=" ~ page;
        logprint(1, 'EFB loadChart:', url);

        # In case we're already downloading a page: cancel the download.
        if (me.currentPageURL != nil) {
            downloadManager.cancel(me.currentPageURL);
        }
        me.currentPageURL = url;

        me.contentGroup.removeAllChildren();
        me.showLoadingScreen(url);
        if (pushHistory)
            append(me.history, [me.currentPath, me.currentTitle, me.currentPage]);
        me.currentPath = path;
        me.currentTitle = title;
        me.currentPage = page;

        var imageGroup = me.contentGroup.createChild('group');

        var makePager = func {
            self.pager = Pager.new(self.contentGroup);
            self.rootWidget.appendChild(self.pager);
            self.pager.setCurrentPage(self.currentPage);
            self.pager.setNumPages(self.numPages);
            self.pager.pageChanged.addListener(func (data) {
                self.currentPage = data.page;
                self.loadChartRaw(self.currentPath, self.currentTitle, data.page, 0); # this will remove the pager
            });
        };

        makePager();

        downloadManager.get(url, '/efb-charts/' ~ md5(path ~ '$' ~ page) ~ '.jpg',
            func (path) {
                var img = imageGroup.createChild('image')
                    .set('size[0]', 768)
                    .set('size[1]', 768)
                    .set('src', path);
                img.setTranslation(
                    256 - 384,
                    384 - 384);
                me.makeFavoriteIcon('pdf', me.currentPath, me.currentTitle);
                me.makeZoomScrollOverlay(img);
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
        me.loadListing(me.currentPath, me.currentTitle, me.currentPage, 0);
    },

    addToFavorites: func (type, path, title) {
        append(me.favorites,
            {
                type: type,
                path: path,
                name: title
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
        me.showLoadingScreen('Favorites');
        if (pushHistory and path != me.currentPath) append(me.history, [me.currentPath, me.currentTitle, me.currentPage]);
        me.currentPath = path;
        me.currentTitle = 'Favorites';
        me.currentPage = page;
        me.pager.setCurrentPage(page);
        me.currentListing = me.favorites;
        me.showListing();
    },

    loadMeta: func (metaPath, page, then) {
        var self = me;
        var url = me.baseURL ~ urlencode(metaPath);

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
                    then(nil);
                }
                else {
                    var properties = {};
                    foreach (var propNode; xmlDocument.getNode('/meta').getChildren('property')) {
                        var key = propNode.getValue('___name');
                        var val = propNode.getValue('___value');
                        properties[key] = val;
                    }
                    var numPages = properties['Pages'];
                    then(numPages);
                }
            },
            func (r) {
                if (r.status >= 300) {
                    # Not-found, client error, or server error: carry on
                    # without page count. Most likely this means the companion
                    # server doesn't serve metadata yet.
                    then(nil);
                }
            });
    },

    loadListing: func (path, title, page, pushHistory = 1) {
        var self = me;
        var url = me.baseURL ~ urlencode(path);
        me.showLoadingScreen(url);
        if (pushHistory and path != me.currentPath) append(me.history, [me.currentPath, me.currentTitle, me.currentPage]);
        me.currentPath = path;
        me.currentTitle = title;
        me.currentPage = page;

        var filename = getprop('/sim/fg-home') ~ "/Export/efb_listing.xml";
        var onFailure = func (r) {
            logprint(4, 'EFB: HTTP error:', debug.string(r.status));
            if (r.status < 100) {
                self.showErrorScreen(
                    [ "Download failed"
                    , url
                    , sprintf("Error code: %s", r.status)
                    , "Is the companion app running"
                    , "on the following URL?"
                    , getprop('/instrumentation/efb/charts-companion-uri')
                    ]);
                self.makeReloadIcon(func () { self.reloadListing(); }, 'Retry');
            }
            else if (r.status > 399) {
                self.showErrorScreen(
                    [ "Download failed"
                    , url
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
                    [ "Invalid listing"
                    , "Malformed XML"
                    ]);
            }
            else {
                self.currentListing = self.parseListing(listingNode);
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
