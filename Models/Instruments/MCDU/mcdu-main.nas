# Embraer E-Jet family MCDU.
#
# E190 AOM:
# - p1582: T/O DATASET menu
# - p1761: MCDU CONTROLS
# - p1804: RADIO COMMUNICATION SYSTEM
# - p1822: ACARS etc.
# - p1859: IRS
# - p1901: Preflight flow

var acdir = getprop('/sim/aircraft-dir');
var include = func (basename) {
    var path = acdir ~ '/Models/Instruments/MCDU/' ~ basename;
    logprint(3, "--- loading " ~ path ~ " ---");
    io.load_nasal(path, 'mcdu');
}

var includeAll = func (dirname) {
    logprint(3, "--- loading " ~ dirname ~ " ---");
    var basedir = acdir ~ '/Models/Instruments/MCDU/' ~ dirname;
    var paths = directory(basedir);
    if (paths == nil) paths = [];
    foreach (var path; paths) {
        if (substr(path, -4) == '.nas') {
            logprint(3, "--- loading " ~ path ~ " ---");
            io.load_nasal(basedir ~ '/' ~ path, 'mcdu');
        }
        else {
            logprint(2, "--- skipping " ~ path ~ "---");
        }
    }
}

var reload = func {
    include('mcdu-main.nas');
}

# Initialize MCDU variables in case they don't exist yet
if (!contains(globals.mcdu, 'mcdu0')) {
    globals.mcdu.mcdu0 = nil;
}
if (!contains(globals.mcdu, 'mcdu1')) {
    globals.mcdu.mcdu1 = nil;
}

# Clean up stuff from previous runs
if (contains(globals.mcdu, 'initListener')) {
    removelistener(globals.mcdu.initListener);
}
if (contains(globals.mcdu, 'powerListener0')) {
    removelistener(globals.mcdu.powerListener0);
}
if (contains(globals.mcdu, 'powerListener1')) {
    removelistener(globals.mcdu.powerListener1);
}

if (globals.mcdu.mcdu0 != nil) {
    globals.mcdu.mcdu0.teardown();
}

if (globals.mcdu.mcdu1 != nil) {
    globals.mcdu.mcdu1.teardown();
}

# (re-)load submodules
include('util.nas');
include('defs.nas');
include('model-factory.nas');
includeAll('models');
includeAll('controllers');
includeAll('modules');
includeAll('views');
include('device.nas');

# initialize
var initialized = 0;

globals.mcdu.initListener = setlistener("/sim/signals/fdm-initialized", func (node) {
    if (!node.getBoolValue()) return;
    if (initialized) return;
    initialized = 1;

    print("INITIALIZE MCDU");

    print("Make new MCDU's");
    globals.mcdu.mcdu0 = MCDU.new(0);
    globals.mcdu.mcdu1 = MCDU.new(1);

    print("Set canvas indices");
    setprop('/instrumentation/mcdu[0]/canvas-index', mcdu0.display._node.getIndex());
    setprop('/instrumentation/mcdu[1]/canvas-index', mcdu1.display._node.getIndex());

    print("Install power listeners");
    globals.mcdu.powerListener0 = setlistener("/systems/electrical/outputs/mcdu[0]", func () {
        if ((getprop("/systems/electrical/outputs/mcdu[0]") or 0) < 15.0) {
            print("MCDU0 power off");
            globals.mcdu.mcdu0.powerOff();
        }
        else {
            print("MCDU0 power on");
            globals.mcdu.mcdu0.powerOn();
        }
    }, 1, 0);
    globals.mcdu.powerListener1 = setlistener("/systems/electrical/outputs/mcdu[1]", func () {
        if ((getprop("/systems/electrical/outputs/mcdu[1]") or 0) < 15.0) {
            globals.mcdu.mcdu1.powerOff();
        }
        else {
            globals.mcdu.mcdu1.powerOn();
        }
    }, 1, 0);

    print("Done initializing");
}, 1, 0);
