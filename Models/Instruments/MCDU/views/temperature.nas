var TemperatureView = {
    new: func (x, y, flags, model) {
        var m = ModelView.new(x, y, flags, model);
        m.parents = prepended(TemperatureView, m.parents);
        m.w = 12;
        return m;
    },

    draw: func (mcdu, valC) {
        if (valC == nil) {
            mcdu.print(me.x, me.y, "---°C/---°F", me.flags);
        }
        else {
            var valF = celsiusToFahrenheit(valC);
            var fmt = "%+2.0f°C/%+2.0f°F";
            mcdu.print(me.x, me.y, sprintf(fmt, valC, valF), me.flags);
        }
    },
};
