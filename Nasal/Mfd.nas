### Citation X ####
### C. Le Moigne (clm76) - 2016  ###


props.globals.initNode("instrumentation/mfd/menu-num",0,"BOOL");
props.globals.initNode("instrumentation/mfd[1]/menu-num",0,"BOOL");
props.globals.initNode("instrumentation/mfd/s-menu",0,"INT");
props.globals.initNode("instrumentation/mfd[1]/s-menu",0,"INT");
props.globals.initNode("instrumentation/mfd/cdr-tot",0,"INT");
props.globals.initNode("instrumentation/mfd[1]/cdr-tot",0,"INT");
props.globals.initNode("instrumentation/mfd/map",0,"BOOL");
props.globals.initNode("instrumentation/mfd[1]/map",0,"BOOL");
props.globals.initNode("instrumentation/mfd/outputs/apt",0,"BOOL");
props.globals.initNode("instrumentation/mfd[1]/outputs/apt",0,"BOOL");
props.globals.initNode("instrumentation/mfd/outputs/vor",0,"BOOL");
props.globals.initNode("instrumentation/mfd[1]/outputs/vor",0,"BOOL");
props.globals.initNode("instrumentation/mfd/outputs/fix",0,"BOOL");
props.globals.initNode("instrumentation/mfd[1]/outputs/fix",0,"BOOL");
props.globals.initNode("instrumentation/efis/baro-hpa",0,"BOOL");
for (var i=0;i<5;i+=1) {
	props.globals.initNode("instrumentation/mfd/cdr"~i,0,"BOOL");
	props.globals.initNode("instrumentation/mfd[1]/cdr"~i,0,"BOOL");
}
for (var i=0;i<6;i+=1) {
	props.globals.initNode("instrumentation/mfd/btn"~i,0,"BOOL");
	props.globals.initNode("instrumentation/mfd[1]/btn"~i,0,"BOOL");
}
var menu_num = ["instrumentation/mfd/menu-num",
                "instrumentation/mfd[1]/menu-num"];
var path = ["instrumentation/mfd/",
            "instrumentation/mfd[1]/"];
var s_menu = ["instrumentation/mfd/s-menu",
              "instrumentation/mfd[1]/s-menu"];
var alt_m = "instrumentation/efis/alt-meters";
var baro = "instrumentation/efis/baro-hpa";
var apt = ["instrumentation/mfd/outputs/apt",
           "instrumentation/mfd[1]/outputs/apt"];
var vor = ["instrumentation/mfd/outputs/vor",
           "instrumentation/mfd[1]/outputs/vor"];
var fix = ["instrumentation/mfd/outputs/fix",
           "instrumentation/mfd[1]/outputs/fix"];
var traf = ["instrumentation/tcas/tfc",
            "instrumentation/tcas/tfc[1]"];
var vsd = ["instrumentation/efis/vsd",
           "instrumentation/efis/vsd[1]"];
var cdr = ["cdr0","cdr1","cdr2","cdr3","cdr4"];
var wx_range = [10,20,40,80,160,320];
var wx_index = 1;
var spd_range = 0;
var n=0;
var btn_0 = btn_1 = btn_2 = btn_3 = btn_4 = btn_5 = nil;
var raz_c = nil;

var mfd_stl = setlistener("/sim/signals/fdm-initialized", func {
  setprop("instrumentation/mfd/range-nm",wx_range[wx_index]);
  setprop("instrumentation/mfd[1]/range-nm",wx_range[wx_index]);
  removelistener(mfd_stl);  
},0,0);

