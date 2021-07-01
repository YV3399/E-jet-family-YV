# E-jet-family HUD by D-ECHO based on
# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

# sources:
# http://www.smartcockpit.com/docs/Embraer_190-Powerplant.pdf
# http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf
# http://www.smartcockpit.com/docs/Embraer_190-APU.pdf

# HSI: E190 AOM p1733
# Bearing Source Selector: E190 AOM p1764

var ED_only = [nil, nil];
var HUD_master = [nil, nil];
var HUD_display = [nil, nil];

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
            return "e190.ttf";
        };


        canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

        var svg_keys = me.getKeys();

        foreach (var key; svg_keys) {
            me[key] = canvas_group.getElementById(key);
            if (me[key] == nil) {
                printf("Key not found: %s", key);
            }
            var clip_el = canvas_group.getElementById(key ~ "_clip");
            if (clip_el != nil) {
                clip_el.hide();
                var tran_rect = clip_el.getTransformedBounds();
                var clip_rect = sprintf("rect(%d,%d, %d,%d)",
                tran_rect[1], # 0 ys
                tran_rect[2], # 1 xe
                tran_rect[3], # 2 ye
                tran_rect[0]); #3 xs
                #   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
                if (me[key] != nil) {
                    me[key].set("clip", clip_rect);
                    me[key].set("clip-frame", canvas.Element.PARENT);
                }
            }
        }

        me.h_trans = me["horizon"].createTransform();
        me.h_rot = me["horizon"].createTransform();
        me["asi.odo-frame"]
            .set("blend-source-alpha", "zero")
            .set("blend-destination-alpha", "zero");

        me.page = canvas_group;

        return me;
    },
    getKeys: func() {
        return [];
    },
};

