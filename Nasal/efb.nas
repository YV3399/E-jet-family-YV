var efbDisplay = nil;
var efbMaster = nil;
var efb = nil;

var urlencode = func (raw) {
    return string.replace(raw, ' ', '%20');
};

var font_mapper = func(family, weight) {
    return "LiberationFonts/LiberationSans-Regular.ttf";
};


var BaseApp = {
    touch: func (x, y) {},
    handleBack: func () {},
    handleMenu: func () {},
    foreground: func () {},
    background: func () {},
    initialize: func () {},
};

var lineSplitStr = func (str, maxLineLen) {
    var words = split(" ", str);
    var lines = [];
    var lineAccum = [];
    var lineLen = 0;
    foreach (var word; words) {
        while ((lineLen == 0) and (utf8.size(word) > maxLineLen)) {
            var w0 = utf8.substr(word, 0, maxLineLen - 1) ~ '…';
            word = '…' ~ utf8.substr(word, maxLineLen - 1);
            append(lines, w0);
            lineLen = 0;
        }
        var wlen = utf8.size(word);
        if (lineLen == 0) {
            newLineLen = wlen;
        }
        else {
            newLineLen = lineLen + wlen + 1;
        }
        if ((lineLen > 0) and (newLineLen > maxLineLen)) {
            append(lines, string.join(" ", lineAccum));
            lineAccum = [word];
            lineLen = wlen;
        }
        else {
            append(lineAccum, word);
            lineLen = newLineLen;
        }
    }
    append(lines, string.join(" ", lineAccum));
    return lines;
}

