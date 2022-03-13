## AUTOPILOT
############

# Selecting a different nav source on the active side, or switching sides,
# when the autopilot is in LNAV or NAV mode, reverts the autopilot to HDG
# mode.

var LATMODE_HDGSEL = 0;
var LATMODE_LNAV = 1;
var LATMODE_VORLOC = 2;
var LATMODE_HDGHLD = 3; # Old wing leveler; we use 6 instead now
var LATMODE_ROLL = 6;

var VERTMODE_ALT = 0;
var VERTMODE_VS = 1;
var VERTMODE_ILS = 2;
var VERTMODE_FLCH = 4;
var VERTMODE_FPA = 5;

var checkNavDisengage = func () {
    var side = getprop("/controls/flight/nav-src/side");
    var navsrc = getprop("/instrumentation/pfd[" ~ side ~ "]/nav-src");
    var apLat = getprop("/it-autoflight/output/lat");
    var apNav2 = getprop("/it-autoflight/input/use-nav2-radio");
    var apNavsrc = navsrc;
    setprop("/controls/flight/nav-src/lat-mode", (navsrc == 0) ? 1 : 2);
    setprop("/controls/flight/nav-src/nav2", (navsrc == 2) ? 1 : 0);
    if (apLat == 1) {
        # LNAV
        apNavsrc = 0;
    }
    else if (apLat == 2) {
        # VOR/LOC
        if (apNav2) {
            apNavsrc = 2;
        }
        else {
            apNavsrc = 1;
        }
    }
    else {
        # Some other mode - no need to disengage anything
        return;
    }
    if (apNavsrc != navsrc) {
        # disengage!
        # (select HDG HOLD)
        setprop("/it-autoflight/input/lat", 3);
    }
};

# once to initialize, and then on each change of any of the inputs.
checkNavDisengage();
setlistener("/controls/flight/nav-src/side", checkNavDisengage);
setlistener("/instrumentation/pfd[0]/nav-src", checkNavDisengage);
setlistener("/instrumentation/pfd[1]/nav-src", checkNavDisengage);

var apActiveProp = props.globals.getNode('it-autoflight/output/ap1', 1);
var apControlProp1 = props.globals.getNode('it-autoflight/input/ap1', 1);
var apControlProp2 = props.globals.getNode('it-autoflight/input/ap2', 1);
var apWarningProp = props.globals.getNode('instrumentation/annun/ap-disconnect-warning', 1);

var atActiveProp = props.globals.getNode('it-autoflight/output/athr', 1);
var atControlProp = props.globals.getNode('it-autoflight/input/athr', 1);
var atWarningProp = props.globals.getNode('instrumentation/annun/at-disconnect-warning', 1);

var apLatModeInProp = props.globals.getNode('it-autoflight/input/lat', 1);
var apLatModeOutProp = props.globals.getNode('it-autoflight/output/lat', 1);
var apRollProp = props.globals.getNode('it-autoflight/input/roll', 1);
var rollAngleProp = props.globals.getNode('orientation/roll-deg', 1);
var apUseNav2Prop = props.globals.getNode('it-autoflight/input/use-nav2-radio', 1);
var apVertModeInProp = props.globals.getNode('it-autoflight/input/vert', 1);
var apVertModeOutProp = props.globals.getNode('it-autoflight/output/vert', 1);
var apApprArmedProp = props.globals.getNode('it-autoflight/output/appr-armed', 1);
var navSourceLatModeProp = props.globals.getNode('controls/flight/nav-src/lat-mode', 1);
var navSourceNav2Prop = props.globals.getNode('controls/flight/nav-src/nav2', 1);
var itafCWSProp = props.globals.getNode('it-autoflight/output/cws', 1);

