# IT-AUTOFLIGHT System Controller V4.0.8 Beta
# Copyright (c) 2022 Josh Davidson (Octal450)

setprop("/it-autoflight/config/tuning-mode", 0); # Not used by controller

# Initialize all used variables and property nodes
# Sim
var Controls = {
	aileron: props.globals.getNode("/controls/flight/aileron", 1),
	elevator: props.globals.getNode("/controls/flight/elevator", 1),
	rudder: props.globals.getNode("/controls/flight/rudder", 1),
};

var FPLN = {
	active: props.globals.getNode("/autopilot/route-manager/active", 1),
	activeTemp: 0,
	currentCourse: 0,
	currentWp: props.globals.getNode("/autopilot/route-manager/current-wp", 1),
	currentWpTemp: 0,
	deltaAngle: 0,
	deltaAngleRad: 0,
	distCoeff: 0,
	maxBank: 0,
	maxBankLimit: 0,
	nextCourse: 0,
	num: props.globals.getNode("/autopilot/route-manager/route/num", 1),
	numTemp: 0,
	R: 0,
	radius: 0,
	turnDist: 0,
	wp0Dist: props.globals.getNode("/autopilot/route-manager/wp/dist", 1),
	wpFlyFrom: 0,
	wpFlyTo: 0,
};

var Gear = {
	wow0: props.globals.getNode("/gear/gear[0]/wow", 1),
	wow1: props.globals.getNode("/gear/gear[1]/wow", 1),
	wow1Temp: 1,
	wow2: props.globals.getNode("/gear/gear[2]/wow", 1),
	wow2Temp: 1,
};

var Misc = {
	efis0Trk: props.globals.getNode("/instrumentation/efis[0]/hdg-trk-selected", 1),
	efis1Trk: props.globals.getNode("/instrumentation/efis[1]/hdg-trk-selected", 1),
	flapNorm: props.globals.getNode("/surface-positions/flap-pos-norm", 1),
};

var Orientation = {
	rollDeg: props.globals.getNode("/orientation/roll-deg"),
};

var Position = {
	gearAglFtTemp: 0,
	gearAglFt: props.globals.getNode("/position/gear-agl-ft", 1),
	indicatedAltitudeFt: props.globals.getNode("/instrumentation/altimeter/indicated-altitude-ft", 1),
	indicatedAltitudeFtTemp: 0,
};

var Radio = {
	gsDefl: [props.globals.getNode("/instrumentation/nav[0]/gs-needle-deflection-norm", 1), props.globals.getNode("/instrumentation/nav[1]/gs-needle-deflection-norm", 1), props.globals.getNode("/instrumentation/nav[2]/gs-needle-deflection-norm", 1)],
	gsDeflTemp: [0, 0, 0],
	inRange: [props.globals.getNode("/instrumentation/nav[0]/in-range", 1), props.globals.getNode("/instrumentation/nav[1]/in-range", 1), props.globals.getNode("/instrumentation/nav[2]/in-range", 1)],
	locDefl: [props.globals.getNode("/instrumentation/nav[0]/heading-needle-deflection-norm", 1), props.globals.getNode("/instrumentation/nav[1]/heading-needle-deflection-norm", 1), props.globals.getNode("/instrumentation/nav[2]/heading-needle-deflection-norm", 1)],
	locDeflTemp: [0, 0, 0],
	signalQuality: [props.globals.getNode("/instrumentation/nav[0]/signal-quality-norm", 1), props.globals.getNode("/instrumentation/nav[1]/signal-quality-norm", 1), props.globals.getNode("/instrumentation/nav[2]/signal-quality-norm", 1)],
	signalQualityTemp: [0, 0, 0],
};

var Velocities = {
	airspeedKt: props.globals.getNode("/velocities/airspeed-kt", 1), # Only used for gain scheduling
	groundspeedKt: props.globals.getNode("/velocities/groundspeed-kt", 1),
	groundspeedMps: 0,
	indicatedAirspeedKt: props.globals.getNode("/instrumentation/airspeed-indicator/indicated-speed-kt", 1),
	indicatedMach: props.globals.getNode("/instrumentation/airspeed-indicator/indicated-mach", 1),
	trueAirspeedKt: props.globals.getNode("/instrumentation/airspeed-indicator/true-speed-kt", 1),
	trueAirspeedKtTemp: 0,
};

# IT-AUTOFLIGHT
var Fd = {
	pitchBar: props.globals.initNode("/it-autoflight/fd/pitch-bar", 0, "DOUBLE"),
	rollBar: props.globals.initNode("/it-autoflight/fd/roll-bar", 0, "DOUBLE"),
};

var Input = {
	alt: props.globals.initNode("/it-autoflight/input/alt", 10000, "INT"),
	ap1: props.globals.initNode("/it-autoflight/input/ap1", 0, "BOOL"),
	ap1Avail: props.globals.initNode("/it-autoflight/input/ap1-avail", 1, "BOOL"),
	ap2: props.globals.initNode("/it-autoflight/input/ap2", 0, "BOOL"),
	ap2Avail: props.globals.initNode("/it-autoflight/input/ap2-avail", 1, "BOOL"),
	athr: props.globals.initNode("/it-autoflight/input/athr", 0, "BOOL"),
	athrAvail: props.globals.initNode("/it-autoflight/input/athr-avail", 1, "BOOL"),
	altDiff: 0,
	bankLimitSw: props.globals.initNode("/it-autoflight/input/bank-limit-sw", 0, "INT"),
	bankLimitSwTemp: 0,
	fd1: props.globals.initNode("/it-autoflight/input/fd1", 0, "BOOL"),
	fd2: props.globals.initNode("/it-autoflight/input/fd2", 0, "BOOL"),
	fpa: props.globals.initNode("/it-autoflight/input/fpa", 0, "DOUBLE"),
	fpaAbs: props.globals.initNode("/it-autoflight/input/fpa-abs", 0, "DOUBLE"), # Set by property rule
	hdg: props.globals.initNode("/it-autoflight/input/hdg", 0, "INT"),
	hdgCalc: 0,
	hdgHldCalc: 0,
	kts: props.globals.initNode("/it-autoflight/input/kts", 250, "INT"),
	ktsMach: props.globals.initNode("/it-autoflight/input/kts-mach", 0, "BOOL"),
	lat: props.globals.initNode("/it-autoflight/input/lat", 5, "INT"),
	latTemp: 5,
	mach: props.globals.initNode("/it-autoflight/input/mach", 0.5, "DOUBLE"),
	radioSel: props.globals.initNode("/it-autoflight/input/radio-sel", 0, "INT"),
	radioSelTemp: 0,
	roll: props.globals.initNode("/it-autoflight/input/roll", 0, "INT"),
	toga: props.globals.initNode("/it-autoflight/input/toga", 0, "BOOL"),
	trk: props.globals.initNode("/it-autoflight/input/trk", 0, "BOOL"),
	trueCourse: props.globals.initNode("/it-autoflight/input/true-course", 0, "BOOL"),
	vert: props.globals.initNode("/it-autoflight/input/vert", 7, "INT"),
	vertTemp: 7,
	vs: props.globals.initNode("/it-autoflight/input/vs", 0, "INT"),
	vsAbs: props.globals.initNode("/it-autoflight/input/vs-abs", 0, "INT"), # Set by property rule
	vsFpa: props.globals.initNode("/it-autoflight/input/vs-fpa", 0, "BOOL"),
};

