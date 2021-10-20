# Embraer E-Jet family MCDU.
#
# E190 AOM:
# - p1582: T/O DATASET menu
# - p1761: MCDU CONTROLS
# - p1804: RADIO COMMUNICATION SYSTEM
# - p1822: ACARS etc.
# - p1859: IRS
# - p1901: Preflight flow

var mcdu0 = nil;
var mcdu1 = nil;

setlistener("/sim/signals/fdm-initialized", func () {
    mcdu0 = MCDU.new(0);
    mcdu1 = MCDU.new(1);
    setprop('/instrumentation/mcdu[0]/canvas-index', mcdu0.display._node.getIndex());
    setprop('/instrumentation/mcdu[1]/canvas-index', mcdu1.display._node.getIndex());
    setlistener("/systems/electrical/outputs/mcdu[0]", func () {
        if (getprop("/systems/electrical/outputs/mcdu[0]") < 15.0) {
            mcdu0.powerOff();
        }
        else {
            mcdu0.powerOn();
        }
    });
    setlistener("/systems/electrical/outputs/mcdu[1]", func () {
        if (getprop("/systems/electrical/outputs/mcdu[1]") < 15.0) {
            mcdu1.powerOff();
        }
        else {
            mcdu1.powerOn();
        }
    });
});
