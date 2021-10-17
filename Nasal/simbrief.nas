globals.getFlightplan = func (index) {
    logprint(3, sprintf("E-Jet getFlightplan(%d)", index));
    if (index == 0) {
        return flightplan();
    }
    elsif (index == 1) {
        return fms.getModifyableFlightplan();
    }
};

globals.commitFlightplan = func () {
    fms.commitFlightplan();
};
