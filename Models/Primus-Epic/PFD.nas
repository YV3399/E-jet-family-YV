# E-jet-family PFD by D-ECHO based on
# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

# sources:
# http://www.smartcockpit.com/docs/Embraer_190-Powerplant.pdf
# http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf
# http://www.smartcockpit.com/docs/Embraer_190-APU.pdf

# HSI: E190 AOM p1733
# Bearing Source Selector: E190 AOM p1764

var pfd = [nil, nil];
var PFD_master = [nil, nil];
var PFD_display = [nil, nil];

setprop("/systems/electrical/outputs/efis", 0);

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

var odoDigitRaw = func(v, p) {
    if (p == 0) {
        var dy = math.fmod(v, 1.0);
        var n = math.floor(math.fmod(v, 10.0));
        return [dy, n];
    }
    else {
        var parent = odoDigitRaw(v, p - 1);
        var e = math.pow(10.0, p);
        var dyp = parent[0];
        var np = parent[1];
        var dy = 0.0;
        if (np == 9) {
            dy = dyp;
        }
        var n = math.floor(math.fmod(v / e, 10.0));
        return [dy, n]
    }
};

var odoDigit = func(v, p) {
    var o = odoDigitRaw(v, p);
    return o[0] + o[1];
};

var PFDCanvas = {
    new: func(canvas_group, file, index=0) {
        var m = { parents: [PFDCanvas] };
        m.init(canvas_group, file);
        m.props = {};
        m.props["/acars/telex/unread"] = props.globals.getNode("/acars/telex/unread", 1);
        m.props["/autopilot/autoland/armed-mode"] = props.globals.getNode("/autopilot/autoland/armed-mode");
        m.props["/autopilot/autoland/engaged-mode"] = props.globals.getNode("/autopilot/autoland/engaged-mode");
        m.props["/autopilot/route-manager/active"] = props.globals.getNode("/autopilot/route-manager/active");
        m.props["/autopilot/route-manager/wp/dist"] = props.globals.getNode("/autopilot/route-manager/wp/dist");
        m.props["/autopilot/route-manager/wp/eta-seconds"] = props.globals.getNode("/autopilot/route-manager/wp/eta-seconds");
        m.props["/autopilot/route-manager/wp/id"] = props.globals.getNode("/autopilot/route-manager/wp/id");
        m.props["/controls/flight/flaps"] = props.globals.getNode("/controls/flight/flaps");
        m.props["/controls/flight/nav-src/side"] = props.globals.getNode("/controls/flight/nav-src/side");
        m.props["/controls/flight/selected-alt"] = props.globals.getNode("/controls/flight/selected-alt");
        m.props["/controls/flight/speed-mode"] = props.globals.getNode("/controls/flight/speed-mode");
        m.props["/controls/flight/vnav-enabled"] = props.globals.getNode("/controls/flight/vnav-enabled");
        m.props["/cpdlc/unread"] = props.globals.getNode("/cpdlc/unread", 1);
        m.props["/environment/wind-from-heading-deg"] = props.globals.getNode("/environment/wind-from-heading-deg");
        m.props["/environment/wind-speed-kt"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/wind-speed-kt");
        m.props["/fms/speed-limits/green-dot-kt"] = props.globals.getNode("/fms/speed-limits/green-dot-kt");
        m.props["/fms/speed-limits/vmo-effective"] = props.globals.getNode("/fms/speed-limits/vmo-effective");
        m.props["/fms/speed-limits/vstall-kt"] = props.globals.getNode("/fms/speed-limits/vstall-kt");
        m.props["/fms/speed-limits/vwarn-kt"] = props.globals.getNode("/fms/speed-limits/vwarn-kt");
        m.props["/fms/vnav/alt-deviation"] = props.globals.getNode("/fms/vnav/alt-deviation");
        m.props["/fms/vspeeds-effective/approach/vac"] = props.globals.getNode("/fms/vspeeds-effective/approach/vac");
        m.props["/fms/vspeeds-effective/approach/vap"] = props.globals.getNode("/fms/vspeeds-effective/approach/vap");
        m.props["/fms/vspeeds-effective/approach/vref"] = props.globals.getNode("/fms/vspeeds-effective/approach/vref");
        m.props["/fms/vspeeds-effective/departure/v1"] = props.globals.getNode("/fms/vspeeds-effective/departure/v1");
        m.props["/fms/vspeeds-effective/departure/v2"] = props.globals.getNode("/fms/vspeeds-effective/departure/v2");
        m.props["/fms/vspeeds-effective/departure/vf1"] = props.globals.getNode("/fms/vspeeds-effective/departure/vf1");
        m.props["/fms/vspeeds-effective/departure/vf2"] = props.globals.getNode("/fms/vspeeds-effective/departure/vf2");
        m.props["/fms/vspeeds-effective/departure/vf3"] = props.globals.getNode("/fms/vspeeds-effective/departure/vf3");
        m.props["/fms/vspeeds-effective/departure/vf4"] = props.globals.getNode("/fms/vspeeds-effective/departure/vf4");
        m.props["/fms/vspeeds-effective/departure/vf"] = props.globals.getNode("/fms/vspeeds-effective/departure/vf");
        m.props["/fms/vspeeds-effective/departure/vfs"] = props.globals.getNode("/fms/vspeeds-effective/departure/vfs");
        m.props["/fms/vspeeds-effective/departure/vr"] = props.globals.getNode("/fms/vspeeds-effective/departure/vr");
        m.props["/gear/gear/wow"] = props.globals.getNode("/gear/gear/wow");
        m.props["/instrumentation/airspeed-indicator/indicated-mach"] = props.globals.getNode("/instrumentation/airspeed-indicator/indicated-mach");
        m.props["/instrumentation/airspeed-indicator/indicated-speed-kt"] = props.globals.getNode("/instrumentation/airspeed-indicator/indicated-speed-kt");
        m.props["/instrumentation/altimeter/indicated-altitude-ft"] = props.globals.getNode("/instrumentation/altimeter[" ~ index ~ "]/indicated-altitude-ft");
        m.props["/instrumentation/altimeter/setting-hpa"] = props.globals.getNode("/instrumentation/altimeter[" ~ index ~ "]/setting-hpa");
        m.props["/instrumentation/altimeter/setting-inhg"] = props.globals.getNode("/instrumentation/altimeter[" ~ index ~ "]/setting-inhg");
        m.props["/instrumentation/chrono/elapsed_time/total"] = props.globals.getNode("/instrumentation/chrono/elapsed_time/total");
        m.props["/instrumentation/comm[0]/frequencies/selected-mhz"] = props.globals.getNode("/instrumentation/comm[0]/frequencies/selected-mhz");
        m.props["/instrumentation/comm[0]/frequencies/standby-mhz"] = props.globals.getNode("/instrumentation/comm[0]/frequencies/standby-mhz");
        m.props["/instrumentation/dme[0]/frequencies/selected-mhz"] = props.globals.getNode("/instrumentation/dme[0]/frequencies/selected-mhz");
        m.props["/instrumentation/dme[0]/frequencies/source"] = props.globals.getNode("/instrumentation/dme[0]/frequencies/source");
        m.props["/instrumentation/dme[0]/indicated-distance-nm"] = props.globals.getNode("/instrumentation/dme[0]/indicated-distance-nm");
        m.props["/instrumentation/dme[0]/indicated-time-min"] = props.globals.getNode("/instrumentation/dme[0]/indicated-time-min");
        m.props["/instrumentation/dme[0]/in-range"] = props.globals.getNode("/instrumentation/dme[0]/in-range");
        m.props["/instrumentation/dme[1]/frequencies/selected-mhz"] = props.globals.getNode("/instrumentation/dme[1]/frequencies/selected-mhz");
        m.props["/instrumentation/dme[1]/frequencies/source"] = props.globals.getNode("/instrumentation/dme[1]/frequencies/source");
        m.props["/instrumentation/dme[1]/indicated-distance-nm"] = props.globals.getNode("/instrumentation/dme[1]/indicated-distance-nm");
        m.props["/instrumentation/dme[1]/indicated-time-min"] = props.globals.getNode("/instrumentation/dme[1]/indicated-time-min");
        m.props["/instrumentation/dme[1]/in-range"] = props.globals.getNode("/instrumentation/dme[1]/in-range");
        m.props["/instrumentation/eicas/master/caution"] = props.globals.getNode("/instrumentation/eicas/master/caution");
        m.props["/instrumentation/eicas/master/warning"] = props.globals.getNode("/instrumentation/eicas/master/warning");
        m.props["/instrumentation/gps/cdi-deflection"] = props.globals.getNode("/instrumentation/gps/cdi-deflection");
        m.props["/instrumentation/gps/desired-course-deg"] = props.globals.getNode("/instrumentation/gps/desired-course-deg");
        m.props["/instrumentation/iru/outputs/valid-att"] = props.globals.getNode("/instrumentation/iru[" ~ index ~ "]/outputs/valid-att");
        m.props["/instrumentation/iru/outputs/valid"] = props.globals.getNode("/instrumentation/iru[" ~ index ~ "]/outputs/valid");
        m.props["/instrumentation/marker-beacon/inner"] = props.globals.getNode("/instrumentation/marker-beacon/inner");
        m.props["/instrumentation/marker-beacon/middle"] = props.globals.getNode("/instrumentation/marker-beacon/middle");
        m.props["/instrumentation/marker-beacon/outer"] = props.globals.getNode("/instrumentation/marker-beacon/outer");
        m.props["/instrumentation/nav[0]/frequencies/selected-mhz"] = props.globals.getNode("/instrumentation/nav[0]/frequencies/selected-mhz");
        m.props["/instrumentation/nav[0]/frequencies/standby-mhz"] = props.globals.getNode("/instrumentation/nav[0]/frequencies/standby-mhz");
        m.props["/instrumentation/nav[0]/from-flag"] = props.globals.getNode("/instrumentation/nav[0]/from-flag");
        m.props["/instrumentation/nav[0]/gs-in-range"] = props.globals.getNode("/instrumentation/nav[0]/gs-in-range");
        m.props["/instrumentation/nav[0]/gs-needle-deflection-norm"] = props.globals.getNode("/instrumentation/nav[0]/gs-needle-deflection-norm");
        m.props["/instrumentation/nav[0]/has-gs"] = props.globals.getNode("/instrumentation/nav[0]/has-gs");
        m.props["/instrumentation/nav[0]/heading-needle-deflection-norm"] = props.globals.getNode("/instrumentation/nav[0]/heading-needle-deflection-norm");
        m.props["/instrumentation/nav[0]/in-range"] = props.globals.getNode("/instrumentation/nav[0]/in-range");
        m.props["/instrumentation/nav[0]/nav-id"] = props.globals.getNode("/instrumentation/nav[0]/nav-id");
        m.props["/instrumentation/nav[0]/nav-loc"] = props.globals.getNode("/instrumentation/nav[0]/nav-loc");
        m.props["/instrumentation/nav[0]/radials/selected-deg"] = props.globals.getNode("/instrumentation/nav[0]/radials/selected-deg");
        m.props["/instrumentation/nav[1]/frequencies/selected-mhz"] = props.globals.getNode("/instrumentation/nav[1]/frequencies/selected-mhz");
        m.props["/instrumentation/nav[1]/frequencies/standby-mhz"] = props.globals.getNode("/instrumentation/nav[1]/frequencies/standby-mhz");
        m.props["/instrumentation/nav[1]/from-flag"] = props.globals.getNode("/instrumentation/nav[1]/from-flag");
        m.props["/instrumentation/nav[1]/gs-in-range"] = props.globals.getNode("/instrumentation/nav[1]/gs-in-range");
        m.props["/instrumentation/nav[1]/gs-needle-deflection-norm"] = props.globals.getNode("/instrumentation/nav[1]/gs-needle-deflection-norm");
        m.props["/instrumentation/nav[1]/has-gs"] = props.globals.getNode("/instrumentation/nav[1]/has-gs");
        m.props["/instrumentation/nav[1]/heading-needle-deflection-norm"] = props.globals.getNode("/instrumentation/nav[1]/heading-needle-deflection-norm");
        m.props["/instrumentation/nav[1]/in-range"] = props.globals.getNode("/instrumentation/nav[1]/in-range");
        m.props["/instrumentation/nav[1]/nav-id"] = props.globals.getNode("/instrumentation/nav[1]/nav-id");
        m.props["/instrumentation/nav[1]/nav-loc"] = props.globals.getNode("/instrumentation/nav[1]/nav-loc");
        m.props["/instrumentation/nav[1]/radials/selected-deg"] = props.globals.getNode("/instrumentation/nav[1]/radials/selected-deg");
        m.props["/instrumentation/pfd/airspeed-alive"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/airspeed-alive");
        m.props["/instrumentation/pfd/airspeed-lookahead-10s"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/airspeed-lookahead-10s");
        m.props["/instrumentation/pfd/alt-bug-offset"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/alt-bug-offset");
        m.props["/instrumentation/pfd/alt-tape-offset"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/alt-tape-offset");
        m.props["/instrumentation/pfd/alt-tape-thousands"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/alt-tape-thousands");
        m.props["/instrumentation/pfd/bearing[0]/bearing"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[0]/bearing");
        m.props["/instrumentation/pfd/bearing[0]/source"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[0]/source");
        m.props["/instrumentation/pfd/bearing[0]/visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[0]/visible");
        m.props["/instrumentation/pfd/bearing[1]/bearing"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[1]/bearing");
        m.props["/instrumentation/pfd/bearing[1]/source"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[1]/source");
        m.props["/instrumentation/pfd/bearing[1]/visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[1]/visible");
        m.props["/instrumentation/pfd/blink-state"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/blink-state");
        m.props["/instrumentation/pfd/dme/dist10"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/dme/dist10");
        m.props["/instrumentation/pfd/dme/ete"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/dme/ete");
        m.props["/instrumentation/pfd/dme/ete-unit"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/dme/ete-unit");
        m.props["/instrumentation/pfd/dme/hold"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/dme/hold");
        m.props["/instrumentation/pfd/dme/in-range"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/dme/in-range");
        m.props["/instrumentation/pfd/fd/lat-offset-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fd/lat-offset-deg");
        m.props["/instrumentation/pfd/fd/vert-offset-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fd/vert-offset-deg");
        m.props["/instrumentation/pfd/fd/pitch-scale"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fd/pitch-scale");
        m.props["/instrumentation/pfd/fd/pitch-bar-scale"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fd/pitch-bar-scale");
        m.props["/instrumentation/pfd/fma/ap"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fma/ap");
        m.props["/instrumentation/pfd/fma/at"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fma/at");
        m.props["/instrumentation/pfd/groundspeed-kt"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/groundspeed-kt");
        m.props["/instrumentation/pfd/hsi/deflection"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/hsi/deflection");
        m.props["/instrumentation/pfd/hsi/from-flag"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/hsi/from-flag");
        m.props["/instrumentation/pfd/hsi/heading"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/hsi/heading");
        m.props["/instrumentation/pfd/ils/gs-in-range"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/gs-in-range");
        m.props["/instrumentation/pfd/ils/gs-needle"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/gs-needle");
        m.props["/instrumentation/pfd/ils/has-gs"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/has-gs");
        m.props["/instrumentation/pfd/ils/has-loc"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/has-loc");
        m.props["/instrumentation/pfd/ils/loc-in-range"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/loc-in-range");
        m.props["/instrumentation/pfd/ils/loc-needle"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/loc-needle");
        m.props["/instrumentation/pfd/ils/source"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/source");
        m.props["/instrumentation/pfd/minimums-baro"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-baro");
        m.props["/instrumentation/pfd/minimums-decision-altitude"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-decision-altitude");
        m.props["/instrumentation/pfd/minimums-indicator-visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-indicator-visible");
        m.props["/instrumentation/pfd/minimums-mode"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-mode");
        m.props["/instrumentation/pfd/minimums-radio"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-radio");
        m.props["/instrumentation/pfd/minimums-visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-visible");
        m.props["/instrumentation/pfd/nav/course-source"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav/course-source");
        m.props["/instrumentation/pfd/nav/course-source-type"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav/course-source-type");
        m.props["/instrumentation/pfd/nav/dme-source"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav/dme-source");
        m.props["/instrumentation/pfd/nav/selected-radial"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav/selected-radial");
        m.props["/instrumentation/pfd/nav-src"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav-src");
        m.props["/instrumentation/pfd/pitch-scale"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/pitch-scale");
        m.props["/instrumentation/pfd/fpa-pitch-scale"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fpa-pitch-scale");
        m.props["/instrumentation/pfd/fpa-scale"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fpa-scale");
        m.props["/instrumentation/pfd/preview"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/preview");
        m.props["/instrumentation/pfd/qnh-mode"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/qnh-mode");
        m.props["/instrumentation/pfd/radio-altimeter-visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/radio-altimeter-visible");
        m.props["/instrumentation/pfd/radio-alt"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/radio-alt");
        m.props["/instrumentation/pfd/track-error-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/track-error-deg");
        m.props["/instrumentation/pfd/vsi-needle-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/vsi-needle-deg");
        m.props["/instrumentation/pfd/vsi-target-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/vsi-target-deg");
        m.props["/instrumentation/pfd/waypoint/dist10"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/waypoint/dist10");
        m.props["/instrumentation/pfd/waypoint/ete"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/waypoint/ete");
        m.props["/instrumentation/pfd/waypoint/ete-unit"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/waypoint/ete-unit");
        m.props["/instrumentation/slip-skid-ball/indicated-slip-skid"] = props.globals.getNode("/instrumentation/slip-skid-ball/indicated-slip-skid");
        m.props["/instrumentation/tcas/inputs/mode"] = props.globals.getNode("/instrumentation/tcas/inputs/mode");
        m.props["/instrumentation/vertical-speed-indicator/indicated-speed-fpm"] = props.globals.getNode("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
        m.props["/it-autoflight/fd/pitch-bar"] = props.globals.getNode("/it-autoflight/fd/pitch-bar");
        m.props["/it-autoflight/fd/roll-bar"] = props.globals.getNode("/it-autoflight/fd/roll-bar");
        m.props["/it-autoflight/input/alt"] = props.globals.getNode("/it-autoflight/input/alt");
        m.props["/it-autoflight/input/fpa"] = props.globals.getNode("/it-autoflight/input/fpa");
        m.props["/it-autoflight/input/hdg"] = props.globals.getNode("/it-autoflight/input/hdg");
        m.props["/it-autoflight/input/kts-mach"] = props.globals.getNode("/it-autoflight/input/kts-mach");
        m.props["/it-autoflight/input/kts"] = props.globals.getNode("/it-autoflight/input/kts");
        m.props["/it-autoflight/input/mach"] = props.globals.getNode("/it-autoflight/input/mach");
        m.props["/it-autoflight/input/vs"] = props.globals.getNode("/it-autoflight/input/vs");
        m.props["/it-autoflight/mode/arm"] = props.globals.getNode("/it-autoflight/mode/arm");
        m.props["/it-autoflight/mode/lat"] = props.globals.getNode("/it-autoflight/mode/lat");
        m.props["/it-autoflight/mode/thr"] = props.globals.getNode("/it-autoflight/mode/thr");
        m.props["/it-autoflight/mode/vert"] = props.globals.getNode("/it-autoflight/mode/vert");
        m.props["/it-autoflight/output/ap1"] = props.globals.getNode("/it-autoflight/output/ap1");
        m.props["/it-autoflight/output/appr-armed"] = props.globals.getNode("/it-autoflight/output/appr-armed");
        m.props["/it-autoflight/output/athr"] = props.globals.getNode("/it-autoflight/output/athr");
        m.props["/it-autoflight/output/fd"] = props.globals.getNode("/it-autoflight/output/fd" ~ (index + 1));
        m.props["/it-autoflight/output/lnav-armed"] = props.globals.getNode("/it-autoflight/output/lnav-armed");
        m.props["/it-autoflight/output/loc-armed"] = props.globals.getNode("/it-autoflight/output/loc-armed");
        m.props["/orientation/heading-deg"] = props.globals.getNode("/orientation/heading-deg");
        m.props["/orientation/heading-magnetic-deg"] = props.globals.getNode("/orientation/heading-magnetic-deg");
        m.props["/orientation/roll-deg"] = props.globals.getNode("/orientation/roll-deg");
        m.props["/position/gear-agl-ft"] = props.globals.getNode("/position/gear-agl-ft");
        m.props["/velocities/groundspeed-kt"] = props.globals.getNode("/velocities/groundspeed-kt");
        m.ilscolor = [0,1,0];
        m.listeners = [];
        m.dme_id_listener = nil;

        return m;
    },

    init: func(canvas_group, file) {
        var font_mapper = func(family, weight) {
            return "e190.ttf";
        };


        canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

        var svg_keys = me.getKeys();

        foreach(var key; svg_keys) {
            me[key] = canvas_group.getElementById(key);
            var svg_keys = me.getKeys();
            foreach (var key; svg_keys) {
            me[key] = canvas_group.getElementById(key);
            if (me[key] == nil) {
                printf("Key not found: %s", key);
            }
            var clip_el = canvas_group.getElementById(key ~ "_clip");
            if (clip_el != nil) {
                clip_el.setVisible(0);
                var tran_rect = clip_el.getTransformedBounds();
                var clip_rect = sprintf("rect(%d,%d, %d,%d)",
                tran_rect[1], # 0 ys
                tran_rect[2], # 1 xe
                tran_rect[3], # 2 ye
                tran_rect[0]); #3 xs
                #   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
                me[key].set("clip", clip_rect);
                me[key].set("clip-frame", canvas.Element.PARENT);
            }
            }
        }

        me.h_trans = me["horizon"].createTransform();
        me.h_rot = me["horizon"].createTransform();

        me.page = canvas_group;

        return me;
    },

    getKeys: func() {
        return [
            "airspeed.bug",
            "airspeed.bug_clip",
            "alt.100",
            "alt.1000",
            "alt.10000",
            "alt.10000.neg",
            "alt.10000.tape",
            "alt.10000.z",
            "alt.10000.zero",
            "alt.1000_clip",
            "alt.1000.neg",
            "alt.1000.tape",
            "alt.1000.z",
            "alt.1000.zero",
            "alt.100_clip",
            "alt.100.neg",
            "alt.100.tape",
            "alt.100.z",
            "altNumHigh1",
            "altNumHigh2",
            "altNumLow1",
            "alt.rollingdigits",
            "alt.rollingdigits_clip",
            "alt.rollingdigits.neg",
            "alt.rollingdigits.pos",
            "alt.rollingdigits.zero",
            "alt.tape",
            "alt.tape.container",
            "alt.tape.container_clip",
            "alt.bug",
            "asi.1",
            "asi.10",
            "asi.10.0",
            "asi.100",
            "asi.100_clip",
            "asi.10.9",
            "asi.10_clip",
            "asi.10.z",
            "asi.1_clip",
            "asi.preview-v1.digital",
            "asi.preview-v2.digital",
            "asi.preview-vfs.digital",
            "asi.preview-vr.digital",
            "asi.tape",
            "asi.tape_clip",
            "asi.vspeeds",
            "atc.indicator",
            "barberpole",
            "chrono.digital",
            "compass",
            "compass.numbers",
            "dlk.indicator",
            "dme",
            "dme.dist",
            "dme.ete",
            "dme.eteunit",
            "dme.hold",
            "dme.id",
            "dme.selection",
            "eicas.indicator",
            "eicas.indicator.bg",
            "failure.att",
            "failure.hdg",
            "fd.pitch",
            "fd.roll",
            "fd.bars",
            "fd.icon",
            "fma.ap",
            "fma.ap.bg",
            "fma.appr",
            "fma.apprarmed",
            "fma.at",
            "fma.at.bg",
            "fma.lat",
            "fma.lat.bg",
            "fma.latarmed",
            "fma.spd",
            "fma.spdarmed",
            "fma.spdarmed.minor",
            "fma.spd.minor",
            "fma.src.arrow",
            "fma.vert",
            "fma.vert.bg",
            "fma.vertarmed",
            "fpa.target",
            "fpa.target.digital",
            "fpv",
            "greendot",
            "groundspeed",
            "heading.digital",
            "horizon",
            "horizon_clip",
            "horizon.ground",
            "hsi.dots",
            "hsi.from",
            "hsi.label.circle",
            "hsi.label.diamond",
            "hsi.nav1",
            "hsi.nav1track",
            "hsi.pointer.circle",
            "hsi.pointer.diamond",
            "hsi.to",
            "ils.fmsloc",
            "ils.fmsvert",
            "ils.gsneedle",
            "ils.locneedle",
            "mach.digital",
            "marker.inner",
            "marker.middle",
            "marker.outer",
            "minimums",
            "minimums.barora",
            "minimums.digital",
            "minimums.indicator",
            "nav1.act",
            "nav1.sby",
            "navsrc.preview",
            "navsrc.preview.id",
            "navsrc.preview.selection",
            "navsrc.primary",
            "navsrc.primary.id",
            "navsrc.primary.selection",
            "QNH.digital",
            "QNH.unit",
            "radioalt",
            "radioalt.digital",
            "roll.pointer",
            "selectedalt.digital100",
            "selectedcourse.digital",
            "selectedheading.digital",
            "selectedheading.pointer",
            "selectedspeed.digital",
            "selectedvspeed.digital",
            "slip.pointer",
            "speedbar.amber",
            "speedbar.red",
            "speederror.vector",
            "speedref.v1",
            "speedref.v2",
            "speedref.vac",
            "speedref.vappr",
            "speedref.vf",
            "speedref.vfs",
            "speedref.vr",
            "speedref.vref",
            "speedtrend.vector",
            "speedtrend.pointer",
            "tcas.warning",
            "vhf1.act",
            "vhf1.sby",
            "VNAV.constraints1",
            "VNAV.constraints1.abovebar",
            "VNAV.constraints1.belowbar",
            "VNAV.constraints1.text",
            "VNAV.constraints2",
            "VNAV.constraints2.above",
            "VNAV.constraints2.bars",
            "VNAV.constraints2.below",
            "VNAV.constraints2.text",
            "VS.digital",
            "VS.digital.wrapper",
            "vs.needle",
            "vs.needle.current",
            "vs.needle.target",
            "vs.needle_clip",
            "waypoint",
            "waypoint.dist",
            "waypoint.ete",
            "waypoint.eteunit",
            "waypoint.id",
            "wind.kt",
            "wind.pointer",
            "wind.pointer.wrapper",
        ];
    },

    deleteListeners: func () {
        foreach (var ls; me.listeners) {
            removelistener(ls);
        }
        me.listeners = [];
        if (me.dme_id_listener != nil) {
            removelistener(me.dme_id_listener);
            me.dme_id_listener = nil;
        }
    },

    setupListeners: func () {
        var self = me;

        me.deleteListeners();

        # bearing pointers / sources
        append(me.listeners, setlistener(me.props["/instrumentation/pfd/bearing[0]/source"], func (node) {
            var hsiLabelText = ["----", "VOR1", "ADF1", "FMS1"];
            var mode = node.getValue();
            self["hsi.label.circle"].setText(hsiLabelText[mode]);
        }, 1, 0));
        append(me.listeners, setlistener(me.props["/instrumentation/pfd/bearing[1]/source"], func (node) {
            var hsiLabelText = ["----", "VOR2", "ADF2", "FMS2"];
            var mode = node.getValue();
            self["hsi.label.diamond"].setText(hsiLabelText[mode]);
        }, 1, 0));

        # selected heading
        append(me.listeners, setlistener(me.props["/it-autoflight/input/hdg"], func (node) {
            var selectedheading = node.getValue() or 0;
            self["selectedheading.digital"].setText(sprintf("%03d", selectedheading));
            self["selectedheading.pointer"].setRotation(selectedheading * D2R);
        }, 1, 0));

        # wind speed
        append(me.listeners, setlistener(me.props["/environment/wind-speed-kt"], func (node) {
            var windSpeed = node.getValue() or 0;
            if (windSpeed > 1) {
                me["wind.pointer"].show();
            }
            else {
                me["wind.pointer"].hide();
            }
            me["wind.kt"].setText(sprintf("%u", windSpeed));
        }, 1, 0));

        # selected altitude
        append(me.listeners, setlistener(me.props["/controls/flight/selected-alt"], func (node) {
            self["selectedalt.digital100"].setText(sprintf("%02d", (node.getValue() or 0) * 0.01));
        }, 1, 0));

        # comm/nav
        append(me.listeners, setlistener(me.props["/instrumentation/comm[0]/frequencies/selected-mhz"], func (node) {
            self["vhf1.act"].setText(sprintf("%.2f", node.getValue() or 0));
        }, 1, 0));
        append(me.listeners, setlistener(me.props["/instrumentation/comm[0]/frequencies/standby-mhz"], func (node) {
            self["vhf1.sby"].setText(sprintf("%.2f", node.getValue() or 0));
        }, 1, 0));
        append(me.listeners, setlistener(me.props["/instrumentation/nav[0]/frequencies/selected-mhz"], func (node) {
            self["nav1.act"].setText(sprintf("%.2f", node.getValue() or 0));
        }, 1, 0));
        append(me.listeners, setlistener(me.props["/instrumentation/nav[0]/frequencies/standby-mhz"], func (node) {
            self["nav1.sby"].setText(sprintf("%.2f", node.getValue() or 0));
        }, 1, 0));

        # VNAV annunciations
        # TODO
        me["VNAV.constraints1"].hide();
        me["VNAV.constraints2"].hide();

        # V-speed previews
        append(me.listeners, setlistener(me.props["/fms/vspeeds-effective/departure/v1"], func (node) {
            self["asi.preview-v1.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0));
        append(me.listeners, setlistener(me.props["/fms/vspeeds-effective/departure/vr"], func (node) {
            self["asi.preview-vr.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0));
        append(me.listeners, setlistener(me.props["/fms/vspeeds-effective/departure/v2"], func (node) {
            self["asi.preview-v2.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0));
        append(me.listeners, setlistener(me.props["/fms/vspeeds-effective/departure/vfs"], func (node) {
            self["asi.preview-vfs.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0));
        append(me.listeners, setlistener(me.props["/instrumentation/pfd/airspeed-alive"], func (node) {
            self["asi.vspeeds"].setVisible(!node.getBoolValue());
        }, 1, 0));

        # QNH
        var updateQNH = func {
            if (self.props["/instrumentation/pfd/qnh-mode"].getValue()) {
                # 1 = inhg
                self["QNH.digital"].setText(
                    sprintf("%5.2f", self.props["/instrumentation/altimeter/setting-inhg"].getValue()));
                self["QNH.unit"].setText("IN");
            }
            else {
                # 0 = hpa
                self["QNH.digital"].setText(
                    sprintf("%4.0f", self.props["/instrumentation/altimeter/setting-hpa"].getValue()));
                self["QNH.unit"].setText("HPA");
            }
        };
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/qnh-mode"], updateQNH, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/altimeter/setting-inhg"], updateQNH, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/altimeter/setting-hpa"], updateQNH, 1, 0));

        var updateNavAnn = func () {
            var navsrc = self.props["/instrumentation/pfd/nav-src"].getValue() or 0;
            var preview = self.props["/instrumentation/pfd/preview"].getValue() or 0;

            if (navsrc == 0) {
                self["navsrc.primary.selection"].setText("FMS");
                self["navsrc.primary.selection"].setColor(1, 0, 1);
                self["navsrc.primary.id"].setText("");

                if (preview) {
                    self["navsrc.preview"].show();
                    if (self.props["/instrumentation/nav[" ~ (preview - 1) ~ "]/nav-loc"].getValue() or 0) {
                        self["navsrc.preview.selection"].setText("LOC" ~ preview);
                    }
                    else {
                        self["navsrc.preview.selection"].setText("VOR" ~ preview);
                    }
                    self["navsrc.preview.id"].setText(self.props["/instrumentation/nav[" ~ (preview - 1) ~ "]/nav-id"].getValue() or "");
                }
                else {
                    self["navsrc.preview"].hide();
                }
            }
            else {
                self["navsrc.primary"].show();
                if (self.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/nav-loc"].getValue() or 0) {
                    self["navsrc.primary.selection"].setText("LOC" ~ navsrc);
                }
                else {
                    self["navsrc.primary.selection"].setText("VOR" ~ navsrc);
                }
                self["navsrc.primary.selection"].setColor(0, 1, 0);
                self["navsrc.primary.id"].setText(self.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/nav-id"].getValue() or "");
                self["navsrc.primary.id"].setColor(0, 1, 0);
                self["navsrc.preview"].hide();
            }
        };

        append(me.listeners, setlistener(self.props["/controls/flight/nav-src/side"],
            func (node) {
                if (node.getBoolValue()) {
                    self["fma.src.arrow"].setRotation(math.pi);
                }
                else {
                    self["fma.src.arrow"].setRotation(0);
                }
            }, 1, 0));

        append(me.listeners, setlistener(self.props["/instrumentation/pfd/bearing[0]/visible"],
            func (node) { self["hsi.pointer.circle"].setVisible(node.getBoolValue()); },
            1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/bearing[0]/bearing"],
            func (node) { self["hsi.pointer.circle"].setRotation(node.getValue() * D2R); },
            1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/bearing[1]/visible"],
            func (node) { self["hsi.pointer.diamond"].setVisible(node.getBoolValue()); },
            1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/bearing[1]/bearing"],
            func (node) { self["hsi.pointer.diamond"].setRotation(node.getValue() * D2R); },
            1, 0));

        append(me.listeners, setlistener(self.props["/instrumentation/pfd/preview"], func { updateNavAnn(); }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/nav[0]/nav-loc"], func { updateNavAnn(); }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/nav[0]/nav-id"], func { updateNavAnn(); }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/nav[1]/nav-loc"], func { updateNavAnn(); }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/nav[1]/nav-id"], func { updateNavAnn(); }, 1, 0));

        append(me.listeners, setlistener(self.props["/instrumentation/pfd/nav-src"],
            func (node) {
                var courseColor = [0, 1, 0];
                var hsiColor = [0, 1, 0];

                if (node.getValue() == 0) {
                    courseColor = [0, 0.75, 1];
                    hsiColor = [1, 0, 1];
                    me["ils.fmsloc"].show();
                    me["ils.fmsvert"].show();
                }
                else {
                    me["ils.fmsloc"].hide();
                    me["ils.fmsvert"].hide();
                }
                self["selectedcourse.digital"].setColorFill(courseColor[0], courseColor[1], courseColor[2]);
                self["hsi.nav1"].setColor(hsiColor[0], hsiColor[1], hsiColor[2]);
                self["hsi.nav1track"].setColor(hsiColor[0], hsiColor[1], hsiColor[2]);
                updateNavAnn();
            }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/nav/course-source"],
            func (node) {
                if (node.getValue() == 0) {
                    self["selectedcourse.digital"].hide();
                }
                else {
                    self["selectedcourse.digital"].show();
                }
            }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/nav/selected-radial"],
            func (node) {
                self["selectedcourse.digital"].setText(sprintf("%03d", node.getValue()));
            }, 1, 0));

        # DME
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/nav/dme-source"], func (node) {
            var dmesrc = node.getValue();
            if (self.dme_id_listener != nil) {
                removelistener(self.dme_id_listener);
                self.dme_id_listener = nil;
            }
            if (dmesrc > 0) {
                self["dme"].show();
                self["dme.selection"].setText("DME" ~ dmesrc);
                self.dme_id_listener = setlistener(self.props["/instrumentation/nav[" ~ (dmesrc - 1) ~ "]/nav-id"],
                    func (node) {
                        self["dme.id"].setText(node.getValue() or "");
                    }, 1, 0);
            }
            else {
                self["dme"].hide();
            }
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/dme/dist10"], func (node) {
            self["dme.dist"].setText(sprintf("%5.1f", node.getValue() * 0.1));
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/dme/ete"], func (node) {
            var ete = node.getValue();
            if (ete >= 600) {
                self["dme.ete"].setText("+++");
            }
            else {
                self["dme.ete"].setText(sprintf("%3.0d", ete));
            }
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/dme/ete-unit"], func (node) {
            if (node.getValue()) {
                self["dme.eteunit"].setText("MIN");
            }
            else {
                self["dme.eteunit"].setText("SEC");
            }
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/dme/hold"], func (node) {
            self["dme.hold"].setVisible(node.getBoolValue());
        }, 1, 0));

        # HSI
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/hsi/heading"],
            func (node) {
                var hsiHeading = node.getValue() * D2R;
                self["hsi.nav1"].setRotation(hsiHeading);
                self["hsi.dots"].setRotation(hsiHeading);
            }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/hsi/deflection"],
            func (node) {
                self["hsi.nav1track"].setTranslation(node.getValue() * 120, 0);
            }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/hsi/from-flag"],
            func (node) {
                var flag = node.getValue();
                self["hsi.from"].setVisible(flag == 1);
                self["hsi.to"].setVisible(flag == 0);
            }, 1, 0));

        updateILSColors = func {
            var ilssrc = self.props["/instrumentation/pfd/ils/source"].getValue();
            var navsrc = self.props["/instrumentation/pfd/nav-src"].getValue();
            var gsInRange = self.props["/instrumentation/pfd/ils/gs-in-range"].getBoolValue();
            var locInRange = self.props["/instrumentation/pfd/ils/loc-in-range"].getBoolValue();
            if (navsrc == 0) {
                self.ilscolor = [0, 0.75, 1]; # preview mode
            }
            else {
                self.ilscolor = [0, 1, 0]; # V/L mode
            }
            self["ils.gsneedle"].setColor(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
            if (gsInRange) {
                self["ils.gsneedle"].setColorFill(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
            }
            else {
                self["ils.gsneedle"].setColorFill(0, 0, 0);
            }
            self["ils.locneedle"].setColor(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
            if (locInRange) {
                self["ils.locneedle"].setColorFill(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
            }
            else {
                self["ils.locneedle"].setColorFill(0, 0, 0);
            }
        };
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/ils/source"], updateILSColors, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/nav-src"], updateILSColors, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/ils/gs-in-range"], updateILSColors, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/ils/loc-in-range"], updateILSColors, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/ils/has-gs"], func (node) {
                self["ils.gsneedle"].setVisible(node.getBoolValue());
            }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/ils/has-loc"], func (node) {
                self["ils.locneedle"].setVisible(node.getBoolValue());
            }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/ils/gs-needle"], func (node) {
                self["ils.gsneedle"].setTranslation(0, math.round((node.getValue() or 0) * -100.0));
            }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/ils/loc-needle"], func (node) {
                self["ils.locneedle"].setTranslation(math.round((node.getValue() or 0) * 100.0), 0);
            }, 1, 0));

        append(me.listeners, setlistener(self.props["/autopilot/route-manager/active"], func (node) {
            self["waypoint"].setVisible(node.getBoolValue());
            }, 1, 0));

        append(me.listeners, setlistener(self.props["/autopilot/route-manager/wp/id"], func (node) {
            self["waypoint.id"].setText(node.getValue() or "");
            }, 1, 0));

        append(me.listeners, setlistener(self.props["/instrumentation/pfd/waypoint/dist10"], func (node) {
            self["waypoint.dist"].setText(
                sprintf("%5.1f", (node.getValue() or 0) * 0.1));
            }, 1, 0));

        append(me.listeners, setlistener(self.props["/instrumentation/pfd/waypoint/ete"], func (node) {
                self["waypoint.ete"].setText(sprintf("%3d", node.getValue()));
            }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/waypoint/ete-unit"], func (node) {
                if (node.getBoolValue()) {
                    self["waypoint.eteunit"].setText("MIN");
                }
                else {
                    self["waypoint.eteunit"].setText("SEC");
                }
            }, 1, 0));

        # FMA
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/fma/ap"], func (node) {
                var mode = node.getValue() or 0;
                if (mode == 0) {
                    self["fma.ap"].hide();
                    self["fma.ap.bg"].hide();
                }
                elsif (mode == 1) {
                    self["fma.ap"].show();
                    self["fma.ap.bg"].hide();
                    self["fma.ap"].setColor(0, 1, 0);
                }
                elsif (mode == 2) {
                    self["fma.ap"].show();
                    self["fma.ap.bg"].hide();
                    self["fma.ap"].setColor(1, 0, 0);
                }
                elsif (mode == 3) {
                    self["fma.ap"].show();
                    self["fma.ap.bg"].show();
                    self["fma.ap"].setColor(0, 0, 0);
                }
            }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/fma/at"], func (node) {
                var mode = node.getValue() or 0;
                if (mode == 0) {
                    self["fma.at"].hide();
                    self["fma.at.bg"].hide();
                }
                elsif (mode == 1) {
                    self["fma.at"].show();
                    self["fma.at.bg"].hide();
                    self["fma.at"].setColor(0, 1, 0);
                }
                elsif (mode == 2) {
                    self["fma.at"].show();
                    self["fma.at.bg"].hide();
                    self["fma.at"].setColor(1, 0, 0);
                }
                elsif (mode == 3) {
                    self["fma.at"].show();
                    self["fma.at.bg"].show();
                    self["fma.at"].setColor(0, 0, 0);
                }
            }, 1, 0));
        append(me.listeners, setlistener("/instrumentation/annun/lat-mode", func (node) {
                self["fma.lat"].setText(node.getValue());
                self["fma.lat.bg"].setColorFill(0, 0, 0); # TODO
            }, 1, 0));
        append(me.listeners, setlistener("/instrumentation/annun/lat-mode-armed", func (node) {
                self["fma.latarmed"].setText(node.getValue());
            }, 1, 0));
        append(me.listeners, setlistener("/instrumentation/annun/vert-mode", func (node) {
                self["fma.vert"].setText(node.getValue());
                self["fma.vert.bg"].setColorFill(0, 0, 0); # TODO
            }, 1, 0));
        append(me.listeners, setlistener("/instrumentation/annun/vert-mode-armed", func (node) {
                self["fma.vertarmed"].setText(node.getValue());
            }, 1, 0));
        append(me.listeners, setlistener("/instrumentation/annun/spd-mode", func (node) {
                self["fma.spd"].setText(node.getValue());
            }, 1, 0));
        append(me.listeners, setlistener("/instrumentation/annun/spd-mode-armed", func (node) {
                self["fma.spdarmed"].setText(node.getValue());
            }, 1, 0));
        append(me.listeners, setlistener("/instrumentation/annun/spd-minor-mode", func (node) {
                self["fma.spd.minor"].setText(node.getValue());
            }, 1, 0));
        append(me.listeners, setlistener("/instrumentation/annun/spd-minor-mode-armed", func (node) {
                self["fma.spdarmed.minor"].setText(node.getValue());
            }, 1, 0));
        append(me.listeners, setlistener("/instrumentation/annun/appr-mode", func (node) {
                self["fma.appr"].setText(node.getValue());
            }, 1, 0));
        append(me.listeners, setlistener("/instrumentation/annun/appr-mode-armed", func (node) {
                var value = node.getValue();
                self["fma.apprarmed"].setText(value);
                if (value == 'APPR1 ONLY') {
                    self["fma.apprarmed"].setColor(1, 0.5, 0);
                }
                else {
                    self["fma.apprarmed"].setColor(1, 1, 1);
                }
            }, 1, 0));

        append(me.listeners, setlistener(me.props["/instrumentation/iru/outputs/valid-att"], func (node) {
                if (node.getBoolValue()) {
                    self["horizon"].show();
                    self["failure.att"].hide();
                }
                else {
                    self["horizon"].hide();
                    self["failure.att"].show();
                }
            }, 1, 0));
        append(me.listeners, setlistener(me.props["/instrumentation/iru/outputs/valid"], func (node) {
                if (node.getBoolValue()) {
                    self["compass.numbers"].show();
                    self["selectedheading.pointer"].show();
                    self["heading.digital"].setColor(0, 1, 0);
                    self["groundspeed"].setColor(0, 1, 0);
                    self["failure.hdg"].hide();
                }
                else {
                    self["compass.numbers"].hide();
                    self["selectedheading.pointer"].hide();
                    self["heading.digital"].setColor(1, 0.5, 0);
                    self["heading.digital"].setText('---');
                    self["groundspeed"].setColor(1, 0.5, 0);
                    self["groundspeed"].setText('---');
                    self["failure.hdg"].show();
                }
            }, 1, 0));

        var updateFDViz = func {
            var viz = self.props["/it-autoflight/output/fd"].getBoolValue();
            if (viz) {
                var vertMode = self.props["/it-autoflight/mode/vert"].getValue();
                if (vertMode == "T/O CLB" or vertMode == "G/A CLB") {
                    self["fd.icon"].hide();
                    self["fd.bars"].show();
                }
                else {
                    self["fd.icon"].show();
                    self["fd.bars"].hide();
                }
            }
            else {
                self["fd.icon"].hide();
                self["fd.bars"].hide();
            }
        };

        var updateSelectedVSpeed = func {
            var vertMode = self.props["/it-autoflight/mode/vert"].getValue();
            if (vertMode == "V/S") {
                self["selectedvspeed.digital"].setText(sprintf("%+05d", (self.props["/it-autoflight/input/vs"].getValue() or 0)));
                self["selectedvspeed.digital"].show();
                self["vs.needle.target"].show();
                self["fpa.target"].hide();
            }
            else if (vertMode == "FPA") {
                var fpaText = sprintf("%+4.1f", (self.props["/it-autoflight/input/fpa"].getValue() or 0));
                self["selectedvspeed.digital"].setText(fpaText);
                self["selectedvspeed.digital"].show();
                self["vs.needle.target"].hide();
                self["fpa.target.digital"].setText(fpaText);
                self["fpa.target"].show();
            }
            else {
                self["selectedvspeed.digital"].hide();
                self["vs.needle.target"].hide();
                self["fpa.target"].hide();
            }
        };

        append(me.listeners, setlistener(self.props["/it-autoflight/output/fd"], func {
            updateFDViz();
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/it-autoflight/mode/vert"], func {
            updateSelectedVSpeed();
            updateFDViz();
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/it-autoflight/input/fpa"], func {
            updateSelectedVSpeed();
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/it-autoflight/input/vs"], func {
            updateSelectedVSpeed();
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/fpa-pitch-scale"], func (node) {
            var fpaPitch = (self.props["/instrumentation/pfd/fpa-pitch-scale"].getValue() or 0);
            self["fpa.target"].setTranslation(0,-fpaPitch*8.05);
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/vsi-target-deg"], func (node) {
            var vneedle = self.props["/instrumentation/pfd/vsi-target-deg"].getValue() or 0;
            self["vs.needle.target"].setRotation(vneedle * D2R);
        }, 1, 0));

        var updateSelectedSpeed = func {
            if (self.props["/it-autoflight/input/kts-mach"].getValue()) {
                var selectedMach = (self.props["/it-autoflight/input/mach"].getValue() or 0);
                self["selectedspeed.digital"].setText(sprintf(".%03dM", selectedMach * 1000 + 0.5));
            }
            else {
                var selectedKts = (self.props["/it-autoflight/input/kts"].getValue() or 0);
                self["selectedspeed.digital"].setText(sprintf("%03d", selectedKts));
            }
        };

        append(me.listeners, setlistener(self.props["/it-autoflight/input/kts"], updateSelectedSpeed, 1, 0));
        append(me.listeners, setlistener(self.props["/it-autoflight/input/mach"], updateSelectedSpeed, 1, 0));
        append(me.listeners, setlistener(self.props["/it-autoflight/input/kts-mach"], updateSelectedSpeed, 1, 0));

        append(me.listeners, setlistener(self.props["/controls/flight/speed-mode"], func(node) {
            if (node.getValue() == 1) {
                self["selectedspeed.digital"].setColor(1, 0, 1);
            }
            else {
                self["selectedspeed.digital"].setColor(0, 0.75, 1);
            }
        }, 1, 0));

        append(me.listeners, setlistener(self.props["/instrumentation/pfd/alt-tape-offset"], func(node) {
            self["alt.tape"].setTranslation(0, node.getValue() * 0.45);
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/alt-bug-offset"], func(node) {
            self["alt.bug"].setTranslation(0, node.getValue() * 0.45);
        }, 1, 0));

        append(me.listeners, setlistener(self.props["/instrumentation/pfd/alt-tape-thousands"], func(node) {
            var altTapeThousands = node.getValue() * 1000;
            self["altNumLow1"].setText(sprintf("%5.0f", altTapeThousands - 1000));
            self["altNumHigh1"].setText(sprintf("%5.0f", altTapeThousands));
            self["altNumHigh2"].setText(sprintf("%5.0f", altTapeThousands + 1000));
        }, 1, 0));

        # Minimums
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/radio-alt"], func(node) {
            var ra = node.getValue();
            self["radioalt.digital"].setText(sprintf("%04d", ra));
        }, 1, 0));
        self["radioalt.digital"].setText(sprintf("%04d", 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/minimums-visible"], func(node) {
            self["minimums"].setVisible(node.getBoolValue());
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/minimums-indicator-visible"], func(node) {
            self["minimums.indicator"].setVisible(node.getBoolValue());   
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/radio-altimeter-visible"], func(node) {
            self["radioalt"].setVisible(node.getBoolValue());   
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/minimums-mode"], func(node) {
            if (node.getBoolValue()) {
                self["minimums.barora"].setText("BARO");
                self["minimums.digital"].setColor(1, 1, 0);
            }
            else {
                self["minimums.barora"].setText("RA");
                self["minimums.digital"].setColor(1, 1, 1);
            }
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/pfd/minimums-decision-altitude"], func(node) {
            self["minimums.digital"].setText(sprintf("%d", node.getValue()));
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/cpdlc/unread"], func (node) {
            self["atc.indicator"].setVisible(node.getValue() != 0);
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/acars/telex/unread"], func (node) {
            self["dlk.indicator"].setVisible(node.getValue() != 0);
        }, 1, 0));

        var updateEicasWarning = func () {
            var warning = self.props['/instrumentation/eicas/master/warning'].getBoolValue();
            var caution = self.props['/instrumentation/eicas/master/caution'].getBoolValue();
            if (warning) {
                self["eicas.indicator.bg"].setColorFill(1, 0, 0);
                self["eicas.indicator"].show();
            }
            elsif (caution) {
                self["eicas.indicator.bg"].setColorFill(1, 1, 0);
                self["eicas.indicator"].show();
            }
            else {
                self["eicas.indicator"].hide();
            }
        };

        append(me.listeners, setlistener(self.props["/instrumentation/eicas/master/warning"], func (node) { updateEicasWarning(); }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/eicas/master/caution"], func (node) { updateEicasWarning(); }, 1, 0));

        append(me.listeners, setlistener(self.props["/instrumentation/marker-beacon/inner"], func (node) {
            self["marker.inner"].setVisible(node.getBoolValue());
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/marker-beacon/middle"], func (node) {
            self["marker.middle"].setVisible(node.getBoolValue());
        }, 1, 0));
        append(me.listeners, setlistener(self.props["/instrumentation/marker-beacon/outer"], func (node) {
            self["marker.outer"].setVisible(node.getBoolValue());
        }, 1, 0));


        append(me.listeners, setlistener(self.props["/instrumentation/tcas/inputs/mode"], func (node) {
            var tcasMode = node.getValue();
            if (tcasMode == 3) {
                # TA/RA
                self["tcas.warning"].hide();
            }
            elsif (tcasMode == 2) {
                # TA ONLY
                self["tcas.warning"].setText('TA ONLY');
                self["tcas.warning"].show();
            }
            else {
                # TA OFF
                self["tcas.warning"].setText('TCAS OFF');
                self["tcas.warning"].show();
            }
        }, 1, 0));
    },

    toggleBlink: func() {
        me.props["/instrumentation/pfd/blink-state"].toggleBoolValue();
    },

    updateSlow: func() {
        # CHR
        var t = me.props["/instrumentation/chrono/elapsed_time/total"].getValue() or 0;
        me["chrono.digital"].setText(sprintf("%02d:%02d", math.floor(t / 60), math.mod(t, 60)));
    },

    update: func() {
        var pitch = (me.props["/instrumentation/pfd/pitch-scale"].getValue() or 0);
        var roll =  me.props["/orientation/roll-deg"].getValue() or 0;
        var slip = me.props["/instrumentation/slip-skid-ball/indicated-slip-skid"].getValue() or 0;
        var trackError = me.props["/instrumentation/pfd/track-error-deg"].getValue() or 0;
        var fpaScaled = me.props["/instrumentation/pfd/fpa-scale"].getValue() or 0;
        me.h_trans.setTranslation(0,pitch*8.05);
        me.h_rot.setRotation(-roll*D2R,me["horizon"].getCenter());
        if(math.abs(roll)<=45){
            me["roll.pointer"].setRotation(roll*(-D2R));
        }
        me["slip.pointer"].setTranslation(math.round(slip * -25), 0);
        if (math.abs(slip) >= 1.0)
            me["slip.pointer"].setColorFill(1, 1, 1);
        else
            me["slip.pointer"].setColorFill(0, 0, 0);

        # Heading
        var heading = me.props["/orientation/heading-magnetic-deg"].getValue() or 0;
        if (me.props["/instrumentation/iru/outputs/valid"].getBoolValue()) {
            # wind direction
            # For some reason, if we attempt to do this in a listener, it will
            # be extremely unreliable.
            me["wind.pointer"].setRotation((me.props["/environment/wind-from-heading-deg"].getValue() or 0) * D2R);
            me["wind.pointer.wrapper"].setRotation(heading * -D2R);
            me["compass"].setRotation(heading * -D2R);
            me["heading.digital"].setText(sprintf("%03d", heading));
            # groundspeed
            me["groundspeed"].setText(
                sprintf("%3d", me.props["/instrumentation/pfd/groundspeed-kt"].getValue() or 0));
        }

        # FPV
        me["fpv"]
            .setTranslation(geo.normdeg180(trackError) * 8.05, -fpaScaled * 8.05)
            .setRotation(roll * D2R);

        # FD
        var barPitch = me.props["/instrumentation/pfd/fd/pitch-bar-scale"].getValue() or 0;
        var barRoll = me.props["/it-autoflight/fd/roll-bar"].getValue() or 0;
        var trackError = me.props["/instrumentation/pfd/track-error-deg"].getValue() or 0;
        var fdPitch = me.props["/instrumentation/pfd/fd/pitch-scale"].getValue() or 0;
        var fdRoll = me.props["/instrumentation/pfd/fd/lat-offset-deg"].getValue() or 0;

        me["fd.pitch"].setTranslation(0, (pitch - barPitch) * 8.05);
        me["fd.roll"].setTranslation(barRoll * 8.05, 0);
        me["fd.icon"]
            .setTranslation(
                geo.normdeg180(trackError + fdRoll) * 8.05,
                fdPitch * -8.05)
            .setRotation(roll * D2R);

        # V/S
        var vspeed = me.props["/instrumentation/vertical-speed-indicator/indicated-speed-fpm"].getValue() or 0;
        me["VS.digital"].setText(sprintf("%+05d", vspeed));
        var vneedle = me.props["/instrumentation/pfd/vsi-needle-deg"].getValue() or 0;
        me["vs.needle.current"].setRotation(vneedle * D2R);
        me["VS.digital.wrapper"].setVisible(math.abs(vspeed) >= 500);

        # Altitude
        var alt = me.props["/instrumentation/altimeter/indicated-altitude-ft"].getValue() or 0;

        var o = odoDigit(alt / 10, 0);
        me["alt.rollingdigits"].setTranslation(0, o * 18);
        if (alt >= 100) {
            me["alt.rollingdigits.pos"].show();
            me["alt.rollingdigits.zero"].hide();
            me["alt.rollingdigits.neg"].hide();
        }
        else if (alt <= -100) {
            me["alt.rollingdigits.pos"].hide();
            me["alt.rollingdigits.zero"].hide();
            me["alt.rollingdigits.neg"].show();
        }
        else {
            me["alt.rollingdigits.pos"].hide();
            me["alt.rollingdigits.zero"].show();
            me["alt.rollingdigits.neg"].hide();
        }

        var altR = math.max(-20, alt);
        var o100 = odoDigit(altR / 10, 1);
        me["alt.100"].setTranslation(0, o100 * 44);
        var o1000 = odoDigit(altR / 10, 2);
        me["alt.1000"].setTranslation(0, o1000 * 44);
        var o10000 = odoDigit(altR / 10, 3);
        me["alt.10000"].setTranslation(0, o10000 * 44);

        if (alt < 0) {
            me["alt.100.tape"].hide();
            me["alt.1000.tape"].hide();
            me["alt.10000.tape"].hide();
            me["alt.100.neg"].show();
            me["alt.1000.neg"].show();
            me["alt.10000.neg"].show();
        }
        else {
            me["alt.100.tape"].show();
            me["alt.1000.tape"].show();
            me["alt.10000.tape"].show();
            me["alt.100.neg"].hide();
            me["alt.1000.neg"].hide();
            me["alt.10000.neg"].hide();
        }

        if (alt < 5000) {
            me["alt.1000.z"].hide();
        }
        else {
            me["alt.1000.z"].show();
        }
        if (alt < 50000) {
            me["alt.10000.z"].hide();
        }
        else {
            me["alt.10000.z"].show();
        }

        if (alt < 1000) {
            me["alt.1000.zero"].show();
        }
        else {
            me["alt.1000.zero"].hide();
        }
        if (alt < 10000) {
            me["alt.10000.zero"].show();
        }
        else {
            me["alt.10000.zero"].hide();
        }

        # Airspeed
        var airspeedRaw = me.props["/instrumentation/airspeed-indicator/indicated-speed-kt"].getValue() or 0;
        var airspeed = math.max(40, airspeedRaw);
        var airspeedLookahead = me.props["/instrumentation/pfd/airspeed-lookahead-10s"].getValue() or 0;
        var currentMach = me.props["/instrumentation/airspeed-indicator/indicated-mach"].getValue() or 0;
        var selectedKts = 0;

        if (me.props["/it-autoflight/input/kts-mach"].getValue()) {
            var selectedMach = (me.props["/it-autoflight/input/mach"].getValue() or 0);
            if (currentMach > 0.001) {
                selectedKts = selectedMach * airspeed / currentMach;
            }
            else {
                # this shouldn't happen in practice, but when it does, use the
                # least objectionable default.
                selectedKts = me.props["/it-autoflight/input/kts"].getValue();
            }
        }
        else {
            selectedKts = (me.props["/it-autoflight/input/kts"].getValue() or 0);
        }
        me["mach.digital"].setText(sprintf(".%03d", currentMach * 1000));


        me["speedtrend.vector"].reset();
        me["speedtrend.vector"].rect(152, 450, 15,
            math.max(-40.0, math.min(40.0, (airspeedLookahead - airspeed))) * -6.42);

        me["speederror.vector"].reset();
        me["speederror.vector"].rect(419, 437, 10,
            math.max(-40.0, math.min(40.0, (selectedKts - airspeed))) * -2);
        me["speedtrend.pointer"].setTranslation(
            0,
            math.max(-40.0, math.min(40.0, (airspeedLookahead - airspeed))) * -2);

        me["asi.tape"].setTranslation(0,airspeed * 6.42);
        me["airspeed.bug"].setTranslation(0, (airspeed-selectedKts) * 6.42);

        var redSpeed = me.props["/fms/speed-limits/vstall-kt"].getValue() or 0;
        var amberSpeed = me.props["/fms/speed-limits/vwarn-kt"].getValue() or 0;
        var greenSpeed = me.props["/fms/speed-limits/green-dot-kt"].getValue() or 0;
        var maxSpeed = me.props["/fms/speed-limits/vmo-effective"].getValue() or 0;

        me["speedbar.red"].setTranslation(0, math.max(-41, (airspeed-redSpeed)) * 6.42);
        me["speedbar.amber"].setTranslation(0, math.max(-41, (airspeed-amberSpeed)) * 6.42);
        me["barberpole"].setTranslation(0, math.max(-41, (airspeed-maxSpeed)) * 6.42);
        me["greendot"].setTranslation(0, (airspeed-greenSpeed) * 6.42);
        if (greenSpeed > airspeed + 40 or greenSpeed < airspeed - 40) {
            me["greendot"].hide();
        }
        else {
            me["greendot"].show();
        }
        if (me.props["/gear/gear/wow"].getValue()) {
            me["speedbar.red"].hide();
            me["speedbar.amber"].hide();
        }
        else {
            me["speedbar.red"].show();
            me["speedbar.amber"].show();
        }

        o = odoDigit(airspeed, 0);

        me["asi.1"].setTranslation(0, o * 64);

        o = odoDigit(airspeed, 1);
        me["asi.10"].setTranslation(0, o * 64);

        o = odoDigit(airspeed, 2);
        me["asi.100"].setTranslation(0, o * 64);

        if (airspeed < 90.0) {
            me["asi.10.0"].hide();
            me["asi.10.9"].hide();
        }
        else {
            me["asi.10.0"].show();
            me["asi.10.9"].show();
        }


        # Speed ref bugs
        foreach (var spdref; ["v1", "vr", "v2", "vfs"]) {
            var prop = me.props["/fms/vspeeds-effective/departure/" ~ spdref];
            var elem = me["speedref." ~ spdref];
            if (elem == nil) continue;
            if (prop == nil) {
                elem.hide();
            }
            else {
                ktsRel = airspeed - (prop.getValue() or 0);
                elem.setTranslation(0, ktsRel * 6.42);
                var phase = getprop("/fms/phase");
                if ((phase == 0 or phase == 1) and ktsRel < 50 and ktsRel > -50) {
                    # takeoff / departure
                    elem.show();
                }
                else {
                    elem.hide();
                }
            }
        }
        foreach (var spdref; ["vref", "vappr", "vap", "vac"]) {
            var prop = me.props["/fms/vspeeds-effective/approach/" ~ spdref];
            var elem = me["speedref." ~ spdref];
            if (elem == nil) continue;
            if (prop == nil) {
                elem.hide();
            }
            else {
                ktsRel = airspeed - (prop.getValue() or 0);
                elem.setTranslation(0, ktsRel * 6.42);
                var phase = getprop("/fms/phase");
                if ((phase == 6) and ktsRel < 50 and ktsRel > -50) {
                    # approach
                    elem.show();
                }
                else {
                    elem.hide();
                }
            }
        }

        # Flaps-up markers
        var flaps = me.props["/controls/flight/flaps"].getValue();
        var flapsElem = me["speedref.vf"];
        if (flaps <= 0.000001) {
            flapsElem.hide();
        }
        else {
            # vf0 = vf; and then vf1 through vf4.
            var nextFlapIndex = math.max(0, math.min(4, math.round(flaps * 8) - 1));
            var prop = me.props["/fms/vspeeds-effective/departure/vf"];
            if (nextFlapIndex > 0) {
                var propname = sprintf("/fms/vspeeds-effective/departure/vf%1.0f", nextFlapIndex);
                prop = me.props[propname];
            }
            ktsRel = airspeed - (prop.getValue() or 0);
            flapsElem.setTranslation(0, ktsRel * 6.42);
            flapsElem.show();
        }

        me["ils.fmsloc"].setTranslation(
            math.round((me.props["/instrumentation/gps/cdi-deflection"].getValue() or 0) * 10.0),
            0);

        # TODO
        # me["ils.fmsvert"].setTranslation(0, math.min(1000, math.max(-1000, node.getValue())) * 0.1);


    },
};

initialize = func {
    var timer = [];
    var timerSlow = [];
    var blinkTimer = [];

    for (var i = 0; i < 2; i += 1) {
        PFD_display[i] = canvas.new({
            "name": "PFD" ~ i,
            "size": [1024, 1560],
            "view": [1024, 1560],
            "mipmapping": 1
        });
        PFD_display[i].addPlacement({"node": "PFD" ~ i});
        PFD_master[i] = PFD_display[i].createGroup();
        pfd[i] =
            PFDCanvas.new(
                PFD_master[i],
                "Aircraft/E-jet-family/Models/Primus-Epic/PFD.svg",
                i);
        (func (j) {
            outputProp = props.globals.getNode("systems/electrical/outputs/pfd[" ~ j ~ "]");
            enabledProp = props.globals.getNode("instrumentation/pfd[" ~ j ~ "]/enabled");
            rateProp = props.globals.getNode("instrumentation/pfd[" ~ j ~ "]/update-rate");
            append(timer, maketimer(0.04, func() { pfd[j].update(); }));
            append(timerSlow, maketimer(1.0, func() { pfd[j].updateSlow(); }));
            append(blinkTimer, maketimer(0.25, func () { pfd[j].toggleBlink(); }));
            blinkTimer[j].simulatedTime = 1;
            var check = func {
                var visible = ((outputProp.getValue() or 0) >= 15) and enabledProp.getBoolValue();
                PFD_master[j].setVisible(visible);
                if (visible) {
                    var rate = rateProp.getValue();
                    var interval = 1.0 / 20.0;
                    if (rate == 0)
                        interval = 0.1;
                    elsif (rate == 2)
                        interval = 1.0 / 30.0;
                    pfd[j].setupListeners();
                    timer[j].restart(interval);
                    timerSlow[j].start();
                    blinkTimer[j].start();
                }
                else {
                    pfd[j].deleteListeners();
                    timer[j].stop();
                    timerSlow[j].stop();
                    blinkTimer[j].stop();
                }
            };

            setlistener(outputProp, check, 1, 0);
            setlistener(enabledProp, check, 1, 0);
            setlistener(rateProp, check, 1, 0);
        })(i);
    }
    setlistener('instrumentation/pfd[0]/slaved', func (node) {
        if (node.getBoolValue()) {
            print('deslave 1');
            setprop('instrumentation/pfd[1]/slaved', 0);
        }
    }, 0, 0);
    setlistener('instrumentation/pfd[1]/slaved', func (node) {
        if (node.getBoolValue()) {
            print('deslave 0');
            setprop('instrumentation/pfd[0]/slaved', 0);
        }
    }, 0, 0);
};

var initialized = 0;
setlistener("sim/signals/fdm-initialized", func {
    if (!initialized) {
        initialize();
        initialized = 1;
    }
});