var Internal = {
	alt: props.globals.initNode("/it-autoflight/internal/alt", 10000, "INT"),
	altCaptureActive: 0,
	altDiff: 0,
	altTemp: 0,
	altPredicted: props.globals.initNode("/it-autoflight/internal/altitude-predicted", 0, "DOUBLE"),
	bankLimit: props.globals.initNode("/it-autoflight/internal/bank-limit", 30, "INT"),
	bankLimitAuto: 30,
	bankLimitMax: [30, 5, 10, 15, 20, 25, 30],
	bankLimitTemp: 30,
	captVs: 0,
	driftAngle: props.globals.initNode("/it-autoflight/internal/drift-angle-deg", 0, "DOUBLE"),
	driftAngleTemp: 0,
	flchActive: 0,
	fpa: props.globals.initNode("/it-autoflight/internal/fpa", 0, "DOUBLE"),
	hdgErrorDeg: props.globals.initNode("/it-autoflight/internal/heading-error-deg", 0, "DOUBLE"),
	hdgHldTarget: props.globals.initNode("/it-autoflight/internal/hdg-hld-target", 360, "INT"),
	hdgHldValue: 360,
	hdgPredicted: props.globals.initNode("/it-autoflight/internal/heading-predicted", 0, "DOUBLE"),
	lnavAdvanceNm: props.globals.initNode("/it-autoflight/internal/lnav-advance-nm", 0, "DOUBLE"),
	minVs: props.globals.initNode("/it-autoflight/internal/min-vs", -500, "INT"),
	maxVs: props.globals.initNode("/it-autoflight/internal/max-vs", 500, "INT"),
	navCourseTrackErrorDeg: [props.globals.initNode("/it-autoflight/internal/nav1-course-track-error-deg", 0, "DOUBLE"), props.globals.initNode("/it-autoflight/internal/nav2-course-track-error-deg", 0, "DOUBLE"), props.globals.initNode("/it-autoflight/internal/nav3-course-track-error-deg", 0, "DOUBLE")],
	navHeadingErrorDeg: [props.globals.initNode("/it-autoflight/internal/nav1-heading-error-deg", 0, "DOUBLE"), props.globals.initNode("/it-autoflight/internal/nav2-heading-error-deg", 0, "DOUBLE"), props.globals.initNode("/it-autoflight/internal/nav3-heading-error-deg", 0, "DOUBLE")],
	navHeadingErrorDegTemp: [0, 0, 0],
	vs: props.globals.initNode("/it-autoflight/internal/vert-speed-fpm", 0, "DOUBLE"),
	vsTemp: 0,
};

var Output = {
	ap1: props.globals.initNode("/it-autoflight/output/ap1", 0, "BOOL"),
	ap1Temp: 0,
	ap2: props.globals.initNode("/it-autoflight/output/ap2", 0, "BOOL"),
	ap2Temp: 0,
	apprArm: props.globals.initNode("/it-autoflight/output/appr-armed", 0, "BOOL"),
	athr: props.globals.initNode("/it-autoflight/output/athr", 0, "BOOL"),
	athrTemp: 0,
	fd1: props.globals.initNode("/it-autoflight/output/fd1", 0, "BOOL"),
	fd1Temp: 0,
	fd2: props.globals.initNode("/it-autoflight/output/fd2", 0, "BOOL"),
	fd2Temp: 0,
	hdgInHld: props.globals.initNode("/it-autoflight/output/hdg-in-hld", 0, "BOOL"),
	hdgInHldTemp: 0,
	lat: props.globals.initNode("/it-autoflight/output/lat", 5, "INT"),
	latTemp: 5,
	lnavArm: props.globals.initNode("/it-autoflight/output/lnav-armed", 0, "BOOL"),
	locArm: props.globals.initNode("/it-autoflight/output/loc-armed", 0, "BOOL"),
	thrMode: props.globals.initNode("/it-autoflight/output/thr-mode", 2, "INT"),
	vert: props.globals.initNode("/it-autoflight/output/vert", 7, "INT"),
	vertTemp: 7,
};

var Text = {
	lat: props.globals.initNode("/it-autoflight/mode/lat", "T/O", "STRING"),
	thr: props.globals.initNode("/it-autoflight/mode/thr", "PITCH", "STRING"),
	vert: props.globals.initNode("/it-autoflight/mode/vert", "T/O CLB", "STRING"),
	vertTemp: "T/O CLB",
};

var Settings = {
	accelFt: props.globals.getNode("/it-autoflight/settings/accel-ft", 1),
	autoBankMaxDeg: props.globals.getNode("/it-autoflight/settings/auto-bank-max-deg", 1),
	autolandWithoutAp: props.globals.getNode("/it-autoflight/settings/autoland-without-ap", 1),
	autolandWithoutApTemp: 0,
	customFma: props.globals.getNode("/it-autoflight/settings/custom-fma", 1),
	disableFinal: props.globals.getNode("/it-autoflight/settings/disable-final", 1),
	fdStartsOn: props.globals.getNode("/it-autoflight/settings/fd-starts-on", 1),
	hdgHldSeparate: props.globals.getNode("/it-autoflight/settings/hdg-hld-separate", 1),
	latAglFt: props.globals.getNode("/it-autoflight/settings/lat-agl-ft", 1),
	landingFlap: props.globals.getNode("/it-autoflight/settings/land-flap", 1),
	retardAltitude: props.globals.getNode("/it-autoflight/settings/retard-ft", 1),
	retardEnable: props.globals.getNode("/it-autoflight/settings/retard-enable", 1),
	togaSpd: props.globals.getNode("/it-autoflight/settings/toga-spd", 1),
};

var Sound = {
	apOff: props.globals.initNode("/it-autoflight/sound/apoff", 0, "BOOL"),
	enableApOff: 0,
};

var Gain = {
	altGain: props.globals.getNode("/it-autoflight/config/cmd/alt-gain", 1),
	hdgGain: props.globals.getNode("/it-autoflight/config/cmd/roll", 1),
	pitchKp: props.globals.initNode("/it-autoflight/config/pitch/kp", 0, "DOUBLE"),
	pitchKpCalc: 0,
	pitchKpLow: props.globals.getNode("/it-autoflight/config/pitch/kp-low", 1),
	pitchKpLowTemp: 0,
	pitchKpHigh: props.globals.getNode("/it-autoflight/config/pitch/kp-high", 1),
	pitchKpHighTemp: 0,
	rollCmdKp: props.globals.initNode("/it-autoflight/config/cmd/roll-kp", 0, "DOUBLE"),
	rollCmdKpCalc: 0,
	rollKp: props.globals.initNode("/it-autoflight/config/roll/kp", 0, "DOUBLE"),
	rollKpCalc: 0,
	rollKpLowTemp: 0,
	rollKpLow: props.globals.getNode("/it-autoflight/config/roll/kp-low", 1),
	rollKpHighTemp: 0,
	rollKpHigh: props.globals.getNode("/it-autoflight/config/roll/kp-high", 1),
};

