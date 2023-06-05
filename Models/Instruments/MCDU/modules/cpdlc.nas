var CPDLCDatalinkSetupModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(CPDLCDatalinkSetupModule, m.parents);
        m.loadOptions();
        return m;
    },

    loadOptions: func () {
        me.options = [];
        foreach (var k; globals.cpdlc.system.listDrivers()) {
            append(me.options, k);
        }
        # debug.dump(me.options);
    },

    getTitle: func () { return "DATALINK SETUP"; },
    getShortTitle: func () { return "DLK SETUP"; },

    activate: func () {
        me.loadOptions();
        me.loadPage(me.page);
    },

    getNumPages: func () {
        return math.ceil(size(me.options) / 5);
    },

    loadPageItems: func (n) {
        # debug.dump('LOAD PAGE', n);
        me.views = [];
        me.controllers = {};
        for (var i = 0; i < 5; i += 1) {
            if (i + n * 5 >= size(me.options)) break;
            var item = me.options[i + n * 5];
            append(me.views, StaticView.new(0, i * 2 + 2, left_triangle, mcdu_large | mcdu_white));
            append(me.views, StaticView.new(1, i * 2 + 2, item,
                (item == globals.cpdlc.system.getDriver()) ?
                    (mcdu_large | mcdu_green) :
                    mcdu_white));
            me.controllers['L' ~ (i + 1)] =
                (func (k) { return FuncController.new(func (owner, val) {
                    globals.cpdlc.system.setDriver(k);
                    owner.loadPage(owner.page);
                    owner.fullRedraw();
                    return nil;
                }); })(item);
        }
        if (me.ptitle != nil) {
            me.controllers["L6"] = SubmodeController.new("ret");
            append(me.views,
                 StaticView.new(0, 12, left_triangle ~ me.ptitle, mcdu_large));
        }
    },
};

