# Effects volume

var vol = {
	  apu: props.globals.getNode("sim/sound/apu-vol"),
	 gear: props.globals.getNode("sim/sound/gear-vol"),
	flaps: props.globals.getNode("sim/sound/flaps-vol"),
};

# int/ext volume control for 'static' sound events
setlistener("sim/current-view/internal", func (node) {
	if (node.getValue() == 1) {
		vol.apu.setValue(0.2);
		vol.gear.setValue(0.2);
		vol.flaps.setValue(0.02);
	}
	else {
		vol.apu.setValue(1.0);
		vol.gear.setValue(1.0);
		vol.flaps.setValue(0.5);
	}
}, 0, 0);
