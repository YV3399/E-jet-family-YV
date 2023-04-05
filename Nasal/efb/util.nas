var urlencode = func (raw) {
    return string.replace(raw, ' ', '%20');
};

var font_mapper = func(family, weight='normal') {
    if (family == 'mono') {
        return "LiberationFonts/LiberationMono-Regular.ttf";
    }
    elsif (family == 'script') {
        return "SteveHand/SteveHand.ttf";
    }
    else {
        if (weight == 'normal') {
            return "LiberationFonts/LiberationSans-Regular.ttf";
        }
        else {
            return "LiberationFonts/LiberationSans-Bold.ttf";
        }
    }
};

var lineSplitStr = func (str, maxLineLen) {
    if (str == "") return [];
    var words = split(" ", str);
    var lines = [];
    var lineAccum = [];
    var lineLen = 0;
    foreach (var word; words) {
        while ((lineLen == 0) and (utf8.size(word) > maxLineLen)) {
            var w0 = utf8.substr(word, 0, maxLineLen - 1) ~ '…';
            word = '…' ~ utf8.substr(word, maxLineLen - 1);
            append(lines, w0);
            lineLen = 0;
        }
        var wlen = utf8.size(word);
        if (lineLen == 0) {
            newLineLen = wlen;
        }
        else {
            newLineLen = lineLen + wlen + 1;
        }
        if ((lineLen > 0) and (newLineLen > maxLineLen)) {
            append(lines, string.join(" ", lineAccum));
            lineAccum = [word];
            lineLen = wlen;
        }
        else {
            append(lineAccum, word);
            lineLen = newLineLen;
        }
    }
    append(lines, string.join(" ", lineAccum));
    return lines;
};

# It's almost too horrible to admit, but for some reason, Nasal does not give
# us anything to convert between UNIX timestamps and gregorian calendar dates.
var unixToDateTime = func (s) {
    var z = math.floor(s / 86400) + 719468;
    var era = math.floor((z >= 0 ? z : z - 146096) / 146097);
    var doe = z - era * 146097;
    var yoe = math.floor((doe - math.floor(doe/1460) + math.floor(doe/36524) - math.floor(doe/146096)) / 365);
    var y = yoe + era * 400;
    var doy = doe - (365*yoe + math.floor(yoe/4) - math.floor(yoe/100));
    var mp = math.floor((5*doy + 2)/153);
    var d = doy - math.floor((153*mp+2)/5) + 1;
    var m = mp + (mp < 10 ? 3 : -9);
    y += (m <= 2);
    var sod = math.mod(s, 86400);
    var ss = math.mod(sod, 60);
    var mm = math.mod(math.floor(sod / 60), 60);
    var hh = math.floor(sod / 3600);
    return {
        year: y,
        month: m,
        day: d,
        hour: hh,
        minute: mm,
        second: ss
    };
};

var monthNames3 = [ 'XXX', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC' ];

var formatPM = func(numDigits, numFrac=0, spacing=0, showP=1) {
    var formatStr = (numFrac == 0)
                        ? ('%0' ~ numDigits ~ 'i')
                        : ('%0' ~ (numDigits + numFrac + 1) ~ '.' ~ numFrac ~ 'f');
    return func(val) {
        if (val == nil) return '';
        var prefix = (val < 0) ? 'M' : (showP ? 'P' : ' ');
        var digits = sprintf(formatStr, math.abs(val));
        return prefix ~ substr('                          ', 0, spacing) ~ digits;
    }
};

var formatSeconds0202PM = func (spacing=0) {
    return func (secondsRaw) {
        if (secondsRaw == nil) return '';
        var prefix = (secondsRaw < 0) ? 'M' : 'P';
        var digits = formatSeconds0202(math.abs(secondsRaw));
        return prefix ~ substr('                          ', 0, spacing) ~ digits;
    }
};

var formatSeconds0202 = func (secondsRaw) {
    if (secondsRaw == nil or secondsRaw == '') return '';
    return formatTime0202(secondsRaw / 60);
};

var formatTime0202 = func (minutesRaw) {
    if (minutesRaw == nil) return '';
    var minutes = math.mod(minutesRaw, 60);
    var hours = math.floor(minutesRaw / 60);
    return sprintf('%02i%02i', hours, minutes);
};

var fuelToSeconds = func (fuelFlow, fuel) {
    if (fuelFlow == nil or fuel == nil) return 0;
    return math.floor(fuel * 3600 / fuelFlow);
};

var fuelToMinutes = func (fuelFlow, fuel) {
    if (fuelFlow == nil or fuel == nil) return 0;
    return math.floor(fuel * 60 / fuelFlow);
};

var formatFuelTime0202 = func (fuelFlow, fuel) {
    if (fuelFlow == nil or fuel == nil) return '';
    var minutesRaw = fuelToMinutes(fuelFlow, fuel);
    return formatTime0202(minutesRaw);
};

var formatGeoCoordLog = func (coord, dim) {
    if (coord == nil) return '';
    var markers = [ '+', '-' ];
    var format = '%s%03i%04.1f';
    if (dim == 'lat') {
        markers = ['S', 'N'];
        format = ' %s%02i%04.1f';
    }
    elsif (dim == 'lon') {
        markers = ['W', 'E'];
        format = '%s%03i%04.1f';
    }
    var sign = (coord < 0) ? markers[0] : markers[1];
    var degreesRaw = math.abs(coord);
    var degrees = math.floor(degreesRaw);
    var minutes = math.fmod(degreesRaw * 60, 60);
    return sprintf(format, sign, degrees, minutes);
};

var formatGeoCoord = func (coord, dim) {
    if (coord == nil) return '';
    var markers = [ '+', '-' ];
    var format1 = '%i';
    if (dim == 'lat') {
        markers = ['S', 'N'];
        format1 = '%02i';
    }
    elsif (dim == 'lon') {
        markers = ['E', 'W'];
        format1 = '%03i';
    }
    var sign = (coord < 0) ? markers[0] : markers[1];
    var degreesRaw = math.abs(coord);
    var degrees = math.floor(degreesRaw);
    var minutes = math.fmod(degreesRaw * 60, 60);
    var seconds = math.fmod(degreesRaw * 3600, 60);
    var format = format1 ~ '°%02i\'%05.2f"%s';
    return sprintf(format, degrees, minutes, seconds, sign);
};

var formatLatLon = func (lat, lon) {
    return formatGeoCoord(lat, 'lat') ~ ' ' ~ formatGeoCoord(lon, 'lon');
};
