var airwaysDB = nil;

setprop('/fms/airac/valid-from/year', 2000);
setprop('/fms/airac/valid-from/month', 1);
setprop('/fms/airac/valid-from/day', 1);
setprop('/fms/airac/valid-from/date', 'n/a');
setprop('/fms/airac/valid-until/year', 2000);
setprop('/fms/airac/valid-until/month', 1);
setprop('/fms/airac/valid-until/day', 1);
setprop('/fms/airac/valid-until/date', 'n/a');
setprop('/fms/airac/valid', 0);

var airacCycles = {};

(func {
    var date = datetime.Date.new(2012, 1, 12);
    var cycle = 1;
    # 2050 should be enough for anyone
    while (date.year < 2050) {
        cycleID = sprintf("%02i%02i", math.mod(date.year, 100), cycle);
        var endDate = date.addDays(27);
        airacCycles[cycleID] = { from: date, until: endDate };
        var nextDate = date.addDays(28);
        if (nextDate.year == date.year)
            cycle = cycle + 1;
        else
            cycle = 1;
        date = nextDate;
    }
})();

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
            if (segment.from.id == waypointID or
                segment.to.id == waypointID) {
                append(found, segment);
            }
        }
        return found;
    },

    findSegmentsFromTo: func(airwayID, fromID, toID) {
        logprint(2, sprintf("AirwaysDB.findSegmentsFromTo(%s, %s, %s)", airwayID, fromID, toID));

        var initialCandidates = me.findSegmentsFrom(airwayID, fromID);
        if (initialCandidates == nil) {
            logprint(2, sprintf("AirwaysDB.findSegmentsFromTo: no initial candidates found"));
            return nil;
        }
        logprint(2, sprintf("AirwaysDB.findSegmentsFromTo: initial candidates: %d", size(initialCandidates)));

        foreach (var initialCandidate; initialCandidates) {
            logprint(2, sprintf("AirwaysDB.findSegmentsFromTo; initial candidate: %s/%s", initialCandidate.from.id, initialCandidate.to.id));
            var seen = {};
            var route = [];
            var current = fromID;
            seen[fromID] = 1;
            if (initialCandidate.from.id == fromID) {
                route = [initialCandidate.from, initialCandidate.to];
                current = initialCandidate.to.id;
                seen[initialCandidate.to.id] = 1;
            }
            else {
                route = [initialCandidate.to, initialCandidate.from];
                current = initialCandidate.from.id;
                seen[initialCandidate.from.id] = 1;
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
                    if (candidate.from.id == current)
                        other = candidate.to;
                    else
                        other = candidate.from;
                    if (seen[other.id] == nil) {
                        found = other;
                        break;
                    }
                }
                if (found == nil) {
                    logprint(2, sprintf("AIRWAYS: Cannot continue from %s towards %s via %s", current, toID, airwayID));
                    break;
                }
                else {
                    seen[found.id] = 1;
                    append(route, found);
                    current = found.id;
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
        printf("AIRWAYS: Trying " ~ filename);
        if (io.stat(filename) != nil) {
            airwaysFile = filename;
            break;
        }
    }
    if (airwaysFile != nil) {
        print("AIRWAYS FILE FOUND: " ~ airwaysFile);

        var airwaysDB = { parents: [AirwaysDB], airways: {}, cycleID: '0001', airwaysFilename: airwaysFile, sourceInfoStr: 'INVALID' };

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
        if (size(items) < 1 or items[0] != '640' or items[1] != 'Version' or items [2] != '-') {
            logprint(4, "AIRWAYS: Invalid awy.dat - expected version 640, but found '" ~ line ~ "'");
            return nil;
        }

        # Attempt to extract AIRAC
        if (size(items) >= 6 and
            items[3] == 'AIRAC' and
            items[4] == 'Cycle') {
            airwaysDB.cycleID = items[5];
        }
        elsif (size(items) >= 6 and
               items[3] == 'data' and
               items[4] == 'cycle') {
            var s = split('.', items[5]);
            var y = num(s[0]);
            var c = num(s[1]);
            airwaysDB.cycleID = sprintf("%02i%02i", math.max(y, 0), math.max(c, 1));
        }
        else {
            # FG ships with AIRAC cycle 1310
            airwaysDB.cycleID = '1310';
        }

        # Attempt to extract copyright / data source info
        items = split(',', line);
        var infoItems = wordsplit(string.trim(items[2]));

        if (size(infoItems) > 3 and infoItems[3] == 'Navigraph') {
            airwaysDB.sourceInfoStr = 'NAVIGRAPH';
        }
        elsif (size(infoItems) > 1 and infoItems[0] == 'metadata') {
            airwaysDB.sourceInfoStr = substr(string.uc(infoItems[1]), 0, 12);
        }
        else {
            airwaysDB.sourceInfoStr = 'FG-' ~ getprop('/sim/version/flightgear');
        }

        line = io.readln(file);

        var startTime = systime();
        var numSegments = 0;
        var numAirways = 0;

        # Now parse entries
        while (line = io.readln(file)) {
            items = wordsplit(line);
            if (size(items) == 10) {
                var fromWaypoint = {
                    id: items[0],
                    lat: num(items[1]),
                    lon: num(items[2]),
                };
                var toWaypoint = {
                    id: items[3],
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
    }
    else {
        print("NO AIRWAYS FILE FOUND");
        return nil;
    }
};

setprop('/fms/airways/loaded', 0);

thread.newthread(func {
    airwaysDB = loadAirwaysData();
    var cycle = airacCycles['1310'];

    if (airwaysDB == nil) {
        cycle = airacCycles['1310'];
        setprop('/fms/airac/cycle', '1310');
        setprop('/fms/airac/source/str', 'FG-MINIMAL');
        setprop('/fms/airac/source/filename', '');
    }
    else {
        cycle = airacCycles[airwaysDB.cycleID];
        setprop('/fms/airac/cycle', airwaysDB.cycleID);
        setprop('/fms/airac/source/str', airwaysDB.sourceInfoStr);
        setprop('/fms/airac/source/filename', airwaysDB.airwaysFilename);
    }

    if (cycle != nil) {
        setprop('/fms/airac/valid-from/year', cycle.from.year);
        setprop('/fms/airac/valid-from/month', cycle.from.month);
        setprop('/fms/airac/valid-from/day', cycle.from.day);
        setprop('/fms/airac/valid-from/date',
            sprintf('%02i/%s/%02i',
                cycle.from.day,
                datetime.monthName3(cycle.from.month),
                math.mod(cycle.from.year, 100)));

        setprop('/fms/airac/valid-until/year', cycle.until.year);
        setprop('/fms/airac/valid-until/month', cycle.until.month);
        setprop('/fms/airac/valid-until/day', cycle.until.day);
        setprop('/fms/airac/valid-until/date',
            sprintf('%02i/%s/%02i',
                cycle.until.day,
                datetime.monthName3(cycle.until.month),
                math.mod(cycle.until.year, 100)));

        var currentDate =
                datetime.Date.new(
                    getprop('/sim/time/utc/year'),
                    getprop('/sim/time/utc/month'),
                    getprop('/sim/time/utc/day'));

        setprop('/fms/airac/valid',
            currentDate.toJulianDay() >= cycle.from.toJulianDay() and
            currentDate.toJulianDay() <= cycle.until.toJulianDay());
    }
    else {
        setprop('/fms/airac/valid-from/year', 2000);
        setprop('/fms/airac/valid-from/month', 1);
        setprop('/fms/airac/valid-from/day', 1);
        setprop('/fms/airac/valid-from/date', 'n/a');
        setprop('/fms/airac/valid-until/year', 2000);
        setprop('/fms/airac/valid-until/month', 1);
        setprop('/fms/airac/valid-until/day', 1);
        setprop('/fms/airac/valid-until/date', 'n/a');
        setprop('/fms/airac/valid', 0);
    }

    setprop('/fms/airways/loaded', airwaysDB != nil);
});
