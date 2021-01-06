# Projection-related helper functions for the MFD maps

var Camera = {
    new: func(options) {
        var m = {
            parents: [Camera],

            camGeo: options['camGeo'] or geo.aircraft_position(),
            camHdg: options['camHdg'] or 0,
            range: options['range'] or 10.0,
            screenRange: options['screenRange'] or 256.0,
            screenCX: options['screenCX'] or options['screenRange'] or 256.0,
            screenCY: options['screenCY'] or options['screenRange'] or 256.0,
            projectNorthX: 0,
            projectNorthY: 0,
            projectNorthFactor: 1,
            projectEastX: 0,
            projectEastY: 0,
            projectEastFactor: 1,
            projectCenterX: 0,
            projectCenterY: 0,
        };
        m.updateProjection();
        return m;
    },

    setRange: func(range) {
        me.range = range;
        me.updateProjection();
    },

    updateProjection: func() {
        var northGeo = geo.Coord.new();
        northGeo.set(me.camGeo);
        northGeo.apply_course_distance(0, me.range * NM2M);
        me.projectNorthFactor = northGeo.lat() - me.camGeo.lat();

        var eastGeo = geo.Coord.new();
        eastGeo.set(me.camGeo);
        eastGeo.apply_course_distance(90, me.range * NM2M);
        me.projectEastFactor = eastGeo.lon() - me.camGeo.lon();

        (me.projectNorthX, me.projectNorthY) = me.projectGeo(northGeo);
        (me.projectEastX, me.projectEastY) = me.projectGeo(eastGeo);
        (me.projectCenterX, me.projectCenterY) = me.projectGeo(me.camGeo);
    },

    reposition: func(geo, hdg) {
        me.camGeo = geo;
        me.camHdg = hdg;
        me.updateProjection();
    },

    project: func(targetGeo) {
        var deltaLat = (targetGeo.lat() - me.camGeo.lat()) / me.projectNorthFactor;
        var deltaLon = (targetGeo.lon() - me.camGeo.lon()) / me.projectEastFactor;
        var x = me.screenCX +
                    ((me.projectNorthX - me.projectCenterX) * deltaLat +
                     (me.projectEastX - me.projectCenterX) * deltaLon);
        var y = me.screenCY +
                    ((me.projectNorthY - me.projectCenterY) * deltaLat +
                     (me.projectEastY - me.projectCenterY) * deltaLon);
        return [x, y];
    },

    projectLatLon: func(latlon) {
        var coords = geo.Coord.new();
        coords.set_latlon(latlon.lat, latlon.lon);
        return me.project(coords);
    },

    projectGeo: func(targetGeo) {
        var dist = me.camGeo.direct_distance_to(targetGeo) * M2NM;
        var bearing = me.camGeo.course_to(targetGeo) - me.camHdg;
        return me.projectDistBearing(dist, bearing);
    },

    projectDistBearing: func(dist, bearing) {
        var bearingRad = bearing * D2R;
        var tx =  math.sin(bearingRad) * dist;
        var ty = -math.cos(bearingRad) * dist;
        var x = tx * me.screenRange / me.range + me.screenCX;
        var y = ty * me.screenRange / me.range + me.screenCY;
        return [x, y];
    },
};
