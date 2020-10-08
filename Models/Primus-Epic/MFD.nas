# E-Jet Family MFD

var mfd_display = [nil, nil];
var mfd = [nil, nil];
var DC = 0.01744;

var RouteDriver = {
    new: func(){
        var m = {
            parents: [RouteDriver],
        };
        return m;
    },

    update: func () {
    },

    getNumberOfFlightPlans: func() {
        if (fms.modifiedFlightplan == nil) {
            return 1;
        }
        else {
            return 2;
        }
    },

    getFlightPlanType: func(fpNum) {
        if (fpNum == 0) {
            return 'current';
        }
        else {
            return 'modified';
        }
    },

    getFlightPlan: func(fpNum) {
        if (fpNum == 0) {
            return flightplan();
        }
        else {
            return fms.modifiedFlightplan;
        }
    },

    getPlanSize: func(fpNum) {
        var fp = me.getFlightPlan(fpNum);
        if (fp == nil) return 0;
        return fp.getPlanSize();
    },

    getWP: func(fpNum, idx) {
        var fp = me.getFlightPlan(fpNum);
        if (fp == nil) return nil;
        return fp.getWP(idx)
    },

    getPlanModeWP: func(idx) {
        var fp = me.getFlightPlan(0);
        if (fp == nil) return nil;
        return fp.getWP(idx)
    },

    hasDiscontinuity: func(fpNum, wptID) {
        # todo
        return 0;
    },

    getListeners: func(){[
        "/fms/flightplan-modifications",
		"/autopilot/route-manager/active",
    ]},

    shouldUpdate: func 1
};

