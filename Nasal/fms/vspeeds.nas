# V-Speed calculations

var lstrip = func (str) {
    while (size(str) > 0 and str[0] <= 32) {
        str = substr(str, 1);
    }
    return str;
};

var rstrip = func (str) {
    while (size(str) > 0 and str[size(str) - 1] <= 32) {
        str = substr(str, 0, size(str) - 1);
    }
    return str;
};

var strip = func (str) {
    return rstrip(lstrip(str));
};

var stripComment = func (str) {
    var pos = find("#", str);
    if (pos >= 0) {
        return substr(str, 0, pos);
    }
    else {
        return str;
    }
};

var num_compare = func (a, b) {
    return a - b;
};

var loadTable1D = func (tablekey) {
    var path = resolvepath("Aircraft/E-jet-family/Data/" ~ tablekey ~ ".table");
    if (path == nil or path == '') { return nil; }
    var file = io.open(path, "r");
    var result = {};
    while (1) {
        var ln = io.readln(file);
        if (ln == nil) { break; }
        ln = strip(stripComment(ln));
        if (ln == "") {
            continue;
        }
        var row = split(" ", ln);
        if (size(row) >= 2) {
            result[num(row[0])] = num(row[1]);
        }
    }
    return result;
    io.close(file);
};

var loadTable2D = func (tablekey) {
    var path = resolvepath("Aircraft/E-jet-family/Data/" ~ tablekey ~ ".table");
    if (path == nil or path == '') { return nil; }
    var file = io.open(path, "r");
    var result = {};
    while (1) {
        var ln = io.readln(file);
        if (ln == nil) { break; }
        ln = strip(stripComment(ln));
        if (ln == "") {
            continue;
        }
        var row = split(" ", ln);
        if (size(row) >= 2) {
            var rowIndex = num(row[0]);
            result[rowIndex] = [];
            for (var i = 1; i < size(row); i += 1) {
                append(result[rowIndex], num(row[i]));
            }
        }
    }
    return result;
    io.close(file);
};

var loadTable2DH = func (tablekey) {
    var path = resolvepath("Aircraft/E-jet-family/Data/" ~ tablekey ~ ".table");
    if (path == nil or path == '') { return nil; }
    var file = io.open(path, "r");
    var result = {};
    var columnHeaders = nil;
    while (1) {
        var ln = io.readln(file);
        if (ln == nil) { break; }
        ln = strip(stripComment(ln));
        if (ln == "") {
            continue;
        }
        if (columnHeaders == nil) {
            columnHeaders = [];
            foreach (var k; split(" ", ln)) {
                append(columnHeaders, num(k));
            }
        }
        else {
            var row = split(" ", ln);
            var rowKey = num(row[0]);
            result[rowKey] = {};
            forindex (var i; columnHeaders) {
                result[rowKey][columnHeaders[i]] = num(row[i+1]);
            }
        }
    }
    return result;
    io.close(file);
};

var loadTable3DH = func (tablekey) {
    var path = resolvepath("Aircraft/E-jet-family/Data/" ~ tablekey ~ ".table");
    if (path == nil or path == '') { return nil; }
    var file = io.open(path, "r");
    var result = {};
    var key = 0;
    var columnHeaders = nil;
    while (1) {
        var ln = io.readln(file);
        if (ln == nil) { break; }
        ln = strip(stripComment(ln));
        if (ln == "") {
            continue;
        }
        var s = split(':', ln);
        if (size(s) > 1) {
            key = num(strip(s[1]));
            columnHeaders = nil;
            result[key] = {};
        }
        else if (columnHeaders == nil) {
            columnHeaders = [];
            foreach (var k; split(" ", ln)) {
                append(columnHeaders, num(k));
            }
        }
        else {
            var row = split(" ", ln);
            var rowKey = num(row[0]);
            result[key][rowKey] = {};
            forindex (var i; columnHeaders) {
                result[key][rowKey][columnHeaders[i]] = num(row[i+1]);
            }
        }
    }
    return result;
    io.close(file);
};

