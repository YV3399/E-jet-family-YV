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

var FOCUS_NONE = 0;
var FOCUS_COM = 1;
var FOCUS_NAV = 2;

var PFDCanvas = {
    new: func(side=0) {
        var m = canvas_base.BaseScreen.new(side, 0);
        m.parents = [PFDCanvas] ~ m.parents;
        m.focus = FOCUS_NONE;
        return m;
    },

    
    registerProps: func () {
        call(canvas_base.BaseScreen.registerProps, [], me);

        me.registerProp('cursor', "/instrumentation/pfd[" ~ me.side ~ "]/cursor");
        me.registerProp('cursor.x', "/instrumentation/pfd[" ~ me.side ~ "]/cursor/x");
        me.registerProp('cursor.y', "/instrumentation/pfd[" ~ me.side ~ "]/cursor/y");
        me.registerProp('cursor.visible', "/instrumentation/pfd[" ~ me.side ~ "]/cursor/visible");

        me.registerProp("/acars/telex/unread", "/acars/telex/unread", 1);
        me.registerProp("/autopilot/autoland/armed-mode", "/autopilot/autoland/armed-mode");
        me.registerProp("/autopilot/autoland/engaged-mode", "/autopilot/autoland/engaged-mode");
        me.registerProp("/autopilot/route-manager/active", "/autopilot/route-manager/active");
        me.registerProp("/autopilot/route-manager/wp/dist", "/autopilot/route-manager/wp/dist");
        me.registerProp("/autopilot/route-manager/wp/eta-seconds", "/autopilot/route-manager/wp/eta-seconds");
        me.registerProp("/autopilot/route-manager/wp/id", "/autopilot/route-manager/wp/id");
        me.registerProp("/controls/flight/flaps", "/controls/flight/flaps");
        me.registerProp("/controls/flight/nav-src/side", "/controls/flight/nav-src/side");
        me.registerProp("/controls/flight/selected-alt", "/controls/flight/selected-alt");
        me.registerProp("/controls/flight/speed-mode", "/controls/flight/speed-mode");
        me.registerProp("/controls/flight/vnav-enabled", "/controls/flight/vnav-enabled");
        me.registerProp("/cpdlc/unread", "/cpdlc/unread", 1);
        me.registerProp("/environment/wind-from-heading-deg", "/environment/wind-from-heading-deg");
        me.registerProp("/environment/wind-speed-kt", "/instrumentation/pfd[" ~ me.side ~ "]/wind-speed-kt");
        me.registerProp("/fms/speed-limits/green-dot-kt", "/fms/speed-limits/green-dot-kt");
        me.registerProp("/fms/speed-limits/vmo-effective", "/fms/speed-limits/vmo-effective");
        me.registerProp("/fms/speed-limits/vstall-kt", "/fms/speed-limits/vstall-kt");
        me.registerProp("/fms/speed-limits/vwarn-kt", "/fms/speed-limits/vwarn-kt");
        me.registerProp("/fms/vnav/alt-deviation", "/fms/vnav/alt-deviation");
        me.registerProp("/fms/vspeeds-effective/approach/vac", "/fms/vspeeds-effective/approach/vac");
        me.registerProp("/fms/vspeeds-effective/approach/vap", "/fms/vspeeds-effective/approach/vap");
        me.registerProp("/fms/vspeeds-effective/approach/vref", "/fms/vspeeds-effective/approach/vref");
        me.registerProp("/fms/vspeeds-effective/departure/v1", "/fms/vspeeds-effective/departure/v1");
        me.registerProp("/fms/vspeeds-effective/departure/v2", "/fms/vspeeds-effective/departure/v2");
        me.registerProp("/fms/vspeeds-effective/departure/vf1", "/fms/vspeeds-effective/departure/vf1");
        me.registerProp("/fms/vspeeds-effective/departure/vf2", "/fms/vspeeds-effective/departure/vf2");
        me.registerProp("/fms/vspeeds-effective/departure/vf3", "/fms/vspeeds-effective/departure/vf3");
        me.registerProp("/fms/vspeeds-effective/departure/vf4", "/fms/vspeeds-effective/departure/vf4");
        me.registerProp("/fms/vspeeds-effective/departure/vf", "/fms/vspeeds-effective/departure/vf");
        me.registerProp("/fms/vspeeds-effective/departure/vfs", "/fms/vspeeds-effective/departure/vfs");
        me.registerProp("/fms/vspeeds-effective/departure/vr", "/fms/vspeeds-effective/departure/vr");
        me.registerProp("/gear/gear/wow", "/gear/gear/wow");
        me.registerProp("/instrumentation/annun/vert-mode-managed", "/instrumentation/annun/vert-mode-managed");
        me.registerProp("/instrumentation/annun/lat-mode-managed", "/instrumentation/annun/lat-mode-managed");
        me.registerProp("/instrumentation/annun/spd-mode-managed", "/instrumentation/annun/spd-mode-managed");
        me.registerProp("/instrumentation/airspeed-indicator/indicated-mach", "/instrumentation/airspeed-indicator/indicated-mach");
        me.registerProp("/instrumentation/airspeed-indicator/indicated-speed-kt", "/instrumentation/airspeed-indicator/indicated-speed-kt");
        me.registerProp("/instrumentation/altimeter/indicated-altitude-ft", "/instrumentation/altimeter[" ~ me.side ~ "]/indicated-altitude-ft");
        me.registerProp("/instrumentation/altimeter/setting-hpa", "/instrumentation/altimeter[" ~ me.side ~ "]/setting-hpa");
        me.registerProp("/instrumentation/altimeter/setting-inhg", "/instrumentation/altimeter[" ~ me.side ~ "]/setting-inhg");
        me.registerProp("/instrumentation/chrono/elapsed_time/total", "/instrumentation/chrono/elapsed_time/total");
        me.registerProp("/instrumentation/chrono/chrono/total", "/instrumentation/chrono/chrono/total");
        me.registerProp("/instrumentation/comm[0]/frequencies/selected-mhz", "/instrumentation/comm[0]/frequencies/selected-mhz");
        me.registerProp("/instrumentation/comm[0]/frequencies/standby-mhz", "/instrumentation/comm[0]/frequencies/standby-mhz");
        me.registerProp("/instrumentation/comm[0]/spacing", "/instrumentation/comm[0]/spacing");
        me.registerProp("/instrumentation/dme.elems[0]/frequencies/selected-mhz", "/instrumentation/dme.elems[0]/frequencies/selected-mhz");
        me.registerProp("/instrumentation/dme.elems[0]/frequencies/source", "/instrumentation/dme.elems[0]/frequencies/source");
        me.registerProp("/instrumentation/dme.elems[0]/indicated-distance-nm", "/instrumentation/dme.elems[0]/indicated-distance-nm");
        me.registerProp("/instrumentation/dme.elems[0]/indicated-time-min", "/instrumentation/dme.elems[0]/indicated-time-min");
        me.registerProp("/instrumentation/dme.elems[0]/in-range", "/instrumentation/dme.elems[0]/in-range");
        me.registerProp("/instrumentation/dme.elems[1]/frequencies/selected-mhz", "/instrumentation/dme.elems[1]/frequencies/selected-mhz");
        me.registerProp("/instrumentation/dme.elems[1]/frequencies/source", "/instrumentation/dme.elems[1]/frequencies/source");
        me.registerProp("/instrumentation/dme.elems[1]/indicated-distance-nm", "/instrumentation/dme.elems[1]/indicated-distance-nm");
        me.registerProp("/instrumentation/dme.elems[1]/indicated-time-min", "/instrumentation/dme.elems[1]/indicated-time-min");
        me.registerProp("/instrumentation/dme.elems[1]/in-range", "/instrumentation/dme.elems[1]/in-range");
        me.registerProp("/instrumentation/eicas/master/caution", "/instrumentation/eicas/master/caution");
        me.registerProp("/instrumentation/eicas/master/warning", "/instrumentation/eicas/master/warning");
        me.registerProp("/instrumentation/gps/cdi-deflection", "/instrumentation/gps/cdi-deflection");
        me.registerProp("/instrumentation/gps/desired-course-deg", "/instrumentation/gps/desired-course-deg");
        me.registerProp("/instrumentation/iru/outputs/valid-att", "/instrumentation/iru[" ~ me.side ~ "]/outputs/valid-att");
        me.registerProp("/instrumentation/iru/outputs/valid", "/instrumentation/iru[" ~ me.side ~ "]/outputs/valid");
        me.registerProp("/instrumentation/marker-beacon/inner", "/instrumentation/marker-beacon/inner");
        me.registerProp("/instrumentation/marker-beacon/middle", "/instrumentation/marker-beacon/middle");
        me.registerProp("/instrumentation/marker-beacon/outer", "/instrumentation/marker-beacon/outer");
        me.registerProp("/instrumentation/nav[0]/frequencies/selected-mhz", "/instrumentation/nav[0]/frequencies/selected-mhz");
        me.registerProp("/instrumentation/nav[0]/frequencies/standby-mhz", "/instrumentation/nav[0]/frequencies/standby-mhz");
        me.registerProp("/instrumentation/nav[0]/from-flag", "/instrumentation/nav[0]/from-flag");
        me.registerProp("/instrumentation/nav[0]/gs-in-range", "/instrumentation/nav[0]/gs-in-range");
        me.registerProp("/instrumentation/nav[0]/gs-needle-deflection-norm", "/instrumentation/nav[0]/gs-needle-deflection-norm");
        me.registerProp("/instrumentation/nav[0]/has-gs", "/instrumentation/nav[0]/has-gs");
        me.registerProp("/instrumentation/nav[0]/heading-needle-deflection-norm", "/instrumentation/nav[0]/heading-needle-deflection-norm");
        me.registerProp("/instrumentation/nav[0]/in-range", "/instrumentation/nav[0]/in-range");
        me.registerProp("/instrumentation/nav[0]/nav-id", "/instrumentation/nav[0]/nav-id");
        me.registerProp("/instrumentation/nav[0]/nav-loc", "/instrumentation/nav[0]/nav-loc");
        me.registerProp("/instrumentation/nav[0]/radials/selected-deg", "/instrumentation/nav[0]/radials/selected-deg");
        me.registerProp("/instrumentation/nav[1]/frequencies/selected-mhz", "/instrumentation/nav[1]/frequencies/selected-mhz");
        me.registerProp("/instrumentation/nav[1]/frequencies/standby-mhz", "/instrumentation/nav[1]/frequencies/standby-mhz");
        me.registerProp("/instrumentation/nav[1]/from-flag", "/instrumentation/nav[1]/from-flag");
        me.registerProp("/instrumentation/nav[1]/gs-in-range", "/instrumentation/nav[1]/gs-in-range");
        me.registerProp("/instrumentation/nav[1]/gs-needle-deflection-norm", "/instrumentation/nav[1]/gs-needle-deflection-norm");
        me.registerProp("/instrumentation/nav[1]/has-gs", "/instrumentation/nav[1]/has-gs");
        me.registerProp("/instrumentation/nav[1]/heading-needle-deflection-norm", "/instrumentation/nav[1]/heading-needle-deflection-norm");
        me.registerProp("/instrumentation/nav[1]/in-range", "/instrumentation/nav[1]/in-range");
        me.registerProp("/instrumentation/nav[1]/nav-id", "/instrumentation/nav[1]/nav-id");
        me.registerProp("/instrumentation/nav[1]/nav-loc", "/instrumentation/nav[1]/nav-loc");
        me.registerProp("/instrumentation/nav[1]/radials/selected-deg", "/instrumentation/nav[1]/radials/selected-deg");
        me.registerProp("/instrumentation/pfd/airspeed-alive", "/instrumentation/pfd[" ~ me.side ~ "]/airspeed-alive");
        me.registerProp("/instrumentation/pfd/airspeed-lookahead-10s", "/instrumentation/pfd[" ~ me.side ~ "]/airspeed-lookahead-10s");
        me.registerProp("/instrumentation/pfd/alt-bug-offset", "/instrumentation/pfd[" ~ me.side ~ "]/alt-bug-offset");
        me.registerProp("/instrumentation/pfd/alt-tape-offset", "/instrumentation/pfd[" ~ me.side ~ "]/alt-tape-offset");
        me.registerProp("/instrumentation/pfd/alt-tape-thousands", "/instrumentation/pfd[" ~ me.side ~ "]/alt-tape-thousands");
        me.registerProp("/instrumentation/pfd/bearing[0]/bearing", "/instrumentation/pfd[" ~ me.side ~ "]/bearing[0]/bearing");
        me.registerProp("/instrumentation/pfd/bearing[0]/source", "/instrumentation/pfd[" ~ me.side ~ "]/bearing[0]/source");
        me.registerProp("/instrumentation/pfd/bearing[0]/visible", "/instrumentation/pfd[" ~ me.side ~ "]/bearing[0]/visible");
        me.registerProp("/instrumentation/pfd/bearing[1]/bearing", "/instrumentation/pfd[" ~ me.side ~ "]/bearing[1]/bearing");
        me.registerProp("/instrumentation/pfd/bearing[1]/source", "/instrumentation/pfd[" ~ me.side ~ "]/bearing[1]/source");
        me.registerProp("/instrumentation/pfd/bearing[1]/visible", "/instrumentation/pfd[" ~ me.side ~ "]/bearing[1]/visible");
        me.registerProp("/instrumentation/pfd/blink-state", "/instrumentation/pfd[" ~ me.side ~ "]/blink-state");
        me.registerProp("/instrumentation/pfd/dme/dist10", "/instrumentation/pfd[" ~ me.side ~ "]/dme/dist10");
        me.registerProp("/instrumentation/pfd/dme/ete", "/instrumentation/pfd[" ~ me.side ~ "]/dme/ete");
        me.registerProp("/instrumentation/pfd/dme/ete-unit", "/instrumentation/pfd[" ~ me.side ~ "]/dme/ete-unit");
        me.registerProp("/instrumentation/pfd/dme/hold", "/instrumentation/pfd[" ~ me.side ~ "]/dme/hold");
        me.registerProp("/instrumentation/pfd/dme/in-range", "/instrumentation/pfd[" ~ me.side ~ "]/dme/in-range");
        me.registerProp("/instrumentation/pfd/fd/lat-offset-deg", "/instrumentation/pfd[" ~ me.side ~ "]/fd/lat-offset-deg");
        me.registerProp("/instrumentation/pfd/fd/vert-offset-deg", "/instrumentation/pfd[" ~ me.side ~ "]/fd/vert-offset-deg");
        me.registerProp("/instrumentation/pfd/fd/pitch-scale", "/instrumentation/pfd[" ~ me.side ~ "]/fd/pitch-scale");
        me.registerProp("/instrumentation/pfd/fd/pitch-bar-scale", "/instrumentation/pfd[" ~ me.side ~ "]/fd/pitch-bar-scale");
        me.registerProp("/instrumentation/pfd/fma/ap", "/instrumentation/pfd[" ~ me.side ~ "]/fma/ap");
        me.registerProp("/instrumentation/pfd/fma/at", "/instrumentation/pfd[" ~ me.side ~ "]/fma/at");
        me.registerProp("/instrumentation/pfd/fma/vert-blink", "/instrumentation/pfd[" ~ me.side ~ "]/fma/vert-blink");
        me.registerProp("/instrumentation/pfd/fma/lat-blink", "/instrumentation/pfd[" ~ me.side ~ "]/fma/lat-blink");
        me.registerProp("/instrumentation/pfd/fma/spd-blink", "/instrumentation/pfd[" ~ me.side ~ "]/fma/spd-blink");
        me.registerProp("/instrumentation/pfd/groundspeed-kt", "/instrumentation/pfd[" ~ me.side ~ "]/groundspeed-kt");
        me.registerProp("/instrumentation/pfd/hsi/deflection", "/instrumentation/pfd[" ~ me.side ~ "]/hsi/deflection");
        me.registerProp("/instrumentation/pfd/hsi/from-flag", "/instrumentation/pfd[" ~ me.side ~ "]/hsi/from-flag");
        me.registerProp("/instrumentation/pfd/hsi/heading", "/instrumentation/pfd[" ~ me.side ~ "]/hsi/heading");
        me.registerProp("/instrumentation/pfd/ils/gs-in-range", "/instrumentation/pfd[" ~ me.side ~ "]/ils/gs-in-range");
        me.registerProp("/instrumentation/pfd/ils/gs-needle", "/instrumentation/pfd[" ~ me.side ~ "]/ils/gs-needle");
        me.registerProp("/instrumentation/pfd/ils/has-gs", "/instrumentation/pfd[" ~ me.side ~ "]/ils/has-gs");
        me.registerProp("/instrumentation/pfd/ils/has-loc", "/instrumentation/pfd[" ~ me.side ~ "]/ils/has-loc");
        me.registerProp("/instrumentation/pfd/ils/loc-in-range", "/instrumentation/pfd[" ~ me.side ~ "]/ils/loc-in-range");
        me.registerProp("/instrumentation/pfd/ils/loc-needle", "/instrumentation/pfd[" ~ me.side ~ "]/ils/loc-needle");
        me.registerProp("/instrumentation/pfd/ils/source", "/instrumentation/pfd[" ~ me.side ~ "]/ils/source");
        me.registerProp("/instrumentation/pfd/minimums-baro", "/instrumentation/pfd[" ~ me.side ~ "]/minimums-baro");
        me.registerProp("/instrumentation/pfd/minimums-decision-altitude", "/instrumentation/pfd[" ~ me.side ~ "]/minimums-decision-altitude");
        me.registerProp("/instrumentation/pfd/minimums-indicator-visible", "/instrumentation/pfd[" ~ me.side ~ "]/minimums-indicator-visible");
        me.registerProp("/instrumentation/pfd/minimums-mode", "/instrumentation/pfd[" ~ me.side ~ "]/minimums-mode");
        me.registerProp("/instrumentation/pfd/minimums-radio", "/instrumentation/pfd[" ~ me.side ~ "]/minimums-radio");
        me.registerProp("/instrumentation/pfd/minimums-visible", "/instrumentation/pfd[" ~ me.side ~ "]/minimums-visible");
        me.registerProp("/instrumentation/pfd/nav/course-source", "/instrumentation/pfd[" ~ me.side ~ "]/nav/course-source");
        me.registerProp("/instrumentation/pfd/nav/course-source-type", "/instrumentation/pfd[" ~ me.side ~ "]/nav/course-source-type");
        me.registerProp("/instrumentation/pfd/nav/dme-source", "/instrumentation/pfd[" ~ me.side ~ "]/nav/dme-source");
        me.registerProp("/instrumentation/pfd/nav/selected-radial", "/instrumentation/pfd[" ~ me.side ~ "]/nav/selected-radial");
        me.registerProp("/instrumentation/pfd/nav-src", "/instrumentation/pfd[" ~ me.side ~ "]/nav-src");
        me.registerProp("/instrumentation/pfd/pitch-scale", "/instrumentation/pfd[" ~ me.side ~ "]/pitch-scale");
        me.registerProp("/instrumentation/pfd/fpa-pitch-scale", "/instrumentation/pfd[" ~ me.side ~ "]/fpa-pitch-scale");
        me.registerProp("/instrumentation/pfd/fpa-scale", "/instrumentation/pfd[" ~ me.side ~ "]/fpa-scale");
        me.registerProp("/instrumentation/pfd/preview", "/instrumentation/pfd[" ~ me.side ~ "]/preview");
        me.registerProp("/instrumentation/pfd/qnh-mode", "/instrumentation/pfd[" ~ me.side ~ "]/qnh-mode");
        me.registerProp("/instrumentation/pfd/radio-altimeter-visible", "/instrumentation/pfd[" ~ me.side ~ "]/radio-altimeter-visible");
        me.registerProp("/instrumentation/pfd/radio-alt", "/instrumentation/pfd[" ~ me.side ~ "]/radio-alt");
        me.registerProp("/instrumentation/pfd/track-error-deg", "/instrumentation/pfd[" ~ me.side ~ "]/track-error-deg");
        me.registerProp("/instrumentation/pfd/vsi-needle-deg", "/instrumentation/pfd[" ~ me.side ~ "]/vsi-needle-deg");
        me.registerProp("/instrumentation/pfd/vsi-target-deg", "/instrumentation/pfd[" ~ me.side ~ "]/vsi-target-deg");
        me.registerProp("/instrumentation/pfd/waypoint/dist10", "/instrumentation/pfd[" ~ me.side ~ "]/waypoint/dist10");
        me.registerProp("/instrumentation/pfd/waypoint/ete", "/instrumentation/pfd[" ~ me.side ~ "]/waypoint/ete");
        me.registerProp("/instrumentation/pfd/waypoint/ete-unit", "/instrumentation/pfd[" ~ me.side ~ "]/waypoint/ete-unit");
        me.registerProp("/instrumentation/slip-skid-ball/indicated-slip-skid", "/instrumentation/slip-skid-ball/indicated-slip-skid");
        me.registerProp("/instrumentation/tcas/inputs/mode", "/instrumentation/tcas/inputs/mode");
        me.registerProp("/instrumentation/vertical-speed-indicator/indicated-speed-fpm", "/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
        me.registerProp("/it-autoflight/fd/pitch-bar", "/it-autoflight/fd/pitch-bar");
        me.registerProp("/it-autoflight/fd/roll-bar", "/it-autoflight/fd/roll-bar");
        me.registerProp("/it-autoflight/input/alt", "/it-autoflight/input/alt");
        me.registerProp("/it-autoflight/input/fpa", "/it-autoflight/input/fpa");
        me.registerProp("/it-autoflight/input/hdg", "/it-autoflight/input/hdg");
        me.registerProp("/it-autoflight/input/kts-mach", "/it-autoflight/input/kts-mach");
        me.registerProp("/it-autoflight/input/kts", "/it-autoflight/input/kts");
        me.registerProp("/it-autoflight/input/mach", "/it-autoflight/input/mach");
        me.registerProp("/it-autoflight/input/vs", "/it-autoflight/input/vs");
        me.registerProp("/it-autoflight/mode/arm", "/it-autoflight/mode/arm");
        me.registerProp("/it-autoflight/mode/lat", "/it-autoflight/mode/lat");
        me.registerProp("/it-autoflight/mode/thr", "/it-autoflight/mode/thr");
        me.registerProp("/it-autoflight/mode/vert", "/it-autoflight/mode/vert");
        me.registerProp("/it-autoflight/output/ap1", "/it-autoflight/output/ap1");
        me.registerProp("/it-autoflight/output/appr-armed", "/it-autoflight/output/appr-armed");
        me.registerProp("/it-autoflight/output/athr", "/it-autoflight/output/athr");
        me.registerProp("/it-autoflight/output/fd", "/it-autoflight/output/fd" ~ (me.side + 1));
        me.registerProp("/it-autoflight/output/lnav-armed", "/it-autoflight/output/lnav-armed");
        me.registerProp("/it-autoflight/output/loc-armed", "/it-autoflight/output/loc-armed");
        me.registerProp("/orientation/heading-deg", "/orientation/heading-deg");
        me.registerProp("/orientation/heading-magnetic-deg", "/orientation/heading-magnetic-deg");
        me.registerProp("/orientation/roll-deg", "/orientation/roll-deg");
        me.registerProp("/position/gear-agl-ft", "/position/gear-agl-ft");
        me.registerProp("/velocities/groundspeed-kt", "/velocities/groundspeed-kt");
    },

    postInit: func () {
        me.ilscolor = [0,1,0];
    },

    font_mapper: func(family, weight) {
        return "e190.ttf";
    },

    makeMasterGroup: func (group) {
        call(canvas_base.BaseScreen.makeMasterGroup, [group], me);
        canvas.parsesvg(group, "Aircraft/E-jet-family/Models/Primus-Epic/PFD.svg", { 'font-mapper': me.font_mapper });
    },

    registerElems: func () {
        var ks = [
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
            "fma.spd.bg",
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
            "nav1.label",
            "nav1.clickbox",
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
            "vhf1.label",
            "vhf1.clickbox",
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
        me.registerElemsFrom(ks);
    },

    getAtlasGroupName: func "PFD",

    getAtlasItems: func {
        return {
            'alt.tape.scale': {
                srcRect: [ 0, 0, 128, 1472 ],
                refOffset: [ 32, 896 ],
                refPos: [ 776, 446 ],
            },
            'horizon.scale': {
                srcRect: [ 256, 0, 256, 1408 ],
                refOffset: [ 384, 704 ],
                refPos: [ 473, 447 ],
            },
            'mask': {
                srcRect: [ 512, 1024, 1024, 768 ],
                refOffset: [ 512, 1024 ],
                refPos: [ 0, 0 ],
            },
            'compass.rose': {
                srcRect: [ 512, 0, 512, 512 ],
                refOffset: [ 768, 256 ],
                refPos: [ 472, 1094 ],
            },
            'compass.numbers': {
                srcRect: [ 512, 512, 512, 512 ],
                refOffset: [ 768, 768 ],
                refPos: [ 472, 1094 ],
            },

            'alt.10000.nonzero': {
                srcRect: [ 58, 1536, 22, 488 ],
                refOffset: [58, 2048 ],
                refPos: [ 804, 446 ],
            },
            'alt.10000.z': {
                srcRect: [ 58, 2024, 22, 88 ],
                refOffset: [ 58, 2048 ],
                refPos: [ 804, 446 ],
            },
            'alt.10000.pos': {
                srcRect: [ 58, 2304, 22, 64 ],
                refOffset: [58, 2336 ],
                refPos: [ 804, 446 ],
            },
            'alt.10000.neg': {
                srcRect: [ 58, 2112, 22, 64 ],
                refOffset: [ 58, 2144 ],
                refPos: [ 804, 488 ],
            },

            'alt.1000.nonzero': {
                srcRect: [ 58, 1536, 22, 488 ],
                refOffset: [58, 2048 ],
                refPos: [ 826, 446 ],
            },
            'alt.1000.z': {
                srcRect: [ 58, 2024, 22, 88 ],
                refOffset: [ 58, 2048 ],
                refPos: [ 826, 446 ],
            },
            'alt.1000.pos': {
                srcRect: [ 58, 2304, 22, 64 ],
                refOffset: [58, 2336 ],
                refPos: [ 826, 446 ],
            },
            'alt.1000.neg': {
                srcRect: [ 58, 2176, 22, 64 ],
                refOffset: [ 58, 2208 ],
                refPos: [ 826, 488 ],
            },

            'alt.100.nonzero': {
                srcRect: [ 58, 1536, 22, 488 ],
                refOffset: [58, 2048 ],
                refPos: [ 848, 446 ],
            },
            'alt.100.z': {
                srcRect: [ 58, 2024, 22, 88 ],
                refOffset: [ 58, 2048 ],
                refPos: [ 848, 446 ],
            },
            'alt.100.pos': {
                srcRect: [ 58, 2304, 22, 64 ],
                refOffset: [58, 2336 ],
                refPos: [ 848, 446 ],
            },
            'alt.100.neg': {
                srcRect: [ 58, 2240, 22, 64 ],
                refOffset: [ 58, 2272 ],
                refPos: [ 848, 488 ],
            },

            'alt.rollingdigits.pos': {
                srcRect: [ 82, 1536, 36, 320 ],
                refOffset: [ 82, 1792 ],
                refPos: [ 871, 446 ],
            },
            'alt.rollingdigits.neg': {
                srcRect: [ 82, 1856, 36, 336 ],
                refOffset: [ 82, 1952 ],
                refPos: [ 871, 446 ],
            },
            'alt.rollingdigits.zero': {
                srcRect: [ 82, 2192, 36, 512 ],
                refOffset: [ 82, 2448 ],
                refPos: [ 871, 446 ],
            },

            'asi.tape': {
                srcRect: [ 128, 0, 128, 3200 ],
                refOffset: [ 248, 3136 ],
                refPos: [ 160, 448 ],
            },
            'asi.100': {
                srcRect: [ 0, 1536, 27, 832 ],
                refOffset: [ 0, 2240 ],
                refPos: [ 23, 448 ],
            },
            'asi.10': {
                srcRect: [ 29, 1536, 27, 832 ],
                refOffset: [ 29, 2240 ],
                refPos: [ 58, 448 ],
            },
            'asi.1': {
                srcRect: [ 29, 1536, 27, 832 ],
                refOffset: [ 29, 2240 ],
                refPos: [ 92, 448 ],
            },
        };
    },

    postInit: func () {
        me.h_trans = me.elems["horizon"].createTransform();
        me.h_rot = me.elems["horizon"].createTransform();

        me.elems["VNAV.constraints1"].hide();
        me.elems["VNAV.constraints2"].hide();
    },

    swapCommFreqs: func () {
        var sby = me.props['/instrumentation/comm[0]/frequencies/standby-mhz'];
        var act = me.props['/instrumentation/comm[0]/frequencies/selected-mhz'];
        var buf = act.getValue();
        act.setValue(sby.getValue());
        sby.setValue(buf);
    },

    swapNavFreqs: func () {
        var sby = me.props['/instrumentation/nav[0]/frequencies/standby-mhz'];
        var act = me.props['/instrumentation/nav[0]/frequencies/selected-mhz'];
        var buf = act.getValue();
        act.setValue(sby.getValue());
        sby.setValue(buf);
    },

    clickComm: func () {
        if (me.focus == FOCUS_COM) {
            me.swapCommFreqs();
        }
        else {
            me.focus = FOCUS_COM;
            me.updateFocus();
        }
    },

    clickNav: func () {
        if (me.focus == FOCUS_NAV) {
            me.swapNavFreqs();
        }
        else {
            me.focus = FOCUS_NAV;
            me.updateFocus();
        }
    },

    scrollComm: func (amount, which) {
        if (me.focus == FOCUS_COM) {
            var p = me.props['/instrumentation/comm[0]/frequencies/standby-mhz'];
            if (which == 0) {
                # outer ring
                var val = p.getValue() + amount;
                p.setValue(val);
            }
            else {
                # inner ring
                var mode = me.props['/instrumentation/comm[0]/spacing'].getValue();
                var val = p.getValue();
                if (amount > 0)
                    val = frequencies.nextComChannel(val, mode);
                else
                    val = frequencies.prevComChannel(val, mode);
                p.setValue(val);
            }
        }
    },

    scrollNav: func (amount, which) {
        if (me.focus == FOCUS_NAV) {
            var p = me.props['/instrumentation/nav[0]/frequencies/standby-mhz'];
            if (which == 0) {
                # outer ring
                var val = p.getValue() + amount;
                p.setValue(val);
            }
            else {
                # inner ring
                if (amount > 0)
                    val = p.getValue() + 0.05;
                else
                    val = p.getValue() - 0.05;
                p.setValue(val);
            }
        }
    },

    updateFocus: func () {
        if (me.focus == FOCUS_COM)
            me.elems['vhf1.clickbox'].setColor(0, 1, 1);
        else
            me.elems['vhf1.clickbox'].setColor(0.5, 0.5, 0.5);
        if (me.focus == FOCUS_NAV)
            me.elems['nav1.clickbox'].setColor(0, 1, 1);
        else
            me.elems['nav1.clickbox'].setColor(0.5, 0.5, 0.5);
    },

    masterClick: func () {
        me.focus = FOCUS_NONE;
        me.updateFocus();
    },

    makeWidgets: func () {
        var self = me;

        call(canvas_base.BaseScreen.makeWidgets, [], me);

        me.addWidget('vhf1.clickbox',
            {
                onclick: func () { self.clickComm(); },
                onscroll: func (amount, which) { self.scrollComm(amount, which); },
            }, me.master);
        me.addWidget('nav1.clickbox',
            {
                onclick: func () { self.clickNav(); },
                onscroll: func (amount, which) { self.scrollNav(amount, which); },
            }, me.master);
    },

    registerListeners: func () {
        var self = me;

        call(canvas_base.BaseScreen.registerListeners, [], me);

        # bearing pointers / sources
        me.addListener('main', "@/instrumentation/pfd/bearing[0]/source", func (node) {
            var hsiLabelText = ["----", "VOR1", "ADF1", "FMS1"];
            var mode = node.getValue();
            self.elems["hsi.label.circle"].setText(hsiLabelText[mode]);
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/bearing[1]/source", func (node) {
            var hsiLabelText = ["----", "VOR2", "ADF2", "FMS2"];
            var mode = node.getValue();
            self.elems["hsi.label.diamond"].setText(hsiLabelText[mode]);
        }, 1, 0);

        # selected heading
        me.addListener('main', "@/it-autoflight/input/hdg", func (node) {
            var selectedheading = node.getValue() or 0;
            self.elems["selectedheading.digital"].setText(sprintf("%03d", selectedheading));
            self.elems["selectedheading.pointer"].setRotation(selectedheading * D2R);
        }, 1, 0);

        # wind speed
        me.addListener('main', "@/environment/wind-speed-kt", func (node) {
            var windSpeed = node.getValue() or 0;
            if (windSpeed > 1) {
                self.elems["wind.pointer"].show();
            }
            else {
                self.elems["wind.pointer"].hide();
            }
            self.elems["wind.kt"].setText(sprintf("%u", windSpeed));
        }, 1, 0);

        # selected altitude
        me.addListener('main', "@/controls/flight/selected-alt", func (node) {
            self.elems["selectedalt.digital100"].setText(sprintf("%02d", (node.getValue() or 0) * 0.01));
        }, 1, 0);

        # comm/nav
        var vhfFormat = "%7.3f";
        var vorFormat = "%6.2f";
        me.addListener('main', "@/instrumentation/comm[0]/frequencies/selected-mhz", func (node) {
            self.elems["vhf1.act"].setText(sprintf(vhfFormat, node.getValue() or 0));
        }, 1, 0);
        me.addListener('main', "@/instrumentation/comm[0]/frequencies/standby-mhz", func (node) {
            self.elems["vhf1.sby"].setText(sprintf(vhfFormat, node.getValue() or 0));
        }, 1, 0);
        me.addListener('main', "@/instrumentation/nav[0]/frequencies/selected-mhz", func (node) {
            self.elems["nav1.act"].setText(sprintf(vorFormat, node.getValue() or 0));
        }, 1, 0);
        me.addListener('main', "@/instrumentation/nav[0]/frequencies/standby-mhz", func (node) {
            self.elems["nav1.sby"].setText(sprintf(vorFormat, node.getValue() or 0));
        }, 1, 0);

        # VNAV annunciations
        # TODO

        # V-speed previews
        me.addListener('main', "@/fms/vspeeds-effective/departure/v1", func (node) {
            self.elems["asi.preview-v1.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0);
        me.addListener('main', "@/fms/vspeeds-effective/departure/vr", func (node) {
            self.elems["asi.preview-vr.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0);
        me.addListener('main', "@/fms/vspeeds-effective/departure/v2", func (node) {
            self.elems["asi.preview-v2.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0);
        me.addListener('main', "@/fms/vspeeds-effective/departure/vfs", func (node) {
            self.elems["asi.preview-vfs.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/airspeed-alive", func (node) {
            self.elems["asi.vspeeds"].setVisible(!node.getBoolValue());
        }, 1, 0);

        # QNH
        var updateQNH = func {
            if (self.props["/instrumentation/pfd/qnh-mode"].getValue()) {
                # 1 = inhg
                self.elems["QNH.digital"].setText(
                    sprintf("%5.2f", self.props["/instrumentation/altimeter/setting-inhg"].getValue()));
                self.elems["QNH.unit"].setText("IN");
            }
            else {
                # 0 = hpa
                self.elems["QNH.digital"].setText(
                    sprintf("%4.0f", self.props["/instrumentation/altimeter/setting-hpa"].getValue()));
                self.elems["QNH.unit"].setText("HPA");
            }
        };
        me.addListener('main', "@/instrumentation/pfd/qnh-mode", updateQNH, 1, 0);
        me.addListener('main', "@/instrumentation/altimeter/setting-inhg", updateQNH, 1, 0);
        me.addListener('main', "@/instrumentation/altimeter/setting-hpa", updateQNH, 1, 0);

        var updateNavAnn = func () {
            var navsrc = self.props["/instrumentation/pfd/nav-src"].getValue() or 0;
            var preview = self.props["/instrumentation/pfd/preview"].getValue() or 0;

            if (navsrc == 0) {
                self.elems["navsrc.primary.selection"].setText("FMS");
                self.elems["navsrc.primary.selection"].setColor(1, 0, 1);
                self.elems["navsrc.primary.id"].setText("");

                if (preview) {
                    self.elems["navsrc.preview"].show();
                    if (self.props["/instrumentation/nav[" ~ (preview - 1) ~ "]/nav-loc"].getValue() or 0) {
                        self.elems["navsrc.preview.selection"].setText("LOC" ~ preview);
                    }
                    else {
                        self.elems["navsrc.preview.selection"].setText("VOR" ~ preview);
                    }
                    self.elems["navsrc.preview.id"].setText(self.props["/instrumentation/nav[" ~ (preview - 1) ~ "]/nav-id"].getValue() or "");
                }
                else {
                    self.elems["navsrc.preview"].hide();
                }
            }
            else {
                self.elems["navsrc.primary"].show();
                if (self.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/nav-loc"].getValue() or 0) {
                    self.elems["navsrc.primary.selection"].setText("LOC" ~ navsrc);
                }
                else {
                    self.elems["navsrc.primary.selection"].setText("VOR" ~ navsrc);
                }
                self.elems["navsrc.primary.selection"].setColor(0, 1, 0);
                self.elems["navsrc.primary.id"].setText(self.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/nav-id"].getValue() or "");
                self.elems["navsrc.primary.id"].setColor(0, 1, 0);
                self.elems["navsrc.preview"].hide();
            }
        };
        me.addListener('main', "@/instrumentation/pfd/preview", func { updateNavAnn(); }, 1, 0);
        me.addListener('main', "@/instrumentation/nav[0]/nav-loc", func { updateNavAnn(); }, 1, 0);
        me.addListener('main', "@/instrumentation/nav[0]/nav-id", func { updateNavAnn(); }, 1, 0);
        me.addListener('main', "@/instrumentation/nav[1]/nav-loc", func { updateNavAnn(); }, 1, 0);
        me.addListener('main', "@/instrumentation/nav[1]/nav-id", func { updateNavAnn(); }, 1, 0);


        me.addListener('main', "@/controls/flight/nav-src/side",
            func (node) {
                if (node.getBoolValue()) {
                    self.elems["fma.src.arrow"].setRotation(math.pi);
                }
                else {
                    self.elems["fma.src.arrow"].setRotation(0);
                }
            }, 1, 0);

        me.addListener('main', "@/instrumentation/pfd/bearing[0]/visible",
            func (node) { self.elems["hsi.pointer.circle"].setVisible(node.getBoolValue()); },
            1, 0);
        me.addListener('main', "@/instrumentation/pfd/bearing[0]/bearing",
            func (node) { self.elems["hsi.pointer.circle"].setRotation(node.getValue() * D2R); },
            1, 0);
        me.addListener('main', "@/instrumentation/pfd/bearing[1]/visible",
            func (node) { self.elems["hsi.pointer.diamond"].setVisible(node.getBoolValue()); },
            1, 0);
        me.addListener('main', "@/instrumentation/pfd/bearing[1]/bearing",
            func (node) { self.elems["hsi.pointer.diamond"].setRotation(node.getValue() * D2R); },
            1, 0);

        me.addListener('main', "@/instrumentation/pfd/nav-src",
            func (node) {
                var courseColor = [0, 1, 0];
                var hsiColor = [0, 1, 0];

                if (node.getValue() == 0) {
                    courseColor = [0, 0.75, 1];
                    hsiColor = [1, 0, 1];
                    self.elems["ils.fmsloc"].show();
                    self.elems["ils.fmsvert"].show();
                }
                else {
                    self.elems["ils.fmsloc"].hide();
                    self.elems["ils.fmsvert"].hide();
                }
                self.elems["selectedcourse.digital"].setColorFill(courseColor[0], courseColor[1], courseColor[2]);
                self.elems["hsi.nav1"].setColor(hsiColor[0], hsiColor[1], hsiColor[2]);
                self.elems["hsi.nav1track"].setColor(hsiColor[0], hsiColor[1], hsiColor[2]);
                updateNavAnn();
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/nav/course-source",
            func (node) {
                if (node.getValue() == 0) {
                    self.elems["selectedcourse.digital"].hide();
                }
                else {
                    self.elems["selectedcourse.digital"].show();
                }
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/nav/selected-radial",
            func (node) {
                self.elems["selectedcourse.digital"].setText(sprintf("%03d", node.getValue()));
            }, 1, 0);

        # DME
        me.addListener('main', "@/instrumentation/pfd/nav/dme-source", func (node) {
            var dmesrc = node.getValue();
            self.clearListeners('dme');
            if (dmesrc > 0) {
                self.elems["dme"].show();
                self.elems["dme.selection"].setText("DME" ~ dmesrc);
                self.addListener('dme', "@/instrumentation/nav[" ~ (dmesrc - 1) ~ "]/nav-id",
                    func (node) {
                        self.elems["dme.id"].setText(node.getValue() or "");
                    }, 1, 0);
            }
            else {
                self.elems["dme"].hide();
            }
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/dme/dist10", func (node) {
            self.elems["dme.dist"].setText(sprintf("%5.1f", node.getValue() * 0.1));
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/dme/ete", func (node) {
            var ete = node.getValue();
            if (ete >= 600) {
                self.elems["dme.ete"].setText("+++");
            }
            else {
                self.elems["dme.ete"].setText(sprintf("%3.0d", ete));
            }
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/dme/ete-unit", func (node) {
            if (node.getValue()) {
                self.elems["dme.eteunit"].setText("MIN");
            }
            else {
                self.elems["dme.eteunit"].setText("SEC");
            }
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/dme/hold", func (node) {
            self.elems["dme.hold"].setVisible(node.getBoolValue());
        }, 1, 0);

        # HSI
        me.addListener('main', "@/instrumentation/pfd/hsi/heading",
            func (node) {
                var hsiHeading = node.getValue() * D2R;
                self.elems["hsi.nav1"].setRotation(hsiHeading);
                self.elems["hsi.dots"].setRotation(hsiHeading);
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/hsi/deflection",
            func (node) {
                self.elems["hsi.nav1track"].setTranslation(node.getValue() * 120, 0);
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/hsi/from-flag",
            func (node) {
                var flag = node.getValue();
                self.elems["hsi.from"].setVisible(flag == 1);
                self.elems["hsi.to"].setVisible(flag == 0);
            }, 1, 0);

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
            self.elems["ils.gsneedle"].setColor(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
            if (gsInRange) {
                self.elems["ils.gsneedle"].setColorFill(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
            }
            else {
                self.elems["ils.gsneedle"].setColorFill(0, 0, 0);
            }
            self.elems["ils.locneedle"].setColor(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
            if (locInRange) {
                self.elems["ils.locneedle"].setColorFill(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
            }
            else {
                self.elems["ils.locneedle"].setColorFill(0, 0, 0);
            }
        };
        me.addListener('main', "@/instrumentation/pfd/ils/source", updateILSColors, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/nav-src", updateILSColors, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/ils/gs-in-range", updateILSColors, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/ils/loc-in-range", updateILSColors, 1, 0);

        me.addListener('main', "@/instrumentation/pfd/ils/has-gs", func (node) {
                self.elems["ils.gsneedle"].setVisible(node.getBoolValue());
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/ils/has-loc", func (node) {
                self.elems["ils.locneedle"].setVisible(node.getBoolValue());
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/ils/gs-needle", func (node) {
                self.elems["ils.gsneedle"].setTranslation(0, math.round((node.getValue() or 0) * -100.0));
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/ils/loc-needle", func (node) {
                self.elems["ils.locneedle"].setTranslation(math.round((node.getValue() or 0) * 100.0), 0);
            }, 1, 0);

        me.addListener('main', "@/autopilot/route-manager/active", func (node) {
            self.elems["waypoint"].setVisible(node.getBoolValue());
            }, 1, 0);

        me.addListener('main', "@/autopilot/route-manager/wp/id", func (node) {
                var id = node.getValue();
                if (id == nil)
                    id = '';
                if (id == 'DISCONTINUITY')
                    id = '----';
                self.elems["waypoint.id"].setText(id);
            }, 1, 0);

        me.addListener('main', "@/instrumentation/pfd/waypoint/dist10", func (node) {
            self.elems["waypoint.dist"].setText(
                sprintf("%5.1f", (node.getValue() or 0) * 0.1));
            }, 1, 0);

        me.addListener('main', "@/instrumentation/pfd/waypoint/ete", func (node) {
                self.elems["waypoint.ete"].setText(sprintf("%3d", node.getValue()));
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/waypoint/ete-unit", func (node) {
                if (node.getBoolValue()) {
                    self.elems["waypoint.eteunit"].setText("MIN");
                }
                else {
                    self.elems["waypoint.eteunit"].setText("SEC");
                }
            }, 1, 0);

        # FMA
        me.addListener('main', "@/instrumentation/pfd/fma/ap", func (node) {
                var mode = node.getValue() or 0;
                if (mode == 0) {
                    self.elems["fma.ap"].hide();
                    self.elems["fma.ap.bg"].hide();
                }
                elsif (mode == 1) {
                    self.elems["fma.ap"].show();
                    self.elems["fma.ap.bg"].hide();
                    self.elems["fma.ap"].setColor(0, 1, 0);
                }
                elsif (mode == 2) {
                    self.elems["fma.ap"].show();
                    self.elems["fma.ap.bg"].hide();
                    self.elems["fma.ap"].setColor(1, 0, 0);
                }
                elsif (mode == 3) {
                    self.elems["fma.ap"].show();
                    self.elems["fma.ap.bg"].show();
                    self.elems["fma.ap"].setColor(0, 0, 0);
                }
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/fma/at", func (node) {
                var mode = node.getValue() or 0;
                if (mode == 0) {
                    self.elems["fma.at"].hide();
                    self.elems["fma.at.bg"].hide();
                }
                elsif (mode == 1) {
                    self.elems["fma.at"].show();
                    self.elems["fma.at.bg"].hide();
                    self.elems["fma.at"].setColor(0, 1, 0);
                }
                elsif (mode == 2) {
                    self.elems["fma.at"].show();
                    self.elems["fma.at.bg"].hide();
                    self.elems["fma.at"].setColor(1, 0, 0);
                }
                elsif (mode == 3) {
                    self.elems["fma.at"].show();
                    self.elems["fma.at.bg"].show();
                    self.elems["fma.at"].setColor(0, 0, 0);
                }
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/fma/vert-blink", func (node) {
                self.updateFMAColorsVert();
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/fma/lat-blink", func (node) {
                self.updateFMAColorsLat();
            }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/fma/spd-blink", func (node) {
                self.updateFMAColorsSpd();
            }, 1, 0);
        me.addListener('main', "/instrumentation/annun/lat-mode", func (node) {
                self.elems["fma.lat"].setText(node.getValue());
                self.updateFMAColorsLat();
            }, 1, 0);
        me.addListener('main', "/instrumentation/annun/lat-mode-armed", func (node) {
                self.elems["fma.latarmed"].setText(node.getValue());
            }, 1, 0);
        me.addListener('main', "/instrumentation/annun/vert-mode", func (node) {
                var mode = node.getValue();
                self.elems["fma.vert"].setText(mode);
                self.updateFMAColorsVert();
            }, 1, 0);
        me.addListener('main', "/instrumentation/annun/vert-mode-armed", func (node) {
                var mode = node.getValue();
                self.elems["fma.vertarmed"].setText(mode);
            }, 1, 0);
        me.addListener('main', "/instrumentation/annun/spd-mode", func (node) {
                self.elems["fma.spd"].setText(node.getValue());
                self.updateFMAColorsSpd();
            }, 1, 0);
        me.addListener('main', "/instrumentation/annun/spd-mode-armed", func (node) {
                self.elems["fma.spdarmed"].setText(node.getValue());
            }, 1, 0);
        me.addListener('main', "/instrumentation/annun/spd-minor-mode", func (node) {
                self.elems["fma.spd.minor"].setText(node.getValue());
                self.updateFMAColorsSpd();
            }, 1, 0);
        me.addListener('main', "/instrumentation/annun/spd-minor-mode-armed", func (node) {
                self.elems["fma.spdarmed.minor"].setText(node.getValue());
            }, 1, 0);
        me.addListener('main', "/instrumentation/annun/appr-mode", func (node) {
                self.elems["fma.appr"].setText(node.getValue());
            }, 1, 0);
        me.addListener('main', "/instrumentation/annun/appr-mode-armed", func (node) {
                var value = node.getValue();
                self.elems["fma.apprarmed"].setText(value);
                if (value == 'APPR1 ONLY') {
                    self.elems["fma.apprarmed"].setColor(1, 0.5, 0);
                }
                else {
                    self.elems["fma.apprarmed"].setColor(1, 1, 1);
                }
            }, 1, 0);

        me.addListener('main', "@/instrumentation/iru/outputs/valid-att", func (node) {
                if (node.getBoolValue()) {
                    self.elems["horizon"].show();
                    self.elems["failure.att"].hide();
                }
                else {
                    self.elems["horizon"].hide();
                    self.elems["failure.att"].show();
                }
            }, 1, 0);
        me.addListener('main', "@/instrumentation/iru/outputs/valid", func (node) {
                if (node.getBoolValue()) {
                    self.elems["compass.numbers"].show();
                    self.elems["selectedheading.pointer"].show();
                    self.elems["heading.digital"].setColor(0, 1, 0);
                    self.elems["groundspeed"].setColor(0, 1, 0);
                    self.elems["failure.hdg"].hide();
                }
                else {
                    self.elems["compass.numbers"].hide();
                    self.elems["selectedheading.pointer"].hide();
                    self.elems["heading.digital"].setColor(1, 0.5, 0);
                    self.elems["heading.digital"].setText('---');
                    self.elems["groundspeed"].setColor(1, 0.5, 0);
                    self.elems["groundspeed"].setText('---');
                    self.elems["failure.hdg"].show();
                }
            }, 1, 0);

        var updateFDViz = func {
            var viz = self.props["/it-autoflight/output/fd"].getBoolValue();
            if (viz) {
                var vertMode = self.props["/it-autoflight/mode/vert"].getValue();
                if (vertMode == "T/O CLB" or vertMode == "G/A CLB") {
                    self.elems["fd.icon"].hide();
                    self.elems["fd.bars"].show();
                }
                else {
                    self.elems["fd.icon"].show();
                    self.elems["fd.bars"].hide();
                }
            }
            else {
                self.elems["fd.icon"].hide();
                self.elems["fd.bars"].hide();
            }
        };

        var updateSelectedVSpeed = func {
            var vertMode = self.props["/it-autoflight/mode/vert"].getValue();
            if (vertMode == "V/S") {
                self.elems["selectedvspeed.digital"].setText(sprintf("%+05d", (self.props["/it-autoflight/input/vs"].getValue() or 0)));
                self.elems["selectedvspeed.digital"].show();
                self.elems["vs.needle.target"].show();
                self.elems["fpa.target"].hide();
            }
            else if (vertMode == "FPA") {
                var fpaText = sprintf("%+4.1f", (self.props["/it-autoflight/input/fpa"].getValue() or 0));
                self.elems["selectedvspeed.digital"].setText(fpaText);
                self.elems["selectedvspeed.digital"].show();
                self.elems["vs.needle.target"].hide();
                self.elems["fpa.target.digital"].setText(fpaText);
                self.elems["fpa.target"].show();
            }
            else {
                self.elems["selectedvspeed.digital"].hide();
                self.elems["vs.needle.target"].hide();
                self.elems["fpa.target"].hide();
            }
        };

        me.addListener('main', "@/it-autoflight/output/fd", func {
            updateFDViz();
        }, 1, 0);
        me.addListener('main', "@/it-autoflight/mode/vert", func {
            updateSelectedVSpeed();
            updateFDViz();
        }, 1, 0);
        me.addListener('main', "@/it-autoflight/input/fpa", func {
            updateSelectedVSpeed();
        }, 1, 0);
        me.addListener('main', "@/it-autoflight/input/vs", func {
            updateSelectedVSpeed();
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/fpa-pitch-scale", func (node) {
            var fpaPitch = (self.props["/instrumentation/pfd/fpa-pitch-scale"].getValue() or 0);
            self.elems["fpa.target"].setTranslation(0,-fpaPitch*8.0);
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/vsi-target-deg", func (node) {
            var vneedle = self.props["/instrumentation/pfd/vsi-target-deg"].getValue() or 0;
            self.elems["vs.needle.target"].setRotation(vneedle * D2R);
        }, 1, 0);

        var updateSelectedSpeed = func {
            if (self.props["/it-autoflight/input/kts-mach"].getValue()) {
                var selectedMach = (self.props["/it-autoflight/input/mach"].getValue() or 0);
                self.elems["selectedspeed.digital"].setText(sprintf(".%03dM", selectedMach * 1000 + 0.5));
            }
            else {
                var selectedKts = (self.props["/it-autoflight/input/kts"].getValue() or 0);
                self.elems["selectedspeed.digital"].setText(sprintf("%03d", selectedKts));
            }
        };
        me.addListener('main', "@/it-autoflight/input/kts", updateSelectedSpeed, 1, 0);
        me.addListener('main', "@/it-autoflight/input/mach", updateSelectedSpeed, 1, 0);
        me.addListener('main', "@/it-autoflight/input/kts-mach", updateSelectedSpeed, 1, 0);

        me.addListener('main', "@/controls/flight/speed-mode", func(node) {
            if (node.getValue() == 1) {
                self.elems["selectedspeed.digital"].setColor(1, 0, 1);
            }
            else {
                self.elems["selectedspeed.digital"].setColor(0, 0.75, 1);
            }
        }, 1, 0);

        me.addListener('main', "@/instrumentation/pfd/alt-tape-offset", func(node) {
            self.elems["alt.tape"].setTranslation(0, node.getValue() * 0.45);
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/alt-bug-offset", func(node) {
            self.elems["alt.bug"].setTranslation(0, node.getValue() * 0.45);
        }, 1, 0);

        me.addListener('main', "@/instrumentation/pfd/alt-tape-thousands", func(node) {
            var altTapeThousands = node.getValue() * 1000;
            self.elems["altNumLow1"].setText(sprintf("%5.0f", altTapeThousands - 1000));
            self.elems["altNumHigh1"].setText(sprintf("%5.0f", altTapeThousands));
            self.elems["altNumHigh2"].setText(sprintf("%5.0f", altTapeThousands + 1000));
        }, 1, 0);

        # Minimums
        me.addListener('main', "@/instrumentation/pfd/radio-alt", func(node) {
            var ra = node.getValue();
            self.elems["radioalt.digital"].setText(sprintf("%04d", ra));
        }, 1, 0);
        self.elems["radioalt.digital"].setText(sprintf("%04d", 0));
        me.addListener('main', "@/instrumentation/pfd/minimums-visible", func(node) {
            self.elems["minimums"].setVisible(node.getBoolValue());
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/minimums-indicator-visible", func(node) {
            self.elems["minimums.indicator"].setVisible(node.getBoolValue());   
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/radio-altimeter-visible", func(node) {
            self.elems["radioalt"].setVisible(node.getBoolValue());   
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/minimums-mode", func(node) {
            if (node.getBoolValue()) {
                self.elems["minimums.barora"].setText("BARO");
                self.elems["minimums.digital"].setColor(1, 1, 0);
            }
            else {
                self.elems["minimums.barora"].setText("RA");
                self.elems["minimums.digital"].setColor(1, 1, 1);
            }
        }, 1, 0);
        me.addListener('main', "@/instrumentation/pfd/minimums-decision-altitude", func(node) {
            self.elems["minimums.digital"].setText(sprintf("%d", node.getValue()));
        }, 1, 0);
        me.addListener('main', "@/cpdlc/unread", func (node) {
            self.elems["atc.indicator"].setVisible(node.getValue() != 0);
        }, 1, 0);
        me.addListener('main', "@/acars/telex/unread", func (node) {
            self.elems["dlk.indicator"].setVisible(node.getValue() != 0);
        }, 1, 0);

        var updateEicasWarning = func () {
            var warning = self.props['/instrumentation/eicas/master/warning'].getBoolValue();
            var caution = self.props['/instrumentation/eicas/master/caution'].getBoolValue();
            if (warning) {
                self.elems["eicas.indicator.bg"].setColorFill(1, 0, 0);
                self.elems["eicas.indicator"].show();
            }
            elsif (caution) {
                self.elems["eicas.indicator.bg"].setColorFill(1, 1, 0);
                self.elems["eicas.indicator"].show();
            }
            else {
                self.elems["eicas.indicator"].hide();
            }
        };
        me.addListener('main', "@/instrumentation/eicas/master/warning", func (node) { updateEicasWarning(); }, 1, 0);
        me.addListener('main', "@/instrumentation/eicas/master/caution", func (node) { updateEicasWarning(); }, 1, 0);

        me.addListener('main', "@/instrumentation/marker-beacon/inner", func (node) {
            self.elems["marker.inner"].setVisible(node.getBoolValue());
        }, 1, 0);
        me.addListener('main', "@/instrumentation/marker-beacon/middle", func (node) {
            self.elems["marker.middle"].setVisible(node.getBoolValue());
        }, 1, 0);
        me.addListener('main', "@/instrumentation/marker-beacon/outer", func (node) {
            self.elems["marker.outer"].setVisible(node.getBoolValue());
        }, 1, 0);


        me.addListener('main', "@/instrumentation/tcas/inputs/mode", func (node) {
            var tcasMode = node.getValue();
            if (tcasMode == 3) {
                # TA/RA
                self.elems["tcas.warning"].hide();
            }
            elsif (tcasMode == 2) {
                # TA ONLY
                self.elems["tcas.warning"].setText('TA ONLY');
                self.elems["tcas.warning"].show();
            }
            else {
                # TA OFF
                self.elems["tcas.warning"].setText('TCAS OFF');
                self.elems["tcas.warning"].show();
            }
        }, 1, 0);
    },

    toggleBlink: func() {
        me.props["/instrumentation/pfd/blink-state"].toggleBoolValue();
    },

    updateFMAColorsVert: func () {
        var managed = me.props["/instrumentation/annun/vert-mode-managed"].getBoolValue();
        var state = me.props["/instrumentation/pfd/fma/vert-blink"].getBoolValue();
        if (state) {
            me.elems["fma.vert"].setColor(0, 0, 0);
            if (managed)
                me.elems["fma.vert.bg"].setColorFill(1, 0, 1);
            else
                me.elems["fma.vert.bg"].setColorFill(0, 1, 0);
        }
        else {
            me.elems["fma.vert.bg"].setColorFill(0, 0, 0);
            if (managed)
                me.elems["fma.vert"].setColor(1, 0, 1);
            else
                me.elems["fma.vert"].setColor(0, 1, 0);
        }
    },

    updateFMAColorsLat: func () {
        var managed = me.props["/instrumentation/annun/lat-mode-managed"].getBoolValue();
        var state = me.props["/instrumentation/pfd/fma/lat-blink"].getBoolValue();
        if (state) {
            me.elems["fma.lat"].setColor(0, 0, 0);
            if (managed)
                me.elems["fma.lat.bg"].setColorFill(1, 0, 1);
            else
                me.elems["fma.lat.bg"].setColorFill(0, 1, 0);
        }
        else {
            me.elems["fma.lat.bg"].setColorFill(0, 0, 0);
            if (managed)
                me.elems["fma.lat"].setColor(1, 0, 1);
            else
                me.elems["fma.lat"].setColor(0, 1, 0);
        }
    },

    updateFMAColorsSpd: func () {
        var state = me.props["/instrumentation/pfd/fma/spd-blink"].getBoolValue();
        if (state) {
            me.elems["fma.spd"].setColor(0, 0, 0);
            me.elems["fma.spd.minor"].setColor(0, 0, 0);
            me.elems["fma.spd.bg"].setColorFill(0, 1, 0);
        }
        else {
            me.elems["fma.spd"].setColor(0, 1, 0);
            me.elems["fma.spd.minor"].setColor(0, 1, 0);
            me.elems["fma.spd.bg"].setColorFill(0, 0, 0);
        }
    },

    updateSlow: func(dt) {
        call(canvas_base.BaseScreen.updateSlow, [dt], me);
        # CHR
        var t = me.props["/instrumentation/chrono/chrono/total"].getValue() or 0;
        me.elems["chrono.digital"].setText(sprintf("%02d:%02d", math.floor(t / 60), math.mod(t, 60)));
    },

    update: func(dt) {
        call(canvas_base.BaseScreen.update, [dt], me);
        var pitch = (me.props["/instrumentation/pfd/pitch-scale"].getValue() or 0);
        var roll =  me.props["/orientation/roll-deg"].getValue() or 0;
        var slip = me.props["/instrumentation/slip-skid-ball/indicated-slip-skid"].getValue() or 0;
        var trackError = me.props["/instrumentation/pfd/track-error-deg"].getValue() or 0;
        var fpaScaled = me.props["/instrumentation/pfd/fpa-scale"].getValue() or 0;
        me.h_trans.setTranslation(0,pitch*8.0);
        me.h_rot.setRotation(-roll*D2R,me.elems["horizon"].getCenter());
        if(math.abs(roll)<=45){
            me.elems["roll.pointer"].setRotation(roll*(-D2R));
        }
        me.elems["slip.pointer"].setTranslation(math.round(slip * -25), 0);
        if (math.abs(slip) >= 1.0)
            me.elems["slip.pointer"].setColorFill(1, 1, 1);
        else
            me.elems["slip.pointer"].setColorFill(0, 0, 0);

        # Heading
        var heading = me.props["/orientation/heading-magnetic-deg"].getValue() or 0;
        if (me.props["/instrumentation/iru/outputs/valid"].getBoolValue()) {
            # wind direction
            # For some reason, if we attempt to do this in a listener, it will
            # be extremely unreliable.
            me.elems["wind.pointer"].setRotation((me.props["/environment/wind-from-heading-deg"].getValue() or 0) * D2R);
            me.elems["wind.pointer.wrapper"].setRotation(heading * -D2R);
            me.elems["wind.pointer.wrapper"].show();
            me.elems["compass"].setRotation(heading * -D2R);
            me.elems["heading.digital"].setText(sprintf("%03d", heading));
            # groundspeed
            me.elems["groundspeed"].setText(
                sprintf("%3d", me.props["/instrumentation/pfd/groundspeed-kt"].getValue() or 0));
        }
        else {
            me.elems["wind.pointer.wrapper"].hide();
        }

        # FPV
        me.elems["fpv"]
            .setTranslation(geo.normdeg180(trackError) * 8.0, -fpaScaled * 8.0)
            .setRotation(roll * D2R);

        # FD
        var barPitch = me.props["/instrumentation/pfd/fd/pitch-bar-scale"].getValue() or 0;
        var barRoll = me.props["/it-autoflight/fd/roll-bar"].getValue() or 0;
        var trackError = me.props["/instrumentation/pfd/track-error-deg"].getValue() or 0;
        var fdPitch = me.props["/instrumentation/pfd/fd/pitch-scale"].getValue() or 0;
        var fdRoll = me.props["/instrumentation/pfd/fd/lat-offset-deg"].getValue() or 0;

        me.elems["fd.pitch"].setTranslation(0, (pitch - barPitch) * 8.0);
        me.elems["fd.roll"].setTranslation(barRoll * 8.0, 0);
        me.elems["fd.icon"]
            .setTranslation(
                geo.normdeg180(trackError + fdRoll) * 8.0,
                fdPitch * -8.0)
            .setRotation(roll * D2R);

        # V/S
        var vspeed = me.props["/instrumentation/vertical-speed-indicator/indicated-speed-fpm"].getValue() or 0;
        me.elems["VS.digital"].setText(sprintf("%+05d", vspeed));
        var vneedle = me.props["/instrumentation/pfd/vsi-needle-deg"].getValue() or 0;
        me.elems["vs.needle.current"].setRotation(vneedle * D2R);
        me.elems["VS.digital.wrapper"].setVisible(math.abs(vspeed) >= 500);

        # Altitude
        var alt = me.props["/instrumentation/altimeter/indicated-altitude-ft"].getValue() or 0;

        var o = odoDigit(alt / 10, 0);
        me.elems["alt.rollingdigits"].setTranslation(0, o * 18);
        if (alt >= 100) {
            me.elems["alt.rollingdigits.pos"].show();
            me.elems["alt.rollingdigits.zero"].hide();
            me.elems["alt.rollingdigits.neg"].hide();
        }
        else if (alt <= -100) {
            me.elems["alt.rollingdigits.pos"].hide();
            me.elems["alt.rollingdigits.zero"].hide();
            me.elems["alt.rollingdigits.neg"].show();
        }
        else {
            me.elems["alt.rollingdigits.pos"].hide();
            me.elems["alt.rollingdigits.zero"].show();
            me.elems["alt.rollingdigits.neg"].hide();
        }

        var altR = math.max(-20, alt);
        var o100 = odoDigit(altR / 10, 1);
        me.elems["alt.100"].setTranslation(0, o100 * 44);
        var o1000 = odoDigit(altR / 10, 2);
        me.elems["alt.1000"].setTranslation(0, o1000 * 44);
        var o10000 = odoDigit(altR / 10, 3);
        me.elems["alt.10000"].setTranslation(0, o10000 * 44);

        if (alt < 0) {
            me.elems["alt.100.tape"].hide();
            me.elems["alt.1000.tape"].hide();
            me.elems["alt.10000.tape"].hide();
            me.elems["alt.100.neg"].show();
            me.elems["alt.1000.neg"].show();
            me.elems["alt.10000.neg"].show();
        }
        else {
            me.elems["alt.100.tape"].show();
            me.elems["alt.1000.tape"].show();
            me.elems["alt.10000.tape"].show();
            me.elems["alt.100.neg"].hide();
            me.elems["alt.1000.neg"].hide();
            me.elems["alt.10000.neg"].hide();
        }

        if (alt < 5000) {
            me.elems["alt.1000.z"].hide();
        }
        else {
            me.elems["alt.1000.z"].show();
        }
        if (alt < 50000) {
            me.elems["alt.10000.z"].hide();
        }
        else {
            me.elems["alt.10000.z"].show();
        }

        if (alt < 1000) {
            me.elems["alt.1000.zero"].show();
        }
        else {
            me.elems["alt.1000.zero"].hide();
        }
        if (alt < 10000) {
            me.elems["alt.10000.zero"].show();
        }
        else {
            me.elems["alt.10000.zero"].hide();
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
        me.elems["mach.digital"].setText(sprintf(".%03d", currentMach * 1000));


        me.elems["speedtrend.vector"].reset();
        me.elems["speedtrend.vector"].rect(152, 450, 15,
            math.max(-40.0, math.min(40.0, (airspeedLookahead - airspeed))) * -6.42);

        me.elems["speederror.vector"].reset();
        me.elems["speederror.vector"].rect(419, 437, 10,
            math.max(-40.0, math.min(40.0, (selectedKts - airspeed))) * -2);
        me.elems["speedtrend.pointer"].setTranslation(
            0,
            math.max(-40.0, math.min(40.0, (airspeedLookahead - airspeed))) * -2);

        me.elems["asi.tape"].setTranslation(0,airspeed * 6.42);
        me.elems["airspeed.bug"].setTranslation(0, (airspeed-selectedKts) * 6.42);

        var redSpeed = me.props["/fms/speed-limits/vstall-kt"].getValue() or 0;
        var amberSpeed = me.props["/fms/speed-limits/vwarn-kt"].getValue() or 0;
        var greenSpeed = me.props["/fms/speed-limits/green-dot-kt"].getValue() or 0;
        var maxSpeed = me.props["/fms/speed-limits/vmo-effective"].getValue() or 0;

        me.elems["speedbar.red"].setTranslation(0, math.max(-41, (airspeed-redSpeed)) * 6.42);
        me.elems["speedbar.amber"].setTranslation(0, math.max(-41, (airspeed-amberSpeed)) * 6.42);
        me.elems["barberpole"].setTranslation(0, math.max(-41, (airspeed-maxSpeed)) * 6.42);
        me.elems["greendot"].setTranslation(0, (airspeed-greenSpeed) * 6.42);
        if (greenSpeed > airspeed + 40 or greenSpeed < airspeed - 40) {
            me.elems["greendot"].hide();
        }
        else {
            me.elems["greendot"].show();
        }
        if (me.props["/gear/gear/wow"].getValue()) {
            me.elems["speedbar.red"].hide();
            me.elems["speedbar.amber"].hide();
        }
        else {
            me.elems["speedbar.red"].show();
            me.elems["speedbar.amber"].show();
        }

        o = odoDigit(airspeed, 0);

        me.elems["asi.1"].setTranslation(0, o * 64);

        o = odoDigit(airspeed, 1);
        me.elems["asi.10"].setTranslation(0, o * 64);

        o = odoDigit(airspeed, 2);
        me.elems["asi.100"].setTranslation(0, o * 64);

        if (airspeed < 90.0) {
            me.elems["asi.10.0"].hide();
            me.elems["asi.10.9"].hide();
        }
        else {
            me.elems["asi.10.0"].show();
            me.elems["asi.10.9"].show();
        }


        # Speed ref bugs
        foreach (var spdref; ["v1", "vr", "v2", "vfs"]) {
            var prop = me.props["/fms/vspeeds-effective/departure/" ~ spdref];
            var elem = me.elems["speedref." ~ spdref];
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
            var elem = me.elems["speedref." ~ spdref];
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
        var flapsElem = me.elems["speedref.vf"];
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

        me.elems["ils.fmsloc"].setTranslation(
            math.round((me.props["/instrumentation/gps/cdi-deflection"].getValue() or 0) * 10.0),
            0);

        # TODO
        # me.elems["ils.fmsvert"].setTranslation(0, math.min(1000, math.max(-1000, node.getValue())) * 0.1);
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
        pfd[i] = PFDCanvas.new(i).init(PFD_master[i]);
        (func (j) {
            var outputProp = props.globals.getNode("systems/electrical/outputs/pfd[" ~ j ~ "]");
            var enabledProp = props.globals.getNode("instrumentation/pfd[" ~ j ~ "]/enabled");
            var rateProp = props.globals.getNode("instrumentation/pfd[" ~ j ~ "]/update-rate");
            var fastRate = 0.04;
            var slowRate = 1.0;
            var blinkRate = 0.25;
            append(timer, maketimer(fastRate, func() { pfd[j].update(fastRate); }));
            append(timerSlow, maketimer(slowRate, func() { pfd[j].updateSlow(slowRate); }));
            append(blinkTimer, maketimer(blinkRate, func () { pfd[j].toggleBlink(); }));
            blinkTimer[j].simulatedTime = 1;
            var check = func {
                var visible = ((outputProp.getValue() or 0) >= 15) and enabledProp.getBoolValue();
                PFD_master[j].setVisible(visible);
                if (visible) {
                    var rate = rateProp.getValue();
                    fastRate = 1.0 / (10.0 + 10.0 * rate);
                    pfd[j].activate();
                    timer[j].restart(fastRate);
                    timerSlow[j].start();
                    blinkTimer[j].start();
                }
                else {
                    pfd[j].deactivate();
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
