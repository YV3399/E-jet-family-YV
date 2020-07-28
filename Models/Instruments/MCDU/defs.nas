# Definitions / constants for MCDU

var lsks =
    { "L1": 1
    , "L2": 3
    , "L3": 5
    , "L4": 7
    , "L5": 9
    , "L6": 11
    , "R1": 2
    , "R2": 4
    , "R3": 6
    , "R4": 8
    , "R5": 10
    , "R6": 12
    };

var lskIndex = func (cmd) {
    if (contains(lsks, cmd)) {
        return lsks[cmd];
    }
    else {
        return 0;
    }
};

var isLSK = func (cmd) { return (lskIndex(cmd) != 0); }

var dials =
    { "INC1": 1
    , "INC2": 2
    , "INC3": 3
    , "INC4": 4
    , "DEC1": -1
    , "DEC2": -2
    , "DEC3": -3
    , "DEC4": -4
    };

var dialIndex = func (cmd) {
    if (contains(dials, cmd)) {
        return dials[cmd];
    }
    else {
        return 0;
    }
};

var isDial = func (cmd) { return (dialIndex(cmd) != 0); }

# -------------- CONSTANTS -------------- 

var mcdu_colors = [
    [1,1,1],
    [1,0,0],
    [1,1,0],
    [0,1,0],
    [0,1,1],
    [0,0.5,1],
    [1,0,1],
    [1,1,1],
];

var mcdu_white = 0;
var mcdu_red = 1;
var mcdu_yellow = 2;
var mcdu_green = 3;
var mcdu_cyan = 4;
var mcdu_blue = 5;
var mcdu_magenta = 6;

var mcdu_large = 0x10;

var mcdu_reverse = 0x20;

var cell_w = 18;
var cell_h = 27;
var cells_x = 24;
var cells_y = 13;
var num_cells = cells_x * cells_y;
var margin_left = 40;
var margin_top = 24;
var font_size_small = 20;
var font_size_large = 26;

var left_triangle = "◄";
var right_triangle = "►";
var left_right_arrow = "↔";
var up_down_arrow = "↕";
var black_square = "■";

var xpdrModeLabels = [
    "STBY",
    "ALT-OFF",
    "ALT-ON",
    "TA",
    "TA/RA",
];

