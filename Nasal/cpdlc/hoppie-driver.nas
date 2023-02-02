io.include('parser-combinators.nas');

# These are not in ICAO Doc 4444; we use these to inject system events into the
# message log, but we never send or receive these.
var hoppie_uplink_messages = {
    "HPPU-1": { txt: "LOGON ACCEPTED", args: [] },
    "HPPU-2": { txt: "HANDOVER $1", args: [ARG_DATA_AUTHORITY] },
    "HPPU-3": { txt: "LOGOFF", args: [] },
};

var hoppie_downlink_messages = {
    "HPPD-1": { txt: "REQUEST LOGON", args: [] },
};

var sortBySpecificity = func (messages) {
    var compare = func (a, b) {
        return cmp(b.txt, a.txt) or cmp(b.key, a.key);
    };
    return sort(messages, compare);
};

var collectMessages = func (messages) {
    var result = [];
    foreach (var k; keys(messages)) {
        var msg = {};
        foreach (var kk; keys(messages[k]))
            msg[kk] = messages[k][kk];
        msg.key = k;
        append(result, msg);
    }
    return result;
};

var uplinkMessageList =
    sortBySpecificity(
        collectMessages(hoppie_uplink_messages) ~
        collectMessages(uplink_messages));

var downlinkMessageList =
    sortBySpecificity(
        collectMessages(hoppie_downlink_messages) ~
        collectMessages(downlink_messages));

# foreach (var msg; downlinkMessageList) {
#     printf("%s %s", msg.key, msg.txt);
# }

var unwords = func (words) {
    return string.join(' ', words);
};

var isIdentifier = func (str) {
    return isstr(str) and size(str) and string.isalpha(str[0]);
};

var isNumber = func (str) {
    return num(str) != nil;
};

var isSpeed = func (str) {
    if (startswith(str, 'MACH') and isNumber(substr(str, 4))) {
        return 1;
    }
    elsif (startswith(str, 'M') and isNumber(substr(str, 1))) {
        return 1;
    }
    else {
        return 0;
    }
};

var isProcedure = func (str) {
    return isstr(str) and size(str) and string.isalpha(str[0]) and str != 'TO';
};


var argParsers = {};

argParsers[ARG_TEXT] = func (delimiter=nil) {
    if (delimiter == nil)
        delimiter = eof;
    manyTill(anyToken, delimiter).map(unwords);
};

argParsers[ARG_ROUTE] = func (delimiter=nil) {
    if (delimiter == nil)
        delimiter = eof;
    satisfy(func (t) { t != 'TO'; }).bind(func (x) {
        manyTill(anyToken, delimiter).bind(func (xs) {
            Parser.pure(unwords([x] ~ xs));
        });
    });
};

argParsers[ARG_PROCEDURE] = func (delimiter=nil) {
    satisfy(isProcedure);
};

argParsers[ARG_FACILITY] = func (delimiter=nil) {
    satisfy(isIdentifier);
};

argParsers[ARG_DATA_AUTHORITY] = func (delimiter=nil) {
    satisfy(isIdentifier);
};

argParsers[ARG_NAVPOS] = func (delimiter=nil) {
    satisfy(isIdentifier);
};

argParsers[ARG_CALLSIGN] = func (delimiter=nil) {
    some(satisfy(isIdentifier)).map(unwords);
};

argParsers[ARG_FREQ] = func (delimiter=nil) {
    satisfy(isNumber);
};

var isAltOrFL = func (val) {
    if (startswith(val, 'FL') and isNumber(substr(val, 2))) {
        return 1;
    }
    elsif (endswith(val, 'FT') and isNumber(substr(val, 0, size(val) - 2))) {
        return 1;
    }
    elsif (endswith(val, 'M') and isNumber(substr(val, 0, size(val) - 1))) {
        return 1;
    }
    else {
        return 0;
    }
};

argParsers[ARG_FL_ALT] = func (delimiter=nil) {
    choice(
        [
            satisfy(isAltOrFL),
            satisfy(isNumber).bind(func (val) {
                oneOf(['FT', 'FEET', 'M', 'METERS']).bind(func (unit) {
                    return Parser.pure(val ~ ' ' ~ unit);
                });
            }),
        ]);
};

argParsers[ARG_SPEED] = func (delimiter=nil) {
    choice(
        [
            satisfy(isSpeed),
            satisfy(isNumber).bind(func (val) {
                oneOf(['KTS', 'KNOTS', 'MACH', 'KMH', 'KPH']).bind(func (unit) {
                        return Parser.pure(val ~ ' ' ~ unit);
                });
            }),
        ]);
};

