include('apps/base.nas');
include('/html/main.nas');

var H = html.H;

var HTMLTestApp = {
    new: func(masterGroup) {
        var m = BaseApp.new(masterGroup);
        m.parents = [me] ~ m.parents;
        return m;
    },

    handleBack: func () {
    },

    initialize: func () {
        var self = me;
        me.masterGroup.createChild('path')
                .rect(0, 0, 512, 768)
                .setColorFill(0.8, 0.8, 0.8);
        me.contentGroup = me.masterGroup.createChild('group');
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
                )
            );
        var stylesheet = html.CSS.loadStylesheet(me.assetDir ~ 'style.css');
        stylesheet.apply(me.document);
        html.showDOM(me.document, me.contentGroup, font_mapper, 0, 32, 512, 704);
    },

};

registerApp('htmltest', 'HTML Test', 'htmltest.png', HTMLTestApp);


