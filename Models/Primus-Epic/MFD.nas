# E-Jet Family MFD
#
# AOM references:
# - TCAS mode: p. 2157

var initialized = 0;
var mfd_display = [nil, nil];
var mfd_master = [nil, nil];
var mfd = [nil, nil];
var DC = 0.01744;
var sin30 = math.sin(30 * D2R);
var cos30 = math.cos(30 * D2R);

var noTakeoffBrakeTemp = 300.0;

var SUBMODE_STATUS = 0;
var SUBMODE_ELECTRICAL = 1;
var SUBMODE_FUEL = 2;
var SUBMODE_FLIGHT_CONTROLS = 3;

var submodeNames = [
    'Status',
    'Elec',
    'Fuel',
    'FltCtl',
];

var currentFile = os.path.new(caller(0)[2]);
canvas.MapStructure.loadFile(
    currentFile.dir ~ '/MFD/aircraftpos-ejet.controller',
    'aircraftpos-ejet');

var toggleBoolProp = func(node) {
    if (node != nil) { node.toggleBoolValue(); }
};

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
};

# Set fill color for electrical and hydraulic nodes for a given status.
# Status 0 is "off", rendered in white.
# Status 1 is "live", rendered in bright green.
# All other statuses default to 0 (white).
var fillColorByStatus = func (target, status) {
    if (status == 0) {
        target.setColorFill(1, 1, 1);
    }
    else if (status == 1) {
        target.setColorFill(0, 1, 0);
    }
    else {
        target.setColorFill(1, 1, 0);
    }
};

# Set fill color for electrical and hydraulic connections depending on their
# status.
# Status 0 is "off", rendered in 25% gray.
# Status 1 is "live", rendered in bright green.
# All other statuses default to 1 (green).
var fillIfConnected = func (target, status) {
    if (status) {
        target.setColorFill(0, 1, 0);
    }
    else {
        target.setColorFill(0.25, 0.25, 0.25);
    }
}

