# E-jet-family EICAS by D-ECHO based on
# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

#sources: http://www.smartcockpit.com/docs/Embraer_190-Powerplant.pdf http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf http://www.smartcockpit.com/docs/Embraer_190-APU.pdf

var ED_only = nil;
var ED_display = nil;
var page = "only";

setprop("/engines/engine[0]/itt_degc", 0);
setprop("/engines/engine[1]/itt_degc", 0);
setprop("/engines/engine[0]/oil-pressure-psi", 0);
setprop("/MFD/oil-pressure-needle[0]", 0);
setprop("/engines/engine[1]/oil-pressure-psi", 0);
setprop("/MFD/oil-pressure-needle[1]", 0);
setprop("/engines/engine[0]/oil-temperature-degc", 0);
setprop("/MFD/oil-temperature-needle[0]", 0);
setprop("/engines/engine[1]/oil-temperature-degc", 0);
setprop("/MFD/oil-temperature-needle[1]", 0);
setprop("/engines/engine[0]/fuel-flow_pph", 0);
setprop("/engines/engine[1]/fuel-flow_pph", 0);
setprop("/engines/engine[0]/reverser-pos-norm", 0);
setprop("/engines/engine[1]/reverser-pos-norm", 0);
setprop("/consumables/fuel/tank[0]/temperature-degc", 0);
setprop("/consumables/fuel/tank[1]/temperature-degc", 0);
setprop("/controls/engines/engine[0]/condition-lever-state", 0);
setprop("/controls/engines/engine[1]/condition-lever-state", 0);
setprop("/controls/engines/engine[0]/throttle-int", 0);
setprop("/controls/engines/engine[1]/throttle-int", 0);

var engLn1	=	props.globals.getNode("engines/engine[0]/n1",1);
var engRn1	=	props.globals.getNode("engines/engine[1]/n1",1);
var engLn2	=	props.globals.getNode("engines/engine[0]/n2",1);
var engRn2	=	props.globals.getNode("engines/engine[1]/n2",1);

var engLoff	=	props.globals.getNode("controls/engines/engine[0]/cutoff-switch", 1);
var engRoff	=	props.globals.getNode("controls/engines/engine[1]/cutoff-switch", 1);

setprop("/systems/elecrical/outputs/efis", 0);

var canvas_ED_base = {
	init: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			return "LiberationFonts/LiberationSans-Regular.ttf";
		};


		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		 var svg_keys = me.getKeys();
		 
		foreach(var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var svg_keys = me.getKeys();
			foreach (var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var clip_el = canvas_group.getElementById(key ~ "_clip");
			if (clip_el != nil) {
				clip_el.setVisible(0);
				var tran_rect = clip_el.getTransformedBounds();
				var clip_rect = sprintf("rect(%d,%d, %d,%d)", 
				tran_rect[1], # 0 ys
				tran_rect[2], # 1 xe
				tran_rect[3], # 2 ye
				tran_rect[0]); #3 xs
				#   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
				me[key].set("clip", clip_rect);
				me[key].set("clip-frame", canvas.Element.PARENT);
			}
			}
		}

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		#if (getprop("systems/electrical/outputs/efis") >= 15) {
		#		ED_only.page.show();
		#} else {
		#	ED_only.page.hide();
		#}
		
		settimer(func me.update(), 0.02);
	},
};

var trsModeLabels = {
	0: "TO",
	1: "GA",
	2: "CLB",
	4: "CRZ",
	5: "CON",
};

