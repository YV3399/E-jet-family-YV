# E-Jet-Family
#By Gabriel Hernandez(YV3399)

setlistener("/sim/signals/fdm-initialized", func {


var beacon = aircraft.light.new( "/sim/model/lights/beacon", [0,2, ], "/controls/lighting/beacon" );
var strobe = aircraft.light.new( "/sim/model/lights/strobe", [0,2, ], "/controls/lighting/strobe" );

strobe_switch = props.globals.getNode("controls/switches/strobe", 1);
beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);

setprop("/controls/lighting/strobe",0);
setprop("/controls/lighting/beacon",0);
setprop("/controls/lighting/landing-lights[0]",0);
setprop("/controls/lighting/landing-lights[1]",0);
setprop("/controls/lighting/landing-lights[2]",0);
setprop("/controls/lighting/logo-lights",0);
setprop("/controls/lighting/nav-lights",0);
});