var MFD = {
    new: func(canvas_group, file, index = 0) {
        var m = { parents: [MFD] };
        m.init(canvas_group, file, index);
        return m;
    },

    init: func(canvas_group, file, index) {
        var font_mapper = func(family, weight) {
            return "LiberationFonts/LiberationSans-Regular.ttf";
        };

        me.index = index;
        me.elems = {};
        me.props = {
                'heading': props.globals.getNode('/orientation/heading-deg'),
                'heading-mag': props.globals.getNode('/orientation/heading-magnetic-deg'),
                'track': props.globals.getNode('/orientation/track-deg'),
                'track-mag': props.globals.getNode('/orientation/track-magnetic-deg'),
                'heading-bug': props.globals.getNode('/it-autoflight/input/hdg'),
                'tas': props.globals.getNode('/instrumentation/airspeed-indicator/true-speed-kt'),
                'ias': props.globals.getNode('/instrumentation/airspeed-indicator/indicated-speed-kt'),
                'sat': props.globals.getNode('/environment/temperature-degc'),
                'tat': props.globals.getNode('/fdm/jsbsim/propulsion/tat-c'),
                'wind-dir': props.globals.getNode("/environment/wind-from-heading-deg"),
                'wind-speed': props.globals.getNode("/environment/wind-speed-kt"),
                'nav-src': props.globals.getNode("/instrumentation/pfd[" ~ index ~ "]/nav-src"),
                'nav-id': [
                    props.globals.getNode("/instrumentation/nav[0]/nav-id"),
                    props.globals.getNode("/instrumentation/nav[1]/nav-id"),
                ],
                'nav-loc': [
                    props.globals.getNode("/instrumentation/nav[0]/nav-loc"),
                    props.globals.getNode("/instrumentation/nav[1]/nav-loc"),
                ],
                'route-active': props.globals.getNode("/autopilot/route-manager/active"),
                'wp-dist': props.globals.getNode("/autopilot/route-manager/wp/dist"),
                'wp-eta': props.globals.getNode("/autopilot/route-manager/wp/eta-seconds"),
                'wp-id': props.globals.getNode("/autopilot/route-manager/wp/id"),
            };

        me.master = canvas_group;

        # Upper area (lateral/systems): 1024x768
        me.upperArea = me.master.createChild("group");
        me.upperArea.set("clip", "rect(100px, 1024px, 868px, 0px)");
        me.upperArea.set("clip-frame", canvas.Element.PARENT);
        me.upperArea.setTranslation(0, 100);

        # Lower area (vertical/checklists): 1024x400
        me.lowerArea = me.master.createChild("group");
        me.lowerArea.set("clip", "rect(868px, 1024px, 1266px, 0px)");
        me.lowerArea.set("clip-frame", canvas.Element.PARENT);
        me.lowerArea.setTranslation(0, 868);

        me.guiOverlay = me.master.createChild("group");
        canvas.parsesvg(me.guiOverlay, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-gui.svg", {'font-mapper': font_mapper});

        me.mapPage = me.upperArea.createChild("group");
        me.map = me.mapPage.createChild("map");
        me.map.set("clip", "rect(0px, 1024px, 640px, 0px)");
        me.map.set("clip-frame", canvas.Element.PARENT);

        me.mapOverlay = me.mapPage.createChild("group");
        canvas.parsesvg(me.mapOverlay, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-map.svg", {'font-mapper': font_mapper});

        var keys = [
                'arc',
                'arc.compass',
                'arc.heading-bug',
                'arc.heading-bug.arrow-left',
                'arc.heading-bug.arrow-right',
                'arc.range.left',
                'arc.range.right',
                'dest.dist',
                'dest.eta',
                'dest.fuel',
                'dest.fuel.unit',
                'dest.wpt',
                'eta-ete',
                'heading.digital',
                'nav.src',
                'nav.target.name',
                'nav.target',
                'nav.target.dist',
                'nav.target.ete',
                'next.dist',
                'next.eta',
                'next.fuel',
                'next.fuel.unit',
                'next.wpt',
                'progress.master',
                'weather.master',
                'wind.arrow',
                'wind.digital',
                'tat.digital',
                'sat.digital',
                'tas.digital',
            ];
        foreach (var key; keys) {
            me.elems[key] = me.mapOverlay.getElementById(key);
        }
        me.elems['arc'].set("clip", "rect(0px, 1024px, 540px, 0px)");
        me.elems['arc'].set("clip-frame", canvas.Element.PARENT);
        me.elems['arc'].setCenter(512, 530);
        me.elems['arc.heading-bug'].setCenter(512, 530);

        me.routeDriver = RouteDriver.new();

        me.map.setTranslation(512, 540);
        me.map.setController("Aircraft position");
        me.map.setRange(20);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "TFC", visible: 1, priority: 9,);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "WPT", visible: 1, priority: 6,
                        opts: { 'route_driver': me.routeDriver },);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "RTE", visible: 1, priority: 5,
                        opts: { 'route_driver': me.routeDriver }, style: { 'line_dash_modified': func (arg=nil) { debug.dump(arg); return [32,16]; } },);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "APT", visible: 1, priority: 4,);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "RWY", visible: 0, priority: 3,);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "TAXI", visible: 0, priority: 3,);

        me.showFMSTarget = 1;

        var self = me;
        setlistener("/instrumentation/mfd[" ~ index ~ "]/lateral-range", func (node) {
            self.setRange(node.getValue());
        }, 1, 0);
        setlistener(me.props['heading-bug'], func (node) {
            self.elems['arc.heading-bug'].setRotation(node.getValue() * DC);
        }, 1, 0);
        setlistener(me.props['nav-src'], func (node) {
            self.updateNavSrc();
        }, 1, 0);
        setlistener(me.props['wp-id'], func (node) {
            self.updateNavSrc();
        }, 0, 0);

        return me;
    },

    setRange: func(range) {
        me.map.setRange(range);
        me.map.layers["TAXI"].setVisible(range < 9.5);
        me.map.layers["RWY"].setVisible(range < 9.5);
        me.map.layers["APT"].setVisible(range >= 9.5 and range < 99.5);
        var rangeTxt = sprintf("%2.0f", range);
        me.elems['arc.range.left'].setText(rangeTxt);
        me.elems['arc.range.right'].setText(rangeTxt);
    },

    touch: func(args) {
        debug.dump(args);
    },

    updateNavSrc: func () {
        var navSrc = me.props['nav-src'].getValue();
        if (navSrc == 0) {
            var id = me.props['wp-id'].getValue();
            me.elems['nav.src'].setText('FMS' ~ (me.index + 1));
            me.elems['nav.src'].setColor(1, 0, 1);
            me.elems['nav.target.name'].setText(id);
            me.elems['nav.target.name'].setColor(1, 0, 1);
            me.elems['nav.target'].show();
            me.showFMSTarget = 1;
        }
        else {
            var lbl = 'VOR';
            if (me.props['nav-loc'][navSrc - 1].getValue()) {
                lbl = 'LOC';
            }
            var id = me.props['nav-id'][navSrc - 1].getValue();
            me.elems['nav.src'].setText(lbl ~ navSrc);
            me.elems['nav.src'].setColor(0, 1, 0);
            me.elems['nav.target.name'].setText(id);
            me.elems['nav.target.name'].setColor(0, 1, 0);
            me.elems['nav.target'].hide();
            me.showFMSTarget = 0;
        }
    },

    update: func () {
        var heading = me.props['heading-mag'].getValue();
        var headingBug = me.props['heading-bug'].getValue();
        var headingDiff = geo.normdeg180(headingBug - heading);
        if (headingDiff < -90) {
            me.elems['arc.heading-bug'].hide();
            me.elems['arc.heading-bug.arrow-left'].show();
            me.elems['arc.heading-bug.arrow-right'].hide();
        }
        else if (headingDiff > 90) {
            me.elems['arc.heading-bug'].hide();
            me.elems['arc.heading-bug.arrow-left'].hide();
            me.elems['arc.heading-bug.arrow-right'].show();
        }
        else {
            me.elems['arc.heading-bug'].show();
            me.elems['arc.heading-bug.arrow-left'].hide();
            me.elems['arc.heading-bug.arrow-right'].hide();
        }
        me.elems['arc'].setRotation(heading * -DC);
        me.elems['heading.digital'].setText(sprintf("%03.0f", heading));
        me.elems['wind.arrow'].setRotation(me.props['wind-dir'].getValue() * DC);
        me.elems['wind.digital'].setText(sprintf("%2.0f", me.props['wind-speed'].getValue()));
        me.elems['tat.digital'].setText(sprintf("%3.0f", me.props['tat'].getValue()));
        me.elems['sat.digital'].setText(sprintf("%3.0f", me.props['sat'].getValue()));
        me.elems['tas.digital'].setText(sprintf("%3.0f", me.props['tas'].getValue()));
        if (me.showFMSTarget) {
            var dist = me.props['wp-dist'].getValue();
            var distStr = '----';
            if (dist != nil) {
                var distFmt = "%4.1f";
                if (dist >= 50.0) {
                    distFmt = "%4.0f";
                }
                distStr = sprintf(distFmt, dist);
            }
            me.elems['nav.target.dist'].setText(distStr);

            var eta = me.props['wp-eta'].getValue();
            var etaStr = '---';
            if (eta != nil) {
                etaStr = sprintf("%3.0f", eta / 60.0);
            }
            me.elems['nav.target.ete'].setText(etaStr);
        }
    }
};


setlistener("sim/signals/fdm-initialized", func {
    for (var i = 0; i <= 1; i += 1) {
        mfd_display[i] = canvas.new({
            "name": "MFD" ~ i,
            "size": [1024, 1560],
            "view": [1024, 1560],
            "mipmapping": 1
        });
        mfd_display[i].addPlacement({"node": "MFD" ~ i});
        mfd[i] =
            MFD.new(
                mfd_display[i].createGroup(),
                "Aircraft/E-jet-family/Models/Primus-Epic/MFD.svg",
                i);
    }

    var timer = maketimer(0.1, func() {
        mfd[0].update();
        mfd[1].update();
    });
    timer.start();
});
