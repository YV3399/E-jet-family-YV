# list of lists; each entry represents one beam, entries are ordered
# near to far and signify distance to nearest terrain on the selected path.
var wx_buffer = [];
var ground_buffer = [];

var wx_ranges = [ 10, 25, 50, 100, 200, 300 ];

var bestRangeFor = func(target) {
    forindex (var i; wx_ranges) {
        if (wx_ranges[i] >= target) {
            return wx_ranges[i];
        }
    }
    return 300;
}

var range_left = 300;
var range_right = 300;

var scan_active = 0;
var left_mode = 0;
var right_mode = 0;
var scan_rate = 0;
var dist_resolution = 128;
var angle_resolution = 120; # number of steps
var sweep_min = -60; # degrees
var sweep_max = 60; # degrees
var scan_rate = 240.0; # steps per second
var scan_range = 10.0; # in miles
var tilt = 0.0; # in degrees
var tilt_range = 5.6; # in degrees
var gain = 20.0;

var prop_sweep_pos = nil;
var prop_scan_pos = nil;
var prop_heading = nil;
var prop_range = nil;
var prop_tilt = nil;
var prop_gain = nil;
var prop_sect = nil;

var setup_buffers = func () {
    for (var a = 0; a < angle_resolution; a += 1) {
        append(wx_buffer, []);
        append(ground_buffer, []);
        for (var d = 0; d < dist_resolution; d += 1) {
            append(wx_buffer[a], 0.0);
            append(ground_buffer[a], 0.0);
        }
    }
};

var clear_buffers = func () {
    for (var a = 0; a < angle_resolution; a += 1) {
        append(wx_buffer, []);
        append(ground_buffer, []);
        for (var d = 0; d < dist_resolution; d += 1) {
            wx_buffer[a][d] = 0.0;
            ground_buffer[a][d] = 0.0;
        }
    }
};

var get_ground_pixel = func (angle, dist) {
    var a = math.floor((angle - sweep_min) / (sweep_max - sweep_min) * angle_resolution);
    var d = math.floor(dist / scan_range * dist_resolution);
    if (a < 0 or a >= angle_resolution or
        d < 0 or d >= dist_resolution)
        return nil;
    return ground_buffer[a][d];
};

var get_weather_pixel = func (angle, dist) {
    var a = math.floor((angle - sweep_min) / (sweep_max - sweep_min) * angle_resolution);
    var d = math.floor(dist / scan_range * dist_resolution);
    if (a < 0 or a >= angle_resolution or
        d < 0 or d >= dist_resolution)
        return nil;
    return wx_buffer[a][d];
};


var set_mode = func ( mode) {
    scan_active = mode;
};