var set_range = func(inc,x){
	if (getprop(s_menu[x])<5 or (getprop(s_menu[x])==5 and getprop(path[x],"cdr-tot")==0)){ 
    wx_index += inc;
    if(wx_index>5) {wx_index=5}
    if(wx_index<0) {wx_index=0}
    setprop("instrumentation/mfd["~x~"]/range-nm",wx_range[wx_index]);
	}
	# if (getprop(s_menu[x]) == 5 ) {
	# 	if (getprop(path[x],cdr[0])) {
	# 		spd_range = getprop("controls/flight/v1");
	# 		spd_range += inc;
	# 		if(spd_range<100) {spd_range=100}
	# 		if(spd_range>200) {spd_range=200}
	# 		setprop("controls/flight/v1",spd_range);
	# 		if (getprop("controls/flight/vr") < spd_range) {
	# 			setprop("controls/flight/vr",spd_range);
	# 		}
	# 		if(getprop("controls/flight/v2")< getprop("controls/flight/vr")+3) {
	# 			setprop("controls/flight/v2",getprop("controls/flight/vr")+3);
	# 		}
	# 	}
	# 	if (getprop(path[x],cdr[1])) {		
	# 		spd_range = getprop("controls/flight/vr");
	# 		spd_range += inc;
	# 		if(spd_range<100) {spd_range=100}
	# 		if(spd_range>200) {spd_range=200}
	# 		setprop("controls/flight/vr",spd_range);
	# 		if (getprop("controls/flight/v1") > spd_range) {
	# 			setprop("controls/flight/v1",spd_range);
	# 		}
	# 		if(getprop("controls/flight/v2")< getprop("controls/flight/vr")+4) {
	# 			setprop("controls/flight/v2",getprop("controls/flight/vr")+4);
	# 		}
	# 	}
	# 	if (getprop(path[x],cdr[2])) {		
	# 		spd_range = getprop("controls/flight/v2");
	# 		spd_range += inc;
	# 		if(spd_range<100) {spd_range=100}
	# 		if(spd_range>200) {spd_range=200}
	# 		setprop("controls/flight/v2",spd_range);
	# 		if (getprop("controls/flight/vr") > spd_range-4) {
	# 			setprop("controls/flight/vr",spd_range-4);
	# 		}
	# 		if(getprop("controls/flight/vr")< getprop("controls/flight/v1")) {
	# 			setprop("controls/flight/v1",getprop("controls/flight/vr"));
	# 		}
	# 	}
	# 	if (getprop(path[x],cdr[3])) {		
	# 		spd_range = getprop("controls/flight/vref");
	# 		spd_range += inc;
	# 		if(spd_range<100) {spd_range=100}
	# 		if(spd_range>250) {spd_range=250}
	# 		setprop("controls/flight/vref",spd_range);
	# 		if (getprop("controls/flight/va") < spd_range+4) {
	# 			setprop("controls/flight/va",spd_range+4);
	# 		}
	# 	}
	# 	if (getprop(path[x],cdr[4])) {		
	# 		spd_range = getprop("controls/flight/va");
	# 		spd_range += inc;
	# 		if(spd_range<100) {spd_range=100}
	# 		if(spd_range>250) {spd_range=250}
	# 		setprop("controls/flight/va",spd_range);
	# 		if (getprop("controls/flight/vr") > spd_range-4) {
	# 			setprop("controls/flight/vr",spd_range-4);
	# 		}
	# 	}
	# }
}

