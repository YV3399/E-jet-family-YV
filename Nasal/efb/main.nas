var efb = nil;

logprint(3, "EFB main module start");

var appBasedir = acdir ~ '/Nasal/efb/apps';

globals.efb.availableApps = {};
globals.efb.registerApp = func(key, label, iconName, class) {
    globals.efb.availableApps[key] = {
        key: key,
        icon: acdir ~ '/Models/EFB/icons/' ~ iconName,
        label: label,
        loader: func (g) { return class.new(g); },
    };
};

include('util.nas');
include('downloadManager.nas');

if (contains(globals.efb, 'downloadManager')) {
    var err = [];
    call(globals.efb.downloadManager.cancelAll, [], globals.efb.downloadManager, {}, err);
    if (size(err)) {
        debug.printerror(err);
    }
}
globals.efb.downloadManager = DownloadManager.new();

var appFiles = directory(appBasedir);
foreach (var f; appFiles) {
    if (substr(f, 0, 1) != '.' and substr(f, -4) == '.nas') {
        include('apps/' ~ f);
    }
}

var EFB = {
    new: func (master) {
        var m = {
            parents: [EFB],
            master: master,
        };
        m.currentApp = nil;
        m.shellPage = 0;
        m.shellNumPages = 1;
        m.apps = [];
        foreach (var k; keys(availableApps)) {
            var app = availableApps[k];
            append(m.apps,
                { icon: app.icon,
                , label: app.label,
                , loader: app.loader,
                , key: app.key,
                });
        }
        m.initialize();
        return m;
    },

    initialize: func() {
        me.shellGroup = me.master.createChild('group');
        me.shellPages = [];
        me.background = me.shellGroup.createChild('path')
                            .rect(0, 0, 512, 768)
                            .setColorFill(1, 1, 1);
        me.background = me.shellGroup.createChild('image');
        me.background.set('src', "Aircraft/E-jet-family/Models/EFB/efb.png");

        me.clientGroup = me.master.createChild('group');

        me.overlay = canvas.parsesvg(me.master, "Aircraft/E-jet-family/Models/EFB/overlay.svg", {'font-mapper': font_mapper});
        me.clockElem = me.master.getElementById('clock.digital');
        me.shellNumPages = math.ceil(size(me.apps) / 20);
        for (var i = 0; i < me.shellNumPages; i += 1) {
            var pageGroup = me.shellGroup.createChild('group');
            append(me.shellPages, pageGroup);
        }
        var row = 0;
        var col = 0;
        var page = 0;
        foreach (var app; me.apps) {
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

            # App icon grid:
            # Each app gets a 128x141 square.
            app.shellIcon = me.shellPages[page].createChild('group');
            app.shellIcon.setTranslation(app.col * 128, app.row * 141 + 64);
            app.box = [
                app.col * 128, app.row * 141 + 64,
                app.col * 128 + 128, app.row * 141 + 64 + 86,
            ];
            var img = app.shellIcon.createChild('image');
            img.set('src', app.icon);
            var bbox = img.getBoundingBox();
            var imgW = bbox[2];
            img.setTranslation((64 - imgW) / 2, 0);
            var txt = app.shellIcon.createChild('text');
            txt.setText(app.label);
            txt.setColor(0, 0, 0);
            txt.setAlignment('center-top');
            txt.setTranslation(64, 70);
            txt.setFont("LiberationFonts/LiberationSans-Regular.ttf");
            txt.setFontSize(20);
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
                foreach (var appInfo; me.apps) {
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

    wheel: func (axis, amount) {
        if (me.currentApp == nil) {
            # Once we get multiple screens, we might handle the event here.
        }
        else {
            me.currentApp.wheel(axis, amount);
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
            appInfo.app.setAssetDir(appBasedir ~ '/' ~ appInfo.key ~ '/');
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

var initMaster = func {
    if (!contains(globals.efb, 'efbDisplay') or globals.efb.efbDisplay == nil) {
        globals.efb.efbDisplay = canvas.new({
            "name": "EFB",
            "size": [1024, 1536],
            "view": [512, 768],
            "mipmapping": 1
        });
        globals.efb.efbDisplay.addPlacement({"node": "EFBScreen"});
    }
    if (!contains(globals.efb, 'efbMaster') or globals.efb.efbMaster == nil) {
        globals.efb.efbMaster = globals.efb.efbDisplay.createGroup();
    }
    efbMaster = globals.efb.efbMaster;
    efbMaster.removeAllChildren();
    efb = EFB.new(efbMaster);
};

