globals.efb = {};

var includes = {};

var acdir = getprop('/sim/aircraft-dir');
var include = func (basename) {
    if (contains(includes, basename))
        return includes[basename];
    var path = acdir ~ '/Nasal/efb/' ~ basename;
    printf("--- loading " ~ path ~ " ---");
    io.load_nasal(path, 'efb');
    includes[basename] = 1;
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
    if (contains(globals.efb, "initialized") and globals.efb.initialized) return;
    include('main.nas');
    initMaster();
    globals.efb.initialized = 1;
};

setlistener("sim/signals/fdm-initialized", func {
    init();
});

var reload = func {
    # clean up first
    foreach (var l; listeners) {
        globals.removelistener(l);
    }
    listeners = [];
    includes = {}; # force re-loading includes
    globals.efb.initialized = 0;
    init();
};