var syncRoll = func () {
    # Calculate target bank angle:
    # - If current bank angle is between 0° and 6°, keep wings level.
    # - If current bank angle is between 6° and 35°, hold current bank angle
    # - If current bank angle is larger than 35°, hold 35° bank
    var currentRoll = rollAngleProp.getDoubleValue();
    if (currentRoll > 35.0) {
        # Right bank limit exceeded
        apRollProp.setValue(35.0);
    }
    elsif (currentRoll < -35.0) {
        # Left bank limit exceeded
        apRollProp.setValue(-35.0);
    }
    elsif (math.abs(currentRoll) > 6.0) {
        # Hold current bank
        apRollProp.setValue(currentRoll);
    }
    else {
        # Wings level
        apRollProp.setValue(0.0);
    }
}

var activateRollMode = func () {
    apLatModeInProp.setValue(LATMODE_ROLL);
    syncRoll();
};

var activateHdgMode = func () {
    apLatModeInProp.setValue(LATMODE_HDGSEL);
};

var activateApprMode = func () {
    # TODO: check approach type
    apVertModeInProp.setValue(VERTMODE_ILS);
    apLatModeInProp.setValue(LATMODE_VORLOC);
};

var activateNavMode = func () {
    var navSrc = navSourceLatModeProp.getValue();
    var whichNav = navSourceNav2Prop.getValue();
    apUseNav2Prop.setValue(whichNav);
    apLatModeInProp.setValue(navSrc);
};

var deactivateApprMode = func () {
    apVertModeInProp.setValue(VERTMODE_ALT);
    # Always select wings level, do not synchronize roll
    apVertModeInProp.setValue(LATMODE_ROLL);
    apRollProp.setValue(0.0);
};

var hdgButton = func () {
    var currentMode = apLatModeOutProp.getValue();
    if (currentMode == LATMODE_ROLL)
        activateHdgMode();
    else
        activateRollMode();
};

var navButton = func () {
    var currentMode = apLatModeOutProp.getValue();
    if (currentMode == LATMODE_LNAV or
        currentMode == LATMODE_VORLOC)
        activateHdgMode();
    else
        activateNavMode();
};

var apprButton = func () {
    var apprArmed = apApprArmedProp.getBoolValue();
    var latMode = apLatModeOutProp.getValue();
    var vertMode = apVertModeInProp.getValue();
    if (apprArmed or vertMode == VERTMODE_ILS) {
        deactivateApprMode();
    }
    else {
        activateApprMode();
    }
};

var syncVert = func () {
    var vertMode = apVertModeOutProp.getValue();
    if (vertMode == VERTMODE_VS or vertMode == VERTMODE_FPA) {
        # Set the mode again to trigger a sync
        apVertModeInProp.setValue(vertMode);
    }
};

setlistener("/controls/flight/tcs", func (node) {
    if (!node.getBoolValue()) {
        syncRoll();
        syncVert();
    }
    itafCWSProp.setValue(node.getValue());
}, 1, 0);

setlistener("/controls/autoflight/disconnect", func (node) {
    if (node.getBoolValue()) {
        apWarningProp.setBoolValue(apActiveProp.getBoolValue());
        apControlProp1.setBoolValue(0);
        apControlProp2.setBoolValue(0);
    }
}, 1, 0);
setlistener("/it-autoflight/output/ap1", func (node) {
    if (node.getBoolValue()) {
        apWarningProp.setBoolValue(0);
    }
}, 1, 0);
setlistener("/controls/autoflight/at-disconnect", func (node) {
    if (node.getBoolValue()) {
        atWarningProp.setBoolValue(atActiveProp.getBoolValue());
        atControlProp.setBoolValue(0);
    }
}, 1, 0);
setlistener("/it-autoflight/output/at", func (node) {
    if (node.getBoolValue()) {
        atWarningProp.setBoolValue(0);
    }
}, 1, 0);

setlistener('autopilot/disconnect-conditions/control-input-filtered', func (node) {
    if (node.getDoubleValue() > 0.99999) {
        if (getprop('it-autoflight/output/ap1')) {
            setprop('controls/autoflight/disconnect', 1);
            setprop('controls/autoflight/disconnect', 0);
        }
    }
}, 1, 0);
