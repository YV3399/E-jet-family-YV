# E-jet-family EICAS by D-ECHO based on
# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

#sources: http://www.smartcockpit.com/docs/Embraer_190-Powerplant.pdf http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf http://www.smartcockpit.com/docs/Embraer_190-APU.pdf

var ED_only = nil;
var PFD_display = nil;
var page = "only";
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

setprop("/systems/elecrical/outputs/efis", 0);


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
    new: func(canvas_group, file) {
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
        m.props["/instrumentation/dme/frequencies/selected-mhz"] = props.globals.getNode("/instrumentation/dme/frequencies/selected-mhz");
        m.props["/instrumentation/dme/frequencies/source"] = props.globals.getNode("/instrumentation/dme/frequencies/source");
        m.props["/instrumentation/dme/indicated-distance-nm"] = props.globals.getNode("/instrumentation/dme/indicated-distance-nm");
        m.props["/instrumentation/dme/indicated-time-min"] = props.globals.getNode("/instrumentation/dme/indicated-time-min");
        m.props["/instrumentation/dme/in-range"] = props.globals.getNode("/instrumentation/dme/in-range");
        m.props["/instrumentation/nav[0]/frequencies/selected-mhz"] = props.globals.getNode("/instrumentation/nav[0]/frequencies/selected-mhz");
        m.props["/instrumentation/nav[0]/frequencies/standby-mhz"] = props.globals.getNode("/instrumentation/nav[0]/frequencies/standby-mhz");
        m.props["/instrumentation/nav[0]/from-flag"] = props.globals.getNode("/instrumentation/nav[0]/from-flag");
        m.props["/instrumentation/nav[0]/gs-in-range"] = props.globals.getNode("/instrumentation/nav[0]/gs-in-range");
        m.props["/instrumentation/nav[0]/gs-needle-deflection-norm"] = props.globals.getNode("/instrumentation/nav[0]/gs-needle-deflection-norm");
        m.props["/instrumentation/nav[0]/heading-needle-deflection-norm"] = props.globals.getNode("/instrumentation/nav[0]/heading-needle-deflection-norm");
        m.props["/instrumentation/nav[0]/in-range"] = props.globals.getNode("/instrumentation/nav[0]/in-range");
        m.props["/instrumentation/nav[0]/radials/selected-deg"] = props.globals.getNode("/instrumentation/nav[0]/radials/selected-deg");
        m.props["/instrumentation/nav/nav-id"] = props.globals.getNode("/instrumentation/nav/nav-id");
        m.props["/instrumentation/nav/nav-loc"] = props.globals.getNode("/instrumentation/nav/nav-loc");
        m.props["/instrumentation/pfd/asi-10"] = props.globals.getNode("/instrumentation/pfd/asi-10");
        m.props["/instrumentation/pfd/asi-100"] = props.globals.getNode("/instrumentation/pfd/asi-100");
        m.props["/instrumentation/pfd/pitch-scale"] = props.globals.getNode("/instrumentation/pfd/pitch-scale");
        m.props["/instrumentation/slip-skid-ball/indicated-slip-skid"] = props.globals.getNode("/instrumentation/slip-skid-ball/indicated-slip-skid");
        m.props["/instrumentation/vertical-speed-indicator/indicated-speed-fpm"] = props.globals.getNode("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
        m.props["/it-autoflight/input/alt"] = props.globals.getNode("/it-autoflight/input/alt");
        m.props["/it-autoflight/input/hdg"] = props.globals.getNode("/it-autoflight/input/hdg");
        m.props["/it-autoflight/input/kts-mach"] = props.globals.getNode("/it-autoflight/input/kts-mach");
        m.props["/it-autoflight/input/spd-kts"] = props.globals.getNode("/it-autoflight/input/spd-kts");
        m.props["/it-autoflight/input/spd-mach"] = props.globals.getNode("/it-autoflight/input/spd-mach");
        m.props["/it-autoflight/input/vs"] = props.globals.getNode("/it-autoflight/input/vs");
        m.props["/it-autoflight/input/fpa"] = props.globals.getNode("/it-autoflight/input/fpa");
        m.props["/it-autoflight/internal/lookahead-10-sec-airspeed-kt"] = props.globals.getNode("/it-autoflight/internal/lookahead-10-sec-airspeed-kt");
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
        m.props["/instrumentation/efis/inputs/minimums-mode"] = props.globals.getNode("/instrumentation/efis/inputs/minimums-mode");
        m.props["/instrumentation/mk-viii/inputs/arinc429/decision-height"] = props.globals.getNode("/instrumentation/mk-viii/inputs/arinc429/decision-height");
        m.props["/controls/flight/vfs"] = props.globals.getNode("/controls/flight/vfs");
        m.props["/controls/flight/vf"] = props.globals.getNode("/controls/flight/vf");
        m.props["/controls/flight/v2"] = props.globals.getNode("/controls/flight/v2");
        m.props["/controls/flight/vac"] = props.globals.getNode("/controls/flight/vac");
        m.props["/controls/flight/vr"] = props.globals.getNode("/controls/flight/vr");
        m.props["/controls/flight/vap"] = props.globals.getNode("/controls/flight/vap");
        m.props["/controls/flight/vref"] = props.globals.getNode("/controls/flight/vref");
        m.props["/controls/flight/v1"] = props.globals.getNode("/controls/flight/v1");
        m.props["/controls/flight/speed-mode"] = props.globals.getNode("/controls/flight/speed-mode");

        m.props["/controls/flight/flaps"] = props.globals.getNode("/controls/flight/flaps");
        return m;
    },
    getKeys: func() {
        return [
            "horizon",
            "compass",
            "groundspeed",
            "chrono.digital",
            "mach.digital",
            "airspeed.bug",
            "speedtrend.vector",
            "speedref.vfs",
            "speedref.vf",
            "speedref.v2",
            "speedref.vac",
            "speedref.vr",
            "speedref.vappr",
            "speedref.vref",
            "speedref.v1",
            "wind.pointer",
            "wind.kt",
            "heading.digital",
            "selectedheading.digital",
            "selectedcourse.digital",
            "selectedheading.pointer",
            "chrono.digital",
            "nav1.act",
            "nav1.sby",
            "vhf1.act",
            "vhf1.sby",
            "navsrc.primary",
            "navsrc.primary.selection",
            "navsrc.primary.id",
            "navsrc.preview",
            "navsrc.preview.selection",
            "navsrc.preview.id",
            "dme",
            "dme.selection",
            "dme.id",
            "dme.dist",
            "dme.hold",
            "dme.ete",
            "dme.eteunit",
            "waypoint",
            "waypoint.id",
            "waypoint.dist",
            "waypoint.ete",
            "waypoint.eteunit",
            "minimums",
            "minimums.indicator",
            "minimums.barora",
            "minimums.digital",
            "radioalt",
            "radioalt.digital",
            "ils.locneedle",
            "ils.gsneedle",
            "alt.tape",
            "altNumLow1",
            "altNumHigh1",
            "altNumHigh2",
            "alt.rollingdigits",
            "alt.rollingdigits.pos",
            "alt.rollingdigits.zero",
            "alt.rollingdigits.neg",
            "alt.10000",
            "alt.1000",
            "alt.100",
            "asi.100",
            "asi.10",
            "asi.10.0",
            "asi.10.9",
            "asi.1",
            "asi.tape",
            "hsi.nav1",
            "hsi.nav1track",
            "hsi.dots",
            "hsi.to",
            "hsi.from",
            "selectedspeed.digital",
            "selectedalt.digital100",
            "selectedvspeed.digital",
            "roll.pointer",
            "slip.pointer",
            "vs.needle",
            "VS.digital",
            "fma.appr",
            "fma.apprarmed",
            "fma.spd",
            "fma.spdarmed",
            "fma.ap",
            "fma.at",
            "fma.lat",
            "fma.latarmed",
            "fma.vert",
            "fma.vertarmed",
            "fd.pitch",
            "fd.roll"
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

        var heading = me.props["/orientation/heading-magnetic-deg"].getValue() or 0;
        var selectedheading = me.props["/it-autoflight/input/hdg"].getValue() or 0;
        var selectedcourse = me.props["/instrumentation/nav[0]/radials/selected-deg"].getValue() or 0;

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
        me["selectedcourse.digital"].setText(sprintf("%03d", selectedcourse));

        # FD
        var pitchBar = me.props["/it-autoflight/fd/pitch-bar"].getValue() or 0;
        var rollBar = me.props["/it-autoflight/fd/roll-bar"].getValue() or 0;
        me["fd.pitch"].setTranslation(0, pitchBar * 8.05);
        me["fd.roll"].setTranslation(pitchBar * 8.05, 0);

        # CHR
        var t = me.props["/instrumentation/chrono/elapsed_time/total"].getValue() or 0;
        me["chrono.digital"].setText(sprintf("%02d:%02d", math.floor(t / 60), math.mod(t, 60)));

        # HSI NAV1
        var nav1heading = me.props["/instrumentation/nav[0]/radials/selected-deg"].getValue() or 0;
        var nav1error = me.props["/instrumentation/nav[0]/heading-needle-deflection-norm"].getValue() or 0;
        me["hsi.nav1"].setRotation((nav1heading - heading) * DC);
        me["hsi.dots"].setRotation((nav1heading - heading) * DC);
        me["hsi.nav1track"].setTranslation(nav1error * 120, 0);
        if (me.props["/instrumentation/nav[0]/from-flag"].getValue()) {
            me["hsi.from"].show();
            me["hsi.to"].hide();
        }
        else {
            me["hsi.from"].hide();
            me["hsi.to"].show();
        }


        me["selectedalt.digital100"].setText(sprintf("%02d", (me.props["/it-autoflight/input/alt"].getValue() or 0) * 0.01));

        #COMM/NAV
        me["vhf1.act"].setText(sprintf("%.2f", me.props["/instrumentation/comm[0]/frequencies/selected-mhz"].getValue() or 0));
        me["vhf1.sby"].setText(sprintf("%.2f", me.props["/instrumentation/comm[0]/frequencies/standby-mhz"].getValue() or 0));
        me["nav1.act"].setText(sprintf("%.2f", me.props["/instrumentation/nav[0]/frequencies/selected-mhz"].getValue() or 0));
        me["nav1.sby"].setText(sprintf("%.2f", me.props["/instrumentation/nav[0]/frequencies/standby-mhz"].getValue() or 0));
        if (me.props["/instrumentation/nav[0]/gs-in-range"].getValue()) {
            me["ils.gsneedle"].setTranslation(0, math.round((me.props["/instrumentation/nav[0]/gs-needle-deflection-norm"].getValue() or 0) * -100.0));
        }
        else {
            me["ils.gsneedle"].setTranslation(0, 0);
        }
        if (me.props["/instrumentation/nav[0]/in-range"].getValue()) {
            me["ils.locneedle"].setTranslation(math.round((me.props["/instrumentation/nav[0]/heading-needle-deflection-norm"].getValue() or 0) * 100.0), 0);
        }
        else {
            me["ils.locneedle"].setTranslation(0, 0);
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
            me["navsrc.primary.selection"].setText("FMS");
            me["navsrc.primary.selection"].setColor(255, 0, 255);
            me["navsrc.preview"].show();

            if (me.props["/instrumentation/nav/nav-loc"].getValue() or 0) {
                me["navsrc.preview.selection"].setText("LOC1");
            }
            else {
                me["navsrc.preview.selection"].setText("VOR1");
            }
            me["navsrc.preview.id"].setText(me.props["/instrumentation/nav/nav-id"].getValue() or "");
            me["navsrc.primary.id"].setText("");
        }
        else {
            me["waypoint"].hide();
            me["navsrc.preview"].hide();
            if (me.props["/instrumentation/nav/nav-loc"].getValue() or 0) {
                me["navsrc.primary.selection"].setText("LOC1");
            }
            else {
                me["navsrc.primary.selection"].setText("VOR1");
            }
            me["navsrc.primary.id"].setText(me.props["/instrumentation/nav/nav-id"].getValue() or "");
            me["navsrc.primary.selection"].setColor(0, 255, 0);
        }

        if (me.props["/instrumentation/dme/in-range"].getValue() or 0) {
            me["dme"].show();
            me["dme.selection"].setText("DME1");
            me["dme.id"].setText(me.props["/instrumentation/nav/nav-id"].getValue() or "");
            me["dme.dist"].setText(
                sprintf("%5.1f", me.props["/instrumentation/dme/indicated-distance-nm"].getValue() or 0));
            var ete = me.props["/instrumentation/dme/indicated-time-min"].getValue() or 600.0;
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
            if (me.props["/instrumentation/dme/frequencies/source"].getValue() == "/instrumentation/dme/frequencies/selected-mhz") {
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
        if (roundToNearest(alt, 1000) == 0) {
            var altNumLow = "-1";
            var altNumHigh = "1";
            var altNumCenter = 0;
        }
        elsif (roundToNearest(alt, 1000) > 0) {
            var altNumLow = (roundToNearest(alt, 1000)/1000 - 1);
            var altNumHigh = (roundToNearest(alt, 1000)/1000 + 1);
            var altNumCenter = altNumHigh-1;
        }
        elsif (roundToNearest(alt, 1000) < 0) {
            var altNumLow = roundToNearest(alt, 1000)/1000-1;
            var altNumHigh = (roundToNearest(alt, 1000)/1000 + 1) ;
            var altNumCenter = altNumLow-1;
        }
        if ( altNumLow == 0 ) {
            altNumLow = "";
        }
        elsif(altNumLow != nil) {
            altNumLow=1000*altNumLow;
        }
        if ( altNumHigh == 0 and alt < 0) {
            altNumHigh = "-";
        }
        elsif(altNumHigh != nil) {
            altNumHigh=1000*altNumHigh;
        }
        if(altNumCenter != nil){
            altNumCenter=1000*altNumCenter;
        }

        me["alt.tape"].setTranslation(0,(alt - roundToNearest(alt, 1000))*0.45);


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

        var o = odoDigit(alt / 10, 1);
        me["alt.100"].setTranslation(0, o * 42.6);
        var o = odoDigit(alt / 10, 2);
        me["alt.1000"].setTranslation(0, o * 42.6);
        var o = odoDigit(alt / 10, 3);
        me["alt.10000"].setTranslation(0, o * 42.6);

        # Minimums
        var radarAlt = me.props["/position/gear-agl-ft"].getValue() or 0.0;
        var minimumsMode = 0; # me.props["/instrumentation/efis/inputs/minimums-mode"].getValue();
        var decisionHeight = me.props["/instrumentation/mk-viii/inputs/arinc429/decision-height"].getValue();

        if (radarAlt <= 4000) {
            me["radioalt.digital"].setText(sprintf("%04d", radarAlt));
            if (radarAlt <= decisionHeight) {
                me["minimums.indicator"].show();
            }
            else {
                me["minimums.indicator"].hide();
            }

            if (minimumsMode) {
                me["minimums.barora"].setText("BARO");
                me["minimums.digital"].setColor(255, 255, 0);
            }
            else {
                me["minimums.barora"].setText("RA");
                me["minimums.digital"].setColor(255, 255, 255);
            }
            me["minimums.digital"].setText(sprintf("%d", decisionHeight));
            me["radioalt"].show();
            me["minimums"].show();
        }
        else {
            me["radioalt"].hide();
            me["minimums"].hide();
        }

        # Airspeed
        var airspeed = me.props["/instrumentation/airspeed-indicator/indicated-speed-kt"].getValue() or 0;
        var airspeedLookahead = me.props["/it-autoflight/internal/lookahead-10-sec-airspeed-kt"].getValue() or 0;
        var currentMach = me.props["/instrumentation/airspeed-indicator/indicated-mach"].getValue() or 0;
        var selectedKts = 0;

        if (me.props["/it-autoflight/input/kts-mach"].getValue()) {
            var selectedMach = (me.props["/it-autoflight/input/spd-mach"].getValue() or 0);
            me["selectedspeed.digital"].setText(sprintf(".%03dM", selectedMach * 1000));
            if (currentMach > 0.001) {
                selectedKts = selectedMach * airspeed / currentMach;
            }
            else {
                # this shouldn't happen in practice, but when it does, use the
                # least objectionable default.
                selectedKts = me.props["/it-autoflight/input/spd-kts"].getValue();
            }
        }
        else {
            selectedKts = (me.props["/it-autoflight/input/spd-kts"].getValue() or 0);
            me["selectedspeed.digital"].setText(sprintf("%03d", selectedKts));
        }
        if (me.props["/controls/flight/speed-mode"].getValue() == 1) {
            me["selectedspeed.digital"].setColor(255, 0, 255);
        }
        else {
            me["selectedspeed.digital"].setColor(0, 128, 255);
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
        var flaps = me.props["/controls/flight/flaps"].getValue();
        foreach (var spdref; ["vfs", "vf", "v2", "vac", "vr", "vappr", "vref", "v1"]) {
            var prop = me.props["/controls/flight/" ~ spdref];
            var elem = me["speedref." ~ spdref];
            if (elem == nil) continue;
            if (prop == nil) {
                elem.hide();
            }
            else {
                ktsRel = airspeed - (prop.getValue() or 0);
                elem.setTranslation(0, ktsRel * 6.42);
                if (ktsRel > 50 or ktsRel < -50) {
                    elem.hide();
                }
                else {
                    # TODO: detect flight phase
                    var phase = getprop("/fms/phase");
                    if (spdref == "vfs" or
                        spdref == "v1" or
                        spdref == "v2" or
                        spdref == "vr") {
                        if (phase == 0 or phase == 1) {
                            # takeoff / departure
                            elem.show();
                        }
                        else {
                            elem.hide();
                        }
                    }
                    else if (spdref == "vappr" or
                             spdref == "vref" or
                             spdref == "vac") {
                        if (phase == 6) {
                            # approach
                            elem.show();
                        }
                        else {
                            elem.hide();
                        }
                    }
                    else if (spdref == "vf") {
                        # show flap speed while flaps extended
                        if (flaps > 0.01) {
                            elem.show();
                        }
                        else {
                            elem.hide();
                        }
                    }
                    else {
                        elem.show();
                    }
                }
            }
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
        var vertModeMap = {
            "ALT HLD": "ALT",
            "V/S": "VS",
            "G/S": "GS",
            "ALT CAP": "ASEL",
            "SPD DES": "FLCH",
            "SPD CLB": "FLCH",
            "FPA": "FPA",
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
        me["fma.vert"].setText(vertModeMap[me.props["/it-autoflight/mode/vert"].getValue() or ""] or "");
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
    PFD_display = canvas.new({
        "name": "EICAS",
        "size": [1024, 1530],
        "view": [1024, 1530],
        "mipmapping": 1
    });
    PFD_display.addPlacement({"node": "PFD_screen"});
    var groupED = PFD_display.createGroup();

    ED_only = canvas_ED_only.new(groupED, "Aircraft/E-jet-family/Models/Primus-Epic/PFD.svg");

    var timer = maketimer(0.02, func() { ED_only.update(); });
    timer.start();
});

var showPFD = func {
    var dlg = canvas.Window.new([512, 765], "dialog").set("resize", 1);
    dlg.setCanvas(PFD_display);
}
