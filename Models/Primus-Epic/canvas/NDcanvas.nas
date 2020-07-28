##
##### Citation X - Canvas NdDisplay #####
##### Christian Le Moigne (clm76) - oct 2016 - Nov 2018 ###

var nasal_dir = getprop("/sim/aircraft-dir") ~ "/Models/Primus-Epic/canvas";
io.load_nasal(nasal_dir ~ '/NavMap.nas', "fgMap");
io.include('init.nas');

var clk_hour = "sim/time/real/hour";
var clk_min = "sim/time/real/minute";
var clk_sec = "sim/time/real/second";
var chrono = ["instrumentation/mfd/chrono",
                "instrumentation/mfd[1]/chrono"];
var wx = ["instrumentation/mfd/range-nm","instrumentation/mfd[1]/range-nm"];
var bank = "autopilot/settings/bank-limit";
var sat = "environment/temperature-degc";
var tat = "environment/temperature-degc"; #TODO calculate real total air temperature!
var tas = "instrumentation/airspeed-indicator/true-speed-kt";
var gspd = "velocities/groundspeed-kt";
var etx = ["instrumentation/mfd/etx","instrumentation/mfd[1]/etx"];
var nav_dist = "autopilot/internal/nav-distance";
var nav_id = "autopilot/internal/nav-id";
var nav_type = "autopilot/internal/nav-type";
var nav_type = "autopilot/internal/nav-type";
var hdg_ann = "autopilot/settings/heading-bug-deg";
var dist_rem = "autopilot/route-manager/distance-remaining-nm";
var Wtot = nil;
var chronH = nil;
var chronM = nil;
var chronS = nil;

var wind_spd	=	props.globals.getNode("environment/wind-speed-kt", 1);
var wind_dir	=	props.globals.getNode("environment/wind-from-heading-deg", 1);
var heading	=	props.globals.getNode("orientation/heading-deg", 1);

var cur_wp	=	props.globals.getNode("autopilot/route-manager/current-wp", 1);
var ete		=	props.globals.getNode("autopilot/route-manager/ete", 1);

#For the systems part
var door_L1	=	props.globals.getNode("sim/model/door-positions/l1/position-norm", 1);
var door_L2	=	props.globals.getNode("sim/model/door-positions/l2/position-norm", 1);
var door_R1	=	props.globals.getNode("sim/model/door-positions/r1/position-norm", 1);
var door_R2	=	props.globals.getNode("sim/model/door-positions/r2/position-norm", 1);

var grossweight	=	props.globals.getNode("fdm/jsbsim/inertia/weight-lbs", 1);

var batt1v	=	props.globals.getNode("systems/electrical/left-bus", 1);
var batt2v	=	props.globals.getNode("systems/electrical/right-bus", 1);

