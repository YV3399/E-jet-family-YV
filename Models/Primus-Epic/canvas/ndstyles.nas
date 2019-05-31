##
# ==============================================================================
# Boeing Navigation Display by Gijs de Rooy
# See: http://wiki.flightgear.org/Canvas_ND_Framework
#
# Adapted for the Citation X by C. Le Moigne (clm76) - 2016
# ==============================================================================
# This file makes use of the MapStructure framework, see: http://wiki.flightgear.org/Canvas_MapStructure
#

var ALWAYS = func 1;
var NOTHING = func nil;

var NDStyles = {
	'Citation': {
		font_mapper: func(family, weight) {
			if( family == "Liberation Sans" and weight == "Normal" )
				return "LiberationFonts/LiberationSans-Regular.ttf";
		},

		svg_filename: get_local_path("Images/ND_B.svg"),
		initialize_elements: func(me) {
			foreach(var element; ["plane","hsi","compass","hdgIndex","hdgBug", 															"arrowL","arrowR","rangeL","rangeLtxt", 														"rangeR","rangeRtxt","hdgLine","tcas", 															"tcasLabel","tcasValue"])
				me.symbols[element] = me.nd.getElementById(element);
		},

		layers: [

			{ name:'APT-citation',
				isMapStructure:1,
				update_on:['toggle_airports','toggle_display_mode','toggle_range'],
				predicate: func(nd, layer) {
					var visible = nd.get_switch('toggle_airports') and (nd.rangeNm() <= 80); #and nd.in_mode('toggle_display_mode', ['MAP']);
					layer.group.setVisible( visible );
					if (visible) {
						layer.update();
					}
				}, 
				style: {
					scale_icon:1.3,
					scale_text:1.3,
					icon_color: [0,1,0.9],
					font_color :[0,1,0.9],
					text_offset: [30,20]
				},
				options: {range_dependant: 1},				
				'z-index': -1,
			}, # end of APT layer

			{ name:'VOR-citation',
				isMapStructure:1,			
				update_on:['toggle_stations','toggle_display_mode','toggle_range'],
				predicate: func(nd, layer) {
					var visible = nd.get_switch('toggle_stations') and nd.in_mode('toggle_display_mode', ['MAP','PLAN']) and (nd.rangeNm() <= 80);
					layer.group.setVisible(visible);
					if (visible) {
						layer.update();
					}
				},
				style:{
					scale_factor:1.6,
					text_offset:[40,40],
					text_scale:1.3
				},
				options: {
					range_dependant: 1,				
					course_dependant:1,
				},
				'z-index': -2,
			}, # end of VOR layer

			{ name:'FIX-citation',
				isMapStructure:1,
				update_on:['toggle_display_mode','toggle_waypoints','toggle_range'],
				predicate: func(nd, layer) {
					var visible = nd.get_switch('toggle_waypoints') and nd.in_mode('toggle_display_mode', ['MAP','PLAN']) and nd.rangeNm() < 40;
					layer.group.setVisible( visible );
					if (visible) {
						layer.update();
					}
				},
				style:{
					scale_factor:1.6,
					text_offset:[40,40],
					text_scale:1.3
				},
				options:{range_dependant:1},
				'z-index': -3,
			}, # end of FIX layer

			{ name:'RTE',
				isMapStructure:1,
				update_on:['toggle_range','toggle_display_mode'],
				predicate: func(nd, layer) {
					var visible= nd.in_mode('toggle_display_mode', ['MAP','PLAN']);
					layer.group.setVisible( visible );
					if (visible)
						layer.update();
				},
				'z-index': 1,
			}, # end of route layer

			{ name:'WPT',
				isMapStructure:1,
				update_on:['toggle_cruise_alt','toggle_range','toggle_display_mode','toggle_fp_active'],
				predicate: func(nd, layer) {
					var visible= nd.in_mode('toggle_display_mode', ['MAP','PLAN']);
					layer.group.setVisible( visible );
					if (visible)
						layer.update();
				},
				'z-index': 2,
			}, # end of waypoint layer

			{ name: 'ALT-profile',
				isMapStructure:1,
				update_on:['toggle_cruise_alt','toggle_range','toggle_display_mode','toggle_fp_active'],
				predicate: func(nd, layer) {
					var visible= nd.get_switch('toggle_fp_active') and nd.in_mode('toggle_display_mode', ['MAP','PLAN']);
					layer.group.setVisible(visible);
					if (visible)
						layer.update();
				},
				'z-index': 3,
			}, # end of altitude profile layer

			{ name:'TFC-citation',
				isMapStructure:1,
				always_update:1,
				update_on:['toggle_display_mode','toggle_traffic'],
				predicate: func(nd, layer) {
					var visible = nd.in_mode('toggle_display_mode', ['MAP','PLAN']) and nd.get_switch('toggle_traffic');
					layer.group.setVisible( visible );
					if (visible)
						layer.update();
				}, 
				style: {
					scale_icon:2,
					scale_text:2,
				},
				'z-index': 2,
			}, # end of traffic layer

#			{	name:'WXR_live',
#				isMapStructure:1,
#				always_update: 1,
#				update_on:['toggle_range','toggle_weather','toggle_display_mode','toggle_weather_live'],
#				predicate: func(nd, layer) {
#					var visible = nd.get_switch('toggle_weather') and
#						nd.get_switch('toggle_weather_live') and
#						nd.get_switch('toggle_display_mode') != "PLAN";
#					layer.group.setVisible(visible);
#					if (visible) {
#						layer.update();
#					}
#				},
#				'z-index': -100,
#			},# end of Weather_live layer

			{	name:'WXR',
				isMapStructure:1,
				update_on:[ {rate_hz: 0.1},				 'toggle_range','toggle_weather','toggle_display_mode', 'toggle_weather_live'],
				predicate: func(nd, layer) {
					var visible=nd.get_switch('toggle_weather') and
						!nd.get_switch('toggle_weather_live') and
						nd.get_switch('toggle_display_mode') != "PLAN";
					layer.group.setVisible(visible);
					if (visible) {
						#print("storms update requested! (timer issue when closing the dialog?)");
						layer.update();
					}
				}, 
				'z-index': -4,
			}, # end of storms layer

		], # end of vector with configured layers

		features: [

			{	id:'compass',
				impl: {
					init: func(nd,symbol),
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['MAP']),
					is_true: func(nd) {
#						var hdg = getprop("/orientation/heading-magnetic-deg");
						var hdg = getprop("/orientation/heading-deg");
						nd.symbols.compass.setRotation(-hdg*D2R);
						nd.symbols.compass.show();
					},
					is_false: func(nd) nd.symbols.compass.hide(),
				},
			}, # end of compass

			{	id: 'hsi',
				impl: { 
					init: func(nd, symbol), 
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['MAP']), 
					is_true: func(nd) {
#						var hsi = getprop("orientation/heading-magnetic-deg");
						var hsi = getprop("orientation/heading-deg");
						nd.symbols.hsi.setText(sprintf("%03d",hsi));
						nd.symbols.hsi.show();
					},
					is_false: func(nd) nd.symbols.hsi.hide(),
				},
			}, # end of hsi

			{	id: 'rangeL',
				impl: { 
					init: func(nd, symbol), 
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['MAP','PLAN']), 
					is_true: func(nd) {
						var range = getprop("instrumentation/efis/inputs/range-nm");
						nd.symbols.rangeLtxt.setText(sprintf("%d",range/2));
						nd.symbols.rangeL.show();
					},
					is_false: func(nd,symbol) nd.symbols.rangeL.hide(),
				},
			}, # end of rangeL

			{	id: 'rangeR',
				impl: { 
					init: func(nd, symbol), 
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['MAP',"PLAN"]), 
					is_true: func(nd) {
						var range = getprop("instrumentation/efis/inputs/range-nm");
						nd.symbols.rangeRtxt.setText(sprintf("%d",range/2));
						nd.symbols.rangeR.show();
					},
					is_false: func(nd) nd.symbols.rangeR.hide(),
				},
			}, # end of rangeR

			{	id:'hdgBug',
				impl: {
					init: func(nd,symbol),
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['MAP']),
					is_true: func(nd) {
#						if(getprop("autopilot/internal/heading-bug-error-deg")!=nil) {
						var hdg_bug = getprop("autopilot/internal/heading-bug-error-deg") or 0;
#							var hdg_Bug = int(getprop("autopilot/internal/heading-bug-error-deg"));
							nd.symbols.hdgBug.setCenter(450,516);
							nd.symbols.hdgBug.setRotation(hdg_bug*D2R);
							nd.symbols.hdgBug.show();
#						}
					},
					is_false: func(nd) nd.symbols.hdgBug.hide(),
				},
			}, # end of hdgBug

			{	id:'arrowL',
				impl: {
					init: func(nd,symbol),
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['MAP']),
					is_true: func(nd) {
						var hbed = getprop("autopilot/internal/heading-bug-error-deg");
						if (hbed != nil) {
							if (hbed < -53) {nd.symbols.arrowL.show()}
							else {nd.symbols.arrowL.hide()}
						}
					},
					is_false: func(nd) nd.symbols.arrowL.hide(),
				},
			}, # end of arrowL

			{	id:'arrowR',
				impl: {
					init: func(nd,symbol),
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['MAP']),
					is_true: func(nd) {
						var hbed = getprop("autopilot/internal/heading-bug-error-deg");
						if (hbed != nil) {
							if (hbed > 53) {nd.symbols.arrowR.show()}
							else {nd.symbols.arrowR.hide()}
						}
					},
					is_false: func(nd) nd.symbols.arrowR.hide(),
				},
			}, # end of arrowR

