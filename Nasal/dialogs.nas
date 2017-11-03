var aircraft_path = "Aircraft/E-jet-family/Systems/";
var Dialogs = {
	announcements: gui.Dialog.new("sim/gui/dialogs/E-jet-family[1]/menu/dialog", aircraft_path~"announcements-dlg.xml"),
	autopilot: gui.Dialog.new("sim/gui/dialogs/autopilot/dialog", aircraft_path~"autopilot-dlg.xml"),
	lights: gui.Dialog.new("sim/gui/dialogs/lights/dialog", aircraft_path~"lights-dlg.xml"),
	operations: gui.Dialog.new("sim/gui/dialogs/E-jet-family[0]/menu/dialog", aircraft_path~"operations-dlg.xml"),
	radio: gui.Dialog.new("sim/gui/dialogs/radios/dialog", aircraft_path~"radio.xml"),
	tiller: gui.Dialog.new("sim/gui/dialogs/tiller/dialog", aircraft_path~"tiller-dlg.xml"),
	failures: gui.Dialog.new("sim/gui/dialogs/failures/dialog", aircraft_path~"failures-dlg.xml"),
};

gui.menuBind("autopilot", "dialogs.Dialogs.autopilot.open();");
gui.menuBind("radio", "dialogs.Dialogs.radio.open();");
gui.menuBind("failures", "dialogs.Dialogs.failures.open();");