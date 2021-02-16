var efbDisplay = nil;
var efbMaster = nil;
var efb = nil;

var BaseApp = {
    touch: func (x, y) {},
    handleBack: func () {},
    handleForward: func () {},
    foreground: func () {},
    background: func () {},
    initialize: func () {},
};

var FlightbagApp = {
    new: func(masterGroup) {
        var m = {
            parents: [FlightbagApp, BaseApp],
            masterGroup: masterGroup,
        };
        return m;
    },

    initialize: func () {
        me.bgfill = me.masterGroup.createChild('path')
                        .rect(0, 0, 512, 768)
                        .setColorFill(255, 255, 255);
        me.text = me.masterGroup.createChild('text')
                        .setText('Charts not available')
                        .setColor(0, 0, 0)
                        .setAlignment('center-top')
                        .setTranslation(256, 384)
                        .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                        .setFontSize(24);
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
        debug.dump(x, y);
        if (y >= 736) {
            if (x < 171) {
                me.handleBack();
            }
            else if (x < 342) {
                me.handleHome();
            }
            else {
                me.handleForward();
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

    handleForward: func () {
        if (me.currentApp != nil) {
            me.currentApp.handleForward();
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
        "size": [512, 768],
        "view": [512, 768],
        "mipmapping": 1
    });
    efbDisplay.addPlacement({"node": "EFBScreen"});
    efbMaster = efbDisplay.createGroup();
    efb = EFB.new(efbMaster);
});