var ITAF = {
	init: func(t = 0) { # Not everything should be reset if the reset is type 1
		if (t != 1) {
			Input.alt.setValue(10000);
			Input.bankLimitSw.setValue(0);
			Input.hdg.setValue(360);
			Input.ktsMach.setBoolValue(0);
			Input.kts.setValue(250);
			Input.mach.setValue(0.5);
			Input.trk.setBoolValue(0);
			Input.trueCourse.setBoolValue(0);
			Input.radioSel.setBoolValue(0);
			Input.vsFpa.setBoolValue(0);
		}
		Input.ap1.setBoolValue(0);
		Input.ap2.setBoolValue(0);
		Input.athr.setBoolValue(0);
		if (t != 1) {
			Input.fd1.setBoolValue(Settings.fdStartsOn.getBoolValue());
			Input.fd2.setBoolValue(Settings.fdStartsOn.getBoolValue());
		}
		Input.vs.setValue(0);
		Input.fpa.setValue(0);
		Input.lat.setValue(5);
		Input.vert.setValue(7);
		Input.toga.setBoolValue(0);
		Output.ap1.setBoolValue(0);
		Output.ap2.setBoolValue(0);
		Output.athr.setBoolValue(0);
		if (t != 1) {
			Output.fd1.setBoolValue(Settings.fdStartsOn.getBoolValue());
			Output.fd2.setBoolValue(Settings.fdStartsOn.getBoolValue());
		}
		Output.hdgInHld.setBoolValue(0);
		me.updateLnavArm(0);
		me.updateLocArm(0);
		Output.apprArm.setBoolValue(0);
		Output.thrMode.setValue(2);
		Output.lat.setValue(5);
		Output.vert.setValue(7);
		Internal.minVs.setValue(-500);
		Internal.maxVs.setValue(500);
		Internal.alt.setValue(10000);
		Internal.altCaptureActive = 0;
		Text.thr.setValue("PITCH");
		if (Settings.customFma.getBoolValue()) {
			updateFma.arm();
		}
		me.updateLatText("T/O");
		me.updateVertText("T/O CLB");
		loopTimer.start();
		slowLoopTimer.start();
	},
	loop: func() {
		Output.ap1Temp = Output.ap1.getBoolValue();
		Output.ap2Temp = Output.ap2.getBoolValue();
		Output.latTemp = Output.lat.getValue();
		Output.vertTemp = Output.vert.getValue();
		
		# Trip system off
		if (!Input.ap1Avail.getBoolValue() and Output.ap1Temp) {
			me.ap1Master(0);
		}
		if (!Input.ap2Avail.getBoolValue() and Output.ap2Temp) {
			me.ap2Master(0);
		}
		if (!Input.athrAvail.getBoolValue() and Output.athr.getBoolValue()) {
			me.athrMaster(0);
		}
		
		# VOR/ILS Revision
		if (Output.latTemp == 2 or Output.latTemp == 4 or Output.vertTemp == 2 or Output.vertTemp == 6) {
			me.checkRadioRevision(Output.latTemp, Output.vertTemp);
		}
		
		Output.ap1Temp = Output.ap1.getBoolValue();
		Output.ap2Temp = Output.ap2.getBoolValue();
		Output.athrTemp = Output.athr.getBoolValue();
		Settings.autolandWithoutApTemp = Settings.autolandWithoutAp.getBoolValue();
		
		# Kill Autoland if the system should not autoland without AP, and AP is off
		if (Settings.autolandWithoutApTemp) { # Only evaluate the rest if this setting is on
			if (!Output.ap1Temp and !Output.ap2Temp) {
				if (Output.latTemp == 4) {
					me.activateLoc();
				}
				if (Output.vertTemp == 6) {
					me.activateGs();
				}
			}
		}
		
		Gear.wow1Temp = Gear.wow1.getBoolValue();
		Gear.wow2Temp = Gear.wow2.getBoolValue();
		Output.latTemp = Output.lat.getValue();
		Output.vertTemp = Output.vert.getValue();
		Text.vertTemp = Text.vert.getValue();
		Position.gearAglFtTemp = Position.gearAglFt.getValue();
		Internal.vsTemp = Internal.vs.getValue();
		Position.indicatedAltitudeFtTemp = Position.indicatedAltitudeFt.getValue();
		
		# HDG HLD logic
		if (!Settings.hdgHldSeparate.getBoolValue()) {
			Output.hdgInHldTemp = Output.hdgInHld.getBoolValue();
			
			if (Output.latTemp == 0) {
				if (Input.hdg.getValue() == Internal.hdgHldValue and abs(Internal.hdgErrorDeg.getValue()) <= 2.5) {
					if (Output.hdgInHldTemp != 1) {
						Output.hdgInHld.setBoolValue(1);
						if (Settings.customFma.getBoolValue()) { # Update it for planes that use both
							updateFma.lat();
						}
					}
				} else if (Input.hdg.getValue() != Internal.hdgHldValue) {
					Internal.hdgHldValue = Input.hdg.getValue();
					if (Output.hdgInHldTemp != 0 and abs(Internal.hdgErrorDeg.getValue()) > 2.5) {
						Output.hdgInHld.setBoolValue(0);
						if (Settings.customFma.getBoolValue()) { # Update it for planes that use both
							updateFma.lat();
						}
					}
				}
			} else {
				if (Output.hdgInHldTemp != 0) {
					Output.hdgInHld.setBoolValue(0);
				}
			}
		}
		
		# LNAV Engagement
		if (Output.lnavArm.getBoolValue()) {
			me.checkLnav(1);
		}
		
		# VOR/LOC or ILS/LOC Capture
		if (Output.locArm.getBoolValue()) {
			me.checkLoc(1);
		}
		
		# G/S Capture
		if (Output.apprArm.getBoolValue()) {
			me.checkAppr(1);
		}
		
		# Autoland Logic
		if (Output.latTemp == 2) {
			if (Position.gearAglFtTemp <= 150) {
				if (Output.ap1Temp or Output.ap2Temp or Settings.autolandWithoutApTemp) {
					me.setLatMode(4);
				}
			}
		}
		if (Output.vertTemp == 2) {
			if (Position.gearAglFtTemp <= 50 and Position.gearAglFtTemp >= 5) {
				if (Output.ap1Temp or Output.ap2Temp or Settings.autolandWithoutApTemp) {
					me.setVertMode(6);
				}
			}
		} else if (Output.vertTemp == 6) {
			if (!Output.ap1Temp and !Output.ap2Temp and !Settings.autolandWithoutApTemp) {
				me.activateLoc();
				me.activateGs();
			} else {
				if (Gear.wow1Temp and Gear.wow2Temp and Text.vert.getValue() != "ROLLOUT") {
					me.updateLatText("RLOU");
					me.updateVertText("ROLLOUT");
				}
			}
		}
		
		# FLCH Engagement
		if (Text.vertTemp == "T/O CLB") {
			me.checkFlch(Settings.accelFt.getValue());
		}
		
		# Altitude Capture/Sync Logic
		if (Output.vertTemp != 0) {
			Internal.alt.setValue(Input.alt.getValue());
		}
		Internal.altTemp = Internal.alt.getValue();
		Internal.altDiff = Internal.altTemp - Position.indicatedAltitudeFtTemp;
		
		if (Output.vertTemp != 0 and Output.vertTemp != 2 and Output.vertTemp != 6 and Output.vertTemp != 9) {
			Internal.captVs = math.clamp(math.round(abs(Internal.vs.getValue()) / (-1 * Gain.altGain.getValue()), 100), 50, 2500); # Capture limits
			if (abs(Internal.altDiff) <= Internal.captVs and !Gear.wow1Temp and !Gear.wow2Temp) {
				if (Internal.altTemp >= Position.indicatedAltitudeFtTemp and Internal.vsTemp >= -25) { # Don't capture if we are going the wrong way
					me.setVertMode(3);
				} else if (Internal.altTemp < Position.indicatedAltitudeFtTemp and Internal.vsTemp <= 25) { # Don't capture if we are going the wrong way
					me.setVertMode(3);
				}
			}
		}
		
		# Altitude Hold Min/Max Reset
		if (Internal.altCaptureActive) {
			if (abs(Internal.altDiff) <= 25 and Text.vert.getValue() != "ALT HLD") {
				me.resetClimbRateLim();
				me.updateVertText("ALT HLD");
			}
		}
		
		# Thrust Mode Selector
		me.updateThrustMode();
	},
	slowLoop: func() {
		Input.bankLimitSwTemp = Input.bankLimitSw.getValue();
		Velocities.trueAirspeedKtTemp = Velocities.trueAirspeedKt.getValue();
		FPLN.activeTemp = FPLN.active.getValue();
		FPLN.currentWpTemp = FPLN.currentWp.getValue();
		FPLN.numTemp = FPLN.num.getValue();
		
		# Bank Limit
		if (Velocities.trueAirspeedKtTemp >= 420) {
			Internal.bankLimitAuto = 15;
		} else if (Velocities.trueAirspeedKtTemp >= 340) {
			Internal.bankLimitAuto = 20;
		} else {
			Internal.bankLimitAuto = 30;
		}
		
		if (Internal.bankLimitAuto > Internal.bankLimitMax[Input.bankLimitSwTemp]) {
			Internal.bankLimit.setValue(Internal.bankLimitMax[Input.bankLimitSwTemp]);
		} else {
			Internal.bankLimit.setValue(Internal.bankLimitAuto);
		}
		
		# If in LNAV mode and route is not longer active, switch to HDG HLD
		if (Output.lat.getValue() == 1) { # Only evaulate the rest of the condition if we are in LNAV mode
			if (FPLN.num.getValue() == 0 or !FPLN.active.getBoolValue()) {
				me.setLatMode(3);
			}
		}
		
		# Waypoint Advance Logic
		if (FPLN.numTemp > 0 and FPLN.activeTemp == 1) {
			if ((FPLN.currentWpTemp + 1) < FPLN.numTemp) {
				Velocities.groundspeedMps = Velocities.groundspeedKt.getValue() * 0.5144444444444;
				FPLN.wpFlyFrom = FPLN.currentWpTemp;
				if (FPLN.wpFlyFrom < 0) {
					FPLN.wpFlyFrom = 0;
				}
				FPLN.currentCourse = getprop("/autopilot/route-manager/route/wp[" ~ FPLN.wpFlyFrom ~ "]/leg-bearing-true-deg"); # Best left at getprop
				FPLN.wpFlyTo = FPLN.currentWpTemp + 1;
				if (FPLN.wpFlyTo < 0) {
					FPLN.wpFlyTo = 0;
				}
				FPLN.nextCourse = getprop("/autopilot/route-manager/route/wp[" ~ FPLN.wpFlyTo ~ "]/leg-bearing-true-deg"); # Best left at getprop
				FPLN.maxBankLimit = Internal.bankLimit.getValue();

				FPLN.deltaAngle = math.abs(geo.normdeg180(FPLN.currentCourse - FPLN.nextCourse));
				FPLN.maxBank = FPLN.deltaAngle * 1.5;
				if (FPLN.maxBank > FPLN.maxBankLimit) {
					FPLN.maxBank = FPLN.maxBankLimit;
				}
				FPLN.radius = (Velocities.groundspeedMps * Velocities.groundspeedMps) / (9.81 * math.tan(FPLN.maxBank / 57.2957795131));
				FPLN.deltaAngleRad = (180 - FPLN.deltaAngle) / 114.5915590262;
				FPLN.R = FPLN.radius / math.sin(FPLN.deltaAngleRad);
				FPLN.distCoeff = FPLN.deltaAngle * -0.011111 + 2;
				if (FPLN.distCoeff < 1) {
					FPLN.distCoeff = 1;
				}
				FPLN.turnDist = math.cos(FPLN.deltaAngleRad) * FPLN.R * FPLN.distCoeff / 1852;
				if (Gear.wow0.getBoolValue() and FPLN.turnDist < 1) {
					FPLN.turnDist = 1;
				}
				Internal.lnavAdvanceNm.setValue(FPLN.turnDist);
				
				if (FPLN.wp0Dist.getValue() <= FPLN.turnDist and flightplan().getWP(FPLN.currentWp.getValue()).fly_type == "flyBy") { # Don't care unless we are flyBy-ing
					FPLN.currentWp.setValue(FPLN.currentWpTemp + 1);
				}
			}
		}
		
		# Reset system once flight complete
		if (!Output.ap1.getBoolValue() and !Output.ap2.getBoolValue() and Gear.wow0.getBoolValue() and Velocities.groundspeedKt.getValue() < 60 and Output.vert.getValue() != 7) { # Not in T/O or G/A
			me.init(1);
		}
		
		# Calculate Roll and Pitch Rate Kp
		if (!Settings.disableFinal.getBoolValue()) {
			Gain.rollKpLowTemp = Gain.rollKpLow.getValue();
			Gain.rollKpHighTemp = Gain.rollKpHigh.getValue();
			Gain.pitchKpLowTemp = Gain.pitchKpLow.getValue();
			Gain.pitchKpHighTemp = Gain.pitchKpHigh.getValue();
			
			Gain.rollKpCalc = Gain.rollKpLowTemp + (Velocities.airspeedKt.getValue() - 140) * ((Gain.rollKpHighTemp - Gain.rollKpLowTemp) / (360 - 140));
			Gain.pitchKpCalc = Gain.pitchKpLowTemp + (Velocities.airspeedKt.getValue() - 140) * ((Gain.pitchKpHighTemp - Gain.pitchKpLowTemp) / (360 - 140));
			
			if (Gain.rollKpLowTemp > Gain.rollKpHighTemp) {
				Gain.rollKpCalc = math.clamp(Gain.rollKpCalc, Gain.rollKpHighTemp, Gain.rollKpLowTemp);
			} else if (Gain.rollKpLowTemp < Gain.rollKpHighTemp) {
				Gain.rollKpCalc = math.clamp(Gain.rollKpCalc, Gain.rollKpLowTemp, Gain.rollKpHighTemp);
			}
			if (Gain.pitchKpLowTemp > Gain.pitchKpHighTemp) {
				Gain.pitchKpCalc = math.clamp(Gain.pitchKpCalc, Gain.pitchKpHighTemp, Gain.pitchKpLowTemp);
			} else if (Gain.pitchKpLowTemp < Gain.pitchKpHighTemp) {
				Gain.pitchKpCalc = math.clamp(Gain.pitchKpCalc, Gain.pitchKpLowTemp, Gain.pitchKpHighTemp);
			}
			
			Gain.rollKp.setValue(Gain.rollKpCalc);
			Gain.pitchKp.setValue(Gain.pitchKpCalc);
		}
		
		# Calculate Roll Command Kp
		Gain.rollCmdKpCalc = Gain.hdgGain.getValue() + (Velocities.airspeedKt.getValue() - 140) * ((Gain.hdgGain.getValue() + 1.0 - Gain.hdgGain.getValue()) / (360 - 140));
		Gain.rollCmdKpCalc = math.clamp(Gain.rollCmdKpCalc, Gain.hdgGain.getValue(), Gain.hdgGain.getValue() + 1.0);
		
		Gain.rollCmdKp.setValue(Gain.rollCmdKpCalc);
	},
	ap1Master: func(s) {
		if (s == 1) {
			if (Input.ap1Avail.getBoolValue() and Output.vert.getValue() != 6 and !Gear.wow1.getBoolValue() and !Gear.wow2.getBoolValue()) {
				Controls.rudder.setValue(0);
				Output.ap1.setBoolValue(1);
				Sound.enableApOff = 1;
				Sound.apOff.setBoolValue(0);
			}
		} else {
			Output.ap1.setBoolValue(0);
			me.apOffFunction();
		}
		Output.ap1Temp = Output.ap1.getBoolValue();
		if (Input.ap1.getBoolValue() != Output.ap1Temp) {
			Input.ap1.setBoolValue(Output.ap1Temp);
		}
	},
	ap2Master: func(s) {
		if (s == 1) {
			if (Input.ap2Avail.getBoolValue() and Output.vert.getValue() != 6 and !Gear.wow1.getBoolValue() and !Gear.wow2.getBoolValue()) {
				Controls.rudder.setValue(0);
				Output.ap2.setBoolValue(1);
				Sound.enableApOff = 1;
				Sound.apOff.setBoolValue(0);
			}
		} else {
			Output.ap2.setBoolValue(0);
			me.apOffFunction();
		}
		Output.ap2Temp = Output.ap2.getBoolValue();
		if (Input.ap2.getBoolValue() != Output.ap2Temp) {
			Input.ap2.setBoolValue(Output.ap2Temp);
		}
	},
	apOffFunction: func() {
		if (!Output.ap1.getBoolValue() and !Output.ap2.getBoolValue()) { # Only do if both APs are off
			if (!Settings.disableFinal.getBoolValue()) {
				Controls.aileron.setValue(0);
				Controls.elevator.setValue(0);
				Controls.rudder.setValue(0);
			}
			if (Text.vert.getValue() == "ROLLOUT") {
				me.init(1);
			}
			if (Sound.enableApOff) {
				Sound.apOff.setBoolValue(1);
				Sound.enableApOff = 0;
			}
		}
	},
	athrMaster: func(s) {
		if (s == 1) {
			if (Input.athrAvail.getBoolValue()) {
				Output.athr.setBoolValue(1);
			}
		} else {
			Output.athr.setBoolValue(0);
		}
		Output.athrTemp = Output.athr.getBoolValue();
		if (Input.athr.getBoolValue() != Output.athrTemp) {
			Input.athr.setBoolValue(Output.athrTemp);
		}
	},
	killApSilent: func() {
		Output.ap1.setBoolValue(0);
		Output.ap2.setBoolValue(0);
		Sound.apOff.setBoolValue(0);
		Sound.enableApOff = 0;
		# Now that APs are off, we can safely update the input to 0 without the AP Master running
		Input.ap1.setBoolValue(0);
		Input.ap2.setBoolValue(0);
	},
	killAthrSilent: func() {
		Output.athr.setBoolValue(0);
		# Now that A/THR is off, we can safely update the input to 0 without the A/THR Master running
		Input.athr.setBoolValue(0);
	},
	fd1Master: func(s) {
		if (s == 1) {
			Output.fd1.setBoolValue(1);
		} else {
			Output.fd1.setBoolValue(0);
		}
		Output.fd1Temp = Output.fd1.getBoolValue();
		if (Input.fd1.getBoolValue() != Output.fd1Temp) {
			Input.fd1.setBoolValue(Output.fd1Temp);
		}
	},
	fd2Master: func(s) {
		if (s == 1) {
			Output.fd2.setBoolValue(1);
		} else {
			Output.fd2.setBoolValue(0);
		}
		Output.fd2Temp = Output.fd2.getBoolValue();
		if (Input.fd2.getBoolValue() != Output.fd2Temp) {
			Input.fd2.setBoolValue(Output.fd2Temp);
		}
	},
	setLatMode: func(n) {
		Output.vertTemp = Output.vert.getValue();
		if (n == 0) { # HDG SEL
			me.updateLnavArm(0);
			me.updateLocArm(0);
			me.updateApprArm(0);
			if (Settings.hdgHldSeparate.getBoolValue()) {
				Output.hdgInHld.setBoolValue(0);
			}
			Output.lat.setValue(0);
			me.updateLatText("HDG");
			if (Output.vertTemp == 2 or Output.vertTemp == 6) { # Also cancel G/S or FLARE if active
				me.setVertMode(1);
			}
		} else if (n == 1) { # LNAV
			me.updateLocArm(0);
			me.updateApprArm(0);
			me.checkLnav(0);
		} else if (n == 2) { # VOR/LOC
			me.updateLnavArm(0);
			me.checkLoc(0);
		} else if (n == 3) { # HDG HLD
			me.updateLnavArm(0);
			me.updateLocArm(0);
			me.updateApprArm(0);
			Internal.hdgHldValue = Input.hdg.getValue(); # Unused if HDG HLD is seperated
			if (Settings.hdgHldSeparate.getBoolValue()) {
				Internal.hdgHldTarget.setValue(math.round(Internal.hdgPredicted.getValue())); # Switches to track automatically
			} else {
				me.syncHdg();
			}
			Output.hdgInHld.setBoolValue(1);
			Output.lat.setValue(0);
			me.updateLatText("HDG");
			if (Output.vertTemp == 2 or Output.vertTemp == 6) { # Also cancel G/S or FLARE if active
				me.setVertMode(1);
			}
		} else if (n == 4) { # ALIGN
			me.updateLnavArm(0);
			me.updateLocArm(0);
			me.updateApprArm(0);
			Output.lat.setValue(4);
			me.updateLatText("ALGN");
		} else if (n == 5) { # T/O
			me.updateLnavArm(0);
			me.updateLocArm(0);
			me.updateApprArm(0);
			Output.lat.setValue(5);
			me.updateLatText("T/O");
		} else if (n == 6) { # ROLL
			me.updateLnavArm(0);
			me.updateLocArm(0);
			me.updateApprArm(0);
			Output.lat.setValue(6);
			me.updateLatText("ROLL");
			me.syncRoll();
		} else if (n == 9) { # Blank
			me.updateLnavArm(0);
			me.updateLocArm(0);
			me.updateApprArm(0);
			Output.lat.setValue(9);
			me.updateLatText("");
			if (!Settings.disableFinal.getBoolValue()) {
				Controls.aileron.setValue(0);
				Controls.rudder.setValue(0);
			}
		}
	},
	setLatArm: func(n) {
		if (n == 0) {
			me.updateLnavArm(0);
		} else if (n == 1) {
			if (FPLN.num.getValue() > 0 and FPLN.active.getBoolValue()) {
				me.updateLnavArm(1);
			}
		} else if (n == 3) {
			me.syncHdg();
			me.updateLnavArm(0);
		} 
	},
	setVertMode: func(n) {
		Input.altDiff = Input.alt.getValue() - Position.indicatedAltitudeFt.getValue();
		if (n == 0) { # ALT HLD
			Internal.flchActive = 0;
			Internal.altCaptureActive = 0;
			me.updateApprArm(0);
			Output.vert.setValue(0);
			me.resetClimbRateLim();
			me.updateVertText("ALT HLD");
			me.syncAlt();
			me.updateThrustMode();
		} else if (n == 1) { # V/S or FPA
			if (Input.vsFpa.getBoolValue()) { # FPA if vsFpa is set
				if (abs(Input.altDiff) >= 25) {
					Internal.flchActive = 0;
					Internal.altCaptureActive = 0;
					me.updateApprArm(0);
					Output.vert.setValue(5);
					me.updateVertText("FPA");
					me.syncFpa();
					me.updateThrustMode();
				} else {
					me.updateApprArm(0);
				}
			} else {
				if (abs(Input.altDiff) >= 25) {
					Internal.flchActive = 0;
					Internal.altCaptureActive = 0;
					me.updateApprArm(0);
					Output.vert.setValue(1);
					me.updateVertText("V/S");
					me.syncVs();
					me.updateThrustMode();
				} else {
					me.updateApprArm(0);
				}
			}
		} else if (n == 2) { # G/S
			me.updateLnavArm(0);
			me.checkLoc(0);
			me.checkAppr(0);
		} else if (n == 3) { # ALT CAP
			Internal.flchActive = 0;
			Output.vert.setValue(0);
			me.setClimbRateLim();
			Internal.altCaptureActive = 1;
			me.updateVertText("ALT CAP");
			me.updateThrustMode();
		} else if (n == 4) { # FLCH
			me.updateApprArm(0);
			if (abs(Input.altDiff) >= 125) { # SPD CLB or SPD DES
				Internal.altCaptureActive = 0;
				Output.vert.setValue(4);
				Internal.flchActive = 1;
				Internal.alt.setValue(Input.alt.getValue());
				me.updateThrustMode();
			} else { # ALT CAP
				Internal.flchActive = 0;
				Internal.alt.setValue(Input.alt.getValue());
				Internal.altCaptureActive = 1;
				Output.vert.setValue(0);
				me.updateVertText("ALT CAP");
				me.updateThrustMode();
			}
		} else if (n == 5) { # FPA
			if (abs(Input.altDiff) >= 25) {
				Internal.flchActive = 0;
				Internal.altCaptureActive = 0;
				me.updateApprArm(0);
				Output.vert.setValue(5);
				me.updateVertText("FPA");
				me.syncFpa();
				me.updateThrustMode();
			} else {
				me.updateApprArm(0);
			}
		} else if (n == 6) { # FLARE/ROLLOUT
			Internal.flchActive = 0;
			Internal.altCaptureActive = 0;
			me.updateApprArm(0);
			Output.vert.setValue(6);
			me.updateVertText("FLARE");
			me.updateThrustMode();
		} else if (n == 7) { # T/O CLB or G/A CLB, text is set by TOGA selector
			Internal.flchActive = 0;
			Internal.altCaptureActive = 0;
			me.updateApprArm(0);
			Output.vert.setValue(7);
			Input.ktsMach.setBoolValue(0);
			me.updateThrustMode();
		} else if (n == 9) { # Blank
			Internal.flchActive = 0;
			Internal.altCaptureActive = 0;
			me.updateApprArm(0);
			Output.vert.setValue(9);
			me.updateVertText("");
			me.updateThrustMode();
			if (!Settings.disableFinal.getBoolValue()) {
				Controls.elevator.setValue(0);
			}
		}
	},
	updateThrustMode: func() {
		Output.vertTemp = Output.vert.getValue();
		if (Output.athr.getBoolValue() and Output.vertTemp != 7 and Settings.retardEnable.getBoolValue() and Position.gearAglFt.getValue() <= Settings.retardAltitude.getValue() and Misc.flapNorm.getValue() >= Settings.landingFlap.getValue() - 0.001) {
			Output.thrMode.setValue(1);
			Text.thr.setValue("RETARD");
			if (Gear.wow1.getBoolValue() or Gear.wow2.getBoolValue()) { # Disconnect A/THR on either main gear touch
				me.athrMaster(0);
				setprop("/controls/engines/engine[0]/throttle", 0);
				setprop("/controls/engines/engine[1]/throttle", 0);
				setprop("/controls/engines/engine[2]/throttle", 0);
				setprop("/controls/engines/engine[3]/throttle", 0);
				setprop("/controls/engines/engine[4]/throttle", 0);
				setprop("/controls/engines/engine[5]/throttle", 0);
				setprop("/controls/engines/engine[6]/throttle", 0);
				setprop("/controls/engines/engine[7]/throttle", 0);
			}
		} else if (Output.vertTemp == 4) {
			if (Internal.alt.getValue() >= Position.indicatedAltitudeFt.getValue()) {
				Output.thrMode.setValue(2);
				Text.thr.setValue("PITCH");
				if (Internal.flchActive and Text.vert.getValue() != "SPD CLB") {
					me.updateVertText("SPD CLB");
				}
			} else {
				Output.thrMode.setValue(1);
				Text.thr.setValue("PITCH");
				if (Internal.flchActive and Text.vert.getValue() != "SPD DES") {
					me.updateVertText("SPD DES");
				}
			}
		} else if (Output.vertTemp == 7) {
			Output.thrMode.setValue(2);
			Text.thr.setValue("PITCH");
		} else {
			Output.thrMode.setValue(0);
			Text.thr.setValue("THRUST");
		}
	},
	activateLnav: func() {
		if (Output.lat.getValue() != 1) {
			me.updateLnavArm(0);
			me.updateLocArm(0);
			me.updateApprArm(0);
			Output.lat.setValue(1);
			me.updateLatText("LNAV");
			if (Output.vertTemp == 2 or Output.vertTemp == 6) { # Also cancel G/S or FLARE if active
				me.setVertMode(1);
			}
		}
	},
	activateLoc: func() {
		if (Output.lat.getValue() != 2) {
			me.updateLnavArm(0);
			me.updateLocArm(0);
			Output.lat.setValue(2);
			me.updateLatText("LOC");
		}
	},
	activateGs: func() {
		if (Output.vert.getValue() != 2) {
			Internal.flchActive = 0;
			Internal.altCaptureActive = 0;
			me.updateApprArm(0);
			Output.vert.setValue(2);
			me.updateVertText("G/S");
			me.updateThrustMode();
		}
	},
	checkLnav: func(t) {
		FPLN.activeTemp = FPLN.active.getBoolValue();
		if (FPLN.num.getValue() > 0 and FPLN.activeTemp and Position.gearAglFt.getValue() >= Settings.latAglFt.getValue()) {
			me.activateLnav();
		} else if (FPLN.activeTemp and Output.lat.getValue() != 1 and t != 1) {
			me.updateLnavArm(1);
		}
		if (!FPLN.activeTemp) {
			me.updateLnavArm(0);
		}
	},
	checkFlch: func(a) {
		if (Position.gearAglFt.getValue() >= a and a != 0) {
			me.setVertMode(4);
		}
	},
	checkLoc: func(t) {
		Input.radioSelTemp = Input.radioSel.getValue();
		if (Radio.inRange[Input.radioSelTemp].getBoolValue()) { #  # Only evaulate the rest of the condition unless we are in range
			Internal.navHeadingErrorDegTemp[Input.radioSelTemp] = Internal.navHeadingErrorDeg[Input.radioSelTemp].getValue();
			Radio.locDeflTemp[Input.radioSelTemp] = Radio.locDefl[Input.radioSelTemp].getValue();
			Radio.signalQualityTemp[Input.radioSelTemp] = Radio.signalQuality[Input.radioSelTemp].getValue();
			if (abs(Radio.locDeflTemp[Input.radioSelTemp]) <= 0.95 and Radio.locDeflTemp[Input.radioSelTemp] != 0 and Radio.signalQualityTemp[Input.radioSelTemp] >= 0.99) {
				if (abs(Radio.locDeflTemp[Input.radioSelTemp]) <= 0.25) {
					me.activateLoc();
				} else if (Radio.locDeflTemp[Input.radioSelTemp] >= 0 and Internal.navHeadingErrorDegTemp[Input.radioSelTemp] <= 0) {
					me.activateLoc();
				} else if (Radio.locDeflTemp[Input.radioSelTemp] < 0 and Internal.navHeadingErrorDegTemp[Input.radioSelTemp] >= 0) {
					me.activateLoc();
				} else if (t != 1) { # Do not do this if loop calls it
					if (Output.lat.getValue() != 2) {
						me.updateLnavArm(0);
						me.updateLocArm(1);
					}
				}
			} else if (t != 1) { # Do not do this if loop calls it
				if (Output.lat.getValue() != 2) {
					me.updateLnavArm(0);
					me.updateLocArm(1);
				}
			}
		} else {
			Radio.signalQuality[Input.radioSelTemp].setValue(0); # Prevent bad behavior due to FG not updating it when not in range
			me.updateLocArm(0);
		}
	},
	checkAppr: func(t) {
		Input.radioSelTemp = Input.radioSel.getValue();
		if (Radio.inRange[Input.radioSelTemp].getBoolValue()) { #  # Only evaulate the rest of the condition unless we are in range
			Radio.gsDeflTemp[Input.radioSelTemp] = Radio.gsDefl[Input.radioSelTemp].getValue();
			if (abs(Radio.gsDeflTemp[Input.radioSelTemp]) <= 0.2 and Radio.gsDeflTemp[Input.radioSelTemp] != 0 and Output.lat.getValue() == 2 and abs(Internal.navCourseTrackErrorDeg[Input.radioSelTemp].getValue()) <= 80) { # Only capture if LOC is active and course error less or equals 80
				me.activateGs();
			} else if (t != 1) { # Do not do this if loop calls it
				if (Output.vert.getValue() != 2) {
					me.updateApprArm(1);
				}
			}
		} else {
			Radio.signalQuality[Input.radioSelTemp].setValue(0); # Prevent bad behavior due to FG not updating it when not in range
			me.updateApprArm(0);
		}
	},
	checkRadioRevision: func(l, v) { # Revert mode if signal lost
		if (!Radio.inRange[Input.radioSel.getValue()].getBoolValue()) {
			if (l == 4 or v == 6) {
				me.ap1Master(0);
				me.ap2Master(0);
				me.setLatMode(3);
				me.setVertMode(1);
			} else {
				me.setLatMode(3); # Also cancels G/S if active
			}
		}
	},
	setClimbRateLim: func() {
		Internal.vsTemp = Internal.vs.getValue();
		if (Internal.alt.getValue() >= Position.indicatedAltitudeFt.getValue()) {
			Internal.maxVs.setValue(math.round(Internal.vsTemp));
			Internal.minVs.setValue(-500);
		} else {
			Internal.maxVs.setValue(500);
			Internal.minVs.setValue(math.round(Internal.vsTemp));
		}
	},
	resetClimbRateLim: func() {
		Internal.minVs.setValue(-500);
		Internal.maxVs.setValue(500);
	},
	takeoffGoAround: func() {
		Output.vertTemp = Output.vert.getValue();
		if ((Output.vertTemp == 2 or Output.vertTemp == 6) and Velocities.indicatedAirspeedKt.getValue() >= 80) {
			me.setLatMode(3);
			me.setVertMode(7); # Must be before kicking AP off
			me.updateVertText("G/A CLB");
			me.syncKtsGa();
			if (Gear.wow1.getBoolValue() or Gear.wow2.getBoolValue()) {
				me.ap1Master(0);
				me.ap2Master(0);
			}
		} else if (Gear.wow1Temp or Gear.wow2Temp) {
			me.athrMaster(1);
			if (Output.lat.getValue() != 5) { # Don't accidently disarm LNAV
				me.setLatMode(5);
			}
			me.setVertMode(7);
			me.updateVertText("T/O CLB");
		}
	},
	syncKts: func() {
		Input.kts.setValue(math.clamp(math.round(Velocities.indicatedAirspeedKt.getValue()), 100, 350));
	},
	syncKtsGa: func() { # Same as syncKts, except doesn't go below TogaSpd
		Input.kts.setValue(math.clamp(math.round(Velocities.indicatedAirspeedKt.getValue()), Settings.togaSpd.getValue(), 350));
	},
	syncMach: func() {
		Input.mach.setValue(math.clamp(math.round(Velocities.indicatedMach.getValue(), 0.001), 0.5, 0.9));
	},
	syncHdg: func() {
		Input.hdg.setValue(math.round(Internal.hdgPredicted.getValue())); # Switches to track automatically
	},
	syncRoll: func() {
		Internal.bankLimitTemp = Internal.bankLimit.getValue();
		Input.roll.setValue(math.clamp(math.round(Orientation.rollDeg.getValue(), 1), Internal.bankLimitTemp * -1, Internal.bankLimitTemp));
	},
	syncAlt: func() {
		Input.alt.setValue(math.clamp(math.round(Internal.altPredicted.getValue(), 100), 0, 50000));
		Internal.alt.setValue(math.clamp(math.round(Internal.altPredicted.getValue(), 100), 0, 50000));
	},
	syncVs: func() {
		Input.vs.setValue(math.clamp(math.round(Internal.vs.getValue(), 100), -6000, 6000));
	},
	syncFpa: func() {
		Input.fpa.setValue(math.clamp(math.round(Internal.fpa.getValue(), 0.1), -9.9, 9.9));
	},
	# Allows custom FMA behavior if desired
	updateLatText: func(t) {
		Text.lat.setValue(t);
		if (Settings.customFma.getBoolValue()) {
			updateFma.lat();
		}
	},
	updateVertText: func(t) {
		Text.vert.setValue(t);
		if (Settings.customFma.getBoolValue()) {
			updateFma.vert();
		}
	},
	updateLnavArm: func(n) {
		Output.lnavArm.setBoolValue(n);
		if (Settings.customFma.getBoolValue()) {
			updateFma.arm();
		}
	},
	updateLocArm: func(n) {
		Output.locArm.setBoolValue(n);
		if (Settings.customFma.getBoolValue()) {
			updateFma.arm();
		}
	},
	updateApprArm: func(n) {
		Output.apprArm.setBoolValue(n);
		if (Settings.customFma.getBoolValue()) {
			updateFma.arm();
		}
	},
};

