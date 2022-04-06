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
        # debug.dump('ABOUT TO SEND:', packed);
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
            # debug.dump('CPDLC', raw, cpdlc);
            var msg = Message.new();
            msg.dir = 'up';
            msg.min = cpdlc.min;
            msg.mrn = cpdlc.mrn;
            msg.parts = [];
            msg.from = raw.from;
            msg.to = raw.to;
            msg.dir = 'up';
            msg.valid = 1;
            foreach (var m; cpdlc.message) {
                var rawPart = me._parseCPDLCPart(m);
                var type = me._matchCPDLCMessageType(rawPart[0], rawPart[1]);
                var args = rawPart[1];
                if (type == nil) {
                    args = [m];
                    if (cpdlc.ra == 'WU')
                        type = 'TXTU-4';
                    elsif (cpdlc.ra == 'AN')
                        type = 'TXTU-5';
                    elsif (cpdlc.ra == 'R')
                        type = 'TXTU-1';
                    else
                        type = 'TXTU-2';
                }
                append(msg.parts, {type: type, args: args});
            }
            # debug.dump('RECEIVED', msg);
            me.system.receive(msg);
        }
    },

    _parseCPDLCPart: func (txt, dir='up') {
        var words = split(' ', txt);
        var parsed = [];
        var i = 0;
        var args = [];
        var a = [];
        var argmode = 0;
        var argnum = 1;
        forindex (var i; words) {
            var word = words[i];
            if (word == '') continue;
            if (argmode) {
                if (substr(word, -1) == '@') {
                    # found terminating '@'
                    append(a, string.replace(word, '@', ''));
                    if (size(a)) {
                        append(args, string.join(' ', a));
                    }
                    a = [];
                    argmode = 0;
                }
                else {
                    append(a, word);
                }
            }
            else {
                if (substr(word, 0, 1) == '@') {
                    # found opening '@'
                    append(parsed, '$' ~ argnum);
                    argnum += 1;
                    if (substr(word, -1) == '@') {
                        # found terminating '@'
                        append(args, substr(word, 1, size(word) - 2));
                    }
                    else {
                        append(a, substr(word, 1));
                        argmode = 1;
                    }
                }
                else {
                    append(parsed, word);
                }
            }
        }
        if (size(a)) {
            append(args, string.join(' ', a));
        }
        var txt = string.join(' ', parsed);
        return [txt, args];
    },

    _matchCPDLCMessageType: func (txt, args, dir='up') {
        var messages = (dir == 'up') ? uplink_messages : downlink_messages;
        var msg = nil;
        foreach (var msgKey; keys(messages)) {
            var message = messages[msgKey];
            if (message.txt != txt) {
                continue;
            }
            var valid = 1;
            forindex (var i; message.args) {
                var argTy = message.args[i];
                var argVal = args[i] or '';
                if (!me._validateArg(argTy, argVal)) {
                    valid = 0;
                    break;
                }
            }
            if (valid) {
                msg = msgKey;
                break;
            }
        }
        return msg;
    },

    _validateArg: func (argTy, argVal) {
        var spacesRemoved = string.replace(argVal, ' ', '');
        if (argTy == ARG_FL_ALT) {
            return string.match(spacesRemoved, 'FL[0-9][0-9][0-9]') or
                   string.match(spacesRemoved, 'FL[0-9][0-9]') or

                   string.match(spacesRemoved, '[0-9][0-9][0-9][0-9]FT');
                   string.match(spacesRemoved, '[0-9][0-9][0-9][0-9][0-9]FT') or

                   string.match(spacesRemoved, '[0-9][0-9][0-9][0-9]FEET') or
                   string.match(spacesRemoved, '[0-9][0-9][0-9][0-9][0-9]FEET') or

                   string.match(spacesRemoved, '[0-9][0-9][0-9][0-9]') or
                   string.match(spacesRemoved, '[0-9][0-9][0-9][0-9][0-9]') or

                   string.match(spacesRemoved, '[0-9][0-9][0-9]M');
                   string.match(spacesRemoved, '[0-9][0-9][0-9][0-9]M');
                   string.match(spacesRemoved, '[0-9][0-9][0-9][0-9][0-9]M') or

                   string.match(spacesRemoved, '[0-9][0-9][0-9]METERS') or
                   string.match(spacesRemoved, '[0-9][0-9][0-9][0-9]METERS') or
                   string.match(spacesRemoved, '[0-9][0-9][0-9][0-9][0-9]METERS');
        }
        elsif (argTy == ARG_SPEED) {
            return string.match(spacesRemoved, '[0-9][0-9][0-9]KTS') or
                   string.match(spacesRemoved, '[0-9][0-9]KTS') or
                   string.match(spacesRemoved, '[0-9][0-9][0-9]KNOTS') or
                   string.match(spacesRemoved, '[0-9][0-9]KNOTS') or
                   string.match(spacesRemoved, '[0-9][0-9][0-9]KMH') or
                   string.match(spacesRemoved, '[0-9][0-9]KMH') or
                   string.match(spacesRemoved, '[0-9][0-9][0-9]KPH') or
                   string.match(spacesRemoved, '[0-9][0-9]KPH') or
                   string.match(spacesRemoved, 'MACH.[0-9][0-9]') or
                   string.match(spacesRemoved, 'MACH.[0-9]') or
                   string.match(spacesRemoved, 'M.[0-9][0-9]') or
                   string.match(spacesRemoved, 'M.[0-9]') or
                   string.match(spacesRemoved, 'MACH0[0-9][0-9]') or
                   string.match(spacesRemoved, 'MACH[0-9][0-9]') or
                   string.match(spacesRemoved, 'MACH[0-9]') or
                   string.match(spacesRemoved, 'M0[0-9][0-9]') or
                   string.match(spacesRemoved, 'M[0-9][0-9]') or
                   string.match(spacesRemoved, 'M[0-9]');
        }
        else {
            # We skip validating any other argument types; the only messages
            # that are potentially ambiguous are those that can take either a
            # speed or an altitude/flight level, so these are the only types
            # we need to distinguish here.
            return 1;
        }
    },

    _send: func (to, packed, then=nil) {
        # debug.dump('SENDING', to, packed);
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

var testMessages = [
    "CONTACT @LONDON CONTROL@ @127.100",
    "ROGER",
    "CLIMB TO @FL360",
    "DESCEND TO @FL110",
    "PROCEED DIRECT TO @HELEN@ DESCEND TO @FL200",
    "PROCEED DIRECT TO @BUB",
    "SQUAWK @1000",
    "FLIGHT PLAN NOT HELD",
    "INCREASE SPEED TO @250 KTS",
    "MAINTAIN @FL100",
    "MAINTAIN @210 KTS",
];

# foreach (var msg; testMessages) {
#     var parsed = HoppieDriver._parseCPDLCPart(msg);
#     var msgType = HoppieDriver._matchCPDLCMessageType(parsed[0], parsed[1]);
#     debug.dump(msg, parsed, msgType);
# }