var keyProps = {
    # Radios
    "NAV1A": "/instrumentation/nav[0]/frequencies/selected-mhz",
    "NAV1S": "/instrumentation/nav[0]/frequencies/standby-mhz",
    "NAV1ID": "/instrumentation/nav[0]/nav-id",
    "DME1H": "/instrumentation/dme[0]/hold",
    "NAV1AUTO": "/fms/radio/nav-auto[0]",
    "NAV2A": "/instrumentation/nav[1]/frequencies/selected-mhz",
    "NAV2S": "/instrumentation/nav[1]/frequencies/standby-mhz",
    "NAV2ID": "/instrumentation/nav[1]/nav-id",
    "DME2H": "/instrumentation/dme[1]/hold",
    "NAV2AUTO": "/fms/radio/nav-auto[1]",
    "COM1A": "/instrumentation/comm[0]/frequencies/selected-mhz",
    "COM1S": "/instrumentation/comm[0]/frequencies/standby-mhz",
    "COM2A": "/instrumentation/comm[1]/frequencies/selected-mhz",
    "COM2S": "/instrumentation/comm[1]/frequencies/standby-mhz",
    "ADF1A": "/instrumentation/adf[0]/frequencies/selected-khz",
    "ADF1S": "/instrumentation/adf[0]/frequencies/standby-khz",
    "ADF2A": "/instrumentation/adf[1]/frequencies/selected-khz",
    "ADF2S": "/instrumentation/adf[1]/frequencies/standby-khz",
    "XPDRA": "/instrumentation/transponder/id-code",
    "XPDRS": "/instrumentation/transponder/standby-id",
    "XPDRON": "/fms/radio/tcas-xpdr/enabled",
    "XPDRMD": "/fms/radio/tcas-xpdr/mode",
    "PALT": "/instrumentation/altimeter/pressure-alt-ft",
    "XPDRID": "/instrumentation/transponder/inputs/ident-btn",

    # Misc
    "ACTYPE": "/sim/aircraft",
    "ACMODEL": "/instrumentation/mcdu/ident/model",
    "ENGINE": "/sim/engine",
    "FGVER": "/sim/version/flightgear",
    "TAIL": "/sim/model/tail-number",
    "TRANSALT": "/controls/flight/transition-alt",

    # Weights and fuel
    "WGT-EMPTY": "/fdm/jsbsim/inertia/empty-weight-lbs",
    "WGT-CUR": "/fdm/jsbsim/inertia/weight-lbs",
    "WGT-ZF": "/fms/fuel/zfw-kg",
    "WGT-TO": "/fms/fuel/tow",
    "FUEL-CUR": "/consumables/fuel/total-fuel-kg",
    "FUEL-RESERVE": "/fms/fuel/reserve",
    "FUEL-TAKEOFF": "/fms/fuel/takeoff",
    "FUEL-LANDING": "/fms/fuel/landing",
    "FUEL-CONTINGENCY": "/fms/fuel/contingency",

    # Date/Time
    "ZHOUR": "/sim/time/utc/hour",
    "ZMIN": "/sim/time/utc/minute",
    "ZSEC": "/sim/time/utc/second",
    "ZDAY": "/sim/time/utc/day",
    "ZMON": "/sim/time/utc/month",
    "ZYEAR": "/sim/time/utc/year",

    # Position
    "CALLSIG": "/sim/multiplay/callsign",
    "FLTID": "/sim/multiplay/callsign", # TODO: separate property for this
    "GPSLAT": "/instrumentation/gps/indicated-latitude-deg",
    "GPSLON": "/instrumentation/gps/indicated-longitude-deg",
    "RAWLAT": "/position/latitude-deg",
    "RAWLON": "/position/longitude-deg",
    "POSLOADED1": "/fms/radio/position-loaded[0]",
    "POSLOADED2": "/fms/radio/position-loaded[1]",
    "POSLOADED3": "/fms/radio/position-loaded[2]",

    # Speed schedule
    "VDEP": "/controls/flight/speed-schedule/departure",
    "VCLBLO": "/controls/flight/speed-schedule/climb-below-10k",
    "CLBLOALT": "/controls/flight/speed-schedule/climb-limit-alt",
    "VCLB": "/controls/flight/speed-schedule/climb-kts",
    "MCLB": "/controls/flight/speed-schedule/climb-mach",
    "VCRZ": "/controls/flight/speed-schedule/cruise-kts",
    "MCRZ": "/controls/flight/speed-schedule/cruise-mach",
    "CRZ-MODE": "/controls/flight/speed-schedule/cruise-mode",
    "CRZ-ALT": "/autopilot/route-manager/cruise/altitude-ft",
    "MDES": "/controls/flight/speed-schedule/descent-mach",
    "VDES": "/controls/flight/speed-schedule/descent-kts",
    "VDESLO": "/controls/flight/speed-schedule/descent-below-10k",
    "DES-FPA": "/controls/flight/speed-schedule/descent-fpa",
    "PERF-MODE": "/controls/flight/perf-mode",

    # Pilot-selected vspeeds - departure
    "DEP-SEL-V1": "/controls/flight/vspeeds/departure/v1",
    "DEP-SEL-VR": "/controls/flight/vspeeds/departure/vr",
    "DEP-SEL-V2": "/controls/flight/vspeeds/departure/v2",
    "DEP-SEL-VFS": "/controls/flight/vspeeds/departure/vfs",
    "DEP-SEL-VF": "/controls/flight/vspeeds/departure/vf",
    "DEP-SEL-VF1": "/controls/flight/vspeeds/departure/vf1",
    "DEP-SEL-VF2": "/controls/flight/vspeeds/departure/vf2",
    "DEP-SEL-VF3": "/controls/flight/vspeeds/departure/vf3",
    "DEP-SEL-VF4": "/controls/flight/vspeeds/departure/vf4",

    # Pilot-selected vspeeds - approach
    "APP-SEL-VREF": "/controls/flight/vspeeds/approach/vref",
    "APP-SEL-VAPPR": "/controls/flight/vspeeds/approach/vappr",
    "APP-SEL-VAF1": "/controls/flight/vspeeds/approach/vaf1",
    "APP-SEL-VAF2": "/controls/flight/vspeeds/approach/vaf2",
    "APP-SEL-VAF3": "/controls/flight/vspeeds/approach/vaf3",
    "APP-SEL-VAF4": "/controls/flight/vspeeds/approach/vaf4",
    "APP-SEL-VAF5": "/controls/flight/vspeeds/approach/vaf5",
    "APP-SEL-VAF6": "/controls/flight/vspeeds/approach/vaf6",
    "APP-SEL-VAC": "/controls/flight/vspeeds/approach/vac",
    "APP-SEL-VFS": "/controls/flight/vspeeds/approach/vfs",

    # Effective vspeeds - departure
    "DEP-EFF-V1": "/fms/vspeeds-effective/departure/v1",
    "DEP-EFF-VR": "/fms/vspeeds-effective/departure/vr",
    "DEP-EFF-V2": "/fms/vspeeds-effective/departure/v2",
    "DEP-EFF-VFS": "/fms/vspeeds-effective/departure/vfs",
    "DEP-EFF-VF": "/fms/vspeeds-effective/departure/vf",
    "DEP-EFF-VF1": "/fms/vspeeds-effective/departure/vf1",
    "DEP-EFF-VF2": "/fms/vspeeds-effective/departure/vf2",
    "DEP-EFF-VF3": "/fms/vspeeds-effective/departure/vf3",
    "DEP-EFF-VF4": "/fms/vspeeds-effective/departure/vf4",

    # Effective vspeeds - approach
    "APP-EFF-VREF": "/fms/vspeeds-effective/approach/vref",
    "APP-EFF-VAPPR": "/fms/vspeeds-effective/approach/vappr",
    "APP-EFF-VAF1": "/fms/vspeeds-effective/approach/vaf1",
    "APP-EFF-VAF2": "/fms/vspeeds-effective/approach/vaf2",
    "APP-EFF-VAF3": "/fms/vspeeds-effective/approach/vaf3",
    "APP-EFF-VAF4": "/fms/vspeeds-effective/approach/vaf4",
    "APP-EFF-VAF5": "/fms/vspeeds-effective/approach/vaf5",
    "APP-EFF-VAF6": "/fms/vspeeds-effective/approach/vaf6",
    "APP-EFF-VAC": "/fms/vspeeds-effective/approach/vac",
    "APP-EFF-VFS": "/fms/vspeeds-effective/approach/vfs",

    # Takeoff parameters
    "TO-FLAPS": "/fms/takeoff-conditions/flaps",
    "TO-PITCH": "/fms/takeoff-conditions/pitch",
    "TO-RUNWAY-HEADING": "/fms/takeoff-conditions/runway-heading",
    "TO-RUNWAY-SLOPE": "/fms/takeoff-conditions/runway-slope",
    "TO-RUNWAY-CONDITION": "/fms/takeoff-conditions/runway-condition",
    "TO-RUNWAY-ELEVATION": "/fms/takeoff-conditions/runway-elevation",
    "TO-QNH": "/fms/takeoff-conditions/qnh",
    "TO-PRESSURE-ALT": "/fms/takeoff-conditions/pressure-alt",
    "TO-OAT": "/fms/takeoff-conditions/oat",
    "TO-WIND-DIR": "/fms/takeoff-conditions/wind-dir",
    "TO-WIND-SPEED": "/fms/takeoff-conditions/wind-speed",
    "TO-TRS-MODE": "/controls/flight/trs/to",

    # Landing parameters
    "APPROACH-CAT": "/fms/landing-conditions/approach-cat",
    "APPR-FLAPS": "/fms/landing-conditions/approach-flaps",
    "LANDING-FLAPS": "/fms/landing-conditions/landing-flaps",
    "LANDING-ICE": "/fms/landing-conditions/ice-accretion",
    "LANDING-OAT": "/fms/landing-conditions/oat",

    # Route
    "DEPARTURE-AIRPORT": "/autopilot/route-manager/departure/airport",
    "DEPARTURE-RUNWAY": "/autopilot/route-manager/departure/runway",
    "DEPARTURE-SID": "/autopilot/route-manager/departure/sid",
    "ARRIVAL-AIRPORT": "/autopilot/route-manager/destination/airport",
    "ARRIVAL-RUNWAY": "/autopilot/route-manager/destination/runway",
    "ARRIVAL-STAR": "/autopilot/route-manager/destination/star",
    "ARRIVAL-APPROACH": "/autopilot/route-manager/destination/approach",
};

