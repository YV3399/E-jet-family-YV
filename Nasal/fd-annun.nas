# FD annunciations

var myprops = {};


var vertModeMap = {
    "ALT HLD": "ALT",
    "V/S": "VS",
    "G/S": "GS",
    "ALT CAP": "ASEL",
    "SPD DES": "FLCH",
    "SPD CLB": "FLCH",
    "FPA": "PATH",
    "LAND 3": "LAND",
    "FLARE": "FLARE",
    "ROLLOUT": "ROLLOUT",
    "T/O CLB": "TO",
    "G/A CLB": "GA"
};
var vertModeArmedMap = {
    "V/S": "ASEL",
    "G/S": "ASEL",
    "ALT CAP": "ALT",
    "SPD DES": "ASEL",
    "SPD CLB": "ASEL",
    "FPA": "ASEL",
    "T/O CLB": "FLCH",
    "G/A CLB": "FLCH"
};

var latModeMap = {
    "HDG": "HDG",
    "HDG HLD": "ROLL",
    "HDG SEL": "HDG",
    "LNAV": "LNAV",
    "LOC": "LOC",
    "ALGN": "ROLL",
    "RLOU": "ROLL",
    "T/O": "TRACK"
};
var latModeArmedMap = {
    "LNV": "LNAV",
    "LOC": "LOC",
    "ILS": "LOC",
    "HDG": "HDG",
    "HDG HLD": "ROLL",
    "HDG SEL": "HDG",
    "T/O": "TRACK"
};
var spdModeMap = {
    "THRUST": "SPD",
    "PITCH": "SPD",
    " PITCH": "SPD", # yes, this is correct, ITAF 4.0 is buggy here
    "RETARD": "SPD",
    "T/O CLB": " TO",
    "G/A CLB": " GA"
};
var spdMinorModeMap = {
    "THRUST": "T",
    "PITCH": "E",
    " PITCH": "E", # yes, this is correct, ITAF 4.0 is buggy here
    "RETARD": "E",
    "T/O CLB": " ",
    "G/A CLB": " "
};
var spdModeArmedMap = {
    "THRUST": "",
    "PITCH": "SPD",
    " PITCH": "SPD",
    "RETARD": "SPD",
    "T/O CLB": "SPD",
    "G/A CLB": "SPD"
};
var spdMinorModeArmedMap = {
    "THRUST": " ",
    "PITCH": "T",
    " PITCH": "T",
    "RETARD": "T",
    "T/O CLB": "T",
    "G/A CLB": "T"
};

var updateFMAVert = func () {
    var vertMode = myprops["/it-autoflight/mode/vert"].getValue() or "";
    var vertModeLabel = vertModeMap[vertMode] or "";
    if (myprops["/controls/flight/vnav-enabled"].getValue()) {
        vertModeLabel = "V" ~ vertModeLabel;
    }
    myprops["vert-mode"].setValue(vertModeLabel);
    if (myprops["/it-autoflight/output/appr-armed"].getValue() and vertMode != "G/S") {
        myprops["vert-mode-armed"].setValue("GS");
    }
    else {
        myprops["vert-mode-armed"].setValue(vertModeArmedMap[vertMode] or "");
    }
};

var updateFMALat = func () {
    var vorOrLoc = "VOR";
    if (myprops["/instrumentation/pfd/ils/has-loc"].getBoolValue()) {
        vorOrLoc = "LOC";
    }

    var latModeLabel = latModeMap[myprops["/it-autoflight/mode/lat"].getValue() or ""] or "";
    if (latModeLabel == "LOC") {
        latModeLabel = vorOrLoc;
    }
    myprops["lat-mode"].setValue(latModeLabel);
    if (myprops["/it-autoflight/output/lnav-armed"].getValue()) {
        myprops["lat-mode-armed"].setValue("LNAV");
    }
    else if (myprops["/it-autoflight/output/loc-armed"].getValue() or myprops["/it-autoflight/output/appr-armed"].getValue()) {
        myprops["lat-mode-armed"].setValue("LOC");
    }
    else if (myprops["/it-autoflight/mode/lat"].getValue() == "T/O") {
        # In T/O mode, if LNAV wasn't armed, the A/P will transition to HDG mode.
        myprops["lat-mode-armed"].setValue("HDG");
    }
    else {
        myprops["lat-mode-armed"].setValue(latModeArmedMap[myprops["/it-autoflight/mode/arm"].getValue()] or "");
    }
};

var updateFMASpeed = func () {
    var vertMode = myprops["/it-autoflight/mode/vert"].getValue() or "";
    var thrMode = myprops["/it-autoflight/mode/thr"].getValue() or "";

    myprops["spd-mode"].setValue(
            spdModeMap[vertMode] or
            spdModeMap[thrMode] or
            "");
    myprops["spd-minor-mode"].setValue(
            spdMinorModeMap[vertMode] or
            spdMinorModeMap[thrMode] or
            " ");
    myprops["spd-mode-armed"].setValue(
            spdModeArmedMap[vertMode] or
            spdModeArmedMap[thrMode] or
            "");
    myprops["spd-minor-mode-armed"].setValue(
            spdMinorModeArmedMap[vertMode] or
            spdMinorModeArmedMap[thrMode] or
            " ");
};

