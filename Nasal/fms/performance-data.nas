# Adaptive performance data

var file = nil;
var filename = nil;
var initialized = 0;
var timer = nil;
var prev = nil;
var current = nil;
var interpolated = nil;

var nextEntry = func (dt) {
    current = {
        fl: getprop('/instrumentation/altimeter/pressure-alt-ft'),
        ias: getprop('/instrumentation/airspeed-indicator/indicated-speed-kt'),
        mach: getprop('/instrumentation/airspeed-indicator/indicated-mach'),
        fob: getprop('/consumables/fuel/total-fuel-kg'),
        gw: getprop('/fms/fuel/gw-kg'),
    };
    if (prev != nil) {
        interpolated = {
            gw: (current.gw + prev.gw) * 0.5,
            fl: (current.fl + prev.fl) * 0.5,
            ias: (current.ias + prev.ias) * 0.5,
            mach: (current.mach + prev.mach) * 0.5,
            ff: (prev.fob - current.fob) / dt, # kg per second!
            vs: (current.fl - prev.fl) * 60 / dt, # feet per minute
            iasAccel: (current.ias - prev.ias) / dt, # knots per second
            machAccel: (current.mach - prev.mach) / dt, # mach number change per second
        };

        # Only log if fuel hasn't been tampered with, and airspeed is alive.
        if (interpolated.ff > 0.0 and interpolated.ias > 40.0) {
            var str = sprintf(
                            "%5.0f %5.0f %3.0f %0.3f %1.10f %4.0f %3.3f %1.8f",
                            interpolated.gw,
                            interpolated.fl,
                            interpolated.ias,
                            interpolated.mach,
                            interpolated.ff,
                            interpolated.vs,
                            interpolated.iasAccel,
                            interpolated.machAccel);
            logprint(2, "Performance entry: " ~ str);
            file = io.open(filename, 'a');
            io.write(file, str ~ "\n");
            io.close(file);
        }
        else {
            logprint(2, "No performance entry");
        }
    }
    prev = current;
};

var initialized = 0;
var initialize = func () {
    var dt = 10;
    if (initialized) return;
    filename = getprop('/sim/fg-home') ~ '/Export/' ~ getprop('/sim/aircraft') ~ '-performance.dat';
    logprint(3, "Performance log file: " ~ filename);
    if (io.stat(filename) != nil) {
        logprint(3, "Performance log: loading");
        var consolidated = {};
        var line = nil;
        file = io.open(filename, 'r');
        while ((line = io.readln(file)) != nil) {
            var items = [];
            if (string.scanf(line, "%f %f %f %f %f %f %f %f %f", items) < 0) {
                items = [];
                if (string.scanf(line, "%f %f %f %f %f %f %f %f", items = []) < 0) {
                    logprint(4, "Skipping invalid log line: " ~ line);
                    continue;
                }
            }
            if (size(items) < 9) {
                append(items, 1);
            }
            (gw, fl, ias, mach, ff, vs, iasAccel, machAccel, weight) = items;
            if ((abs(iasAccel) < 0.1 or abs(machAccel) < 0.1) and abs(vs) < 100) {
                gwBucket = math.round(gw / 1000);
                flBucket = math.round(fl / 1000);
                iasBucket = math.round(ias / 100);
                var key = sprintf("%02.0f:%03.0f:%02.0f", gwBucket, flBucket, iasBucket);
                var other = consolidated[key];
                var interpolated = {};
                var self =
                        {
                            gw: gw,
                            fl: fl,
                            ias: ias,
                            mach: mach,
                            ff: ff,
                            vs: vs,
                            iasAccel: iasAccel,
                            machAccel: machAccel,
                            weight: weight
                        };
                if (other == nil) {
                    interpolated = self;
                }
                else {
                    foreach (var k; ['gw', 'fl', 'ias', 'mach', 'ff', 'vs', 'iasAccel', 'machAccel']) {
                        interpolated[k] = (self.weight * self[k] + other.weight * other[k]) / (self.weight + other.weight);
                    }
                    interpolated.weight = self.weight + other.weight;
                }
                consolidated[key] = interpolated;
            }
        }
        io.close(file);
        foreach (var key; keys(consolidated)) {
            var entry = consolidated[key];
            var entryLine = sprintf(
                        "%5.0f %5.0f %3.0f %0.3f %1.10f %4.0f %3.3f %1.8f %1.0f",
                        entry.gw,
                        entry.fl,
                        entry.ias,
                        entry.mach,
                        entry.ff,
                        entry.vs,
                        entry.iasAccel,
                        entry.machAccel,
                        entry.weight);
            debug.dump(key, entryLine);
        }
    }
    timer = maketimer(dt, func { nextEntry(dt); });
    timer.simulatedTime = 1;
    timer.singleShot = 0;
	timer.start();
};

initialize();
