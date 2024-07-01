include('gui/widget.nas');
include('util.nas');
include('eventSource.nas');

var ZoomScroll = {
    new: func (parentGroup, followRotation=0) {
        var m = Widget.new();
        m.parents = [me] ~ m.parents;
        m.onScroll = EventSource.new();
        m.onZoom = EventSource.new();
        m.onReset = EventSource.new();
        m.zoom = 1;
        m.autoCenter = 0;
        m.fmtZoom = func(zoom) { sprintf('%i', zoom * 100); };
        m.fmtUnit = func(zoom) { return '%'; };
        m.followRotation = followRotation;
        m.rotation = 0;

        m.initialize(parentGroup);
        return m;
    },

    setZoomFormat: func (fmtZoom, fmtUnit) {
        me.fmtZoom = fmtZoom;
        me.fmtUnit = fmtUnit;
        me.updateZoomPercent();
    },

    setZoom: func (zoom) {
        me.zoom = zoom;
        me.updateZoomPercent();
        return me;
    },

    setAutoCenter: func (enabled) {
        me.autoCenter = enabled;
        me.autoCenterMarker.setVisible(enabled);
        return me;
    },

    updateZoomPercent: func {
        me.zoomDigital.setText(me.fmtZoom(me.zoom));
        me.zoomUnit.setText(me.fmtUnit(me.zoom));
    },

    handleRotate: func (rotationNorm, hard=0) {
        me.rotation = rotationNorm;
        me.updateRotation();
    },

    updateRotation: func () {
        var portraitX = 8;
        var landscapeX = 8;
        var portraitY = 40;
        var landscapeY = 768 - 32 - 94;
        var phi = me.rotation * math.pi * 0.5;

        if (me.followRotation) {
            me.group.setTranslation(
                        portraitX + (landscapeX - portraitX) * math.sin(phi),
                        portraitY + (landscapeY - portraitY) * (1 - math.cos(phi)))
                    .setRotation(-phi);
        }
        else {
            me.group.setTranslation(portraitX, portraitY)
                    .setRotation(0);
        }
    },



    initialize: func (parentGroup) {
        me.group = parentGroup.createChild('group');
        canvas.parsesvg(me.group, acdirRel ~ "/Models/EFB/zoom-scroll-overlay.svg", {'font-mapper': font_mapper});
        me.group.setCenter(47, 36);

        me.updateRotation();

        me.autoCenterMarker = me.group.getElementById('autoCenterMarker');
        me.autoCenterMarker.hide();

        me.zoomDigital = me.group.getElementById('zoomPercent.digital');
        me.zoomUnit = me.group.getElementById('zoomPercent.unit');

        me.btnZoomIn = me.group.getElementById('btnZoomIn');
        me.btnZoomOut = me.group.getElementById('btnZoomOut');
        me.btnScrollN = me.group.getElementById('btnScrollN');
        me.btnScrollS = me.group.getElementById('btnScrollS');
        me.btnScrollE = me.group.getElementById('btnScrollE');
        me.btnScrollW = me.group.getElementById('btnScrollW');
        me.btnScrollReset = me.group.getElementById('btnScrollReset');

        var self = me;
        me.appendChild(
            Widget.new(me.btnZoomIn)
                .setClickHandler(func () {
                    self.onZoom.raise({amount: 1});
                    return 0;
                }));
        me.appendChild(
            Widget.new(me.btnZoomOut)
                .setClickHandler(func () {
                    self.onZoom.raise({amount: -1});
                    return 0;
                }));
        me.appendChild(
            Widget.new(me.btnScrollN)
                .setClickHandler(func () {
                    self.onScroll.raise({x: 0, y: -1});
                    return 0;
                }));
        me.appendChild(
            Widget.new(me.btnScrollS)
                .setClickHandler(func () {
                    self.onScroll.raise({x: 0, y: 1});
                    return 0;
                }));
        me.appendChild(
            Widget.new(me.btnScrollE)
                .setClickHandler(func () {
                    self.onScroll.raise({x: 1, y: 0});
                    return 0;
                }));
        me.appendChild(
            Widget.new(me.btnScrollW)
                .setClickHandler(func () {
                    self.onScroll.raise({x: -1, y: 0});
                    return 0;
                }));
        me.appendChild(
            Widget.new(me.btnScrollReset)
                .setClickHandler(func () {
                    self.onReset.raise({});
                    return 0;
                }));

    },
};