#var eng0oq	=	props.globals.getNode("engines/engine[0]/oil-quantity", 1);
#var eng1oq	=	props.globals.getNode("engines/engine[1]/oil-quantity", 1);

	var MFDDisplay = {
		new: func(x) {
			var m = {parents:[MFDDisplay]};
      if (!x) {
			  m.canvas = canvas.new({
				  "name": "MFD_L", 
				  "size": [900, 753],
				  "view": [900, 753],
				  "mipmapping": 1 
			  });
			  m.canvas.addPlacement({"node": "mfd.upper.F"});
			  m.canvas.setColorBackground(0,0,0,0);
      } else {
			  m.canvas = canvas.new({
				  "name": "MFD_R", 
				  "size": [900, 753],
				  "view": [900, 753],
				  "mipmapping": 1 
			  });
			  m.canvas.addPlacement({"node": "screenR_F"});
			  m.canvas.setColorBackground(0,0,0,0);
      }
			  m.mfd = m.canvas.createGroup();
			  canvas.parsesvg(m.mfd, get_local_path("Images/ND_F.svg"));

			### Texts init ###
			m.text = {};
			m.text_val = ["wx","bank","sat","tat","tas","gspd","clock",
										"chrono","navDist","navId","navTtw","navType",
										"hdgAnn","main","range","distRem","windSpeed","sat2","tat2","gw","batt1Volts","batt2Volts",
					"wpNext","wpNextDist","wpNextETA","wpNextFuel100","wpNextFuel1","wpDest","wpDestDist","wpDestETA","wpDestFuel100","wpDestFuel1"];
			foreach(var element;m.text_val) {
				m.text[element] = m.mfd.getElementById(element);
			}
			
			m.symbol = {};
			m.symbol_val = ["windArrow","mapSelected","planSelected","systemsSelected","doorL1","doorL2","doorR1","doorR2"];

			foreach(var element;m.symbol_val) {
				m.symbol[element] = m.mfd.getElementById(element);
			}
			
			m.layer = {};
			m.layer_val = ["layerMP","layerSystems"];
			
			foreach(var element;m.layer_val) {
				m.layer[element] = m.mfd.getElementById(element);
			}
			
			### Menus init ###
			m.menu = ["instrumentation/mfd/menu-num",
                "instrumentation/mfd[1]/menu-num"];
			m.s_menu = ["instrumentation/mfd/s-menu",
                  "instrumentation/mfd[1]/s-menu"];

			m.menus = {};
			m.menu_val = ["menu1","menu2","menu3","menu4","menu5","menu1b",
										"menu2b","menu3b","menu4b","menu5b"];
			foreach(var element;m.menu_val) {
				m.menus[element] = m.mfd.getElementById(element);
			}

			#m.rect = {};
			#m.cdr = ["cdr1","cdr2","cdr3","cdr4","cdr5"];
			#foreach(var element;m.cdr) {
			#	m.rect[element] = m.mfd.getElementById(element);
			#}

			m.design = {}; 
			m.pat = ["trueNorth"];
			foreach(var element;m.pat) {
				m.design[element] = m.mfd.getElementById(element);
			}
			m.design.trueNorth.hide(); # initialisation

			m.tod = m.mfd.createChild("text","TOD")
				.setTranslation(450,378)
				.setAlignment("center-center")
				.setText("TOD")
				.setFont("LiberationFonts/LiberationMono-Bold.ttf")
				.setFontSize(36)
				.setColor(1,1,0)
				.setScale(1.5);
			m.tod.hide();

			m.tod_timer = nil;
      m.ete = nil;
      m.white = [1,1,1];
      m.blue = [0,1,0.9];

			return m;	
		}, # end of new

		listen : func(x) { 
			setlistener("instrumentation/primus2000/dc840/mfd-map", func(n) {
				if (n.getValue()) me.design.trueNorth.show();
				else me.design.trueNorth.hide();
			},0,0);

			setlistener("autopilot/locks/alm-tod", func (n) {
				if (n.getValue()) {
					var t = 0;
					me.tod_timer = maketimer(0.5,func() {
						if (t==0) {me.tod.show()}
						if (t==1) {me.tod.hide()}					
						t+=1;
						if(t==2) {t=0}
					});
					me.tod_timer.start();
				} else { 
					if (me.tod_timer != nil and me.tod_timer.isRunning) {
					  me.tod_timer.stop();
					  me.tod.hide();
          }
				}
			},0,0);

			setlistener("autopilot/route-manager/active", func (n) {
				setprop("instrumentation/efis/fp-active",n.getValue());
			},0,0);

      setlistener(me.menu[x], func {
        me.razMenu();
        me.selectMenu(x);
      },0,0);

      setlistener(me.s_menu[x], func {
        me.razMenu();
        me.selectMenu(x);
      },0,0);

      setlistener("instrumentation/mfd["~x~"]/cdr-tot", func {
        me.showRect(x);
      },0,0);

		}, # end of listen

		update: func(x) {
			
			var page = getprop("instrumentation/mfd/upper-page");
			
			if(page=="map" or page=="plan"){
				me.text.sat.setText(sprintf("%2d",getprop(sat)));
				me.text.tat.setText(sprintf("%2d",getprop(tat)));
				me.text.tas.setText(sprintf("%3d",getprop(tas)));
				#me.text.gspd.setText(sprintf("%3d",getprop(gspd)));
				me.text.navDist.setText(sprintf("%3.1f",getprop(nav_dist))~" NM");			
				me.text.navId.setText(getprop(nav_id));
				#me.text.navType.setText(getprop(nav_type));
				#me.text.hdgAnn.setText(sprintf("%03d",getprop(hdg_ann)));
				
				me.text.windSpeed.setText(sprintf("%3d", math.round(wind_spd.getValue())));
				
				me.symbol.windArrow.setRotation((wind_dir.getValue()-heading.getValue())*D2R);
				
				#Waypoint indication
				var cwp = cur_wp.getValue() or 1;
				if(cwp<1){
					cwp=1;
				}
				var cwp_id = getprop("autopilot/route-manager/route/wp["~cwp~"]/id") or "";
				var cwp_dist = getprop("autopilot/route-manager/wp["~(cwp-1)~"]/dist") or 999;
				var cwp_eta = getprop("autopilot/route-manager/wp["~(cwp-1)~"]/eta") or "--H--";
				me.text.wpNext.setText(cwp_id);
				if(cwp_dist<100){
					me.text.wpNextDist.setText(sprintf("%2.1f",cwp_dist));
				}else{
					me.text.wpNextDist.setText(sprintf("%3d",math.round(cwp_dist)));
				}
				me.text.wpNextETA.setText(cwp_eta);
				
				me.text.wpDest.setText(getprop("autopilot/route-manager/destination/airport"));
				var dest_d=getprop("autopilot/route-manager/distance-remaining-nm");
				if(dest_d<100){
					me.text.wpDestDist.setText(sprintf("%2.1f",dest_d));
				}else{
					me.text.wpDestDist.setText(sprintf("%3d",math.round(dest_d)));
				}
				var ete=ete.getValue();
				var ete_min=math.round(ete/60);
				var ete_h=int(ete_min/60);
				ete_min=ete_min-(ete_h*60);
				if(ete_h<99){
					me.text.wpDestETA.setText(ete_h~"H"~ete_min);
				}else{
					me.text.wpDestETA.setText("--H--");
				}
				
				me.layer.layerMP.show();
				me.layer.layerSystems.hide();
				
				if(page=="map"){
					me.symbol.mapSelected.show();
					me.symbol.planSelected.hide();
					me.symbol.systemsSelected.hide();
				}else if(page=="plan"){
					me.symbol.mapSelected.hide();
					me.symbol.planSelected.show();
					me.symbol.systemsSelected.hide();
				}
			}else{
				me.symbol.mapSelected.hide();
				me.symbol.planSelected.hide();
				me.symbol.systemsSelected.show();
				me.layer.layerMP.hide();
				me.layer.layerSystems.show();
				#Now the systems animation
				#General Part
				me.text.sat2.setText(sprintf("%2d",getprop(sat)));
				me.text.tat2.setText(sprintf("%2d",getprop(tat)));
				me.text.gw.setText(sprintf("%5d", math.round(grossweight.getValue())));
				#ELEC Part
				me.text.batt1Volts.setText(sprintf("%2.1f", batt1v.getValue()));
				me.text.batt2Volts.setText(sprintf("%2.1f", batt2v.getValue()));
				
				if(door_L1.getValue()==0){
					me.symbol.doorL1.setColorFill(0,1,0,1);
				}else{
					me.symbol.doorL1.setColorFill(1,0,0,1);
				}
				if(door_L2.getValue()==0){
					me.symbol.doorL2.setColorFill(0,1,0,1);
				}else{
					me.symbol.doorL2.setColorFill(1,0,0,1);
				}
				if(door_R1.getValue()==0){
					me.symbol.doorR1.setColorFill(0,1,0,1);
				}else{
					me.symbol.doorR1.setColorFill(1,0,0,1);
				}
				if(door_R2.getValue()==0){
					me.symbol.doorR2.setColorFill(0,1,0,1);
				}else{
					me.symbol.doorR2.setColorFill(1,0,0,1);
				}
			}

      me.ete = getprop("autopilot/internal/nav-ttw");
		  if (!me.ete or size(me.ete) > 10) {me.ete = "ETE 0:00"}
			me.text.navTtw.setText(me.ete);
			#if (getprop(dist_rem) > 0) {
			#	me.text.distRem.setText(sprintf("%.0f",getprop(dist_rem))~" NM");
			#} else {me.text.distRem.setText("")}

			settimer(func me.update(x),0.1);

		}, # end of update


    setColor : func(color) {
      for (var n=5;n<10;n+=1) {
        me.menus[me.menu_val[n]].setColor(color);
      }
    }, # end of setColor

    razMenu : func {
      for (var n=1;n<10;n+=1) me.menus[me.menu_val[n]].setText("");
    }, # end of razMenu

		#Disabled
		showRect: func(x) { 
			var n = 0;
			foreach(var element;me.cdr) {
				if (getprop("instrumentation/mfd["~x~"]/cdr"~n)) {
					me.rect[element].show();
				} else {me.rect[element].hide()}
				n+=1;
			}
		}, # end of showRect

	}; # end of MFDDisplay

###### Main #####
var mfd_setl = setlistener("sim/signals/fdm-initialized", func() {
  for (var x=0;x<2;x+=1) {
    fgMap.NavMap.new(x); # To navMap.nas for background
	  var mfd = MFDDisplay.new(x);
	  mfd.listen(x);
    #mfd.showRect(x);
	  mfd.update(x);
  }
	print('MFD Canvas ... Ok');
	removelistener(mfd_setl); 
},0,0);

