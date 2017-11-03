var autopitot_setting = {
	speed: "autopilot/settings/speed",
	hdg: "autopilot/settings/heading",
	alt: "autopilot/settings/altitude",
};

var toggleTOGA = func() {
	if (getprop(autopitot_setting.speed) == "speed-to-ga") {
		setprop(autopitot_setting.speed, "");
	} else {
		setprop(autopitot_setting.speed, "speed-to-ga");
	}
};

var toggleGS = func() {
	if (getprop(autopitot_setting.alt) == "gs1-hold") {
		setprop(autopitot_setting.hdg, "dg-heading-hold");
		setprop(autopitot_setting.alt, "altitude-hold");
	} else {
		setprop(autopitot_setting.hdg, "nav1-hold");
		setprop(autopitot_setting.alt, "gs1-hold");
	}
};

var toggleHeadingMode = func(hdg) {
	if (getprop(autopitot_setting.hdg) == hdg) {
		setprop(autopitot_setting.hdg, "dg-heading-hold");
	} else {
		setprop(autopitot_setting.hdg, hdg);
	}
};