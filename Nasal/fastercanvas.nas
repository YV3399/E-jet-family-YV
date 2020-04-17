# This improves canvas performance by caching text and visibility of canvas
# elements, and only updating the element when those don't match.

canvas.Text._lastText = canvas.Text["_lastText"];
canvas.Text.setText = func(text) {
    if (text == me._lastText and text != nil and size(text) == size(me._lastText)) {return me;}
    me._lastText = text;
    me.set("text", typeof(text) == 'scalar' ? text : "");
};

canvas.Element._lastVisible = nil;
canvas.Element.show = func {
    if (1 == me._lastVisible) {return me;}
    me._lastVisible = 1;
    me.setBool("visible", 1);
};
canvas.Element.hide = func {
    if (0 == me._lastVisible) {return me;}
    me._lastVisible = 0;
    me.setBool("visible", 0);
};
canvas.Element.setVisible = func(vis) {
    if (vis == me._lastVisible) {return me;}
    me._lastVisible = vis;
    me.setBool("visible", vis);
};
