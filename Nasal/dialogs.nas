var dialogs_path = "Aircraft/E-jet-family/gui/dialogs/";
var Dialogs = {
	announcements: gui.Dialog.new("sim/gui/dialogs/E-jet-family[1]/menu/dialog", dialogs_path~"announcements-dlg.xml"),
	autopilot: gui.Dialog.new("sim/gui/dialogs/autopilot/dialog", dialogs_path~"it-autoflight-dlg.xml"),
	lights: gui.Dialog.new("sim/gui/dialogs/lights/dialog", dialogs_path~"lights-dlg.xml"),
	operations: gui.Dialog.new("sim/gui/dialogs/E-jet-family[0]/menu/dialog", dialogs_path~"operations-dlg.xml"),
	radio: gui.Dialog.new("sim/gui/dialogs/radios/dialog", dialogs_path~"radio.xml"),
	tiller: gui.Dialog.new("sim/gui/dialogs/tiller/dialog", dialogs_path~"tiller-dlg.xml"),
	performance: gui.Dialog.new("sim/gui/dialogs/performance/dialog", dialogs_path~"performance-dlg.xml"),
    autopush: gui.Dialog.new("sim/gui/dialogs/autopush/dialog", dialogs_path ~ "autopush.xml"),
    mcdu1: gui.Dialog.new("sim/gui/dialogs/mcdu1/dialog", dialogs_path~"mcdu1-dlg.xml"),
    mcdu2: gui.Dialog.new("sim/gui/dialogs/mcdu2/dialog", dialogs_path~"mcdu2-dlg.xml"),
    pfd1: gui.Dialog.new("sim/gui/dialogs/pfd1/dialog", dialogs_path~"pfd1-dlg.xml"),
    pfd2: gui.Dialog.new("sim/gui/dialogs/pfd2/dialog", dialogs_path~"pfd2-dlg.xml"),
    mfd1: gui.Dialog.new("sim/gui/dialogs/mfd1/dialog", dialogs_path~"mfd1-dlg.xml"),
    mfd2: gui.Dialog.new("sim/gui/dialogs/mfd2/dialog", dialogs_path~"mfd2-dlg.xml"),
    simbrief: gui.Dialog.new("sim/gui/dialogs/simbrief/dialog", dialogs_path~"simbrief.xml"),
};

gui.menuBind("autopilot", "dialogs.Dialogs.autopilot.open();");
gui.menuBind("radio", "dialogs.Dialogs.radio.open();");
gui.menuBind("failures", "dialogs.Dialogs.failures.open();");