var clipTo = func (clippee, clipper) {
    if (clipper != nil) {
        var bounds = clipper.getTransformedBounds();
        var boundsFmt = sprintf("rect(%d,%d, %d,%d)",
                            bounds[1], # 0 ys
                            bounds[2], # 1 xe
                            bounds[3], # 2 ye
                            bounds[0]); #3 xs
        # coordinates are top,right,bottom,left (ys, xe, ye, xs)
        # ref: l621 of simgear/canvas/CanvasElement.cxx
        clippee.set("clip", boundsFmt);
        clippee.set("clip-frame", canvas.Element.PARENT);
    }
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
    new: func(side = 0) {
        var m = canvas_base.BaseScreen.new(side, 1);
        m.parents = [MFD] ~ m.parents;
        return m;
    },

    registerProps: func () {
        call(canvas_base.BaseScreen.registerProps, [], me);
        me.registerProp('cursor', "/instrumentation/mfd[" ~ me.side ~ "]/cursor");
        me.registerProp('cursor.x', "/instrumentation/mfd[" ~ me.side ~ "]/cursor/x");
        me.registerProp('cursor.y', "/instrumentation/mfd[" ~ me.side ~ "]/cursor/y");
        me.registerProp('cursor.visible', "/instrumentation/mfd[" ~ me.side ~ "]/cursor/visible");

        me.registerProp('page', '/instrumentation/mfd[' ~ me.side ~ ']/page');
        me.registerProp('submode', '/instrumentation/mfd[' ~ me.side ~ ']/submode');
        me.registerProp('altitude-amsl', '/position/altitude-ft');
        me.registerProp('altitude', '/instrumentation/altimeter/indicated-altitude-ft');
        me.registerProp('altitude-selected', '/controls/flight/selected-alt');
        me.registerProp('altitude-target', '/it-autoflight/input/alt');
        me.registerProp('heading', '/orientation/heading-deg');
        me.registerProp('valid-att', "/instrumentation/iru[" ~ me.side ~ "]/outputs/valid-att");
        me.registerProp('valid-nav', "/instrumentation/iru[" ~ me.side ~ "]/outputs/valid");
        me.registerProp('heading-mag', '/orientation/heading-magnetic-deg');
        me.registerProp('track', '/orientation/track-deg');
        me.registerProp('track-mag', '/orientation/track-magnetic-deg');
        me.registerProp('heading-bug', '/it-autoflight/input/hdg');
        me.registerProp('tas', '/instrumentation/airspeed-indicator/true-speed-kt');
        me.registerProp('ias', '/instrumentation/airspeed-indicator/indicated-speed-kt');
        me.registerProp('sat', '/environment/temperature-degc');
        me.registerProp('tat', '/fdm/jsbsim/propulsion/tat-c');
        me.registerProp('wind-dir', "/environment/wind-from-heading-deg");
        me.registerProp('wind-speed', "/environment/wind-speed-kt");
        me.registerProp('groundspeed', "/velocities/groundspeed-kt");
        me.registerProp('vs', "/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
        me.registerProp('latitude', "/instrumentation/iru[" ~ me.side ~ "]/outputs/latitude-deg");
        me.registerProp('longitude', "/instrumentation/iru[" ~ me.side ~ "]/outputs/longitude-deg");
        me.registerProp('nav-src', "/instrumentation/pfd[" ~ me.side ~ "]/nav-src");
        me.registerProp('nav-id', ['/instrumentation/nav[0]/nav-id', '/instrumentation/nav[1]/nav-id']);
        me.registerProp('nav-loc', ['/instrumentation/nav[0]/nav-loc', '/instrumentation/nav[1]/nav-loc']);
        me.registerProp('route-active', "/autopilot/route-manager/active");
        me.registerProp('wp-dist', "/autopilot/route-manager/wp/dist");
        me.registerProp('wp-ete', "/autopilot/route-manager/wp/eta-seconds");
        me.registerProp('wp-id', "/autopilot/route-manager/wp/id");
        me.registerProp('wp-next-dist', "/autopilot/route-manager/wp[1]/dist");
        me.registerProp('wp-next-ete', "/autopilot/route-manager/wp[1]/eta-seconds");
        me.registerProp('wp-next-id', "/autopilot/route-manager/wp[1]/id");
        me.registerProp('dest-dist', "/autopilot/route-manager/distance-remaining-nm");
        me.registerProp('dest-ete', "/autopilot/route-manager/ete");
        me.registerProp('dest-id', "/autopilot/route-manager/destination/airport");
        me.registerProp('zulutime', "/instrumentation/clock/indicated-sec");
        me.registerProp('zulu-hour', "/sim/time/utc/hour");
        me.registerProp('zulu-minute', "/sim/time/utc/minute");
        me.registerProp('range', "/instrumentation/mfd[" ~ me.side ~ "]/lateral-range");
        me.registerProp('tcas-mode', "/instrumentation/tcas/inputs/mode");
        me.registerProp('wx-sweep-angle', "/instrumentation/wxr/sweep-pos-deg");
        me.registerProp('wx-sweep-me.side', "/instrumentation/wxr/scan-pos");
        me.registerProp('wx-range', "/instrumentation/wxr/range-nm");
        me.registerProp('wx-mode', "/instrumentation/wxr/mode");
        me.registerProp('wx-mode-sel', "/instrumentation/mfd[" ~ me.side ~ "]/wx-mode");
        me.registerProp('wx-mode-indicated', "/instrumentation/mfd[" ~ me.side ~ "]/wx-mode-indicated");
        me.registerProp('wx-gain', "/instrumentation/wxr/gain");
        me.registerProp('wx-tilt', "/instrumentation/wxr/tilt-angle-deg");
        me.registerProp('wx-sect', "/instrumentation/wxr/sector-scan");
        me.registerProp('wx-turb', "/instrumentation/wxr/turb");
        me.registerProp('wx-lx', "/instrumentation/wxr/lx");
        me.registerProp('wx-act', "/instrumentation/wxr/act");
        me.registerProp('wx-rct', "/instrumentation/wxr/rct");
        me.registerProp('wx-tgt', "/instrumentation/wxr/tgt");
        me.registerProp('wx-fsby-ovrd', "/instrumentation/wxr/fstby-ovrd");
        me.registerProp('green-arc-dist', "/fms/dist-to-alt-target-nm");
        me.registerProp('route-progress', "/fms/vnav/route-progress");

        # TODO: separate property for this
        me.registerProp('flight-id', "/sim/multiplay/callsign");
        me.registerProp('gross-weight', "/fms/fuel/gw-kg");
        me.registerProp('brake-temp-0', "/gear/gear[1]/brakes/brake[0]/temperature-c");
        me.registerProp('brake-temp-1', "/gear/gear[1]/brakes/brake[1]/temperature-c");
        me.registerProp('brake-temp-2', "/gear/gear[2]/brakes/brake[0]/temperature-c");
        me.registerProp('brake-temp-3', "/gear/gear[2]/brakes/brake[1]/temperature-c");
        me.registerProp('resolution', "instrumentation/mfd[" ~ me.side ~ "]/resolution");
        me.registerProp('scan-rate', "instrumentation/mfd[" ~ me.side ~ "]/scan-rate");

        me.registerProp('elevator-law', "fbw/elevator/law");
        me.registerProp('rudder-law', "fbw/rudder/law");
        me.registerProp('spoilers-law', "fbw/spoilers/law");
        me.registerProp('aileron-left', "surface-positions/left-aileron-pos-norm");
        me.registerProp('aileron-right', "surface-positions/right-aileron-pos-norm");
        me.registerProp('rudder', "surface-positions/rudder-pos-norm");
        me.registerProp('elevator', "surface-positions/elevator-pos-norm");
        me.registerProp('mfs1',  "fdm/jsbsim/fcs/mfs1-pos-norm");
        me.registerProp('mfs2',  "fdm/jsbsim/fcs/mfs2-pos-norm");
        me.registerProp('mfs3',  "fdm/jsbsim/fcs/mfs3-pos-norm");
        me.registerProp('mfs4',  "fdm/jsbsim/fcs/mfs4-pos-norm");
        me.registerProp('mfs5',  "fdm/jsbsim/fcs/mfs5-pos-norm");
        me.registerProp('mfs6',  "fdm/jsbsim/fcs/mfs6-pos-norm");
        me.registerProp('mfs7',  "fdm/jsbsim/fcs/mfs7-pos-norm");
        me.registerProp('mfs8',  "fdm/jsbsim/fcs/mfs8-pos-norm");
        me.registerProp('mfs9',  "fdm/jsbsim/fcs/mfs9-pos-norm");
        me.registerProp('mfs10', "fdm/jsbsim/fcs/mfs10-pos-norm");

        var masterProp = props.globals.getNode("/instrumentation/mfd[" ~ me.side ~ "]");
        foreach (var key; ['show-navaids', 'show-airports', 'show-wpt', 'show-progress', 'show-missed', 'show-tcas']) {
            var node = masterProp.addChild(key);
            node.setBoolValue(0);
            me.registerProp(key, node);
        }
    },

    # makeMasterGroup: func (group) {
    #     call(canvas_base.BaseScreen.makeMasterGroup, [group], me);
    #     canvas.parsesvg(group, "Aircraft/E-jet-family/Models/Primus-Epic/MFD.svg", { 'font-mapper': me.font_mapper });
    # },

    makeGroups: func () {
        var self = me;

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

        # Set up MAP/PLAN page
        me.dualRouteDriver = RouteDriver.new();
        me.plannedRouteDriver = RouteDriver.new(0);

        me.vnav = me.lowerArea.createChild("group");
        canvas.parsesvg(me.vnav, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-vnav.svg", {'font-mapper': me.font_mapper});

        me.pageContainer = me.upperArea.createChild("group");

        me.systemsContainer = me.pageContainer.createChild("group");
        me.systemsPages = {};
        me.systemsPages.status = me.systemsContainer.createChild("group");
        canvas.parsesvg(me.systemsPages.status, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-systems-status.svg", {'font-mapper': me.font_mapper});
        me.systemsPages.electrical = me.systemsContainer.createChild("group");
        canvas.parsesvg(me.systemsPages.electrical, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-systems-electrical.svg", {'font-mapper': me.font_mapper});
        me.systemsPages.fuel = me.systemsContainer.createChild("group");
        canvas.parsesvg(me.systemsPages.fuel, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-systems-fuel.svg", {'font-mapper': me.font_mapper});
        me.systemsPages.flightControls = me.systemsContainer.createChild("group");
        canvas.parsesvg(me.systemsPages.flightControls, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-systems-flight-controls.svg", {'font-mapper': me.font_mapper});

        me.underlay = me.pageContainer.createChild("group");
        me.terrainViz = me.underlay.createChild("image");
        me.terrainViz.set("src", resolvepath("Aircraft/E-jet-family/Models/Primus-Epic/MFD/terrain" ~ me.side ~ ".png"));
        me.terrainViz.setCenter(128, 128);
        me.radarViz = me.underlay.createChild("image");
        me.radarViz.set("src", resolvepath("Aircraft/E-jet-family/Models/Primus-Epic/MFD/radar" ~ me.side ~ ".png"));
        me.radarViz.setCenter(128, 128);
        canvas.parsesvg(me.underlay, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-radar-mask.svg");

        me.mapCamera = mfdmap.Camera.new({
            range: 25,
            screenRange: 416,
            screenCX: 512,
            screenCY: 540,
        });
        me.trafficGroup = me.pageContainer.createChild("group");
        me.trafficLayer = mfdmap.TrafficLayer.new(me.mapCamera, me.trafficGroup);

        me.map = me.pageContainer.createChild("map");
        me.map.set("clip", "rect(0px, 1024px, 740px, 0px)");
        me.map.set("clip-frame", canvas.Element.PARENT);
        me.map.setTranslation(512, 540);
        me.map.setController("Aircraft position EJ", 'iru' ~ me.side);
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

        me.plan = me.pageContainer.createChild("map");
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

        me.mapOverlay = me.pageContainer.createChild("group");
        canvas.parsesvg(me.mapOverlay, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-map.svg", {'font-mapper': me.font_mapper});

        call(canvas_base.BaseScreen.makeGroups, [], me);

        canvas.parsesvg(me.guiOverlay, "Aircraft/E-jet-family/Models/Primus-Epic/MFD-gui.svg", {'font-mapper': me.font_mapper});
    },

    registerListeners: func () {
        call(canvas_base.BaseScreen.registerListeners, [], me);

        var self = me;

        me.addListener('main', "/instrumentation/wxr/sweep-pos-deg", func (node) {
            self.updateRadarViz(node.getValue());
        });
        me.addListener('main', '@wx-range', func () {
            self.updateRadarScale();
        });

        me.addListener('main', me.props['valid-nav'], func (node) {
            if (node.getBoolValue()) {
                self.elems['arc.compass'].show();
                self.elems['arc.track'].show();
                self.elems['heading.digital'].setColor(0, 1, 0);
                self.elems['wind.arrow'].show();
                self.elems['wind.digital'].show();
                self.elems['terrain.status'].setColor(0, 1, 0);
                self.elems['terrain.status'].setText('TERRAIN');
            }
            else {
                self.elems['arc.compass'].hide();
                self.elems['arc.heading-bug'].hide();
                self.elems['arc.heading-bug.arrow-left'].hide();
                self.elems['arc.heading-bug.arrow-right'].hide();
                self.elems['arc.track'].hide();
                self.elems['wind.arrow'].hide();
                self.elems['wind.digital'].hide();
                self.elems['heading.digital'].setColor(1, 0.5, 0);
                self.elems['heading.digital'].setText('---');
                self.elems['terrain.status'].setColor(1, 0.5, 0);
                self.elems['terrain.status'].setText('TERR N/A');
            }
        }, 1, 0);
        me.addListener('main', me.props['wx-gain'], func (node) {
            self.elems['weatherMenu.gain'].setText(sprintf("%3.0f", node.getValue() or 0));
        }, 1, 0);
        me.addListener('main', me.props['wx-tilt'], func (node) {
            self.elems['weather.tilt'].setText(sprintf("%-2.0f", node.getValue() or 0));
        }, 1, 0);
        me.addListener('main', me.props['wx-mode-indicated'], func(node) {
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
        me.addListener('main', me.props['green-arc-dist'], func (node) {
            self.updateGreenArc(node.getValue());
        }, 1, 0);
        me.addListener('main', me.props['wx-sect'], func (node) {
            self.elems['weatherMenu.checkSect'].setVisible(node.getBoolValue());
        }, 1, 0);
        me.addListener('main', '/fms/vnav/available', func () {
            self.updateVnavFlightplan();
        }, 1, 0);
        me.addListener('main', me.props['wx-fsby-ovrd'], func (node) {
            self.elems['weatherMenu.checkFsbyOvrd'].setVisible(node.getBoolValue());
        }, 1, 0);
        me.addListener('main', "/instrumentation/mfd[" ~ me.side ~ "]/lateral-range", func (node) {
            self.setRange(node.getValue());
        }, 1, 0);
        me.addListener('main', me.props['heading-bug'], func (node) {
            self.elems['arc.heading-bug'].setRotation(node.getValue() * DC);
        }, 1, 0);
        me.addListener('main', me.props['track-mag'], func (node) {
            self.elems['arc.track'].setRotation(node.getValue() * DC);
        }, 1, 0);
        me.addListener('main', me.props['nav-src'], func (node) {
            self.updateNavSrc();
        }, 1, 0);
        me.addListener('main', me.props['wp-id'], func (node) {
            self.updateNavSrc();
        }, 0, 0);
        me.addListener('main', "/autopilot/route-manager/active", func {
            self.updatePlanWPT();
            self.updateVnavFlightplan();
        }, 1, 0);
        me.addListener('main',  "/autopilot/route-manager/cruise/altitude-ft", func {
            self.updateVnavFlightplan();
        }, 1, 0);
        me.addListener('main', me.props['page'], func (node) {
            self.updatePage();
        }, 1, 0);
        me.addListener('main', me.props['submode'], func (node) {
            var submode = node.getValue();
            self.elems['btnSystems.mode.label'].setText(submodeNames[submode]);
            self.updateSystemsSubmode(submode);
            self.updatePage();
        }, 1, 0);
        me.addListener('main', me.props['show-navaids'], func (node) {
            var viz = node.getBoolValue();
            self.elems['checkNavaids'].setVisible(viz);
            self.map.layers['NDB'].setVisible(viz);
            self.map.layers['VOR'].setVisible(viz);
        }, 1, 0);
        me.addListener('main', me.props['show-airports'], func (node) {
            var viz = node.getBoolValue();
            var range = me.map.getRange();
            self.elems['checkAirports'].setVisible(viz);
            self.map.layers["RWY"].setVisible(range < 9.5 and viz);
            self.map.layers["APT"].setVisible(range >= 9.5 and range < 99.5 and viz);
        }, 1, 0);
        me.addListener('main', me.props['show-wpt'], func (node) {
            var viz = node.getBoolValue();
            self.elems['checkWptIdent'].setVisible(viz);
            self.map.layers['WPT'].setVisible(viz);
        }, 1, 0);
        me.addListener('main', me.props['show-progress'], func (node) {
            var viz = node.getBoolValue();
            self.elems['checkProgress'].setVisible(viz);
            self.elems['progress.master'].setVisible(viz);
        }, 1, 0);
        me.addListener('main', me.props['show-missed'], func (node) {
            var viz = node.getBoolValue();
            self.elems['checkMissedAppr'].setVisible(viz);
            # TODO: toggle missed approach display
        }, 1, 0);
        me.addListener('main', me.props['show-tcas'], func (node) {
            var viz = node.getBoolValue();
            self.elems['checkTCAS'].setVisible(viz);
            self.elems['tcas.master'].setVisible(viz);
            self.trafficGroup.setVisible(viz);
            if (viz)
                self.trafficLayer.start();
            else
                self.trafficLayer.stop();
            # self.map.layers['TFC-Ejet'].setVisible(viz);
        }, 1, 0);
        me.addListener('main', me.props['tcas-mode'], func (node) {
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
        me.addListener('main', me.props['altitude-selected'], func (node) {
            var alt = node.getValue();
            var offset = -alt * 0.04;
            self.elems['vnav.selectedalt'].setTranslation(0, offset);
        }, 1, 0);

    },

    postInit: func () {
        var self = me;
        me.timerFast = maketimer(0.1, func() { self.update(); });
        me.timerSlow = maketimer(1.0, func() { self.update(); });
        me.terrainTimer = maketimer(0.1, func { self.updateTerrainViz(); });
        me.terrainTimer.simulatedTime = 1;

        # Hide extra stuff when not Lineage 1000
        if (getprop('/sim/aircraft') == 'EmbraerLineage1000') {
        }
        else {
            me.elems['fuel.tank3.group'].hide();
        }
    },

    preActivate: func () {
        me.txRadarScanX = 0;
        me.lastRadarSweepAngle = -60;
        me.showFMSTarget = 1;
        me.selectUnderlay(nil);
        me.setWxMode(nil);
    },

    postActivate: func () {
        var self = me;

        me.timerFast.start();
        me.timerSlow.start();
        me.terrainTimer.start();
    },

    preDeactivate: func {
        me.terrainTimer.stop();
        me.timerFast.stop();
        me.timerSlow.stop();
    },

    registerElems: func () {
        call(canvas_base.BaseScreen.registerElems, [], me);
        var mapkeys = [
                'arc',
                'arc.compass',
                'arc.compass.ring',
                'arc.heading-bug',
                'arc.heading-bug.arrow-left',
                'arc.heading-bug.arrow-right',
                'arc.master',
                'arc.range.left',
                'arc.range.right',
                'arc.track',
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
                'terrain.status',
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
                'submodeMenu',
                'checkNavaids',
                'checkAirports',
                'checkWptIdent',
                'checkProgress',
                'checkMissedAppr',
                'checkTCAS',
                'radioWeather',
                'radioTerrain',
                'radioOff',

                'btnSystems.mode.label',

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
        var systemskeys = [
                'status.battery1.voltage.digital',
                'status.battery2.voltage.digital',
                'status.brake-pressure.left.digital',
                'status.brake-pressure.left.pointer',
                'status.brake-pressure.right.digital',
                'status.brake-pressure.right.pointer',
                'status.brake-temp.left-ib.digital',
                'status.brake-temp.left-ib.pointer',
                'status.brake-temp.left-ob.digital',
                'status.brake-temp.left-ob.pointer',
                'status.brake-temp.right-ib.digital',
                'status.brake-temp.right-ib.pointer',
                'status.brake-temp.right-ob.digital',
                'status.brake-temp.right-ob.pointer',
                'status.clock.hours',
                'status.clock.minutes',
                'status.crew-oxy-press.digital',
                'status.doors.avionics-front',
                'status.doors.avionics-mid',
                'status.doors.cargo1',
                'status.doors.cargo2',
                'status.doors.l1',
                'status.doors.r1',
                'status.doors.fuel-panel',
                'status.doors.l3',
                'status.doors.r3',
                'status.doors.l2',
                'status.doors.r2',
                'status.doors.water',
                'status.flightid',
                'status.grossweight.digital',
                'status.oil-level.left.digital',
                'status.oil-level.left.pointer',
                'status.oil-level.right.digital',
                'status.oil-level.right.pointer',
                'status.sat.digital',
                'status.tat.digital',


                'elec.feed.ac1-ac12',
                'elec.feed.ac1-idg1',
                'elec.feed.ac12',
                'elec.feed.ac12-acgpu',
                'elec.feed.ac12-apu',
                'elec.feed.ac2-ac12',
                'elec.feed.ac2-idg2',
                'elec.feed.acess-ac1',
                'elec.feed.acess-ac2',
                'elec.feed.acess-rat',
                'elec.feed.acstby-acess',
                'elec.feed.apustart-batt2',
                'elec.feed.apustart-dcgpu',
                'elec.feed.dc1-tru1',
                'elec.feed.dc12',
                'elec.feed.dc2-tru2',
                'elec.feed.dcess1-batt1',
                'elec.feed.dcess1-dc1',
                'elec.feed.dcess1-dcess3',
                'elec.feed.dcess2-batt2',
                'elec.feed.dcess2-dc2',
                'elec.feed.dcess2-dcess3',
                'elec.feed.dcess3-truess',
                'elec.feed.dcess3-truess-mask',
                'elec.feed.tru1-ac1',
                'elec.feed.tru2-ac2',
                'elec.feed.truess-acess',

                'elec.ac1.symbol',
                'elec.ac2.symbol',
                'elec.acess.symbol',
                'elec.acgpu.group',
                'elec.acgpu.hz.digital',
                'elec.acgpu.kva.digital',
                'elec.acgpu.symbol',
                'elec.acgpu.volts.digital',
                'elec.acstby.symbol',
                'elec.apu.hz.digital',
                'elec.apu.kva.digital',
                'elec.apu.group',
                'elec.apu.symbol',
                'elec.apu.volts.digital',
                'elec.apustart.symbol',
                'elec.battery1.symbol',
                'elec.battery1.temp.digital',
                'elec.battery1.volts.digital',
                'elec.battery2.symbol',
                'elec.battery2.temp.digital',
                'elec.battery2.volts.digital',
                'elec.dc1.symbol',
                'elec.dc2.symbol',
                'elec.dcess1.symbol',
                'elec.dcess2.symbol',
                'elec.dcess3.symbol',
                'elec.dcgpu.group',
                'elec.dcgpu.inuse',
                'elec.dcgpu.symbol',
                'elec.rat.group',
                'elec.rat.volts.digital',
                'elec.rat.hz.digital',
                'elec.rat.symbol',
                'elec.idg1.hz.digital',
                'elec.idg1.kva.digital',
                'elec.idg1.symbol',
                'elec.idg1.volts.digital',
                'elec.idg2.hz.digital',
                'elec.idg2.kva.digital',
                'elec.idg2.symbol',
                'elec.idg2.volts.digital',
                'elec.tru1.symbol',
                'elec.tru1.volts.digital',
                'elec.tru2.symbol',
                'elec.tru2.volts.digital',
                'elec.truess.symbol',
                'elec.truess.volts.digital',

                'fuel.apu.symbol',
                'fuel.crossfeed.mode',
                'fuel.line.apu',
                'fuel.line.engineL',
                'fuel.line.engineR',
                'fuel.line.tankL',
                'fuel.line.tankR',
                'fuel.line.epump1',
                'fuel.line.epump2',
                'fuel.line.acpump1',
                'fuel.line.acpump2',
                'fuel.line.acpump3',
                'fuel.line.dcpump',
                'fuel.pump.ac1',
                'fuel.pump.ac2',
                'fuel.pump.ac3',
                'fuel.pump.dc',
                'fuel.pump.e1',
                'fuel.pump.e2',
                'fuel.temp.digital',
                'fuel.total.digital',
                'fuel.used.digital',
                'fuel.valve.apu',
                'fuel.valve.crossfeed',
                'fuel.valve.cutoffL',
                'fuel.valve.cutoffR',
                'fuel.quantityL.digital',
                'fuel.quantityL.unit',
                'fuel.quantityL.pointer',
                'fuel.quantityR.digital',
                'fuel.quantityR.unit',
                'fuel.quantityR.pointer',
                'fuel.quantityC.digital',
                'fuel.quantityC.unit',
                'fuel.quantityC.pointer',
                'fuel.tank3.group',

                # flight controls: AOM p 1644
                # display: AOM p 1654
                'fctl.aileron-lh-down',
                'fctl.aileron-lh-down.cover',
                'fctl.aileron-lh-down.dashedbox',
                'fctl.aileron-lh-down.stripes',
                'fctl.aileron-lh-up',
                'fctl.aileron-lh-up.cover',
                'fctl.aileron-lh-up.dashedbox',
                'fctl.aileron-lh-up.stripes',
                'fctl.aileron-rh-down',
                'fctl.aileron-rh-down.cover',
                'fctl.aileron-rh-down.dashedbox',
                'fctl.aileron-rh-down.stripes',
                'fctl.aileron-rh-up',
                'fctl.aileron-rh-up.cover',
                'fctl.aileron-rh-up.dashedbox',
                'fctl.aileron-rh-up.stripes',
                'fctl.actuator1.elev-lh.text',
                'fctl.actuator1.elev-rh.text',
                'fctl.actuator2.elev-lh.text',
                'fctl.actuator2.elev-rh.text',
                'fctl.actuator1.rudder.text',
                'fctl.actuator2.rudder.text',
                'fctl.aileron-lh-down',
                'fctl.aileron-lh-down.cover',
                'fctl.aileron-lh-down.dashedbox',
                'fctl.aileron-lh-down.stripes',
                'fctl.aileron-lh-up',
                'fctl.aileron-lh-up.cover',
                'fctl.aileron-lh-up.dashedbox',
                'fctl.aileron-lh-up.stripes',
                'fctl.aileron-rh-down',
                'fctl.aileron-rh-down.cover',
                'fctl.aileron-rh-down.dashedbox',
                'fctl.aileron-rh-down.stripes',
                'fctl.aileron-rh-up',
                'fctl.aileron-rh-up.cover',
                'fctl.aileron-rh-up.dashedbox',
                'fctl.aileron-rh-up.stripes',
                'fctl.mode.elev-lh.frame',
                'fctl.mode.elev-lh.text',
                'fctl.mode.elev-rh.frame',
                'fctl.mode.elev-rh.text',
                'fctl.elev-lh-down',
                'fctl.elev-lh-down.cover',
                'fctl.elev-lh-down.dashedbox',
                'fctl.elev-lh-down.stripes',
                'fctl.elev-lh-up',
                'fctl.elev-lh-up.cover',
                'fctl.elev-lh-up.dashedbox',
                'fctl.elev-lh-up.stripes',
                'fctl.elev-rh-down',
                'fctl.elev-rh-down.cover',
                'fctl.elev-rh-down.dashedbox',
                'fctl.elev-rh-down.stripes',
                'fctl.elev-rh-up',
                'fctl.elev-rh-up.cover',
                'fctl.elev-rh-up.dashedbox',
                'fctl.elev-rh-up.stripes',
                'fctl.mode.rudder.frame',
                'fctl.mode.rudder.text',
                'fctl.rudder-left',
                'fctl.rudder-left.cover',
                'fctl.rudder-left.dashedbox',
                'fctl.rudder-left.stripes',
                'fctl.rudder-right',
                'fctl.rudder-right.cover',
                'fctl.rudder-right.dashedbox',
                'fctl.rudder-right.stripes',
                'fctl.mfs1',
                'fctl.mfs1.cover',
                'fctl.mfs1.dashedbox',
                'fctl.mfs1.stripes',
                'fctl.mfs2',
                'fctl.mfs2.cover',
                'fctl.mfs2.dashedbox',
                'fctl.mfs2.stripes',
                'fctl.mfs3',
                'fctl.mfs3.cover',
                'fctl.mfs3.dashedbox',
                'fctl.mfs3.stripes',
                'fctl.mfs4',
                'fctl.mfs4.cover',
                'fctl.mfs4.dashedbox',
                'fctl.mfs4.stripes',
                'fctl.mfs5',
                'fctl.mfs5.cover',
                'fctl.mfs5.dashedbox',
                'fctl.mfs5.stripes',
                'fctl.mfs6',
                'fctl.mfs6.cover',
                'fctl.mfs6.dashedbox',
                'fctl.mfs6.stripes',
                'fctl.mfs7',
                'fctl.mfs7.cover',
                'fctl.mfs7.dashedbox',
                'fctl.mfs7.stripes',
                'fctl.mfs8',
                'fctl.mfs8.cover',
                'fctl.mfs8.dashedbox',
                'fctl.mfs8.stripes',
                'fctl.mfs9',
                'fctl.mfs9.cover',
                'fctl.mfs9.dashedbox',
                'fctl.mfs9.stripes',
                'fctl.mfs10',
                'fctl.mfs10.cover',
                'fctl.mfs10.dashedbox',
                'fctl.mfs10.stripes',
        ];

        me.registerElemsFrom(mapkeys, me.mapOverlay);
        me.registerElemsFrom(guikeys, me.guiOverlay);
        me.registerElemsFrom(vnavkeys, me.vnav);
        me.registerElemsFrom(systemskeys, me.systemsContainer);

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
        me.elems['arc.track'].setCenter(512, 530);
        me.elems['mapMenu'].hide();
        me.elems['submodeMenu'].hide();
        me.elems['weatherMenu'].hide();

        me.elems['greenarc'] = me.elems['arc.master'].createChild("path");
        me.elems['greenarc'].setStrokeLineWidth(3);
        me.elems['greenarc'].setColor(0, 1, 0, 1);
    },

    makeWidgets: func () {
        call(canvas_base.BaseScreen.makeWidgets, [], me);

        var self = me;

        me.addWidget('btnMap', { onclick: func { self.touchMap(); } });
        me.addWidget('btnPlan', { onclick: func { self.touchPlan(); } });
        me.addWidget('btnSystems.mode', { onclick: func { self.touchSystemsSubmode(); } });
        me.addWidget('btnSystems', { onclick: func { self.touchSystems(); } });
        me.addWidget('btnTCAS', { onclick: func { debug.dump("MFD TCAS menu not implemented yet"); } });
        me.addWidget('btnWeather', { onclick: func { self.elems['weatherMenu'].toggleVisibility(); } });
        me.addWidget('checkNavaids', { active: func { self.elems['mapMenu'].getVisible() }, onclick: func { self.toggleMapCheckbox('navaids'); } });
        me.addWidget('checkAirports', { active: func { self.elems['mapMenu'].getVisible() }, onclick: func { self.toggleMapCheckbox('airports'); } });
        me.addWidget('checkWptIdent', { active: func { self.elems['mapMenu'].getVisible() }, onclick: func { self.toggleMapCheckbox('wpt'); } });
        me.addWidget('checkProgress', { active: func { self.elems['mapMenu'].getVisible() }, onclick: func { self.toggleMapCheckbox('progress'); } });
        me.addWidget('checkMissedAppr', { active: func { self.elems['mapMenu'].getVisible() }, onclick: func { self.toggleMapCheckbox('missed'); } });
        me.addWidget('checkTCAS', { active: func { self.elems['mapMenu'].getVisible() }, onclick: func { self.toggleMapCheckbox('tcas'); } });
        me.addWidget('radioWeather', { active: func { self.elems['mapMenu'].getVisible() }, onclick: func { self.selectUnderlay('WX'); } });
        me.addWidget('radioTerrain', { active: func { self.elems['mapMenu'].getVisible() }, onclick: func { self.selectUnderlay('TERRAIN'); } });
        me.addWidget('radioOff', { active: func { self.elems['mapMenu'].getVisible() }, onclick: func { self.selectUnderlay(nil); } });
        me.addWidget('submodeStatus', { active: func { self.elems['submodeMenu'].getVisible() }, onclick: func { self.selectSystemsSubmode(SUBMODE_STATUS); } });
        me.addWidget('submodeElectrical', { active: func { self.elems['submodeMenu'].getVisible() }, onclick: func { self.selectSystemsSubmode(SUBMODE_ELECTRICAL); } });
        me.addWidget('submodeFuel', { active: func { self.elems['submodeMenu'].getVisible() }, onclick: func { self.selectSystemsSubmode(SUBMODE_FUEL); } });
        me.addWidget('submodeFlightControls', { active: func { self.elems['submodeMenu'].getVisible() }, onclick: func { self.selectSystemsSubmode(SUBMODE_FLIGHT_CONTROLS); } });
        me.addWidget('weatherMenu.radioOff', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.setWxMode(0); } });
        me.addWidget('weatherMenu.radioSTBY', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.setWxMode(1); } });
        me.addWidget('weatherMenu.radioWX', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.setWxMode(2); } });
        me.addWidget('weatherMenu.radioGMAP', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.setWxMode(3); } });
        me.addWidget('weatherMenu.checkSect', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.toggleWeatherCheckbox('wx-sect'); } });
        me.addWidget('weatherMenu.checkStabOff', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.toggleWeatherCheckbox('wx-stab-off'); } });
        me.addWidget('weatherMenu.checkVarGain', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.toggleWeatherCheckbox('wx-var-gain'); } });
        me.addWidget('weatherMenu.checkTGT', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.toggleWeatherCheckbox('wx-tgt'); } });
        me.addWidget('weatherMenu.checkRCT', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.toggleWeatherCheckbox('wx-rct'); } });
        me.addWidget('weatherMenu.checkACT', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.toggleWeatherCheckbox('wx-act'); } });
        me.addWidget('weatherMenu.checkTurb', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.toggleWeatherCheckbox('wx-turb'); } });
        me.addWidget('weatherMenu.checkLX', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.toggleWeatherCheckbox('wx-lx'); } });
        me.addWidget('weatherMenu.checkClrTst', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.toggleWeatherCheckbox('wx-clr-tst'); } });
        me.addWidget('weatherMenu.checkFsbyOvrd', { active: func { self.elems['weatherMenu'].getVisible() }, onclick: func { self.toggleWeatherCheckbox('wx-fsby-ovrd'); } });
    },

    updateACshared: func () {
        var feed12 = getprop('/systems/electrical/buses/ac[0]/feed');
        var feed1 = getprop('/systems/electrical/buses/ac[1]/feed');
        var feed2 = getprop('/systems/electrical/buses/ac[2]/feed');
        var tieUsed = (feed1 == 2) or (feed2 == 2);
        var tieAvail = getprop('/systems/electrical/buses/ac[0]/powered');

        fillIfConnected(me.elems['elec.feed.ac1-ac12'], tieUsed and ((feed1 == 2) or (feed12 == 3)));
        fillIfConnected(me.elems['elec.feed.ac2-ac12'], tieUsed and ((feed2 == 2) or (feed12 == 4)));
        fillIfConnected(me.elems['elec.feed.ac12'], tieUsed and tieAvail);
    },

    updateDCshared: func () {
        var feed1 = getprop('/systems/electrical/buses/dc[1]/feed');
        var feed2 = getprop('/systems/electrical/buses/dc[2]/feed');
        fillIfConnected(me.elems['elec.feed.dc1-tru1'], feed1 == 1);
        fillIfConnected(me.elems['elec.feed.dc2-tru2'], feed2 == 1);
        fillIfConnected(me.elems['elec.feed.dc12'], (feed1 == 2) or (feed2 == 2));
    },
    updateDCESS1: func () {
        var feed1 = getprop('/systems/electrical/buses/dc[3]/feed');
        var feed3 = getprop('/systems/electrical/buses/dc[5]/feed');
        fillIfConnected(me.elems['elec.feed.dcess1-dcess3'], (feed1 == 2) or (feed3 == 2));
    },
    updateDCESS2: func () {
        var feed2 = getprop('/systems/electrical/buses/dc[4]/feed');
        var feed3 = getprop('/systems/electrical/buses/dc[5]/feed');
        fillIfConnected(me.elems['elec.feed.dcess2-dcess3'], (feed2 == 2) or (feed3 == 3));
    },

    updateFlightControl: func (baseName, dx, dy, pos) {
        if (pos >= 0.9999) {
            # full deflection
            me.elems[baseName ~ '.cover']
              .setTranslation(0, 0)
              .setColorFill(0, 1, 0, 1)
              .show();
            me.elems[baseName ~ '.dashedbox']
                .hide();
        }
        elsif (pos >= 0.5) {
            me.elems[baseName ~ '.cover']
              .setTranslation(pos * dx, pos * dy)
              .setColorFill(0, 0, 0, 1)
              .show();
            me.elems[baseName ~ '.dashedbox']
              .show();
        }
        elsif (pos >= 0.0) {
            me.elems[baseName ~ '.cover']
              .setTranslation(pos * dx, pos * dy)
              .setColorFill(0, 0, 0, 1)
              .show();
            me.elems[baseName ~ '.dashedbox']
              .hide();
        }
        else {
            # negative
            me.elems[baseName ~ '.cover']
              .setTranslation(0, 0)
              .setColorFill(0, 0, 0, 1)
              .show();
            me.elems[baseName ~ '.dashedbox']
              .hide();
        }
    },

    initFlightControl: func (baseName, prop, dx, dy, factor) {
        var self = me;
        clipTo(me.elems[baseName ~ '.cover'], me.elems[baseName ~ '.dashedbox']);
        clipTo(me.elems[baseName ~ '.stripes'], me.elems[baseName ~ '.dashedbox']);
        me.addListener('systems', prop, func (node) {
                self.updateFlightControl(baseName, dx, dy, node.getValue() * factor);
            });
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
        if (me.props['valid-nav'].getBoolValue()) {
            var acAlt = me.props['altitude-amsl'].getValue();
            var acPos = geo.Coord.new();
            acPos.set_latlon(
                me.props['latitude'].getValue() or 0,
                me.props['longitude'].getValue() or 0,
                acAlt);
            var x = 0;
            var y = 0;
            var resolution = me.props['resolution'].getValue();
            var step = math.max(1, math.pow(2, 8 - resolution));
            var numScanlines = me.props['scan-rate'].getValue();
            var color = nil;
            var density = 1;
            var range = me.mapCamera.range;
            for (var i = 0; i < numScanlines; i += 1) {
                for (y = 0; y < 256; y += step) {
                    var x = me.txRadarScanX;
                    var xRel = x - 128;
                    var yRel = y - 128;
                    var bearingRelRad = math.atan2(xRel, yRel);
                    var bearingAbs = geo.normdeg(bearingRelRad * R2D);
                    var dist = math.sqrt(yRel * yRel + xRel * xRel);
                    var elev = nil;
                    var isWater = 0;

                    if (dist <= 128) {
                        var coord = geo.Coord.new(acPos);
                        coord.apply_course_distance(bearingAbs, dist * (range / 10) * 10.675 * NM2M / 128);
                        var start = geo.Coord.new(coord);
                        var end = geo.Coord.new(coord);
                        start.set_alt(10000);
                        end.set_alt(0);
                        var xyz = { "x": start.x(), "y": start.y(), "z": start.z() };
                        var dir = { "x": end.x() - start.x(), "y": end.y() - start.y(), "z": end.z() - start.z() };
                        var result = get_cart_ground_intersection(xyz, dir);
                        elev = (result == nil) ? nil : result.elevation;
                        isWater = 0;

                        if (elev != nil and elev < 100) {
                            var info = geodinfo(start.lat(), start.lon(), 1000);
                            if (info != nil and info[1] != nil and info[1].solid == 0) {
                                isWater = 1;
                            }
                        }
                    }
                    if (elev == nil) {
                        color = '#000000';
                        density = 1;
                    }
                    else {
                        var terrainAlt = elev * M2FT;
                        var relAlt = terrainAlt - acAlt;

                        if (isWater) {
                            # color = [0, 0.5, 1, 1];
                            # density = 0;
                            color = [0, 0.25, 0.5, 1];
                        }
                        elsif (relAlt > 2000) {
                            color = [1, 0, 0, 1];
                            density = 1;
                        }
                        else if (relAlt > 1000) {
                            color = [1, 1, 0, 1];
                            density = 1;
                        }
                        else if (relAlt > -250) {
                            # color = [1, 1, 0, 1];
                            # density = 0;
                            color = [0.5, 0.5, 0, 1];
                        }
                        else if (relAlt > -1000) {
                            color = [0, 0.5, 0, 1];
                            density = 1;
                        }
                        else if (relAlt > -2000) {
                            # color = [0, 0.5, 0, 1];
                            # density = 0;
                            color = [0, 0.25, 0, 1];
                        }
                        else {
                            color = [0, 0, 0, 1];
                            density = 1;
                        }
                    }
                    # if (density)
                    #     me.terrainViz.fillRect([x, y, 2, 2], color);
                    # else
                    #     me.terrainViz.fillRect([x, y, 2, 2], '#000000');
                    var dither = 0;
                    for (var yy = y; yy < y + step; yy += 1) {
                        for (var xx = x; xx < x + step; xx += 1) {
                            dither = ((xx & 2) != (yy & 2)) or density;
                            me.terrainViz.setPixel(xx, yy, dither ? color : [0,0,0,1]);
                        }
                    }
                }
                me.txRadarScanX += step;
                if (me.txRadarScanX >= 256) {
                    me.txRadarScanX = 0;
                }
            }
            me.terrainViz.dirtyPixels();
        }
        else {
            me.terrainViz.fillRect([0, 0, 256, 256], [0, 0, 0, 1]);
            me.terrainViz.dirtyPixels();
        }
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

        # var txScale = 10 / range * 444 / 127;
        var txScale = 444 / 127;
        me.terrainViz.setTranslation(512 - 446, 530 - 446);
        me.terrainViz.setScale(txScale, txScale);
        me.terrainViz.fillRect([0, 0, 256, 256], '#000000');
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

    adjustProp: func (key, delta, min, max) {
        var prop = me.props[key];
        prop.setValue(math.min(max, math.max(min, prop.getValue() + delta)));
    },

    # direction: -1 = decrease, 1 = increase
    # knob: 0 = outer ring, 1 = inner ring
    masterScroll: func(direction, knob=0) {
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

    touchSystemsSubmode: func () {
        me.props['page'].setValue(2);
        me.elems['submodeMenu'].toggleVisibility();
    },

    selectSystemsSubmode: func (submode) {
        me.props['submode'].setValue(submode);
    },

    toggleMapCheckbox: func (which) {
        toggleBoolProp(me.props['show-' ~ which]);
    },

    toggleWeatherCheckbox: func (which) {
        toggleBoolProp(me.props[which]);
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
            me.elems['nav.src'].setText('FMS' ~ (me.side + 1));
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
            me.mapOverlay.show();
            me.plan.hide();
            me.systemsContainer.hide();
            me.elems['submodeMenu'].hide();
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
            me.mapOverlay.show();
            me.plan.show();
            me.systemsContainer.hide();
            me.elems['mapMenu'].hide();
            me.elems['submodeMenu'].hide();
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
            me.mapOverlay.hide();
            me.plan.hide();
            me.systemsContainer.show();
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

    updateSystemsSubmode: func (submode) {
        var self = me;
        me.systemsPages.status.setVisible(submode == SUBMODE_STATUS);
        me.systemsPages.electrical.setVisible(submode == SUBMODE_ELECTRICAL);
        me.systemsPages.fuel.setVisible(submode == SUBMODE_FUEL);
        me.systemsPages.flightControls.setVisible(submode == SUBMODE_FLIGHT_CONTROLS);
        me.clearListeners('systems');
        if (submode == SUBMODE_STATUS) {
            me.addListener('systems', me.props['flight-id'], func (node) {
                    self.elems['status.flightid'].setText(node.getValue());
                }, 1, 0);
            me.addListener('systems', me.props['zulu-hour'], func (node) {
                    self.elems['status.clock.hours'].setText(sprintf("%02.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', me.props['zulu-minute'], func (node) {
                    self.elems['status.clock.minutes'].setText(sprintf("%02.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', me.props['gross-weight'], func (node) {
                    self.elems['status.grossweight.digital'].setText(sprintf("%5.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/battery[0]/volts-avail', func (node) {
                    self.elems['status.battery1.voltage.digital'].setText(sprintf("%03.1f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/battery[1]/volts-avail', func (node) {
                    self.elems['status.battery2.voltage.digital'].setText(sprintf("%03.1f", node.getValue()));
                }, 1, 0);

            var doornames = ['l1', 'r1', 'l2', 'r2', 'cargo1', 'cargo2', 'fuel-panel', 'avionics-front', 'avionics-mid'];
            foreach (var doorname; doornames) {
                (func (doorname) {
                    me.addListener('systems', '/sim/model/door-positions/' ~ doorname ~ '/closed', func(node) {
                        if (node.getBoolValue()) {
                            self.elems['status.doors.' ~ doorname].setColorFill(0, 1, 0);
                        }
                        else {
                            self.elems['status.doors.' ~ doorname].setColorFill(1, 0, 0);
                        }
                    }, 1, 0);
                })(doorname);
            }
            var brakenames = [
                    'status.brake-temp.left-ob',
                    'status.brake-temp.left-ib',
                    'status.brake-temp.right-ib',
                    'status.brake-temp.right-ob',
                ];
            for (var i = 0; i < 4; i += 1) {
                (func () {
                    var brakename = brakenames[i];
                    me.addListener('systems', self.props['brake-temp-' ~ i], func(node) {
                        var temp = node.getValue();
                        var offset = math.max(0, math.min(136, (136 - 42) * temp / noTakeoffBrakeTemp));
                        self.elems[brakename ~ '.pointer'].setTranslation(0, -offset);
                        self.elems[brakename ~ '.digital'].setText(sprintf("%3.0f", temp));
                        if (temp >= noTakeoffBrakeTemp) {
                            self.elems[brakename ~ '.pointer'].setColor(1, 1, 0);
                            self.elems[brakename ~ '.pointer'].setColorFill(1, 1, 0);
                            self.elems[brakename ~ '.digital'].setColorFill(1, 1, 0);
                        }
                        else {
                            self.elems[brakename ~ '.pointer'].setColor(0, 1, 0);
                            self.elems[brakename ~ '.pointer'].setColorFill(0, 0, 0);
                            self.elems[brakename ~ '.digital'].setColorFill(0, 1, 0);
                        }
                    }, 1, 0);
                })();
            }

        }
        elsif (submode == SUBMODE_ELECTRICAL) {
            # External power
            me.addListener('systems', '/controls/electric/external-power-connected', func (node) {
                    var connected = node.getBoolValue();
                    me.elems['elec.acgpu.group'].setVisible(connected);
                    me.elems['elec.dcgpu.group'].setVisible(connected);
                }, 1, 0);

            # Elec. sources
            me.addListener('systems', '/systems/electrical/sources/generator[0]/visible', func (node) {
                    me.elems['elec.apu.group'].setVisible(node.getBoolValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/generator[0]/volts', func (node) {
                    me.elems['elec.apu.volts.digital'].setText(sprintf("%3.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/generator[0]/status', func (node) {
                    fillColorByStatus(me.elems['elec.apu.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/generator[1]/volts', func (node) {
                    me.elems['elec.idg1.volts.digital'].setText(sprintf("%3.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/generator[1]/status', func (node) {
                    fillColorByStatus(me.elems['elec.idg1.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/generator[2]/volts', func (node) {
                    me.elems['elec.idg2.volts.digital'].setText(sprintf("%3.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/generator[2]/status', func (node) {
                    fillColorByStatus(me.elems['elec.idg2.symbol'], node.getValue());
                }, 1, 0);

            me.addListener('systems', '/controls/electric/ram-air-turbine', func (node) {
                    me.elems['elec.rat.group'].setVisible(node.getBoolValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/generator[3]/volts', func (node) {
                    me.elems['elec.rat.volts.digital'].setText(sprintf("%3.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/generator[3]/status', func (node) {
                    fillColorByStatus(me.elems['elec.rat.symbol'], node.getValue());
                }, 1, 0);

            me.addListener('systems', '/systems/electrical/sources/ac-gpu/volts', func (node) {
                    me.elems['elec.acgpu.volts.digital'].setText(sprintf("%3.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/ac-gpu/status', func (node) {
                    fillColorByStatus(me.elems['elec.acgpu.symbol'], node.getValue());
                }, 1, 0);

            me.addListener('systems', '/systems/electrical/sources/dc-gpu/status', func (node) {
                    fillColorByStatus(me.elems['elec.dcgpu.symbol'], node.getValue());
                }, 1, 0);

            me.addListener('systems', '/systems/electrical/sources/battery[0]/volts-avail', func (node) {
                    me.elems['elec.battery1.volts.digital'].setText(sprintf("%4.1f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/battery[0]/status', func (node) {
                    fillColorByStatus(me.elems['elec.battery1.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/battery[1]/volts-avail', func (node) {
                    me.elems['elec.battery2.volts.digital'].setText(sprintf("%4.1f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/battery[1]/status', func (node) {
                    fillColorByStatus(me.elems['elec.battery2.symbol'], node.getValue());
                }, 1, 0);

            me.addListener('systems', '/systems/electrical/sources/tru[0]/volts', func (node) {
                    me.elems['elec.truess.volts.digital'].setText(sprintf("%4.1f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/tru[0]/status', func (node) {
                    fillColorByStatus(me.elems['elec.truess.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/tru[1]/volts', func (node) {
                    me.elems['elec.tru1.volts.digital'].setText(sprintf("%4.1f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/tru[1]/status', func (node) {
                    fillColorByStatus(me.elems['elec.tru1.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/tru[2]/volts', func (node) {
                    me.elems['elec.tru2.volts.digital'].setText(sprintf("%4.1f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/tru[2]/status', func (node) {
                    fillColorByStatus(me.elems['elec.tru2.symbol'], node.getValue());
                }, 1, 0);

            # Elec. buses
            me.addListener('systems', '/systems/electrical/buses/ac[1]/powered', func (node) {
                    fillColorByStatus(me.elems['elec.ac1.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/ac[2]/powered', func (node) {
                    fillColorByStatus(me.elems['elec.ac2.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/ac[3]/powered', func (node) {
                    fillColorByStatus(me.elems['elec.acess.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/ac[4]/powered', func (node) {
                    fillColorByStatus(me.elems['elec.acstby.symbol'], node.getValue());
                }, 1, 0);

            me.addListener('systems', '/systems/electrical/buses/dc[1]/powered', func (node) {
                    fillColorByStatus(me.elems['elec.dc1.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/dc[2]/powered', func (node) {
                    fillColorByStatus(me.elems['elec.dc2.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/dc[3]/powered', func (node) {
                    fillColorByStatus(me.elems['elec.dcess1.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/dc[4]/powered', func (node) {
                    fillColorByStatus(me.elems['elec.dcess2.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/dc[5]/powered', func (node) {
                    fillColorByStatus(me.elems['elec.dcess3.symbol'], node.getValue());
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/dc[6]/powered', func (node) {
                    fillColorByStatus(me.elems['elec.apustart.symbol'], node.getValue());
                }, 1, 0);

            me.addListener('systems', '/systems/electrical/buses/ac[0]/powered', func (node) {
                    me.updateACshared();
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/ac[0]/feed', func (node) {
                    var feed = node.getValue();
                    fillIfConnected(me.elems['elec.feed.ac12-apu'], feed == 1);
                    fillIfConnected(me.elems['elec.feed.ac12-acgpu'], feed == 2);
                    me.updateACshared();
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/ac[1]/feed', func (node) {
                    var feed = node.getValue();
                    fillIfConnected(me.elems['elec.feed.ac1-idg1'], feed == 1);
                    me.updateACshared();
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/ac[2]/feed', func (node) {
                    var feed = node.getValue();
                    fillIfConnected(me.elems['elec.feed.ac2-idg2'], feed == 1);
                    me.updateACshared();
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/ac[3]/feed', func (node) {
                    var feed = node.getValue();
                    fillIfConnected(me.elems['elec.feed.acess-ac2'], feed == 1);
                    fillIfConnected(me.elems['elec.feed.acess-ac1'], feed == 2);
                    fillIfConnected(me.elems['elec.feed.acess-rat'], feed == 3);
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/ac[4]/feed', func (node) {
                    var feed = node.getValue();
                    fillIfConnected(me.elems['elec.feed.acstby-acess'], feed == 1);
                }, 1, 0);

            me.addListener('systems', '/systems/electrical/sources/tru[0]/status', func (node) {
                    var status = node.getValue();
                    fillIfConnected(me.elems['elec.feed.truess-acess'], status == 1);
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/tru[1]/status', func (node) {
                    var status = node.getValue();
                    fillIfConnected(me.elems['elec.feed.tru1-ac1'], status == 1);
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/sources/tru[2]/status', func (node) {
                    var status = node.getValue();
                    fillIfConnected(me.elems['elec.feed.tru2-ac2'], status == 1);
                }, 1, 0);

            me.addListener('systems', '/systems/electrical/buses/dc[1]/feed', func self.updateDCshared, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/dc[2]/feed', func self.updateDCshared, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/dc[3]/feed', func (node) {
                    var feed = node.getValue();
                    fillIfConnected(me.elems['elec.feed.dcess1-dc1'], feed == 1);
                    fillIfConnected(me.elems['elec.feed.dcess1-batt1'], feed == 3);
                    self.updateDCESS1();
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/dc[4]/feed', func (node) {
                    var feed = node.getValue();
                    fillIfConnected(me.elems['elec.feed.dcess2-dc2'], feed == 1);
                    fillIfConnected(me.elems['elec.feed.dcess2-batt2'], feed == 3);
                    self.updateDCESS2();
                }, 1, 0);
            me.addListener('systems', '/systems/electrical/buses/dc[5]/feed', func (node) {
                    var feed = node.getValue();
                    fillIfConnected(me.elems['elec.feed.dcess3-truess'], feed == 1);
                    self.updateDCESS1();
                    self.updateDCESS2();
                }, 1, 0);

            me.addListener('systems', '/systems/electrical/buses/dc[6]/feed', func (node) {
                    var feed = node.getValue();
                    fillIfConnected(me.elems['elec.feed.apustart-dcgpu'], feed == 1);
                    fillIfConnected(me.elems['elec.feed.apustart-batt2'], feed == 2);
                    me.elems['elec.dcgpu.inuse'].setVisible(feed == 1);
                    fillColorByStatus(me.elems['elec.dcgpu.symbol'], feed == 1);
                }, 1, 0);
        }
        elsif (submode == SUBMODE_FUEL) {
            me.addListener('systems', '/controls/fuel/crossfeed', func (node) {
                    var state = node.getValue();
                    var c = (state == 0) ? [1,1,1] : [0,1,0];
                    self.elems['fuel.valve.crossfeed']
                        .setRotation(state * math.pi * 0.5)
                        .setColorFill(c);
                    self.elems['fuel.crossfeed.mode']
                        .setText((state == 1) ? "LOW 2" : "LOW 1")
                        .setVisible(state != 0);

                }, 1, 0);
            me.addListener('systems', '/engines/engine[0]/cutoff', func (node) {
                    var c = node.getBoolValue() ? [1,1,1] : [0,1,0];
                    self.elems['fuel.valve.cutoffL']
                        .setRotation(node.getValue() * math.pi * 0.5)
                        .setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/engines/engine[1]/cutoff', func (node) {
                    var c = node.getBoolValue() ? [1,1,1] : [0,1,0];
                    self.elems['fuel.valve.cutoffR']
                        .setRotation(node.getValue() * math.pi * 0.5)
                        .setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/engines/apu/cutoff', func (node) {
                    var c = node.getBoolValue() ? [1,1,1] : [0,1,0];
                    self.elems['fuel.valve.apu']
                        .setRotation(node.getValue() * math.pi * 0.5)
                        .setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/engines/engine[0]/running', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [0.5, 0.5, 0.5];
                    self.elems['fuel.pump.e1']
                        .setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/engines/engine[1]/running', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [0.5, 0.5, 0.5];
                    self.elems['fuel.pump.e2']
                        .setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/fuel-pump[0]/running', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.pump.ac1']
                        .setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/fuel-pump[1]/running', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.pump.ac2']
                        .setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/fuel-pump[2]/running', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.pump.ac3']
                        .setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/fuel-pump[3]/running', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.pump.dc']
                        .setColorFill(c[0], c[1], c[2]);
                }, 1, 0);

            me.addListener('systems', '/systems/fuel/pressure/pump[0]', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.acpump1'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/pressure/pump[1]', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.acpump2'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/pressure/pump[2]', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.acpump3'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/pressure/pump[3]', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.dcpump'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/pressure/pump[4]', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.epump1'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/pressure/pump[5]', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.epump2'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);

            me.addListener('systems', '/systems/fuel/pressure/tank[0]', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.tankL'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/pressure/tank[1]', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.tankR'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/pressure/engine[0]', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.engineL'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/pressure/engine[1]', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.engineR'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/systems/fuel/pressure/apu', func (node) {
                    var c = node.getBoolValue() ? [0,1,0] : [1, 1, 1];
                    self.elems['fuel.line.apu'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);

            me.addListener('systems', '/fms/fuel/current', func (node) {
                    self.elems['fuel.total.digital'].setText(sprintf("%5.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/fms/fuel/used', func (node) {
                    self.elems['fuel.used.digital'].setText(sprintf("%5.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/fms/fuel/gauge[0]/pointer', func (node) {
                    self.elems['fuel.quantityL.pointer'].setTranslation(0, node.getValue());
                }, 1, 0);
            me.addListener('systems', '/fms/fuel/gauge[1]/pointer', func (node) {
                    self.elems['fuel.quantityR.pointer'].setTranslation(0, node.getValue());
                }, 1, 0);
            me.addListener('systems', '/fms/fuel/gauge[2]/pointer', func (node) {
                    self.elems['fuel.quantityC.pointer'].setTranslation(0, node.getValue());
                }, 1, 0);
            me.addListener('systems', '/fms/fuel/gauge[0]/indicated', func (node) {
                    self.elems['fuel.quantityL.digital'].setText(sprintf("%5.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/fms/fuel/gauge[1]/indicated', func (node) {
                    self.elems['fuel.quantityR.digital'].setText(sprintf("%5.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/fms/fuel/gauge[2]/indicated', func (node) {
                    self.elems['fuel.quantityC.digital'].setText(sprintf("%5.0f", node.getValue()));
                }, 1, 0);
            me.addListener('systems', '/instrumentation/eicas/messages/fuel-low-left', func (node) {
                    var c = node.getBoolValue() ? [1,0,0] : [0,1,0];
                    self.elems['fuel.quantityL.digital'].setColor(c[0], c[1], c[2]);
                    self.elems['fuel.quantityL.pointer'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
            me.addListener('systems', '/instrumentation/eicas/messages/fuel-low-right', func (node) {
                    var c = node.getBoolValue() ? [1,0,0] : [0,1,0];
                    self.elems['fuel.quantityR.digital'].setColor(c[0], c[1], c[2]);
                    self.elems['fuel.quantityR.pointer'].setColorFill(c[0], c[1], c[2]);
                }, 1, 0);
        }
        elsif (submode == SUBMODE_FLIGHT_CONTROLS) {
            me.initFlightControl('fctl.aileron-lh-up', self.props['aileron-left'], 0, -75, -1);
            me.initFlightControl('fctl.aileron-lh-down', self.props['aileron-left'], 0, 75, 1);
            me.initFlightControl('fctl.aileron-rh-up', self.props['aileron-right'], 0, -75, 1);
            me.initFlightControl('fctl.aileron-rh-down', self.props['aileron-right'], 0, 75, -1);
            me.initFlightControl('fctl.rudder-left', self.props['rudder'], -45, 0, -1/0.55);
            me.initFlightControl('fctl.rudder-right', self.props['rudder'], 45, 0, 1/0.55);
            me.initFlightControl('fctl.elev-lh-up', self.props['elevator'], 0, -68, -1);
            me.initFlightControl('fctl.elev-rh-up', self.props['elevator'], 0, -68, -1);
            me.initFlightControl('fctl.elev-lh-down', self.props['elevator'], 0, 54, 1);
            me.initFlightControl('fctl.elev-rh-down', self.props['elevator'], 0, 54, 1);
            me.initFlightControl('fctl.mfs1', self.props['mfs1'], 0, -34, 1);
            me.initFlightControl('fctl.mfs2', self.props['mfs2'], 0, -34, 1);
            me.initFlightControl('fctl.mfs3', self.props['mfs3'], 0, -34, 1);
            me.initFlightControl('fctl.mfs4', self.props['mfs4'], 0, -34, 1);
            me.initFlightControl('fctl.mfs5', self.props['mfs5'], 0, -34, 1);
            me.initFlightControl('fctl.mfs6', self.props['mfs6'], 0, -34, 1);
            me.initFlightControl('fctl.mfs7', self.props['mfs7'], 0, -34, 1);
            me.initFlightControl('fctl.mfs8', self.props['mfs8'], 0, -34, 1);
            me.initFlightControl('fctl.mfs9', self.props['mfs9'], 0, -34, 1);
            me.initFlightControl('fctl.mfs10', self.props['mfs10'], 0, -34, 1);

            me.addListener('systems', me.props['elevator-law'], func (node) {
                    var law = node.getValue();

                    if (law == 1) {
                        self.elems['fctl.mode.elev-lh.text'].setText('NORMAL').setColor(0, 1, 0);
                        self.elems['fctl.mode.elev-rh.text'].setText('NORMAL').setColor(0, 1, 0);
                        self.elems['fctl.mode.elev-lh.frame'].hide();
                        self.elems['fctl.mode.elev-rh.frame'].hide();
                    }
                    else {
                        self.elems['fctl.mode.elev-lh.text'].setText('DIRECT').setColor(0, 0, 0);
                        self.elems['fctl.mode.elev-rh.text'].setText('DIRECT').setColor(0, 0, 0);
                        self.elems['fctl.mode.elev-lh.frame'].show();
                        self.elems['fctl.mode.elev-rh.frame'].show();
                    }
                }, 1, 0);

            me.addListener('systems', me.props['rudder-law'], func (node) {
                    var law = node.getValue();

                    if (law == 1) {
                        self.elems['fctl.mode.rudder.text'].setText('NORMAL').setColor(0, 1, 0);
                        self.elems['fctl.mode.rudder.frame'].hide();
                    }
                    else {
                        self.elems['fctl.mode.rudder.text'].setText('DIRECT').setColor(0, 0, 0);
                        self.elems['fctl.mode.rudder.frame'].show();
                    }
                }, 1, 0);
        }
    },

    updateSlow: func () {
        call(canvas_base.BaseScreen.updateSlow, [], me);
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

        var alt = me.props['altitude'].getValue();
        me.trafficLayer.setRefAlt(alt);
        if (me.trafficGroup.getVisible()) {
            me.trafficLayer.update();
        }
    },

    update: func () {
        call(canvas_base.BaseScreen.update, [], me);
        var heading = me.props['heading-mag'].getValue();
        var headingT = me.props['heading'].getValue();
        var headingBug = me.props['heading-bug'].getValue();
        var headingDiff = geo.normdeg180(headingBug - heading);
        if (me.props['valid-nav'].getBoolValue()) {
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
        }
        me.elems['tat.digital'].setText(sprintf("%3.0f", me.props['tat'].getValue()));
        me.elems['sat.digital'].setText(sprintf("%3.0f", me.props['sat'].getValue()));
        me.elems['tas.digital'].setText(sprintf("%3.0f", me.props['tas'].getValue()));
        me.elems['status.tat.digital'].setText(sprintf("%3.0f", me.props['tat'].getValue()));
        me.elems['status.sat.digital'].setText(sprintf("%3.0f", me.props['sat'].getValue()));
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
                    nextEFOB = fms.performanceProfile.estimated[wpi].fob * LB2KG;
                }
                if (dsti != nil and dsti < size(fms.performanceProfile.estimated)) {
                    destEFOB = fms.performanceProfile.estimated[dsti].fob * LB2KG;
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

        me.mapCamera.reposition(geo.aircraft_position(), headingT);

        if (me.trafficGroup.getVisible()) {
            me.trafficLayer.redraw();
        }
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

var listeners = [];

var teardown = func {
    initialized = 0;
    foreach (var l; listeners) {
        removelistener(l);
    }
    listeners = [];
    for (var i = 0; i <= 1; i += 1) {
        mfd[i].deinit();
        mfd[i] = nil;
        mfd_display[i].del();
        mfd_display[i] = nil;
    }
};

var initialize = func {
    if (initialized) { teardown(); }
    initialized = 1;
    for (var i = 0; i <= 1; i += 1) {
        mfd_display[i] = canvas.new({
            "name": "MFD" ~ i,
            "size": [512, 1024],
            "view": [1024, 1560],
            "mipmapping": 1
        });
        mfd_display[i].addPlacement({"node": "MFD" ~ i});
        mfd_master[i] = mfd_display[i].createGroup();
        mfd[i] = MFD.new(i).init(mfd_master[i]);
        (func (j) {
            outputProp = props.globals.getNode("systems/electrical/outputs/mfd[" ~ j ~ "]");
            enabledProp = props.globals.getNode("instrumentation/mfd[" ~ j ~ "]/enabled");
            var check = func {
                var visible = ((outputProp.getValue() or 0) >= 15) and enabledProp.getBoolValue();
                mfd_master[j].setVisible(visible);
                if (visible) {
                    mfd[j].activate();
                }
                else {
                    mfd[j].deactivate();
                }
            };
            append(listeners, setlistener(outputProp, check, 1, 0));
            append(listeners, setlistener(enabledProp, check, 1, 0));
        })(i);
    }
};

setlistener("sim/signals/fdm-initialized", initialize);
