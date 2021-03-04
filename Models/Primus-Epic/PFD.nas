# E-jet-family PFD by D-ECHO based on
# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

#sources: http://www.smartcockpit.com/docs/Embraer_190-Powerplant.pdf http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf http://www.smartcockpit.com/docs/Embraer_190-APU.pdf

var ED_only = [nil, nil];
var PFD_master = [nil, nil];
var PFD_display = [nil, nil];
var DC=0.01744;

setprop("/engines/engine[0]/n1", 0);
setprop("/engines/engine[1]/n1", 0);
setprop("/engines/engine[0]/n2", 0);
setprop("/engines/engine[1]/n2", 0);
setprop("/engines/engine[0]/itt_degc", 0);
setprop("/engines/engine[1]/itt_degc", 0);
setprop("/engines/engine[0]/oil-pressure-psi", 0);
setprop("/MFD/oil-pressure-needle[0]", 0);
setprop("/engines/engine[1]/oil-pressure-psi", 0);
setprop("/MFD/oil-pressure-needle[1]", 0);
setprop("/engines/engine[0]/oil-temperature-degc", 0);
setprop("/MFD/oil-temperature-needle[0]", 0);
setprop("/engines/engine[1]/oil-temperature-degc", 0);
setprop("/MFD/oil-temperature-needle[1]", 0);
setprop("/engines/engine[0]/fuel-flow_pph", 0);
setprop("/engines/engine[1]/fuel-flow_pph", 0);
setprop("/engines/engine[0]/reverser-pos-norm", 0);
setprop("/engines/engine[1]/reverser-pos-norm", 0);
setprop("/consumables/fuel/tank[0]/temperature-degc", 0);
setprop("/consumables/fuel/tank[1]/temperature-degc", 0);
setprop("/controls/engines/engine[0]/condition-lever-state", 0);
setprop("/controls/engines/engine[1]/condition-lever-state", 0);
setprop("/controls/engines/engine[0]/throttle-int", 0);
setprop("/controls/engines/engine[1]/throttle-int", 0);
setprop("/instrumentation/pfd[0]/qnh-mode", 0);
setprop("/instrumentation/pfd[0]/minimums-mode", 0);
setprop("/instrumentation/pfd[0]/minimums-radio", 200);
setprop("/instrumentation/pfd[0]/minimums-baro", 400);
setprop("/instrumentation/pfd[1]/qnh-mode", 0);
setprop("/instrumentation/pfd[1]/minimums-mode", 0);
setprop("/instrumentation/pfd[1]/minimums-radio", 200);
setprop("/instrumentation/pfd[1]/minimums-baro", 400);
setprop("/instrumentation/pfd[1]/minimums-visible", 1);

setprop("/systems/electrical/outputs/efis", 0);


var roundToNearest = func(n, m) {
    var x = int(n/m)*m;
    if((math.mod(n,m)) > (m/2) and n > 0)
            x = x + m;
    if((m - (math.mod(n,m))) > (m/2) and n < 0)
            x = x - m;
    return x;
}

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