var update_wxr = func () {
    if (!scan_active) return;
    var acpos = geo.aircraft_position();
    var achdg = prop_heading.getValue();

    # update sweep and scan positions
    var scan_pos = prop_scan_pos.getValue();
    var sweep_pos = prop_sweep_pos.getValue();
    scan_pos += 1;
    if (scan_pos >= angle_resolution) {
        scan_pos = 0;
    }
    sweep_pos = sweep_min + (sweep_max - sweep_min) * (scan_pos / angle_resolution);

    # clear the current beam
    for (var d = 0; d < dist_resolution; d += 1) {
        wx_buffer[scan_pos][d] = 0;
        ground_buffer[scan_pos][d] = 0;
    }

    var scan_range_m = scan_range * NM2M;

    # perform terrain scan
    var start = geo.Coord.new(acpos);
    var tgt = geo.Coord.new(start);
    tgt.apply_course_distance(geo.normdeg(achdg + sweep_pos), 2 * scan_range * NM2M);
    var returns = [];
    var alpha_step = 0.2;
    var ground_gain = 0.25 * gain * alpha_step / tilt_range;
    for (var alpha = -tilt_range; alpha <= tilt_range; alpha += alpha_step) {
        var deltaAlt = math.tan((tilt + alpha) * D2R) * 2 * scan_range_m;
        var end = geo.Coord.new(tgt);
        end.set_alt(start.alt() + deltaAlt);
        var xyz = {"x": start.x(), "y": start.y(), "z": start.z()};
        var dir = {"x": end.x() - start.x(), "y": end.y() - start.y(), "z": end.z() - start.z()};
        var terrain_geod = get_cart_ground_intersection(xyz, dir);
        if (terrain_geod != nil) {
            end.set_latlon(terrain_geod.lat, terrain_geod.lon, terrain_geod.elevation);
            var projDist = math.round(start.direct_distance_to(end) * M2NM * dist_resolution / scan_range);
            append(returns, projDist);
        }
    }
    foreach (var ret; returns) {
        if (ret >= 0 and ret < dist_resolution) {
            ground_buffer[scan_pos][ret] += ground_gain;
        }
    }

    # do a weather scan
    if (defined('local_weather')) {
        foreach (var effectVolume; local_weather.effectVolumeArray) {
            if (!effectVolume.rain_flag and !effectVolume.snow_flag) {
                # transparent weather, can't see it
                # print("Not precipitation, skip");
                continue;
            }
            if (effectVolume.lat == nil) {
                print("lat is nil");
                continue;
            }
            if (effectVolume.lon == nil) {
                print("lon is nil");
                continue;
            }
            var effectPos = geo.Coord.new(acpos);
            effectPos.set_lat(effectVolume.lat);
            effectPos.set_lon(effectVolume.lon);
            var bearing = acpos.course_to(effectPos);
            var dist = acpos.direct_distance_to(effectPos);
            var scan_alt = acpos.alt() + dist * math.tan(tilt * D2R);
            if (scan_alt < effectVolume.alt_low or scan_alt > effectVolume.alt_high) {
                # beam passed over or under the weather
                # printf("ALT MISMATCH: %1.0f <= %1.0f <= %1.0f",
                #     effectVolume.alt_low, scan_alt, effectVolume.alt_high);
                continue;
            }
            var bearing_delta = geo.normdeg180(bearing - (achdg + sweep_pos));
            var dx = dist * math.tan(bearing_delta * D2R);
            var er = effectVolume.r1 + effectVolume.r2; # twice the average radius
            if (dx > er) {
                # beam passes left or right of the weather
                continue;
            }
            var depth_squared = er * er - dx * dx;
            if (depth_squared <= 0) {
                # cater for rounding errors and such
                continue;
            }
            var depth = math.sqrt(depth_squared);
            var from_dist = (dist - depth) * M2NM;
            var to_dist = (dist + depth) * M2NM;
            var proj_from = math.round(from_dist * dist_resolution / scan_range);
            var proj_to = math.round(to_dist * dist_resolution / scan_range);
            var step = (scan_range / dist_resolution) * NM2M;
            var dy = -depth;
            var baseSat = math.max(0, effectVolume.rain) * 0.01 +
                          math.max(0, effectVolume.snow) * 0.005;
            for (var d = proj_from; d <= proj_to; d += 1) {
                var r = math.sqrt(dx * dx + dy * dy);
                var sat = baseSat * math.pow(er / r, 2.0);
                if (d >= dist_resolution) break; # no need to continue
                if (d >= 0) wx_buffer[scan_pos][d] += sat;
                dy += step;
            }
        }

        # weaken signals as the beam passes through things
        var atmo_atten = 1.0; # 1.0 = full strength
        var terrain_obsc = 0.0; # 1.0 = fully obscured
        var vargain = gain;
        for (d = 0; d < dist_resolution; d += 1) {
            # terrain return should add up to 1 for terrain that covers the
            # entire vertical scan range, so adding returns as we encounter
            # them should get us the effective obscuration
            terrain_obsc = math.min(1, terrain_obsc + ground_buffer[scan_pos][d]);

            # for atmospheric attenuation, we implement an exponential
            # dropoff.
            var r = wx_buffer[scan_pos][d];
            var atten = math.pow(100, -r * scan_range * NM2M / (dist_resolution * 2000));
            atmo_atten *= atten;

            strength = (1.0 - terrain_obsc) * atmo_atten;
            wx_buffer[scan_pos][d] *= strength * vargain;
            if (strength < 0.05) {
                wx_buffer[scan_pos][d] = 0;
            }
            else if (strength < 0.3) {
                # put a value > 1 here to make it light up in cyan
                wx_buffer[scan_pos][d] = 1.1;
                atmo_atten = 0;
            }
            else {
                # keep it just under 1 to avoid cyan
                wx_buffer[scan_pos][d] = math.min(0.999, wx_buffer[scan_pos][d]);
            }
        }
    }

    # update also triggers renderers
    prop_scan_pos.setValue(scan_pos);
    prop_sweep_pos.setValue(sweep_pos);
};

setlistener("sim/signals/fdm-initialized", func {
    prop_sweep_pos = props.globals.getNode("/instrumentation/wxr/sweep-pos-deg");
    prop_scan_pos = props.globals.getNode("/instrumentation/wxr/scan-pos");
    prop_heading = props.globals.getNode("/orientation/heading-deg");
    prop_range = props.globals.getNode("/instrumentation/wxr/range-nm");
    prop_tilt = props.globals.getNode("/instrumentation/wxr/tilt-angle-deg");
    prop_gain = props.globals.getNode("/instrumentation/wxr/gain");
    prop_sect = props.globals.getNode("/instrumentation/wxr/sector-scan");

    setup_buffers();

    var timer = maketimer(1.0 / scan_rate, func() {
        update_wxr();
    });
    timer.start();

    # Auto-select suitable range based on demand on both sides
    var updateRange = func {
        var range = 10;
        if (left_mode >= 2) { range = math.max(range, range_left); }
        if (right_mode >= 2) { range = math.max(range, range_right); }
        prop_range.setValue(range);
    };

    setlistener("/instrumentation/mfd[0]/wx-mode", func (node) {
        left_mode = node.getValue();
        updateRange();
    }, 1, 0);
    setlistener("/instrumentation/mfd[1]/wx-mode", func (node) {
        right_mode = node.getValue();
        updateRange();
    }, 1, 0);
    setlistener("/instrumentation/mfd[0]/lateral-range", func (node) {
        range_left = bestRangeFor(node.getValue() or 500);
        updateRange();
    }, 1, 0);
    setlistener("/instrumentation/mfd[1]/lateral-range", func (node) {
        range_right = bestRangeFor(node.getValue() or 500);
        updateRange();
    }, 1, 0);
    setlistener("/instrumentation/wxr/mode", func (node) {
        set_mode(node.getValue());
    }, 1, 0);
    setlistener(prop_tilt, func (node) {
        tilt = node.getValue();
    }, 1, 0);
    setlistener(prop_range, func (node) {
        scan_range = node.getValue();
    }, 1, 0);
    setlistener(prop_gain, func (node) {
        gain = node.getValue();
    }, 1, 0);
    setlistener(prop_sect, func (node) {
        if (node.getBoolValue()) {
            sweep_min = -30;
            sweep_max = 30;
            clear_buffers();
        }
        else {
            sweep_min = -60;
            sweep_max = 60;
            clear_buffers();
        }
    }, 1, 0);
});