var keyDefs = {
    "WGT-TO": func () { return getprop("/fdm/jsbsim/inertia/weight-lbs") * LB2KG; },
    "DEPARTURE-AIRPORT": func () {
        var apts = findAirportsWithinRange(4.0);
        if (size(apts) == 0) return nil;
        return apts[0].id;
    },
    # Pilot-selected vspeeds - departure
    "DEP-SEL-V1": 0,
    "DEP-SEL-VR": 0,
    "DEP-SEL-V2": 0,
    "DEP-SEL-VFS": 0,
    "DEP-SEL-VF": 0,
    "DEP-SEL-VF1": 0,
    "DEP-SEL-VF2": 0,
    "DEP-SEL-VF3": 0,
    "DEP-SEL-VF4": 0,

    # Pilot-selected vspeeds - approach
    "APP-SEL-VREF": 0,
    "APP-SEL-VAPPR": 0,
    "APP-SEL-VAF1": 0,
    "APP-SEL-VAF2": 0,
    "APP-SEL-VAF3": 0,
    "APP-SEL-VAF4": 0,
    "APP-SEL-VAF5": 0,
    "APP-SEL-VAF6": 0,
    "APP-SEL-VAC": 0,
    "APP-SEL-VFS": 0,

    # Effective vspeeds - departure
    "DEP-EFF-V1": 0,
    "DEP-EFF-VR": 0,
    "DEP-EFF-V2": 0,
    "DEP-EFF-VFS": 0,
    "DEP-EFF-VF": 0,
    "DEP-EFF-VF1": 0,
    "DEP-EFF-VF2": 0,
    "DEP-EFF-VF3": 0,
    "DEP-EFF-VF4": 0,

    # Effective vspeeds - approach
    "APP-EFF-VREF": 0,
    "APP-EFF-VAPPR": 0,
    "APP-EFF-VAF1": 0,
    "APP-EFF-VAF2": 0,
    "APP-EFF-VAF3": 0,
    "APP-EFF-VAF4": 0,
    "APP-EFF-VAF5": 0,
    "APP-EFF-VAF6": 0,
    "APP-EFF-VAC": 0,
    "APP-EFF-VFS": 0,
};
