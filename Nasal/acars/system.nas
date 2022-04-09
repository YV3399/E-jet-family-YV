var System = {
    new: func () {
        var m = {
            parents: [System],
            props: {
                base: nil,
                telexReceived: nil,
                telexSent: nil,
                unread: nil,
                statusText: nil,
                uplink: nil,
                downlink: nil,
                uplinkStatus: nil,
                downlinkStatus: nil,
            },
            listeners: {
                uplink: nil,
                downlink: nil,
            },
            nextSerial: 1,
        };
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
        me.props.statusText = props.globals.getNode('/hoppie/status-text');
        me.props.uplink = props.globals.getNode('/hoppie/uplink', 1);
        me.props.downlink = props.globals.getNode('/hoppie/downlink', 1);
        me.props.uplinkStatus = props.globals.getNode('/hoppie/uplink/status', 1);
        me.props.downlinkStatus = props.globals.getNode('/hoppie/downlink/status', 1);
        me.updateUnread();
        var self = me;
        me.listeners.uplink = setlistener(me.props.uplinkStatus, func (node) {
            self.receive();
        });
        me.listeners.downlink = setlistener(me.props.downlinkStatus, func (node) {
            self.handleSent(node);
        });
        foreach (var p; ['facility', 'departure-airport', 'destination-airport', 'flight-id', 'aircraft-type', 'atis', 'gate']) {
            me.listeners['pdc-dialog/' ~ p] = setlistener(props.globals.getNode('/acars/pdc-dialog/' ~ p), func (node) {
                self.validatePDC();
            });
        }
    },

    detach: func {
        var errors = [];
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

    genSerial: func {
        var result = me.nextSerial;
        me.nextSerial += 1;
        return result;
    },

    receive: func (msg=nil) {
        if (msg == nil)
            msg = me.props.uplink.getValues();
        debug.dump('ACARS UPLINK', msg);
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
    },

    handleSent: func (node) {
        var status = node.getValue();
        if (status == 'sent' or status == 'error') {
            var msg = me.props.downlink.getValues();
            debug.dump('ACARS DOWNLINK', msg);
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
        if (to == nil) to = getprop('/acars/telex-dialog/to');
        if (txt == nil) txt = getprop('/acars/telex-dialog/text');
        if (to != '' and txt != '') {
            globals.hoppieAcars.send(to, 'telex', txt);
            return 1;
        }
        else {
            return 0;
        }
    },

    sendMetarRequest: func (station) { me.sendInfoRequest('metar', station); },
    sendTafRequest: func (station) { me.sendInfoRequest('taf', station); },
    sendAtisRequest: func (station) { me.sendInfoRequest('atis', station); },

    sendInfoRequest: func (what, station) {
        if (getprop('/hoppie/status-text') == 'running')
            me.sendHoppieInfoRequest(what, station);
        else
            me.sendNoaaInfoRequest(what, station);
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
                    debug.dump(r.status, r.reason, r.response);
                    if (r.status == 200) {
                        var lines = split("\n", r.response);
                        var packet = string.join("\n", subvec(lines, 1));
                        var msg = {
                            type: 'telex',
                            from: 'NOAA',
                            packet: packet,
                            timestamp: globals.hoppieAcars.getCurrentTimestamp(),
                        };
                        self.receive(msg);
                    }
                    else {
                        # TODO: handle HTTP error
                    }
                })
                .fail(func {
                    # TODO
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
        if (what == 'atis') what = 'vatatis';
        if (station == nil or station == '') return 0;
        var self = me;
        globals.hoppieAcars.send('SERVER', 'inforeq', what ~ ' ' ~ station,
            func (response) {
                debug.dump(response);
                if (string.match(response, 'ok {server info {*}}')) {
                    packet = string.uc(
                                substr(response,
                                    size('ok {server info {'),
                                    size(response) - size('ok {server info {}}')));
                    var msg = {
                        type: 'telex',
                        from: 'SYSTEM',
                        packet: packet,
                        timestamp: globals.hoppieAcars.getCurrentTimestamp(),
                    };
                    self.receive(msg);
                }
            });
        return 1;
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
        foreach (var msgNode; msgNodes) {
            if (msgNode.getValue('status') == 'new') {
                me.props.unread.setValue(1);
                break;
            }
        }
        me.props.unread.setValue(0);
    },

    clearHistory: func () {
        me.props.telexReceived.removeAllChildren();
        me.props.telexSent.removeAllChildren();
        me.updateUnread();
    },
};

