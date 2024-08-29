var efb = nil;

logprint(3, "EFB main module start");

# Un-grab the keyboard in case it was still grabbed by a previous instance
props.globals.getNode('/instrumentation/efb/keyboard-grabbed', 1).setValue(0);

var fgdir = getprop('/sim/fg-home');

var systemAppBasedir = acdir ~ '/Nasal/efb/apps';
var customAppBasedir = acdir ~ '/Nasal/efbapps';
var globalAppBasedir = fgdir ~ '/Export/efbapps';

# Compatibility shim: canvasToLocal
if (!contains(globals.canvas.Element, 'canvasToLocal')) {
    globals.canvas.Element.canvasToLocal = func (xy) {
        var tf = me._node.getChildren('tf');
        if (tf == nil)
            tf = [];
        for (var i = size(tf) - 1; i >= 0; i -= 1) {
            var tff = tf[i];
            var m = tff.getValues()['m'];
            var ma = m[0] * m[3] - m[1] * m[2];
            # reverse:
            xy[0] -= m[4];
            xy[1] -= m[5];
            xy = [
                ( xy[0] * m[3] - xy[1] * m[2]) / ma,
                (-xy[0] * m[1] + xy[1] * m[0]) / ma,
            ];
        }
        var p = me.getParent();
        if (p == nil or !isa(p, globals.canvas.Element)) {
            return xy;
        }
        else {
            return p.canvasToLocal(xy);
        }
    };
};

# Compatibility shim: imageSize
if (!contains(globals.canvas.Element, 'imageSize')) {
    globals.canvas.Image.imageSize = func {
        var sizeNodes = me._node.getChildren('size');
        return [sizeNodes[0].getValue(), sizeNodes[1].getValue()];
    };
}

# Fix: writexml() from Nasal's IO library is incorrect. This version here should
# encode strings correctly.

# Writes a property tree as returned by readxml() to a file. Children
# with name starting with <prefix> are again turned into attributes of
# their parent. <node> must contain exactly one child, which will
# become the XML file's outermost element.
#
var writexml = func(path, node, indent = "\t", prefix = "___") {
    var root = node.getChildren();
    if (!size(root))
        die("writexml(): tree doesn't have a root node");
    if (substr(path, -4) != ".xml")
        path ~= ".xml";
    var file = io.open(path, "w");
    io.write(file, "<?xml version=\"1.0\"?>\n\n");

    var xmlencode = func (str) {
        str = string.replace(str, '&', '&amp;');
        str = string.replace(str, '"', '&quot;');
        str = string.replace(str, '>', '&gt;');
        str = string.replace(str, '<', '&lt;');
        str = string.replace(str, '\'', '&apos;');
        return str;
    };

    var writenode = func(n, ind = "") {
        var name = n.getName();
        var name_attr = name;
        var children = [];
        foreach (var c; n.getChildren()) {
            var a = c.getName();
            if (substr(a, 0, size(prefix)) == prefix)
                name_attr ~= " " ~ substr(a, size(prefix)) ~ '="' ~  xmlencode(c.getValue()) ~ '"';
            else
                append(children, c);
        }
        if (size(children)) {
            io.write(file, ind ~ "<" ~ name_attr ~ ">\n");
            foreach (var c; children)
                writenode(c, ind ~ indent);
            io.write(file, ind ~ "</" ~ name ~ ">\n");
        } elsif ((var value = n.getValue()) != nil) {
            io.write(file, ind ~ "<" ~ name_attr ~ ">" ~ xmlencode(value) ~ "</" ~ name ~ ">\n");
        } else {
            io.write(file, ind ~ "<" ~ name_attr ~ "/>\n");
        }
    };
    writenode(root[0]);
    io.close(file);
    if (size(root) != 1)
        die("writexml(): tree has more than one root node");
}

