setlistener('/sim/current-view/view-number-raw', func (node) {
    var view = props.globals.getNode('/sim/view[' ~ node.getValue() ~ ']');
    if (view == nil) return;
    var walkable = view.getValue('config/walkable') or 0;
    setprop('/sim/current-view/config/walkable', walkable);
});
