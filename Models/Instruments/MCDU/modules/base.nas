var BaseModule = {
    new: func (mcdu, parentModule) {
        var m = { parents: [BaseModule] };
        m.page = 0;
        m.parentModule = parentModule;
        var maxw = math.round(cells_x / 2) - 1;
        m.ptitle = nil;
        if (parentModule != nil) {
            if (parentModule.getNumPages() > 1) {
                m.ptitle = sprintf("%s %d/%d",
                    parentModule.getShortTitle(),
                    parentModule.page + 1,
                    parentModule.getNumPages());
            }
            else {
                m.ptitle = parentModule.getShortTitle();
            }
        }
        if (m.ptitle != nil and size(m.ptitle) > maxw) {
            m.ptitle = parentModule.getShortTitle();
        }
        if (m.ptitle != nil and size(m.ptitle) > maxw) {
            m.ptitle = substr(m.ptitle, 0, maxw);
        }
        m.mcdu = mcdu;

        m.views = [];
        m.controllers = {};
        m.dividers = [];
        m.boxedController = nil;
        m.boxedView = nil;

        return m;
    },

    getNumPages: func () {
        return 1;
    },

    getTitle: func() { return "MODULE"; },

    getShortTitle: func { return me.getTitle(); },

    loadPage: func (n) {
        me.unloadPage();
        me.loadPageItems(n);
        foreach (var view; me.views) {
            view.activate(me.mcdu);
        }
    },

    unloadPage: func () {
        me.boxedView = nil;
        me.boxedController = nil;
        foreach (var view; me.views) {
            view.deactivate();
        }
        me.views = [];
        me.controllers = {};
    },

    loadPageItems: func (n) {
        # Override to load the views and controllers and dividers for the current page
    },

    findView: func (key) {
        if (key == nil) {
            return nil;
        }
        foreach (var view; me.views) {
            if (view.getKey() == key) {
                return view;
            }
        }
        return nil;
    },

    findController: func (key) {
        if (key == nil) {
            return nil;
        }
        foreach (var i; keys(me.controllers)) {
            var controller = me.controllers[i];
            if (controller != nil and controller.getKey() == key) {
                return controller;
            }
        }
        return nil;
    },

    drawFocusBox: func () {
        if (me.boxedView == nil) {
            me.mcdu.clearFocusBox();
        }
        else {
            me.mcdu.setFocusBox(
                me.boxedView.getL(),
                me.boxedView.getT(),
                me.boxedView.getW());
        }
    },

    drawPager: func () {
        me.mcdu.print(21, 0, sprintf("%1d/%1d", me.page + 1, me.getNumPages()), 0);
    },

    drawTitle: func () {
        var title = me.getTitle();
        var x = math.floor((cells_x - 3 - size(title)) / 2);
        me.mcdu.print(x, 0, title, mcdu_large | mcdu_white);
    },

    redraw: func () {
        foreach (var view; me.views) {
            view.drawAuto(me.mcdu);
        }
        var dividers = me.dividers;
        if (dividers == nil) { dividers = [] };
        for (var d = 0; d < 7; d += 1) {
            if (vecfind(d, dividers) == -1) {
                me.mcdu.hideDivider(d);
            }
            else {
                me.mcdu.showDivider(d);
            }
        }
        me.drawFocusBox();
    },


    fullRedraw: func () {
        me.mcdu.clear();
        me.drawTitle();
        me.drawPager();
        me.redraw();
    },

    gotoPage: func (p) {
        me.unloadPage();
        me.page = math.min(me.getNumPages() - 1, math.max(0, p));
        me.loadPage(me.page);
        me.fullRedraw();
    },

    nextPage: func () {
        if (me.page < me.getNumPages() - 1) {
            me.unloadPage();
            me.page += 1;
            me.loadPage(me.page);
            me.fullRedraw();
        }
    },

    prevPage: func () {
        if (me.page > 0) {
            me.unloadPage();
            me.page -= 1;
            me.loadPage(me.page);
            me.selectedKey = nil;
            me.fullRedraw();
        }
    },

    push: func (target) {
        me.mcdu.pushModule(target);
    },

    goto: func (target) {
        me.mcdu.gotoModule(target);
    },

    sidestep: func (target) {
        me.mcdu.sidestepModule(target);
    },

    ret: func () {
        me.mcdu.popModule();
    },

    activate: func () {
        me.loadPage(me.page);
    },

    deactivate: func () {
        me.unloadPage();
    },

    box: func (key) {
        me.boxedController = me.findController(key);
        me.boxedView = me.findView(key);
        me.drawFocusBox();
    },

    handleCommand: func (cmd) {
        var controller = me.controllers[cmd];
        if (isLSK(cmd)) {
            var scratch = me.mcdu.popScratchpad();
            if (controller == nil) {
                me.mcdu.setScratchpad(scratch);
            }
            else {
                var boxed = (me.boxedController != nil and
                             me.boxedController.getKey() == controller.getKey());
                if (scratch == '') {
                    controller.select(me, boxed);
                }
                else if (scratch == '*DELETE*') {
                    controller.delete(me, boxed);
                }
                else {
                    controller.send(me, scratch);
                }
            }
        }
        else if (isDial(cmd)) {
            var digit = dialIndex(cmd);
            if (me.boxedController != nil) {
                me.boxedController.dial(me, digit);
            }
        }
    },

};