globals.efb.availableApps = {};
globals.efb.registerApp_ = func(basedir, key, label, iconName, class) {
    globals.efb.availableApps[key] = {
        basedir: basedir,
        key: key,
        icon: (iconName == nil) ? (acdir ~ '/Models/EFB/icons/unknown-app.png') : (basedir ~ '/' ~ iconName),
        label: label,
        loader: func (g) {
            var app = class.new(g);
            app.basedir = basedir;
            return app;
        },
    };
};

var registerApp = nil;

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

var loadAppDir = func (basedir) {
    printf("Scanning for apps in %s", basedir);
    var appFiles = directory(basedir);
    if (appFiles == nil)
        appFiles = [];
    foreach (var f; appFiles) {
        if (substr(f, 0, 1) != '.') {
            printf("Found app: %s", f);
            var dirname = basedir ~ '/' ~ f;
            registerApp = func(key, label, iconName, class) {
                # print(dirname);
                registerApp_(dirname, key, label, iconName, class);
            }
            io.load_nasal(dirname ~ '/main.nas', 'efb');
        }
    }
};

loadAppDir(systemAppBasedir);
loadAppDir(globalAppBasedir);
loadAppDir(customAppBasedir);

var EFB = {
    clipTemplate: string.compileTemplate('rect({top}px, {right}px, {bottom}px, {left}px)'),

    new: func (master) {
        var m = {
            parents: [EFB],
            master: master,
        };
        m.currentApp = nil;
        m.shellPage = 0;
        m.shellNumPages = 1;
        m.reportedRotation = 0;
        m.apps = [];
        m.carousel = nil;
        m.appStack = [];
        foreach (var k; sort(keys(availableApps), cmp)) {
            var app = availableApps[k];
            append(m.apps,
                { icon: app.icon,
                , label: app.label,
                , loader: app.loader,
                , key: app.key,
                , basedir: app.basedir,
                });
        }
        m.metrics = {
            screenW: 512,
            screenH: 768,
            effectiveScreenW: 512,
            effectiveScreenH: 768,
            buttonRowH: 32,
            carouselScale: 0.5,
            carouselPadding: 32,
        };
        m.metrics.carouselW = m.metrics.screenW * m.metrics.carouselScale;
        m.metrics.carouselH = m.metrics.screenH * m.metrics.carouselScale;
        m.metrics.carouselAdvance = m.metrics.carouselW + m.metrics.carouselPadding;

        m.initialize();
        return m;
    },

    setupBackgroundImage: func {
        var backgroundImagePaths = [];

        var appendPathsFromNodes = func (parentNode, selector) {
            if (typeof(parentNode) == 'scalar')
                parentNode = props.globals.getNode(parentNode);
            if (parentNode == nil)
                return;
            var nodes = parentNode.getChildren(selector);
            foreach (var n; nodes) {
                var path = n.getValue();
                if (path != nil) {
                    append(backgroundImagePaths, acdir ~ '/' ~ path);
                }
            }
        }

        me.backgroundImg = me.master.createChild('image');

        appendPathsFromNodes('/instrumentation/efb', 'background-image');
        if (size(backgroundImagePaths) == 0) {
            # Nothing configured, try previews
            appendPathsFromNodes('/sim/previews', 'preview/path');
        }
        if (size(backgroundImagePaths) == 0) {
            # Nothing suitable found yet, use the default image.
            append(backgroundImagePaths, acdir ~ '/Models/EFB/wallpaper.jpg');
        }
        var index = math.min(size(backgroundImagePaths) - 1, math.floor(rand() * size(backgroundImagePaths)));
        var path = backgroundImagePaths[index];
        me.backgroundImg.set('src', path);
        (var w, var h) = me.backgroundImg.imageSize();
        var minZoomX = me.metrics.screenW / w;
        var minZoomY = me.metrics.screenH / h;
        var zoom = math.max(minZoomX, minZoomY);
        var dx = (me.metrics.screenW - w * zoom) * 0.5;
        var dy = (me.metrics.screenH - h * zoom) * 0.5;
        me.backgroundImg.setTranslation(dx, dy);
        me.backgroundImg.setScale(zoom, zoom);

        me.background = me.master.createChild('path')
                            .rect(0, 0, me.metrics.screenW, me.metrics.screenH)
                            .setColorFill(1, 1, 1, 0.5);
    },

    initialize: func() {
        me.setupBackgroundImage();
        me.shellGroup = me.master.createChild('group');
        me.shellPages = [];

        me.clientGroup = me.master.createChild('group');

        me.carouselWidget = Widget.new();
        me.carouselGroup = me.master.createChild('group');

        me.overlay = canvas.parsesvg(me.master, acdirRel ~ "/Models/EFB/overlay.svg", {'font-mapper': font_mapper});
        me.keyboardGrabElem = me.master.getElementById('keyboardGrabIcon');
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

            app.shellIcon.createChild('text')
                .setText(app.label)
                .setColor(0, 0, 0)
                .setAlignment('center-top')
                .setTranslation(64, 70)
                .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                .setFontSize(20);
        }
        var self = me;
        setlistener('/instrumentation/efb/keyboard-grabbed', func (node) {
            self.keyboardGrabElem.setVisible(node.getBoolValue());
        }, 1, 1);
        setlistener('/instrumentation/clock/local-short-string', func(node) {
            self.clockElem.setText(node.getValue());
        }, 1, 1);
        setlistener('/instrumentation/efb/orientation-norm', func (node) {
            me.deviceRotation = node.getValue();
            me.rotate(me.deviceRotation);
        }, 0, 1);
        me.deviceRotation = getprop('/instrumentation/efb/orientation-norm') or 0;
        me.rotate(me.deviceRotation, 1);
        var dt = 0.025;
        me.carouselAnimationTimer = maketimer(dt, func () {
            self.updateCarouselScroll(dt);
        });
        me.carouselAnimationTimer.start();
    },

    rotate: func (rotationNorm, hard=0) {
        var prevRotation = me.reportedRotation;

        if (rotationNorm > 0.75) {
            me.reportedRotation = 1;
            me.metrics.effectiveScreenW = me.metrics.screenH;
            me.metrics.effectiveScreenH = me.metrics.screenW;
        }
        elsif (rotationNorm < 0.25) {
            me.reportedRotation = 0;
            me.metrics.effectiveScreenW = me.metrics.screenW;
            me.metrics.effectiveScreenH = me.metrics.screenH;
        }
        if (prevRotation != me.reportedRotation) {
            if (me.currentApp == nil) {
                # TODO: implement rotation for the shell
            }
            else {
                me.currentApp.app.rotate(me.reportedRotation, hard);
            }
        }
    },

    touch: func (args) {
        var x = math.floor(args.x * me.metrics.screenW);
        var y = math.floor((1.0 - args.y) * me.metrics.screenH);
        if (y >= me.metrics.screenH - me.metrics.buttonRowH) {
            if (x < me.metrics.screenW / 3) {
                me.handleBack();
            }
            else if (x < me.metrics.screenW * 2 / 3) {
                me.handleHome();
            }
            else {
                me.handleMenu();
            }
        }
        else {
            if (me.carousel != nil) {
                # Carousel mode: handle accordingly
                me.carouselWidget.touch(x, y);
            }
            elsif (me.currentApp != nil) {
                me.currentApp.app.touch(x, y);
            }
            else {
                # Shell: find icon
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
        }
    },

    wheel: func (axis, amount) {
        if (me.carousel != nil) {
            # Carousel mode
            if (axis == 0) {
                me.carousel.selectedAppIndex -= amount;
                me.carousel.selectedAppIndex =
                    math.max(0,
                        math.min(size(me.carousel.apps) - 1,
                            me.carousel.selectedAppIndex));
            }
        }
        elsif (me.currentApp == nil) {
            # Once we get multiple screens, we might handle the event here.
        }
        else {
            me.currentApp.app.wheel(axis, amount);
        }
    },

    hideCurrentApp: func () {
        if (me.currentApp != nil) {
            me.currentApp.app.background();
            me.currentApp.app.masterGroup.hide();
            me.currentApp = nil;
        }
    },

    openShell: func () {
        me.hideCurrentApp();
        me.shellGroup.show();
    },

    openCarousel: func {
        var self = me;

        me.carousel = {
            apps: [],
            selectedAppIndex: 0,
            scrollX: 0,
        };
        var x = 0;
        var i = 0;
        me.carouselWidget.removeAllChildren();
        me.carouselGroup.removeAllChildren();
        foreach (var appInfo; me.appStack) {
            if (appInfo.app != nil) {
                append(me.carousel.apps, appInfo);
                if (me.currentApp != nil and id(appInfo.app) == id(me.currentApp.app)) {
                    me.carousel.selectedAppIndex = i;
                    me.currentApp.app.background();
                    me.carousel.scrollX = i * me.metrics.carouselAdvance;
                }
                (func (appInfo, i) {
                    var box = self.carouselGroup.createChild('path')
                                .rect(i * self.metrics.carouselAdvance, 0, self.metrics.carouselW, self.metrics.carouselH)
                                .setColor(0, 0, 0);
                    appInfo.carouselClickbox = box;
                    var clickWidget = Widget.new(box);
                    clickWidget.setClickHandler(func {
                        if (self.carousel.selectedAppIndex == i) {
                            self.cancelCarousel();
                            self.openApp(appInfo);
                        }
                        else {
                            self.carousel.selectedAppIndex = i;
                        }
                        return 0;
                    });
                    self.carouselWidget.appendChild(clickWidget);

                    var img = self.carouselGroup.createChild('image');
                    img.set('src', appInfo.icon);
                    var imgW = 64;
                    var imgH = 64;
                    var centerX = i * self.metrics.carouselAdvance + self.metrics.carouselW * 0.5;
                    img.setTranslation(
                        centerX - imgW * 0.5,
                        -imgH * 0.66);
                    self.carouselGroup.createChild('text')
                        .setText(appInfo.label)
                        .setAlignment('center-baseline')
                        .setColor(0,0,0)
                        .setFont(font_mapper('sans', 'normal'))
                        .setFontSize(20, 1)
                        .setTranslation(centerX, -imgH * 0.5 - 20);

                    var trashBox = self.carouselGroup.createChild('path')
                                       .rect(
                                            centerX - imgW * 0.5 - self.metrics.carouselPadding * 0.5,
                                            self.metrics.carouselH + self.metrics.carouselPadding * 0.5,
                                            imgW + self.metrics.carouselPadding,
                                            imgH + self.metrics.carouselPadding,
                                            { 'border-radius': 8 })
                                        .setColorFill(1, 1, 1, 0.5);
                    var trashImg = self.carouselGroup.createChild('image');
                    trashImg.set('src', acdir ~ '/Models/EFB/icons/trash.png');
                    trashImg.setTranslation(
                        centerX - imgW * 0.5,
                        self.metrics.carouselH + self.metrics.carouselPadding);

                    var killWidget = Widget.new(trashBox);
                    killWidget.setClickHandler(func {
                        self.cancelCarousel();
                        self.killApp(appInfo);
                        self.openCarousel();
                    });
                    self.carouselWidget.appendChild(killWidget);
                })(appInfo, i);
                appInfo.app.masterGroup.setScale(0.5, 0.5);
                appInfo.app.masterGroup.show();
                i += 1;
            }
        }
        if (i == 0) {
            me.carousel = nil;
            me.openShell();
        }
        else {
            me.shellGroup.hide();
            me.updateCarouselScroll();
        }
    },

    cancelCarousel: func {
        if (me.carousel == nil)
            return;
        me.carouselWidget.removeAllChildren();
        me.carouselGroup.removeAllChildren();
        foreach (var appInfo; me.carousel.apps) {
            appInfo.app.masterGroup.hide();
            if (appInfo.carouselClickbox != nil) {
                appInfo.carouselClickbox.hide();
                appInfo.carouselClickbox = nil;
            }
        }
        me.carousel = nil;
        me.showCurrentApp();
    },

    updateCarouselScroll: func (dt=nil) {
        if (me.carousel == nil)
            return;
        var targetScroll = me.carousel.selectedAppIndex * me.metrics.carouselAdvance;
        var nextScroll = 0;
        var dist = me.carousel.scrollX - targetScroll;
        if (dt == nil) { 
            nextScroll = targetScroll;
        }
        elsif (dist > 1) {
            nextScroll =
                math.max(targetScroll, me.carousel.scrollX - (dist + 10) * dt * 4);
        }
        elsif (dist < -1) {
            nextScroll =
                math.min(targetScroll, me.carousel.scrollX - (dist - 10) * dt * 4);
        }
        else {
            nextScroll = targetScroll;
        }
        if (me.carousel.scrollX != nextScroll or dt == nil) {
            me.carousel.scrollX = nextScroll;
            var x = me.metrics.carouselW * 0.5 - me.carousel.scrollX;
            var top = (me.metrics.screenH - me.metrics.carouselH) * 0.5;
            var bottom = top + me.metrics.carouselH;
            me.carouselGroup.setTranslation(x, top);
            foreach (var appInfo; me.carousel.apps) {
                appInfo.app.masterGroup.setTranslation(x, top);
                appInfo.app.masterGroup.set('clip', me.clipTemplate({left: x, right: x + me.metrics.carouselW, top: top, bottom: bottom}));
                x += me.metrics.carouselAdvance;
            }
        }
    },

    showCurrentApp: func () {
        if (me.currentApp == nil) {
            me.openShell();
            return;
        }
        # Set current rotation, because the app may not have caught it yet
        me.currentApp.app.rotate(me.reportedRotation, 1);
        me.currentApp.app.masterGroup.setTranslation(0, 0);
        me.currentApp.app.masterGroup.setScale(1, 1);
        me.currentApp.app.masterGroup.set('clip', me.clipTemplate({left: 0, right: me.metrics.screenW, top: 0, bottom: me.metrics.screenH}));
        me.currentApp.app.masterGroup.show();
        me.currentApp.app.foreground();
    },

    pushCurrentAppToStack: func {
        if (me.currentApp == nil)
            return;
        var newAppStack = [];
        foreach (var item; me.appStack) {
            if (id(item) != id(me.currentApp)) {
                append(newAppStack, item);
            }
        }
        newAppStack = [me.currentApp] ~ newAppStack;
        me.appStack = newAppStack;
    },

    removeAppFromStack: func (appInfo) {
        var newAppStack = [];
        foreach (var item; me.appStack) {
            if (id(item) != id(appInfo)) {
                append(newAppStack, item);
            }
        }
        me.appStack = newAppStack;
    },

    openApp: func (appInfo) {
        me.hideCurrentApp();
        me.shellGroup.hide();
        if (appInfo.app == nil) {
            var masterGroup = me.clientGroup.createChild('group');
            appInfo.app = appInfo.loader(masterGroup);
            appInfo.app.setAssetDir(appInfo.basedir ~ '/');
            appInfo.app.efb = me;
            appInfo.app.initialize();
        }
        me.currentApp = appInfo;
        me.pushCurrentAppToStack();
        me.showCurrentApp();
    },

    killApp: func (appInfo) {
        me.removeAppFromStack(appInfo);
        if (id(me.currentApp) == id(appInfo)) {
            me.hideCurrentApp();
            me.currentApp = nil;
        }
        if (appInfo.app != nil) {
            appInfo.app.masterGroup._node.remove();
            appInfo.app = nil;
        }
    },

    handleMenu: func () {
        if (me.currentApp != nil) {
            me.currentApp.app.handleMenu();
        }
        else {
            # next shell page
        }
    },

    handleBack: func () {
        if (me.carousel != nil) {
            me.cancelCarousel();
        }
        elsif (me.currentApp != nil) {
            me.currentApp.app.handleBack();
        }
        else {
            # previous shell page
        }
    },

    handleHome: func () {
        if (me.carousel != nil) {
            me.cancelCarousel();
            me.openShell();
        }
        elsif (me.currentApp != nil) {
            me.openShell();
        }
        else {
            me.openCarousel();
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

