# E-jet-family SYSTEMS
#########################

## LIVERY SELECT
################

aircraft.livery.init("Aircraft/E-jet-family/Models/Liveries/ERJ175");

## LIGHTS
#########

# create all lights
var beacon_switch = props.globals.getNode("controls/switches/beacon", 2);
var beacon = aircraft.light.new("sim/model/lights/beacon", [0.015, 3], "controls/lighting/beacon");

var strobe_switch = props.globals.getNode("controls/switches/strobe", 2);
var strobe = aircraft.light.new("sim/model/lights/strobe", [0.025, 1.5], "controls/lighting/strobe");

## SOUNDS
#########

# seatbelt/no smoking sign triggers
setlistener("controls/switches/seatbelt-sign", func
 {
 props.globals.getNode("sim/sound/seatbelt-sign").setBoolValue(1);

 settimer(func
  {
  props.globals.getNode("sim/sound/seatbelt-sign").setBoolValue(0);
  }, 2);
 });
setlistener("controls/switches/no-smoking-sign", func
 {
 props.globals.getNode("sim/sound/no-smoking-sign").setBoolValue(1);

 settimer(func
  {
  props.globals.getNode("sim/sound/no-smoking-sign").setBoolValue(0);
  }, 2);
 });

## ENGINES
##########

# APU loop function
var apuLoop = func
 {
 if (props.globals.getNode("engines/apu/on-fire").getBoolValue())
  {
  props.globals.getNode("engines/apu/serviceable").setBoolValue(0);
  }
 if (props.globals.getNode("controls/APU/fire-switch").getBoolValue())
  {
  props.globals.getNode("engines/apu/on-fire").setBoolValue(0);
  }
 if (props.globals.getNode("engines/apu/serviceable").getBoolValue() and (props.globals.getNode("controls/APU/master-switch").getBoolValue() or props.globals.getNode("controls/APU/starter").getBoolValue()))
  {
  if (props.globals.getNode("controls/APU/starter").getBoolValue())
   {
   var rpm = getprop("engines/apu/rpm");
   rpm += getprop("sim/time/delta-realtime-sec") * 25;
   if (rpm >= 100)
    {
    rpm = 100;
    }
   setprop("engines/apu/rpm", rpm);
   }
  if (props.globals.getNode("controls/APU/master-switch").getBoolValue() and getprop("engines/apu/rpm") == 100)
   {
   props.globals.getNode("engines/apu/running").setBoolValue(1);
   }
  }
 else
  {
  props.globals.getNode("engines/apu/running").setBoolValue(0);

  var rpm = getprop("engines/apu/rpm");
  rpm -= getprop("sim/time/delta-realtime-sec") * 30;
  if (rpm < 0)
   {
   rpm = 0;
   }
  setprop("engines/apu/rpm", rpm);
  }

 settimer(apuLoop, 0);
 };
# engine loop function
var engineLoop = func(engine_no)
 {
 var tree1 = "engines/engine[" ~ engine_no ~ "]/";
 var tree2 = "controls/engines/engine[" ~ engine_no ~ "]/";

 if (props.globals.getNode(tree1 ~ "on-fire").getBoolValue())
  {
  props.globals.getNode("sim/failure-manager/engines/engine[" ~ engine_no ~ "]/serviceable").setBoolValue(0);
  }
 if (props.globals.getNode(tree2 ~ "fire-bottle-discharge").getBoolValue())
  {
  props.globals.getNode(tree1 ~ "on-fire").setBoolValue(0);
  }
 if (props.globals.getNode("sim/failure-manager/engines/engine[" ~ engine_no ~ "]/serviceable").getBoolValue())
  {
  props.globals.getNode(tree2 ~ "cutoff").setBoolValue(props.globals.getNode(tree2 ~ "cutoff-switch").getBoolValue());
  }
 props.globals.getNode(tree2 ~ "starter").setBoolValue(props.globals.getNode(tree2 ~ "starter-switch").getBoolValue());

 if (getprop("controls/engines/engine-start-switch") == 0 or getprop("controls/engines/engine-start-switch") == 2)
  {
  props.globals.getNode(tree2 ~ "starter").setBoolValue(1);
  }

 if (!props.globals.getNode("engines/apu/running").getBoolValue())
  {
  props.globals.getNode(tree2 ~ "starter").setBoolValue(0);
  }

 settimer(func
  {
  engineLoop(engine_no);
  }, 0);
 };
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(func
  {
  engineLoop(0);
  engineLoop(1);
  apuLoop();
  }, 2);
 });

