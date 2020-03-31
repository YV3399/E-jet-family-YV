var ifesCanvas = nil;
var screenWidth = 1024;
var screenHeight = 800;
var texSize = 1024;
var uvBottom = 0.997109;
var uvTop = 0.214844;
var uvHeight = uvBottom - uvTop;
var uvWidth = 1;
var screenTop = (screenHeight / uvHeight) * uvTop;

var Console = {
    new: func(group) {
        var m = { parents: [Console] };
        m.init(group);
        return m;
    },

    init: func(group) {
        me.textLines = [];
        me.textLineElems = [];
        me.numLines = math.floor(screenHeight / 20);
        me.textgroup = group.createChild("group");
        for (var i = 0; i < me.numLines; i = i + 1) {
            var y = (i + 1) * 20;
            append(me.textLineElems,
                me.textgroup.createChild("text")
                            .setTranslation(0, y)
                            .setFontSize(16)
                            .setFont("LiberationFonts/LiberationMono-Bold.ttf")
                            .setColor([255,255,255]));
        }
        me.dirty = 1;

        return me;
    },

    refresh: func() {
        for (var i = 0; i < me.numLines; i = i + 1) {
            if (i < size(me.textLines)) {
                me.textLineElems[i].setText(me.textLines[i] or "");
            }
            else {
                me.textLineElems[i].setText("");
            }
        }
    },

    writeLine: func(line) {
        append(me.textLines, line);
        if (size(me.textLines) > me.numLines) {
            me.textLines = me.textLines[-me.numLines:];
        }
        me.dirty = 1;
    },

    clear: func() {
        me.textLines = [];
        me.dirty = 1;
    },

    update: func() {
        if (me.dirty) {
            me.refresh();
            me.dirty = 0;
        }
    }
};

var BootScreen = {
    new: func(con) {
        var m = { parents: [BootScreen] };
        m.con = con;
        m.reset();
        return m;
    },

    reset: func() {
        me.bootEntry = 0;
        me.bootTimer = 0.0;
        me.con.clear();
    },

    update: func() {
        me.bootTimer = me.bootTimer + 0.02;
        while (me.bootEntry < size(BootScreen.sequence)) {
            if (me.bootTimer > BootScreen.sequence[me.bootEntry][0]) {
                var line = BootScreen.sequence[me.bootEntry][1];
                if (line == nil) {
                    me.con.clear();
                }
                else {
                    me.con.writeLine(line);
                }
                me.bootEntry = me.bootEntry + 1;
            }
            else {
                break;
            }
        }
    },

    sequence: [
        [ 0.0, "FreeFlight IFES v1.0" ],
        [ 0.0, "Starting, please wait..." ],
        [ 0.2, "Configuring ISA PNP" ],
        [ 1.1, "Setting system time from the hardware clock (localtime). " ],
        [ 1.2, "Using /etc/random-seed to initialize /dev/urandom" ],
        [ 1.3, "Initializing basic system settings ..." ],
        [ 1.5, "Updating shared libraries" ],
        [ 2.4, "Setting hostname: ifes70.flightgear.org" ],
        [ 2.4, "INIT: Entering runlevel: 4" ],
        [ 2.4, "Going multiuser..." ],
        [ 2.5, "Starting system logger ...                                               [ OK ]" ],
        [ 2.6, "Initialising advanced hardware" ],
        [ 2.6, "Setting up modules ...                                                   [ OK ]" ],
        [ 3.1, "Initialising network" ],
        [ 3.1, "Setting up localhost ...                                                 [ OK ]" ],
        [ 3.2, "Setting up inet1 ...                                                     [ OK ]" ],
        [ 3.4, "Setting up dhcp ...                                                      [ OK ]" ],
        [ 4.0, "Setting up route ...                                                     [ OK ]" ],
        [ 4.4, "Going to runlevel 4" ],
        [ 4.8, "Setting up locale ...                                                    [ OK ]" ],
        [ 5.5, "ifes@ifes70> _" ]
    ]
};

var IFES = {
    new: func(canvas) {
        var m = { parents: [IFES] };
        var fontMapper = func(family, weight) {
            printf("FONTMAPPER: %s %s\n", family, weight);
            return "LiberationFonts/LiberationMono-Regular.ttf";
        };

        var screenGroup = canvas.createGroup("screen");
        print(screenGroup);
        var background = screenGroup.rect(0, 0, screenWidth, screenHeight)
                                    .setColorFill([0,0,0]);
        m.masterGroup = screenGroup.createChild("group", "master");
        m.console = Console.new(m.masterGroup.createChild("group", "console"));
        m.bootScreen = BootScreen.new(m.console);
        m.powered = 0;

        return m;
    },

    update: func() {
        if (me.powered) {
            me.bootScreen.update();
            me.console.update();
        }
    },

    start: func() {
        if (!me.powered) {
            me.bootScreen.reset();
            me.powered = 1;
            me.masterGroup.show();
        }
    },

    stop: func() {
        if (me.powered) {
            me.powered = 0;
            me.masterGroup.hide();
        }
    },

    touch: func(x, y) {
        if (!me.powered) return;
        me.console.writeLine(sprintf("touch (%i, %i)", x, y));
    }
};

var onTouch = nil;
var registerTouch = func(x, y) {
    if (onTouch != nil) {
        onTouch(x, y);
    }
};

setlistener("sim/signals/fdm-initialized", func {
    ifesCanvas = canvas.new({
        "name": "IFES",
        "size": [texSize, texSize],
        "view": [texSize, texSize],
        "mipmapping": 1
    });
    ifesCanvas.addPlacement({"node": "ifes_screen"});
    var ifes = IFES.new(ifesCanvas);
    var update = func () {
            ifes.update();
            settimer(update, 0.02);
        };
    update();
    setlistener("systems/electrical/left-bus", func(changed, listen, mode) {
        if (mode == 0 and listen != nil) {
            var voltage = listen.getValue();
            if (voltage > 20.0) {
                ifes.start();
            }
            elsif (voltage < 12.0) {
                ifes.stop();
            }
        }
    });
    onTouch = func(x, y) {
        var sx = math.floor(x / uvWidth * screenWidth);
        var sy = math.floor((uvBottom - y) / uvHeight * screenHeight);
        ifes.touch(sx, sy);
    };
});
