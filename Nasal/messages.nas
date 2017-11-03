var space1="instrumentation/EICAS/message/space1";
var space2="instrumentation/EICAS/message/space2";
var space3="instrumentation/EICAS/message/space3";
var space4="instrumentation/EICAS/message/space4";
setprop(space1,"");
setprop(space2,"");
setprop(space3,"");
setprop(space4,"");
#PARKING BRAKE
setlistener("/controls/gear/brake-parking", func{
	if(getprop("/controls/gear/brake-parking")==1){
		if(getprop(space1)=="PARKING BRAKE" or getprop(space2)=="PARKING BRAKE" or getprop(space3)=="PARKING BRAKE" or getprop(space4)=="PARKING BRAKE"){
			#do nothing
		}else if(getprop(space1)==""){
			setprop(space1, "PARKING BRAKE");
		}else if(getprop(space2)==""){
			setprop(space2, "PARKING BRAKE");
		}else if(getprop(space3)==""){
			setprop(space3, "PARKING BRAKE");
		}else if(getprop(space4)==""){
			setprop(space4, "PARKING BRAKE");
		}
	}else{
		if(getprop(space1)=="PARKING BRAKE"){
			setprop(space1, "");
		}else if(getprop(space2)=="PARKING BRAKE"){
			setprop(space2, "");
		}else if(getprop(space3)=="PARKING BRAKE"){
			setprop(space3, "");
		}else if(getprop(space4)=="PARKING BRAKE"){
			setprop(space4, "");
		}else{
			print("Doing nothing");
		}
	}
});
#ENG 1 FAIL (Shutdown)
setlistener("/engines/engine/running", func{
	if(getprop("/engines/engine/running")==0){		
		if(getprop(space1)=="ENG 1 FAIL" or getprop(space2)=="ENG 1 FAIL" or getprop(space3)=="ENG 1 FAIL" or getprop(space4)=="ENG 1 FAIL"){
			#do nothing
		}else if(getprop(space1)==""){
			setprop(space1, "ENG 1 FAIL");
		}else if(getprop(space2)==""){
			setprop(space2, "ENG 1 FAIL");
		}else if(getprop(space3)==""){
			setprop(space3, "ENG 1 FAIL");
		}else if(getprop(space4)==""){
			setprop(space4, "ENG 1 FAIL");
		}
	}else{
		if(getprop(space1)=="ENG 1 FAIL"){
			setprop(space1, "");
		}else if(getprop(space2)=="ENG 1 FAIL"){
			setprop(space2, "");
		}else if(getprop(space3)=="ENG 1 FAIL"){
			setprop(space3, "");
		}else if(getprop(space4)=="ENG 1 FAIL"){
			setprop(space4, "");
		}
	}
});
#ENG 2 FAIL (Shutdown)
setlistener("/engines/engine[1]/running", func{
	if(getprop("/engines/engine/running")==0){		
		if(getprop(space1)=="ENG 2 FAIL" or getprop(space2)=="ENG 2 FAIL" or getprop(space3)=="ENG 2 FAIL" or getprop(space4)=="ENG 2 FAIL"){
			#do nothing
		}else if(getprop(space1)==""){
			setprop(space1, "ENG 2 FAIL");
		}else if(getprop(space2)==""){
			setprop(space2, "ENG 2 FAIL");
		}else if(getprop(space3)==""){
			setprop(space3, "ENG 2 FAIL");
		}else if(getprop(space4)==""){
			setprop(space4, "ENG 2 FAIL");
		}
	}else{
		if(getprop(space1)=="ENG 2 FAIL"){
			setprop(space1, "");
		}else if(getprop(space2)=="ENG 2 FAIL"){
			setprop(space2, "");
		}else if(getprop(space3)=="ENG 2 FAIL"){
			setprop(space3, "");
		}else if(getprop(space4)=="ENG 2 FAIL"){
			setprop(space4, "");
		}
	}
});


setlistener("/sim/signals/fdm-initialized", func{
	print("EICAS Message system loaded.");
	settimer(update_message, 0.5);
	if(getprop("/controls/gear/brake-parking")){
		setprop("/controls/gear/brake-parking", 1);
	}
});

var update_message = func{
	
	#Check whether earlier spaces are free
	if(getprop(space4)!=""){
		if(getprop(space3)==""){
			setprop(space3, getprop(space4));
			setprop(space4,"");
		}
	}
	if(getprop(space3)!=""){
		if(getprop(space2)==""){
			setprop(space2, getprop(space3));
			setprop(space3,"");
		}
	}
	if(getprop(space2)!=""){
		if(getprop(space1)==""){
			setprop(space1, getprop(space2));
			setprop(space2,"");
		}
	}
	
	
	settimer(update_message, 0.5);
}