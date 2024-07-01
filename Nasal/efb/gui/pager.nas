include('gui/widget.nas');
include('util.nas');
include('eventSource.nas');

var Pager = {
    new: func (parentGroup, followRotation=0) {
        var m = Widget.new();
        m.parents = [me] ~ m.parents;
        m.numPages = nil;
        m.currentPage = 0;
        m.pageChanged = EventSource.new();
        m.followRotation = followRotation;
        m.rotation = 0;

        m.initialize(parentGroup);
        return m;
    },

    initialize: func (parentGroup) {
        me.group = parentGroup.createChild('group');
        canvas.parsesvg(me.group, acdirRel ~ "/Models/EFB/pager-overlay.svg", {'font-mapper': font_mapper});
        me.group.setCenter(54, 12);
        me.btnPgUp = me.group.getElementById('btnPgUp');
        me.btnPgDn = me.group.getElementById('btnPgDn');
        me.currentPageIndicator = me.group.getElementById('pager.digital');
        me.updateRotation();

        var self = me;
        me.appendChild(
            Widget.new(me.btnPgUp)
                  .setClickHandler(func () {
                      self.prevPage();
                  }));
        me.appendChild(
            Widget.new(me.btnPgDn)
                  .setClickHandler(func () {
                      self.nextPage();
                  }));
    },

    handleRotate: func (rotationNorm, hard=0) {
        me.rotation = rotationNorm;
        me.updateRotation();
    },

    updateRotation: func () {
        var portraitX = 256 - 54;
        var landscapeX = 512 - 76;
        var portraitY = 768 - 64;
        var landscapeY = 384 - 12;
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

    updatePageIndicator: func () {
        me.currentPageIndicator
          .setText(
              (me.numPages == nil)
                  ? sprintf("%i", me.currentPage + 1)
                  : sprintf("%i/%i", me.currentPage + 1, me.numPages)
           );
    },

    setNumPages: func (numPages) {
        me.numPages = numPages;
        me.updatePageIndicator();
    },

    setCurrentPage: func (page) {
        var oldPage = me.currentPage;
        me.currentPage = page;
        if (me.numPages != nil) {
            me.currentPage = math.min(me.numPages - 1, me.currentPage);
        }
        me.currentPage = math.max(0, me.currentPage);
        if (oldPage != me.currentPage) {
            me.updatePageIndicator();
            me.pageChanged.raise({page: me.currentPage, previousPage: oldPage, numPages: me.numPages});
        }
    },

    nextPage: func () {
        me.setCurrentPage(me.currentPage + 1);
    },

    prevPage: func () {
        me.setCurrentPage(me.currentPage - 1);
    },
};