var getArgParser = func (type, delimiter=nil) {
    var elemType = type & ARG_TYPE_MASK;
    var optionalType = type & ARG_OPTIONAL;

    var p = nil;
    if (contains(argParsers, elemType)) {
        p = argParsers[elemType](delimiter);
    }
    else {
        p = argParsers[ARG_TEXT](delimiter);
    }

    if (optionalType) {
        p = optionally(p);
    }

    return p;
};

var matchMessageText = func (msg, tokens) {
    var ts = TokenStream.new(tokens);
    var words = split(' ', msg.txt);
    var ps = TokenStream.new(words);

    var args = [];

    while (!ps.eof()) {
        var pspec = anyToken.runOrDie(ps);
        var delimiter = optionally(peekToken, nil).runOrDie(ps);
        if (delimiter != nil and startswith(delimiter, '$'))
            delimiter = nil;
        if (delimiter != nil)
            delimiter = exactly(delimiter);

        # printf("Parsing: %s (next %s)", pspec, delimiter);

        if (startswith(pspec, '$')) {
            var index = num(substr(pspec, 1)) - 1;
            var type = ARG_TEXT;
            if (index < size(msg.args))
                type = msg.args[index];
            var p = getArgParser(type, delimiter);
            var r = p.run(ts);
            if (r.failed)
                return r;
            else
                append(args, r.val);
        }
        else {
            var r = exactly(pspec).run(ts);
            if (r.failed)
                return r;
        }
    }

    return Result.pure([args, ts.unconsumed()]);
};

var matchMessage = func (tokens, dir, ra) {
    var msgTypeList = [];
    if (dir == 'up' or dir == 'any') {
        msgTypeList = msgTypeList ~ uplinkMessageList;
    }
    if (dir == 'down' or dir == 'any') {
        msgTypeList = msgTypeList ~ downlinkMessageList;
    }
    foreach (var msgType; msgTypeList) {
        var msgTypeKey = msgType.key;

        # printf("Trying %s", msgTypeKey);

        # Skip the message types that just have a single catch-all pattern.
        if (msgType.txt == '$1') continue;

        var result = matchMessageText(msgType, tokens);
        if (result.ok) {
            (args, remainder) = result.val;
            return [{type: msgTypeKey, args: args}, remainder];
        }
    }
    if (dir == 'up') {
        if (ra == 'WU')
            type = 'TXTU-4';
        elsif (ra == 'AN')
            type = 'TXTU-5';
        elsif (ra == 'R')
            type = 'TXTU-1';
        else
            type = 'TXTU-2';
    }
    else {
        if (ra == 'Y')
            type = 'TXTU-1';
        else
            type = 'TXTU-2';
    }
    return [{type: type, args: [unwords(tokens)]}, []];
};

var tokenSplit = func (str) {
    str = string.replace(str, '@_@', ' ');
    str = string.replace(str, '@', ' ');
    var words = split(' ', str);
    var tokens = [];
    foreach (var word; words) {
        if (word != '')
            append(tokens, word);
    }
    return tokens;
};

var matchMessages = func (str, dir, ra) {
    var tokens = tokenSplit(str);
    var parts = [];
    while (size(tokens) > 0) {
        var result = matchMessage(tokens, dir, ra);
        if (result == nil) {
            die("No result from matchMessage()");
        }
        (part, tokens) = result;
        append(parts, part);
    }
    return parts;
};

