gui.showWeightDialog = func {
    var name = "WeightAndFuel";
#   menu entry is "Fuel and Payload"
    var title = "Fuel and Payload Settings";
    weightDialogOpen = 1;
    #
    # General Dialog Structure
    #
    dialog[name] = Widget.new();
    dialog[name].set("name", name);
    dialog[name].set("layout", "vbox");

# 2018.3 - add a close method that will remember the coordinates and also clear the flag that
#          indicates this dialog is visible
    var nasal = dialog[name].addChild("nasal");
    var nasal_close = nasal.addChild("close");
    nasal_close.node.setValue(dlg_nasal_close ~ 'foreach (var l; gui.dialog["' ~ name ~ '"].listeners) { removelistener(l); }');
    dialog[name].listeners = [];

# if we have an X coordinate then set both (to the previous position as recorded on close).
    if (weightAndFuel_x != nil){
        dialog[name].set("x", weightAndFuel_x);
        dialog[name].set("y", weightAndFuel_y);
    }

    var header = dialog[name].addChild("group");
    header.set("layout", "hbox");
    header.addChild("empty").set("stretch", "1");
    header.addChild("text").set("label", title);
    header.addChild("empty").set("stretch", "1");
    var w = header.addChild("button");
    w.set("pref-width", 16);
    w.set("pref-height", 16);
    w.set("legend", "");
    w.set("default", 0);
    # "Esc" causes dialog-close
    w.set("key", "Esc");
    w.setBinding("dialog-close");

    dialog[name].addChild("hrule");

    var fdmdata = {
        grosswgt : "/fms/fuel/gw-kg",
        payload  : "/payload",
        cg       : "/fdm/jsbsim/inertia/cg-x-in",
        percentMac: "/weight-and-balance/mac-position-percent",
    };

    var contentArea = dialog[name].addChild("group");
    contentArea.set("layout", "hbox");
    contentArea.set("default-padding", 10);

    dialog[name].addChild("empty");

    var limits = dialog[name].addChild("group");
    limits.set("layout", "table");
    limits.set("halign", "center");
    var row = 0;
    var col = 0;

    var tablerow = func(name, format, node, placeholder = '1234567890') {
        if (node == nil) return;
        var label = limits.addChild("text");
        label.set("row", row);
        label.set("col", col + 0);
        label.set("halign", "left");
        label.set("label", name ~ ":");

        var val = limits.addChild("text");
        val.set("row", row);
        val.set("col", col + 1);
        val.set("halign", "right");
        val.set("label", placeholder);
        val.set("format", format);
        val.set("property", node.getPath());
        val.set("live", 1);
          
        row += 1;
    }

    var tablerow2 = func(name, format, nodeMin, nodeMax, placeholder = '1234567') {
        if (nodeMax == nil or nodeMin == nil) return;
        var label = limits.addChild("text");
        label.set("row", row);
        label.set("col", col + 0);
        label.set("halign", "left");
        label.set("label", name ~ ":");

        var valMin = limits.addChild("text");
        valMin.set("row", row);
        valMin.set("col", col + 1);
        valMin.set("halign", "right");
        valMin.set("label", placeholder);
        valMin.set("format", format);
        valMin.set("property", nodeMin.getPath());
        valMin.set("live", 1);

        var valMax = limits.addChild("text");
        valMax.set("row", row);
        valMax.set("col", col + 2);
        valMax.set("halign", "right");
        valMax.set("label", "0123457890123456789");
        valMax.set("format", format);
        valMax.set("property", nodeMax.getPath());
        valMax.set("live", 1);
          
        row += 1;
    }

    row = 0;
    col = 0;
    var massLimits = props.globals.getNode("/limits/mass-and-balance");
    tablerow("ZFW (Zero Fuel Weight)", "%7.0f kg", props.globals.getNode("/fms/fuel/zfw-kg"));
    tablerow("MZFW (Max Zero-Fuel Weight)", "%7.0f kg", massLimits.getNode("maximum-zero-fuel-mass-kg"));
    tablerow("Gross Weight", "%7.0f kg", props.globals.getNode(fdmdata.grosswgt));
    tablerow("MRW (Max Ramp Weight)",  "%7.0f kg", massLimits.getNode("maximum-ramp-mass-kg"));
    tablerow("MTOW (Max Takeoff Weight)", "%7.0f kg", massLimits.getNode("maximum-takeoff-mass-kg"));
    tablerow("MLW (Max Landing Weight)",  "%7.0f kg", massLimits.getNode("maximum-landing-mass-kg"));

    row = 0;
    col = 2;

    var cgLimits = props.globals.getNode("/weight-and-balance");
    if (cgLimits != nil) {
        tablerow("CG (%MAC)", "%3.1f%%", props.globals.getNode(fdmdata.percentMac));
        tablerow2("CG min/max T/O", "%3.1f%%", cgLimits.getNode('mac-percent-min-takeoff'), cgLimits.getNode('mac-percent-max-takeoff'));
        tablerow2("CG min/max LDG", "%3.1f%%", cgLimits.getNode('mac-percent-min-landing'), cgLimits.getNode('mac-percent-max-landing'));
        tablerow2("CG min/max clean", "%3.1f%%", cgLimits.getNode('mac-percent-min-clean'), cgLimits.getNode('mac-percent-max-clean'));
    }

    row = 1;

    foreach (var when; ['takeoff', 'landing', 'clean']) {
        (func (when) {
            var indicator = limits.addChild("text");
            indicator.set("row", row);
            indicator.set("col", 5);
            indicator.set("halign", "left");
            indicator.set("label", "???");
            indicator.set("property", cgLimits.getNode('mac-' ~ when ~ '-check-text').getPath());
            indicator.set("live", 1);
            append(dialog[name].listeners,
                setlistener(
                    cgLimits.getNode('mac-' ~ when ~ '-ok', 1),
                    func (node) {
                        var c = indicator.node.getNode('color', 1);
                        if (node.getBoolValue()) {
                            c.getNode('red', 1).setValue(0);
                            c.getNode('green', 1).setValue(1);
                            c.getNode('blue', 1).setValue(0);
                        }
                        else {
                            c.getNode('red', 1).setValue(1);
                            c.getNode('green', 1).setValue(0);
                            c.getNode('blue', 1).setValue(0);
                        }
                        dialog_apply(name);
                    }, 1, 0)
            );
        })(when);
        row += 1;
    }

    dialog[name].addChild("hrule");

    var buttonBar = dialog[name].addChild("group");
    buttonBar.set("layout", "hbox");
    buttonBar.set("default-padding", 10);

    var close = buttonBar.addChild("button");
    close.set("legend", "Close");
    close.set("default", "true");
    close.set("key", "Enter");
    close.setBinding("dialog-close");

    # Temporary helper function
    var tcell = func(parent, type, row, col) {
        var cell = parent.addChild(type);
        cell.set("row", row);
        cell.set("col", col);
        return cell;
    }

    #
    # Fill in the content area
    #
    var fuelArea = contentArea.addChild("group");
    fuelArea.set("layout", "vbox");
    fuelArea.addChild("text").set("label", "Fuel Tanks");

    var fuelTable = fuelArea.addChild("group");
    fuelTable.set("layout", "table");

    fuelArea.addChild("empty").set("stretch", 1);

    tcell(fuelTable, "text", 0, 0).set("label", "Tank");
    tcell(fuelTable, "text", 0, 3).set("label", "Kilograms");
    tcell(fuelTable, "text", 0, 4).set("label", "Pounds");
    tcell(fuelTable, "text", 0, 5).set("label", "Fraction");

    var tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
    for(var i=0; i<size(tanks); i+=1) {
        var t = tanks[i];
        var hidden=0;
        var tname = i ~ "";
        var hnode = t.getNode("hidden");
        if(hnode != nil) { hidden = hnode.getValue(); }# Check for <hidden> property ,skip adding tank if true#
        if(!hidden){
        var tnode = t.getNode("name");
        if(tnode != nil) { tname = tnode.getValue(); }

        var tankprop = "/consumables/fuel/tank["~i~"]";

        var cap = t.getNode("capacity-gal_us", 0);

        # Hack, to ignore the "ghost" tanks created by the C++ code.
        if(cap == nil ) { continue; }
        cap = cap.getValue();

        # Ignore tanks of capacity 0
        if (cap == 0) { continue; }

        var title = tcell(fuelTable, "text", i+1, 0);
        title.set("label", tname);
        title.set("halign", "right");

        var selected = props.globals.initNode(tankprop ~ "/selected", 1, "BOOL");
        if (selected.getAttribute("writable")) {
            var sel = tcell(fuelTable, "checkbox", i+1, 1);
            sel.set("property", tankprop ~ "/selected");
            sel.set("live", 1);
            sel.setBinding("dialog-apply");
        }

        var slider = tcell(fuelTable, "slider", i+1, 2);
        slider.set("property", tankprop ~ "/level-gal_us");
        slider.set("live", 1);
        slider.set("min", 0);
        slider.set("max", cap);
        slider.setBinding("dialog-apply");

        var kg = tcell(fuelTable, "text", i+1, 3);
        kg.set("property", tankprop ~ "/level-kg");
        kg.set("label", "0123456");
        kg.set("format", cap < 1 ? "%.3f" : cap < 10 ? "%.2f" : "%.1f" );
        kg.set("halign", "right");
        kg.set("live", 1);

        var lbs = tcell(fuelTable, "text", i+1, 4);
        lbs.set("property", tankprop ~ "/level-lbs");
        lbs.set("label", "0123456");
        lbs.set("format", cap < 1 ? "%.3f" : cap < 10 ? "%.2f" : "%.1f" );
        lbs.set("halign", "right");
        lbs.set("live", 1);

        var per = tcell(fuelTable, "text", i+1, 5);
        per.set("property", tankprop ~ "/level-norm");
        per.set("label", "0123456");
        per.set("format", "%.2f");
        per.set("halign", "right");
        per.set("live", 1);
        }
    }

    varbar = tcell(fuelTable, "hrule", size(tanks)+1, 0);
    varbar.set("colspan", 6);

    var total_label = tcell(fuelTable, "text", size(tanks)+2, 2);
    total_label.set("label", "Total:");
    total_label.set("halign", "right");

    var kg = tcell(fuelTable, "text", size(tanks)+2, 3);
    kg.set("property", "/consumables/fuel/total-fuel-kg");
    kg.set("label", "0123456");
    kg.set("format", "%.1f" );
    kg.set("halign", "right");
    kg.set("live", 1);

    var lbs = tcell(fuelTable, "text", size(tanks)+2, 4);
    lbs.set("property", "/consumables/fuel/total-fuel-lbs");
    lbs.set("label", "0123456");
    lbs.set("format", "%.1f" );
    lbs.set("halign", "right");
    lbs.set("live", 1);

    var per = tcell(fuelTable, "text", size(tanks)+2, 5);
    per.set("property", "/consumables/fuel/total-fuel-norm");
    per.set("label", "0123456");
    per.set("format", "%.2f");
    per.set("halign", "right");
    per.set("live", 1);

    var weightArea = contentArea.addChild("group");
    weightArea.set("layout", "vbox");
    weightArea.addChild("text").set("label", "Payload");

    var weightTable = weightArea.addChild("group");
    weightTable.set("layout", "table");

    weightArea.addChild("empty").set("stretch", 1);

    tcell(weightTable, "text", 0, 0).set("label", "Location");
    tcell(weightTable, "text", 0, 2).set("label", "#");
    tcell(weightTable, "text", 0, 3).set("label", "kg");

    var payload_base = props.globals.getNode(fdmdata.payload);
    if (payload_base != nil)
        var wgts = payload_base.getChildren("weight");
    else
        var wgts = [];
    for(var i=0; i<size(wgts); i+=1) {
        var w = wgts[i];
        var wname = w.getNode("name", 1).getValue() or "";
        var wprop = fdmdata.payload ~ "/weight[" ~ i ~ "]";

        var title = tcell(weightTable, "text", i+1, 0);
        title.set("label", wname);
        title.set("halign", "right");

        if (w.getNode('unit-lb') != nil) {
            var slider = tcell(weightTable, "slider", i+1, 1);
            slider.set("property", wprop ~ "/weight-lb");
            var min = w.getNode("min-lb", 1).getValue();
            var max = w.getNode("max-lb", 1).getValue();
            slider.set("min", min != nil ? min : 0);
            slider.set("max", max != nil ? max : 100);
            slider.set("live", 1);
            slider.setBinding("dialog-apply");

            var units = tcell(weightTable, "text", i+1, 2);
            units.set("property", wprop ~ "/unit-count");
            units.set("label", "0123456");
            units.set("format", "%7.0f");
            units.set("live", 1);
        }
        else {
            var slider = tcell(weightTable, "slider", i+1, 1);
            slider.set("property", wprop ~ "/weight-lb");
            var min = w.getNode("min-lb", 1).getValue();
            var max = w.getNode("max-lb", 1).getValue();
            slider.set("min", min != nil ? min : 0);
            slider.set("max", max != nil ? max : 100);
            slider.set("live", 1);
            slider.setBinding("dialog-apply");
        }

        var kg = tcell(weightTable, "text", i+1, 3);
        kg.set("property", wprop ~ "/weight-kg");
        kg.set("label", "0123456");
        kg.set("format", "%7.0f");
        kg.set("live", 1);
    }

    # All done: pop it up
    fgcommand("dialog-new", dialog[name].prop());
    showDialog(name);
}
