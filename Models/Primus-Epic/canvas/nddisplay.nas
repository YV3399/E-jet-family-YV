##
# ==============================================================================
# Boeing Navigation Display by Gijs de Rooy
# See: http://wiki.flightgear.org/Canvas_ND_Framework
#
#	Adapted for the Citation X by C.Le Moigne (clm76) - oct 2016
#
# ==============================================================================

##
# this file contains a hash that declares features in a generic fashion
#io.include("Nasal/canvas/map/nddisplay.styles");

##
# encapsulate hdg/lat/lon source, so that the ND may also display AI/MP aircraft in a pilot-view at some point (aka stress-testing)
# TODO: this predates aircraftpos.controller (MapStructure) should probably be unified to some degree ...

var wxr_live_tree = "/instrumentation/wxr";
var userLat = nil;
var userLon = nil;
var userAlt = nil;
var userGndSpd = nil;
var userVSpd = nil;
var userHdg = nil;
var userTrk = nil;
var userHdgMag = nil;
var userHdgTru = nil;
var userTrkMag = nil;
var userTrkTru = nil;
var oldRange = nil;
var pos = nil;
var _time = nil;
var wxr_live_enabled =nil;
var update_layers = nil;
var translation_callback = nil;
var trsl = nil;

var NDSourceDriver = {};
NDSourceDriver.new = func {
	var m = {parents:[NDSourceDriver]};
	m.get_hdg_mag= func getprop("/orientation/heading-magnetic-deg");
	m.get_hdg_tru= func getprop("/orientation/heading-deg");
	m.get_hgg = func getprop("instrumentation/afds/settings/heading");
	m.get_trk_mag= func	{
		if(getprop("/velocities/groundspeed-kt") > 80)
			getprop("/orientation/track-magnetic-deg");
		else
			getprop("/orientation/heading-magnetic-deg");
 	};
	m.get_trk_tru = func {
		if(getprop("/velocities/groundspeed-kt") > 80)
			getprop("/orientation/track-deg");
		else
			getprop("/orientation/heading-deg");
	};
	m.get_lat= func getprop("/position/latitude-deg");
	m.get_lon= func getprop("/position/longitude-deg");
####
	m.get_alt= func getprop("/position/altitude-ft");
####
	m.get_spd= func getprop("/instrumentation/airspeed-indicator/true-speed-kt");
	m.get_gnd_spd= func getprop("/velocities/groundspeed-kt");
	m.get_vspd= func getprop("/velocities/vertical-speed-fps");
	return m;
} # end of NDSourceDriver.new