setlistener("/it-autoflight/input/ap1", func() {
	Input.ap1Temp = Input.ap1.getBoolValue();
	if (Input.ap1Temp != Output.ap1.getBoolValue()) {
		ITAF.ap1Master(Input.ap1Temp);
	}
});

setlistener("/it-autoflight/input/ap2", func() {
	Input.ap2Temp = Input.ap2.getBoolValue();
	if (Input.ap2Temp != Output.ap2.getBoolValue()) {
		ITAF.ap2Master(Input.ap2Temp);
	}
});

setlistener("/it-autoflight/input/athr", func() {
	Input.athrTemp = Input.athr.getBoolValue();
	if (Input.athrTemp != Output.athr.getBoolValue()) {
		ITAF.athrMaster(Input.athrTemp);
	}
});

setlistener("/it-autoflight/input/fd1", func() {
	Input.fd1Temp = Input.fd1.getBoolValue();
	if (Input.fd1Temp != Output.fd1.getBoolValue()) {
		ITAF.fd1Master(Input.fd1Temp);
	}
});

setlistener("/it-autoflight/input/fd2", func() {
	Input.fd2Temp = Input.fd2.getBoolValue();
	if (Input.fd2Temp != Output.fd2.getBoolValue()) {
		ITAF.fd2Master(Input.fd2Temp);
	}
});