var HoppieDriver = {
    new: func (system) {
        var m = BaseDriver.new(system);
        m.parents = [HoppieDriver] ~ m.parents;

        var hoppieNode = props.globals.getNode('/hoppie', 1);

        m.props = {
            downlink: hoppieNode.getNode('downlink', 1),
            uplink: hoppieNode.getNode('uplink', 1),
            status: hoppieNode.getNode('status-text', 1),
            uplinkStatus: hoppieNode.getNode('uplink/status', 1),
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
            contains(globals, 'hoppieAcars') and
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
        me.system.setCurrentStation('');
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
        var cpdlc = parseCPDLC(raw.packet);
        # bail on CPDLC parser error (parseCPDLC will dump error)
        if (cpdlc == nil)
            return;

        # ignore empty messages
        if (typeof(cpdlc.message) != 'vector' or size(cpdlc.message) == 0)
            return;

        # Now handle the actual message.
        var m = cpdlc.message[0];
        var vars = [];

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
            matched = matchMessages(m, 'up', cpdlc.ra);
            msg.parts = msg.parts ~ matched;
        }
        # debug.dump('RECEIVED', msg);

        if (size(msg.parts) == 0)
            return nil;

        if (msg.parts[0].type == 'HPPU-1') {
            # LOGON ACCEPTED
            me.system.setLogonAccepted(raw.from);
            me.system.setCurrentStation(raw.from);
        }
        elsif (msg.parts[0].type == 'HPPU-3') {
            # LOGOFF
            me.system.setCurrentStation('');
        }
        elsif (msg.parts[0].type == 'HPPU-2' or msg.parts[0].type == 'SYSU-2') {
            me.system.setNextStation(vars[0]);
            me.system.connect(vars[0]);
        }
        else {
            me.system.receive(msg);
        }
    },

    _send: func (to, packed, then=nil) {
        # debug.dump('SENDING', to, packed);
        globals.hoppieAcars.send(to, 'cpdlc', packed, then);
    },

    _pack: func (min, mrn, ra, message) {
        if (typeof(message) == 'vector') {
            message = string.join('/', message);
        }
        if (ra == '')
            ra = 'N';
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


};

var startswith = func (haystack, needle) {
    return (left(haystack, size(needle)) == needle);
};

var endswith = func (haystack, needle) {
    return (right(haystack, size(needle)) == needle);
};

var parseCPDLC = func (str) {
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
    var message = split('|', string.join('|', subvec(result, 5)));
    return {
        min: min,
        mrn: mrn,
        ra: ra,
        message: message,
    }
};

var smokeTestMessages = [
    "AIR TRAFFIC SERVICE TERMINATED MONITOR UNICOM 122.800",
    "AT @1257@ DESCEND TO AND MAINTAIN @FL290",
    "ATC REQUEST STATUS . . FSM 1104 230123 EFHK @FIN7RA@ CDA RECEIVED @CLEARANCE CONFIRMED",
    "CALL ATC ON FREQUENCY",
    "CALL ME ON VOICE",
    "CLEARANCE DELIVERED VIA TELEX",
    "CLEARED TO DESTINATION  DEPART VIA ARA1X RWY 16 CLIMB FL150 SQK 1447",
    "CLEARED TO DESTINATION  DEPART VIA PIMOS2H RWY 13 CLIMB FL90 SQK 2621 ATIS INFO D",
    "CLEARED TO @GCLP@ VIA @OSPEN4C OSPEN FP ROUTE CLIMB INIT 5000FT SQUAWK 4024",
    "CLEARED TO @IFR FLIGHT TO PARIS@ VIA @RTE 1 AS FILED",
    "CLEARED TO @KORD@ VIA @HYLND CAM PAYGE Q822 FNT WYNDE2 EMMMA@ SQUAWK @2654@",
    "CLIMB TO AND MAINTAIN @30000FT@ REPORT LEVEL @30000FT@",
    "CLIMB TO AND MAINTAIN @32000FT@ REPORT LEVEL @32000FT@",
    "CLIMB TO AND MAINTAIN @34000FT@ REPORT LEVEL @34000FT@",
    "CLIMB TO AND MAINTAIN @36000FT@ REPORT LEVEL @36000FT@",
    "CLIMB TO AND MAINTAIN @FL400@ REPORT LEVEL @FL400@",
    "CLIMB TO @FL240",
    "CLIMB TO @FL290@",
    "CLIMB TO @FL300@",
    "CLIMB TO @FL300@ | PROCEED DIRECT TO @VELIS@",
    "CLIMB TO @FL310@ CLIMB AT @1000 FT|MIN MAXIMUM",
    "CLIMB TO @FL320",
    "CLIMB TO @FL330",
    "CLIMB TO @FL330@ RESUME OWN NAVIGATION",
    "CLIMB TO @FL340",
    "CLIMB TO @FL350",
    "CLIMB TO @FL350@",
    "CLIMB TO @FL360",
    "CLIMB TO @FL360@",
    "CLIMB TO @FL370",
    "CLIMB TO @FL380",
    "CLIMB TO @FL390",
    "CLRD TO @ZBAA@ OFF @01@ VIA @YIN1A@ SQUAWK @@ INITIAL ALT @@ NEXT FREQ @121.950@",
    "CONTACT @121.375@_@COPENHAGEN CTL",
    "CONTACT @121.375@_@COPENHAGEN CTR",
    "CONTACT @127.725@_@EDGG_H1F_CTR",
    "CONTACT @127.725@_@EDGG_HEF_CTR",
    "CONTACT @128.100@_@PARIS CTL",
    "CONTACT @128.625@_@SWEDEN CTL",
    "CONTACT @129.425@_@LON_S_CTR",
    "CONTACT @129.675@_@LGGG_CTR",
    "CONTACT @130.000@_@ADRIA",
    "CONTACT @131.225@_@SOFIA",
    "CONTACT @131.900@_@NAT_FSS",
    "CONTACT @132.850@_@LPPC_E_CTR",
    "CONTACT @132.975@_@LECM_CTR",
    "CONTACT @134.125@_@LTC_S_CTR",
    "CONTACT @134.700@_@EDYY_J_CTR",
    "CONTACT @134.700@_@MAASTRICHT CTR",
    "CONTACT @136.955@ @@",
    "CONTACT @EDGD 125.200@_@LANGEN CTR",
    "CONTACT @EDGG 124.725@_@LANGEN CTR",
    "CONTACT EDGG_CTR @136.955@",
    "CONTACT @EDYC 133.950@_@MAASTRICHT CTR",
    "CONTACT @EDYJ 134.700@_@MAASTRICHT CTR",
    "CONTACT @EGPX 135.525@_@SCOTTISH CTL",
    "CONTACT @EKDB 121.375@_@COPENHAGEN CTR",
    "CONTACT @EUROCONTROL@ @135.125@",
    "CONTACT @EUWN 135.125@_@EUROCONTROL CTL",
    "CONTACT @GENEVA ARRIVAL@ @131.325@",
    "CONTACT LECM_R1_CTR @135.700@",
    "CONTACT @LFFF@ @128.100@",
    "CONTACT LFMM_NW_CTR @123.805@",
    "CONTACT @LFXX 128.100@_@PARIS CTL",
    "CONTACT @LON@ @129.425@",
    "CONTACT @LONC 127.100@_@LONDON CTL",
    "CONTACT @LONDON CONTROL@ @127.100",
    "CONTACT @LONN 133.700@_@LONDON CTL",
    "CONTACT @LONS 129.425@_@LONDON CTL",
    "CONTACT @LPZE 132.850@_@LISBOA CTL",
    "CONTACT ME BY RADIO I HAVE BEEN TRYING TO CALL YOU",
    "CONTACT @REIMS CONTROL@ @128.300@",
    "CONTLR CHANGE RESEND REQ OR REVERT TO VOICE",
    "CURRENT ATC UNIT@_@ADRA@_@ADRIA",
    "CURRENT ATC UNIT@_@ADRW@_@ADRIA",
    "CURRENT ATC UNIT@_@BIRD@_@REYKJAVIK OCA",
    "CURRENT ATC UNIT@_@CBRA@_@BARCELONA CTL",
    "CURRENT ATC UNIT@_@CMRM@_@MADRID CTL",
    "CURRENT ATC UNIT@_@EDGD@_@LANGEN CTR",
    "CURRENT ATC UNIT@_@EDGG@_@LANGEN CTR",
    "CURRENT ATC UNIT@_@EDUW@_@RHEIN RADAR CTR",
    "CURRENT ATC UNIT@_@EDYC@_@MAASTRICHT CTR",
    "CURRENT ATC UNIT@_@EDYJ@_@MAASTRICHT CTR",
    "CURRENT ATC UNIT@_@EFIN@_@HELSINKI CTL",
    "CURRENT ATC UNIT@_@EGPX",
    "CURRENT ATC UNIT@_@EGPX@_@SCOTTISH CONTROL",
    "CURRENT ATC UNIT@_@EGPX@_@SCOTTISH CTL",
    "CURRENT ATC UNIT@_@EISE@_@SHANNON CTL",
    "CURRENT ATC UNIT@_@EKCH",
    "CURRENT ATC UNIT@_@EKCH1",
    "CURRENT ATC UNIT@_@EKCH2",
    "CURRENT ATC UNIT@_@EKDB@_@COPENHAGEN CTL",
    "CURRENT ATC UNIT@_@EPWW@_@WARSZAWA RADAR",
    "CURRENT ATC UNIT@_@ESOS@_@SWEDEN CTL",
    "CURRENT ATC UNIT@_@EUWN",
    "CURRENT ATC UNIT@_@LGGG@_@ATHINAI",
    "CURRENT ATC UNIT@_@LONC@_@LONDON CTL",
    "CURRENT ATC UNIT@_@LONE@_@LONDON CTL",
    "CURRENT ATC UNIT@_@LONM@_@LONDON CTL",
    "CURRENT ATC UNIT@_@LONN@_@LONDON CTL",
    "CURRENT ATC UNIT@_@LONS@_@LONDON CTL",
    "CURRENT ATC UNIT@_@LOVE@_@WIEN",
    "CURRENT ATC UNIT@_@LPZE@_@LISBOA CTL",
    "CURRENT ATC UNIT@_@LPZW@_@LISBOA CTL",
    "CURRENT ATC UNIT@_@LTBB@_@ANKARA CTR",
    "DESCEND TO @12000 FT",
    "DESCEND TO @3000 FT",
    "DESCEND TO @4000 FT",
    "DESCEND TO AND MAINTAIN @FL200@",
    "DESCEND TO @FL080",
    "DESCEND TO @FL100",
    "DESCEND TO @FL110",
    "DESCEND TO @FL110@",
    "DESCEND TO @FL120",
    "DESCEND TO @FL140",
    "DESCEND TO @FL180",
    "DESCEND TO @FL200",
    "DESCEND TO @FL210",
    "DESCEND TO @FL250",
    "DESCEND TO @FL260",
    "DESCEND TO @FL280",
    "DESCEND TO @FL290",
    "DESCEND TO @FL300",
    "DESCEND TO @FL320",
    "DESCEND TO @FL330",
    "DESCEND TO @FL340",
    "DESCEND TO @FL350",
    "DESCEND TO REACH @FL190@ BY @DJL@",
    "DESCENT FL100",
    "DOWNLINK REJECTED - @USE VOICE",
    "ERROR @REVERT TO VOICE PROCEDURES",
    "FLIGHT PLAN NOT HELD",
    "FLY HEADING @120",
    "FREE SPEED",
    "FSM 1133 230123 EDVK @AIB1010@ RCD REJECTED @TYPE MISMATCH @UPDATE RCD AND RESEND",
    "FSM 1140 230123 EDVK @AIB1010@ RCD REJECTED @REVERT TO VOICE PROCEDURES",
    "FSM 1337 230122 EDDK @WAT585@ RCD RECEIVED @REQUEST BEING PROCESSED @STANDBY",
    "FSM 1648 230122 EDDM @DLH09W@ RCD RECEIVED @REQUEST BEING PROCESSED @STANDBY",
    "HANDOVER @EDGD",
    "HANDOVER @EGPX",
    "INCREASE SPEED TO @250 KTS",
    "INCREASE SPEED TO @M.74",
    "LEAVING AIRSPACE MONITOR UNICOM 122.8",
    "LOGOFF",
    "LOGON ACCEPTED",
    "MAINTAIN @210 KTS",
    "MAINTAIN @FL100",
    "MAINTAIN @FL280",
    "MAINTAIN @M.72",
    "MAINTAIN @M.75",
    "MAINTAIN @M77@",
    "MESSAGE NOT SUPPORTED BY THIS ATS UNIT",
    "MONITOR @UNICOM@ @122.8@",
    "MONITOR UNICOM 122.8",
    "MONITOR UNICOM @122.800@",
    "MONITOR UNICOM 122.800",
    "MONITOR UNICOM 122.8 BYE",
    "MONITOR UNICOM 122.8. NICE DAY",
    "NEXT DATA AUTHORITY @EKCH2@",
    "OCEAN REQUEST ENTRY POINT: BALIX AT:1431 REQ: M.78 FL360  BALIX 61N014W EXIT",
    "PLS CONTACT ME BY QQ",
    "POSITION AM059 AT 1638 FL 85M EST RINIS AT 1656 NEXT IDESI",
    "PROCEED DIRECT TO @AHVEC@",
    "PROCEED DIRECT TO @HELEN@ DESCEND TO @FL200",
    "REDUCE SPEED TO @M.77",
    "REQUEST 10000",
    "REQUEST AGAIN WITH NEXT UNIT",
    "REQUEST CLB TO 34000FT",
    "REQUEST CRUISE CLIMB TO FL380",
    "REQUEST DEPARTURE CLEARANCE",
    "REQUEST DIRECT TO@EVRIN",
    "REQUEST DIRECT TO HMM",
    "REQUEST DIR TO TOPTU",
    "REQUEST FL110",
    "REQUEST FL320 DUE TO WEATHER",
    "REQUEST FL360 DUE TO AIRCRAFT PERFORMANCE",
    "REQUEST KBOS-KORD KBOS.HYLND.CAM.PAYGE.Q822.FNT.WYNDE2.EMMMA.KORD",
    "REQUEST KMCI-KATL KMCI.KATL",
    "REQUEST LOGON",
    "REQUEST URB7A",
    "REQUEST VOICE CONTACT ON 126.425",
    "RESUME NORMAL SPEED",
    "REVERT TO VOICE",
    "ROGER",
    "SERVICE TERMINATED",
    "SERVICE TERMINATED FREQ CHG APPROVED",
    "SERVICE TERMINATED. MONITOR UNICOM 122.800",
    "SQUAWK @1000",
    "SQUAWK IDENT",
    "STANDBY",
    "STBY",
    "STDBY",
    "THANKS FOR USING MAASTRICHT CPDLC",
    "THANK YOU FOR USING CPDLC. BEST REGARDS FROM PLVACC.",
    "TIMEDOUT RESEND REQUEST OR REVERT TO VOICE",
    "UNABLE",
    "UNABLE AT EGAA",
    "UNABLE DUE AIRSPACE",
    "UNABLE DUE TO AIRSPACE",
    "UNABLE DUE TRAFFIC",
    "UNABLE REVERT TO VOICE",
    "WHEN CAN WE EXPECT CLIMB TO CRZ ALT 32000",
    "WHEN CAN WE EXPECT HIGHER ALT",
    "WHEN CAN WE EXPECT LOWER ALT",
    "WHEN CAN WE EXPECT LOWER ALT AT PILOT DISCRETION",
    "WHEN READY DESCEND TO REACH FL250 AT RIMET",
    "WILCO",
    "YOU ARE LEAVING MY AIRSPACE NO FURTHER ATC MONITOR UNICOM 122.800 BYE BYE",
];

var testCases = [
    [ "down", "REQUEST LOGON", [{type: 'HPPD-1', args: []}] ],
    [ "up", "LOGON ACCEPTED", [{type: 'HPPU-1', args: []}] ],
    [ "up", "PROCEED DIRECT TO SUGOL DESCEND TO FL70", [{type: 'RTEU-2', args: ['SUGOL']}, {type: 'LVLU-9', args: ['FL70']}] ],
    [ "up", "CLIMB TO REACH FL70 BEFORE TIME 2230", [{type: 'LVLU-12', args: ['FL70', '2230']}] ],
    [ "up", "CLIMB TO FL70 PROCEED DIRECT TO PAM", [{type: 'LVLU-6', args: ['FL70']}, {type: 'RTEU-2', args: ['PAM']}] ],
];

var runParserTests = func {
    var failed = 0;
    var succeeded = 0;
    var total = 0;
    var formatResult = func(results) {
        var strs = [];
        foreach (var result; results) {
            append(
                strs,
                sprintf('%s (%s)',
                    result.type, string.join(', ', result.args)));
        }
        return '[' ~ string.join('; ', strs) ~ ']';
    };
    foreach (var testCase; testCases) {
        var dir = testCase[0];
        var txt = testCase[1];
        var expected = testCase[2];
        var actual = matchMessages(txt, dir, '');
        var expectedStr = formatResult(expected);
        var actualStr = formatResult(actual);
        total += 1;
        if (actualStr == expectedStr) {
            succeeded += 1;
        }
        else {
            printf("FAIL: %s. Expected %s, but got %s",
                txt,
                expectedStr,
                actualStr);
            failed += 1;
        }
    }
    if (failed > 0) {
        printf("Parser tests: %i/%i FAILED", failed, total);
    }
    else {
        printf("Parser tests: %i/%i succeeded", succeeded, total);
    }
};

var runSmokeTests = func {
    var failed = 0;
    var succeeded = 0;
    var total = 0;
    foreach (var msg; smokeTestMessages) {
        var results = matchMessages(msg, 'any', '');
        total += 1;
        if (results == nil) {
            printf("FAIL: %s", msg);
            failed += 1;
        }
        else {
            succeeded += 1;
        }
    }
    if (failed > 0) {
        printf("Smoke tests: %i/%i FAILED", failed, total);
    }
    else {
        printf("Smoke tests: %i/%i succeeded", succeeded, total);
    }
};
