# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'WXR'; # storms/weather layer for LW/AW (use thunderstom scenario for testing)
var parents = [DotSym];
var __self__ = caller(0)[0];
DotSym.makeinstance( name, __self__ );

var element_type = "group"; # we want a group, becomes "me.element"

# TODO: how to integrate both styling and caching?
var draw = func {
	# TODO: once this works properly, consider using caching here 
	# FIXME: scaling seems way off in comparison with the navdisplay - i.e. hard-coded assumptions about texture size/view port ?
	me.element.createChild("image")
		.setFile("Nasal/canvas/map/Images/storm.png")
		.setSize(128*me.model.radiusNm,128*me.model.radiusNm)
		.setTranslation(-64*me.model.radiusNm,-64*me.model.radiusNm)
		.setCenter(0,0);
		# .setScale(0.3);
	# TODO: overlapping storms should probably set their z-index according to altitudes
	
};

