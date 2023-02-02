setlistener('/sim/current-view/view-number-raw', func (node) {
    var viewNumber = node.getValue();
    if (viewNumber == nil) return;

    var view = props.globals.getNode('/sim/view[' ~ viewNumber ~ ']');
    if (view == nil) return;

    var walkable = view.getValue('config/walkable') or 0;
    setprop('/sim/current-view/config/walkable', walkable);
});
