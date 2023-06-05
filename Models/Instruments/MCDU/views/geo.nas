var GeoView = {
    new: func (x, y, flags, model, latlon) {
        var m = ModelView.new(x, y, flags, model);
        m.parents = prepended(GeoView, m.parents);
        m.axis = latlon;
        if (latlon == "LAT") {
            m.w = 8;
        }
        else {
            m.w = 9;
        }
        return m;
    },

    draw: func (mcdu, val) {
        mcdu.print(me.x, me.y, formatGeo(val, me.axis), me.flags);
    },
};
