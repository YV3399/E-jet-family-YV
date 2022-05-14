var System = {
    new: func () {
        var m = {
            parents: [System],
            props: {
                base: nil,
                telexReceived: nil,
                telexSent: nil,
                unread: nil,
                newestUnread: nil,
                statusText: nil,
                uplink: nil,
                downlink: nil,
                uplinkStatus: nil,
                downlinkStatus: nil,
                weatherBackend: nil,
                atisBackend: nil,
                progressBackend: nil,
                availability: nil,
                adscPeriodics: nil,
                adscTimer: nil,
                lat: nil,
                lon: nil,
                alt: nil,
            },
            listeners: {
                uplink: nil,
                downlink: nil,
            },
            nextSerial: 1,
        };
        m.availabilityPingTimer = maketimer(1, m, m.updateAvailabilities);
        m.adscTimer = maketimer(10, m, m.updateADSC);
        return m;
    },

    attach: func (propBase=nil) {
        if (propBase == nil) {
            propBase = 'acars';
        }
        if (typeof(propBase) == 'scalar') {
            me.props.base = props.globals.getNode(propBase, 1);
        }
        elsif (typeof(propBase) == 'ghost') {
            # Assume it's a property node already
            me.props.base = propBase;
        }
        me.props.telexSent = me.props.base.getNode('telex/sent', 1);
        me.props.telexReceived = me.props.base.getNode('telex/received', 1);
        me.props.unread = me.props.base.getNode('telex/unread', 1);
        me.props.newestUnread = me.props.base.getNode('telex/newest-unread', 1);
        me.props.newestUnread.setValue(0);
        me.props.statusText = props.globals.getNode('/hoppie/status-text');
        me.props.uplink = props.globals.getNode('/hoppie/uplink', 1);
        me.props.downlink = props.globals.getNode('/hoppie/downlink', 1);
        me.props.uplinkStatus = props.globals.getNode('/hoppie/uplink/status', 1);
        me.props.downlinkStatus = props.globals.getNode('/hoppie/downlink/status', 1);
        me.props.weatherBackend = me.props.base.getNode('config/weather-backend', 1);
        me.props.atisBackend = me.props.base.getNode('config/atis-backend', 1);
        me.props.progressBackend = me.props.base.getNode('config/progress-backend', 1);
        me.props.availability = me.props.base.getNode('availability', 1);
        me.props.callsign = props.globals.getNode('/sim/multiplay/callsign');
        me.props.dispatchCallsign = me.props.base.getNode('dispatch-callsign', 1);
        me.props.dispatchCallsignConfig = me.props.base.getNode('config/dispatch-callsign', 1);
        me.props.adscPeriodics = me.props.base.getNode('ads-c/periodics', 1);
        me.props.adscTimer = me.props.base.getNode('ads-c/timer', 1);
        me.props.lat = props.globals.getNode('/position/latitude-deg', 1);
        me.props.lon = props.globals.getNode('/position/longitude-deg', 1);
        me.props.alt = props.globals.getNode('/instrumentation/altimeter/indicated-altitude-ft', 1);
        me.updateUnread();
        var self = me;
        me.listeners.uplink = setlistener(me.props.uplinkStatus, func (node) {
            self.receive();
        });
        me.listeners.downlink = setlistener(me.props.downlinkStatus, func (node) {
            self.handleSent(node);
        });
        me.listeners.callsign = setlistener(me.props.callsign, func (node) {
            if ((self.props.dispatchCallsignConfig.getValue() or '') == '') {
                self.props.dispatchCallsign.setValue(substr(node.getValue(), 0, 3));
            }
        }, 1, 0);
        me.listeners.dispatchCallsignConfig = setlistener(me.props.dispatchCallsignConfig, func (node) {
            var val = node.getValue();
            if (val == nil or val == '') {
                self.props.dispatchCallsign.setValue(substr(self.props.callsign.getValue(), 0, 3));
            }
            else {
                self.props.dispatchCallsign.setValue(val);
            }
        }, 1, 0);
        foreach (var p; ['facility', 'departure-airport', 'destination-airport', 'flight-id', 'aircraft-type', 'atis', 'gate']) {
            me.listeners['pdc-dialog/' ~ p] = setlistener(props.globals.getNode('/acars/pdc-dialog/' ~ p), func (node) {
                self.validatePDC();
            });
        }
        me.availabilityPingTimer.start();
        me.adscTimer.start();
    },

    detach: func {
        var errors = [];
        m.availabilityPingTimer.stop();
        me.adscTimer.stop();
        foreach (var k; keys(me.listeners)) {
            if (me.listeners[k] != nil)
                call(removelistener, [me.listeners[k]], errors);
            me.listeners[k] = nil;
        }
        if (errors != [])
            debug.dump(errors);
    },

    isAvailable: func {
        return contains(globals, 'hoppieAcars') and (me.props.statusText.getValue() or '') == 'running';
    },

    isAtisAvailable: func {
        var backend = me.props.atisBackend.getValue();
        if (backend == 'HOPPIE') return me.isAvailable();
        if (backend == 'OFF') return 0;
        return 1; # DATIS and AUTO are always available
    },

    isWeatherAvailable: func {
        var backend = me.props.weatherBackend.getValue();
        if (backend == 'HOPPIE') return me.isAvailable();
        if (backend == 'OFF') return 0;
        return 1; # NOAA and AUTO are always available
    },

    isProgressAvailable: func {
        var backend = me.props.progressBackend.getValue();
        if (backend == 'OFF') return 0;
        # AUTO is currently always HOPPIE
        return me.isAvailable();
    },

    updateAvailabilities: func {
        if (me.props.availability != nil) {
            me.props.availability.setValue('telex', me.isAvailable());
            me.props.availability.setValue('atis', me.isAtisAvailable());
            me.props.availability.setValue('progress', me.isProgressAvailable());
            me.props.availability.setValue('weather', me.isWeatherAvailable());
        }
    },

    genSerial: func {
        var result = me.nextSerial;
        me.nextSerial += 1;
        return result;
    },

    receive: func (msg=nil) {
        if (msg == nil)
            msg = me.props.uplink.getValues();
        # debug.dump('ACARS UPLINK', msg);
        if (msg.type == 'telex') {
            var serial = me.genSerial();
            var historyNode = me.props.telexReceived.addChild('m' ~ serial);
            historyNode.setValue('serial', serial);
            historyNode.setValue('from', msg.from);
            historyNode.setValue('text', msg.packet);
            historyNode.setValue('timestamp', msg.timestamp);
            historyNode.setValue('status', 'new');
            me.updateUnread();
        }
        elsif (msg.type == 'ads-c') {
            var words = split(' ', msg.packet);
            if (words[0] == 'REQUEST' and words[1] == 'PERIODIC') {
                var period = math.max(60, words[2] or 600);
                var node = me.props.adscPeriodics.getNode(msg.from, 1);
                node.setValue('period', period);
                node.setValue('next', me.props.adscTimer.getValue());
            }
            elsif ((words[0] == 'CANCEL' and words[1] == 'REPORTING') or
                   (words[0] == 'REQUEST' and words[1] == 'CANCEL')) {
                var node = me.props.adscPeriodics.getNode(msg.from, 0);
                if (node != nil) {
                    node.remove();
                }
            }
        }
    },

    updateADSC: func () {
        var timer = me.props.adscTimer.getValue();
        foreach (var periodicNode; me.props.adscPeriodics.getChildren()) {
            if (periodicNode.getValue('next') <= timer) {
                me.sendADSCReport(periodicNode.getName());
                periodicNode.setValue('next', timer + periodicNode.getValue('period'));
            }
        }
        me.props.adscTimer.setValue(timer + 10);
    },

    handleSent: func (node) {
        var status = node.getValue();
        if (status == 'sent' or status == 'error') {
            var msg = me.props.downlink.getValues();
            # debug.dump('ACARS DOWNLINK', msg);
            if (msg.type == 'telex') {
                var serial = me.genSerial();
                var historyNode = me.props.telexSent.addChild('m' ~ serial);
                historyNode.setValue('serial', serial);
                historyNode.setValue('to', msg.to);
                historyNode.setValue('text', msg.packet);
                historyNode.setValue('timestamp', msg.timestamp);
                historyNode.setValue('status', 'sent');
            }
        }
    },

    sendTelex: func (to=nil, txt=nil) {
        var mode = 'AUTO';
        if (getprop('/hoppie/status-text') == 'running')
            mode = 'HOPPIE';
        else
            mode = 'OFF';
        if (to == nil) to = getprop('/acars/telex-dialog/to');
        if (txt == nil) txt = getprop('/acars/telex-dialog/text');
        if (to != '' and txt != '') {
            if (mode == 'HOPPIE') {
                globals.hoppieAcars.send(to, 'telex', txt);
                return 1;
            }
        }
        return 0;
    },

    sendProgress: func (to=nil, txt='') {
        var mode = me.props.progressBackend.getValue() or 'AUTO';
        if (mode == 'AUTO') {
            if (getprop('/hoppie/status-text') == 'running')
                mode = 'HOPPIE';
            else
                mode = 'OFF';
        }
        if (to == nil) to = getprop('/acars/dispatch-callsign');
        if (to != '' and txt != '') {
            if (mode == 'HOPPIE') {
                globals.hoppieAcars.send(to, 'progress', txt);
                return 1;
            }
        }
        return 0;
    },

    sendInfoRequest: func (what, station=nil) {
        if (station == nil)
            station = getprop('/acars/inforeq-dialog/station');
        if (what == 'metar' or what == 'taf' or what == 'shorttaf') {
            me.sendWeatherRequest(what, station);
        }
        elsif (what == 'atis' or what == 'vatatis') {
            me.sendAtisRequest(station);
        }
    },

    sendWeatherRequest: func (what, station) {
        var mode = me.props.weatherBackend.getValue() or 'AUTO';
        if (mode == 'AUTO') {
            if (getprop('/hoppie/status-text') == 'running')
                mode = 'HOPPIE';
            else
                mode = 'NOAA';
        }
        if (mode == 'HOPPIE')
            return me.sendHoppieInfoRequest(what, station);
        elsif (mode == 'NOAA')
            return me.sendNoaaInfoRequest(what, station);
        else
            return 0;
    },

    sendAtisRequest: func (station) {
        var mode = me.props.atisBackend.getValue() or 'AUTO';
        if (mode == 'AUTO') {
            if (getprop('/hoppie/status-text') == 'running')
                mode = 'HOPPIE';
            else
                mode = 'DATIS';
        }
        if (mode == 'HOPPIE')
            return me.sendHoppieInfoRequest('vatatis', station);
        elsif (mode == 'DATIS')
            return me.sendDAtisRequest(station);
        else
            return 0;
    },

    dAtisTemplate: string.compileTemplate('https://datis.clowd.io/api/{station}'),

    injectSystemMessage: func (from, packet) {
        var msg = {
            type: 'telex',
            from: 'SYS:' ~ from,
            packet: packet,
            timestamp: me.getCurrentTimestamp(),
        };
        me.receive(msg);
    },

    sendDAtisRequest: func (station) {
        var url = me.dAtisTemplate({'station': station});
        var errors = [];

        call(func (url) {
            var self = me;
            http.load(url)
                .done(func(r) {
                    if (r.status == 200) {
                        var data = call(json.parse, [r.response], nil, errors);
                        if (size(errors) != 0) {
                            debug.dump(errors);
                            self.injectSystemMessage('DATIS', 'DATALINK ERROR');
                        }
                        elsif (typeof(data) == 'vector') {
                            if (size(data) == 0)
                                self.injectSystemMessage('DATIS', "ATIS " ~ station ~ ":\nNO ATIS AVAILABLE FOR THIS STATION");
                            else
                                self.injectSystemMessage('DATIS', data[0].datis);
                        }
                        elsif (typeof(data) == 'hash')
                            self.injectSystemMessage('DATIS', "ATIS " ~ station ~ ":\n" ~ string.uc(data.error or 'THIS STATION IS NOT AVAILABLE'));
                    }
                    elsif (r.status == 404) {
                        self.injectSystemMessage('DATIS', "ATIS " ~ station ~ ":\n" ~ 'THIS STATION IS NOT AVAILABLE');
                    }
                    else {
                        # TODO: handle HTTP error
                        print(r.status ~ ' ' ~ r.reason);
                        self.injectSystemMessage('DATIS', 'DATALINK ERROR');
                    }
                })
                .fail(func (r) {
                    # TODO
                    debug.dump(r);
                    self.injectSystemMessage('DATIS', 'DATALINK ERROR');
                });
        }, [url], me, {}, errors);
        if (size(errors) > 0) {
            debug.dump(errors);
            return 0;
        }
        return 1;
    },

    noaaTemplates: {
        'metar': string.compileTemplate('https://tgftp.nws.noaa.gov/data/observations/metar/stations/{station}.TXT'),
        'taf': string.compileTemplate('https://tgftp.nws.noaa.gov/data/forecasts/taf/stations/{station}.TXT'),
        'shorttaf': string.compileTemplate('https://tgftp.nws.noaa.gov/data/forecasts/taf/stations/{station}.TXT'),
    },

    sendNoaaInfoRequest: func (what, station) {
        var template = me.noaaTemplates[what];
        if (template == nil) return 0;
        var url = template({'station': station});
        var errors = [];

        call(func (url) {
            var self = me;
            http.load(url)
                .done(func(r) {
                    if (r.status == 200) {
                        var lines = split("\n", r.response);
                        var packet = string.join("\n", subvec(lines, 1));
                        self.injectSystemMessage('NOAA', packet);
                    }
                    elsif (r.status == 404) {
                        self.injectSystemMessage('NOAA', "ATIS " ~ station ~ ":\n" ~ 'THIS STATION IS NOT AVAILABLE');
                    }
                    else {
                        # TODO: handle HTTP error
                        print(r.status ~ ' ' ~ r.reason);
                        self.injectSystemMessage('DATIS', 'DATALINK ERROR');
                    }
                })
                .fail(func (r) {
                    # TODO
                    debug.dump(r);
                    self.injectSystemMessage('DATIS', 'DATALINK ERROR');
                });
        }, [url], me, {}, errors);
        if (size(errors) > 0) {
            debug.dump(errors);
            return 0;
        }
        return 1;
    },

    sendHoppieInfoRequest: func (what, station) {
        if (what == nil or what == '') return 0;
        if (station == nil or station == '') return 0;
        var self = me;
        globals.hoppieAcars.send('SERVER', 'inforeq', what ~ ' ' ~ station,
            func (response) {
                if (string.match(response, 'ok {server info {*}}')) {
                    packet = string.uc(
                                substr(response,
                                    size('ok {server info {'),
                                    size(response) - size('ok {server info {}}')));
                    self.injectSystemMessage('HOPPIE', packet);
                }
            });
        return 1;
    },

    sendADSCReport: func (station) {
        var utcNode = props.globals.getNode('/sim/time/utc');
        var txt = sprintf('REPORT %s %02i%02i%02i %1.5f %1.5f %i',
                    me.props.callsign.getValue(),
                    utcNode.getValue('day'),
                    utcNode.getValue('hour'),
                    utcNode.getValue('minute'),
                    me.props.lat.getValue(),
                    me.props.lon.getValue(),
                    me.props.alt.getValue());
        globals.hoppieAcars.send(station, 'ads-c', txt);
    },

    clearTelexDialog: func () {
        setprop('/acars/telex-dialog/text', '');
    },

    completePDC: func (pdc) {
        if (pdc == nil)
            pdc = {};
        if (pdc['facility'] == nil) pdc.facility = getprop('/acars/pdc-dialog/facility');
        if (pdc['origin'] == nil) pdc.origin = getprop('/acars/pdc-dialog/departure-airport');
        if (pdc['destination'] == nil) pdc.destination = getprop('/acars/pdc-dialog/destination-airport');
        if (pdc['fltID'] == nil) pdc.fltID = getprop('/acars/pdc-dialog/flight-id');
        if (pdc['acType'] == nil) pdc.acType = getprop('/acars/pdc-dialog/aircraft-type');
        if (pdc['atis'] == nil) pdc.atis = getprop('/acars/pdc-dialog/atis');
        if (pdc['gate'] == nil) pdc.gate = getprop('/acars/pdc-dialog/gate');
        return pdc;
    },

    pdcValid: func (pdc) {
        if (pdc == nil) return 0;
        if (pdc['facility'] == '') return 0;
        if (pdc['origin'] == '') return 0;
        if (pdc['destination'] == '') return 0;
        if (pdc['fltID'] == '') return 0;
        if (pdc['acType'] == '') return 0;

        # ATIS is optional; if given, must be A-Z
        if (pdc['atis'] != '' and !string.match(pdc['atis'], '[A-Z]')) return 0;

        # gate is optional
        return 1;
    },

    validatePDC: func (pdc=nil) {
        pdc = me.completePDC(pdc);
        var valid = me.pdcValid(pdc);
        setprop('/acars/pdc-dialog/valid', valid);
        return valid;
    },

    sendPDC: func (pdc=nil) {
        pdc = me.completePDC(pdc);
        if (!me.pdcValid(pdc)) return 0;

        var msg = sprintf("REQUEST PREDEP CLEARANCE %s %s TO %s AT %s",
                    pdc.fltID, pdc.acType, pdc.destination, pdc.origin);
        if (pdc.gate != '')
            msg = msg ~ sprintf(" STAND %s", pdc.gate);
        if (pdc.atis != '')
            msg = msg ~ sprintf(" ATIS %s", pdc.atis);
        me.sendTelex(pdc.facility, msg);
        return 1;
    },

    updateUnread: func () {
        var msgNodes = me.props.telexReceived.getChildren();
        var numUnread = 0;
        var newest = 0;
        foreach (var msgNode; msgNodes) {
            if (msgNode.getValue('status') == 'new') {
                numUnread += 1;
                if (newest == 0)
                    newest = msgNode.getValue('serial');
            }
        }
        me.props.unread.setValue(numUnread);
        me.props.newestUnread.setValue(newest);
    },

    clearHistory: func () {
        me.props.telexReceived.removeAllChildren();
        me.props.telexSent.removeAllChildren();
        me.updateUnread();
    },

    getCurrentTimestamp: func () {
        var utcNode = props.globals.getNode('/sim/time/utc');
        return sprintf('%04u%02u%02uT%02u%02u%02u',
            utcNode.getValue('year'),
            utcNode.getValue('month'),
            utcNode.getValue('day'),
            utcNode.getValue('hour'),
            utcNode.getValue('minute'),
            utcNode.getValue('second'));
    },
};

