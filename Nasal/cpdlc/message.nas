var Message = {
    new: func () {
        var m = {
            parents: [Message],
            timestamp: nil,
            min: 0,
            mrn: nil,
            parts: [],
            to: '',
            from: '',
            dir: 'down',
            valid: 0,
            status: '',
        };
        return m;
    },

    fromNode: func (node) {
        var vals = node.getValues();
        if (typeof(vals.parts) != 'vector') vals.parts = [vals.parts];
        foreach (var part; vals.parts) {
            if (typeof(part.args) != 'vector') part.args = [part.args];
        }
        var msg = Message.new();
        foreach (var k; keys(msg)) {
            if (k != 'parents' and contains(vals, k)) {
                msg[k] = vals[k];
            }
        }
        return msg;
    },

    toNode: func (node=nil) {
        if (node == nil)
            node = props.Node.new(me.dir ~ me.min);
        node.removeAllChildren();
        node.setValues(me);
        # foreach (var k; keys(me)) {
        #     debug.dump(k, me[k]);
        #     node.setValue(k, me[k]);
        # }
        node.setValue('ra', me.getRA());
        return node;
    },

    getMessageType: func (partIndex=0) {
        var type = me.parts[partIndex].type;
        if (me.dir == 'up' and contains(uplink_messages, type))
            return uplink_messages[type];
        elsif (me.dir == 'down' and contains(downlink_messages, type))
            return downlink_messages[type];
        else
            return nil;
    },

    getRA: func () {
        var messageType = me.getMessageType();
        if (messageType == nil) return '';
        return string.uc(string.join('', messageType.r_opts));
    },

    getMID: func {
        return me.dir ~ me.min;
    },
};
