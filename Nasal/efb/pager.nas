include('widget.nas');
include('util.nas');

var Pager = {
    new: func (parentGroup) {
        var m = Widget.new();
        m.parents = [me] ~ m.parents;
        m.numPages = nil;
        m.currentPage = 0;
        m.onPageChanged = nil;
        m.initialize(parentGroup);
        return m;
    },

    initialize: func (parentGroup) {
        me.group = parentGroup.createChild('group');
        canvas.parsesvg(me.group, acdir ~ "/Models/EFB/pager-overlay.svg", {'font-mapper': font_mapper});
        me.btnPgUp = me.group.getElementById('btnPgUp');
        me.btnPgDn = me.group.getElementById('btnPgDn');
        me.currentPageIndicator = me.group.getElementById('pager.digital');

        var self = me;
        me.appendChild(
            Widget.new(me.btnPgUp)
                  .setHandler(func () {
                      self.prevPage();
                  }));
        me.appendChild(
            Widget.new(me.btnPgDn)
                  .setHandler(func () {
                      self.nextPage();
                  }));
    },

    updatePageIndicator: func () {
        me.currentPageIndicator
          .setText(
              (me.numPages == nil)
                  ? sprintf("%i", me.currentPage + 1)
                  : sprintf("%i/%i", me.currentPage + 1, me.numPages)
           );
    },

    unregisterOnPage: func {
        me.onPageChanged = nil;
    },

    registerOnPage: func (handler) {
        me.onPageChanged = handler;
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
        me.updatePageIndicator();
        if (me.onPageChanged != nil) {
            me.onPageChanged(me.currentPage, oldPage, me.numPages);
        }
    },

    nextPage: func () {
        me.setCurrentPage(me.currentPage + 1);
    },

    prevPage: func () {
        me.setCurrentPage(me.currentPage - 1);
    },
};
