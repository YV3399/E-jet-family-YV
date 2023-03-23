include('apps/base.nas');

var PaperworkApp = {
    new: func(masterGroup) {
        var m = BaseApp.new(masterGroup);
        m.parents = [me] ~ m.parents;
        m.ofp = nil;
        m.pages = [];
        return m;
    },

    handleBack: func () {
    },

    initialize: func () {
        me.simbriefUsernameProp = props.globals.getNode('/sim/simbrief/username');
        me.bgfill = me.masterGroup.createChild('path')
                        .rect(0, 0, 512, 768)
                        .setColorFill(0.8, 0.9, 1.0);
        me.contentGroup = me.masterGroup.createChild('group');
        me.loadSimbriefOFP();
        me.renderOFP();
    },

    loadSimbriefOFP: func () {
        var filename = getprop('/sim/fg-home') ~ "/Export/simbrief.xml";
        me.ofp = io.readxml(filename);
        if (me.ofp == nil) {
            me.ofp = props.Node.new();
        }
        me.renderOFP();
    },

    collectOFPItems: func () {
        var items = [];
        var plain = func (text) { append(items, { type: 'text', text: text }); };
        var pageBreak = func () { append(items, { type: 'page-break' }); };
        var separator = func () { append(items, { type: 'separator' }); };
        var format = func (fmt, args) {
            append(items, { type: 'formatted', format: fmt, args: args });
        };
        separator();
        for (var i = 1; i < 60; i += 1) {
            plain('--- TEST LINE ' ~ i ~ ' ---');
        }
        pageBreak();
        plain('[ OFP ]');
        separator();
        # format('%-3s%-%6s %02i%3s%04i    %-4s-%-4s   %-4s %-7s RELEASE %-4s %02i%3s%02i',
        format('%-3s%-6s 22MAR2023 %-4s-%-4s   %-4s %-7s RELEASE 1613 22MAR23',
            [ 'OFP/general/icao_airline'
            , 'OFP/general/flight_number'
            # day, month, year
            , 'OFP/origin/icao_code'
            , 'OFP/destination/icao_code'
            , 'OFP/aircraft/icaocode'
            , 'OFP/aircraft/reg'
            # release time
            # day, month, year
            ]);
        var pages = [];
        var page = [];
        var pushPage = func {
            append(pages, page);
            page = [];
        };
        foreach (var item; items) {
            if (item.type == 'page-break' or size(page) >= 60) {
                pushPage();
            }
            append(page, item);
        }
        if (size(page) > 0) {
            pushPage();
        }
        return pages;
    },

    renderItem: func (pageGroup, y, item) {
        var renderText = func (text) {
            pageGroup
                .createChild('text')
                .setText(text)
                .setFontSize(10, 1)
                .setFont(font_mapper('mono', 100))
                .setColor(0, 0, 0)
                .setTranslation(0, y);
        };
        if (item.type == 'text') {
            renderText(item.text);
        }
        elsif (item.type == 'separator') {
            renderText('--------------------------------------------------------------------');
        }
        elsif (item.type == 'formatted') {
            var args = [];
            foreach (var argSpec; item.args) {
                var node = me.ofp.getNode(argSpec);
                if (node == nil)
                    append(args, argSpec);
                else
                    append(args, me.ofp.getNode(argSpec).getValue() or '');
            }
            debug.dump(item.format);
            renderText(call(sprintf, [item.format] ~ args));
        }
    },

    renderPage: func(pageGroup, pageData) {
        var y = 20;
        foreach (var item; pageData) {
            me.renderItem(pageGroup, y, item);
            y += 11;
        }
    },

    renderOFP: func () {
        var self = me;
        me.contentGroup.removeAllChildren();
        me.contentGroup.createChild('path')
                       .rect(90, 40, 414, 690)
                       .setColor(0.2, 0.2, 0.2)
                       .setColorFill(1.0, 1.0, 1.0);
        me.pages = [];
        var pagesData = me.collectOFPItems();
        foreach (var pageData; pagesData) {
            var pageGroup = me.contentGroup
                                .createChild('group')
                                .setTranslation(94, 52);
            me.renderPage(pageGroup, pageData);
            pageGroup.hide();
            append(me.pages, pageGroup);
        }
        if (me.currentPage >= size(me.pages)) {
            me.currentPage = 0;
        }
        if (size(me.pages) > 0) {
            me.pages[me.currentPage].show();
            me.makePager(size(me.pages), func() {
                foreach (var p; self.pages) {
                    p.hide();
                }
                if (self.currentPage < size(self.pages)) {
                    self.pages[self.currentPage].show();
                }
            }, me.contentGroup);
        }
    },
};

registerApp('paperwork', 'Paperwork', 'paperwork.png', PaperworkApp);

