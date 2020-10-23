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

var loadFP = func (options=nil) {
    if (options == nil) {
        options = {};
    }
    if (options['username'] != nil) {
        setprop('/sim/simbrief/username', options['username']);
    }
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
        var fp = toFlightplan(ofpNode, fms.getModifyableFlightplan());
        if (fp == nil) {
            print("Error parsing flight plan");
        }
        else {
            if (options['autocommit'] or 0) {
                fms.commitFlightplan();
            }
            fms.kickRouteManager();
        }
    });
};