var canvas_ED_only = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_ED_only,canvas_ED_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return [
            "flaps.UP",
            "flaps.IND",
            "flaps.SCALE",
            "flaps.TGT",
            "slat.IND",
            "slat.TGT",
            "slat.SCALE",
            "fs",
            "N1L",
            "N1R",
            "N2L",
            "N2R",
            "ITTL",
            "ITTR",
            "FFL",
            "FFR",
            "FQL",
            "FQR",
            "FQC",
            "OPL",
            "OPR",
            "OTL",
            "OTR",
            "revL",
            "revR",
            "gearL.T",
            "gearL.C",
            "gearR.T",
            "gearR.C",
            "gearF.C",
            "gearF.T",
            "AB",
            "apu.PCT",
            "apu.DEGC",
            "N1L.needle",
            "N1R.needle",
            "parkbrake",
            "space1",
            "space2",
            "space3",
            "space4",
            "lfilled1",
            "lfilled2",
            "engL.off",
            "engR.off",
            "pitchtrim.digital",
            "pitchtrim.pointer",
            "ailerontrim.pointer",
            "ruddertrim.pointer",
            "limitL.digital",
            "limitR.digital",
            "trsMode"
        ];
	},
	update: func() {
			
		var flap_pos=getprop("/fdm/jsbsim/fcs/flap-pos-deg") or 0;
		var flap_cmd=getprop("/fdm/jsbsim/fcs/flap-cmd-int-deg") or 0;
		
		if(flap_pos==0){
			me["flaps.IND"].hide();
			me["flaps.SCALE"].hide();
			me["flaps.TGT"].hide();
			me["flaps.UP"].show();
		}else{
			me["flaps.IND"].show();
			me["flaps.SCALE"].show();
			me["flaps.TGT"].show();
			me["flaps.UP"].hide();
			me["flaps.TGT"].setRotation(flap_cmd * D2R);
			me["flaps.IND"].setRotation(flap_pos * D2R);
		}
		
		var slat_pos=getprop("/fdm/jsbsim/fcs/slat-pos-deg") or 0;
		var slat_cmd=getprop("/fdm/jsbsim/fcs/slat-cmd-int-deg") or 0;
		if(slat_pos==0){
			me["slat.IND"].hide();
			me["slat.SCALE"].hide();
			me["slat.TGT"].hide();
		}else{
			me["slat.IND"].show();
			me["slat.SCALE"].show();
			me["slat.TGT"].show();
			me["slat.TGT"].setRotation(slat_cmd*(-D2R));
			me["slat.IND"].setRotation(slat_pos*(-D2R));
		}
		
        var flap_cmd_raw = math.round((getprop("/controls/flight/flaps") or 0) / 0.125);
		me["fs"].setText(sprintf("%u", flap_cmd_raw));

        me["pitchtrim.digital"].setText(sprintf("%3.1f", (getprop("/controls/flight/elevator-trim") or 0.0) * -10));
        me["pitchtrim.pointer"].setTranslation(0, math.round((getprop("/controls/flight/elevator-trim") or 0) * 60));
        me["ruddertrim.pointer"].setTranslation(math.round((getprop("/controls/flight/rudder-trim") or 0) * 60), 0);
        me["ailerontrim.pointer"].setRotation(math.round((getprop("/controls/flight/aileron-trim") or 0) * 30));
		
		var ln1=engLn1.getValue();
		var rn1=engRn1.getValue();
		var ln2=engLn2.getValue();
		var rn2=engRn2.getValue();
		var litt=getprop("/engines/engine[0]/itt_degc");
		var ritt=getprop("/engines/engine[1]/itt_degc");
		var lff=getprop("/engines/engine[0]/fuel-flow_pph");
		var rff=getprop("/engines/engine[1]/fuel-flow_pph");
		var fq=getprop("/consumables/fuel/total-fuel-lbs");
		var lfq=getprop("/consumables/fuel/tank[0]/level-lbs");
		var rfq=getprop("/consumables/fuel/tank[2]/level-lbs");
		var lop=getprop("/engines/engine[0]/oil-pressure-psi");
		var rop=getprop("/engines/engine[1]/oil-pressure-psi");
		var lot=getprop("/engines/engine[0]/oil-temperature-degc");
		var rot=getprop("/engines/engine[1]/oil-temperature-degc");

        # TRS
        var mode = getprop("/trs/mode") or 0;
        var modeLabel = trsModeLabels[mode] or "---";
        if (modeLabel == "TO" or modeLabel == "GA") {
            if (modeLabel == "TO") {
                if (getprop("/controls/flight/trs/flex-to")) {
                    modeLabel = "FLEX-TO";
                }
            }
            var submode = getprop("/trs/thrust/to-submode") or 1;
            modeLabel = modeLabel ~ "-" ~ submode;
        }
        else if (modeLabel == "CLB") {
            var submode = getprop("/trs/thrust/climb-submode") or 1;
            modeLabel = modeLabel ~ "-" ~ submode;
        }
        me["trsMode"].setText(modeLabel);
        var limit = (getprop("/it-autoflight/settings/autothrottle-max") or 1.0) * 100.0;
        me["limitL.digital"].setText(sprintf("%3.1f", limit));
        me["limitR.digital"].setText(sprintf("%3.1f", limit));
		
		#Engine off
		if(engLoff.getBoolValue()){
			me["engL.off"].show();
		}else{
			me["engL.off"].hide();
		}
		
		me["engR.off"].setVisible(engRoff.getBoolValue());

		
		#0.526
		if(ln1<52.6){
			me["lfilled2"].hide();
			if(ln1==0){
				me["lfilled1"].hide();
			}else{
				#me["lfilled1"].show();
				me["lfilled1"].setRotation(ln1*D2R*2.568);
			}
		}else{
			#me["lfilled2"].show();
			me["lfilled1"].setRotation(0.526*D2R*2.568);
			me["lfilled2"].setRotation((ln1-0.526)*D2R*2.568);
		}
			
		me["N1L.needle"].setRotation(ln1*D2R*2.568);
		me["N1R.needle"].setRotation(rn1*D2R*2.568);
		me["N1L"].setText(sprintf("%.1f", ln1));
		me["N1R"].setText(sprintf("%.1f", rn1));
		me["N2L"].setText(sprintf("%.1f", ln2));
		me["N2R"].setText(sprintf("%.1f", rn2));
		me["ITTL"].setText(sprintf("%u", litt));
		me["ITTR"].setText(sprintf("%u", ritt));
		me["FFL"].setText(sprintf("%u", lff));
		me["FFR"].setText(sprintf("%u", rff));
		me["FQL"].setText(sprintf("%u", lfq));
		me["FQR"].setText(sprintf("%u", rfq));
		me["FQC"].setText(sprintf("%u", fq));
		me["OPL"].setText(sprintf("%u", lop));
		me["OPR"].setText(sprintf("%u", rop));
		me["OTL"].setText(sprintf("%u", lot));
		me["OTR"].setText(sprintf("%u", rot));
		
		var lrvs=getprop("/engines/engine[0]/reverser-pos-norm");
		var rrvs=getprop("/engines/engine[0]/reverser-pos-norm");
		if(lrvs==0){
			me["revL"].hide();
		}else if(lrvs>0 and lrvs<1){
			me["revL"].show();
			me["revL"].setColor(1,1,0);
		}else{
			me["revL"].show();
			me["revL"].setColor(0,1,0);
		}
		if(rrvs==0){
			me["revR"].hide();
		}else if(rrvs>0 and rrvs<1){
			me["revR"].show();
			me["revR"].setColor(1,1,0);
		}else{
			me["revR"].show();
			me["revR"].setColor(0,1,0);
		}
		
		var fg=getprop("/gear/gear[0]/position-norm");
		var lg=getprop("/gear/gear[1]/position-norm");
		var rg=getprop("/gear/gear[2]/position-norm");
		
		if(fg>0){
			me["gearF.C"].show();
			me["gearF.T"].show();
			if(fg==1){
				me["gearF.C"].setColor(0,1,0);
				me["gearF.T"].setColor(0,1,0);
				me["gearF.T"].setText("DN");
			}else{
				me["gearF.C"].setColor(1,1,0);
				me["gearF.T"].setColor(1,1,0);
				me["gearF.T"].setText("TR");
			}
		}else{
			me["gearF.C"].hide();
			me["gearF.T"].hide();
		}if(lg>0){
			me["gearL.C"].show();
			me["gearL.T"].show();
			if(lg==1){
				me["gearL.C"].setColor(0,1,0);
				me["gearL.T"].setColor(0,1,0);
				me["gearL.T"].setText("DN");
			}else{
				me["gearL.C"].setColor(1,1,0);
				me["gearL.T"].setColor(1,1,0);
				me["gearL.T"].setText("TR");
			}
		}else{
			me["gearL.C"].hide();
			me["gearL.T"].hide();
		}if(rg>0){
			me["gearR.C"].show();
			me["gearR.T"].show();
			if(rg==1){
				me["gearR.C"].setColor(0,1,0);
				me["gearR.T"].setColor(0,1,0);
				me["gearR.T"].setText("DN");
			}else{
				me["gearR.C"].setColor(1,1,0);
				me["gearR.T"].setColor(1,1,0);
				me["gearR.T"].setText("TR");
			}
		}else{
			me["gearR.C"].hide();
			me["gearR.T"].hide();
		}
		
		var autobrake=getprop("/autopilot/autobrake/step");
		if(autobrake==0){
			me["AB"].setText("OFF");
		}else if(autobrake==1){
			me["AB"].setText("LO");
		}else if(autobrake==2){
			me["AB"].setText("MED");
		}else if(autobrake==3){
			me["AB"].setText("HI");
		}else if(autobrake==-1){
			me["AB"].setText("RTO");
		}
		
		var apurpm=getprop("/engines/apu/rpm");
		#var aputmp=getprop("/engines/apu/temp") or 0;
		me["apu.PCT"].setText(sprintf("%u", apurpm));
		#me["apu.DEGC"].setText(sprintf("%u", aputmp));
		
		#EICAS Messaging system
		me["space1"].setText(getprop("/instrumentation/EICAS/message/space1"));
		me["space2"].setText(getprop("/instrumentation/EICAS/message/space2"));
		me["space3"].setText(getprop("/instrumentation/EICAS/message/space3"));
		me["space4"].setText(getprop("/instrumentation/EICAS/message/space4"));
		
		
		settimer(func me.update(), 0.02);
	},
};

setlistener("sim/signals/fdm-initialized", func {
	ED_display = canvas.new({
		"name": "EICAS",
		"size": [2048, 2808],
		"view": [1024, 1404],
		"mipmapping": 1
	});
	ED_display.addPlacement({"node": "EICAS.face"});
	var groupED = ED_display.createGroup();

	ED_only = canvas_ED_only.new(groupED, "Aircraft/E-jet-family/Models/Primus-Epic/eicas.svg");

	ED_only.update();
	canvas_ED_base.update();
});

var showED = func {
	var dlg = canvas.Window.new([512, 768], "dialog").set("resize", 1);
	dlg.setCanvas(ED_display);
}
