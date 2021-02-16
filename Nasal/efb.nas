var efbDisplay = nil;
var efbMaster = nil;
var efb = nil;

var urlencode = func (raw) {
    return string.replace(raw, ' ', '%20');
};

var BaseApp = {
    touch: func (x, y) {},
    handleBack: func () {},
    handleMenu: func () {},
    foreground: func () {},
    background: func () {},
    initialize: func () {},
};

var FlightbagApp = {
    new: func(masterGroup) {
        var m = {
            parents: [FlightbagApp, BaseApp],
            masterGroup: masterGroup,
            contentGroup: nil,
            currentListing: nil,
            currentPage: 0,
            currentPath: "",
            history: [],
            numPages: 0,
            clickSpots: [],
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
            me.loadListing(popped, 0);
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
                        .setColorFill(255, 255, 255, 0.5);
        me.contentGroup = me.masterGroup.createChild('group');
        me.loadListing("", 0);
    },

    showLoadingScreen: func (url=nil) {
        me.clickSpots = [];
        me.contentGroup.removeAllChildren();
        me.contentGroup.createChild('text')
            .setText('Loading, please wait...')
            .setColor(0, 0, 0)
            .setAlignment('center-center')
            .setTranslation(256, 384)
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setFontSize(48);
        if (url != nil) {
            me.contentGroup.createChild('text')
                .setText(url)
                .setColor(0, 0, 0)
                .setAlignment('center-center')
                .setTranslation(256, 384 + 64)
                .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                .setFontSize(24);
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
        var lineHeight = 128;
        var hSpacing = 128;
        var perPage = math.floor((768 - 128) / lineHeight) * math.floor(512 / hSpacing);
        var entries = subvec(me.currentListing, me.currentPage * perPage, perPage);
        me.contentGroup.removeAllChildren();
        me.clickSpots = [];
        var x = 0;
        var y = 32;
        var title = (size(me.currentPath) == 0)
                        ? 'Charts'
                        : me.currentPath;
        if (size(title) > 24) {
            title = '...' ~ substr(right(title, 21));
        }
        me.contentGroup.createChild('text')
            .setText(title)
            .setColor(0, 0, 0)
            .setAlignment('left-top')
            .setTranslation(8, y)
            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
            .setFontSize(48);
        y += 64;
        foreach (var entry; entries) {
            (func (entry) {
                var iconName = (entry.type == 'dir') ? 'folder.png' : 'chart.png';
                var icon = me.contentGroup.createChild('image')
                    .set('src', 'Aircraft/E-jet-family/Models/EFB/icons/' ~ iconName)
                    .setTranslation(x + hSpacing / 2 - 32, y);
                var label1 = entry.name;
                var label2 = '';
                if (size(entry.name) > 8) {
                    if (size(entry.name) > 14) {
                        label1 = left(entry.name, 7) ~ '...';
                        label2 = '...' ~ right(entry.name, 7);
                    }
                    else {
                        label1 = left(entry.name, math.ceil(size(entry.name) / 2));
                        label2 = right(entry.name, math.floor(size(entry.name) / 2));
                    }
                }
                me.contentGroup.createChild('text')
                    .setText(label1)
                    .setColor(0, 0, 0)
                    .setAlignment('center-top')
                    .setTranslation(x + hSpacing / 2, y + 72)
                    .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                    .setFontSize(24);
                me.contentGroup.createChild('text')
                    .setText(label2)
                    .setColor(0, 0, 0)
                    .setAlignment('center-top')
                    .setTranslation(x + hSpacing / 2, y + 72 + 32)
                    .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                    .setFontSize(24);
                var subpath = entry.path;
                var what = nil;
                if (entry.type == 'dir') {
                    what = func () { self.loadListing(subpath); };
                }
                else {
                    what = func () { self.loadChart(subpath); };
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
        self.makeReloadIcon(func () { self.loadListing(self.currentPath, 0); }, 'Refresh');
    },

    makeReloadIcon: func (what, text = 'Refresh') {
        var refreshIcon = me.contentGroup.createChild('text')
                .setText(text)
                .setColor(0, 0, 255)
                .setAlignment('center-bottom')
                .setTranslation(256, 768 - 48)
                .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                .setFontSize(24);
        append(me.clickSpots, {
            where: refreshIcon.getTransformedBounds(),
            what: what,
        });
    },

    loadChart: func (path, pushHistory = 1) {
        var self = me;
        var url = 'http://localhost:7675/' ~ urlencode(path);
        me.showLoadingScreen(url);
        me.contentGroup.removeAllChildren();
        if (pushHistory) append(me.history, me.currentPath);
        me.currentPath = path;
        var img = me.contentGroup.createChild('image')
            .set('size[0]', 512)
            .set('size[1]', 768)
            .set('src', url);
    },

    loadListing: func (path, pushHistory = 1) {
        var self = me;
        var url = 'http://localhost:7675/' ~ urlencode(path);
        me.showLoadingScreen(url);
        if (pushHistory) append(me.history, me.currentPath);
        me.currentPath = path;
        var filename = getprop('/sim/fg-home') ~ "/Export/efb_listing.xml";
        var onFailure = func (r) {
            self.showErrorScreen(
                [ "Download failed"
                , url
                , sprintf("HTTP status: %s", r.status)
                ]);
            self.makeReloadIcon(func () { self.loadListing(self.currentPath, 0); }, 'Retry');
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
                self.currentPage = 0;
                self.currentListing = self.parseListing(listingNode);
                self.showListing();
            }
        };
        http.save(url, filename)
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
        var font_mapper = func(family, weight) {
            return "LiberationFonts/LiberationSans-Regular.ttf";
        };

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
