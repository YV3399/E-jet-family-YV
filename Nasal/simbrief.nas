var download = func (username, onSuccess, onFailure=nil) {
    if (getprop('/sim/simbrief/downloading')) {
        print("SimBrief download already active");
    }
    setprop('/sim/simbrief/downloading', 1);
    setprop('/sim/simbrief/text-status', 'downloading...');
    var filename = getprop('/sim/fg-home') ~ "/Export/simbrief.xml";
    var url = "https://www.simbrief.com/api/xml.fetcher.php?username=" ~ username;
    if (onFailure == nil) {
        onFailure = func (r) {
            setprop('/sim/simbrief/text-status', 'HTTP error (%s/%s)', r.status, r.reason);
            printf("SimBrief download from %s failed with HTTP status %s",
                url, r.status);
        }
    }

    http.save(url, filename)
        .done(func (r) {
                setprop('/sim/simbrief/text-status', 'parsing...');
                printf("SimBrief download from %s complete.", url);
                var errs = [];
                call(onSuccess, [filename], nil, {}, errs);
                if (size(errs) > 0) {
                    setprop('/sim/simbrief/text-status', 'parser errors, see log for details');
                    debug.printerror(errs);
                }
                else {
                    setprop('/sim/simbrief/text-status', 'all done!');
                }
            })
        .fail(onFailure)
        .always(func {
            setprop('/sim/simbrief/downloading', 0);
        });
};

var read = func (filename=nil) {
    if (filename == nil) {
        filename = getprop('/sim/fg-home') ~ "/Export/simbrief.xml";
    }
    var xml = io.readxml(filename);
    var ofpNode = xml.getChild('OFP');
    if (ofpNode == nil) {
        print("Error loading SimBrief OFP");
        return nil;
    }
    else {
        return ofpNode;
    }
};

var toFlightplan = func (ofp, fp=nil) {
    # get departure and destination
    var departureID = ofp.getNode('origin/icao_code').getValue();
    var departures = findAirportsByICAO(departureID);
    if (departures == nil or size(departures) == 0) {
        printf("Airport not found: %s", departureID);
        return nil;
    }

    var destinationID = ofp.getNode('destination/icao_code').getValue();
    var destinations = findAirportsByICAO(destinationID);
    if (destinations == nil or size(destinations) == 0) {
        printf("Airport not found: %s", destinationID);
        return nil;
    }

    # cruise parameters
    var initialAltitude = ofp.getNode('general/initial_altitude').getValue();
    var cruiseAltitude = initialAltitude;
    var seenTOC = 0;

    # collect enroute waypoints
    var wps = [];
    var ofpNavlog = ofp.getNode('navlog');
    var ofpFixes = ofpNavlog.getChildren('fix');
    foreach (var ofpFix; ofpFixes) {
        if (ofpFix.getNode('is_sid_star').getBoolValue()) {
            # skip: we only want enroute waypoints
            continue;
        }
        var ident = ofpFix.getNode('ident').getValue();
        if (ident == 'TOC' or ident == 'TOD') {
            # skip TOC and TOD: the FMS should deal with those dynamically
            if (ident == 'TOC') {
                seenTOC = 1;
            }
            continue;
        }
        var altNode = ofpFix.getNode('altitude_feet');
        var alt = (altNode == nil) ? nil : altNode.getValue();
        var coords = geo.Coord.new();
        coords.set_latlon(
            ofpFix.getNode('pos_lat').getValue(),
            ofpFix.getNode('pos_long').getValue());
        printf("%s %f %f", ident, coords.lat(), coords.lon());
        var wp = createWP(coords, ident);
        if (seenTOC and alt == initialAltitude) {
            # this is the waypoint where we expect to reach initial cruise
            # altitude
            
            # reset 'seen TOC' flag to avoid setting alt restrictions on
            # subsequent waypoints
            seenTOC = 0;

            # we'll use an "at" restriction here: we don't want to climb any
            # higher, hence "above" would be wrong, and we want the VNAV to do
            # its best to reach the altitude before this point, so "below"
            # would also be wrong.

            # This doesn't work, and I don't know why.
            # wp.setAltitude(alt, 'at');
        }
        else if (alt > cruiseAltitude) {
            # this is a step climb target waypoint
            cruiseAltitude = alt;

            # This doesn't work, and I don't know why.
            # wp.setAltitude(alt, 'at');
        }
        append(wps, wp);
    }

    # we have everything we need; it's now safe-ish to overwrite or
    # create the actual flightplan

    if (fp == nil) {
        fp = createFlightplan();
    }
    fp.cleanPlan();
    fp.sid = nil;
    fp.sid_trans = nil;
    fp.star = nil;
    fp.star_trans = nil;
    fp.approach = nil;
    fp.approach_trans = nil;
    fp.departure = departures[0];
    fp.destination = destinations[0];
    fp.insertWaypoints(wps, 1);
    return fp;
};