#			{	id: 'direct',
#				impl: { 
#					init: func(nd, symbol), 
#					predicate: func(nd) nd.in_mode('toggle_display_mode', ['MAP']), 
#					is_true: func(nd) nd.symbols.direct.show(),
#					is_false: func(nd) nd.symbols.direct.hide(),
#				},
#			}, # end of direct

			{	id: 'hdgLine',
				impl: { 
					init: func(nd, symbol), 
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['MAP']), 
					is_true: func(nd) {
						var hdg_bug = getprop("autopilot/internal/heading-bug-error-deg") or 0;
						nd.symbols.hdgLine.setCenter(450,484);
						nd.symbols.hdgLine.setRotation(hdg_bug*D2R);
						nd.symbols.hdgLine.show();
					},
					is_false: func(nd) nd.symbols.hdgLine.hide(),
				},
			}, # end of hdgLine

			{	id: 'hdgIndex',
				impl: { 
					init: func(nd, symbol), 
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['MAP']), 
					is_true: func(nd) nd.symbols.hdgIndex.show(),
					is_false: func(nd) nd.symbols.hdgIndex.hide(),
				},
			}, # end of hdgIndex

			{	id: 'airplane',
				impl: { 
					init: func(nd, symbol), 
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['PLAN']), 
					is_true: func(nd) {
						var rot = getprop("/orientation/heading-deg");
						nd.symbols.airplane.setRotation(rot*D2R);
					},
					is_false: func(nd) nd.symbols.airplane.setRotation(0),				
				},
			}, # end of airplane

