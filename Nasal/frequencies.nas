var nearestComChannel = func (f, mode) {
    if (mode == "25") {
        khz = math.round(f / 0.025) * 25;
    }
    else {
        var khz = math.round(f / 0.005) * 5;
        var khzRem = math.mod(khz, 25);
        if (mode == "8.33") {
            if (khzRem == 0) khz += 5; # 0.000 -> 0.005
            if (khzRem == 20) khz -= 5; # 0.020 -> 0.015
        }
        else {
            if (khzRem == 20) khz += 5; # 0.020 -> 0.025
        }
    }
    return khz / 1000.0;
};

var nextComChannel = func (f, mode) {
    var khz = math.round(f / 0.005) * 5;
    var khzRem = math.mod(khz, 25);
    var khzR = khz - khzRem;
    if (mode == "25") {
        return (khzR + 25) / 1000.0;
    }
    elsif (mode == "8.33") {
        if (khzRem < 2.5) {
            return (khzR + 5) / 1000.0;
        }
        elsif (khzRem < 7.5) {
            return (khzR + 10) / 1000.0;
        }
        elsif (khzRem < 12.5) {
            return (khzR + 15) / 1000.0;
        }
        else {
            return (khzR + 30) / 1000.0;
        }
    }
    else {
        if (khzRem == 15)
            return f + 0.010;
        else
            return f + 0.005;
    }
};

var prevComChannel = func (f, mode) {
    var khz = math.round(f / 0.005) * 5;
    var khzRem = math.mod(khz, 25);
    var khzR = khz - khzRem;
    if (mode == "25") {
        return (khzR - 25) / 1000.0;
    }
    elsif (mode == "8.33") {
        if (khzRem > 17.5) {
            return (khzR + 15) / 1000.0;
        }
        elsif (khzRem > 12.5) {
            return (khzR + 10) / 1000.0;
        }
        elsif (khzRem > 7.5) {
            return (khzR + 5) / 1000.0;
        }
        else {
            return (khzR - 10) / 1000.0;
        }
    }
    else {
        if (khzRem == 0)
            return f - 0.010;
        else
            return f - 0.005;
    }
};
