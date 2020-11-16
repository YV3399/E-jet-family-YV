# E-Jet Family MFD
#
# AOM references:
# - TCAS mode: p. 2157

var mfd_display = [nil, nil];
var mfd = [nil, nil];
var DC = 0.01744;
var sin30 = math.sin(30 * D2R);
var cos30 = math.cos(30 * D2R);

var radarColor = func (value) {
    # 0.00 black
    # 0.25 green   (0, 1, 0)
    # 0.50 yellow  (1, 1, 0)
    # 0.75 red     (1, 0, 0)
    # 1.00 magenta (1, 0, 1)
    # > 1.00 cyan
    if (value == nil) return [ 0, 0, 0, 1 ];
    if (value > 1.0) return [ 0, 1, 1, 1 ];
    if (value > 0.75) return [ 1, 0, (value - 0.75) * 4, 1 ];
    if (value > 0.50) return [ 1, (0.75 - value - 0.50) * 4, 0, 1 ];
    if (value > 0.25) return [ (value - 0.25) * 4, 1, 0, 1 ];
    if (value > 0.00) return [ 0, value * 4, 0, 1 ];
    return [ 0, 0, 0, 1 ];
}

var RouteDriver = {
    new: func(includeCurrent=1){
        var m = {
            parents: [RouteDriver],
        };
        m.includeCurrent = includeCurrent;
        return m;
    },

    update: func () {
        me.flightplans = [];
        if ((me.includeCurrent or fms.modifiedFlightplan == nil) and flightplan() != nil) {
            append(me.flightplans, { fp: flightplan(), type: 'current' });
        }
        if (fms.modifiedFlightplan != nil) {
            append(me.flightplans, { fp: fms.modifiedFlightplan, type: 'modified' });
        }
    },

    getNumberOfFlightPlans: func() {
        return size(me.flightplans);
    },

    getFlightPlanType: func(fpNum) {
        if (fpNum >= size(me.flightplans)) return nil;
        return me.flightplans[fpNum].type;
    },

    getFlightPlan: func(fpNum) {
        if (fpNum >= size(me.flightplans)) return nil;
        return me.flightplans[fpNum].fp;
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

        var self = me; # for listeners

        me.index = index;
        me.txRadarScanX = 0;
        me.elems = {};
        me.props = {
                'page': props.globals.getNode('/instrumentation/mfd[' ~ index ~ ']/page'),
                'altitude-amsl': props.globals.getNode('/position/altitude-ft'),
                'altitude': props.globals.getNode('/instrumentation/altimeter/indicated-altitude-ft'),
                'altitude-selected': props.globals.getNode('/controls/flight/selected-alt'),
                'altitude-target': props.globals.getNode('/it-autoflight/input/alt'),
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
                'groundspeed': props.globals.getNode("/velocities/groundspeed-kt"),
                'vs': props.globals.getNode("/instrumentation/vertical-speed-indicator/indicated-speed-fpm"),
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
                'wp-ete': props.globals.getNode("/autopilot/route-manager/wp/eta-seconds"),
                'wp-id': props.globals.getNode("/autopilot/route-manager/wp/id"),
                'dest-dist': props.globals.getNode("/autopilot/route-manager/distance-remaining-nm"),
                'dest-ete': props.globals.getNode("/autopilot/route-manager/ete"),
                'dest-id': props.globals.getNode("/autopilot/route-manager/destination/airport"),
                'zulutime': props.globals.getNode("/instrumentation/clock/indicated-sec"),
                'cursor': props.globals.getNode("/instrumentation/mfd[" ~ index ~ "]/cursor"),
                'cursor.x': props.globals.getNode("/instrumentation/mfd[" ~ index ~ "]/cursor/x"),
                'cursor.y': props.globals.getNode("/instrumentation/mfd[" ~ index ~ "]/cursor/y"),
                'range': props.globals.getNode("/instrumentation/mfd[" ~ index ~ "]/lateral-range"),
                'tcas-mode': props.globals.getNode("/instrumentation/tcas/inputs/mode"),
                'wx-sweep-angle': props.globals.getNode("/instrumentation/wxr/sweep-pos-deg"),
                'wx-sweep-index': props.globals.getNode("/instrumentation/wxr/scan-pos"),
                'wx-range': props.globals.getNode("/instrumentation/wxr/range-nm"),
                'wx-mode': props.globals.getNode("/instrumentation/wxr/mode"),
                'wx-mode-sel': props.globals.getNode("/instrumentation/mfd[" ~ index ~ "]/wx-mode"),
                'wx-mode-indicated': props.globals.getNode("/instrumentation/mfd[" ~ index ~ "]/wx-mode-indicated"),
                'wx-gain': props.globals.getNode("/instrumentation/wxr/gain"),
                'wx-tilt': props.globals.getNode("/instrumentation/wxr/tilt-angle-deg"),
                'wx-sect': props.globals.getNode("/instrumentation/wxr/sector-scan"),
                'wx-turb': props.globals.getNode("/instrumentation/wxr/turb"),
                'wx-lx': props.globals.getNode("/instrumentation/wxr/lx"),
                'wx-act': props.globals.getNode("/instrumentation/wxr/act"),
                'wx-rct': props.globals.getNode("/instrumentation/wxr/rct"),
                'wx-tgt': props.globals.getNode("/instrumentation/wxr/tgt"),
                'wx-fsby-ovrd': props.globals.getNode("/instrumentation/wxr/fstby-ovrd"),
                'green-arc-dist': props.globals.getNode("/fms/dist-to-alt-target-nm"),
                'route-progress': props.globals.getNode("/fms/vnav/route-progress"),
            };

        var masterProp = props.globals.getNode("/instrumentation/mfd[" ~ index ~ "]");
        foreach (var key; ['show-navaids', 'show-airports', 'show-wpt', 'show-progress', 'show-missed', 'show-tcas']) {
            var node = masterProp.addChild(key);
            node.setBoolValue(0);
            me.props[key] = node;
        }

        me.master = canvas_group;

        # Upper area (lateral/systems): 1024x768
        me.upperArea = me.master.createChild("group");
        me.upperArea.set("clip", "rect(100px, 1024px, 850px, 0px)");
        me.upperArea.set("clip-frame", canvas.Element.PARENT);
        me.upperArea.setTranslation(0, 100);

        # Lower area (vertical/checklists): 1024x400
        me.lowerArea = me.master.createChild("group");
        me.lowerArea.set("clip", "rect(850px, 1024px, 1266px, 0px)");
        me.lowerArea.set("clip-frame", canvas.Element.PARENT);
        me.lowerArea.setTranslation(0, 0);

        me.guiOverlay = me.master.createChild("group");
        canvas.parsesvg(me.guiOverlay, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-gui.svg", {'font-mapper': font_mapper});

        # Set up MAP/PLAN page
        me.dualRouteDriver = RouteDriver.new();
        me.plannedRouteDriver = RouteDriver.new(0);

        me.vnav = me.lowerArea.createChild("group");
        canvas.parsesvg(me.vnav, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-vnav.svg", {'font-mapper': font_mapper});

        me.mapPage = me.upperArea.createChild("group");

        me.underlay = me.mapPage.createChild("group");
        me.terrainViz = me.underlay.createChild("image");
        me.terrainViz.set("src", resolvepath("Aircraft/E-jet-family/Models/Primus-Epic/MFD/terrain" ~ index ~ ".png"));
        me.terrainViz.setCenter(128, 128);
        var terrainTimerFunc = func () {
            self.updateTerrainViz();
            settimer(terrainTimerFunc, 0.1);
        };
        me.radarViz = me.underlay.createChild("image");
        me.radarViz.set("src", resolvepath("Aircraft/E-jet-family/Models/Primus-Epic/MFD/radar" ~ index ~ ".png"));
        me.radarViz.setCenter(128, 128);
        me.lastRadarSweepAngle = -60;
        setlistener("/instrumentation/wxr/sweep-pos-deg", func (node) {
            self.updateRadarViz(node.getValue());
        });
        setlistener(me.props['wx-range'], func () {
            self.updateRadarScale();
        });

        canvas.parsesvg(me.underlay, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-radar-mask.svg");
        settimer(terrainTimerFunc, 1.0);

        me.mapCamera = mfdmap.Camera.new({
            range: 25,
            screenRange: 416,
            screenCX: 512,
            screenCY: 540,
        });
        me.trafficGroup = me.mapPage.createChild("group");
        me.trafficLayer = mfdmap.TrafficLayer.new(me.mapCamera, me.trafficGroup);
        me.trafficLayer.start();

        me.map = me.mapPage.createChild("map");
        me.map.set("clip", "rect(0px, 1024px, 740px, 0px)");
        me.map.set("clip-frame", canvas.Element.PARENT);
        me.map.setTranslation(512, 540);
        me.map.setController("Aircraft position");
        me.map.setRange(25);
        me.map.setScreenRange(416);
        # me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "TFC-Ejet", visible: 1, priority: 9,
        #                 style: {
        #                     'color_default':
        #                         [0.5,0.5,0.5],
        #                     'color_by_lvl': {
        #                         # 0: other
        #                         0: [0,1,1],
        #                         # 1: proximity
        #                         1: [0,1,1],
        #                         # 2: traffic advisory (TA)
        #                         2: [1,0.75,0],
        #                         # 3: resolution advisory (RA)
        #                         3: [1,0,0],
        #                     },
        #                 } );
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "WPT", visible: 1, priority: 6,
                        opts: { 'route_driver': me.dualRouteDriver },);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "RTE", visible: 1, priority: 5,
                        opts: { 'route_driver': me.dualRouteDriver }, style: { 'line_dash_modified': func (arg=nil) { return [32,16]; } },);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "APT", visible: 1, priority: 4,);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "VOR", visible: 1, priority: 4,);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "NDB", visible: 1, priority: 4,);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "RWY", visible: 0, priority: 3,);
        me.map.addLayer(factory: canvas.SymbolLayer, type_arg: "TAXI", visible: 0, priority: 3,);
        me.map.hide();

        me.plan = me.mapPage.createChild("map");
        me.plan.set("clip", "rect(0px, 1024px, 640px, 0px)");
        me.plan.set("clip-frame", canvas.Element.PARENT);
        me.plan.setTranslation(512, 320);
        me.plan.setController("Static position");
        var (lat,lon) = geo.aircraft_position().latlon();
        me.plan.controller.setPosition(lat, lon);
        me.plan.setRange(25);
        me.plan.setScreenRange(416);
        me.plan.addLayer(factory: canvas.SymbolLayer, type_arg: "WPT", visible: 1, priority: 6,
                        opts: { 'route_driver': me.plannedRouteDriver },);
        me.plan.addLayer(factory: canvas.SymbolLayer, type_arg: "RTE", visible: 1, priority: 5,
                        opts: { 'route_driver': me.plannedRouteDriver }, style: { 'line_dash_modified': func (arg=nil) { return [32,16]; } },);
        me.plan.addLayer(factory: canvas.SymbolLayer, type_arg: "APT", visible: 1, priority: 4,);
        # TODO: figure out how to position the airplane symbol at the correct
        # position.
        # me.plan.addLayer(factory: canvas.SymbolLayer, type_arg: "APS", visible: 1, priority: 3,);
        me.planIndex = 0;

        me.mapOverlay = me.mapPage.createChild("group");
        canvas.parsesvg(me.mapOverlay, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-map.svg", {'font-mapper': font_mapper});

        var mapkeys = [
                'arc',
                'arc.compass',
                'arc.heading-bug',
                'arc.heading-bug.arrow-left',
                'arc.heading-bug.arrow-right',
                'arc.master',
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
                'nav.target',
                'nav.target.dist',
                'nav.target.ete',
                'nav.target.name',
                'next.dist',
                'next.eta',
                'next.fuel',
                'next.fuel.unit',
                'next.wpt',
                'plan.master',
                'plan.range',
                'progress.master',
                'sat.digital',
                'tas.digital',
                'tat.digital',
                'terrain.master',
                'tcas.master',
                'tcas.altmode',
                'tcas.mode',
                'weather.master',
                'weather.tilt',
                'weather.act',
                'weather.mode',
                'weather.slaved',
                'weather.stab',
                'weather.tgt',
                'weather.lx',
                'wind.arrow',
                'wind.digital',
            ];
        var guikeys = [
                'mapMenu',
                'checkNavaids',
                'checkAirports',
                'checkWptIdent',
                'checkProgress',
                'checkMissedAppr',
                'checkTCAS',
                'radioWeather',
                'radioTerrain',
                'radioOff',

                'weatherMenu',
                'weatherMenu.radioWX',
                'weatherMenu.radioGMAP',
                'weatherMenu.radioSTBY',
                'weatherMenu.radioOff',
                'weatherMenu.gain',
                'weatherMenu.checkSect',
                'weatherMenu.checkStabOff',
                'weatherMenu.checkVarGain',
                'weatherMenu.checkTGT',
                'weatherMenu.checkRCT',
                'weatherMenu.checkACT',
                'weatherMenu.checkTurb',
                'weatherMenu.checkLX',
                'weatherMenu.checkClrTst',
                'weatherMenu.checkFsbyOvrd',
            ];
        var vnavkeys = [
                'vnav.vertical',
                'vnav.lateral',
                'vnav.selectedalt',
                'vnav.alt.scale',
                'vnav.range.left',
                'vnav.range.center',
                'vnav.range.right',
                'vnav.range.left.digital',
                'vnav.range.center.digital',
                'vnav.range.right.digital',
                'vnav.aircraft.symbol',
            ];
        foreach (var key; mapkeys) {
            me.elems[key] = me.mapOverlay.getElementById(key);
            if (me.elems[key] == nil) {
                debug.warn("Element does not exist: " ~ key);
            }
        }
        foreach (var key; guikeys) {
            me.elems[key] = me.guiOverlay.getElementById(key);
            if (me.elems[key] == nil) {
                debug.warn("Element does not exist: " ~ key);
            }
        }
        foreach (var key; vnavkeys) {
            me.elems[key] = me.vnav.getElementById(key);
            if (me.elems[key] == nil) {
                debug.warn("Element does not exist: " ~ key);
            }
        }

        me.elems['vnav-flightplan'] = me.elems['vnav.lateral'].createChild("group");
        me.elems['vnav-flightplan.path'] = me.elems['vnav-flightplan'].createChild("path");
        me.elems['vnav-flightplan.path'].setStrokeLineWidth(2);
        me.elems['vnav-flightplan.path'].setColor(1, 0, 1);
        me.elems['vnav-flightplan.waypoints'] = me.elems['vnav-flightplan'].createChild("group");

        me.elems['vnav-flightpath'] = me.elems['vnav.lateral'].createChild("path");
        me.elems['vnav-flightpath'].setStrokeLineWidth(3);
        me.elems['vnav-flightpath'].setColor(0, 1, 0);

        me.elems['arc'].set("clip", "rect(0px, 1024px, 540px, 0px)");
        me.elems['arc'].set("clip-frame", canvas.Element.PARENT);
        me.elems['arc'].setCenter(512, 530);
        me.elems['arc.heading-bug'].setCenter(512, 530);
        me.elems['mapMenu'].hide();
        me.elems['weatherMenu'].hide();

        me.elems['greenarc'] = me.elems['arc.master'].createChild("path");
        me.elems['greenarc'].setStrokeLineWidth(3);
        me.elems['greenarc'].setColor(0, 1, 0, 1);

        me.widgets = [
            { key: 'btnMap', ontouch: func { self.touchMap(); } },
            { key: 'btnPlan', ontouch: func { self.touchPlan(); } },
            { key: 'btnSystems', ontouch: func { self.touchSystems(); } },
            { key: 'btnTCAS', ontouch: func { debug.dump("TCAS"); } },
            { key: 'btnWeather', ontouch: func { self.elems['weatherMenu'].toggleVisibility(); } },
            { key: 'checkNavaids', active: func { self.elems['mapMenu'].getVisible() }, ontouch: func { self.toggleMapCheckbox('navaids'); } },
            { key: 'checkAirports', active: func { self.elems['mapMenu'].getVisible() }, ontouch: func { self.toggleMapCheckbox('airports'); } },
            { key: 'checkWptIdent', active: func { self.elems['mapMenu'].getVisible() }, ontouch: func { self.toggleMapCheckbox('wpt'); } },
            { key: 'checkProgress', active: func { self.elems['mapMenu'].getVisible() }, ontouch: func { self.toggleMapCheckbox('progress'); } },
            { key: 'checkMissedAppr', active: func { self.elems['mapMenu'].getVisible() }, ontouch: func { self.toggleMapCheckbox('missed'); } },
            { key: 'checkTCAS', active: func { self.elems['mapMenu'].getVisible() }, ontouch: func { self.toggleMapCheckbox('tcas'); } },
            { key: 'radioWeather', active: func { self.elems['mapMenu'].getVisible() }, ontouch: func { self.selectUnderlay('WX'); } },
            { key: 'radioTerrain', active: func { self.elems['mapMenu'].getVisible() }, ontouch: func { self.selectUnderlay('TERRAIN'); } },
            { key: 'radioOff', active: func { self.elems['mapMenu'].getVisible() }, ontouch: func { self.selectUnderlay(nil); } },

            { key: 'weatherMenu.radioOff', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.setWxMode(0); } },
            { key: 'weatherMenu.radioSTBY', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.setWxMode(1); } },
            { key: 'weatherMenu.radioWX', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.setWxMode(2); } },
            { key: 'weatherMenu.radioGMAP', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.setWxMode(3); } },
            { key: 'weatherMenu.checkSect', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.toggleWeatherCheckbox('wx-sect'); } },
            { key: 'weatherMenu.checkStabOff', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.toggleWeatherCheckbox('wx-stab-off'); } },
            { key: 'weatherMenu.checkVarGain', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.toggleWeatherCheckbox('wx-var-gain'); } },
            { key: 'weatherMenu.checkTGT', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.toggleWeatherCheckbox('wx-tgt'); } },
            { key: 'weatherMenu.checkRCT', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.toggleWeatherCheckbox('wx-rct'); } },
            { key: 'weatherMenu.checkACT', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.toggleWeatherCheckbox('wx-act'); } },
            { key: 'weatherMenu.checkTurb', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.toggleWeatherCheckbox('wx-turb'); } },
            { key: 'weatherMenu.checkLX', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.toggleWeatherCheckbox('wx-lx'); } },
            { key: 'weatherMenu.checkClrTst', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.toggleWeatherCheckbox('wx-clr-tst'); } },
            { key: 'weatherMenu.checkFsbyOvrd', active: func { self.elems['weatherMenu'].getVisible() }, ontouch: func { self.toggleWeatherCheckbox('wx-fsby-ovrd'); } },
        ];

        forindex (var i; me.widgets) {
            var elem = me.guiOverlay.getElementById(me.widgets[i].key);
            var boxElem = me.guiOverlay.getElementById(me.widgets[i].key ~ ".clickbox");
            if (boxElem == nil) {
                me.widgets[i].box = elem.getTransformedBounds();
            }
            else {
                me.widgets[i].box = boxElem.getTransformedBounds();
            }
            me.widgets[i].elem = elem;
            if (me.widgets[i]['visible'] != nil and me.widgets[i].visible == 0) {
                elem.hide();
            }
        }


        me.cursor = me.guiOverlay.createChild("group");
        canvas.parsesvg(me.cursor, "Aircraft/E-jet-family/Models/Primus-Epic/cursor.svg", {'font-mapper': font_mapper});

        me.showFMSTarget = 1;

        me.selectUnderlay(nil);
        me.setWxMode(nil);

        setlistener(me.props['green-arc-dist'], func (node) {
            self.updateGreenArc(node.getValue());
        }, 1, 0);
        setlistener(me.props['wx-gain'], func (node) {
            self.elems['weatherMenu.gain'].setText(sprintf("%3.0f", node.getValue() or 0));
        }, 1, 0);
        setlistener(me.props['wx-tilt'], func (node) {
            self.elems['weather.tilt'].setText(sprintf("%-2.0f", node.getValue() or 0));
        }, 1, 0);
        setlistener(me.props['wx-mode-indicated'], func(node) {
            var modeIndex = node.getValue();
            if (modeIndex == 3) {
                self.elems['weather.mode']
                    .setText("GMAP")
                    .setColor([0, 1, 0, 1]);
            }
            else if (modeIndex == 2) {
                self.elems['weather.mode']
                    .setText("WX")
                    .setColor([0, 1, 0, 1]);
            }
            else if (modeIndex == 1) {
                self.elems['weather.mode']
                    .setText("STBY")
                    .setColor([1, 1, 1, 1]);
            }
            else if (modeIndex == 0) {
                self.elems['weather.mode']
                    .setText("WX OFF")
                    .setColor([1, 1, 1, 1]);
            }
            else if (modeIndex == -1) {
                self.elems['weather.mode']
                    .setText("FSBY")
                    .setColor([0, 1, 0, 1]);
            }
            else if (modeIndex == -2) {
                self.elems['weather.mode']
                    .setText("WAIT")
                    .setColor([1, 1, 1, 1]);
            }
            else {
                self.elems['weather.mode']
                    .setText("FAIL")
                    .setColor([1, 0.5, 0, 1]);
            }
        }, 1, 0);
        setlistener(me.props['wx-sect'], func (node) {
            self.elems['weatherMenu.checkSect'].setVisible(node.getBoolValue());
        }, 1, 0);
        setlistener('/fms/vnav/available', func () {
            self.updateVnavFlightplan();
        }, 1, 0);
        setlistener(me.props['wx-fsby-ovrd'], func (node) {
            self.elems['weatherMenu.checkFsbyOvrd'].setVisible(node.getBoolValue());
        }, 1, 0);
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
        setlistener("/autopilot/route-manager/active", func {
            self.updatePlanWPT();
            self.updateVnavFlightplan();
        }, 1, 0);
        setlistener( "/autopilot/route-manager/cruise/altitude-ft", func {
            self.updateVnavFlightplan();
        }, 1, 0);
        setlistener(me.props['page'], func (node) {
            self.updatePage();
        }, 1, 0);
        setlistener(me.props['cursor'], func (node) {
            self.cursor.setTranslation(
                self.props['cursor.x'].getValue(),
                self.props['cursor.y'].getValue()
            );
        }, 1, 2);
        setlistener(me.props['show-navaids'], func (node) {
            var viz = node.getBoolValue();
            self.elems['checkNavaids'].setVisible(viz);
            self.map.layers['NDB'].setVisible(viz);
            self.map.layers['VOR'].setVisible(viz);
        }, 1, 0);
        setlistener(me.props['show-airports'], func (node) {
            var viz = node.getBoolValue();
            var range = me.map.getRange();
            self.elems['checkAirports'].setVisible(viz);
            self.map.layers["RWY"].setVisible(range < 9.5 and viz);
            self.map.layers["APT"].setVisible(range >= 9.5 and range < 99.5 and viz);
        }, 1, 0);
        setlistener(me.props['show-wpt'], func (node) {
            var viz = node.getBoolValue();
            self.elems['checkWptIdent'].setVisible(viz);
            self.map.layers['WPT'].setVisible(viz);
        }, 1, 0);
        setlistener(me.props['show-progress'], func (node) {
            var viz = node.getBoolValue();
            self.elems['checkProgress'].setVisible(viz);
            self.elems['progress.master'].setVisible(viz);
        }, 1, 0);
        setlistener(me.props['show-missed'], func (node) {
            var viz = node.getBoolValue();
            self.elems['checkMissedAppr'].setVisible(viz);
            # TODO: toggle missed approach display
        }, 1, 0);
        setlistener(me.props['show-tcas'], func (node) {
            var viz = node.getBoolValue();
            self.elems['checkTCAS'].setVisible(viz);
            self.elems['tcas.master'].setVisible(viz);
            self.trafficGroup.setVisible(viz);
            # self.map.layers['TFC-Ejet'].setVisible(viz);
        }, 1, 0);
        setlistener(me.props['tcas-mode'], func (node) {
            var mode = node.getValue();
            if (mode == 3) {
                # TA/RA
                self.elems['tcas.mode'].setColor(0, 1, 0);
                self.elems['tcas.mode'].setText('TCAS TA/RA');
            }
            else if (mode == 2) {
                # TA ONLY
                self.elems['tcas.mode'].setColor(0, 1, 0);
                self.elems['tcas.mode'].setText('TA ONLY');
            }
            else {
                # TCAS OFF
                self.elems['tcas.mode'].setColor(1, 0.75, 0);
                self.elems['tcas.mode'].setText('TCAS OFF');
            }
        }, 1, 0);
        setlistener(me.props['altitude-selected'], func (node) {
            var alt = node.getValue();
            var offset = -alt * 0.04;
            self.elems['vnav.selectedalt'].setTranslation(0, offset);
        }, 1, 0);

        return me;
    },

    updateGreenArc: func (greenArcDist=nil, range=nil) {
        if (greenArcDist == nil) {
            greenArcDist = me.props['green-arc-dist'].getValue() or -1;
        }
        if (range == nil) {
            range = me.props['range'].getValue();
        }
        var scale = greenArcDist / range;

        if (greenArcDist > range or greenArcDist <= range / 200) {
            me.elems['greenarc'].hide();
        }
        else {
            var length = scale * 416;
            var w = 208;

            var hSq = length * length - w * w;

            if (hSq <= 0) {
                me.elems['greenarc']
                    .reset()
                    .moveTo(512 - length, 530)
                    .arcSmallCWTo(length, length, 0, 512 + length, 530)
                    .show();
            }
            else {
                var h = math.sqrt(hSq);
                me.elems['greenarc']
                    .reset()
                    .moveTo(512 - w, 530 - h)
                    .arcSmallCWTo(length, length, 0, 512 + w, 530 - h)
                    .show();
            }
        }
    },

    updateRadarViz: func (newAngle) {
        var oldAngle = me.lastRadarSweepAngle;
        var mode = me.props['wx-mode-sel'].getValue();
        var limit = (me.props['wx-sect'].getBoolValue()) ? 30 : 60;

        if (mode >= 2) {
            if (oldAngle > newAngle) {
                me.drawRadarViz(mode, oldAngle, limit);
                me.drawRadarViz(mode, limit, 60);
                me.drawRadarViz(mode, -60, -limit);
                me.drawRadarViz(mode, -limit, newAngle);
            }
            else {
                me.drawRadarViz(mode, oldAngle, newAngle);
            }
            me.radarViz.dirtyPixels();
        }

        me.lastRadarSweepAngle = newAngle;
    },

    drawRadarViz: func (mode, leftAngle, rightAngle) {
        var leftTan = math.tan(leftAngle * D2R);
        var rightTan = math.tan(rightAngle * D2R);
        for (var y = 0; y < 128; y += 1) {
            var left = math.max(-127, math.min(127, math.round(y * leftTan)));
            var right = math.max(-127, math.min(127, math.round(y * rightTan)));
            var d = math.sqrt(y * y + left * left);
            var signal = 0;
            if (mode == 2) {
                # WX
                signal += wxr.get_weather_pixel(leftAngle, d * wxr.scan_range / 128) or 0;
                signal += 0.1 * (wxr.get_ground_pixel(leftAngle, d * wxr.scan_range / 128) or 0);
            }
            else if (mode == 3) {
                # GMAP
                signal += 0.1 * (wxr.get_weather_pixel(leftAngle, d * wxr.scan_range / 128) or 0);
                signal += wxr.get_ground_pixel(leftAngle, d * wxr.scan_range / 128) or 0;
            }
            var color = radarColor(signal);
            for (var x = left; x < right; x += 1) {
                me.radarViz.setPixel(127+x, 128+y, color);
            }
        }
    },

    updateTerrainViz: func() {
        if (!me.terrainViz.getVisible()) return;
        var acPos = geo.aircraft_position();
        var acAlt = me.props['altitude-amsl'].getValue();
        var x = 0;
        var y = 0;
        var color = nil;
        var density = 0;
        for (y = 0; y < 256; y += 2) {
            var x = me.txRadarScanX;
            # for (x = 0; x < 256; x += 2) {
                var xRel = x - 128;
                var yRel = y - 128;
                var bearingRelRad = math.atan2(xRel, yRel);
                var bearingAbs = geo.normdeg(bearingRelRad * R2D);
                var dist = math.sqrt(yRel * yRel + xRel * xRel);
                var elev = nil;
                if (dist <= 128) {
                    var coord = geo.Coord.new(acPos);
                    coord.apply_course_distance(bearingAbs, dist * 10.675 * NM2M / 128);
                    var start = geo.Coord.new(coord);
                    var end = geo.Coord.new(coord);
                    start.set_alt(10000);
                    end.set_alt(0);
                    var xyz = { "x": start.x(), "y": start.y(), "z": start.z() };
                    var dir = { "x": end.x() - start.x(), "y": end.y() - start.y(), "z": end.z() - start.z() };
                    var result = get_cart_ground_intersection(xyz, dir);
                    elev = (result == nil) ? nil : result.elevation;
                }
                if (elev == nil) {
                    color = '#000000';
                    density = 1;
                }
                else {
                    var terrainAlt = elev * M2FT;
                    var relAlt = terrainAlt - acAlt;
                    if (relAlt > 2000) {
                        color = [1, 0, 0, 1];
                        density = 1;
                    }
                    else if (relAlt > 1000) {
                        color = [1, 1, 0, 1];
                        density = 1;
                    }
                    else if (relAlt > -250) {
                        color = [1, 1, 0, 1];
                        density = 0;
                    }
                    else if (relAlt > -1000) {
                        color = [0, 0.5, 0, 1];
                        density = 1;
                    }
                    else if (relAlt > -2000) {
                        color = [0, 0.5, 0, 1];
                        density = 0;
                    }
                    else {
                        color = [0, 0, 0, 1];
                        density = 1;
                    }
                }
                if (density)
                    me.terrainViz.fillRect([x, y, 2, 2], color);
                else
                    me.terrainViz.fillRect([x, y, 2, 2], '#000000');
                me.terrainViz.setPixel(x, y, color);
            # }
        }
        me.txRadarScanX += 2;
        if (me.txRadarScanX >= 256) {
            me.txRadarScanX = 0;
        }
        me.terrainViz.dirtyPixels();
    },

    updateRadarScale: func (range=nil) {
        if (range == nil) { range = me.props['range'].getValue(); }

        var wxRange = me.props['wx-range'].getValue();
        var wxScale = wxRange / range * 444 / 128;
        me.radarViz.setScale(wxScale, wxScale);
        me.radarViz.setTranslation(512 - 128 * wxScale, 530 - 128 * wxScale);
    },

    setRange: func(range) {
        var aptVisible = me.props['show-airports'].getBoolValue();
        me.mapCamera.setRange(range);
        me.map.setRange(range);
        me.plan.setRange(range);
        me.map.layers["TAXI"].setVisible(range < 9.5);
        me.map.layers["RWY"].setVisible(range < 9.5 and aptVisible);
        me.map.layers["APT"].setVisible(range >= 9.5 and range < 99.5 and aptVisible);

        var txScale = 10 / range * 444 / 127;
        me.terrainViz.setTranslation(512 - 444 * 10 / range, 530 - 444 * 10 / range);
        me.terrainViz.setScale(txScale, txScale);
        var fmt = "%2.0f";
        if (range < 20)
            fmt = "%3.1f";
        
        me.updateRadarScale(range);
        me.updateGreenArc();
        me.updateVnavFlightplan();

        var halfRangeTxt = sprintf(fmt, range / 2);
        me.elems['arc.range.left'].setText(halfRangeTxt);
        me.elems['arc.range.right'].setText(halfRangeTxt);
        me.elems['plan.range'].setText(halfRangeTxt);
        if (me.props['page'].getValue() == 1) {
            # Plan mode
            me.elems['vnav.range.left.digital'].setText(halfRangeTxt);
            me.elems['vnav.range.right.digital'].setText(halfRangeTxt);
        }
        else {
            me.elems['vnav.range.center.digital'].setText(halfRangeTxt);
        }
    },

    updateVnavFlightplan: func() {
        var profile = fms.vnav.profile;
        var elem = me.elems['vnav-flightplan'];
        var pathElem = me.elems['vnav-flightplan.path'];
        var wpElem = me.elems['vnav-flightplan.waypoints'];

        var fp = fms.getVisibleFlightplan();

        if (fp == nil or profile == nil or size(profile.waypoints) == 0) {
            pathElem.reset();
            elem.hide();
        }
        else {
            var progress = me.props['route-progress'].getValue();
            var range = me.props['range'].getValue();
            var zoom = 720.0 / range;
            var trX = func(dist) { return 220 + dist * zoom; };
            var trY = func(alt) { return 1266 - alt * 0.04; };

            var drawWaypoint = func (name, dist, alt) {
                var group = wpElem.createChild("group");

                var path =
                        group.createChild("path")
                            .setStrokeLineWidth(3)
                            .moveTo(0,-25)
                            .lineTo(-5,-5)
                            .lineTo(-25,0)
                            .lineTo(-5,5)
                            .lineTo(0,25)
                            .lineTo(5,5)
                            .lineTo(25,0)
                            .lineTo(5,-5)
                            .setColor(1,0,1)
                            .close();

                var text =
                        group.createChild("text")
                            .setText(name)
                            .setAlignment('left-bottom')
                            .setFontSize(28)
                            .setColor(1,0,1)
                            .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                            .setTranslation(25, 35);
                group.setTranslation(trX(dist), trY(alt));
            };

            wpElem.removeAllChildren();
            for (var i = 0; i < fp.getPlanSize(); i += 1) {
                var wp = fp.getWP(i);
                var alt = fms.vnav.nominalProfileAltAt(wp.distance_along_route);
                drawWaypoint(wp.id, wp.distance_along_route, alt);
            };

            var wp = profile.waypoints[0];
            var prevDist = 0.0;
            var prevAlt = 0.0;
            pathElem.reset();
            pathElem.moveTo(trX(wp.dist), trY(wp.alt));
            prevDist = wp.dist;
            prevAlt = wp.alt;
            for (var i = 1; i < size(profile.waypoints); i += 1) {
                wp = profile.waypoints[i];
                var dist = wp.dist;
                if (dist == nil) {
                    var dalt = math.abs(wp.alt - prevAlt);
                    # Wild guess for an average climb:
                    # - 300 knots ground speed
                    # - 2000 fpm
                    # Factor 60 because knots is per hour but fpm is per minute
                    dist = prevDist + dalt * 300 / 60 / 2000;
                }
                pathElem.lineTo(trX(dist), trY(wp.alt));
                prevDist = dist;
                prevAlt = wp.alt;
            }
            elem.show();
        }
    },

    setVnavVerticalScroll: func(vertical) {
        # crop to range of vertical scale
        vertical = math.min(34000, math.max(-2000, vertical));

        # map 1000 ft steps to 40 px
        me.elems['vnav.vertical'].setTranslation(0, vertical * 0.04);
    },

    touch: func(args) {
        var x = args.x * 1024;
        var y = 1560 - args.y * 1560;

        me.props['cursor.x'].setValue(x);
        me.props['cursor.y'].setValue(y);

        var activeCond = nil;
        forindex(var i; me.widgets) {
            if (me.widgets[i]['visible'] == 0) {
                continue;
            }
            activeCond = me.widgets[i]['active'];
            if (isfunc(activeCond) and !activeCond()) {
                continue;
            }
            var box = me.widgets[i].box;
            if (x >= box[0] and x <= box[2] and
                y >= box[1] and y <= box[3]) {
                var f = me.widgets[i].ontouch;
                if (f != nil) {
                    f();
                    break;
                }
            }
        }
    },

    adjustProp: func (key, delta, min, max) {
        var prop = me.props[key];
        prop.setValue(math.min(max, math.max(min, prop.getValue() + delta)));
    },

    # direction: -1 = decrease, 1 = increase
    # knob: 0 = outer ring, 1 = inner ring
    scroll: func(direction, knob=0) {
        var page = me.props['page'].getValue();
        if (page == 0) {
            # map mode
            if (knob == 0) {
                # range
                me.zoom(direction);
            }
            else if (knob == 1) {
                if (me.elems['weatherMenu'].getVisible()) {
                    # WX gain
                    me.adjustProp('wx-gain', direction, 0, 100);
                }
                else {
                    # WX tilt
                    me.adjustProp('wx-tilt', direction, -15, 15);
                }
            }
        }
        else if (page == 1) {
            # plan mode
            if (knob == 0) {
                # range
                me.zoom(direction);
            }
            else {
                me.movePlanWpt(direction);
            }
        }
        else {
            # systems mode
        }
    },

    zoom: func (direction) {
        var range = me.props['range'].getValue();
        var ranges = [2, 5, 10, 20, 50, 100, 200, 500, 1000];
        var i = 0;
        forindex (var j; ranges) {
            if (range <= ranges[j]) {
                i = j;
                break;
            }
        }
        range = ranges[math.max(0, math.min(size(ranges)-1, i + direction))];
        me.props['range'].setValue(range);
    },

    updatePlanWPT: func () {
        var fp = fms.getVisibleFlightplan();
        var wp = nil;
        var (lat,lon) = geo.aircraft_position().latlon();

        if (fp == nil) {
            # No flightplan
            wp = nil;
        }
        else {
            wp = fp.getWP(me.planIndex)
        }
        if (wp != nil) {
            lat = wp.lat;
            lon = wp.lon;
        }
        me.plan.controller.setPosition(lat, lon);
    },

    movePlanWpt: func (direction) {
        var fp = fms.getVisibleFlightplan();
        me.planIndex += direction;
        if (me.planIndex < 0) {
            me.planIndex = 0;
        }
        if (fp == nil) {
            me.planIndex = 0;
        }
        else if (me.planIndex >= fp.getPlanSize()) {
            me.planIndex = fp.getPlanSize() - 1;
        }
        me.updatePlanWPT();
    },

    touchMap: func () {
        if (me.props['page'].getValue() == 0) {
            me.elems['mapMenu'].toggleVisibility();
        }
        else {
            me.props['page'].setValue(0);
        }
    },

    touchPlan: func () {
       me.props['page'].setValue(1);
    },

    touchSystems: func () {
       me.props['page'].setValue(2);
    },

    toggleMapCheckbox: func (which) {
        me.props['show-' ~ which].toggleBoolValue();
    },

    toggleWeatherCheckbox: func (which) {
        var prop = me.props[which];
        if (prop != nil) {
            prop.toggleBoolValue();
        }
    },


    selectUnderlay: func (which) {
        me.elems['radioWeather'].setVisible(which == 'WX');
        me.elems['weather.master'].setVisible(which == 'WX');
        me.radarViz.setVisible(which == 'WX');

        me.elems['radioTerrain'].setVisible(which == 'TERRAIN');
        me.elems['terrain.master'].setVisible(which == 'TERRAIN');
        me.terrainViz.setVisible(which == 'TERRAIN');

        me.elems['radioOff'].setVisible(which == nil);
    },

    setWxMode: func (mode=nil) {
        if (mode == nil) {
            mode = me.props['wx-mode-sel'].getValue();
        }
        else {
            me.props['wx-mode-sel'].setValue(mode);
        }
        me.elems['weatherMenu.radioGMAP'].setVisible(mode == 3);
        me.elems['weatherMenu.radioWX'].setVisible(mode == 2);
        me.elems['weatherMenu.radioSTBY'].setVisible(mode == 1);
        me.elems['weatherMenu.radioOff'].setVisible(mode == 0);
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

    updatePage: func() {
        var page = me.props['page'].getValue();
        if (page == 0) {
            # Arc ("Map")
            me.elems['arc.master'].show();
            me.map.show();
            me.elems['plan.master'].hide();
            me.underlay.show();
            me.plan.hide();
            me.elems['vnav.range.left'].hide();
            me.elems['vnav.range.left.digital'].hide();
            me.elems['vnav.range.right'].hide();
            me.elems['vnav.range.right.digital'].hide();
            me.elems['vnav.range.center'].show();
            me.elems['vnav.range.center.digital'].show();
            var viz = me.props['show-tcas'].getBoolValue();
            me.trafficGroup.setVisible(viz);
        }
        else if (page == 1) {
            # Plan
            me.elems['arc.master'].hide();
            me.map.hide();
            me.elems['plan.master'].show();
            me.underlay.hide();
            me.plan.show();
            me.elems['mapMenu'].hide();
            me.elems['weatherMenu'].hide();
            me.elems['vnav.range.left'].show();
            me.elems['vnav.range.left.digital'].show();
            me.elems['vnav.range.right'].show();
            me.elems['vnav.range.right.digital'].show();
            me.elems['vnav.range.center'].hide();
            me.elems['vnav.range.center.digital'].hide();
            me.trafficGroup.setVisible(0);
        }
        else {
            # Systems
            me.elems['arc.master'].hide();
            me.map.hide();
            me.elems['plan.master'].hide();
            me.underlay.hide();
            me.plan.hide();
            me.elems['mapMenu'].hide();
            me.elems['weatherMenu'].hide();
            me.elems['vnav.range.left'].hide();
            me.elems['vnav.range.left.digital'].hide();
            me.elems['vnav.range.right'].hide();
            me.elems['vnav.range.right.digital'].hide();
            me.elems['vnav.range.center'].show();
            me.elems['vnav.range.center.digital'].show();
            me.trafficGroup.setVisible(0);
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
        me.terrainViz.setRotation(heading * -DC);
        me.elems['heading.digital'].setText(sprintf("%03.0f", heading));
        var windDir = me.props['wind-dir'].getValue();
        if (me.props['page'].getValue() != 1) {
            # if not in Plan view, show wind dir relative to current heading
            windDir -= me.props['heading-mag'].getValue();
        }
        me.elems['wind.arrow'].setRotation(windDir * DC);
        me.elems['wind.digital'].setText(sprintf("%2.0f", me.props['wind-speed'].getValue()));
        me.elems['tat.digital'].setText(sprintf("%3.0f", me.props['tat'].getValue()));
        me.elems['sat.digital'].setText(sprintf("%3.0f", me.props['sat'].getValue()));
        me.elems['tas.digital'].setText(sprintf("%3.0f", me.props['tas'].getValue()));
        if (me.showFMSTarget) {
            var dist = me.props['wp-dist'].getValue();
            me.elems['nav.target.dist'].setText(me.formatDist(dist));

            var ete = me.props['wp-ete'].getValue();
            var eteStr = '---';
            if (ete != nil) {
                eteStr = sprintf("%3.0f", ete / 60.0);
            }
            me.elems['nav.target.ete'].setText(eteStr);
        }
        if (me.props['route-active'].getValue()) {
            var now = me.props['zulutime'].getValue();
            var fp = fms.getVisibleFlightplan();
            var nextEFOB = nil;
            var destEFOB = nil;
            if (fp != nil and fms.performanceProfile != nil) {
                var wpi = fp.current;
                var dsti = fms.performanceProfile.destRunwayIndex;
                if (wpi >= 0 and wpi < size(fms.performanceProfile.estimated)) {
                    nextEFOB = fms.performanceProfile.estimated[wpi].fob;
                }
                if (dsti != nil and dsti < size(fms.performanceProfile.estimated)) {
                    destEFOB = fms.performanceProfile.estimated[dsti].fob;
                }
            }

            me.elems['next.dist'].setText(me.formatDist(me.props['wp-dist'].getValue()));
            var wpETE = me.props['wp-ete'].getValue();
            if (wpETE != nil and wpETE > 86400) {
                me.elems['next.eta'].setText('+++++');
            }
            else {
                me.elems['next.eta'].setText(mcdu.formatZulu(now + (me.props['wp-ete'].getValue() or 0)));
            }
            me.elems['next.wpt'].setText(me.props['wp-id'].getValue() or '---');
            if (nextEFOB != nil) {
                me.elems['next.fuel'].setText(sprintf("%5.0f", nextEFOB));
            }
            else {
                me.elems['next.fuel'].setText('-----');
            }

            me.elems['dest.dist'].setText(me.formatDist(me.props['dest-dist'].getValue()));
            var destETE = me.props['dest-ete'].getValue();
            if (destETE != nil and destETE > 86400) {
                me.elems['dest.eta'].setText('+++++');
            }
            else {
                me.elems['dest.eta'].setText(mcdu.formatZulu(now + (me.props['dest-ete'].getValue() or 0)));
            }
            me.elems['dest.wpt'].setText(me.props['dest-id'].getValue() or '---');
            if (destEFOB != nil) {
                me.elems['dest.fuel'].setText(sprintf("%5.0f", destEFOB));
            }
            else {
                me.elems['dest.fuel'].setText('-----');
            }
        }

        var alt = me.props['altitude'].getValue();
        me.mapCamera.repositon(geo.aircraft_position(), heading);
        me.trafficLayer.setRefAlt(alt);
        if (me.trafficGroup.getVisible()) {
            me.trafficLayer.update();
            me.trafficLayer.redraw();
        }

        var salt = me.props['altitude-selected'].getValue();
        var range = me.props['range'].getValue();
        var latZoom = 720.0 / range;
        var page = me.props['page'].getValue();
        var progress = me.props['route-progress'].getValue();
        var progress = me.props['route-progress'].getValue();
        var alt = me.props['altitude'].getValue();
        var vs = me.props['vs'].getValue();
        var gspd = me.props['groundspeed'].getValue();
        var talt = alt;
        if (gspd > 40) {
            talt = alt + vs * 60 / gspd * range;
        }

        if (gspd > 40) {
            me.elems['vnav-flightpath']
                .reset()
                .moveTo(220 + progress * latZoom,  1266 - alt * 0.04)
                .lineTo(220 + (progress + range) * latZoom, 1266 - talt * 0.04)
                .show();
        }
        else {
            me.elems['vnav-flightpath'].hide();
        }
        if (page == 1) {
            # Plan mode
            var fp = fms.getVisibleFlightplan();
            var wpi = me.planIndex == nil ? 0 : me.planIndex;

            if (fp == nil or wpi > fp.getPlanSize()) {
                me.setVnavVerticalScroll(0);
                me.elems['vnav.lateral'].setTranslation(0, 0.0);
            }
            else {
                var wp = fp.getWP(wpi);
                var wpAlt = fms.vnav.nominalProfileAltAt(wp.distance_along_route);
                me.setVnavVerticalScroll(wpAlt - 5000);
                me.elems['vnav.lateral'].setTranslation((0.5 * range - wp.distance_along_route) * latZoom, 0.0);
            }
        }
        else {
            # Map or Systems mode: put aircraft to the left, and scroll to
            # current lateral position
            var delta = 0.5 * (salt - alt);
            if (delta > 4000) { delta = 4000; }
            if (delta < -4000) { delta = -4000; }
            me.setVnavVerticalScroll(alt + delta - 5000);
            me.elems['vnav.lateral'].setTranslation(-progress * latZoom, 0.0);
        }
        me.elems['vnav.aircraft.symbol'].setTranslation(progress * latZoom, -alt * 0.04);
    },

    formatDist: func(dist) {
        var distStr = '----';
        if (dist != nil) {
            var distFmt = "%4.1f";
            if (dist >= 50.0) {
                distFmt = "%4.0f";
            }
            distStr = sprintf(distFmt, dist);
        }
        return distStr;
    },
};

var path = resolvepath('Aircraft/E-jet-family/Models/Primus-Epic/MFD');
# canvas.MapStructure.loadFile(path ~ '/TFC-Ejet.lcontroller', 'TFC-Ejet');
# canvas.MapStructure.loadFile(path ~ '/TFC-Ejet.symbol', 'TFC-Ejet');

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