var updateApprArmed = func (node) {
    var mode = node.getValue();
    if (mode == 1) {
        # APPR1
        myprops["appr-mode-armed"].setValue("APPR1");
    }
    else if (mode == 2) {
        # APPR1 ONLY
        myprops["appr-mode-armed"].setValue("APPR1 ONLY");
    }
    else if (mode == 3) {
        # APPR1 ONLY
        myprops["appr-mode-armed"].setValue("APPR2");
    }
    else {
        myprops["appr-mode-armed"].setValue("");
    }
};

var updateApprEngaged = func (node) {
    var mode = node.getValue();
    if (mode == 1) {
        # APPR1
        myprops["appr-mode"].setValue("APPR1");
    }
    else if (mode == 2) {
        # APPR1 ONLY
        myprops["appr-mode"].setValue("APPR1");
    }
    else if (mode == 3) {
        # APPR1 ONLY
        myprops["appr-mode"].setValue("APPR2");
    }
    else {
        myprops["appr-mode"].setValue("");
    }
};

setlistener("sim/signals/fdm-initialized", func {
    # outputs
    myprops['spd-mode'] = props.globals.getNode('/instrumentation/annun/spd-mode');
    myprops['spd-mode-armed'] = props.globals.getNode('/instrumentation/annun/spd-mode-armed');
    myprops['spd-minor-mode'] = props.globals.getNode('/instrumentation/annun/spd-minor-mode');
    myprops['spd-minor-mode-armed'] = props.globals.getNode('/instrumentation/annun/spd-minor-mode-armed');
    myprops['ap-engaged'] = props.globals.getNode('/instrumentation/annun/ap-engaged');
    myprops['at-engaged'] = props.globals.getNode('/instrumentation/annun/at-engaged');
    myprops['lat-mode'] = props.globals.getNode('/instrumentation/annun/lat-mode');
    myprops['lat-mode-armed'] = props.globals.getNode('/instrumentation/annun/lat-mode-armed');
    myprops['vert-mode'] = props.globals.getNode('/instrumentation/annun/vert-mode');
    myprops['vert-mode-armed'] = props.globals.getNode('/instrumentation/annun/vert-mode-armed');
    myprops['appr-mode'] = props.globals.getNode('/instrumentation/annun/appr-mode');
    myprops['appr-mode-armed'] = props.globals.getNode('/instrumentation/annun/appr-mode-armed');

    # inputs
    myprops["/controls/flight/vnav-enabled"] = props.globals.getNode('/controls/flight/vnav-enabled');
    myprops["/instrumentation/pfd/ils/has-loc"] = props.globals.getNode('/instrumentation/pfd/ils/has-loc');
    myprops["/it-autoflight/input/fpa"] = props.globals.getNode('/it-autoflight/input/fpa');
    myprops["/it-autoflight/input/vs"] = props.globals.getNode('/it-autoflight/input/vs');
    myprops["/it-autoflight/mode/arm"] = props.globals.getNode('/it-autoflight/mode/arm');
    myprops["/it-autoflight/mode/lat"] = props.globals.getNode('/it-autoflight/mode/lat');
    myprops["/it-autoflight/mode/thr"] = props.globals.getNode('/it-autoflight/mode/thr');
    myprops["/it-autoflight/mode/vert"] = props.globals.getNode('/it-autoflight/mode/vert');
    myprops["/it-autoflight/output/appr-armed"] = props.globals.getNode('/it-autoflight/output/appr-armed');
    myprops["/it-autoflight/output/lnav-armed"] = props.globals.getNode('/it-autoflight/output/lnav-armed');
    myprops["/it-autoflight/output/loc-armed"] = props.globals.getNode('/it-autoflight/output/loc-armed');

    # listeners
    setlistener("/it-autoflight/output/ap1", func (node) {
            myprops["ap-engaged"].setBoolValue(node.getBoolValue());
        }, 1, 0);
    setlistener("/it-autoflight/output/athr", func (node) {
            myprops["at-engaged"].setBoolValue(node.getBoolValue());
        }, 1, 0);

    setlistener(myprops["/it-autoflight/mode/vert"], func {
        updateFMAVert();
        updateFMASpeed();
    }, 1, 0);
    setlistener(myprops["/controls/flight/vnav-enabled"], updateFMAVert, 1, 0);
    setlistener(myprops["/it-autoflight/mode/thr"], updateFMASpeed, 1, 0);

    setlistener(myprops["/instrumentation/pfd/ils/has-loc"], updateFMALat, 1, 0);
    setlistener(myprops["/it-autoflight/mode/lat"], func {
        updateFMALat();
    }, 1, 0);
    setlistener(myprops["/it-autoflight/mode/arm"], updateFMALat, 1, 0);
    setlistener(myprops["/it-autoflight/output/lnav-armed"], updateFMALat, 1, 0);
    setlistener(myprops["/it-autoflight/output/loc-armed"], updateFMALat, 1, 0);

    setlistener(myprops["/it-autoflight/output/appr-armed"],
        func {
            updateFMAVert();
            updateFMALat();
        }, 1, 0);

    setlistener("/autopilot/autoland/armed-mode", updateApprArmed, 1, 0);
    setlistener("/autopilot/autoland/engaged-mode", updateApprEngaged, 1, 0);
});
