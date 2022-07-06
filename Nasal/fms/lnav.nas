var lnavProps = {
    'iru': {
        latitude: props.globals.getNode('/instrumentation/iru[0]/outputs/latitude-deg'),
        longitude: props.globals.getNode('/instrumentation/iru[0]/outputs/longitude-deg'),
    },
    'nextWP': {
        trueBearing: props.globals.getNode('/fms/lnav/next-wp/true-bearing-deg'),
        distance: props.globals.getNode('/fms/lnav/next-wp/distance-nm'),
    },
};

var updateLNAV = func {
    var fp = flightplan();
    if (fp == nil) return;
    var wp = fp.currentWP();
    if (wp == nil) return;

    var wpC = geo.Coord.new();
    wpC.set_latlon(wp.lat, wp.lon);
    var acC = geo.Coord.new();
    acC.set_latlon(lnavProps.iru.latitude.getValue() or 0, lnavProps.iru.longitude.getValue() or 0);

    lnavProps.nextWP.trueBearing.setValue(acC.course_to(wpC));
    lnavProps.nextWP.distance.setValue(acC.distance_to(wpC) * M2NM);
};

var lnavTimer = maketimer(1.0 / 120.0, updateLNAV);
lnavTimer.simulatedTime = 1;
lnavTimer.start();

setlistener("/autopilot/route-manager/current-wp", updateLNAV, 1, 0);