var CPDLCLogModule = {
    new: func (mcdu, parentModule) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(CPDLCLogModule, m.parents);
        m.listener = nil;
        m.historyNode = props.globals.getNode('/cpdlc/history');
        return m;
    },

    getTitle: func () { return "ATC LOG"; },

    activate: func () {
        me.loadPage(me.page);
        me.timer = maketimer(1, me, func () {
            me.loadPage(me.page);
            me.fullRedraw();
        });
        me.timer.start();
    },

    deactivate: func () {
        if (me.timer != nil) {
            me.timer.stop();
            me.timer = nil;
        }
        me.unloadPage();
    },

    getNumPages: func () {
        var refs = props.globals.getNode('/cpdlc/history', 1).getChildren('item');
        return math.max(1, math.floor((size(refs) + 4) / 5));
    },

    loadPageItems: func (n) {
        var refs = props.globals.getNode('/cpdlc/history', 1).getChildren('item');
        me.views = [];
        me.controllers = {};
        var r = size(refs) - 1 - n * 5;
        var y = 1;
        for (var i = 0; i < 5; i += 1) {
            if (r < 0) break;
            var msgID = refs[r].getValue();
            var item = props.globals.getNode('/cpdlc/messages/' ~ msgID);
            if (item == nil) {
                continue;
            }
            var msg = cpdlc.Message.fromNode(item);
            var dir = msg.dir;
            # debug.dump(item, msg);
            var summary = cpdlc.formatMessage(msg.parts);
            if (size(summary) > 22) {
                summary = substr(summary, 0, 20) ~ '..';
            }
            append(me.views,
                StaticView.new(1, y, sprintf("%04sZ", item.getValue('timestamp') or '----'), mcdu_white));
            var flags = mcdu_white;
            var status = item.getValue('status') or '';
            if (status == 'NEW')
                flags = mcdu_white | mcdu_reverse;
            if (status == 'SENT')
                statusText = item.getValue('response-status') or 'OLD';
            else
                statusText = status or 'OLD';
            append(me.views,
                StaticView.new(23 - size(statusText), y, statusText, flags));
            if (dir != 'pseudo') {
                append(me.views,
                    StaticView.new(0, y+1, (dir == 'up') ? '↑' : '↓', mcdu_white | mcdu_large));
            }
            append(me.views,
                StaticView.new(1, y+1, summary,
                    ((dir == 'up') ? mcdu_green : (dir == 'pseudo' ? mcdu_white : mcdu_blue)) | mcdu_large));
            append(me.views,
                StaticView.new(23, y+1, right_triangle, mcdu_white | mcdu_large));
            var lsk = 'R' ~ (i + 1);
            me.controllers[lsk] = (func(mid) {
                return SubmodeController.new(func (owner, parent) {
                    return CPDLCMessageModule.new(owner, parent, mid);
                });
            })(msgID);
            r -= 1;
            y += 2;
        }
        append(me.views, StaticView.new( 0, 12, left_triangle ~ "ATC INDEX", mcdu_white | mcdu_large));
        append(me.views, StaticView.new(14, 12, "CLEAR LOG" ~ right_triangle, mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ret");
        me.controllers['R6'] = FuncController.new(func (owner, val) {
            globals.cpdlc.system.clearHistory();
            return nil;
        });
    },
};

var CPDLCComposeDownlinkModule = {
    new: func (mcdu, parentModule, parts, mrn = nil, to = nil) {
        # debug.dump(parts);
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(CPDLCComposeDownlinkModule, m.parents);
        m.parts = parts;
        m.mrn = mrn;
        m.makeElems();
        m.dir = 'down';
        m.makePages();
        if (mrn != nil) {
            m.ptitle = 'UPLINK';
        }
        elsif (parentModule != nil) {
            m.ptitle = parentModule.getTitle();
        }
        m.to = to;
        return m;
    },

    makeElems: func () {
        # debug.dump(me.parts);
        me.elems = cpdlc.formatMessageFancy(me.parts);
        # debug.dump('makeElems:', me.parts, me.elems);
    },

    getTitle: func () {
        if (me.mrn == nil)
            return "VERIFY REQUEST";
        else
            return "VERIFY RESPONSE";
    },

    getShortTitle: func () {
        if (me.mrn == nil)
            return "VER REQUEST";
        else
            return "VER RESPONSE";
    },

    getNumPages: func () {
        return size(me.pages);
    },

    loadPageItems: func (n) {
        var self = me;

        if (n < size(me.pages)) {
            me.views = me.pages[n].views;
            me.controllers = me.pages[n].controllers;
        }
        else {
            me.views = [];
            me.controllers = {};
        }

        append(me.views, StaticView.new( 0, 12, left_triangle ~ me.ptitle, mcdu_white | mcdu_large));
        append(me.views, StaticView.new(19, 12, "SEND" ~ right_triangle, mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ret");
        me.controllers['R6'] = FuncController.new(func (owner, val) {
                                    var msg = globals.cpdlc.Message.new();
                                    msg.mrn = self.mrn;
                                    msg.parts = [];
                                    foreach (var part; self.parts) {
                                        # don't send empty text parts
                                        if ((substr(part.type, 0, 3) == 'TXT' or
                                             substr(part.type, 0, 3) == 'SUP') and
                                            (size(part.args) == 0 or
                                             part.args[0] == nil or
                                             part.args[0] == ''))
                                            continue;
                                        append(msg.parts, part);
                                    }
                                    msg.dir = 'down';
                                    msg.to = owner.to;
                                    var mid = globals.cpdlc.system.send(msg);
                                    if (mid != nil) owner.ret();
                                });
    },

    makePages: func () {
        var y = 1;
        me.pages = [];
        var views = [];
        var controllers = {};
        var nextPage = func () {
            append(me.pages, { 'views': views, 'controllers': controllers });
            y = 1;
            views = [];
            controllers = {};
        };
        var nextLine = func(limit=10) {
            y += 1;
            if (y > limit) {
                nextPage();
            }
        };
        var evenLine = func(limit=10) {
            if (y > limit) {
                nextPage();
                evenLine();
            }
            elsif (y & 1) {
                nextLine(limit);
            }
        };
        var unevenLine = func(limit=10) {
            if (y > limit) {
                nextPage();
                unevenLine();
            }
            elsif (!(y & 1)) {
                nextLine(limit);
            }
        };
        var lsk = func(which) {
            var i = math.floor((y + 1) / 2);
            return which ~ i;
        };

        var color = mcdu_white;
        var lineSel = unevenLine;
        var partIndex = 0;

        foreach (var part; me.elems) {
            var first = 1;
            var argIndex = 0;
            foreach (var elem; part) {
                var val = elem.value;
                if (first) {
                    first = 0;
                    if (elem.type == 0) {
                        val = '/' ~ val;
                    }
                    else {
                        unevenLine();
                        append(views, StaticView.new(0, y, '/', mcdu_white));
                        nextLine();
                    }
                }

                if (elem.type == 0) {
                    lineSel = unevenLine;
                    color = mcdu_white;
                }
                else {
                    lineSel = evenLine;
                    color = mcdu_green | mcdu_large;
                }

                var words = split(' ', val);
                var line = '';
                lineSel();
                if (elem.type != 0) {
                    controllers[lsk('L')] = (func(partIndex, argIndex) { return FuncController.new(
                        func (owner, val) {
                            printf('parts[%i].args[%i] := %s', partIndex, argIndex, val);
                            owner.parts[partIndex].args[argIndex] = val;
                            owner.makeElems();
                            owner.makePages();
                            owner.loadPage(owner.page);
                            owner.fullRedraw();
                            return val;
                        },
                        func (owner) {
                            printf('parts[%i].args[%i] := %s', partIndex, argIndex, nil);
                            owner.parts[partIndex].args[argIndex] = nil;
                            owner.makeElems();
                            owner.makePages();
                            owner.loadPage(owner.page);
                            owner.fullRedraw();
                        },
                    ); })(partIndex, argIndex);
                    argIndex += 1;
                }
                foreach (var word; words) {
                    if (size(line) == 0) {
                        while (size(word) > 24) {
                            lineSel();
                            append(views, StaticView.new(0, y, substr(word, 0, 22) ~ '..', color));
                            nextLine();
                            word = substr(word, 22);
                        }
                        line = word;
                    }
                    else {
                        if (size(line) + 1 + size(word) > 24) {
                            lineSel();
                            append(views, StaticView.new(0, y, line, color));
                            nextLine();
                            line = word;
                        }
                        else {
                            line = line ~ ' ' ~ word;
                        }
                    }
                }
                if (size(line) > 0) {
                    lineSel();
                    append(views, StaticView.new(0, y, line, color));
                    nextLine();
                }
            }
            partIndex += 1;
        }

        if (size(views))
            nextPage();
    },
};

var CPDLCMessageModule = {
    new: func (mcdu, parentModule, msgID) {
        var m = BaseModule.new(mcdu, parentModule);
        m.parents = prepended(CPDLCMessageModule, m.parents);
        m.msgID = msgID;
        m.loadMessage();
        return m;
    },

    activate: func () {
        if (me.msgID == '') {
            me.mcdu.popModule();
            return;
        }
        me.loadPage(me.page);
        me.timer = maketimer(1, me, func () {
            me.loadMessage();
            me.loadPage(me.page);
            me.fullRedraw();
        });
        me.timer.start();
    },

    deactivate: func () {
        if (me.timer != nil) {
            me.timer.stop();
            me.timer = nil;
        }
        me.unloadPage();
    },


    loadMessage: func () {
        var messageNode = props.globals.getNode('/cpdlc/messages/' ~ me.msgID);
        if (messageNode == nil) {
            me.elems = [];
            me.dir = 'up';
            me.status = 'INVALID';
            me.station = '----';
            me.timestamp = '----';
            me.ra = nil;
            me.replies = [];
            me.replyTimestamp = nil;
            me.replyID = nil;
            me.parentTimestamp = nil;
            me.parentID = nil;
            me.min = nil;
            me.pages = [];
            me.parts = [];
            me.message = nil;
        }
        else {
            me.message = cpdlc.Message.fromNode(messageNode);
            me.elems = cpdlc.formatMessageFancy(me.message.parts);
            me.dir = me.message.dir;
            me.status = me.message['status'] or 'OLD';
            me.station = (me.dir == 'down') ? me.message.to : me.message.from;
            me.timestamp = messageNode.getValue('timestamp');
            me.parts = me.message.parts;

            # Mark as read *after* loading the message, so that the status
            # still shows as 'NEW'
            cpdlc.system.markMessageRead(me.msgID);

            var replyID = messageNode.getValue('reply');
            var replyNode = (replyID == nil) ? nil : props.globals.getNode('/cpdlc/messages/' ~ replyID);
            if (replyNode == nil) {
                me.replyID = nil;
                me.replyTimestamp = nil;
            }
            else {
                me.replyID = replyID;
                me.replyTimestamp = replyNode.getValue('timestamp');
            }
            var parentID = messageNode.getValue('parent');
            var parentNode = (parentID == nil) ? nil : props.globals.getNode('/cpdlc/messages/' ~ parentID);
            if (parentNode == nil) {
                me.parentID = nil;
                me.parentTimestamp = nil;
            }
            else {
                me.parentID = parentID;
                me.parentTimestamp = parentNode.getValue('timestamp');
            }

            if (me.dir == 'up') {
                me.ra = me.message.getRA() or '';
                me.replies = [];
                var ty = cpdlc.uplink_messages[me.message.parts[0].type];
                if (ty != nil and ty['replies'] != nil) {
                    me.replies = ty['replies'];
                }
            }
            else {
                me.ra = '';
            }
            me.min = me.message.min;
            me.makePages();
        }
    },

    printMessage: func {
        if (me.message == nil) return;
        var msgTxt = cpdlc.formatMessage(me.message.parts);
        var lines =
                [ "--- CPDLC BEGIN ---"
                , sprintf("%02u:%02u %s %s",
                    substr(me.message.timestamp, 0, 2),
                    substr(me.message.timestamp, 2, 2),
                    me.message.from,
                    me.message.to)
                , ''
                ] ~
                lineWrap(msgTxt, printer.paperWidth, '...') ~
                [ "--- CPDLC END ---"
                , ''
                ];
        printer.newJob(lines);
    },

    makePages: func () {
        var self = me;
        var y = 1;
        me.pages = [];
        var views = [];
        var controllers = {};
        var nextPage = func () {
            append(me.pages, { 'views': views, 'controllers': controllers });
            y = 1;
            views = [];
            controllers = {};
        };
        var nextLine = func(limit=10) {
            y += 1;
            if (y > limit) {
                nextPage();
            }
        };
        var evenLine = func(limit=10) {
            if (y > limit) {
                nextPage();
                evenLine();
            }
            elsif (y & 1) {
                nextLine(limit);
            }
        };
        var unevenLine = func(limit=10) {
            if (y > limit) {
                nextPage();
                unevenLine();
            }
            elsif (!(y & 1)) {
                nextLine(limit);
            }
        };
        var lsk = func(which) {
            var i = math.floor((y + 1) / 2);
            return which ~ i;
        };

        unevenLine();
        append(views, StaticView.new(1, y, me.station, mcdu_green));
        append(views, StaticView.new(12, y, sprintf("%11s", me.status or 'OLD'), mcdu_green | mcdu_large));
        nextLine();

        evenLine();
        if (me.dir != 'pseudo') {
            if (me.replyID != nil and me.dir == 'down') {
                append(views, StaticView.new(0, y, left_triangle ~ "UPLINK", mcdu_white | mcdu_large));
                controllers[lsk('L')] = (func(mid) {
                        return SubmodeController.new(func (owner, parent) {
                            return CPDLCMessageModule.new(owner, parent, mid);
                        }, 2);
                })(me.replyID);
            }
            elsif (me.parentID != nil) {
                append(views, StaticView.new(0, y, left_triangle ~ "REQUEST", mcdu_white | mcdu_large));
                controllers[lsk('L')] = (func(mid) {
                        return SubmodeController.new(func (owner, parent) {
                            return CPDLCMessageModule.new(owner, parent, mid);
                        }, 2);
                })(me.parentID);
            }
            elsif (me.replyID != nil and me.dir == 'up') {
                append(views, StaticView.new(0, y, left_triangle ~ "RESPONSE", mcdu_white | mcdu_large));
                controllers[lsk('L')] = (func(mid) {
                        return SubmodeController.new(func (owner, parent) {
                            return CPDLCMessageModule.new(owner, parent, mid);
                        }, 2);
                })(me.replyID);
            }
            nextLine();
        }

        var color = mcdu_white;
        var lineSel = unevenLine;

        var first = 0;
        foreach (var part; me.elems) {
            foreach (var elem; part) {
                var val = elem.value;
                if (first) {
                    first = 0;
                    if (elem.type != 0) {
                        unevenLine();
                        append(views, StaticView.new(0, y, '/', mcdu_white));
                        nextLine();
                    }
                    else {
                        val = '/' ~ val;
                    }
                }

                if (elem.type == 0) {
                    lineSel = unevenLine;
                    color = mcdu_white;
                }
                else {
                    lineSel = evenLine;
                    color = mcdu_green | mcdu_large;
                }

                if (val == '') val = '----------------';
                var words = split(' ', val);
                var line = '';
                lineSel();
                foreach (var word; words) {
                    if (size(line) == 0) {
                        while (size(word) > 24) {
                            append(views, StaticView.new(0, y, substr(word, 0, 22) ~ '..', color));
                            nextLine();
                            word = substr(word, 22);
                        }
                        line = word;
                    }
                    else {
                        if (size(line) + 1 + size(word) > 24) {
                            append(views, StaticView.new(0, y, line, color));
                            nextLine();
                            line = word;
                        }
                        else {
                            line = line ~ ' ' ~ word;
                        }
                    }
                }
                if (size(line) > 0) {
                    append(views, StaticView.new(0, y, line, color));
                    nextLine();
                }
            }
            first = 1;
        }

        evenLine();
        if (me.replyID != nil and me.dir == 'down') {
            append(views, StaticView.new( 0, y, ">>>> RESPONSE ", mcdu_white | mcdu_large));
            append(views, StaticView.new(14, y, me.replyTimestamp, mcdu_green | mcdu_large));
            append(views, StaticView.new(18, y, "Z", mcdu_green));
            append(views, StaticView.new(19, y, " <<<<", mcdu_white | mcdu_large));
        }
        nextLine();

        if (me.ra != '' and me.status == 'OPEN') {
            evenLine(8);
            # The RA page
            if (me.ra == 'R') {
                append(views, StaticView.new( 0, y, left_triangle ~ 'UNABLE     ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-2', args: []}
                            , {type: 'SUPD-1', args: ['']}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                append(views, StaticView.new(12, y, '      ROGER' ~ right_triangle, mcdu_white));
                controllers[lsk('R')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-4', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                nextLine(); evenLine();
                append(views, StaticView.new( 0, y, left_triangle ~ 'STAND BY   ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-3', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });
            }
            elsif (me.ra == 'WU') {
                append(views, StaticView.new( 0, y, left_triangle ~ 'UNABLE     ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-2', args: []}
                            , {type: 'SUPD-1', args: ['']}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                append(views, StaticView.new(12, y, '      WILCO' ~ right_triangle, mcdu_white));
                controllers[lsk('R')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-1', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                nextLine(); evenLine();
                append(views, StaticView.new( 0, y, left_triangle ~ 'STAND BY   ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-3', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });
            }
            elsif (me.ra == 'AN') {
                append(views, StaticView.new( 0, y, left_triangle ~ 'NEGATIVE   ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-6', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                append(views, StaticView.new(12, y, 'AFFIRMATIVE' ~ right_triangle, mcdu_white));
                controllers[lsk('R')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-5', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });

                nextLine(); evenLine();
                append(views, StaticView.new( 0, y, left_triangle ~ 'STAND BY   ', mcdu_white));
                controllers[lsk('L')] =
                    SubmodeController.new(func (owner, parent) {
                        return CPDLCComposeDownlinkModule.new(owner, parent,
                            [ {type: 'RSPD-3', args: []}
                            , {type: 'TXTD-1', args: ['']}
                            ],
                            self.min,
                            self.station);
                    });
            }
            elsif (me.ra == 'Y') {
                var left = 1;
                foreach (var reply; me.replies ~ [{type:'TXTD-1'}]) {
                    var replySpec = cpdlc.downlink_messages[reply.type];
                    if (replySpec == nil) continue;
                    var words = [];
                    if (reply.type == 'TXTD-1')
                        words = ['FREE', 'TEXT'];
                    else
                        words = split(' ', replySpec.txt);
                    var title = '';
                    foreach (var word; words) {
                        if (title != '')
                            title = title ~ ' ';
                        if (word[0] == '$')
                            word = '..';
                        if (size(title) + size(word) > 10) {
                            if (title == '')
                                title = substr(word, 0, 8) ~ '..';
                            break;
                        }
                        title = title ~ word;
                    }
                    var args = [];
                    if (reply['args'] == nil) {
                        foreach (var a; replySpec.args) {
                            append(args, '');
                        }
                    }
                    else {
                        foreach (var dnarg; reply.args) {
                            var a = dnarg;
                            var i = 1;
                            foreach (var uparg; me.parts[0].args) {
                                a = string.replace(a, '$' ~ i, uparg);
                                i += 1;
                            }
                            append(args, a);
                        }
                    }
                    var ctrl = (func (reply, args) { return SubmodeController.new(func (owner, parent) {
                            var parts = [{type: reply.type, args: args}];
                            if (substr(reply.type, 0, 3) != 'TXT')
                                append(parts, {type: 'TXTD-1', args: ['']});
                            return CPDLCComposeDownlinkModule.new(owner, parent, parts, self.min, self.station);
                        }); })(reply, args);
                    if (left) {
                        append(views, StaticView.new( 0, y, left_triangle ~ title, mcdu_white));
                        controllers[lsk('L')] = ctrl;
                        left = 0;
                    }
                    else {
                        append(views, StaticView.new(12, y, sprintf("%11s", title) ~ right_triangle, mcdu_white));
                        controllers[lsk('R')] = ctrl;
                        left = 1;
                        nextLine();
                    }
                }
            }
            # append(views, StaticView.new(12, y, '      APPLY' ~ right_triangle, mcdu_white));
            # nextLine();
        }

        unevenLine();
        evenLine();
        append(views, StaticView.new(12, y, sprintf("%11s", 'PRINT') ~ right_triangle, mcdu_white));
        controllers[lsk('R')] = FuncController.new(func (owner, val) { return owner.printMessage(); });

        if (size(views))
            nextPage();
    },

    getTitle: func () {
        # spaces left to fit green timestamp
        if (me.dir == 'up') {
            return "        ATC UPLINK";
        }
        elsif (me.dir == 'pseudo') {
            return "        SYS MSG   ";
        }
        else {
            return "        REQUEST   ";
        }
    },

    getShortTitle: func () {
        if (me.dir == 'up') {
            return "ATC UPLINK";
        }
        elsif (me.dir == 'pseudo') {
            return "SYS MSG";
        }
        else {
            return "REQUEST";
        }
    },

    getNumPages: func () {
        return size(me.pages);
    },

    loadPageItems: func (n) {
        if (n < size(me.pages)) {
            me.views = me.pages[n].views;
            me.controllers = me.pages[n].controllers;
        }
        else {
            me.views = [];
            me.controllers = {};
        }

        append(me.views, StaticView.new(3, 0, me.timestamp or '----', mcdu_green | mcdu_large));
        append(me.views, StaticView.new(7, 0, 'Z', mcdu_green));
        append(me.views, StaticView.new( 0, 12, left_triangle ~ "ATC INDEX", mcdu_white | mcdu_large));
        me.controllers['L6'] = SubmodeController.new("ATCINDEX", 0);
        if (me.ptitle != nil) {
            me.controllers["R6"] = SubmodeController.new("ret");
            append(me.views,
                 StaticView.new(23 - size(me.ptitle), 12, me.ptitle ~ right_triangle, mcdu_large));
        }
    },
};