var nearestKey = func (table, val) {
    var foundKey = nil;
    if (typeof(table) == 'vector') {
        forindex (var key; table) {
            if (key >= val) {
                return key;
            }
            foundKey = key;
        }
    }
    else {
        var keys = sort(keys(table), num_compare);
        foreach (var key; keys) {
            if (key >= val) {
                return key;
            }
            foundKey = key;
        }
    }
    return foundKey;
};

var nearestKeyIndex = func (table, val) {
    forindex (var i; table) {
        if (table[i] >= val) {
            return i;
        }
    }
    return nil;
};

var lookupTable = func (table, path) {
    var current = table;
    while (size(path) > 0) {
        if (current == nil) { return nil; }
        var f = path[0] ~ '';
        if (typeof(f) == 'scalar' and size(f) > 0 and substr(f, 0, 1) == "~") {
            return nearestKeyIndex(current, num(substr(f, 1)));
        }
        else if (typeof(f) == 'scalar' and size(f) > 0 and substr(f, 0, 1) == "@") {
            var k = num(substr(f, 1));
            current = current[k];
        }
        else {
            var k = nearestKey(current, f);
            current = current[k];
        }
        path = subvec(path, 1);
    }
    return current;
};

var modelKeys = {
    'E170': 'E170',
    'E175': 'E170',
    'E190': 'E190',
    'E195': 'E190',
    'Lineage1000': 'E190',
};

var getModel = func () {
    var aero = getprop('sim/aero');
    return modelKeys[aero];
};

var calcMinV = func (which) {
    var model = getModel();
    if (model == nil) { return nil; }
    var toMode = getprop('/controls/flight/trs/to');
    if (toMode == nil) { toMode = 1; }
    toMode = math.min(2, math.max(1, toMode));
    var altitude = getprop('/fms/takeoff-conditions/pressure-alt');
    var oat = getprop('/fms/takeoff-conditions/oat');
    var tow = getprop('/fms/fuel/tow') or 0;
    if (tow < 1000) {
        tow = (getprop('/fdm/jsbsim/inertia/weight-lbs') or 60000) * LB2KG;
    }

    printf("--- Minimum %s calculation ---", which);
    printf("Aircraft:   %5s", model);
    printf("Thrust:      TO-%i", toMode);
    printf("OAT:        %5.0f°C", oat);
    printf("Press. alt: %5.0fft", altitude);
    printf("TOW:        %5.0fkg", tow);

    var tablekey = sprintf("%s/min%s_TO-%i", model, which, toMode);
    var table = loadTable3DH(tablekey);
    return lookupTable(table, [ altitude, oat, tow ]);
};

var calcV = func (which) {
    var model = getModel();
    if (model == nil) { return nil; }
    var toMode = getprop('/controls/flight/trs/to');
    if (toMode == nil) { toMode = 1; }
    toMode = math.min(2, math.max(1, toMode));
    var altitude = getprop('/fms/takeoff-conditions/pressure-alt');
    var oat = getprop('/fms/takeoff-conditions/oat');
    var tow = getprop('/fms/fuel/tow') or 0;
    if (tow < 1000) {
        tow = (getprop('/fdm/jsbsim/inertia/weight-lbs') or 60000) * LB2KG;
    }
    var flaps = math.min(4, math.max(1, math.round((getprop('/fms/takeoff-conditions/flaps') or 0.25) * 8)));

    printf("--- %s calculation ---", which);
    printf("Aircraft:   %5s", model);
    printf("Thrust:      TO-%i", toMode);
    printf("OAT:        %5.0f°C", oat);
    printf("Press. alt: %5.0fft", altitude);
    printf("TOW:        %5.0fkg", tow);
    printf("FLAPS:      FLAPS %i", flaps);

    var tablekey = '';
    var table = nil;

    tablekey = sprintf("%s/min%s_TO-%i", model, which, toMode);
    table = loadTable3DH(tablekey);
    var minV = lookupTable(table, [ altitude, oat, tow ]) or 0;

    tablekey = sprintf("%s/V1VRV2-column_TO-%i_FLAPS-%i", model, toMode, flaps);
    table = loadTable2D(tablekey);
    if (table == nil) {
        return minV;
    }
    var columnOffsets = { 'V1': 0, 'VR': 1, 'V2': 2 };
    var column = lookupTable(table, [ altitude, "~" ~ oat ]);
    if (column == nil or columnOffsets[which] == nil) {
        return minV;
    }
    column = column * 3 + columnOffsets[which];

    tablekey = sprintf("%s/V1VRV2_TO-%i_FLAPS-%i", model, toMode, flaps);
    table = loadTable2D(tablekey);
    var v = lookupTable(table, [ tow, "@" ~ column ]);

    if (v == nil or minV == nil) return nil;
    return math.max(minV, v);
};

