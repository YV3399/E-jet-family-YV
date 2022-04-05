# IRC-CPDLC driver.
#
# This driver connects to mpirc.flightgear.org using FG's built-in CPDLC API.
var IRCDriver = {
    new: func (system) {
        var m = BaseDriver.new(system);
        m.parents = [IRCDriver] ~ m.parents;
        m.onlineListener = nil;
        m.dataAuthorityListener = nil;
        m.rxListener = nil;
        m.nextUplinkMIN = 1;
        m.openDownlinks = [];
        m.props = {
            online: props.globals.getNode('sim/multiplay/online', 1),
            dataAuthority: props.globals.getNode('network/cpdlc/link/data-authority', 1),
            newMessage: props.globals.getNode('network/cpdlc/rx/new-message', 1),
            rxMessage: props.globals.getNode('network/cpdlc/rx/message', 1),
        };
        return m;
    },

    getDriverName: func () { return 'FGMP'; },

    isAvailable: func () {
        return me.props.online.getBoolValue();
    },

    start: func () {
        var self = me;
        me.dataAuthorityListener = setlistener(me.props.dataAuthority, func(node) {
            var dataAuthority = node.getValue();
            me.system.setCurrentStation(dataAuthority);
        }, 1, 0);
        me.onlineListener = setlistener(me.props.online, func(node){
                var online = node.getBoolValue();
                if (online) {
                    if (self.rxListener == nil) {
                        self.rxListener = setlistener(self.props.newMessage, func (node) {
                            if (node.getBoolValue()) {
                                fgcommand('cpdlc-next-message');
                                self.receive(self.props.rxMessage.getValue());
                            }
                        }, 1, 1);
                    }
                }
            }, 1, 0);
    },

    stop: func () {
        me.disconnect();
        if (me.onlineListener != nil) {
            removelistener(me.onlineListener);
            me.onlineListener = nil;
        }
        if (me.rxListener != nil) {
            removelistener(me.rxListener);
            me.rxListener = nil;
        }
        if (me.dataAuthorityListener != nil) {
            removelistener(me.dataAuthorityListener);
            me.dataAuthorityListener = nil;
        }
    },

    connect: func (logonStation) {
        if (logonStation == '') return;
        fgcommand('cpdlc-connect', {'atc': logonStation});
    },

    disconnect: func () {
        fgcommand('cpdlc-disconnect');
    },

    send: func (msg) {
        var encodedParts = [];
        var type = nil;
        var args = nil;
        var first = 1;
        foreach (var part; msg.parts) {
            if (first) {
                first = 0;
            }
            else {
                # skip empty text or supplement parts
                if ((substr(part.type, 0, 3) == 'TXT' or substr(part.type, 0, 3) == 'SUP') and
                        part.args != [] and
                        (part.args[0] == nil or part.args[0] == ''))
                    continue;
            }
            append(encodedParts, part.type ~ ' ' ~ string.join(' ', part.args or []));
        }
        fgcommand('cpdlc-send', { 'message': string.join('|', encodedParts) });
        if (msg.getRA() == 'Y') {
            append(me.openDownlinks, msg.min);
        }
        me.system.markMessageSent(msg.getMID());
    },

    receive: func (rawMessage) {
        printf('Received message: %s', rawMessage);

        var msg = Message.new();

        # IRC-CPDLC does not support MIN/MRN, so we fake it.
        # - We assign sequential MINs for uplink messages ourselves
        msg.min = me.nextUplinkMIN;
        me.nextUplinkMIN += 1;

        # - We assume that uplink messages are always in reference to the last
        #   downlink we sent that has RA='Y'.
        msg.mrn = pop(me.openDownlinks);
        msg.dir = 'up';
        msg.valid = 1;
        msg.from = me.system.getCurrentStation();
        msg.to = getprop('/sim/multiplay/callsign');

        msg.parts = [];
        var partsRaw = split('|', rawMessage);
        foreach (var partRaw; partsRaw) {
            var tokens = split(' ', partRaw);
            var type = tokens[0];
            var args = [];

            if (contains(uplink_messages, type)) {
                if (substr(type, 0, 4) == 'TXTU') {
                    args = [string.join(' ', subvec(tokens, 1))];
                }
                else {
                    if (size(tokens) - 1 != size(uplink_messages[type].args))
                        msg.valid = 0;
                    args = subvec(tokens, 1);
                }
            }
            else {
                msg.valid = 0;
                args = subvec(tokens, 1);
            }
            append(msg.parts, { type: type, args: args });
        }
        me.system.receive(msg);
    },
};