var importFOB = func (ofp) {
    var unit = ofp.getNode('params/units').getValue();
    var fuelFactor = ((unit == 'lbs') ? LB2KG : 1);

    # From here on, we'll do everything in kilograms (kg)
    var fob = ofp.getNode('fuel/plan_ramp').getValue() * fuelFactor;
    var unallocated = fob;

    printf("Fuel to allocate: %1.1f kg", fob);

    var allocate = func(tankNumber, maxAmount = nil) {
        var tankNode = props.globals.getNode('/consumables/fuel/tank[' ~ tankNumber ~ ']');
        if (tankNode == nil) {
            printf("Tank #%i not installed", tankNumber);
            return;
        }
        var tankName = tankNode.getNode('name').getValue();
        var amount = unallocated;
        if (maxAmount != nil) {
            amount = math.min(amount, maxAmount);
        }
        var tankCapacity =
                tankNode.getNode('capacity-m3').getValue() *
                tankNode.getNode('density-kgpm3').getValue();
        amount = math.min(amount, tankCapacity);
        printf("Allocating %1.1f/%1.1f kg to %s", amount, unallocated, tankName);
        tankNode.getNode('level-kg').setValue(amount);
        unallocated -= amount;
    }
    
    # first, put a suitable amount in the tail trimmer tank
    allocate(3, unallocated * 0.05);
    # now fill wing tanks equally (up to half the remaining amount)
    var wingTankMax = unallocated * 0.5;
    allocate(0, wingTankMax);
    allocate(2, wingTankMax);
    # now the central tank, then lower deck tank if installed
    allocate(1);
    allocate(4);
    printf("Fuel not allocated: %1.1f kg", unallocated);
};

var importPayload = func (ofp) {
    var unit = ofp.getNode('params/units').getValue();
    var factor = ((unit == 'lbs') ? 1 : KG2LB);

    # Everything in lbs
    var payload = ofp.getNode('weights/payload').getValue() * factor;
    setprop('/payload/weight[1]/weight-lb', payload);
};

var importPerfInit = func (ofp) {
    # climb profile: kts-below-FL100/kts-above-FL100/mach
    var climbProfile = split('/', ofp.getNode('general/climb_profile').getValue());
    # descent profile: mach/kts-above-FL100/kts-below-FL100
    var descentProfile = split('/', ofp.getNode('general/descent_profile').getValue());
    var cruiseMach = ofp.getNode('general/cruise_mach').getValue();
    var airline = ofp.getNode('general/icao_airline').getValue();
    var flightNumber = ofp.getNode('general/flight_number').getValue();
    var callsign = airline ~ flightNumber;
    var cruiseAlt = ofp.getNode('general/initial_altitude').getValue();

    
    setprop("/sim/multiplay/callsign", callsign);
    setprop("/controls/flight/speed-schedule/climb-below-10k", climbProfile[0]);
    setprop("/controls/flight/speed-schedule/climb-kts", climbProfile[1]);
    setprop("/controls/flight/speed-schedule/climb-mach", climbProfile[2] / 100);
    setprop("/controls/flight/speed-schedule/cruise-mach", cruiseMach);
    setprop("/autopilot/route-manager/cruise/altitude-ft", cruiseAlt);
    setprop("/controls/flight/speed-schedule/descent-mach", descentProfile[0] / 100);
    setprop("/controls/flight/speed-schedule/descent-kts", descentProfile[1]);
    setprop("/controls/flight/speed-schedule/descent-below-10k", descentProfile[2]);
};

var aloftTimer = nil;
var aloftPoints = [];

var setAloftWinds = func (aloftPoint) {
    # printf("setAloftWinds()");
    # debug.dump(aloftPoint);
    forindex (var i; aloftPoint.layers) {
        var node = props.globals.getNode("/environment/config/aloft/entry[" ~ i ~ "]");
        node.getChild('elevation-ft').setValue(aloftPoint.layers[i].alt);
        node.getChild('wind-from-heading-deg').setValue(aloftPoint.layers[i].dir);
        node.getChild('wind-speed-kt').setValue(aloftPoint.layers[i].spd);
        node.getChild('temperature-degc').setValue(aloftPoint.layers[i].temp);
    }
};

var interpolate = func (f, a, b) {
    return a + f * (b - a);
};

var interpolateDegrees = func (f, a, b) {
    return geo.normdeg(a + geo.normdeg180(b - a) * f);
};

var interpolateComponentWise = func (f, ipf, a, b) {
    var s = math.min(size(a), size(b));
    var result = [];
    for (var i = 0; i < s; i = i+1) {
        append(result, ipf(f, a[i], b[i]));
    }
    return result;
};