var calcVFS = func (weight = nil) {
    var model = getModel();
    if (model == nil) { return nil; }
    if (weight == nil) {
        weight = (getprop('/fdm/jsbsim/inertia/weight-lbs') or 60000) * LB2KG;
    }
    var tablekey = sprintf("%s/VFS", model);
    var table = loadTable1D(tablekey);
    return lookupTable(table, [ weight ]);
};

var calcVAC = func (weight = nil) {
    var model = getModel();
    if (model == nil) { return nil; }
    if (weight == nil) {
        weight = (getprop('/fdm/jsbsim/inertia/weight-lbs') or 60000) * LB2KG;
    }
    var tablekey = sprintf("%s/VAC", model);
    var table = loadTable2DH(tablekey);
    var flapSetting = math.round(getprop('/fms/landing-conditions/approach-flaps') * 8);
    return lookupTable(table, [ weight, flapSetting ]);
};

var calcVref = func (weight = nil) {
    var model = getModel();
    if (model == nil) { return nil; }
    if (weight == nil) {
        weight = (getprop('/fdm/jsbsim/inertia/weight-lbs') or 60000) * LB2KG;
    }
    var icing = getprop('/fms/landing-conditions/ice-accretion');
    var tablekey = sprintf("%s/Vref-%s", model, icing ? 'ice' : 'noice');
    var table = loadTable2DH(tablekey);
    var flapSetting = math.round(getprop('/fms/landing-conditions/landing-flaps') * 8);
    return lookupTable(table, [ weight, flapSetting ]);
};

var update_departure_vspeeds = func () {
    var v1 = calcV('V1');
    var vr = calcV('VR');
    var v2 = calcV('V2');
    var vfs = calcVFS();
    printf("V1: %3.0f", (v1 == nil) ? "9999" : v1);
    printf("VR: %3.0f", (vr == nil) ? "9999" : vr);
    printf("V2: %3.0f", (v2 == nil) ? "9999" : v2);
    printf("VFS: %3.0f", (vfs == nil) ? "9999" : vfs);
    if (v1 != nil and v1 > 0) { setprop('/fms/vspeeds-calculated/departure/v1', v1); }
    if (vr != nil and vr > 0) { setprop('/fms/vspeeds-calculated/departure/vr', vr); }
    if (v2 != nil and v2 > 0) { setprop('/fms/vspeeds-calculated/departure/v2', v2); }
    if (vfs != nil and vfs > 0) { setprop('/fms/vspeeds-calculated/departure/vfs', vfs); }
};

var update_approach_vspeeds = func () {
    var vac = calcVAC();
    var vref = calcVref();
    var vfs = calcVFS();
    var vappr = (vref == nil) ? nil : (vref + 10);
    if (vac != nil and vac > 0) { setprop('/fms/vspeeds-calculated/approach/vac', vac); }
    if (vref != nil and vref > 0) { setprop('/fms/vspeeds-calculated/approach/vref', vref); }
    if (vappr != nil and vappr > 0) { setprop('/fms/vspeeds-calculated/approach/vappr', vappr); }
    if (vfs != nil and vfs > 0) { setprop('/fms/vspeeds-calculated/approach/vfs', vfs); }
};

setlistener('/fms/takeoff-conditions', func () { update_departure_vspeeds(); }, 1, 2);
setlistener('/controls/flight/trs/to', func () { update_departure_vspeeds(); }, 1, 0);
setlistener('/fms/landing-conditions', func () { update_approach_vspeeds(); }, 1, 2);