# startup/shutdown functions
var startup = func
 {
 setprop("controls/electric/battery-switch", 1);
 setprop("controls/electric/engine[0]/generator", 1);
 setprop("controls/electric/engine[1]/generator", 1);
 setprop("controls/engines/engine[0]/cutoff-switch", 1);
 setprop("controls/engines/engine[1]/cutoff-switch", 1);
 setprop("controls/APU/master-switch", 1);
 setprop("controls/APU/starter", 1);

 var listener1 = setlistener("engines/apu/running", func
  {
  if (props.globals.getNode("engines/apu/running").getBoolValue())
   {
   setprop("controls/engines/engine-start-switch", 2);
   settimer(func
    {
    setprop("controls/engines/engine[0]/cutoff-switch", 0);
    setprop("controls/engines/engine[1]/cutoff-switch", 0);
    }, 2);
   removelistener(listener1);
   }
  }, 0, 0);
 var listener2 = setlistener("engines/engine[0]/running", func
  {
  if (props.globals.getNode("engines/engine[0]/running").getBoolValue())
   {
   settimer(func
    {
    setprop("controls/APU/master-switch", 0);
    setprop("controls/APU/starter", 0);
    setprop("controls/electric/battery-switch", 0);
    }, 2);
   removelistener(listener2);
   }
  }, 0, 0);
 };
var shutdown = func
 {
 setprop("controls/electric/engine[0]/generator", 0);
 setprop("controls/electric/engine[1]/generator", 0);
 setprop("controls/engines/engine[0]/cutoff-switch", 1);
 setprop("controls/engines/engine[1]/cutoff-switch", 1);
 };

# listener to activate these functions accordingly
setlistener("sim/model/start-idling", func(idle)
 {
 var run = idle.getBoolValue();
 if (run)
  {
  startup();
  }
 else
  {
  shutdown();
  }
 }, 0, 0);

## GEAR
#######

# prevent retraction of the landing gear when any of the wheels are compressed
setlistener("controls/gear/gear-down", func
 {
 var down = props.globals.getNode("controls/gear/gear-down").getBoolValue();
 if (!down and (getprop("gear/gear[0]/wow") or getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow")))
  {
  props.globals.getNode("controls/gear/gear-down").setBoolValue(1);
  }
 });

setlistener("/controls/gear/gear-down", func { controls.click(8) } );
controls.gearDown = func(v) {
    if (v < 0) {
        if(!getprop("gear/gear[1]/wow"))setprop("/controls/gear/gear-down", 0);
    } elsif (v > 0) {
      setprop("/controls/gear/gear-down", 1);
    }
}

## INSTRUMENTS
##############

var instruments =
 {
 calcBugDeg: func(bug, limit)
  {
  var heading = getprop("orientation/heading-magnetic-deg");
  var bugDeg = 0;

  while (bug < 0)
   {
   bug += 360;
   }
  while (bug > 360)
   {
   bug -= 360;
   }
  if (bug < limit)
   {
   bug += 360;
   }
  if (heading < limit)
   {
   heading += 360;
   }
  # bug is adjusted normally
  if (math.abs(heading - bug) < limit)
   {
   bugDeg = heading - bug;
   }
  elsif (heading - bug < 0)
   {
   # bug is on the far right
   if (math.abs(heading - bug + 360 >= 180))
    {
    bugDeg = -limit;
    }
   # bug is on the far left
   elsif (math.abs(heading - bug + 360 < 180))
    {
    bugDeg = limit;
    }
   }
  else
   {
   # bug is on the far right
   if (math.abs(heading - bug >= 180))
    {
    bugDeg = -limit;
    }
   # bug is on the far left
   elsif (math.abs(heading - bug < 180))
    {
    bugDeg = limit;
    }
   }

  return bugDeg;
  },
 loop: func
  {
  instruments.setHSIBugsDeg();
  instruments.setSpeedBugs();
  instruments.setMPProps();
  instruments.calcEGTDegC();

  settimer(instruments.loop, 0);
  },
 # set the rotation of the HSI bugs
 setHSIBugsDeg: func
  {
  setprop("sim/model/ERJ/heading-bug-pfd-deg", instruments.calcBugDeg(getprop("autopilot/settings/heading-bug-deg"), 80));
  setprop("sim/model/ERJ/heading-bug-deg", instruments.calcBugDeg(getprop("autopilot/settings/heading-bug-deg"), 37));
  setprop("sim/model/ERJ/nav1-bug-deg", instruments.calcBugDeg(getprop("instrumentation/nav[0]/heading-deg"), 37));
  setprop("sim/model/ERJ/nav2-bug-deg", instruments.calcBugDeg(getprop("instrumentation/nav[1]/heading-deg"), 37));
  if (getprop("autopilot/route-manager/route/num") > 0 and getprop("autopilot/route-manager/wp[0]/bearing-deg") != nil)
   {
   setprop("sim/model/ERJ/wp-bearing-deg", instruments.calcBugDeg(getprop("autopilot/route-manager/wp[0]/bearing-deg"), 45));
   }
  },
 setSpeedBugs: func
  {
  setprop("sim/model/ERJ/ias-bug-kt-norm", getprop("autopilot/settings/target-speed-kt") - getprop("velocities/airspeed-kt"));
  setprop("sim/model/ERJ/mach-bug-kt-norm", (getprop("autopilot/settings/target-speed-mach") - getprop("velocities/mach")) * 600);
  },
 setMPProps: func
  {
  var calcMPDistance = func(tree)
   {
   var x = getprop(tree ~ "position/global-x");
   var y = getprop(tree ~ "position/global-y");
   var z = getprop(tree ~ "position/global-z");
   var coords = geo.Coord.new().set_xyz(x, y, z);

   var distance = nil;
   call(func distance = geo.aircraft_position().distance_to(coords), nil, var err = []);
   if (size(err) or distance == nil)
    {
    return 0;
    }
   else
    {
    return distance;
    }
   };
  var calcMPBearing = func(tree)
   {
   var x = getprop(tree ~ "position/global-x");
   var y = getprop(tree ~ "position/global-y");
   var z = getprop(tree ~ "position/global-z");
   var coords = geo.Coord.new().set_xyz(x, y, z);

   return geo.aircraft_position().course_to(coords);
   };
  if (getprop("ai/models/multiplayer[0]/valid"))
   {
   setprop("sim/model/ERJ/multiplayer-distance[0]", calcMPDistance("ai/models/multiplayer[0]/"));
   setprop("sim/model/ERJ/multiplayer-bearing[0]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[0]/"), 45));
   }
  if (getprop("ai/models/multiplayer[1]/valid"))
   {
   setprop("sim/model/ERJ/multiplayer-distance[1]", calcMPDistance("ai/models/multiplayer[1]/"));
   setprop("sim/model/ERJ/multiplayer-bearing[1]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[1]/"), 45));
   }
  if (getprop("ai/models/multiplayer[2]/valid"))
   {
   setprop("sim/model/ERJ/multiplayer-distance[2]", calcMPDistance("ai/models/multiplayer[2]/"));
   setprop("sim/model/ERJ/multiplayer-bearing[2]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[2]/"), 45));
   }
  if (getprop("ai/models/multiplayer[3]/valid"))
   {
   setprop("sim/model/ERJ/multiplayer-distance[3]", calcMPDistance("ai/models/multiplayer[3]/"));
   setprop("sim/model/ERJ/multiplayer-bearing[3]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[3]/"), 45));
   }
  if (getprop("ai/models/multiplayer[4]/valid"))
   {
   setprop("sim/model/ERJ/multiplayer-distance[4]", calcMPDistance("ai/models/multiplayer[4]/"));
   setprop("sim/model/ERJ/multiplayer-bearing[4]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[4]/"), 45));
   }
  if (getprop("ai/models/multiplayer[5]/valid"))
   {
   setprop("sim/model/ERJ/multiplayer-distance[5]", calcMPDistance("ai/models/multiplayer[5]/"));
   setprop("sim/model/ERJ/multiplayer-bearing[5]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[5]/"), 45));
   }
  },
 calcEGTDegC: func()
  {
  if (getprop("engines/engine[0]/egt-degf") != nil)
   {
   setprop("engines/engine[0]/egt-degc", (getprop("engines/engine[0]/egt-degf") - 32) * 1.8);
   }
  if (getprop("engines/engine[1]/egt-degf") != nil)
   {
   setprop("engines/engine[1]/egt-degc", (getprop("engines/engine[1]/egt-degf") - 32) * 1.8);
   }
  }
 };
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(instruments.loop, 2);
 });

