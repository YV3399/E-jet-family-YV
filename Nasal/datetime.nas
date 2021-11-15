var div = func (a, b) {
    var q = a / b;
    if (q < 0)
        return math.ceil(q);
    else
        return math.floor(q);
}

var isLeapYear = func (year) {
    if (math.fmod(year, 4) != 0) return 0;
    if (math.fmod(year, 100) != 0) return 1;
    if (math.fmod(year, 400) != 0) return 0;
    return 1;
};

var MONTH_NAMES_3 = [
    'DEC',
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

var monthName3 = func (month) {
    if (month == nil) return '---';
    var i = math.mod(num(month), 12);
    return MONTH_NAMES_3[i];
};

var Date = {
    new: func (year, month, day) {
        return {
            parents: [Date],
            year: year,
            month: month,
            day: day,
            _julian: nil,
        }
    },

    toJulianDay: func () {
        if (me._julian == nil) {
            me._julian =
                div((1461 * (me.year + 4800 + div((me.month - 14), 12))), 4) +
                    div((367 * (me.month - 2 - 12 * div((me.month - 14), 12))), 12) -
                    div((3 * div((me.year + 4900 + div((me.month - 14), 12)), 100)), 4) +
                    me.day - 32075;
        }
        return me._julian;
    },

    fromJulianDay: func (jd) {
        var y = 4716;
        var j = 1401;
        var m = 2;
        var n = 12;
        var r = 4;
        var p = 1461;
        var v = 3;
        var u = 5;
        var s = 153;
        var w = 2;
        var B = 274277;
        var C = -38;

        var f = jd + j + div(( div((4 * jd + B), 146097) * 3), 4) + C;
        var e = r * f + v;
        var g = div(math.fmod(e, p), r);
        var h = u * g + w;

        var D = div(math.fmod(h, s), u) + 1;
        var M = math.fmod(div(h, s) + m, n) + 1;
        var Y = div(e, p) - y + div((n + m - M), n);
        var d = Date.new(Y, M, D);
        d._julian = jd;
        return d;
    },

    addDays: func (d) {
        return Date.fromJulianDay(me.toJulianDay() + d);
    },
};

var runTests = func () {
    var num_tests = 0;
    var num_succeeded = 0;
    var num_failed = 0;

    for (var i = 0; i < 1000; i += 1) {
        var jd = math.floor(rand() * 2400000) + 1200000;
        var d = Date.fromJulianDay(jd);
        var expected = jd;
        var actual = d.toJulianDay();
        if (expected != actual) {
            printf("FAIL: Julian Day round-trip failed for JD = %i. Date: %i-%i-%i, expected: %i, actual: %i",
                jd, d.year, d.month, d.day, expected, actual);
            num_failed += 1;
        }
        else {
            num_succeeded += 1;
        }
        num_tests += 1;
    }
    printf("Julian Day round-trip: ran %i tests, %i succeeded, %i failed",
        num_tests, num_succeeded, num_failed);
};
