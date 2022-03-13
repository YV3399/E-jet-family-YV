# view nodes and offsets --------------------------------------------
var zNoseNode = props.globals.getNode("sim/view/config/y-offset-m", 1);
var xViewNode = props.globals.getNode("sim/current-view/z-offset-m", 1);
var yViewNode = props.globals.getNode("sim/current-view/x-offset-m", 1);
var hViewNode = props.globals.getNode("sim/current-view/heading-offset-deg", 1);

var walk_about = func(wa_distance) {
	var walkable = getprop("sim/current-view/config/walkable") or 0;
	if (walkable) {
		var wa_heading_rad = hViewNode.getValue() * 0.01745329252;
		var new_x_position = xViewNode.getValue() - (math.cos(wa_heading_rad) * wa_distance);
		var new_y_position = yViewNode.getValue() - (math.sin(wa_heading_rad) * wa_distance);
		xViewNode.setValue(new_x_position);
		yViewNode.setValue(new_y_position);
	}
}

