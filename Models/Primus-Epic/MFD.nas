# E-Jet Family MFD

var mfd_display = [nil, nil];
var mfd = [nil, nil];

var MFD = {
    new: func(canvas_group, file, index = 0) {
        var m = { parents: [MFD] };
        m.init(canvas_group, file, index);
        return m;
    },

    init: func(canvas_group, file, index) {
        var font_mapper = func(family, weight) {
            return "LiberationFonts/LiberationSans-Regular.ttf";
        };


        # canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});
        # var svg_keys = me.getKeys();
        # foreach(var key; svg_keys) {
        #     me[key] = canvas_group.getElementById(key);
        #     var svg_keys = me.getKeys();
        #     foreach (var key; svg_keys) {
        #     me[key] = canvas_group.getElementById(key);
        #     var clip_el = canvas_group.getElementById(key ~ "_clip");
        #     if (clip_el != nil) {
        #         clip_el.setVisible(0);
        #         var tran_rect = clip_el.getTransformedBounds();
        #         var clip_rect = sprintf("rect(%d,%d, %d,%d)",
        #         tran_rect[1], # 0 ys
        #         tran_rect[2], # 1 xe
        #         tran_rect[3], # 2 ye
        #         tran_rect[0]); #3 xs
        #         #   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
        #         me[key].set("clip", clip_rect);
        #         me[key].set("clip-frame", canvas.Element.PARENT);
        #     }
        #     }
        # }

        me.master = canvas_group;

        # Upper area (lateral/systems): 1024x970
        me.upperArea = me.master.createChild("group");
        me.upperArea.set("clip", "rect(80px, 1024px, 1050px, 0px)");
        me.upperArea.set("clip-frame", canvas.Element.PARENT);
        # me.upperArea.setTranslation(0, 80);

        # Lower area (vertical/checklists): 1024x400
        me.lowerArea = me.master.createChild("group");
        me.lowerArea.set("clip", "rect(1050px, 1024px, 1450px, 0px)");
        me.lowerArea.set("clip-frame", canvas.Element.PARENT);
        # me.upperArea.setTranslation(0, 1050);

        me.guiOverlay = me.master.createChild("group");

        me.planPage = me.upperArea.createChild("group");
        me.plan = me.planPage.createChild("map");
        me.plan.setTranslation(512, 485);
        me.plan.setController("Aircraft position");
        me.plan.setRange(25);
        me.plan.addLayer(factory: canvas.SymbolLayer, type_arg: "APS", visible: 1, priority: 10,);
        me.plan.addLayer(factory: canvas.SymbolLayer, type_arg: "RTE", visible: 1, priority: 5,);
        me.plan.addLayer(factory: canvas.SymbolLayer, type_arg: "WPT", visible: 1, priority: 6,);
        me.plan.addLayer(factory: canvas.SymbolLayer, type_arg: "TFC", visible: 1, priority: 9,);

        var plan = me.plan;
        setlistener("/instrumentation/mfd[" ~ index ~ "]/lateral-range", func (node) {
            plan.setRange(node.getValue());
            debug.dump(node.getValue());
        }, 0, 0);

        return me;
    },

    touch: func(args) {
        debug.dump(args);
    },

    update: func () {
    }
};


setlistener("sim/signals/fdm-initialized", func {
    for (var i = 0; i <= 1; i += 1) {
        mfd_display[i] = canvas.new({
            "name": "MFD" ~ i,
            "size": [1024, 1530],
            "view": [1024, 1530],
            "mipmapping": 1
        });
        mfd_display[i].addPlacement({"node": "MFD" ~ i});
        mfd[i] =
            MFD.new(
                mfd_display[i].createGroup(),
                "Aircraft/E-jet-family/Models/Primus-Epic/MFD.svg",
                i);
    }

    var timer = maketimer(0.2, func() {
        mfd[0].update();
        mfd[1].update();
    });
    timer.start();
});