## AUTOPILOT
############

# Basic roll mode controller
var set_ap_basic_roll = func
 {
 var roll = getprop("instrumentation/attitude-indicator[0]/indicated-roll-deg");
 if (math.abs(roll) > 5)
  {
  setprop("controls/autoflight/basic-roll-mode", 0);
  setprop("controls/autoflight/basic-roll-select", roll);
  }
 else
  {
  var heading = getprop("instrumentation/heading-indicator[0]/indicated-heading-deg");
  setprop("controls/autoflight/basic-roll-mode", 1);
  setprop("controls/autoflight/basic-roll-heading-select", heading);
  }
 };
# Basic pitch mode controller
var set_ap_basic_pitch = func
 {
 var pitch = getprop("instrumentation/attitude-indicator[0]/indicated-pitch-deg");
 setprop("controls/autoflight/pitch-select", int((pitch / 0.5) + 0.5) * 0.5);
 };
setlistener("controls/autoflight/lateral-mode", func(v)
 {
 if (v.getValue() == 0) set_ap_basic_roll();
 }, 0, 0);
setlistener("controls/autoflight/vertical-mode", func(v)
 {
 if (v.getValue() == 0 and getprop("controls/autoflight/lateral-mode") != 2) set_ap_basic_pitch();
 }, 0, 0);
setlistener("controls/autoflight/autopilot/engage", func(v)
 {
 if (v.getBoolValue())
  {
  var lat = getprop("controls/autoflight/lateral-mode");
  var ver = getprop("controls/autoflight/vertical-mode");
  if (lat == 0) set_ap_basic_roll();
  if (ver == 0 and lat != 2) set_ap_basic_pitch();
  }
 }, 0, 0);
setlistener("controls/autoflight/flight-director/engage", func(v)
 {
 if (v.getBoolValue())
  {
  var lat = getprop("controls/autoflight/lateral-mode");
  var ver = getprop("controls/autoflight/vertical-mode");
  if (lat == 0) set_ap_basic_roll();
  if (ver == 0 and lat != 2) set_ap_basic_pitch();
  }
 }, 0, 0);
