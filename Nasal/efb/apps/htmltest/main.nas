include('baseApp.nas');
include('/html/main.nas');
include('gui/checkbox.nas');

var H = html.H;

var HTMLTestApp = {
    new: func(masterGroup) {
        var m = BaseApp.new(masterGroup);
        m.parents = [me] ~ m.parents;
        m.renderOptions = {
            dpi: 96,
            debugLayout: 0,
            applyStylesheet: 1,
        };
        m.renderInfo = nil;
        m.scroll = { x: 0, y : 0 };
        m.maxScroll = { x: 0, y : 0 };
        return m;
    },

    handleBack: func () {
    },

    clipTemplate: string.compileTemplate('rect({top}px, {right}px, {bottom}px, {left}px)'),

    renderDoc: func () {
        me.htmlGroup.removeAllChildren();
        var renderContext =
                html.mergeDicts(
                    html.makeDefaultRenderContext(me.htmlGroup, font_mapper,
                        me.contentBox.left, me.contentBox.top,
                        me.contentBox.width, me.contentBox.height),
                    me.renderOptions);
        me.renderInfo = html.showDOM(me.document, renderContext);
        me.maxScroll.x = math.max(0, me.renderInfo.docPaddingBox.width() - me.contentBox.width);
        me.scroll.x = math.min(me.maxScroll.x, math.max(0, me.scroll.x));
        me.maxScroll.y = math.max(0, me.renderInfo.docPaddingBox.height() - me.contentBox.height);
        me.scroll.y = math.min(me.maxScroll.y, math.max(0, me.scroll.y));
        me.updateScroll();
    },

    updateScroll: func {
        me.htmlGroup.setTranslation(-me.scroll.x, -me.scroll.y);
    },

    wheel: func (axis, amount) {
        if (axis == 0) {
            me.scroll.y += amount * 20;
            me.scroll.y = math.min(me.maxScroll.y, math.max(0, me.scroll.y));
            me.updateScroll();
        }
    },

    initialize: func () {
        var self = me;
        me.masterGroup.createChild('path')
                .rect(0, 0, 512, 768)
                .setColorFill(0.8, 0.8, 0.8);
        me.contentBox = { left: 5, top: 37, width: 502, height: 600 };
        me.contentBox.right = me.contentBox.left + me.contentBox.width;
        me.contentBox.bottom = me.contentBox.top + me.contentBox.height;
        me.contentGroup = me.masterGroup.createChild('group');

        me.contentGroup.createChild('path')
                .rect(
                    me.contentBox.left, me.contentBox.top,
                    me.contentBox.width, me.contentBox.height)
                .setColorFill(1,1,1,1);

        me.htmlGroup = me.contentGroup.createChild('group');
        me.htmlGroup.set('clip', me.clipTemplate(me.contentBox));
        me.htmlGroup.set('clip-frame', canvas.Element.PARENT);

        me.contentGroup.createChild('path')
                .rect(
                    me.contentBox.left, me.contentBox.top,
                    me.contentBox.width, me.contentBox.height)
                .setColor(0,0,0,1);

        me.uiGroup = me.masterGroup.createChild('group')
                                   .setTranslation(me.contentBox.left, me.contentBox.bottom + 5);

        var btn = func (x, y, label, what) {
            var box = me.uiGroup.createChild('path')
                                .rect(x, y, 30, 30)
                                .setColorFill(1, 1, 1)
                                .setColor(0, 0, 0);
            me.makeClickable(box, what);
            me.uiGroup.createChild('text')
                      .setAlignment('center-center')
                      .setFont(font_mapper('sans', 'normal'))
                      .setFontSize(20)
                      .setColor(0, 0, 0)
                      .setTranslation(x + 15, y + 15)
                      .setText(label);
        };

        var checkbox = func (x, y, what) {
            var cb = 
                Checkbox.new(me.uiGroup, x + 15, y + 15)
                        .setAlignment('center-center')
                        .setClickHandler(what);
            me.rootWidget.appendChild(cb);
            return func(isset) {
                cb.setState(isset);
            };
        };

        var static = func (x, y, label) {
            return me.uiGroup.createChild('text')
                             .setAlignment('center-center')
                             .setFont(font_mapper('sans', 'normal'))
                             .setFontSize(16)
                             .setColor(0.2, 0.2, 0.2)
                             .setTranslation(x + 15, y + 15)
                             .setText(label);
        };

        var self = me;

        static(40, 0, 'DPI');
        me.txtCurrentDPI = static(40, 30, me.renderOptions.dpi);
        btn(0, 30, '-', func {
            self.renderOptions.dpi -= 8;
            self.txtCurrentDPI.setText(self.renderOptions.dpi);
            self.renderDoc();
        });
        btn(80, 30, '+', func {
            self.renderOptions.dpi += 8;
            self.txtCurrentDPI.setText(self.renderOptions.dpi);
            self.renderDoc();
        });

        static(140, 0, 'debug');
        var updateCBDebug = checkbox(140, 30, func {
            self.renderOptions.debugLayout = !self.renderOptions.debugLayout;
            updateCBDebug(self.renderOptions.debugLayout);
            self.renderDoc();
        });
        updateCBDebug(self.renderOptions.debugLayout);

        static(220, 0, 'stylesheet');
        var updateCBStylesheet = checkbox(220, 30, func {
            self.renderOptions.applyStylesheet = !self.renderOptions.applyStylesheet;
            updateCBStylesheet(self.renderOptions.applyStylesheet);
            self.setupDoc();
            self.renderDoc();
        });
        updateCBStylesheet(self.renderOptions.applyStylesheet);

        me.stylesheet = html.CSS.loadStylesheet(me.assetDir ~ 'style.css');
        me.setupDoc();
        me.renderDoc();
    },

    setupDoc: func {
        me.document =
            H.html(
                H.body(
                    H.h1("HTML Test Page"),
                    H.h2("Some Lorem Ipsum"),
                    H.p(
                        H.b(H.a('Lorem ipsum'), 'dolor sit amet'),
                        'consectetur adipiscing',
                        'elit, sed do eiusmod tempor incididunt ut labore et',
                        'dolore magna aliqua. Ut enim ad minim veniam, quis',
                        'nostrud exercitation ullamco laboris nisi ut aliquip ex',
                        'ea commodo consequat.  Duis aute irure dolor in',
                        'reprehenderit in voluptate velit esse cillum dolore eu',
                        'fugiat nulla pariatur. Excepteur sint occaecat',
                        'cupidatat non proident, sunt in culpa qui officia',
                        'deserunt mollit anim id est laborum.'
                        ),
                    H.blockquote(
                        H.b(H.a('Lorem ipsum'), 'dolor sit amet'),
                        'consectetur adipiscing',
                        'elit, sed do eiusmod tempor incididunt ut labore et',
                        'dolore magna aliqua. Ut enim ad minim veniam, quis',
                        'nostrud exercitation ullamco laboris nisi ut aliquip ex',
                        'ea commodo consequat.  Duis aute irure dolor in',
                        'reprehenderit in voluptate velit esse cillum dolore eu',
                        'fugiat nulla pariatur. Excepteur sint occaecat',
                        'cupidatat non proident, sunt in culpa qui officia',
                        'deserunt mollit anim id est laborum.'
                        ),
                )
            );
        if (me.renderOptions['applyStylesheet'])
            me.stylesheet.apply(me.document);
    },

};

if (getprop('/instrumentation/efb/show-debug-apps'))
    registerApp('htmltest', 'HTML Test', 'htmltest.png', HTMLTestApp);
