globals.efb = {};
globals.html = {};

var includes = {};

var acdir = getprop('/sim/aircraft-dir');
var findRelativeAircraftDir = func () {
    var parts = split('/', acdir);
    while (size(parts) > 0 and parts[0] != 'Aircraft')
        parts = subvec(parts, 1);
    if (size(parts) == 0)
        return acdir;
    else
        return string.join('/', parts);
};
var acdirRel = findRelativeAircraftDir();

var fgdir = getprop('/sim/fg-home');


var include = func (basename) {
    var namespace = 'efb';
    var path = acdir ~ '/Nasal/efb/' ~ basename;
    if (substr(basename, 0, 1) == '/') {
        namespace = split('/', basename)[1];
        path = acdir ~ '/Nasal' ~ basename;
    }

    if (!contains(includes, basename)) {
        logprint(3, sprintf("--- loading " ~ path ~ " ---"));
        io.load_nasal(path, namespace);
        includes[basename] = 1;
    }
}

var listeners = [];
var setlistener = func (node, code, init=0, type=1) {
    var l = globals.setlistener(node, code, init, type);
    append(listeners, l);
    return l;
};

var removelistener = func (l) {
    if (l == nil) return;
    var i = vecindex(listeners, l);
    if (i != nil) {
        listeners = subvec(listeners, 0, i) ~ subvec(listeners, i+1);
    }
    globals.removelistener(l);
};

var init = func {
    if (contains(globals.efb, "initialized") and globals.efb.initialized)
        return;
    initTimerSystem();
    include('main.nas');
    initMaster();
    globals.efb.initialized = 1;
};

var initTimerSystem = func {
    if (!contains(globals.efb, 'timerSystem') or globals.efb.timerSystem == nil) {
        globals.efb.timerSystem = {
            delta: 1/60,
            timers: {},
            nextTimerID: 0,
            update: updateTimers,
        };
        globals.efb.timerSystem.masterTimer =
            globals.maketimer(globals.efb.timerSystem.delta, func { globals.efb.timerSystem.update(); });
        globals.efb.timerSystem.masterTimer.start();
    }
};

var updateTimers = func {
    var timers = globals.efb.timerSystem.timers;
    var dt = globals.efb.timerSystem.delta;
    foreach (var k; keys(timers)) {
        var timer = timers[k];
        if (!timer.isRunning)
            continue;
        timer.tickCounter += 1;
        if (timer.tickCounter * dt >= timer.interval) {
            var numUpdates = math.floor(timer.tickCounter * dt / timer.interval);
            var dTicks = math.floor(timer.interval / dt);
            var actualDT = dTicks * dt;
            timer.tickCounter -= dTicks;
            if (timer.singleShot) {
                call(timer.function, [], timer.self);
                timer.isRunning = false;
            }
            else {
                for (var i = 0; i < numUpdates; i += 1) {
                    call(timer.function, [], timer.self);
                }
            }
        }
    }
};

var FakeTimer = {
    start: func { me.isRunning = 1; },
    stop: func { me.isRunning = 0; },
    restart: func (interval) { me.interval = interval; },
};

var maketimer = func () {
    var system = globals.efb.timerSystem;

    var args = arg;
    var self = nil;
    var interval = args[0];
    var function = nil;
    var timerID = system.nextTimerID;
    system.nextTimerID += 1;

    if (size(args) == 3) {
        function = args[2];
        self = args[1];
    }
    else {
        function = args[1];
    }
    var timer = {
        parents: [FakeTimer],
        ident: timerID,
        function: function,
        self: self,
        interval: interval,
        isRunning: 0,
        singleShot: 0,
        simulatedTime: 1,
        tickCounter: 0,
    };
    system.timers[timerID] = timer;
    return timer;
};

setlistener("sim/signals/fdm-initialized", func {
    init();
});

var reload = func {
    # clean up listeners and timers
    foreach (var l; listeners) {
        globals.removelistener(l);
    }
    listeners = [];
    globals.efb.timerSystem.timers = {};

    includes = {}; # force re-loading includes
    globals.efb.initialized = 0;
    init();
};
