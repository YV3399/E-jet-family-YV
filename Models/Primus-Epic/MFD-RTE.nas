
(func () {
    var name = 'EJet-RTE';
    SymbolLayer.Controller.add(name, EJetRTWController);
    SymbolLayer.add(name, {
        parents: [MultiSymbolLayer],
        type: name, # Symbol type
        df_controller: __self__, # controller to use by default -- this one
        df_options: { # default configuration options
            active_node: "/autopilot/route-manager/active",
            current_wp_node: "/autopilot/route-manager/current-wp",
            wp_num: "/autopilot/route-manager/route/num",
            display_inactive_rte: 0
        }
    });
})();

var EJetRTEController = {
    parents: [SymbolLayer.Controller],

var new = func(layer) {
	var m = {
		parents: [__self__],
		layer: layer,
		map: layer.map,
		listeners: [],
	};
	layer.searcher._equals = func(l,r) return (l == r);
	append(m.listeners, setlistener(layer.options.active_node, func m.layer.update() ),
		setlistener(layer.options.wp_num, func m.layer.update() ));

	m.addVisibilityListener();
	var driver = opt_member(m.layer.options, 'route_driver');
	if(driver == nil){
		driver = RouteDriver.new();
	}
	var driver_listeners = driver.getListeners();
	foreach(var listener; driver_listeners){
		append(m.listeners, setlistener(listener, func m.layer.update()));
	}
	m.route_driver = driver;
	return m;
};
var del = func() {
	foreach (var l; me.listeners)
		removelistener(l);
};

var last_result = [];

var searchCmd = func {
	# FIXME: do we return the current route even if it isn't active?
	logprint(_MP_dbg_lvl, "Running query: ", name);
	var plans = []; # TODO: multiple flightplans?
	var driver = me.route_driver;
	driver.update();
	if(!driver.shouldUpdate()) return me.last_result;
	# http://wiki.flightgear.org/Nasal_Flightplan
	var planCount = driver.getNumberOfFlightPlans();
	for (var idx = 0; idx < planCount; idx += 1) {
		if (driver.getFlightPlan(idx) == nil) return [];
		var fpSize = driver.getPlanSize(idx);
		if(fpSize < 2) continue;
		var type = driver.getFlightPlanType(idx);
		if(type == nil) type = 'current';
		if (!getprop(me.layer.options.active_node) and
			type == 'current' and
			!me.layer.options.display_inactive_rte) fpSize = 0;
		var coords = [];
		var discontinuity = 0;
		for (var i=0; i<fpSize; i += 1) {
			var leg = driver.getWP(idx, i);
			if(discontinuity)
				coords ~= [{},{lon:leg.wp_lon, lat:leg.wp_lat}];
			else
				coords ~= leg.path();
			discontinuity = driver.hasDiscontinuity(idx, leg.id);
		}
		append(plans, {
			id: type,
			#name: type,
			type: type,
			path: coords,
			#size: fpSize,
			equals: func(o){
				me.id == o.id# and me.size == o.size
			}
		});
	}
	me.last_result = plans;
	return plans;
};