var FlightbagApp = {
    new: func(masterGroup) {
        var m = {
            parents: [FlightbagApp, BaseApp],
            masterGroup: masterGroup,
            contentGroup: nil,
            currentListing: nil,
            currentPage: 0,
            currentPath: "",
            currentTitle: "Flight Bag",
            history: [],
            clickSpots: [],
            xhr: nil,
        };
        return m;
    },

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
        var popped = pop(me.history);
        if (popped != nil) {
            me.loadListing(popped[0], popped[1], popped[2], 0);
        }
    },

    initialize: func () {
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
        me.loadListing("", "Flight Bag", 0, 0);
    },

    showLoadingScreen: func (url=nil) {
        me.clickSpots = [];
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
        me.clickSpots = [];
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

    showErrorScreen: func (errs) {
        me.clickSpots = [];
        me.contentGroup.removeAllChildren();
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
            }
            append(currentListing, entry);
        }
        return currentListing;
    },

    showListing: func () {
        var self = me;
        var lineHeight = 144;
        var hSpacing = 128;
        var perPage = math.floor((768 - 192) / lineHeight) * math.floor(512 / hSpacing);
        var entries = subvec(me.currentListing, me.currentPage * perPage, perPage);
        var numPages = math.ceil(size(me.currentListing) / perPage);
        me.contentGroup.removeAllChildren();
        me.clickSpots = [];
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
        foreach (var entry; entries) {
            (func (entry) {
                var iconName = (entry.type == 'dir') ? 'folder.png' : 'chart.png';
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
                var subpath = entry.path;
                var what = nil;
                if (entry.type == 'dir') {
                    what = func () { self.loadListing(subpath, entry.name, 0, 1); };
                }
                else {
                    what = func () { self.loadChart(subpath, entry.name, 0, 1); };
                }
                append(me.clickSpots, {
                    where: [ x, y, x + hSpacing, y + lineHeight ],
                    what: what,
                });
            })(entry);
            x += hSpacing;
            if (x > 512 - hSpacing) {
                x = 0;
                y += lineHeight;
            }
        }
        self.makeReloadIcon(func () { self.reloadListing(); }, 'Refresh');
        self.makePager(numPages, func () { self.showListing(); });
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

    makeReloadIcon: func (what) {
        var refreshIcon = me.contentGroup.createChild('image')
                .set('src', 'Aircraft/E-jet-family/Models/EFB/icons/reload.png')
                .setScale(0.5, 0.5)
                .setTranslation(512 - 32, 32);
        me.makeClickableArea([512 - 32, 32, 512, 64], what);
    },

    makePager: func (numPages, what) {
        if (numPages != nil and numPages < 2) return;
        var pager = me.contentGroup.createChild('group');
        canvas.parsesvg(pager, "Aircraft/E-jet-family/Models/EFB/pager-overlay.svg", {'font-mapper': font_mapper});
        var btnPgUp = pager.getElementById('btnPgUp');
        var btnPgDn = pager.getElementById('btnPgDn');
        var self = me;
        if (me.currentPage > 0) {
            me.makeClickable(btnPgUp, func () { self.currentPage = self.currentPage - 1; what(); });
        }
        var currentPageIndicator = pager.getElementById('pager.digital');
        currentPageIndicator
                .setText(
                    (numPages == nil)
                        ? sprintf("%i", me.currentPage + 1)
                        : sprintf("%i/%i", me.currentPage + 1, numPages)
                 );
        if (numPages == nil or me.currentPage < numPages - 1) {
            me.makeClickable(btnPgDn, func () { self.currentPage = self.currentPage + 1; what(); });
        }
    },

    makeZoomScrollOverlay: func (img) {
        var overlay = me.contentGroup.createChild('group');
        canvas.parsesvg(overlay, "Aircraft/E-jet-family/Models/EFB/zoom-scroll-overlay.svg", {'font-mapper': font_mapper});
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

    loadChart: func (path, title, page, pushHistory = 1) {
        var self = me;
        var url = getprop('/instrumentation/efb/flightbag-companion-uri') ~ urlencode(path) ~ "?p=" ~ page;
        debug.dump(url);
        me.showLoadingScreen(url);
        me.contentGroup.removeAllChildren();
        if (pushHistory) append(me.history, [me.currentPath, me.currentTitle, me.currentPage]);
        me.currentPath = path;
        me.currentTitle = title;
        me.currentPage = page;
        var img = me.contentGroup.createChild('image')
            .set('size[0]', 768)
            .set('size[1]', 768)
            .set('src', url);
        img.setTranslation(
            256 - 384,
            384 - 384);
        me.makePager(nil, func () {
            self.loadChart(self.currentPath, self.currentTitle, self.currentPage, 0);
        });
        self.makeReloadIcon(func () {
            self.loadChart(self.currentPath, self.currentTitle, self.currentPage, 0);
        });
        self.makeZoomScrollOverlay(img);
    },

    reloadListing: func () {
        me.loadListing(me.currentPath, me.currentTitle, me.currentPage, 0);
    },

    loadListing: func (path, title, page, pushHistory = 1) {
        var self = me;
        var url = getprop('/instrumentation/efb/flightbag-companion-uri') ~ urlencode(path);
        me.showLoadingScreen(url);
        if (pushHistory) append(me.history, [me.currentPath, me.currentTitle, me.currentPage]);
        me.currentPath = path;
        me.currentTitle = title;
        me.currentPage = page;
        var filename = getprop('/sim/fg-home') ~ "/Export/efb_listing.xml";
        var onFailure = func (r) {
            self.showErrorScreen(
                [ "Download failed"
                , url
                , sprintf("HTTP status: %s", r.status)
                ]);
            self.makeReloadIcon(func () { self.reloadListing(); }, 'Retry');
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

var flightbagApp = func (masterGroup) {
    return FlightbagApp.new(masterGroup);
};

var EFB = {
    new: func (master) {
        var m = {
            parents: [EFB],
            master: master,
        };
        m.currentApp = nil;
        m.shellPage = 0;
        m.shellNumPages = 1;
        m.appInfos =
            [
                {
                    icon: 'Aircraft/E-jet-family/Models/EFB/icons/flightbag.png',
                    label: 'FlightBag',
                    loader: flightbagApp,
                    masterGroup: nil,
                },
            ];
        m.initialize();
        return m;
    },

    initialize: func() {
        me.shellGroup = me.master.createChild('group');
        me.shellPages = [];
        me.background = me.shellGroup.createChild('image');
        me.background.set('src', "Aircraft/E-jet-family/Models/EFB/efb.png");

        me.clientGroup = me.master.createChild('group');

        me.overlay = canvas.parsesvg(me.master, "Aircraft/E-jet-family/Models/EFB/overlay.svg", {'font-mapper': font_mapper});
        me.clockElem = me.master.getElementById('clock.digital');
        me.shellNumPages = math.ceil(size(me.appInfos) / 20);
        for (var i = 0; i < me.shellNumPages; i += 1) {
            var pageGroup = me.shellGroup.createChild('group');
            append(me.shellPages, pageGroup);
        }
        var row = 0;
        var col = 0;
        var page = 0;
        foreach (var app; me.appInfos) {
            app.row = row;
            app.col = col;
            app.page = page;
            app.app = nil;
            col = col + 1;
            if (col > 3) {
                col = 0;
                row = row + 1;
                if (row > 4) {
                    row = 0;
                    page = page + 1;
                }
            }
            app.shellIcon = me.shellPages[page].createChild('group');
            app.shellIcon.setTranslation(app.col * 128, app.row * 141 + 64);
            app.box = [
                app.col * 128, app.row * 141 + 64,
                app.col * 128 + 128, app.row * 141 + 64 + 86,
            ];
            var img = app.shellIcon.createChild('image');
            img.set('src', app.icon);
            img.setTranslation((170 - 64) / 2, 0);
            var txt = app.shellIcon.createChild('text');
            txt.setText(app.label);
            txt.setColor(0, 0, 0);
            txt.setAlignment('center-top');
            txt.setTranslation(85, 70);
            txt.setFont("LiberationFonts/LiberationSans-Regular.ttf");
            txt.setFontSize(24);
        }
        var self = me;
        setlistener('/instrumentation/clock/local-short-string', func(node) {
            self.clockElem.setText(node.getValue());
        }, 0, 1);
    },

    touch: func (args) {
        var x = math.floor(args.x * 512);
        var y = math.floor(768 - args.y * 768);
        if (y >= 736) {
            if (x < 171) {
                me.handleBack();
            }
            else if (x < 342) {
                me.handleHome();
            }
            else {
                me.handleMenu();
            }
        }
        else {
            # Shell: find icon
            if (me.currentApp == nil) {
                foreach (var appInfo; me.appInfos) {
                    if ((appInfo.page == me.shellPage) and
                        (x >= appInfo.box[0]) and
                        (y >= appInfo.box[1]) and
                        (x < appInfo.box[2]) and
                        (y < appInfo.box[3])) {
                        me.openApp(appInfo);
                        break;
                    }
                }
            }
            else {
                me.currentApp.touch(x, y);
            }
        }
    },

    hideCurrentApp: func () {
        if (me.currentApp != nil) {
            me.currentApp.background();
            me.currentApp.masterGroup.hide();
            me.currentApp = nil;
        }
    },

    openShell: func () {
        me.hideCurrentApp();
        me.shellGroup.show();
    },

    openApp: func (appInfo) {
        me.hideCurrentApp();
        me.shellGroup.hide();
        if (appInfo.app == nil) {
            var masterGroup = me.clientGroup.createChild('group');
            appInfo.app = appInfo.loader(masterGroup);
            appInfo.app.initialize();
        }
        me.currentApp = appInfo.app;
        me.currentApp.masterGroup.show();
        me.currentApp.foreground();
    },

    handleMenu: func () {
        if (me.currentApp != nil) {
            me.currentApp.handleMenu();
        }
        else {
            # next shell page
        }
    },

    handleBack: func () {
        if (me.currentApp != nil) {
            me.currentApp.handleBack();
        }
        else {
            # previous shell page
        }
    },

    handleHome: func () {
        if (me.currentApp != nil) {
            me.openShell();
        }
    },
};

setlistener("sim/signals/fdm-initialized", func {
    efbDisplay = canvas.new({
        "name": "EFB",
        "size": [1024, 1536],
        "view": [512, 768],
        "mipmapping": 1
    });
    efbDisplay.addPlacement({"node": "EFBScreen"});
    efbMaster = efbDisplay.createGroup();
    efb = EFB.new(efbMaster);
});