var NdDisplay = {
	id:0,

	del: func {
		print("Cleaning up NdDisplay");
		# shut down all timers and other loops here
		me.update_timer.stop();
		foreach(var t; me.timers)
			t.stop();
		foreach(var l; me.listeners)
			#removelistener(l);
			call(removelistener, [l]);
		# clean up MapStructure
		me.map.del();
		# call(canvas.Map.del, [], me.map);
		# destroy the canvas
		if (me.canvas_handle != nil)
			me.nd.del();
		me.inited = 0;
		NdDisplay.id -= 1;
	},

	addtimer: func(interval, cb) {
		append(me.timers, var job=maketimer(interval, cb));
		return job; # so that we can directly work with the timer (start/stop)
	},

	listen: func(p,c) {
		append(me.listeners, setlistener(p,c));
	},

	# listeners for cockpit switches
	listen_switch: func(s,c) {
		if (!contains(me.efis_switches, s)) {
			print('EFIS Switch not defined: '~ s);
			return;
		}
		me.listen( me.get_full_switch_path(s), func {
			# print("listen_switch triggered:", s, " callback id:", id(c) );
			c();
		});
	},

	# get the full property path for a given switch
	get_full_switch_path: func (s) {
		 #debug.dump( me.efis_switches[s] );
		return me.efis_path ~ me.efis_switches[s].path; # FIXME: should be using props.nas instead of ~
	},

	# helper method for getting configurable cockpit switches (which are usually different in each aircraft)
	get_switch: func(s) {
		var switch = me.efis_switches[s];
		if(switch == nil) return nil;
		var path = me.efis_path ~ switch.path ;
		#print(s,":Getting switch prop:", path);

		return getprop( path );
	},
		
	# helper method for setting configurable cockpit switches (which are usually different in each aircraft)
	set_switch: func(s, v) {
		var switch = me.efis_switches[s];
		if(switch == nil) return nil;
		var path = me.efis_path ~ switch.path ;
		#print(s,":Getting switch prop:", path);
		setprop( path, v );
	},

	# for creating NDs that are driven by AI traffic instead of the main aircraft (generalization rocks!)
	connectAI: func(source=nil) {
		me.aircraft_source = {
			get_hdg_mag: func source.getNode('orientation/heading-magnetic-deg').getValue(),
			get_trk_mag: func source.getNode('orientation/track-magnetic-deg').getValue(),
			get_lat: func source.getNode('position/latitude-deg').getValue(),
			get_lon: func source.getNode('position/longitude-deg').getValue(),
######
			get_alt: func source.getNode('position/altitude-ft').getValue(),
#####
			get_spd: func source.getNode('velocities/true-airspeed-kt').getValue(),
			get_gnd_spd: func source.getNode('velocities/groundspeed-kt').getValue(),
		};
	}, # end of connectAI

	setTimerInterval: func(update_time=0.05) me.update_timer.restart(update_time),

	new : func(prop1, switches, style) {
		NdDisplay.id +=1;
		var m = { parents : [NdDisplay]};
		var df_toggles = keys(switches);
		
		m.inited = 0;
		m.timers=[]; 
		m.listeners=[]; # for cleanup handling
		m.aircraft_source = NDSourceDriver.new(); # uses the main aircraft as the driver/source (speeds, position, heading)
		m.nd_style = NDStyles[style]; # look up ND specific stuff (file names etc)
		m.style_name = style;
		m.radio_list=["instrumentation/comm/frequencies","instrumentation/comm[1]/frequencies",
		              "instrumentation/nav/frequencies", "instrumentation/nav[1]/frequencies"];
		# FIXME: this is redundant, must be moved to the style/Switches list
		m.mfd_mode_list=["APP","VOR","MAP","PLAN"];

		m.efis_path = prop1;
		m.efis_switches = switches;

		# just an alias, to avoid having to rewrite the old code for now
		m.rangeNm = func m.get_switch('toggle_range');
		m.efis = props.globals.initNode(prop1);
		m.mfd = m.efis.initNode("mfd");
#		m.nd_plan_wpt = m.efis.initNode("inputs/plan-wpt-index", -1, "INT"); # 
		# initialize all switches specified in the switch hash
		foreach(var switch; keys( m.efis_switches ) )
			props.globals.initNode
				(	m.get_full_switch_path (switch),
					m.efis_switches[switch].value,
					m.efis_switches[switch].type
				);

		return m;
	},		

	newMFD: func(canvas_group, parent=nil, nd_options=nil, update_time=0.05)
	{
		if (me.inited) die("MFD already was added to scene");
		me.inited = 1;
		me.range_dependant_layers = [];
########
		me.course_dependant_layers = [];
########
		me.always_update_layers = {};
		me.update_timer = maketimer(update_time, func me.update() );
		me.nd = canvas_group;
		me.canvas_handle = parent;
		me.df_options = nil;
		if (contains(me.nd_style, 'options'))
			me.df_options = me.nd_style.options;
		nd_options = canvas.default_hash(nd_options, me.df_options);
		me.options = nd_options;
		me.route_driver = nil;
		if (me.options == nil) me.options = {};
		if (contains(me.options, 'route_driver')) {
			me.route_driver = me.options.route_driver;
		}
		elsif (contains(me.options, 'defaults')) {
			if(contains(me.options.defaults, 'route_driver'))
				me.route_driver = me.options.defaults.route_driver;
		}

		# load the specified SVG file into the me.nd group and populate all sub groups

		canvas.parsesvg(me.nd, me.nd_style.svg_filename, {'font-mapper': me.nd_style.font_mapper});
		me.symbols = {}; 

		foreach(var feature; me.nd_style.features ) {
			me.symbols[feature.id] = me.nd.getElementById(feature.id).updateCenter(   );
			if(contains(feature.impl,'init')) feature.impl.init(me.nd, feature); 
		}

		me.nd_style.initialize_elements(me);
#		var map_rect = [124, 1024, 1024, 0];
		var map_opts = me.options['map'];
		if (map_opts == nil) map_opts = {};
#		if (typeof(map_opts['rect']) == 'vector')
#			map_rect = map_opts.rect;
#		map_rect = string.join(', ', map_rect);

		me.map = me.nd.createChild("map","map")
#			.set("clip", map_rect)
			.set("screen-range", 750); #old 700
		var z_idx = map_opts['z-index'];
		if (z_idx != nil) me.map.set('z-index', z_idx);

		me.update_sub(); # init some map properties based on switches

		# predicate for the draw controller
		var is_tuned = func(freq) {
			var nav1=getprop("instrumentation/nav[0]/frequencies/selected-mhz");
			var nav2=getprop("instrumentation/nav[1]/frequencies/selected-mhz");
			if (freq == nav1 or freq == nav2) return 1;
			return 0;
		}

		# another predicate for the draw controller
		var get_course_by_freq = func(freq) {
			if (freq == getprop("instrumentation/nav[0]/frequencies/selected-mhz"))
				return getprop("instrumentation/nav[0]/radials/selected-deg");
			else
				return getprop("instrumentation/nav[1]/radials/selected-deg");
		}

#####
		var get_course_offset = func {
			return getprop("/orientation/heading-magnetic-deg");
		}
#####
		var get_current_position = func {
			delete(caller(0)[0], "me"); # remove local me, inherit outer one
			return [
#####
				me.aircraft_source.get_lat(), me.aircraft_source.get_lon(), me.aircraft_source.get_alt()
#####
			];
		}

		var controller = {
			parents: [canvas.Map.Controller],
			_pos: nil, _time: nil,
			is_tuned:is_tuned,
			get_tuned_course:get_course_by_freq,
#####
			get_course_dev:get_course_offset,
#####
			get_position: get_current_position,
			new: func(map) return { parents:[controller], map:map },
			del: func() {print("cleaning up nd controller");},
			should_update_all: func {
				var pos = me.map.getPosCoord();
				if (pos == nil) return 0;
				var time = systime();
				if (me._pos == nil)
					me._pos = geo.Coord.new(pos);
				else {
					var dist_m = me._pos.direct_distance_to(pos);
					# 2 NM until we update again
					if (dist_m < 2 * NM2M) return 0;
					# Update at most every 4 seconds to avoid excessive stutter:
					elsif (time - me._time < 4) return 0;
				}
				#print("update aircraft position");
				var (x,y,z) = pos.xyz();
				me._pos.set_xyz(x,y,z);
				me._time = time;
				return 1;
			},
		};
		me.map.setController(controller);
		var make_event_handler = func(predicate, layer) func predicate(me, layer);

		me.layers={}; 
		var default_opts = me.options != nil and contains(me.options, 'defaults') ? me.options.defaults : nil;
		foreach(var layer; me.nd_style.layers) {
			if(layer['disabled']) continue; # skip this layer
			#print("newMFD(): Setting up ND layer:", layer.name);

			var the_layer = nil;
			if(!layer['isMapStructure']) # set up an old INEFFICIENT and SLOW layer
				the_layer = me.layers[layer.name] = canvas.MAP_LAYERS[layer.name].new( me.map, layer.name, controller);
			else {
				# printlog(canvas._MP_dbg_lvl, "Setting up MapStructure-based layer for ND, name:", layer.name);
				var opt = me.options != nil and me.options[layer.name] != nil ? me.options[layer.name] : nil;
				if (opt == nil and contains(layer, 'options'))
					opt = layer.options;
				if (opt != nil and default_opts != nil)
					opt = canvas.default_hash(opt, default_opts);
				#elsif(default_opts != nil)
				#    opt = default_opts;
				var style = nil;
				if(contains(layer, 'style'))
					style = layer.style;
				#print("Options is: ", opt!=nil?"enabled":"disabled");
				#debug.dump(opt);
				me.map.addLayer(
					factory: canvas.SymbolLayer,
					type_arg: layer.name,
					opts: opt,
					visible:0,
					style: style,
					priority: layer['z-index']
				);
				the_layer = me.layers[layer.name] = me.map.getLayer(layer.name);
				if(opt != nil and contains(opt, 'range_dependant')){
					if(opt.range_dependant)
						append(me.range_dependant_layers, the_layer);
				}
#########
				if(opt != nil and contains(opt, 'course_dependant')){
					if(opt.course_dependant)
						append(me.course_dependant_layers, the_layer);
				}
########
				if(contains(layer, 'always_update'))
					me.always_update_layers[layer.name] = layer.always_update;
				if (1) (func {
					var l = layer;
					var _predicate = l.predicate;
					l.predicate = func {
						var t = systime();
						call(_predicate, arg, me);
					# printlog(canvas._MP_dbg_lvl, "Took "~((systime()-t)*1000)~"ms to update layer "~l.name);
					}
				})();
			}

			var event_handler = make_event_handler(layer.predicate, the_layer);
			foreach(var event; layer.update_on) {
				if (typeof(event)=='hash' and contains(event, 'rate_hz')) {
					var job=me.addtimer(1/event.rate_hz, event_handler);	
					job.start();
				}	
				else
				me.listen_switch(event, event_handler);
			} # foreach event subscription
			event_handler();
		} # foreach layer

		me.update_timer.start();

		# TODO: move this to RTE.lcontroller ?
		me.listen("/autopilot/route-manager/current-wp", func(activeWp) {
			canvas.updatewp(activeWp.getValue());
		});
	},

	in_mode:func(switch, modes) {
		foreach(var m; modes) if(me.get_switch(switch)==m) return 1;
		return 0;
	},

	update_sub: func() {
		# Variables:
		userLat = me.aircraft_source.get_lat();
		userLon = me.aircraft_source.get_lon();
#####
		userAlt = me.aircraft_source.get_alt();
#####
		userGndSpd = me.aircraft_source.get_gnd_spd();
		userVSpd = me.aircraft_source.get_vspd();
#		dispLCD = me.get_switch('toggle_display_type') == "LCD";
		# Heading update
		userHdgMag = me.aircraft_source.get_hdg_mag();
		userHdgTru = me.aircraft_source.get_hdg_tru();
		userTrkMag = me.aircraft_source.get_trk_mag();
		userTrkTru = me.aircraft_source.get_trk_tru();
		
		if(me.get_switch('toggle_true_north')) {
			var userHdg=userHdgTru;
#			me.userHdg=userHdgTru;
			userTrk=userTrkTru;
#			me.userTrk=userTrkTru;
		} else {
			var userHdg=userHdgMag;
#			me.userHdg=userHdgMag;
			userTrk=userTrkMag;
#			me.userTrk=userTrkMag;
		}
		# this should only ever happen when testing the experimental AI/MP ND driver hash (not critical) or when an error occurs (critical)
		if (!userHdg or !userTrk or !userLat or !userLon) {
			print("aircraft source invalid, returning !");
			return;
		}
		if (me.aircraft_source.get_gnd_spd() < 80) {
			userTrk = userHdg;
#			me.userTrk=userHdg;
		}
		
		if((me.in_mode('toggle_display_mode', ['MAP']) and me.get_switch('toggle_display_type') == "CRT")
		    or (me.get_switch('toggle_track_heading') and me.get_switch('toggle_display_type') == "LCD"))
		{
			userHdgTrk = userTrk;
#			me.userHdgTrk = userTrk;
			userHdgTrkTru = userTrkTru;
#			me.symbols.hdgTrk.setText("TRK");
		} else {
			userHdgTrk = userHdg;
#			me.userHdgTrk = userHdg;
			userHdgTrkTru = userHdgTru;
#			me.symbols.hdgTrk.setText("HDG");
		}

		# First, update the display position of the map
		var oldRange = me.map.getRange();
		var pos = {
			lat: nil, lon: nil,
			alt: nil, hdg: nil,
			range: nil,
		};
		# reposition the map, change heading & range:
#		var pln_wpt_idx = getprop(me.efis_path ~ "/inputs/plan-wpt-index");
#		if(me.in_mode('toggle_display_mode', ['PLAN'])  and pln_wpt_idx >= 0) {
#		if(me.in_mode('toggle_display_mode', ['PLAN'])) {
#			if(me.route_driver != nil){
#				var wp = me.route_driver.getPlanModeWP(pln_wpt_idx);
#				if(wp != nil){
#					pos.lat = wp.wp_lat;
#					pos.lon = wp.wp_lon;
#				} else {
#					pos.lat = getprop("/autopilot/route-manager/route/wp["~pln_wpt_idx~"]/latitude-deg");
#					pos.lon = getprop("/autopilot/route-manager/route/wp["~pln_wpt_idx~"]/longitude-deg");
#				}
#			} else {
#				pos.lat = getprop("/autopilot/route-manager/route/wp["~pln_wpt_idx~"]/latitude-deg");
#				pos.lon = getprop("/autopilot/route-manager/route/wp["~pln_wpt_idx~"]/longitude-deg");
#			}

#		} else {
			pos.lat = userLat;
			pos.lon = userLon;
####
			pos.alt = userAlt;
####
#		}

		if(me.in_mode('toggle_display_mode', ['PLAN'])) {
			pos.hdg = 0;
			pos.range = me.rangeNm()
		} else {
			pos.range = me.rangeNm(); # avoid this  here, use a listener instead
			pos.hdg = userHdgTrkTru;
		}

		if(me.options != nil and (var pos_callback = me.options['position_callback']) != nil)
			pos_callback(me, pos);
####
		call(me.map.setPos, [pos.lat, pos.lon,nil,nil,pos.alt], me.map, pos);
####
		if(pos.range != oldRange){
			foreach(l; me.range_dependant_layers){
				l.update();
			}
		}
#######
		foreach(l; me.course_dependant_layers){
			l.update();
		}
#######
	},
	update: func()	{
		_time = systime();
		# Disables WXR Live if it's not enabled. The toggle_weather_live should be common to all ND instances.
		wxr_live_enabled = getprop(wxr_live_tree~'/enabled');
		if(wxr_live_enabled == nil or wxr_live_enabled == '') 
			wxr_live_enabled = 0;
		me.set_switch('toggle_weather_live', wxr_live_enabled);
		
		call(me.update_sub, nil, nil, caller(0)[0]); 

		# MapStructure update!
		if (me.map.controller.should_update_all()) {
			me.map.update();
		} else {
			update_layers = me.always_update_layers;
			me.map.update(func(layer) contains(update_layers, layer.type));
		}
		# Other symbol update
		if(me.options != nil)
			translation_callback = me.options['translation_callback'];
		if(typeof(translation_callback) == 'func'){
			trsl = translation_callback(me);
			me.map.setTranslation(trsl.x, trsl.y);
		} else {
			if(me.in_mode('toggle_display_mode', ['PLAN'])) {
				me.map.setTranslation(452,480);
				me.map.setScale(0.52);
			}	else if(me.get_switch('toggle_centered')){
				me.map.setTranslation(452,490);
			}	else {
				me.map.setScale(0.52);
				me.map.setTranslation(452,490);	
			}
		}

		foreach(var feature; me.nd_style.features) {
			if (contains(feature.impl, 'common')) feature.impl.common(me);
			if(!contains(feature.impl, 'predicate')) continue;
			if (var result=feature.impl.predicate(me) )
				feature.impl.is_true(me, result); # pass the result to the predicate
			else
				feature.impl.is_false(me, result); # pass the result to the predicate
		}

		## update the status flags shown on the ND (wxr, wpt, arpt, sta)
		# this could/should be using listeners instead ...
#		me.symbols['status.wxr'].setVisible( me.get_switch('toggle_weather') and me.in_mode('toggle_display_mode', ['MAP']));
#		me.symbols['status.wpt'].setVisible( me.get_switch('toggle_waypoints') and me.in_mode('toggle_display_mode', ['MAP']));
#		me.symbols['status.arpt'].setVisible( me.get_switch('toggle_airports') and me.in_mode('toggle_display_mode', ['MAP']));
#		me.symbols['status.sta'].setVisible( me.get_switch('toggle_stations') and  me.in_mode('toggle_display_mode', ['MAP']));
		# Okay, _how_ do we hook this up with FGPlot?
		# printlog(canvas._MP_dbg_lvl, "Total ND update took "~((systime()-_time)*100)~"ms");
		setprop("/instrumentation/navdisplay["~ NdDisplay.id ~"]/update-ms", systime() - _time);
	} # end of update()
}; # end of NDdisplay

