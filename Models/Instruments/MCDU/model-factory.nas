var modelFactory = func (key) {
    # for now, only KeyPropModel can be loaded
    if (contains(keyProps, key)) {
        return KeyPropModel.new(key);
    }
    else {
        return BaseModel.new();
    }
};

var routeDepartureLens = {
    get: func (route) { return route.departureAirport; },
    set: func (route, val) { return route.departureAirport = val; }
};

var routeDestinationLens = {
    get: func (route) { return route.destinationAirport; },
    set: func (route, val) { return route.destinationAirport = val; }
};

var routeLenses = {
    'DEPARTURE-AIRPORT': routeDepartureLens,
    'DESTINATION-AIRPORT': routeDestinationLens,
};

var makeAirportModel = func(owner, key) {
    return FuncModel.new(key,
        func () {
            var lens = routeLenses[key];
            var ap = lens.get(owner.route);
            if (ap == nil) return "▯▯▯▯";
            return ap.id;
        },
        func (icao) {
            if (size(icao) != 4) return nil;
            var lens = routeLenses[key];
            var aps = findAirportsByICAO(icao);
            if (size(aps) == 1) {
                owner.startEditing();
                lens.set(owner.route, aps[0]);
                fms.kickRouteManager();
                owner.fullRedraw();
            }
            else {
                owner.mcdu.setScratchpadMsg('NO AIRPORT', mcdu_yellow);
            }
        },
        func () {
            var lens = routeLenses[key];
            owner.startEditing();
            lens.set(owner.route, nil);
            fms.kickRouteManager();
            owner.fullRedraw();
        });
};


