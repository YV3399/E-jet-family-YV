include('baseApp.nas');
include('eventSource.nas');
include('gui/checkbox.nas');
include('gui/button.nas');

var GroundServicesApp = {
    new: func (masterGroup) {
        var m = BaseApp.new(masterGroup);
        m.parents = [me] ~ m.parents;
        m.listeners = [];
        m.initialize();
        return m;
    },


    initialize: func {
        var self = me;

        me.masterGroup.createChild('image')
                      .set('src', acdir ~ '/Splash/E175/732.jpg')
                      .setTranslation((512 - 1920) * 0.4, (768 - 1080) * 0.5);
        me.masterGroup.createChild('path')
                      .rect(16, 48, 512 - 32, 768 - 96, {'border-radius': 6})
                      .setColorFill(1, 1, 1, 0.6);
        me.logoImage = me.masterGroup.createChild('image')
                         .setTranslation(32, 40)
                         .set('src', acdir ~ '/Nasal/efbapps/services/ground-services-icon.png');
        var y = 64;
        var x = 32;

        var headingText = me.masterGroup.createChild('text')
                           .setFont(font_mapper('sans', 'bold'))
                           .setFontSize(32)
                           .setColor(0, 0, 0)
                           .setAlignment('center-top')
                           .setTranslation(256, y)
                           .setText('Ground Operations');
        y += 48;

        var mkHeading = func (label) {
          me.masterGroup.createChild('text')
            .setFont(font_mapper('sans', 'bold'))
            .setFontSize(24)
            .setColor(0, 0, 0)
            .setAlignment('center-top')
            .setTranslation(256, y + 4)
            .setText(label);
            y += 40;
            x = 32;
        };

        var buttonPadding = 8;
        var buttonWidth = math.floor(512 - 64 - 2 * buttonPadding) / 3;

        var mkStatic = func (label) {
            me.masterGroup.createChild('text')
                          .setFont(font_mapper('sans', 'normal'))
                          .setFontSize(20)
                          .setColor(0, 0, 0)
                          .setAlignment('left-baseline')
                          .setText(label)
                          .setTranslation(x, y + 24);
            x += buttonWidth;
            if (x >= 512 - 32) {
                y += 40;
                x = 32;
            }
            else {
                x += buttonPadding;
            }
        };

        var mkButton = func (action, label) {
            var button = Button.new(me.masterGroup, label, x, y, buttonWidth, 32);
            button.setClickHandler(action);
            me.rootWidget.appendChild(button);

            x += buttonWidth;
            if (x >= 512 - 39) {
                y += 40;
                x = 32;
            }
            else {
                x += buttonPadding;
            }
        };

        var mkSlider = func (controlProp, progressProp, label, progressLabels) {
            if (typeof(controlProp) == 'scalar')
                controlProp = props.globals.getNode(controlProp, 1);
            if (typeof(progressProp) == 'scalar')
                progressProp = props.globals.getNode(progressProp, 1);

            var labelText = me.masterGroup.createChild('text')
                               .setFont(font_mapper('sans', 'normal'))
                               .setFontSize(20)
                               .setColor(0, 0, 0)
                               .setAlignment('left-baseline')
                               .setTranslation(32, y + 19)
                               .setText(label);

            var slider = Checkbox.new(me.masterGroup, 216, y)
                                 .setAlignment('left-top');
            slider.setState(controlProp.getBoolValue());
            slider.stateChanged.addListener(func (ev) {
                controlProp.setBoolValue(ev.state);
            });

            var statusBackground = me.masterGroup.createChild('path');

            var statusText = me.masterGroup.createChild('text')
                               .setFont(font_mapper('sans', 'normal'))
                               .setFontSize(20)
                               .setColor(0, 0, 0)
                               .setAlignment('left-baseline')
                               .setTranslation(272, y + 19)
                               .setText(progressLabels[1]);
            var box = statusText.getBoundingBox();
            statusBackground.rect(264, y - 2, box[2] - box[0] + 16, 32, {'border-radius': 4})
                            .setColorFill(1, 1, 0, 0.8);
            
            var status = -1;
            var updateStatus = func {
                statusText.setText(progressLabels[status]);
                if (status == 0)
                    statusText.setColor(0.5, 0.5, 0.5);
                else
                    statusText.setColor(0, 0, 0);
                statusBackground.setVisible(status == 1);
            };
            var checkStatus = func {
                var value = progressProp.getValue() or 0;
                var newStatus = 0;
                if (value >= 1.0)
                    newStatus = 2;
                elsif (value <= 0.0)
                    newStatus = 0;
                else
                    newStatus = 1;
                if (newStatus != status) {
                    status = newStatus;
                    updateStatus();
                }
            };
            checkStatus();
            append(self.listeners,
                setlistener(progressProp, func (node) {
                    checkStatus();
                }, 0, 1));

            me.rootWidget.appendChild(slider);
            y += 48;
        };

        mkHeading('Securing');
        mkSlider('/controls/switches/chocks', '/services/chocks', 'Chocks', ['removed', 'in progress...', 'placed']);
        mkSlider('/controls/switches/cones', '/controls/switches/cones', 'Cones', ['removed', 'in progress...', 'placed']);
        mkHeading('Power');
        mkSlider('/controls/switches/fuel-truck', '/services/fuel-truck/position', 'Fuel Truck', ['off', 'enroute...', 'connected']);
        mkSlider('/controls/electric/external-power-connected', '/controls/electric/external-power-connected', 'Ground power unit', ['disconnected', 'in progress...', 'connected']);
        mkHeading('Pushback');
        mkSlider('/sim/model/autopush/enabled', '/sim/model/autopush/enabled', 'Connect', ['disconnected', 'in progress', 'connected']);

        mkButton(func { autopush_driver.start(); }, 'Start');
        mkButton(func { autopush_driver.stop(); }, 'Pause');
        mkButton(func { autopush_route.top_view(); }, 'View');

        mkStatic('Route:');
        mkButton(func { autopush_route.enter(); }, 'Enter');
        mkButton(func { autopush_route.done(); }, 'Done');

        mkStatic('Last Point:');
        mkButton(func { autopush_route.toggle_sharp(); }, 'Sharp');
        mkButton(func { autopush_route.delete_last(); }, 'Delete');
    },

};

registerApp('services', 'Ground Ops', 'ground-services-icon.png', GroundServicesApp);