setlistener("/it-autoflight/input/kts-mach", func() {
	if (Output.vert.getValue() == 7) { # Mach is not allowed in Mode 7, and don't sync
		if (Input.ktsMach.getBoolValue()) {
			Input.ktsMach.setBoolValue(0);
		}
	} else {
		if (Input.ktsMach.getBoolValue()) {
			ITAF.syncMach();
		} else {
			ITAF.syncKts();
		}
	}
}, 0, 0);

setlistener("/it-autoflight/input/toga", func() {
	if (Input.toga.getBoolValue()) {
		ITAF.takeoffGoAround();
		Input.toga.setBoolValue(0);
	}
});

setlistener("/it-autoflight/input/lat", func() {
	Input.latTemp = Input.lat.getValue();
	if (!Gear.wow1.getBoolValue() and !Gear.wow2.getBoolValue()) {
		ITAF.setLatMode(Input.latTemp);
	} else {
		ITAF.setLatArm(Input.latTemp);
	}
});

setlistener("/it-autoflight/input/vert", func() {
	if (!Gear.wow1.getBoolValue() and !Gear.wow2.getBoolValue()) {
		ITAF.setVertMode(Input.vert.getValue());
	}
});

setlistener("/it-autoflight/input/vs-fpa", func() {
	if (Input.vsFpa.getBoolValue()) {
		if (Output.vert.getValue() == 1) {
			afs.Input.vert.setValue(5);
		}
	} else {
		if (Output.vert.getValue() == 5) {
			afs.Input.vert.setValue(1);
		}
	}
});