var menu = func(x) {
	btn_0 = getprop("instrumentation/mfd["~x~"]/btn0");
	btn_1 = getprop("instrumentation/mfd["~x~"]/btn1");
	btn_2 = getprop("instrumentation/mfd["~x~"]/btn2");
	btn_3 = getprop("instrumentation/mfd["~x~"]/btn3");
	btn_4 = getprop("instrumentation/mfd["~x~"]/btn4");
	btn_5 = getprop("instrumentation/mfd["~x~"]/btn5");
	raz_c = func {foreach (var i;cdr) setprop(path[x],i,0)}

	if (btn_0) {setprop(s_menu[x],0);raz_c()}
  if (btn_1 and getprop(s_menu[x])==0) {
		setprop(s_menu[x],1);
		btn_1 = 0;
		n = 0;
	}
  
	if (btn_2 and getprop(s_menu[x])==0) {
		setprop(s_menu[x],2);
		btn_2 = 0;
		n = 0;
	}
	if (btn_5 and getprop(s_menu[x])==0) {
		setprop(s_menu[x],5);
		btn_5 = 0;
		n = 0;
	}

  if (getprop(s_menu[x])==1) {
		if (getprop(baro)) {setprop(path[x],cdr[0],1)}	
		else {setprop(path[x],cdr[0],0)}
		if (getprop(alt_m)) {setprop(path[x],cdr[1],1)}	
		else {setprop(path[x],cdr[1],0)}

		if (btn_1) {
				if (getprop(baro)) {setprop(baro,0);setprop(path[x],cdr[0],0)}
				else {setprop(baro,1);setprop(path[x],cdr[0],1)}				
		}
		if (btn_2){
				if (getprop(alt_m)) {setprop(alt_m,0);setprop(path[x],cdr[1],0)}
				else {setprop(alt_m,1);setprop(path[x],cdr[1],1)}				
		}
  }

	if (getprop(s_menu[x])==2) {
		if (getprop(vor[x])) setprop(path[x],cdr[0],1);
		else setprop(path[x],cdr[0],0);
		if (getprop(apt[x])) setprop(path[x],cdr[1],1);	
		else setprop(path[x],cdr[1],0);
		if (getprop(fix[x])) setprop(path[x],cdr[2],1);
		else setprop(path[x],cdr[2],0);
		if (getprop(traf[x])) setprop(path[x],cdr[3],1);
		else setprop(path[x],cdr[3],0);

		if (btn_1) {
				if (getprop(vor[x])) {setprop(vor[x],0);setprop(path[x],cdr[0],0)}
				else {setprop(vor[x],1);setprop(path[x],cdr[0],1)}				
		}
		if (btn_2){
				if (getprop(apt[x])) {print("183 apt : ",getprop(apt[x]));setprop(apt[x],0);setprop(path[x],cdr[1],0)}
				else {setprop(apt[x],1);setprop(path[x],cdr[1],1)}				
		}
		if (btn_3){
				if (getprop(fix[x])) {setprop(fix[x],0);setprop(path[x],cdr[2],0)}
				else {setprop(fix[x],1);setprop(path[x],cdr[2],1)}				
		}
		if (btn_4){
			if (getprop(traf[x])) {
				setprop(traf[x],0);
				setprop(path[x],cdr[3],0);
			}
			else {
				setprop(traf[x],1);
				setprop(path[x],cdr[3],1);
			}				
		}
		if (btn_5){
			if (!getprop(vsd[x])) {
				setprop(vsd[x],1);
			} else setprop(vsd[x],0);
		}
	}

	if (getprop(s_menu[x])==5) {
		if (btn_1) {
			if (!getprop(path[x],cdr[0])) {
				raz_c();
				setprop(path[x],cdr[0],1);
			} else setprop(path[x],cdr[0],0);
		}
		if (btn_2){
			if (!getprop(path[x],cdr[1])) {
				raz_c();
				setprop(path[x],cdr[1],1);
			} else {setprop(path[x],cdr[1],0)}
		}
		if (btn_3){
			if (!getprop(path[x],cdr[2])) {
				raz_c();
				setprop(path[x],cdr[2],1);
			} else setprop(path[x],cdr[2],0);
		}
		if (btn_4){
			if (!getprop(path[x],cdr[3])) {
				raz_c();
				setprop(path[x],cdr[3],1);
			} else setprop(path[x],cdr[3],0);
		}
		if (btn_5){
			if (!getprop(path[x],cdr[4])) {
				raz_c();
				setprop(path[x],cdr[4],1);
			} else setprop(path[x],cdr[4],0);
		}
	}		
	n = 0;
	foreach (var i;cdr) {
		if(getprop(path[x],i)) n+=1;
	}								
	if (n == 0) setprop(path[x],"cdr-tot",0);
	else setprop(path[x],"cdr-tot",n);
}

