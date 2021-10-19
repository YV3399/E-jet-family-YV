var wordsplit = func (str) {
    var splits = [];
    var pos = 0;
    while (size(str) > 0) {
        pos = find(' ', str);
        if (pos == 0) {
            str = substr(str, 1);
        }
        elsif (pos == -1) {
            append(splits, str);
            str = '';
        }
        else {
            append(splits, substr(str, 0, pos));
            str = substr(str, pos);
        }
    }
    return splits;
};

var AirwaysDB = {
    findSegmentsFrom: func(airwayID, waypointID) {
        var found = [];
        var airway = me.airways[airwayID];
        if (airway == nil) {
            return nil;
        }
        foreach (var segment; airway.segments) {
            if (segment.from.wpid == waypointID or
                segment.to.wpid == waypointID) {
                append(found, segment);
            }
        }
        return found;
    },

    searchPath: func(airwayID, fromID, toID) {
        logprint(2, sprintf("AirwaysDB.searchPath(%s, %s, %s)", airwayID, fromID, toID));

        var initialCandidates = me.findSegmentsFrom(airwayID, fromID);
        if (initialCandidates == nil) {
            logprint(2, sprintf("AirwaysDB.searchPath: no initial candidates found"));
            return nil;
        }
        logprint(2, sprintf("AirwaysDB.searchPath: initial candidates: %d", size(initialCandidates)));

        foreach (var initialCandidate; initialCandidates) {
            logprint(2, sprintf("AirwaysDB.searchPath; initial candidate: %s/%s", initialCandidate.from.wpid, initialCandidate.to.wpid));
            var seen = {};
            var route = [];
            var current = fromID;
            seen[fromID] = 1;
            if (initialCandidate.from.wpid == fromID) {
                route = [initialCandidate.from, initialCandidate.to];
                current = initialCandidate.to.wpid;
                seen[initialCandidate.to.wpid] = 1;
            }
            else {
                route = [initialCandidate.to, initialCandidate.from];
                current = initialCandidate.from.wpid;
                seen[initialCandidate.from.wpid] = 1;
            }
            while (current != toID) {
                var candidates = me.findSegmentsFrom(airwayID, current);
                if (candidates == nil or size(candidates) == 0) {
                    logprint(2, sprintf("AIRWAYS: No route from %s to %s via %s", fromID, toID, airwayID));
                    break;
                }
                var found = nil;
                foreach (var candidate; candidates) {
                    var other = nil;
                    if (candidate.from.wpid == current)
                        other = candidate.to;
                    else
                        other = candidate.from;
                    if (seen[other.wpid] == nil) {
                        found = other;
                        break;
                    }
                }
                if (found == nil) {
                    logprint(2, sprintf("AIRWAYS: Cannot continue from %s towards %s via %s", current, toID, airwayID));
                    break;
                }
                else {
                    seen[found.wpid] = 1;
                    append(route, found);
                    current = found.wpid;
                }
            }
            if (current == toID) {
                return route;
            }
        }
        return nil;
    },
};

var loadAirwaysData = func () {
    var sceneryPathNodes = props.globals.getNode('sim').getChildren('fg-scenery');
    var airwaysFile = nil;
    foreach (var node; sceneryPathNodes) {
        var filename = node.getValue() ~ '/NavData/awy/awy.dat';
        if (io.stat(filename) != nil) {
            airwaysFile = filename;
            break;
        }
    }
    print("AIRWAYS FILE FOUND: " ~ airwaysFile);
    var file = io.open(airwaysFile, 'r');
    var line = nil;
    var items = nil;

    # Parse header
    line = io.readln(file);
    if (line != 'I') {
        logprint(4, "AIRWAYS: Invalid awy.dat - expected 'I', but found '" ~ line ~ "'");
        return nil;
    }
    line = io.readln(file);
    items = wordsplit(line);
    if (size(items) < 1 or items[0] != '640') {
        logprint(4, "AIRWAYS: Invalid awy.dat - expected version 640, but found '" ~ line ~ "'");
        return nil;
    }
    line = io.readln(file);

    var airwaysDB = { parents: [AirwaysDB], airways: {} };

    var startTime = systime();
    var numSegments = 0;
    var numAirways = 0;

    # Now parse entries
    while (line = io.readln(file)) {
        items = wordsplit(line);
        if (size(items) == 10) {
            var fromWaypoint = {
                wpid: items[0],
                lat: num(items[1]),
                lon: num(items[2]),
            };
            var toWaypoint = {
                wpid: items[3],
                lat: num(items[4]),
                lon: num(items[5]),
            };
            var airways = split('-', items[9]);
            foreach (var airwayID; airways) {
                var airway = airwaysDB.airways[airwayID];
                if (airway == nil) {
                    airway = {
                        awid: airwayID,
                        segments: [],
                    };
                    numAirways += 1;
                    airwaysDB.airways[airwayID] = airway;
                }
                append(airway.segments, { from: fromWaypoint, to: toWaypoint });
                numSegments += 1;
            }
        }
    }
    io.close(file);

    var endTime = systime();

    printf("Airways loaded: %d segments of %d airways in %1.1f seconds",
        numSegments, numAirways, endTime - startTime);
    return airwaysDB;
};

var airwaysDB = nil;
setprop('/sim/airways/loaded', 0);

thread.newthread(func {
    airwaysDB = loadAirwaysData();
    setprop('/sim/airways/loaded', 1);

    var fromID = 'KEMAD';
    var toID = 'TIR';
    var airwayID = 'L602';
    var path = airwaysDB.searchPath(airwayID, fromID, toID);
    if (path == nil) path = [];
    var pathIDs = [];
    foreach (var wp; path) {
        append(pathIDs, wp.wpid);
    }

    printf("Airway routing %s %s %s: %s",
        fromID, airwayID, toID, string.join(' ', pathIDs));
});