setlistener("/it-autoflight/input/trk", func() {
	Input.trkTemp = Input.trk.getBoolValue();
	Internal.driftAngleTemp = math.round(Internal.driftAngle.getValue());
	
	if (Input.trkTemp) {
		Input.hdgCalc = Input.hdg.getValue() + Internal.driftAngleTemp;
		Input.hdgHldCalc = Internal.hdgHldTarget.getValue() + Internal.driftAngleTemp;
	} else {
		Input.hdgCalc = Input.hdg.getValue() - Internal.driftAngleTemp;
		Input.hdgHldCalc = Internal.hdgHldTarget.getValue() - Internal.driftAngleTemp;
	}
	
	if (Input.hdgCalc > 360) { # It's rounded, so this is ok. Otherwise do >= 360.5
		Input.hdgCalc = Input.hdgCalc - 360;
	} else if (Input.hdgCalc < 1) { # It's rounded, so this is ok. Otherwise do < 0.5
		Input.hdgCalc = Input.hdgCalc + 360;
	}
	if (Input.hdgHldCalc > 360) { # It's rounded, so this is ok. Otherwise do >= 360.5
		Input.hdgHldCalc = Input.hdgHldCalc - 360;
	} else if (Input.hdgHldCalc < 1) { # It's rounded, so this is ok. Otherwise do < 0.5
		Input.hdgHldCalc = Input.hdgHldCalc + 360;
	}
	
	Input.hdg.setValue(Input.hdgCalc);
	Internal.hdgHldTarget.setValue(Input.hdgHldCalc);
	
	if (Settings.customFma.getBoolValue()) {
		updateFma.lat();
	}
	
	Misc.efis0Trk.setBoolValue(Input.trkTemp); # For Canvas Nav Display.
	Misc.efis1Trk.setBoolValue(Input.trkTemp); # For Canvas Nav Display.
}, 0, 0);

setlistener("/sim/signals/fdm-initialized", func() {
	ITAF.init();
});

# For Canvas Nav Display.
setlistener("/it-autoflight/input/hdg", func() {
	setprop("/autopilot/settings/heading-bug-deg", getprop("/it-autoflight/input/hdg"));
}, 0, 0);

setlistener("/it-autoflight/internal/alt", func() {
	setprop("/autopilot/settings/target-altitude-ft", getprop("/it-autoflight/internal/alt"));
}, 0, 0);

var loopTimer = maketimer(0.1, ITAF, ITAF.loop);
var slowLoopTimer = maketimer(1, ITAF, ITAF.slowLoop);
