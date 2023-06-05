var WaypointSelectModule = {
    new: func (mcdu, parentModule, candidates, onSelect, onCancel) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(WaypointSelectModule, m.parents);
        m.candidates = candidates;
        m.onSelect = onSelect;
        m.onCancel = onCancel;
        return m;
    },

    getNumPages: func () { return math.ceil((size(me.candidates)) / 5); },
    getTitle: func () { return "SELECT WPT"; },

    loadPageItems: func (p) {
        var self = me;
        var ref = geo.aircraft_position();
        me.views = [];
        me.controllers = {};
        var i = p * 5;
        for (var row = 0; row < 5; row += 1) {
            var y = row * 2 + 2;
            if (i >= size(me.candidates)) {
                break;
            }
            else {
                (func (wp) {
                    var lat = formatLat(wp.lat);
                    var lon = formatLon(wp.lon);
                    var name = wp.id;
                    if (ghosttype(wp) != 'waypoint') {
                        name = wp.name;
                    }
                    var coords = geo.Coord.new();
                    coords.set_latlon(wp.lat, wp.lon);
                    var dist = M2NM * coords.distance_to(ref);
                    var distFormatted = formatDist(dist);
                    append(me.views, StaticView.new(0, y, substr(name, 0, 23), mcdu_large | mcdu_green));
                    append(me.views, StaticView.new(23, y, mcdu.right_triangle, mcdu_large | mcdu_white));
                    append(me.views, StaticView.new(0, y + 1, lat, mcdu_green));
                    append(me.views, StaticView.new(8, y + 1, lon, mcdu_green));
                    append(me.views, StaticView.new(18, y + 1, distFormatted ~ "NM", mcdu_green));
                    me.controllers['R' ~ (row + 1)] = 
                        FuncController.new(func (owner, ignored) {
                            owner.mcdu.popModule();
                            owner.onSelect(wp);
                        });
                })(me.candidates[i]);
            }

            i += 1;
        }
        append(me.views, StaticView.new(0, 12, mcdu.left_triangle ~ "CANCEL", mcdu_large | mcdu_white));
        me.controllers['L6'] = 
            FuncController.new(func (owner, val) {
                self.onCancel();
            });
    },
};


