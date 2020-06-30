var dialogs_path = "Aircraft/E-jet-family/gui/dialogs/";
var Dialogs = {
	announcements: gui.Dialog.new("sim/gui/dialogs/E-jet-family[1]/menu/dialog", dialogs_path~"announcements-dlg.xml"),
	autopilot: gui.Dialog.new("sim/gui/dialogs/autopilot/dialog", dialogs_path~"it-autoflight-dlg.xml"),
	lights: gui.Dialog.new("sim/gui/dialogs/lights/dialog", dialogs_path~"lights-dlg.xml"),
	operations: gui.Dialog.new("sim/gui/dialogs/E-jet-family[0]/menu/dialog", dialogs_path~"operations-dlg.xml"),
	radio: gui.Dialog.new("sim/gui/dialogs/radios/dialog", dialogs_path~"radio.xml"),
	tiller: gui.Dialog.new("sim/gui/dialogs/tiller/dialog", dialogs_path~"tiller-dlg.xml"),
	performance: gui.Dialog.new("sim/gui/dialogs/performance/dialog", dialogs_path~"performance-dlg.xml"),
	
};

gui.menuBind("autopilot", "dialogs.Dialogs.autopilot.open();");
gui.menuBind("radio", "dialogs.Dialogs.radio.open();");
gui.menuBind("failures", "dialogs.Dialogs.failures.open();");