var interpolateLayers = func (f, a, b) {
    if (b == nil) return a;
    if (a == nil) return b;
    return {
        alt: interpolate(f, a.alt, b.alt),
        spd: interpolate(f, a.spd, b.spd),
        temp: interpolate(f, a.temp, b.temp),
        dir: interpolateDegrees(f, a.dir, b.dir),
    };
};

var interpolateAloftPoints = func (f, a, b) {
    if (b == nil) return a;
    if (a == nil) return b;
    return {
        layers: interpolateComponentWise(f, interpolateLayers, a.layers, b.layers),
    };
};

var updateAloft = func () {
    # printf("updateAloft()");
    var pos = geo.aircraft_position();
    foreach (var p; aloftPoints) {
        p.dist = pos.distance_to(p.coord);
    }
    var sorted = sort(aloftPoints, func (a, b) { return (a.dist - b.dist); });
    var pointA = sorted[0];
    var pointB = sorted[1];
    var f = (pointB.dist < 0.1) ? 0 : (pointB.dist / (pointA.dist + pointB.dist));
    # foreach (var s; sorted) {
    #     printf(s.dist);
    # }
    # debug.dump(f, pointA, pointB);
    var aloftPoint = interpolateAloftPoints(f, pointA, pointB);
    # printf("Aloft wind interpolation: %f between %s and %s",
    #     f, pointA.name, pointB.name);
    # debug.dump(aloftPoint.layers);
    setAloftWinds(aloftPoint);
};

var startAloftUpdater = func () {
    if (aloftTimer == nil) {
        aloftTimer = maketimer(10, updateAloft);
        aloftTimer.simulatedTime = 1;
    }
    if (aloftTimer.isRunning) return;
    aloftTimer.start();
};

var importWindsAloft = func (ofp) {
    # # disable default winds and set winds-aloft mode
    # setprop("/local-weather/config/wind-model", "aloft waypoints");
    # setprop("/environment/params/metar-updates-winds-aloft", 0);

    # if (defined('local_weather')) {
    #     # clear out the advanced weather winds-aloft interpolation points
    #     setsize(local_weather.windIpointArray, 0);
    # }

    # now go through the flightplan waypoints and create a wind interpolation point for each of them.
    var ofpNavlog = ofp.getNode('navlog');
    var ofpFixes = ofpNavlog.getChildren('fix');
    foreach (var ofpFix; ofpFixes) {
        var lat = ofpFix.getNode('pos_lat').getValue();
        var lon = ofpFix.getNode('pos_long').getValue();
        var args = [lat, lon];
        var layers = [];
        var uneven = 0;
        foreach (var ofpWindLayer; ofpFix.getNode('wind_data').getChildren('level')) {
            var dir = ofpWindLayer.getNode('wind_dir').getValue();
            var spd = ofpWindLayer.getNode('wind_spd').getValue();
            var alt = ofpWindLayer.getNode('altitude').getValue();
            var temp = ofpWindLayer.getNode('oat').getValue();
            if (alt != 14000) {
                # advanced weather ignores this one for some reason
                append(args, dir, spd);
            }
            # pick up every other layer: simbrief reports 10 layers starting
            # at sea level, but we can only use 5, and we don't need sea level
            # (as that comes from METAR)
            if (uneven) {
                append(layers, { alt: alt, dir: dir, spd: spd, temp: temp });
            }
            uneven = !uneven;
        }
        # if (defined('local_weather')) {
        #     call(local_weather.set_wind_ipoint, args);
        # }
        var aloftPos = geo.Coord.new();
        aloftPos.set_latlon(lat, lon);

        var aloftPoint = { coord: aloftPos, dist: 0.0, layers: layers, name: ofpFix.getNode('ident').getValue() };
        append(aloftPoints, aloftPoint);
    }
    startAloftUpdater();
};

var loadFP = func () {
    var username = getprop('/sim/simbrief/username');
    if (username == nil or username == '') {
        print("Username not set");
        return;
    }

    download(username, func (filename) {
        var ofpNode = read(filename);
        if (ofpNode == nil) {
            print("Error loading simbrief XML file");
            return;
        }

        if (getprop('/sim/simbrief/options/import-fp') or 0) {
            var fp = toFlightplan(ofpNode, fms.getModifyableFlightplan());
            if (fp == nil) {
                print("Error parsing flight plan");
            }
            else {
                if (getprop('/sim/simbrief/options/autocommit') or 0) {
                    fms.commitFlightplan();
                }
                fms.kickRouteManager();
            }
        }
        if (getprop('/sim/simbrief/options/import-fob') or 0) {
            importFOB(ofpNode);
        }
        if (getprop('/sim/simbrief/options/import-payload') or 0) {
            importPayload(ofpNode);
        }
        if (getprop('/sim/simbrief/options/import-perfinit') or 0) {
            importPerfInit(ofpNode);
        }
        if (getprop('/sim/simbrief/options/import-winds-aloft') or 0) {
            importWindsAloft(ofpNode);
        }
    });
};
