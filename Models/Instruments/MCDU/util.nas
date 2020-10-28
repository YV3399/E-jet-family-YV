# Various utility cruft for MCDU programming

var utf8NumBytes = func (c) {
    if ((c & 0x80) == 0x00) { return 1; }
    if ((c & 0xE0) == 0xC0) { return 2; }
    if ((c & 0xF0) == 0xE0) { return 3; }
    if ((c & 0xF8) == 0xF0) { return 4; }
    printf("UTF8 error (%d / %02x)", c, c);
    return 1;
};

var parseOctal = func (s) {
    var val = 0;
    for (var i = 0; i < size(s); i += 1) {
        val = val * 8;
        var c = s[i];
        if (c < 48 or c > 55) {
            return nil;
        }
        val += c - 48;
    }
    return val;
};

var vecfind = func (needle, haystack) {
    forindex (var i; haystack) {
        if (haystack[i] == needle) {
            return i;
        }
    }
    return -1;
};

var swapProps = func (prop1, prop2) {
    fgcommand("property-swap", {
        "property[0]": prop1,
        "property[1]": prop2
    });
};

var prepended = func (val, vec) {
    var result = [val];
    foreach (var v; vec) {
        append(result, v);
    }
    return result;
};


var formatRestrictions = func (wp, transitionAlt = 18000, pretty = 0) {
    var formattedAltRestr = pretty ? "-----" : "-";
    if (wp.alt_cstr != nil and wp.alt_cstr_type != nil and wp.alt_cstr_type != 'delete') {
        if (wp.alt_cstr > transitionAlt) {
            formattedAltRestr = sprintf("FL%03.0f", wp.alt_cstr / 100);
        }
        else {
            formattedAltRestr = sprintf(pretty ? "%5.0f" : "%1.0f", wp.alt_cstr);
        }
        if (wp.alt_cstr_type == "above") {
            formattedAltRestr ~= "A";
        }
        else if (wp.alt_cstr_type == "below") {
            formattedAltRestr ~= "B";
        }
    }
    var formattedSpeedRestr = pretty ? "---" : "-";
    if (wp.speed_cstr != nil and wp.speed_cstr_type != nil and wp.speed_cstr_type != 'delete') {
        if (wp.speed_cstr_type == "mach") {
            formattedSpeedRestr = sprintf("%0.2fM", wp.speed_cstr);
        }
        else {
            formattedSpeedRestr = sprintf(pretty ? "%3.0f" : "%1.0f", wp.speed_cstr);
        }
        if (wp.speed_cstr_type == "above") {
            formattedSpeedRestr ~= "A";
        }
        else if (wp.speed_cstr_type == "below") {
            formattedSpeedRestr ~= "B";
        }
    }
    return sprintf(pretty ? "%4s/%-4s" : "%s/%s", formattedSpeedRestr, formattedAltRestr);
};

var extractAboveBelow = func (str) {
    # debug.dump("extractAboveBelow", str);
    if (str == '') {
        return [str, nil];
    }
    if (num(str) != nil) {
        return [str, nil];
    }
    var last = substr(str, -1, 1);
    if (num(last) == nil) {
        var corePart = substr(str, 0, size(str) - 1);
        return [corePart, last];
    }
    else {
        return [str, nil];
    }
};

var parseAsAltitude = func (str) {
    var n = num(str);
    if (n == nil) {
        if (substr(str, 0, 2) == "FL") {
            n = substr(str, 2);
            if (n == nil) {
                return nil;
            }
            else {
                return n * 100;
            }
        }
        else {
            return nil;
        }
    }
    else {
        if (n >= 1000) {
            return n;
        }
        else {
            return nil;
        }
    }
};

var parseAsSpeed = func (str) {
    # debug.dump("parseAsSpeed", str);
    var n = num(str);
    if (n != nil and n < 1000) {
        return n;
    }
    else {
        return nil;
    }
};

var parseAsMach = func (str) {
    # debug.dump("parseAsMach", str);
    var n = num(str);
    if (n == nil) return nil;

    if (n < 1.0) {
        return n;
    }
    else if (n < 10.0) {
        return n / 10.0;
    }
    else if (n < 100.0) {
        return n / 100.0;
    }
};

var parseRestrictions = func (str) {
    var s = split("/", str);
    # debug.dump("Split restrictions", s);
    if (size(s) == 0) { return nil; }
    var speedPart = nil;
    var altPart = nil;
    if (size(s) == 1) {
        # extract above/below marker
        var parts = extractAboveBelow(s[0]);
        if (parts == nil) { return nil; }
        
        # if the indicator is "M", then we're dealing with an "at mach" rule.
        if (parts[1] == "M") {
            var mach = parseAsMach(parts[0]);
            if (mach == nil) { return nil; }
            return {
                speed: {
                    val: mach,
                    ty: 'mach',
                },
                alt: nil,
            }
        }
        else {
            var ty = 'at';
            if (parts[1] == "A") { ty = 'above'; }
            if (parts[1] == "B") { ty = 'below'; }
            var alt = parseAsAltitude(parts[0]);
            var speed = parseAsSpeed(parts[0]);
            if (alt != nil) {
                return {
                    speed: nil,
                    alt: {
                        val: alt,
                        ty: ty,
                    },
                };
            }
            else {
                return {
                    speed: {
                        val: speed,
                        ty: ty,
                    },
                    alt: nil,
                }
            }
        }
    } # size = 1
    else {
        var speedPart = s[0];
        var altPart = s[1];
        var result = { speed: nil, alt: nil };

        var speedParts = extractAboveBelow(speedPart);
        if (speedParts[1] == "M") {
            var mach = parseAsMach(speedParts[0]);
            if (mach != nil) {
                result.speed = { val: mach, ty: 'mach' };
            }
        }
        else {
            var speed = nil;
            if (substr(speedPart, 0, 1) == "-") {
                result.speed = { val: nil, ty: '' };
            }
            else {
                speed = parseAsSpeed(speedParts[0]);
                if (speed != nil) {
                    result.speed = { val: speed, ty: 'at' };
                    if (speedParts[1] == "A") { result.speed.ty = 'above'; }
                    if (speedParts[1] == "B") { result.speed.ty = 'below'; }
                }
            }
        }

        var altParts = extractAboveBelow(altPart);
        var alt = nil;
        if (substr(altPart, 0, 1) == "-") {
            result.alt = { val: nil, ty: '' };
        }
        else {
            alt = parseAsAltitude(altParts[0]);
            if (alt != nil) {
                result.alt = { val: alt, ty: 'at' };
                if (altParts[1] == "A") { result.alt.ty = 'above'; }
                if (altParts[1] == "B") { result.alt.ty = 'below'; }
            }
        }

        return result;
    }
};

var celsiusToFahrenheit = func (c) {
    return 32.0 + c * 1.8;
};

var findWaypointsByID = func (ident) {
    if (size(ident) < 2) {
        # single letter = nonsensical
        return [];
    }
    else if (size(ident) <= 3) {
        # 2 = NDB
        # 3 = VOR/DME
        return findNavaidsByID(ident);
    }
    else if (size(ident) == 4) {
        # 4 = airport
        return findAirportsByICAO(ident);
    }
    else if (size(ident) == 5) {
        # 5 = a fix
        return findFixesByID(ident);
    }
};