var canvas_ED_base = {
    init: func(canvas_group, file) {
        var font_mapper = func(family, weight) {
            return "LiberationFonts/LiberationSans-Regular.ttf";
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
        return [];
    }
};

var canvas_ED_only = {
    new: func(canvas_group, file, index=0) {
        var m = { parents: [canvas_ED_only,canvas_ED_base] };
        m.init(canvas_group, file);
        m.props = {};
        m.props["/autopilot/route-manager/active"] = props.globals.getNode("/autopilot/route-manager/active");
        m.props["/autopilot/route-manager/wp/dist"] = props.globals.getNode("/autopilot/route-manager/wp/dist");
        m.props["/autopilot/route-manager/wp/eta-seconds"] = props.globals.getNode("/autopilot/route-manager/wp/eta-seconds");
        m.props["/autopilot/route-manager/wp/id"] = props.globals.getNode("/autopilot/route-manager/wp/id");
        m.props["/environment/wind-from-heading-deg"] = props.globals.getNode("/environment/wind-from-heading-deg");
        m.props["/environment/wind-speed-kt"] = props.globals.getNode("/environment/wind-speed-kt");
        m.props["/instrumentation/airspeed-indicator/indicated-mach"] = props.globals.getNode("/instrumentation/airspeed-indicator/indicated-mach");
        m.props["/instrumentation/airspeed-indicator/indicated-speed-kt"] = props.globals.getNode("/instrumentation/airspeed-indicator/indicated-speed-kt");
        m.props["/instrumentation/altimeter/indicated-altitude-ft"] = props.globals.getNode("/instrumentation/altimeter/indicated-altitude-ft");
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
        m.props["/instrumentation/nav[0]/frequencies/selected-mhz"] = props.globals.getNode("/instrumentation/nav[0]/frequencies/selected-mhz");
        m.props["/instrumentation/nav[0]/frequencies/standby-mhz"] = props.globals.getNode("/instrumentation/nav[0]/frequencies/standby-mhz");
        m.props["/instrumentation/nav[0]/from-flag"] = props.globals.getNode("/instrumentation/nav[0]/from-flag");
        m.props["/instrumentation/nav[0]/has-gs"] = props.globals.getNode("/instrumentation/nav[0]/has-gs");
        m.props["/instrumentation/nav[0]/nav-loc"] = props.globals.getNode("/instrumentation/nav[0]/nav-loc");
        m.props["/instrumentation/nav[0]/gs-in-range"] = props.globals.getNode("/instrumentation/nav[0]/gs-in-range");
        m.props["/instrumentation/nav[0]/gs-needle-deflection-norm"] = props.globals.getNode("/instrumentation/nav[0]/gs-needle-deflection-norm");
        m.props["/instrumentation/nav[0]/heading-needle-deflection-norm"] = props.globals.getNode("/instrumentation/nav[0]/heading-needle-deflection-norm");
        m.props["/instrumentation/nav[0]/in-range"] = props.globals.getNode("/instrumentation/nav[0]/in-range");
        m.props["/instrumentation/nav[0]/radials/selected-deg"] = props.globals.getNode("/instrumentation/nav[0]/radials/selected-deg");
        m.props["/instrumentation/nav[0]/nav-id"] = props.globals.getNode("/instrumentation/nav[0]/nav-id");
        m.props["/instrumentation/nav[0]/nav-loc"] = props.globals.getNode("/instrumentation/nav[0]/nav-loc");
        m.props["/instrumentation/nav[1]/frequencies/selected-mhz"] = props.globals.getNode("/instrumentation/nav[1]/frequencies/selected-mhz");
        m.props["/instrumentation/nav[1]/frequencies/standby-mhz"] = props.globals.getNode("/instrumentation/nav[1]/frequencies/standby-mhz");
        m.props["/instrumentation/nav[1]/from-flag"] = props.globals.getNode("/instrumentation/nav[1]/from-flag");
        m.props["/instrumentation/nav[1]/gs-in-range"] = props.globals.getNode("/instrumentation/nav[1]/gs-in-range");
        m.props["/instrumentation/nav[1]/gs-needle-deflection-norm"] = props.globals.getNode("/instrumentation/nav[1]/gs-needle-deflection-norm");
        m.props["/instrumentation/nav[1]/heading-needle-deflection-norm"] = props.globals.getNode("/instrumentation/nav[1]/heading-needle-deflection-norm");
        m.props["/instrumentation/nav[1]/in-range"] = props.globals.getNode("/instrumentation/nav[1]/in-range");
        m.props["/instrumentation/nav[1]/radials/selected-deg"] = props.globals.getNode("/instrumentation/nav[1]/radials/selected-deg");
        m.props["/instrumentation/nav[1]/nav-id"] = props.globals.getNode("/instrumentation/nav[1]/nav-id");
        m.props["/instrumentation/nav[1]/nav-loc"] = props.globals.getNode("/instrumentation/nav[1]/nav-loc");
        m.props["/instrumentation/gps/cdi-deflection"] = props.globals.getNode("/instrumentation/gps/cdi-deflection");
        m.props["/instrumentation/gps/desired-course-deg"] = props.globals.getNode("/instrumentation/gps/desired-course-deg");
        m.props["/instrumentation/pfd/asi-10"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/asi-10");
        m.props["/instrumentation/pfd/asi-100"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/asi-100");
        m.props["/instrumentation/pfd/pitch-scale"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/pitch-scale");
        m.props["/instrumentation/slip-skid-ball/indicated-slip-skid"] = props.globals.getNode("/instrumentation/slip-skid-ball/indicated-slip-skid");
        m.props["/instrumentation/vertical-speed-indicator/indicated-speed-fpm"] = props.globals.getNode("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
        m.props["/instrumentation/altimeter/setting-hpa"] = props.globals.getNode("/instrumentation/altimeter/setting-hpa");
        m.props["/instrumentation/altimeter/setting-inhg"] = props.globals.getNode("/instrumentation/altimeter/setting-inhg");
        m.props["/instrumentation/pfd/qnh-mode"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/qnh-mode");
        m.props["/it-autoflight/input/alt"] = props.globals.getNode("/it-autoflight/input/alt");
        m.props["/controls/flight/selected-alt"] = props.globals.getNode("/controls/flight/selected-alt");
        m.props["/controls/flight/vnav-enabled"] = props.globals.getNode("/controls/flight/vnav-enabled");
        m.props["/it-autoflight/input/hdg"] = props.globals.getNode("/it-autoflight/input/hdg");
        m.props["/it-autoflight/input/kts-mach"] = props.globals.getNode("/it-autoflight/input/kts-mach");
        m.props["/it-autoflight/input/kts"] = props.globals.getNode("/it-autoflight/input/kts");
        m.props["/it-autoflight/input/mach"] = props.globals.getNode("/it-autoflight/input/mach");
        m.props["/it-autoflight/input/vs"] = props.globals.getNode("/it-autoflight/input/vs");
        m.props["/it-autoflight/input/fpa"] = props.globals.getNode("/it-autoflight/input/fpa");
        m.props["/instrumentation/pfd/airspeed-lookahead-10s"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/airspeed-lookahead-10s");
        m.props["/it-autoflight/mode/arm"] = props.globals.getNode("/it-autoflight/mode/arm");
        m.props["/it-autoflight/mode/lat"] = props.globals.getNode("/it-autoflight/mode/lat");
        m.props["/it-autoflight/mode/thr"] = props.globals.getNode("/it-autoflight/mode/thr");
        m.props["/it-autoflight/mode/vert"] = props.globals.getNode("/it-autoflight/mode/vert");
        m.props["/it-autoflight/output/ap1"] = props.globals.getNode("/it-autoflight/output/ap1");
        m.props["/it-autoflight/output/ap2"] = props.globals.getNode("/it-autoflight/output/ap2");
        m.props["/it-autoflight/output/appr-armed"] = props.globals.getNode("/it-autoflight/output/appr-armed");
        m.props["/it-autoflight/output/athr"] = props.globals.getNode("/it-autoflight/output/athr");
        m.props["/it-autoflight/output/lnav-armed"] = props.globals.getNode("/it-autoflight/output/lnav-armed");
        m.props["/it-autoflight/output/loc-armed"] = props.globals.getNode("/it-autoflight/output/loc-armed");
        m.props["/it-autoflight/fd/pitch-bar"] = props.globals.getNode("/it-autoflight/fd/pitch-bar");
        m.props["/it-autoflight/fd/roll-bar"] = props.globals.getNode("/it-autoflight/fd/roll-bar");
        m.props["/orientation/heading-deg"] = props.globals.getNode("/orientation/heading-deg");
        m.props["/orientation/heading-magnetic-deg"] = props.globals.getNode("/orientation/heading-magnetic-deg");
        m.props["/orientation/roll-deg"] = props.globals.getNode("/orientation/roll-deg");
        m.props["/velocities/groundspeed-kt"] = props.globals.getNode("/velocities/groundspeed-kt");
        m.props["/position/gear-agl-ft"] = props.globals.getNode("/position/gear-agl-ft");
        m.props["/instrumentation/pfd/minimums-mode"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-mode");
        m.props["/instrumentation/pfd/minimums-radio"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-radio");
        m.props["/instrumentation/pfd/minimums-baro"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-baro");
        m.props["/instrumentation/pfd/minimums-visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-visible");
        m.props["/instrumentation/pfd/nav-src"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav-src");
        m.props["/instrumentation/pfd/preview"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/preview");
        m.props["/fms/vspeeds-effective/departure/v1"] = props.globals.getNode("/fms/vspeeds-effective/departure/v1");
        m.props["/fms/vspeeds-effective/departure/vr"] = props.globals.getNode("/fms/vspeeds-effective/departure/vr");
        m.props["/fms/vspeeds-effective/departure/v2"] = props.globals.getNode("/fms/vspeeds-effective/departure/v2");
        m.props["/fms/vspeeds-effective/departure/vfs"] = props.globals.getNode("/fms/vspeeds-effective/departure/vfs");
        m.props["/fms/vspeeds-effective/departure/vf"] = props.globals.getNode("/fms/vspeeds-effective/departure/vf");
        m.props["/fms/vspeeds-effective/departure/vf1"] = props.globals.getNode("/fms/vspeeds-effective/departure/vf1");
        m.props["/fms/vspeeds-effective/departure/vf2"] = props.globals.getNode("/fms/vspeeds-effective/departure/vf2");
        m.props["/fms/vspeeds-effective/departure/vf3"] = props.globals.getNode("/fms/vspeeds-effective/departure/vf3");
        m.props["/fms/vspeeds-effective/departure/vf4"] = props.globals.getNode("/fms/vspeeds-effective/departure/vf4");
        m.props["/fms/vspeeds-effective/approach/vac"] = props.globals.getNode("/fms/vspeeds-effective/approach/vac");
        m.props["/fms/vspeeds-effective/approach/vap"] = props.globals.getNode("/fms/vspeeds-effective/approach/vap");
        m.props["/fms/vspeeds-effective/approach/vref"] = props.globals.getNode("/fms/vspeeds-effective/approach/vref");
        m.props["/fms/speed-limits/vstall-kt"] = props.globals.getNode("/fms/speed-limits/vstall-kt");
        m.props["/fms/speed-limits/vwarn-kt"] = props.globals.getNode("/fms/speed-limits/vwarn-kt");
        m.props["/fms/speed-limits/green-dot-kt"] = props.globals.getNode("/fms/speed-limits/green-dot-kt");
        m.props["/controls/flight/speed-mode"] = props.globals.getNode("/controls/flight/speed-mode");
        m.props["/gear/gear/wow"] = props.globals.getNode("/gear/gear/wow");

        m.props["/controls/flight/flaps"] = props.globals.getNode("/controls/flight/flaps");
        return m;
    },
    getKeys: func() {
        return [
            "QNH.digital",
            "QNH.unit",
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
            "airspeed.bug",
            "airspeed.bug_clip",
            "alt.100",
            "alt.100.tape",
            "alt.100.zero",
            "alt.100.z",
            "alt.100.neg",
            "alt.1000",
            "alt.1000.tape",
            "alt.1000.zero",
            "alt.1000.z",
            "alt.1000.neg",
            "alt.10000",
            "alt.10000.tape",
            "alt.10000.zero",
            "alt.10000.z",
            "alt.10000.neg",
            "alt.1000_clip",
            "alt.100_clip",
            "alt.rollingdigits",
            "alt.rollingdigits.neg",
            "alt.rollingdigits.pos",
            "alt.rollingdigits.zero",
            "alt.rollingdigits_clip",
            "alt.tape",
            "alt.tape_clip",
            "altNumHigh1",
            "altNumHigh2",
            "altNumLow1",
            "asi.1",
            "asi.10",
            "asi.10.0",
            "asi.10.9",
            "asi.10.z",
            "asi.100",
            "asi.100_clip",
            "asi.10_clip",
            "asi.1_clip",
            "asi.tape",
            "asi.tape_clip",
            "chrono.digital",
            "compass",
            "dme",
            "dme.dist",
            "dme.ete",
            "dme.eteunit",
            "dme.hold",
            "dme.id",
            "dme.selection",
            "fd.pitch",
            "fd.roll",
            "fma.ap",
            "fma.appr",
            "fma.apprarmed",
            "fma.at",
            "fma.lat",
            "fma.latarmed",
            "fma.spd",
            "fma.spdarmed",
            "fma.vert",
            "fma.vertarmed",
            "groundspeed",
            "heading.digital",
            "horizon",
            "horizon.ground",
            "horizon_clip",
            "hsi.dots",
            "hsi.from",
            "hsi.nav1",
            "hsi.nav1track",
            "hsi.to",
            "ils.gsneedle",
            "ils.gs",
            "ils.locneedle",
            "ils.loc",
            "mach.digital",
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
            "speedref.v1",
            "speedref.v2",
            "speedref.vac",
            "speedref.vappr",
            "speedref.vf",
            "speedref.vfs",
            "speedref.vr",
            "speedref.vref",
            "speedtrend.vector",
            "speedbar.amber",
            "speedbar.red",
            "greendot",
            "vhf1.act",
            "vhf1.sby",
            "vs.needle",
            "vs.needle_clip",
            "waypoint",
            "waypoint.dist",
            "waypoint.ete",
            "waypoint.eteunit",
            "waypoint.id",
            "wind.kt",
            "wind.pointer"
        ];
    },

    update: func() {
        var pitch = (me.props["/instrumentation/pfd/pitch-scale"].getValue() or 0);
        var roll =  me.props["/orientation/roll-deg"].getValue() or 0;
        me.h_trans.setTranslation(0,pitch*8.05);
        me.h_rot.setRotation(-roll*DC,me["horizon"].getCenter());
        if(math.abs(roll)<=45){
            me["roll.pointer"].setRotation(roll*(-DC));
        }
        me["slip.pointer"].setTranslation(math.round((me.props["/instrumentation/slip-skid-ball/indicated-slip-skid"].getValue() or 0)*50), 0);

        me["groundspeed"].setText(sprintf("%3d", me.props["/velocities/groundspeed-kt"].getValue() or 0));

        var navsrc = me.props["/instrumentation/pfd/nav-src"].getValue() or 0;
        var preview = me.props["/instrumentation/pfd/preview"].getValue() or 0;
        var dmesrc = navsrc or preview or 0;
        var coursesrc = navsrc or preview or 0;

        var heading = me.props["/orientation/heading-magnetic-deg"].getValue() or 0;
        var selectedheading = me.props["/it-autoflight/input/hdg"].getValue() or 0;
        var selectedcourse = nil;
        var coursecolor = [0, 1, 0];
        if (coursesrc > 0) {
            selectedcourse = me.props["/instrumentation/nav[" ~ (coursesrc - 1) ~ "]/radials/selected-deg"].getValue() or 0;
        }
        if (navsrc == 0) {
            coursecolor = [0, 1, 1];
        }
        if (selectedcourse == nil) {
            me["selectedcourse.digital"].hide();
        }
        else {
            me["selectedcourse.digital"].setText(sprintf("%03d", selectedcourse));
            me["selectedcourse.digital"].show();
            me["selectedcourse.digital"].setColor(coursecolor[0], coursecolor[1], coursecolor[2]);
        }

        me["wind.pointer"].setRotation(((me.props["/environment/wind-from-heading-deg"].getValue() or 0) - heading + 180) * DC);
        if (me.props["/environment/wind-speed-kt"].getValue() > 1) {
            me["wind.pointer"].show();
        }
        else {
            me["wind.pointer"].hide();
        }
        me["wind.kt"].setText(sprintf("%u", math.round(me.props["/environment/wind-speed-kt"].getValue() or 0)));

        me["compass"].setRotation(heading * -DC);
        me["heading.digital"].setText(sprintf("%03d", heading));
        me["selectedheading.digital"].setText(sprintf("%03d", selectedheading));
        me["selectedheading.pointer"].setRotation((selectedheading - heading) * DC);

        # FD
        var pitchBar = me.props["/it-autoflight/fd/pitch-bar"].getValue() or 0;
        var rollBar = me.props["/it-autoflight/fd/roll-bar"].getValue() or 0;
        me["fd.pitch"].setTranslation(0, pitchBar * 8.05);
        me["fd.roll"].setTranslation(rollBar * 8.05, 0);

        # CHR
        var t = me.props["/instrumentation/chrono/elapsed_time/total"].getValue() or 0;
        me["chrono.digital"].setText(sprintf("%02d:%02d", math.floor(t / 60), math.mod(t, 60)));

        # HSI NAV1
        var hsiHeading = 0;
        var hsiDeflection = 0;
        var hsiColor = [0, 1, 0];
        if (navsrc == 0) {
            # FMS
            hsiHeading = me.props["/instrumentation/gps/desired-course-deg"].getValue() or 0;
            hsiDeflection = (me.props["/instrumentation/gps/cdi-deflection"].getValue() or 0) * 0.1;
            hsiColor = [1, 0, 1];
        }
        else {
            hsiHeading = me.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/radials/selected-deg"].getValue() or 0;
            hsiDeflection = me.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/heading-needle-deflection-norm"].getValue() or 0;
        }
        me["hsi.nav1"].setColor(hsiColor[0], hsiColor[1], hsiColor[2]);
        me["hsi.nav1track"].setColor(hsiColor[0], hsiColor[1], hsiColor[2]);

        me["hsi.nav1"].setRotation((hsiHeading - heading) * DC);
        me["hsi.dots"].setRotation((hsiHeading - heading) * DC);
        me["hsi.nav1track"].setTranslation(hsiDeflection * 120, 0);
        if (navsrc == 0) {
            me["hsi.from"].hide();
            me["hsi.to"].hide();
        }
        else {
            if (me.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/from-flag"].getValue()) {
                me["hsi.from"].show();
                me["hsi.to"].hide();
            }
            else {
                me["hsi.from"].hide();
                me["hsi.to"].show();
            }
        }


        me["selectedalt.digital100"].setText(sprintf("%02d", (me.props["/controls/flight/selected-alt"].getValue() or 0) * 0.01));

        #COMM/NAV
        me["vhf1.act"].setText(sprintf("%.2f", me.props["/instrumentation/comm[0]/frequencies/selected-mhz"].getValue() or 0));
        me["vhf1.sby"].setText(sprintf("%.2f", me.props["/instrumentation/comm[0]/frequencies/standby-mhz"].getValue() or 0));
        me["nav1.act"].setText(sprintf("%.2f", me.props["/instrumentation/nav[0]/frequencies/selected-mhz"].getValue() or 0));
        me["nav1.sby"].setText(sprintf("%.2f", me.props["/instrumentation/nav[0]/frequencies/standby-mhz"].getValue() or 0));

        if (me.props["/instrumentation/nav[0]/has-gs"].getValue()) {
            if (me.props["/instrumentation/nav[0]/gs-in-range"].getValue()) {
                me["ils.gsneedle"].setTranslation(0, math.round((me.props["/instrumentation/nav[0]/gs-needle-deflection-norm"].getValue() or 0) * -100.0));
                me["ils.gsneedle"].setColorFill(0, 255, 0);
            }
            else {
                me["ils.gsneedle"].setTranslation(0, 0);
                me["ils.gsneedle"].setColorFill(0, 0, 0);
            }
            me["ils.gs"].show();
        }
        else {
            me["ils.gs"].hide();
        }

        if (me.props["/instrumentation/nav[0]/nav-loc"].getValue()) {
            if (me.props["/instrumentation/nav[0]/in-range"].getValue()) {
                me["ils.locneedle"].setTranslation(math.round((me.props["/instrumentation/nav[0]/heading-needle-deflection-norm"].getValue() or 0) * 100.0), 0);
                me["ils.locneedle"].setColorFill(0, 255, 0);
            }
            else {
                me["ils.locneedle"].setTranslation(0, 0);
                me["ils.locneedle"].setColorFill(0, 0, 0);
            }
            me["ils.loc"].show();
        }
        else {
            me["ils.loc"].hide();
        }

        if (navsrc == 0) {
            me["navsrc.primary.selection"].setText("FMS");
            me["navsrc.primary.selection"].setColor(1, 0, 1);
            me["navsrc.primary.id"].setText("");

            if (preview) {
                me["navsrc.preview"].show();
                if (me.props["/instrumentation/nav[" ~ (preview - 1) ~ "]/nav-loc"].getValue() or 0) {
                    me["navsrc.preview.selection"].setText("LOC" ~ preview);
                }
                else {
                    me["navsrc.preview.selection"].setText("VOR" ~ preview);
                }
                me["navsrc.preview.id"].setText(me.props["/instrumentation/nav[" ~ (preview - 1) ~ "]/nav-id"].getValue() or "");
            }
            else {
                me["navsrc.preview"].hide();
            }
        }
        else {
            me["navsrc.primary"].show();
            if (me.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/nav-loc"].getValue() or 0) {
                me["navsrc.primary.selection"].setText("LOC" ~ navsrc);
            }
            else {
                me["navsrc.primary.selection"].setText("VOR" ~ navsrc);
            }
            me["navsrc.primary.selection"].setColor(0, 1, 0);
            me["navsrc.primary.id"].setText(me.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/nav-id"].getValue() or "");
            me["navsrc.primary.id"].setColor(0, 1, 0);
            me["navsrc.preview"].hide();
        }

        if (me.props["/autopilot/route-manager/active"].getValue() or 0) {
            me["waypoint"].show();
            me["waypoint.id"].setText(me.props["/autopilot/route-manager/wp/id"].getValue() or "");
            me["waypoint.dist"].setText(
                sprintf("%5.1f", me.props["/autopilot/route-manager/wp/dist"].getValue() or 0));
            var ete = me.props["/autopilot/route-manager/wp/eta-seconds"].getValue() or 0;
            if (ete < 60) {
                me["waypoint.ete"].setText(sprintf("%3d", math.round(ete)));
                me["waypoint.eteunit"].setText("SEC");
            }
            else {
                me["waypoint.ete"].setText(sprintf("%3d", math.round(ete) / 60));
                me["waypoint.eteunit"].setText("MIN");
            }

        }
        else {
            me["waypoint"].hide();
        }

        if (dmesrc and (me.props["/instrumentation/dme[" ~ (dmesrc - 1) ~ "]/in-range"].getValue() or 0)) {
            me["dme"].show();
            me["dme.selection"].setText("DME" ~ dmesrc);
            me["dme.id"].setText(me.props["/instrumentation/nav[" ~ (dmesrc - 1) ~ "]/nav-id"].getValue() or "");
            me["dme.dist"].setText(
                sprintf("%5.1f", me.props["/instrumentation/dme[" ~ (dmesrc - 1) ~ "]/indicated-distance-nm"].getValue() or 0));
            var ete = me.props["/instrumentation/dme[" ~ (dmesrc - 1) ~ "]/indicated-time-min"].getValue() or 600.0;
            if (ete >= 600) {
                me["dme.ete"].setText("+++");
                me["dme.eteunit"].setText("+++");
            }
            elsif (ete < 1) {
                me["dme.ete"].setText(sprintf("%3d", math.round(ete * 60.0)));
                me["dme.eteunit"].setText("SEC");
            }
            else {
                me["dme.ete"].setText(sprintf("%3d", math.round(ete)));
                me["dme.eteunit"].setText("MIN");
            }
            if (me.props["/instrumentation/dme[" ~ (dmesrc - 1) ~ "]/frequencies/source"].getValue() == "/instrumentation/dme[" ~ (dmesrc - 1) ~ "]/frequencies/selected-mhz") {
                me["dme.hold"].show();
            }
            else {
                me["dme.hold"].hide();
            }
        }
        else {
            me["dme"].hide();
        }


        # V/S
        var vspeed = me.props["/instrumentation/vertical-speed-indicator/indicated-speed-fpm"].getValue() or 0;
        me["VS.digital"].setText(sprintf("%04d", vspeed));
        me["vs.needle"].setRotation(vspeed * math.pi * 0.25 / 4000.0);

        # Altitude
        var alt = me.props["/instrumentation/altimeter/indicated-altitude-ft"].getValue() or 0;

        var altTapeOffset = math.mod(alt, 1000);
        var altTapeThousands = math.floor(alt / 1000) * 1000;

        me["alt.tape"].setTranslation(0, altTapeOffset * 0.45);
        me["altNumLow1"].setText(sprintf("%5.0f", altTapeThousands - 1000));
        me["altNumHigh1"].setText(sprintf("%5.0f", altTapeThousands));
        me["altNumHigh2"].setText(sprintf("%5.0f", altTapeThousands + 1000));

        var alt100 = alt / 100;
        var alt100Abs = math.abs(math.floor(alt100));
        var altStr = "  0";
        if (alt100Abs >= 1) {
            altStr = sprintf("%3.0d", alt100Abs) or "  0";
        }

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
        me["alt.100"].setTranslation(0, o100 * 42.6);
        var o1000 = odoDigit(altR / 10, 2);
        me["alt.1000"].setTranslation(0, o1000 * 42.6);
        var o10000 = odoDigit(altR / 10, 3);
        me["alt.10000"].setTranslation(0, o10000 * 42.6);

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

        if (alt < 500) {
            me["alt.100.z"].hide();
        }
        else {
            me["alt.100.z"].show();
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

        if (alt < 100) {
            me["alt.100.zero"].show();
        }
        else {
            me["alt.100.zero"].hide();
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

        # VNAV annunciations
        # TODO
        me["VNAV.constraints1"].hide();
        me["VNAV.constraints2"].hide();

        # QNH
        if (me.props["/instrumentation/pfd/qnh-mode"].getValue()) {
            # 1 = inhg
            me["QNH.digital"].setText(
                sprintf("%5.2f", me.props["/instrumentation/altimeter/setting-inhg"].getValue()));
            me["QNH.unit"].setText("IN");
        }
        else {
            # 0 = hpa
            me["QNH.digital"].setText(
                sprintf("%4.0f", me.props["/instrumentation/altimeter/setting-hpa"].getValue()));
            me["QNH.unit"].setText("hPa");
        }

        # Minimums
        var radarAlt = me.props["/position/gear-agl-ft"].getValue() or 0.0;
        var minimumsMode = me.props["/instrumentation/pfd/minimums-mode"].getValue();
        var decisionHeight = 0;
        var comparisonAlt = radarAlt;
        if (minimumsMode) {
            decisionHeight = me.props["/instrumentation/pfd/minimums-baro"].getValue();
            comparisonAlt = alt;
        }
        else {
            decisionHeight = me.props["/instrumentation/pfd/minimums-radio"].getValue();
            comparisonAlt = radarAlt;
        }

        var minimumsVisible = me.props["/instrumentation/pfd/minimums-visible"].getBoolValue();

        if (radarAlt <= 4000) {
            me["radioalt.digital"].setText(sprintf("%04d", radarAlt));
            if (comparisonAlt <= decisionHeight) {
                me["minimums.indicator"].show();
            }
            else {
                me["minimums.indicator"].hide();
            }
            me["radioalt"].show();
        }
        else {
            me["radioalt"].hide();
        }

        if (radarAlt <= 4000 or minimumsVisible) {
            if (minimumsMode) {
                me["minimums.barora"].setText("BARO");
                me["minimums.digital"].setColor(1, 1, 0);
            }
            else {
                me["minimums.barora"].setText("RA");
                me["minimums.digital"].setColor(1, 1, 1);
            }
            me["minimums.digital"].setText(sprintf("%d", decisionHeight));
            me["minimums"].show();
        }
        else {
            me["minimums"].hide();
        }

        # Airspeed
        var airspeedRaw = me.props["/instrumentation/airspeed-indicator/indicated-speed-kt"].getValue() or 0;
        var airspeed = math.max(40, airspeedRaw);
        var airspeedLookahead = me.props["/instrumentation/pfd/airspeed-lookahead-10s"].getValue() or 0;
        var currentMach = me.props["/instrumentation/airspeed-indicator/indicated-mach"].getValue() or 0;
        var selectedKts = 0;

        if (me.props["/it-autoflight/input/kts-mach"].getValue()) {
            var selectedMach = (me.props["/it-autoflight/input/mach"].getValue() or 0);
            me["selectedspeed.digital"].setText(sprintf(".%03dM", selectedMach * 1000));
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
            me["selectedspeed.digital"].setText(sprintf("%03d", selectedKts));
        }
        if (me.props["/controls/flight/speed-mode"].getValue() == 1) {
            me["selectedspeed.digital"].setColor(1, 0, 1);
        }
        else {
            me["selectedspeed.digital"].setColor(0, 0.75, 1);
        }
        me["mach.digital"].setText(sprintf(".%03d", currentMach * 1000));


        var vertMode = me.props["/it-autoflight/mode/vert"].getValue();
        if (vertMode == "V/S") {
            me["selectedvspeed.digital"].setText(sprintf("%-04d", (me.props["/it-autoflight/input/vs"].getValue() or 0)));
            me["selectedvspeed.digital"].show();
        }
        else if (vertMode == "FPA") {
            me["selectedvspeed.digital"].setText(sprintf("%+4.1f", (me.props["/it-autoflight/input/fpa"].getValue() or 0)));
            me["selectedvspeed.digital"].show();
        }
        else {
            me["selectedvspeed.digital"].hide();
        }

        me["speedtrend.vector"].reset();
        me["speedtrend.vector"].rect(152, 152, 15,
            math.max(-40.0, math.min(40.0, (airspeedLookahead - airspeed))) * -6.42);

        me["asi.tape"].setTranslation(0,airspeed * 6.42);
        me["airspeed.bug"].setTranslation(0, (airspeed-selectedKts) * 6.42);

        var redSpeed = me.props["/fms/speed-limits/vstall-kt"].getValue() or 0;
        var amberSpeed = me.props["/fms/speed-limits/vwarn-kt"].getValue() or 0;
        var greenSpeed = me.props["/fms/speed-limits/green-dot-kt"].getValue() or 0;
        me["speedbar.red"].setTranslation(0, math.max(-41, (airspeed-redSpeed)) * 6.42);
        me["speedbar.amber"].setTranslation(0, math.max(-41, (airspeed-amberSpeed)) * 6.42);
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

        me["asi.1"].setTranslation(0, o * 53.25);

        o = odoDigit(airspeed, 1);
        me["asi.10"].setTranslation(0, o * 53.25);

        o = odoDigit(airspeed, 2);
        me["asi.100"].setTranslation(0, o * 53.25);

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

        # FMA
        if (me.props["/it-autoflight/output/ap1"].getValue() or me.props["/it-autoflight/output/ap2"].getValue()) {
            me["fma.ap"].show();
        }
        else {
            me["fma.ap"].hide();
        }
        if (me.props["/it-autoflight/output/athr"].getValue()) {
            me["fma.at"].show();
        }
        else {
            me["fma.at"].hide();
        }

        var activeNav = (navsrc or preview or 1) - 1;
        var vorOrLoc = "VOR";
        if (me.props["/instrumentation/nav[" ~ activeNav ~ "]/nav-loc"].getValue() or 0) {
            vorOrLoc = "LOC";
        }

        var latModeMap = {
            "HDG": "HDG",
            "HDG HLD": "ROLL",
            "HDG SEL": "HDG",
            "LNAV": "LNAV",
            "LOC": vorOrLoc,
            "ALGN": "ROLL",
            "RLOU": "ROLL",
            "T/O": "TRACK"
        };
        var latModeArmedMap = {
            "LNV": "LNAV",
            "LOC": vorOrLoc,
            "ILS": "LOC",
            "HDG": "HDG",
            "HDG HLD": "ROLL",
            "HDG SEL": "HDG",
            "T/O": "TRACK"
        };
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
        var spdModeMap = {
            "THRUST": "SPDt",
            "PITCH": "SPDe",
            " PITCH": "SPDe", # yes, this is correct, ITAF 4.0 is buggy here
            "RETARD": "SPDe",
            "T/O CLB": "TO",
            "G/A CLB": "GA"
        };
        var spdModeArmedMap = {
            "THRUST": "",
            "PITCH": "SPDt",
            " PITCH": "SPDt",
            "RETARD": "SPDt",
            "T/O CLB": "SPDt",
            "G/A CLB": "SPDt"
        };

        me["fma.lat"].setText(latModeMap[me.props["/it-autoflight/mode/lat"].getValue() or ""] or "");
        var vertModeLabel = vertModeMap[me.props["/it-autoflight/mode/vert"].getValue() or ""] or "";
        if (me.props["/controls/flight/vnav-enabled"].getValue()) {
            vertModeLabel = "V" ~ vertModeLabel;
        }
        me["fma.vert"].setText(vertModeLabel);
        if (me.props["/it-autoflight/output/appr-armed"].getValue() and me.props["/it-autoflight/mode/vert"].getValue != "G/S") {
            me["fma.vertarmed"].setText("GS");
        }
        else {
            me["fma.vertarmed"].setText(vertModeArmedMap[me.props["/it-autoflight/mode/vert"].getValue() or ""] or "");
        }
        me["fma.spd"].setText(
                spdModeMap[me.props["/it-autoflight/mode/vert"].getValue() or ""] or
                spdModeMap[me.props["/it-autoflight/mode/thr"].getValue() or ""] or
                "");
        me["fma.spdarmed"].setText(
                spdModeArmedMap[me.props["/it-autoflight/mode/vert"].getValue() or ""] or
                spdModeArmedMap[me.props["/it-autoflight/mode/thr"].getValue() or ""] or
                "");

        if (me.props["/it-autoflight/output/lnav-armed"].getValue()) {
            me["fma.latarmed"].setText("LNAV");
        }
        else if (me.props["/it-autoflight/output/loc-armed"].getValue() or me.props["/it-autoflight/output/appr-armed"].getValue()) {
            me["fma.latarmed"].setText("LOC");
        }
        else if (me.props["/it-autoflight/mode/lat"].getValue() == "T/O") {
            # In T/O mode, if LNAV wasn't armed, the A/P will transition to HDG mode.
            me["fma.latarmed"].setText("HDG");
        }
        else {
            me["fma.latarmed"].setText(latModeArmedMap[me.props["/it-autoflight/mode/arm"].getValue()]);
        }
        # show APPR2 arm when approach armed
        if (me.props["/it-autoflight/output/appr-armed"].getValue() or
            me.props["/it-autoflight/mode/lat"].getValue() == "LOC") {
            me["fma.apprarmed"].show();
            if (radarAlt <= 1500) {
                me["fma.appr"].show();
            }
            else {
                me["fma.appr"].hide();
            }
        }
        else {
            me["fma.appr"].hide();
            me["fma.apprarmed"].hide();
        }
    },
};

setlistener("sim/signals/fdm-initialized", func {
    for (var i = 0; i <= 1; i += 1) {
        PFD_display[i] = canvas.new({
            "name": "PFD" ~ i,
            "size": [1024, 1560],
            "view": [1024, 1560],
            "mipmapping": 1
        });
        PFD_display[i].addPlacement({"node": "PFD" ~ i});
        PFD_master[i] = PFD_display[i].createGroup();
        ED_only[i] =
            canvas_ED_only.new(
            PFD_master[i],
            "Aircraft/E-jet-family/Models/Primus-Epic/PFD.svg",
            i);
    }
    setlistener("/systems/electrical/outputs/efis", func (node) {
        var visible = (node.getValue() >= 15);
        printf("Set PFD visibility: %s", visible ? "ON" : "OFF");
        PFD_master[0].setVisible(visible);
        PFD_master[1].setVisible(visible);
    }, 1, 0);

    var timer = maketimer(0.04, func() {
        ED_only[0].update();
        ED_only[1].update();
    });
    timer.start();
});

# var showPFD = func {
#     var dlg = canvas.Window.new([512, 765], "dialog").set("resize", 1);
#     dlg.setCanvas(PFD_display);
# }
