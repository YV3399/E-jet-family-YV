var urlencode = func (raw) {
    return string.replace(raw, ' ', '%20');
};

var font_mapper = func(family, weight) {
    return "LiberationFonts/LiberationSans-Regular.ttf";
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
}