var canvas_ED_only = {
    new: func(canvas_group, file, index=0) {
        var m = { parents: [canvas_ED_only,canvas_ED_base] };
        m.init(canvas_group, file);
        m.props = {};
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
        m.props["/fms/approach-conditions/runway-width-m"] = props.globals.getNode("/fms/approach-conditions/runway-width-m");
        m.props["/fms/approach-conditions/runway-length-m"] = props.globals.getNode("/fms/approach-conditions/runway-length-m");
        m.props["/fms/approach-conditions/runway-heading"] = props.globals.getNode("/fms/approach-conditions/runway-heading");
        m.props["/gear/gear/wow"] = props.globals.getNode("/gear/gear/wow");
        m.props["/instrumentation/airspeed-indicator/indicated-mach"] = props.globals.getNode("/instrumentation/airspeed-indicator/indicated-mach");
        m.props["/instrumentation/airspeed-indicator/indicated-speed-kt"] = props.globals.getNode("/instrumentation/airspeed-indicator/indicated-speed-kt");
        m.props["/instrumentation/altimeter/indicated-altitude-ft"] = props.globals.getNode("/instrumentation/altimeter/indicated-altitude-ft");
        m.props["/instrumentation/altimeter/setting-hpa"] = props.globals.getNode("/instrumentation/altimeter/setting-hpa");
        m.props["/instrumentation/altimeter/setting-inhg"] = props.globals.getNode("/instrumentation/altimeter/setting-inhg");
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
        m.props["/instrumentation/gps/cdi-deflection"] = props.globals.getNode("/instrumentation/gps/cdi-deflection");
        m.props["/instrumentation/gps/desired-course-deg"] = props.globals.getNode("/instrumentation/gps/desired-course-deg");
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
        m.props["/instrumentation/pfd/alt-tape-offset"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/alt-tape-offset");
        m.props["/instrumentation/pfd/alt-tape-thousands"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/alt-tape-thousands");
        m.props["/instrumentation/pfd/asi-100"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/asi-100");
        m.props["/instrumentation/pfd/asi-10"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/asi-10");
        m.props["/instrumentation/pfd/bearing[0]/bearing"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[0]/bearing");
        m.props["/instrumentation/pfd/bearing[0]/source"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[0]/source");
        m.props["/instrumentation/pfd/bearing[0]/visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[0]/visible");
        m.props["/instrumentation/pfd/bearing[1]/bearing"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[1]/bearing");
        m.props["/instrumentation/pfd/bearing[1]/source"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[1]/source");
        m.props["/instrumentation/pfd/bearing[1]/visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/bearing[1]/visible");
        m.props["/instrumentation/pfd/dme/dist10"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/dme/dist10");
        m.props["/instrumentation/pfd/dme/ete"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/dme/ete");
        m.props["/instrumentation/pfd/dme/ete-unit"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/dme/ete-unit");
        m.props["/instrumentation/pfd/dme/hold"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/dme/hold");
        m.props["/instrumentation/pfd/dme/in-range"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/dme/in-range");
        m.props["/instrumentation/pfd/fpa-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fpa-deg");
        m.props["/instrumentation/pfd/fpa/target"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fpa/target");
        m.props["/instrumentation/pfd/fpa/visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fpa/visible");
        m.props["/instrumentation/pfd/fd/visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fd/visible");
        m.props["/instrumentation/pfd/fd/lat-offset-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fd/lat-offset-deg");
        m.props["/instrumentation/pfd/fd/vert-offset-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/fd/vert-offset-deg");
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
        m.props["/instrumentation/pfd/ils/crosstrack-error-m"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/crosstrack-error-m");
        m.props["/instrumentation/pfd/ils/crosstrack-heading-error-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/crosstrack-heading-error-deg");
        m.props["/instrumentation/pfd/ils/gs-direct-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/gs-direct-deg");
        m.props["/instrumentation/pfd/ils/gs-distance"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/gs-distance");
        m.props["/instrumentation/pfd/ils/runway-width-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/runway-width-deg");
        m.props["/instrumentation/pfd/minimums-baro"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-baro");
        m.props["/instrumentation/pfd/minimums-decision-altitude"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-decision-altitude");
        m.props["/instrumentation/pfd/minimums-indicator-visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-indicator-visible");
        m.props["/instrumentation/pfd/minimums-mode"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-mode");
        m.props["/instrumentation/pfd/minimums-mode"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-mode");
        m.props["/instrumentation/pfd/minimums-radio"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-radio");
        m.props["/instrumentation/pfd/minimums-visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-visible");
        m.props["/instrumentation/pfd/minimums-visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/minimums-visible");
        m.props["/instrumentation/pfd/nav/course-source"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav/course-source");
        m.props["/instrumentation/pfd/nav/course-source-type"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav/course-source-type");
        m.props["/instrumentation/pfd/nav/dme-source"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav/dme-source");
        m.props["/instrumentation/pfd/nav/selected-radial"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav/selected-radial");
        m.props["/instrumentation/pfd/nav-src"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav-src");
        m.props["/instrumentation/pfd/pitch-scale"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/pitch-scale");
        m.props["/instrumentation/pfd/preview"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/preview");
        m.props["/instrumentation/pfd/qnh-mode"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/qnh-mode");
        m.props["/instrumentation/pfd/radio-altimeter-visible"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/radio-altimeter-visible");
        m.props["/instrumentation/pfd/radio-alt"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/radio-alt");
        m.props["/instrumentation/pfd/track-error-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/track-error-deg");
        m.props["/instrumentation/pfd/ils/bearing-error"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/bearing-error");
        m.props["/instrumentation/pfd/ils/heading-error"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/ils/heading-error");
        m.props["/instrumentation/pfd/vsi-needle-deg"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/vsi-needle-deg");
        m.props["/instrumentation/pfd/waypoint/dist10"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/waypoint/dist10");
        m.props["/instrumentation/pfd/waypoint/ete"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/waypoint/ete");
        m.props["/instrumentation/pfd/waypoint/ete-unit"] = props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/waypoint/ete-unit");
        m.props["/instrumentation/annun/lat-mode"] = props.globals.getNode("/instrumentation/annun/lat-mode");
        m.props["/instrumentation/annun/lat-mode-armed"] = props.globals.getNode("/instrumentation/annun/lat-mode-armed");
        m.props["/instrumentation/annun/vert-mode"] = props.globals.getNode("/instrumentation/annun/vert-mode");
        m.props["/instrumentation/annun/vert-mode-armed"] = props.globals.getNode("/instrumentation/annun/vert-mode-armed");
        m.props["/instrumentation/annun/spd-mode"] = props.globals.getNode("/instrumentation/annun/spd-mode");
        m.props["/instrumentation/annun/spd-mode-armed"] = props.globals.getNode("/instrumentation/annun/spd-mode-armed");
        m.props["/instrumentation/annun/appr-mode"] = props.globals.getNode("/instrumentation/annun/appr-mode");
        m.props["/instrumentation/annun/appr-mode-armed"] = props.globals.getNode("/instrumentation/annun/appr-mode-armed");
        m.props["/instrumentation/annun/hud-declutter"] = props.globals.getNode("/instrumentation/annun/hud-declutter");
        m.props["/instrumentation/slip-skid-ball/indicated-slip-skid"] = props.globals.getNode("/instrumentation/slip-skid-ball/indicated-slip-skid");
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
        m.props["/it-autoflight/output/ap2"] = props.globals.getNode("/it-autoflight/output/ap2");
        m.props["/it-autoflight/output/appr-armed"] = props.globals.getNode("/it-autoflight/output/appr-armed");
        m.props["/it-autoflight/output/athr"] = props.globals.getNode("/it-autoflight/output/athr");
        m.props["/it-autoflight/output/lnav-armed"] = props.globals.getNode("/it-autoflight/output/lnav-armed");
        m.props["/it-autoflight/output/loc-armed"] = props.globals.getNode("/it-autoflight/output/loc-armed");
        m.props["/orientation/heading-deg"] = props.globals.getNode("/orientation/heading-deg");
        m.props["/orientation/heading-magnetic-deg"] = props.globals.getNode("/orientation/heading-magnetic-deg");
        m.props["/orientation/track-magnetic-deg"] = props.globals.getNode("/orientation/track-magnetic-deg");
        m.props["/orientation/roll-deg"] = props.globals.getNode("/orientation/roll-deg");
        m.props["/orientation/pitch-deg"] = props.globals.getNode("/orientation/pitch-deg");
        m.props["/position/gear-agl-ft"] = props.globals.getNode("/position/gear-agl-ft");
        m.props["/velocities/groundspeed-kt"] = props.globals.getNode("/velocities/groundspeed-kt");
        m.ilscolor = [0,1,0];
        m.setupListeners();
        return m;
    },
    getKeys: func() {
        return [
            "a3.airspeed",
            "a3.baroalt",
            "a3.ils.crosshair",
            "a3.ils.latscale",
            "a3.radioalt",
            "a3.runway",
            "a3.runway.edges",
            "airspeed.bug",
            "alt.100",
            "alt.1000",
            "alt.10000",
            "alt.10000.neg",
            "alt.10000.tape",
            "alt.10000.z",
            "alt.10000.zero",
            "alt.1000.neg",
            "alt.1000.tape",
            "alt.1000.z",
            "alt.1000.zero",
            "alt.100.neg",
            "alt.100.tape",
            "alt.100.z",
            "altNumHigh1",
            "altNumHigh2",
            "altNumLow1",
            "alt.odo",
            "alt.odo.frame",
            "alt.rollingdigits",
            "alt.rollingdigits.neg",
            "alt.rollingdigits.pos",
            "alt.rollingdigits.zero",
            "alt.tape",
            "alttape.cover",
            "alttape.frame",
            "asi",
            "asi.1",
            "asi.10",
            "asi.100",
            "asi.odo-frame",
            "bankPtr",
            "compass",
            "dme",
            "dme.dist",
            "dme.hold",
            "dme.selection",
            "fd",
            "fma.ap",
            "fma.appr",
            "fma.apprarmed",
            "fma.at",
            "fma.lat",
            "fma.latarmed",
            "fma.spd",
            "fma.spdarmed",
            "fma.spdarmed.minor",
            "fma.spd.minor",
            "fma.src.arrow",
            "fma.vert",
            "fma.vertarmed",
            "fpa",
            "fpa.digital.1",
            "fpa.digital.2",
            "fpv",
            "groundspeed",
            "heading.digital",
            "heading-scale",
            "horizon",
            "hsi.dots",
            "hsi.from",
            "hsi.nav1",
            "hsi.nav1track",
            "hsi.to",
            "mach.digital",
            "mach.digital.group",
            "minimums.barora",
            "minimums.digital",
            "navsrc.primary",
            "navsrc.primary.id",
            "navsrc.primary.selection",
            "QNH.digital",
            "selectedalt.digital100",
            "selectedalt.frame",
            "selectedcourse.digital",
            "selectedheading.digital",
            "selectedheading.pointer",
            "selectedspeed.digital",
            "selectedspeed.fms",
            "selectedspeed.frame",
            "slip",
            "speederror.vector",
            "speedtape",
            "speedtape.cover",
            "speedtape.frame",
            "speedtrend.pointer",
            "speedref.v1",
            "speedref.v2",
            "speedref.vr",
            "speedref.vref",
            "speedref.vf",
            "speedref.vfs",
            "speedref.vap",
            "speedref.vappr",
            "VS.digital",
            "waypoint",
            "waypoint.dist",
            "wind.kt",
            "wind.pointer",
            "wind.pointer.wrapper",
        ];
    },

    setupListeners: func () {
        var self = me;

        # bearing pointers / sources
        setlistener(me.props["/instrumentation/pfd/bearing[0]/source"], func (node) {
            var hsiLabelText = ["----", "VOR1", "ADF1", "FMS1"];
            var mode = node.getValue();
            # self["hsi.label.circle"].setText(hsiLabelText[mode]);
        }, 1, 0);
        setlistener(me.props["/instrumentation/pfd/bearing[1]/source"], func (node) {
            var hsiLabelText = ["----", "VOR2", "ADF2", "FMS2"];
            var mode = node.getValue();
            # self["hsi.label.diamond"].setText(hsiLabelText[mode]);
        }, 1, 0);

        # selected heading
        setlistener(me.props["/it-autoflight/input/hdg"], func (node) {
            var selectedheading = node.getValue() or 0;
            self["selectedheading.digital"].setText(sprintf("%03d", selectedheading));
            self["selectedheading.pointer"].setRotation(selectedheading * D2R);
        }, 1, 0);

        # current heading
        setlistener(me.props["/orientation/heading-magnetic-deg"], func (node) {
            var heading = node.getValue() or 0;
            self["wind.pointer.wrapper"].setRotation(heading * -D2R);
            self["compass"].setRotation(heading * -D2R);
            self["heading.digital"].setText(sprintf("%03d", heading));
            self["heading-scale"].setTranslation(geo.normdeg180(heading) * -43, 0);
        }, 1, 0);

        # wind speed
        setlistener(me.props["/environment/wind-speed-kt"], func (node) {
            var windSpeed = node.getValue() or 0;
            if (windSpeed > 1) {
                me["wind.pointer"].show();
            }
            else {
                me["wind.pointer"].hide();
            }
            me["wind.kt"].setText(sprintf("%u", windSpeed));
        }, 1, 0);

        # groundspeed
        setlistener(me.props["/instrumentation/pfd/groundspeed-kt"], func (node) {
            self["groundspeed"].setText(sprintf("%3d", node.getValue() or 0));
        }, 1, 0);

        # selected altitude
        setlistener(me.props["/controls/flight/selected-alt"], func (node) {
            self["selectedalt.digital100"].setText(sprintf("%02d", (node.getValue() or 0) * 0.01));
        }, 1, 0);

        # comm/nav
        setlistener(me.props["/instrumentation/comm[0]/frequencies/selected-mhz"], func (node) {
            # self["vhf1.act"].setText(sprintf("%.2f", node.getValue() or 0));
        }, 1, 0);
        setlistener(me.props["/instrumentation/comm[0]/frequencies/standby-mhz"], func (node) {
            # self["vhf1.sby"].setText(sprintf("%.2f", node.getValue() or 0));
        }, 1, 0);
        setlistener(me.props["/instrumentation/nav[0]/frequencies/selected-mhz"], func (node) {
            # self["nav1.act"].setText(sprintf("%.2f", node.getValue() or 0));
        }, 1, 0);
        setlistener(me.props["/instrumentation/nav[0]/frequencies/standby-mhz"], func (node) {
            # self["nav1.sby"].setText(sprintf("%.2f", node.getValue() or 0));
        }, 1, 0);

        # VNAV annunciations
        # TODO
        # me["VNAV.constraints1"].hide();
        # me["VNAV.constraints2"].hide();

        # V-speed previews
        setlistener(me.props["/fms/vspeeds-effective/departure/v1"], func (node) {
            # self["asi.preview-v1.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0);
        setlistener(me.props["/fms/vspeeds-effective/departure/vr"], func (node) {
            # self["asi.preview-vr.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0);
        setlistener(me.props["/fms/vspeeds-effective/departure/v2"], func (node) {
            # self["asi.preview-v2.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0);
        setlistener(me.props["/fms/vspeeds-effective/departure/vfs"], func (node) {
            # self["asi.preview-vfs.digital"].setText(sprintf("%-3.0d", node.getValue()));
        }, 1, 0);
        setlistener(me.props["/instrumentation/pfd/airspeed-alive"], func (node) {
            # self["asi.vspeeds"].setVisible(!node.getBoolValue());
        }, 1, 0);

        # QNH
        var updateQNH = func {
            if (self.props["/instrumentation/pfd/qnh-mode"].getValue()) {
                # 1 = inhg
                self["QNH.digital"].setText(
                    sprintf("%5.2f IN", self.props["/instrumentation/altimeter/setting-inhg"].getValue()));
            }
            else {
                # 0 = hpa
                self["QNH.digital"].setText(
                    sprintf("%4.0f HPA", self.props["/instrumentation/altimeter/setting-hpa"].getValue()));
            }
        };
        setlistener(self.props["/instrumentation/pfd/qnh-mode"], updateQNH, 1, 0);
        setlistener(self.props["/instrumentation/altimeter/setting-inhg"], updateQNH, 1, 0);
        setlistener(self.props["/instrumentation/altimeter/setting-hpa"], updateQNH, 1, 0);

        var updateNavAnn = func () {
            var navsrc = self.props["/instrumentation/pfd/nav-src"].getValue() or 0;

            if (navsrc == 0) {
                self["navsrc.primary.selection"].setText("FMS");
                self["navsrc.primary.id"].setText("");
            }
            else {
                if (self.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/nav-loc"].getValue() or 0) {
                    self["navsrc.primary.selection"].setText("LOC" ~ navsrc);
                }
                else {
                    self["navsrc.primary.selection"].setText("VOR" ~ navsrc);
                }
                self["navsrc.primary.id"].setText(self.props["/instrumentation/nav[" ~ (navsrc - 1) ~ "]/nav-id"].getValue() or "");
            }
        };

        setlistener(self.props["/controls/flight/nav-src/side"],
            func (node) {
                if (node.getBoolValue()) {
                    self["fma.src.arrow"].setRotation(math.pi);
                }
                else {
                    self["fma.src.arrow"].setRotation(0);
                }
            }, 1, 0);

        # setlistener(self.props["/instrumentation/pfd/bearing[0]/visible"],
        #     func (node) { self["hsi.pointer.circle"].setVisible(node.getBoolValue()); },
        #     1, 0);
        # setlistener(self.props["/instrumentation/pfd/bearing[0]/bearing"],
        #     func (node) { self["hsi.pointer.circle"].setRotation(node.getValue() * D2R); },
        #     1, 0);
        # setlistener(self.props["/instrumentation/pfd/bearing[1]/visible"],
        #     func (node) { self["hsi.pointer.diamond"].setVisible(node.getBoolValue()); },
        #     1, 0);
        # setlistener(self.props["/instrumentation/pfd/bearing[1]/bearing"],
        #     func (node) { self["hsi.pointer.diamond"].setRotation(node.getValue() * D2R); },
        #     1, 0);

        setlistener(self.props["/instrumentation/nav[0]/nav-loc"], func { updateNavAnn(); }, 1, 0);
        setlistener(self.props["/instrumentation/nav[0]/nav-id"], func { updateNavAnn(); }, 1, 0);
        setlistener(self.props["/instrumentation/nav[1]/nav-loc"], func { updateNavAnn(); }, 1, 0);
        setlistener(self.props["/instrumentation/nav[1]/nav-id"], func { updateNavAnn(); }, 1, 0);

        setlistener(self.props["/instrumentation/pfd/nav-src"],
            func (node) {
                # if (node.getValue() == 0) {
                #     courseColor = [0, 0.75, 1];
                #     hsiColor = [1, 0, 1];
                #     me["ils.fmsloc"].show();
                #     me["ils.fmsvert"].show();
                # }
                # else {
                #     me["ils.fmsloc"].hide();
                #     me["ils.fmsvert"].hide();
                # }
                updateNavAnn();
            }, 1, 0);
        setlistener(self.props["/instrumentation/pfd/nav/course-source"],
            func (node) {
                if (node.getValue() == 0) {
                    self["selectedcourse.digital"].hide();
                }
                else {
                    self["selectedcourse.digital"].show();
                }
            }, 1, 0);
        setlistener(self.props["/instrumentation/pfd/nav/selected-radial"],
            func (node) {
                self["selectedcourse.digital"].setText(sprintf("%03d", node.getValue()));
            }, 1, 0);

        # DME
        setlistener(self.props["/instrumentation/pfd/nav/dme-source"], func (node) {
            var dmesrc = node.getValue();
            if (dmesrc > 0) {
                self["dme"].show();
                self["dme.selection"].setText("DME" ~ dmesrc);
            }
            else {
                self["dme"].hide();
            }
        }, 1, 0);
        setlistener(self.props["/instrumentation/pfd/dme/dist10"], func (node) {
            self["dme.dist"].setText(sprintf("%5.1f", node.getValue() * 0.1));
        }, 1, 0);
        setlistener(self.props["/instrumentation/pfd/dme/hold"], func (node) {
            self["dme.hold"].setVisible(node.getBoolValue());
        }, 1, 0);

        # HSI
        setlistener(self.props["/instrumentation/pfd/hsi/heading"],
            func (node) {
                var hsiHeading = node.getValue() * D2R;
                self["hsi.nav1"].setRotation(hsiHeading);
                self["hsi.dots"].setRotation(hsiHeading);
            }, 1, 0);
        setlistener(self.props["/instrumentation/pfd/hsi/deflection"],
            func (node) {
                self["hsi.nav1track"].setTranslation(node.getValue() * 48, 0);
            }, 1, 0);
        setlistener(self.props["/instrumentation/pfd/hsi/from-flag"],
            func (node) {
                var flag = node.getValue();
                self["hsi.from"].setVisible(flag == 1);
                self["hsi.to"].setVisible(flag == 0);
            }, 1, 0);

        # setlistener(self.props["/instrumentation/gps/cdi-deflection"],
        #     func (node) {
        #         self["ils.fmsloc"].setTranslation(math.round((node.getValue() or 0) * 10.0), 0);
        #     }, 1, 0);

        # setlistener(self.props["/instrumentation/gps/cdi-deflection"],
        #     func (node) {
        #         self["ils.fmsvert"].setTranslation(0, math.min(1000, math.max(-1000, node.getValue())) * 0.1);
        #     }, 1, 0);

        # updateILSColors = func {
        #     var ilssrc = self.props["/instrumentation/pfd/ils/source"].getValue();
        #     var navsrc = self.props["/instrumentation/pfd/nav-src"].getValue();
        #     var gsInRange = self.props["/instrumentation/pfd/ils/gs-in-range"].getBoolValue();
        #     var locInRange = self.props["/instrumentation/pfd/ils/loc-in-range"].getBoolValue();
        #     if (navsrc == 0) {
        #         self.ilscolor = [0, 0.75, 1]; # preview mode
        #     }
        #     else {
        #         self.ilscolor = [0, 1, 0]; # V/L mode
        #     }
        #     self["ils.gsneedle"].setColor(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
        #     if (gsInRange) {
        #         self["ils.gsneedle"].setColorFill(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
        #     }
        #     else {
        #         self["ils.gsneedle"].setColorFill(0, 0, 0);
        #     }
        #     self["ils.locneedle"].setColor(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
        #     if (locInRange) {
        #         self["ils.locneedle"].setColorFill(self.ilscolor[0], self.ilscolor[1], self.ilscolor[2]);
        #     }
        #     else {
        #         self["ils.locneedle"].setColorFill(0, 0, 0);
        #     }
        # };
        # setlistener(self.props["/instrumentation/pfd/ils/source"], updateILSColors, 1, 0);
        # setlistener(self.props["/instrumentation/pfd/nav-src"], updateILSColors, 1, 0);
        # setlistener(self.props["/instrumentation/pfd/ils/gs-in-range"], updateILSColors, 1, 0);
        # setlistener(self.props["/instrumentation/pfd/ils/loc-in-range"], updateILSColors, 1, 0);
        # setlistener(self.props["/instrumentation/pfd/ils/has-gs"], func (node) {
        #         self["ils.gsneedle"].setVisible(node.getBoolValue());
        #     }, 1, 0);
        # setlistener(self.props["/instrumentation/pfd/ils/has-loc"], func (node) {
        #         self["ils.locneedle"].setVisible(node.getBoolValue());
        #     }, 1, 0);
        # setlistener(self.props["/instrumentation/pfd/ils/gs-needle"], func (node) {
        #         self["ils.gsneedle"].setTranslation(0, math.round((node.getValue() or 0) * -100.0));
        #     }, 1, 0);
        # setlistener(self.props["/instrumentation/pfd/ils/loc-needle"], func (node) {
        #         self["ils.locneedle"].setTranslation(math.round((node.getValue() or 0) * 100.0), 0);
        #     }, 1, 0);

        # setlistener(self.props["/autopilot/route-manager/active"], func (node) {
        #     self["waypoint"].setVisible(node.getBoolValue());
        #     }, 1, 0);

        # setlistener(self.props["/autopilot/route-manager/wp/id"], func (node) {
        #     self["waypoint.id"].setText(node.getValue() or "");
        #     }, 1, 0);

        setlistener(self.props["/instrumentation/pfd/waypoint/dist10"], func (node) {
            self["waypoint.dist"].setText(
                sprintf("%5.1f", (node.getValue() or 0) * 0.1));
            }, 1, 0);

        # setlistener(self.props["/instrumentation/pfd/waypoint/ete"], func (node) {
        #         self["waypoint.ete"].setText(sprintf("%3d", node.getValue()));
        #     }, 1, 0);
        # setlistener(self.props["/instrumentation/pfd/waypoint/ete-unit"], func (node) {
        #         if (node.getBoolValue()) {
        #             self["waypoint.eteunit"].setText("MIN");
        #         }
        #         else {
        #             self["waypoint.eteunit"].setText("SEC");
        #         }
        #     }, 1, 0);

        # FMA
        setlistener(self.props["/it-autoflight/output/ap1"], func (node) {
                self["fma.ap"].setVisible(node.getBoolValue());
            }, 1, 0);
        setlistener(self.props["/it-autoflight/output/athr"], func (node) {
                self["fma.at"].setVisible(node.getBoolValue());
            }, 1, 0);
        setlistener("/instrumentation/annun/lat-mode", func (node) {
                self["fma.lat"].setText(node.getValue());
            }, 1, 0);
        setlistener("/instrumentation/annun/lat-mode-armed", func (node) {
                self["fma.latarmed"].setText(node.getValue());
            }, 1, 0);
        setlistener("/instrumentation/annun/vert-mode", func (node) {
                self["fma.vert"].setText(node.getValue());
            }, 1, 0);
        setlistener("/instrumentation/annun/vert-mode-armed", func (node) {
                self["fma.vertarmed"].setText(node.getValue());
            }, 1, 0);
        setlistener("/instrumentation/annun/spd-mode", func (node) {
                self["fma.spd"].setText(node.getValue());
            }, 1, 0);
        setlistener("/instrumentation/annun/spd-mode-armed", func (node) {
                self["fma.spdarmed"].setText(node.getValue());
            }, 1, 0);
        setlistener("/instrumentation/annun/spd-minor-mode", func (node) {
                self["fma.spd.minor"].setText(node.getValue());
            }, 1, 0);
        setlistener("/instrumentation/annun/spd-minor-mode-armed", func (node) {
                self["fma.spdarmed.minor"].setText(node.getValue());
            }, 1, 0);
        setlistener("/instrumentation/annun/appr-mode", func (node) {
                var value = node.getValue();
                self["fma.appr"].setText(value);
            });

        setlistener("/instrumentation/annun/hud-declutter", func (node) {
                var value = node.getValue();
                self["a3.ils.crosshair"].setVisible(value != 0);
                self["a3.ils.latscale"].setVisible(value != 0);
                self["a3.airspeed"].setVisible(value != 0);
                self["a3.baroalt"].setVisible(value != 0);
                self["a3.radioalt"].setVisible(value != 0);

                self["a3.runway"].setVisible(value == 2);

                self["speedtape.cover"].setVisible(value == 0);
                self["alttape.cover"].setVisible(value == 0);
                self["asi"].setVisible(value == 0);
                self["asi.odo-frame"].setVisible(value == 0);
                self["speedtape"].setVisible(value == 0);
                self["speedtape.frame"].setVisible(value == 0);
                self["alttape.frame"].setVisible(value == 0);
                self["alt.tape"].setVisible(value == 0);
                self["alt.odo"].setVisible(value == 0);
                self["alt.odo.frame"].setVisible(value == 0);
                self["mach.digital.group"].setVisible(value == 0);
                self["selectedalt.frame"].setVisible(value == 0);
                self["selectedspeed.frame"].setVisible(value == 0);
            }, 1, 0);
        setlistener("/instrumentation/annun/appr-mode-armed", func (node) {
                var value = node.getValue();
                self["fma.apprarmed"].setText(value);
            }, 1, 0);

        # var updateSelectedVSpeed = func {
        #     var vertMode = self.props["/it-autoflight/mode/vert"].getValue();
        #     if (vertMode == "V/S") {
        #         self["selectedvspeed.digital"].setText(sprintf("%+05d", (self.props["/it-autoflight/input/vs"].getValue() or 0)));
        #         self["selectedvspeed.digital"].show();
        #     }
        #     else if (vertMode == "FPA") {
        #         self["selectedvspeed.digital"].setText(sprintf("%+4.1f", (self.props["/it-autoflight/input/fpa"].getValue() or 0)));
        #         self["selectedvspeed.digital"].show();
        #     }
        #     else {
        #         self["selectedvspeed.digital"].hide();
        #     }
        # };

        # setlistener(self.props["/it-autoflight/mode/vert"], func {
        #     updateSelectedVSpeed();
        # }, 1, 0);
        # setlistener(self.props["/it-autoflight/input/vs"], updateSelectedVSpeed, 1, 0);
        # setlistener(self.props["/it-autoflight/input/fpa"], updateSelectedVSpeed, 1, 0);

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

        setlistener(self.props["/it-autoflight/input/kts"], updateSelectedSpeed, 1, 0);
        setlistener(self.props["/it-autoflight/input/mach"], updateSelectedSpeed, 1, 0);
        setlistener(self.props["/it-autoflight/input/kts-mach"], updateSelectedSpeed, 1, 0);

        setlistener(self.props["/controls/flight/speed-mode"], func(node) {
            if (node.getValue() == 1) {
                self["selectedspeed.fms"].show();
            }
            else {
                self["selectedspeed.fms"].hide();
            }
        }, 1, 0);

        setlistener(self.props["/instrumentation/pfd/alt-tape-offset"], func(node) {
            self["alt.tape"].setTranslation(0, node.getValue() * 0.27);
        }, 1, 0);

        setlistener(self.props["/instrumentation/pfd/alt-tape-thousands"], func(node) {
            var altTapeThousands = node.getValue() * 1000;
            self["altNumLow1"].setText(sprintf("%5.0f", altTapeThousands - 1000));
            self["altNumHigh1"].setText(sprintf("%5.0f", altTapeThousands));
            self["altNumHigh2"].setText(sprintf("%5.0f", altTapeThousands + 1000));
        }, 1, 0);

        # # Minimums
        setlistener(self.props["/instrumentation/pfd/radio-alt"], func(node) {
            var ra = node.getValue();
            # self["radioalt.digital"].setText(sprintf("%04d", ra));
            self["a3.radioalt"].setText(sprintf("%04d", ra));
        }, 1, 0);

        # self["radioalt.digital"].setText(sprintf("%04d", 0));
        # setlistener(self.props["/instrumentation/pfd/minimums-visible"], func(node) {
        #     self["minimums"].setVisible(node.getBoolValue());
        # }, 1, 0);
        # setlistener(self.props["/instrumentation/pfd/minimums-indicator-visible"], func(node) {
        #     self["minimums.indicator"].setVisible(node.getBoolValue());   
        # }, 1, 0);
        # setlistener(self.props["/instrumentation/pfd/radio-altimeter-visible"], func(node) {
        #     self["radioalt"].setVisible(node.getBoolValue());   
        # }, 1, 0);
        setlistener(self.props["/instrumentation/pfd/minimums-mode"], func(node) {
            if (node.getValue()) {
                self["minimums.barora"].setText("BARO");
            }
            else {
                self["minimums.barora"].setText("RA");
            }
        }, 1, 0);
        setlistener(self.props["/instrumentation/pfd/minimums-decision-altitude"], func(node) {
            self["minimums.digital"].setText(sprintf("%d", node.getValue()));
        }, 1, 0);

        setlistener(self.props["/instrumentation/pfd/fpa/visible"], func(node) {
            self["fpa"].setVisible(node.getBoolValue());
        }, 1, 0);
        setlistener(self.props["/instrumentation/pfd/fd/visible"], func(node) {
            self["fd"].setVisible(node.getBoolValue());
        }, 1, 0);
        setlistener(self.props["/instrumentation/pfd/fpa/target"], func(node) {
            var degrees = node.getValue();
            var degreesStr = sprintf("%0.1f", degrees);
            self["fpa"].setTranslation(0, degrees * -43);
            self["fpa.digital.1"].setText(degreesStr);
            self["fpa.digital.2"].setText(degreesStr);
        }, 1, 0);
    },

    update: func() {
        var pitch = me.props["/orientation/pitch-deg"].getValue() or 0;
        var roll =  me.props["/orientation/roll-deg"].getValue() or 0;
        var trackError = me.props["/instrumentation/pfd/track-error-deg"].getValue() or 0;
        var fpa = me.props["/instrumentation/pfd/fpa-deg"].getValue() or 0;
        var fdPitch = me.props["/instrumentation/pfd/fd/vert-offset-deg"].getValue() or 0;
        var fdRoll = me.props["/instrumentation/pfd/fd/lat-offset-deg"].getValue() or 0;

        me.h_trans.setTranslation(0, pitch * 43);
        me.h_rot.setRotation(-roll * D2R, me["horizon"].getCenter());
        if(math.abs(roll)<=45){
            me["bankPtr"].setRotation(roll*(-D2R));
        }
        me["slip"].setTranslation(math.round((me.props["/instrumentation/slip-skid-ball/indicated-slip-skid"].getValue() or 0)*50), 0);
        me["fpv"]
            .setTranslation(geo.normdeg180(trackError) * 43, fpa * -43)
            .setRotation(roll * D2R);
        me["fd"]
            .setTranslation(
                geo.normdeg180(trackError + fdRoll) * 43,
                (fpa + fdPitch) * -43)
            .setRotation(roll * D2R);

        # wind direction
        # For some reason, if we attempt to do this in a listener, it will
        # be extremely unreliable.
        me["wind.pointer"].setRotation((me.props["/environment/wind-from-heading-deg"].getValue() or 0) * D2R);

        # # FD
        # var pitchBar = me.props["/it-autoflight/fd/pitch-bar"].getValue() or 0;
        # var rollBar = me.props["/it-autoflight/fd/roll-bar"].getValue() or 0;
        # me["fd.pitch"].setTranslation(0, pitchBar * 8.05);
        # me["fd.roll"].setTranslation(rollBar * 8.05, 0);

        # A3 ILS
        if (me.props["/instrumentation/annun/hud-declutter"].getValue() != 0) {
            var x = me.props["/instrumentation/pfd/ils/crosstrack-error-m"].getValue() or 0;
            var g = me.props["/instrumentation/pfd/ils/gs-distance"].getValue() or 0;
            var alpha = me.props["/instrumentation/pfd/ils/heading-error"].getValue() or 0;
            var beta = math.atan2(x, g) * R2D;
            var gamma = alpha + beta;

            me["a3.ils.crosshair"].setTranslation(
                gamma * 43,
                me.props["/instrumentation/pfd/ils/gs-direct-deg"].getValue() * 43
            );
            me["a3.ils.latscale"].setTranslation(
                alpha * 43,
                0
            );
            me["a3.runway"].setTranslation(
                alpha * 43,
                0
            );
            var dy = me.props["/instrumentation/pfd/ils/gs-direct-deg"].getValue() * 43;
            var dx = me.props["/instrumentation/pfd/ils/runway-width-deg"].getValue() * 43;
            var sx = beta * 43;
            me["a3.runway.edges"]
                .reset()
                .moveTo(1024, 1024)
                .line((sx + dx) * 1.1, dy * 1.1)
                .moveTo(1024, 1024)
                .line((sx - dx) * 1.1, dy * 1.1)
        }

        # # V/S
        var vspeed = me.props["/instrumentation/vertical-speed-indicator/indicated-speed-fpm"].getValue() or 0;
        me["VS.digital"].setText(sprintf("%+05d", vspeed));
        # var vneedle = me.props["/instrumentation/pfd/vsi-needle-deg"].getValue() or 0;
        # me["vs.needle"].setRotation(vneedle * D2R);
        # me["VS.digital.wrapper"].setVisible(math.abs(vspeed) >= 500);

        # # Altitude
        var alt = me.props["/instrumentation/altimeter/indicated-altitude-ft"].getValue() or 0;

        if (me["a3.baroalt"].getVisible()) {
            me["a3.baroalt"].setText(sprintf("%5.0d B", alt));
        }

        var o = odoDigit(alt / 10, 0);
        me["alt.rollingdigits"].setTranslation(0, o * 12);
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
        me["alt.100"].setTranslation(0, o100 * 32);
        var o1000 = odoDigit(altR / 10, 2);
        me["alt.1000"].setTranslation(0, o1000 * 32);
        var o10000 = odoDigit(altR / 10, 3);
        me["alt.10000"].setTranslation(0, o10000 * 32);

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

        if (me["a3.airspeed"].getVisible()) {
            me["a3.airspeed"].setText(sprintf("%3.0d", airspeedRaw));
        }

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


        me["speederror.vector"].reset();
        me["speederror.vector"].rect(970, 1024, 10,
            math.max(-40.0, math.min(40.0, (selectedKts - airspeed))) * -2);
        me["speedtrend.pointer"].setTranslation(
            0,
            math.max(-40.0, math.min(40.0, (airspeedLookahead - airspeed))) * -2);

        me["speedtape"].setTranslation(0, (airspeed - 40) * 3.4);
        me["airspeed.bug"].setTranslation(0, (40 - math.max(40, selectedKts)) * 3.4);

        # var redSpeed = me.props["/fms/speed-limits/vstall-kt"].getValue() or 0;
        # var amberSpeed = me.props["/fms/speed-limits/vwarn-kt"].getValue() or 0;
        # var greenSpeed = me.props["/fms/speed-limits/green-dot-kt"].getValue() or 0;
        # var maxSpeed = me.props["/fms/speed-limits/vmo-effective"].getValue() or 0;

        # me["speedbar.red"].setTranslation(0, math.max(-41, (airspeed-redSpeed)) * 3.4);
        # me["speedbar.amber"].setTranslation(0, math.max(-41, (airspeed-amberSpeed)) * 3.4);
        # me["barberpole"].setTranslation(0, math.max(-41, (airspeed-maxSpeed)) * 3.4);
        # me["greendot"].setTranslation(0, (airspeed-greenSpeed) * 3.4);
        # if (greenSpeed > airspeed + 40 or greenSpeed < airspeed - 40) {
        #     me["greendot"].hide();
        # }
        # else {
        #     me["greendot"].show();
        # }
        # if (me.props["/gear/gear/wow"].getValue()) {
        #     me["speedbar.red"].hide();
        #     me["speedbar.amber"].hide();
        # }
        # else {
        #     me["speedbar.red"].show();
        #     me["speedbar.amber"].show();
        # }

        o = odoDigit(airspeed, 0);

        me["asi.1"].setTranslation(0, o * 32);

        o = odoDigit(airspeed, 1);
        me["asi.10"].setTranslation(0, o * 32);

        o = odoDigit(airspeed, 2);
        me["asi.100"].setTranslation(0, o * 32);

        # if (airspeed < 90.0) {
        #     me["asi.10.0"].hide();
        #     me["asi.10.9"].hide();
        # }
        # else {
        #     me["asi.10.0"].show();
        #     me["asi.10.9"].show();
        # }


        # Speed ref bugs
        foreach (var spdref; ["v1", "vr", "v2", "vfs"]) {
            var prop = me.props["/fms/vspeeds-effective/departure/" ~ spdref];
            var elem = me["speedref." ~ spdref];
            if (elem == nil) continue;
            if (prop == nil) {
                elem.hide();
            }
            else {
                ktsRel = math.max(40, (prop.getValue() or 0)) - 40;
                elem.setTranslation(0, ktsRel * -3.4);
                var phase = getprop("/fms/phase");
                if (phase == 0 or phase == 1) {
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
                ktsRel = math.max(40, (prop.getValue() or 0)) - 40;
                elem.setTranslation(0, ktsRel * -3.4);
                var phase = getprop("/fms/phase");
                if (phase == 6) {
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
            ktsRel = math.max(40, (prop.getValue() or 0)) - 40;
            flapsElem.setTranslation(0, ktsRel * -3.4);
            flapsElem.show();
        }

    },
};

setlistener("sim/signals/fdm-initialized", func {
    for (var i = 0; i < 2; i += 1) {
        HUD_display[i] = canvas.new({
            "name": "HUD" ~ i,
            "size": [2048, 2048],
            "view": [2048, 2048],
            "mipmapping": 1
        });
        HUD_display[i].set("additive-blend", 1);
        HUD_display[i].setColorBackground(0, 0, 0, 1);
        HUD_display[i].addPlacement({"texture": "hud" ~ (i+1) ~ ".png"});
        HUD_master[i] = HUD_display[i].createGroup();
        ED_only[i] =
            canvas_ED_only.new(
                HUD_master[i],
                "Aircraft/E-jet-family/Models/Primus-Epic/HUD.svg",
                i);
    }

    var timer0 = maketimer(0.04, func() {
        ED_only[0].update();
    });
    var timer1 = maketimer(0.04, func() {
        ED_only[1].update();
    });

    ED_only[0].update();
    ED_only[1].update();

    setlistener("/systems/electrical/outputs/pfd[0]", func (node) {
        var visible = ((node.getValue() or 0) >= 15);
        HUD_master[0].setVisible(visible);
        if (visible) timer0.start(); else timer0.stop();
    }, 1, 0);
    setlistener("/systems/electrical/outputs/pfd[1]", func (node) {
        var visible = ((node.getValue() or 0) >= 15);
        HUD_master[1].setVisible(visible);
        if (visible) timer1.start(); else timer1.stop();
    }, 1, 0);
});