#			{	id: 'tcasLabel',
#				impl: { 
#					init: func(nd, symbol), 
#					predicate: func(nd) nd.in_mode('toggle_display_mode', ['PLAN','MAP']), 
#					is_true: func(nd) {
#						nd.symbols.tcasLabel.show();
#					},
#					is_false: func(nd) {
#						nd.symbols.tcasLabel.hide();
#					}
#				},
#			}, # end of tcasLabel

			{	id: 'tcasValue',
				impl: { 
					init: func(nd, symbol), 
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['PLAN','MAP']) and nd.get_switch('toggle_traffic'), 
					is_true: func(nd) nd.symbols.tcasValue.setText("AUTO"),
					is_false: func(nd) nd.symbols.tcasValue.setText("OFF"),
				},
			}, # end of tcasValue

			{	id:'tfcRangeInt',
				impl: {
					init: func(nd,symbol),
					predicate: func(nd) nd.in_mode('toggle_display_mode', ['PLAN','MAP']) and nd.get_switch('toggle_traffic'),
					is_true: func(nd) nd.symbols.tfcRangeInt.show(),
					is_false: func(nd) nd.symbols.tfcRangeInt.hide(),
				},
			}, # end of tfcRangeInt

			{ id:'altArc',
				impl: {
					init: func(nd,symbol),
					predicate: func(nd) (nd.in_mode('toggle_display_mode', ['MAP'])),
					is_true: func(nd) {
						var altDiff = (getprop("autopilot/settings/target-altitude-ft") or 0)-(getprop("instrumentation/altimeter/indicated-altitude-ft") or 0);
						if (abs(nd.aircraft_source.get_vspd()) > 1 and altDiff/nd.aircraft_source.get_vspd() > 0) {
							var altRangeNm = altDiff/nd.aircraft_source.get_vspd()*nd.aircraft_source.get_gnd_spd()*KT2MPS*M2NM;
							if(altRangeNm > 1) {
								var altRangePx = (350/nd.rangeNm())*altRangeNm;
								if (altRangePx > 700)
									altRangePx = 700;
								nd.symbols.altArc.setTranslation(0,-altRangePx);
							}
							nd.symbols.altArc.show();
						} else
							nd.symbols.altArc.hide();
					},
					is_false: func(nd) nd.symbols.altArc.hide(),
				},
			}, # end of altArc

		], # end of vector with features

	}, # end of Citation style

}; # end of NDStyles

