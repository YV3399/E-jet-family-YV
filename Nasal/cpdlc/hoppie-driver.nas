var HoppieDriver = {
    new: func (system) {
        var m = BaseDriver.new(system);
        m.parents = [HoppieDriver] ~ m.parents;
        m.props = {
            downlink: props.globals.getNode('/acars/downlink', 1),
            uplink: props.globals.getNode('/acars/uplink', 1),
            status: props.globals.getNode('/acars/status-text', 1),
            uplinkStatus: props.globals.getNode('/acars/uplink/status', 1),
        };
        m.listeners = {
            uplink: nil,
            running: nil,
        };
        return m;
    },

    getDriverName: func () { return 'HOPPIE'; },

    isAvailable: func () {
        return
            contains(globals, 'acars') and
            (me.props.status.getValue() == 'running');
    },

    start: func () {
        if (me.listeners.uplink != nil) {
            removelistener(me.listeners.status);
            me.listeners.uplink = nil;
        }
        var self = me;
        me.listeners.uplink = setlistener(me.props.uplinkStatus, func { self.receive(); });
    },

    stop: func () {
        if (me.listeners.uplink != nil) {
            removelistener(me.listeners.uplink);
            me.listeners.uplink = nil;
        }
    },

    connect: func (logonStation) {
        var min = me.system.genMIN();
        var packed = me._pack(min, '', 'Y', 'REQUEST LOGON');
        me._send(logonStation, packed);
    },

    disconnect: func () {
        var to = me.system.getCurrentStation();
        if (to == nil or to == '') return; # Not connected
        var min = me.system.genMIN();
        var packed = me._pack(min, '', 'N', 'LOGOFF');
        me._send(me.system.getCurrentStation(), packed);
    },

    send: func (msg) {
        var body = [];
        var to = msg.to or me.system.getCurrentStation();
        foreach (var part; msg.parts) {
            append(body, formatMessagePart(part.type, part.args));
        }
        var ra = msg.getRA();
        var packed = me._pack(msg.min or '', msg.mrn or '', ra or 'N', body);
        var self = me;
        debug.dump('ABOUT TO SEND:', packed);
        me._send(to, packed, func {
            self.system.markMessageSent(msg.getMID());
        });
    },

    receive: func () {
        var raw = me._rawMessageFromNode(me.props.uplink);
        # ignore non-CPDLC
        if (raw.type != 'cpdlc')
            return;
        var cpdlc = me._parseCPDLC(raw.packet);
        # bail on CPDLC parser error (_parseCPDLC will dump error)
        if (cpdlc == nil)
            return;
        
        # ignore empty messages
        if (typeof(cpdlc.message) != 'vector' or size(cpdlc.message) == 0)
            return;

        # Now handle the actual message.
        var m = cpdlc.message[0];
        var vars = [];

        if (m == 'LOGON ACCEPTED') {
            me.system.setLogonAccepted(raw.from);
        }
        elsif (m == 'LOGOFF') {
            me.system.setCurrentStation('');
        }
        elsif (startswith(m, 'HANDOVER') and string.scanf(m, 'HANDOVER @%4s', vars)) {
            me.system.setNextStation(vars[0]);
            me.system.connect(vars[0]);
        }
        elsif (startswith(m, 'CURRENT ATC UNIT')) {
            if (string.scanf(m, 'CURRENT ATC UNIT@_@%4s@_@%', vars) != 0) {
                me.system.setCurrentStation(vars[0]);
            }
            elsif (string.scanf(m, 'CURRENT ATC UNIT@_@%4s', vars) != 0) {
                me.system.setCurrentStation(vars[0]);
            }
        }
        else {
            debug.dump('CPDLC', raw, cpdlc);
        }
    },

    _send: func (to, packed, then=nil) {
        debug.dump('SENDING', to, packed);
        globals.acars.send(to, 'cpdlc', packed, then);
    },

    _pack: func (min, mrn, ra, message) {
        if (typeof(message) == 'vector') {
            message = string.join('/', message);
        }
        return string.join('/', ['', 'data2', min, mrn, ra, message]);
    },

    _rawMessageFromNode: func(node) {
        var msg = {
                from: node.getValue('from'),
                to: node.getValue('to'),
                type: node.getValue('type'),
                packet: node.getValue('packet'),
                status: node.getValue('status'),
                serial: node.getValue('serial'),
                timestamp: node.getValue('timestamp'),
                timestamp4: substr(node.getValue('timestamp') or '?????????T??????', 9, 4),
            };
        return msg;
    },


    _parseCPDLC: func (str) {
        # /data2/654/3/NE/LOGON ACCEPTED
        var result = split('/', string.uc(str));
        if (result[0] != '') {
            debug.dump('CPDLC PARSER ERROR 10: expected leading slash in ' ~ str);
            return nil;
        }
        if (result[1] != 'DATA2') {
            debug.dump('CPDLC PARSER ERROR 11: expected `data2` in ' ~ str);
            return nil;
        }
        var min = result[2];
        var mrn = result[3];
        var ra = result[4];
        var message = subvec(result, 5);
        return {
            min: min,
            mrn: mrn,
            ra: ra,
            message: message,
        }
    },

};

var startswith = func (haystack, needle) {
    return (left(haystack, size(needle)) == needle);
};
