include('apps/base.nas');

var PaperworkApp = {
    new: func(masterGroup) {
        var m = BaseApp.new(masterGroup);
        m.parents = [me] ~ m.parents;
        m.ofp = nil;
        m.pages = [];
        return m;
    },

    handleBack: func () {
    },

    initialize: func () {
        me.metrics = {
            pageWidth: 414,
            pageHeight: 670,
            fontSize: 10,
            charWidth: 5.935,
            lineHeight: 10.5,
            headerHeight: 22,
            rows: 61,
            columns: 68,
        };
        me.metrics.marginLeft = (512 - me.metrics.pageWidth) / 2;
        me.metrics.marginTop = (738 - me.metrics.pageHeight) / 2;
        me.metrics.paddingTop = (me.metrics.pageHeight - me.metrics.headerHeight - me.metrics.lineHeight * me.metrics.rows) / 2;
        me.metrics.paddingLeft = (me.metrics.pageWidth - me.metrics.charWidth * me.metrics.columns) / 2;

        me.simbriefUsernameProp = props.globals.getNode('/sim/simbrief/username');
        me.bgfill = me.masterGroup.createChild('path')
                        .rect(0, 0, 512, 768)
                        .setColorFill(0.8, 0.9, 1.0);
        me.contentGroup = me.masterGroup.createChild('group');
        me.loadSimbriefOFP();
        me.renderOFP();
    },

    loadSimbriefOFP: func () {
        var filename = getprop('/sim/fg-home') ~ "/Export/simbrief.xml";
        me.ofp = io.readxml(filename);
        if (me.ofp == nil) {
            me.ofp = props.Node.new();
        }
    },

    getOFPValue: func(path) {
        return me.ofp.getValue('OFP/' ~ path);
    },

    getOFPValues: func(path, subkey=nil) {
        var node = me.ofp.getNode('OFP/' ~ path);
        if (node == nil)
            return nil;
        var val = node.getValues();
        if (val == nil)
            return nil;
        if (subkey != nil) {
            if (!contains(val, subkey))
                val = nil;
            else
                val = val[subkey];
        }
        if (typeof(val) == 'scalar')
            val = [val];
        return val;
    },

    collectOFPItems: func () {
        var items = [];
        var newline = func () {
            append(items, { type: 'blank' });
        };
        var plain = func (text, centerW=0) {
            if (centerW > 0) {
                var paddingSize = math.floor((centerW - size(text)) / 2);
                var padding = substr('                                                                    ', 0, paddingSize);
                text = padding ~ text;
            }
            append(items, { type: 'text', text: text });
        };
        var pageBreak = func () {
            append(items, { type: 'page-break' });
        };
        var separator = func (length=nil) {
            if (length == nil)
                length = me.metrics.columns;
            append(items, { type: 'separator', length: length });
        };
        var format = func (fmt, args) {
            append(items, { type: 'formatted', format: fmt, args: args });
        };
        var toc = func (title) {
            append(items, { type: 'toc-entry', title: title });
        };
        var multi = func (subItems) {
            append(items, { type: 'multi', items: subItems });
        };
        var subText = func (x, w, text) {
            return {
                x: x,
                w: w,
                type: 'text',
                text: text
            };
        };
        var subFmt = func (x, w, fmt, args) {
            return {
                x: x,
                w: w,
                type: 'formatted',
                format: fmt,
                args: args
            };
        };
        var subEntry = func (x, w, path, validate=nil) {
            return {
                x: x,
                w: w,
                type: 'entry',
                path: path,
                validate: validate,
            };
        };

        # for (var i = 1; i <= me.metrics.rows; i += 1) {
        #     plain(sprintf('--- TEST LINE %2i ---', i), me.metrics.columns);
        # }
        # pageBreak();

        plain('[ OFP ]');
        separator();

        var generated = unixToDateTime(me.getOFPValue('params/time_generated'));
        var schedOut = unixToDateTime(me.getOFPValue('times/sched_out'));
        var schedOff = unixToDateTime(me.getOFPValue('times/sched_off'));
        var schedOn = unixToDateTime(me.getOFPValue('times/sched_on'));
        var schedIn = unixToDateTime(me.getOFPValue('times/sched_in'));
        var estOn = unixToDateTime(me.getOFPValue('times/est_on'));
        var estIn = unixToDateTime(me.getOFPValue('times/est_in'));
        # var schedOutLocal = unixToDateTime(me.getOFPValue('times/sched_out') + math.floor(me.getOFPValue('times/orig_timezone') * 3600));
        # var schedOffLocal = unixToDateTime(me.getOFPValue('times/sched_off') + math.floor(me.getOFPValue('times/orig_timezone') * 3600));
        # var schedOnLocal = unixToDateTime(me.getOFPValue('times/sched_on') + math.floor(me.getOFPValue('times/dest_timezone') * 3600));
        # var schedInLocal = unixToDateTime(me.getOFPValue('times/sched_in') + math.floor(me.getOFPValue('times/dest_timezone') * 3600));
        var isEtops = me.getOFPValue('general/is_etops');

        # Page 1

        toc('Summary and Fuel');
        format('%-3s%-6s %02i%3s%04i    %-4s-%-4s   %-4s %-7s RELEASE %02i%02i %02i%3s%02i',
            [ 'OFP:general/icao_airline'
            , 'OFP:general/flight_number'
            , schedOut.day, monthNames3[schedOut.month], schedOut.year
            , 'OFP:origin/icao_code'
            , 'OFP:destination/icao_code'
            , 'OFP:aircraft/icaocode'
            , 'OFP:aircraft/reg'
            , generated.hour, generated.minute
            , generated.day, monthNames3[generated.month], math.mod(generated.year, 100)
            ]);
        format('OFP %-3i         %s-%s',
            [ 'OFP:general/release'
            , 'OFP:origin/name'
            , 'OFP:destination/name'
            ]);
        newline(); # TODO: figure out the WX PROG ... OBS ... line
        newline();
        multi([
            subText(2, 7, "ATC C/S"),
            subFmt(12, 12, '%s', ['OFP:atc/callsign']),
            subFmt(25, 8, '%s/%s', ['OFP:origin/icao_code', 'OFP:origin/iata_code']),
            subFmt(36, 8, '%s/%s', ['OFP:destination/icao_code', 'OFP:destination/iata_code']),
            subText(50, 7, 'CRZ SYS'),
            subFmt(58, 10, '%10s', ['OFP:general/cruise_profile']),
        ]);
        multi([
            subFmt(0, 9, '%02i%s%4i', [ schedOut.day, monthNames3[schedOut.month], schedOut.year ]),
            subFmt(12, 12, '%s', ['OFP:aircraft/reg']),
            subFmt(25, 9, '%02i%02i/%02i%02i', [schedOut.hour, schedOut.minute, schedOff.hour, schedOff.minute]),
            subFmt(36, 9, '%02i%02i/%02i%02i', [estOn.hour, estOn.minute, estIn.hour, estIn.minute]),
            subText(50, 8, 'GND DIST'),
            subFmt(59, 9, '%9s', ['OFP:general/route_distance']),
        ]);
        multi([
            subFmt(0, 21, '%s / %s', [ 'OFP:aircraft/name', 'N/A' ]),
            subFmt(36, 9, 'STA  %02i%02i', [schedIn.hour, schedIn.minute]),
            subText(50, 8, 'AIR DIST'),
            subFmt(59, 9, '%9s', ['OFP:general/air_distance']),
        ]);
        multi([
            subText(25, 5, 'CTOT:'),
            subEntry(30, 4, 'OFP:times/ctot'),
            subText(50, 8, 'G/C DIST'),
            subFmt(59, 9, '%9s', ['OFP:general/gc_distance']),
        ]);
        multi([
            subText(50, 8, 'AVG WIND'),
            subFmt(61, 7, '%03i/%03i', ['OFP:general/avg_wind_dir', 'OFP:general/avg_wind_spd']),
        ]);
        multi([
            subFmt(0, 21, 'MAXIMUM    TOW %6i', [ 'OFP:weights/max_tow' ]),
            subFmt(23, 10, 'LAW %6i', [ 'OFP:weights/max_ldw' ]),
            subFmt(35, 10, 'ZFW %6i', [ 'OFP:weights/max_zfw' ]),
            subText(50, 8, 'AVG W/C'),
            subFmt(64, 4,formatPM(3), ['OFP:general/avg_wind_comp']),
        ]);
        multi([
            subFmt(0, 21, 'ESTIMATED  TOW %6i', [ 'OFP:weights/est_tow' ]),
            subFmt(23, 10, 'LAW %6i', [ 'OFP:weights/est_ldw' ]),
            subFmt(35, 10, 'ZFW %6i', [ 'OFP:weights/est_zfw' ]),
            subText(50, 8, 'AVG ISA'),
            subFmt(64, 4, formatPM(3), ['OFP:general/avg_temp_dev']),
        ]);
        multi([
            subText(50, 13, 'AVG FF KGS/HR'),
            subFmt(64, 4, '%4i', ['OFP:fuel/avg_fuel_flow']),
        ]);
        multi([
            subText(50, 13, 'FUEL BIAS'),
            subFmt(63, 5, formatPM(2,1), [0]),
        ]);
        multi([
            subFmt(0, 9, 'ALTN %-4s', ['OFP:alternate/icao_code']),
            subText(50, 9, 'TKOF ALTN'),
            subEntry(61, 7, 'OFP:takeoff_altn/icao_code')
        ]);
        multi([
            subText(0, 9, 'FL STEPS'),
            subFmt(10, 60, func(str) { str ~ '/'; }, ['OFP:general/stepclimb_string']),
        ]);
        separator();
        if (isEtops) {
            plain('*** ETOPS/ETP FLIGHT ***', me.metrics.columns);
            separator();
        }
        var remarks = (me.getOFPValues('general', 'dx_rmk') or []) ~
                      (me.getOFPValues('general', 'sys_rmk') or []);
        if (size(remarks) == 0)
            remarks = ['NIL'];
        var first = 1;
        foreach (var rmk; remarks) {
            multi([
                subText(0, 12, first ? 'DISP RMKS' : ''),
                subText(13, 56, rmk)
            ]);
            first = 0;
        }
        newline();
        separator();

        plain('PLANNED FUEL', 31);
        separator(31);
        multi([
            subText(0, 15, 'FUEL'),
            subText(13, 4, 'ARPT'),
            subText(20, 4, 'FUEL'),
            subText(27, 4, 'TIME'),
        ]);
        separator(31);
        multi([
            subText(0, 15, 'TRIP'),
            subFmt(13, 4, '%4s', ['OFP:origin/iata_code']),
            subFmt(19, 5, '%5s', ['OFP:fuel/enroute_burn']),
            subFmt(27, 4, formatFuelTime0202, ['OFP:fuel/avg_fuel_flow', 'OFP:fuel/enroute_burn']),
        ]);
        multi([
            subFmt(0, 18, 'CONT %s', ['OFP:general/cont_rule']),
            subFmt(19, 5, '%5s', ['OFP:fuel/contingency']),
            subFmt(27, 4, formatSeconds0202, ['OFP:times/contfuel_time']),
        ]);
        multi([
            subText(0, 15, 'ALTN'),
            subFmt(13, 4, '%4s', ['OFP:alternate/iata_code']),
            subFmt(19, 5, '%5s', ['OFP:fuel/alternate_burn']),
            subFmt(27, 4, formatSeconds0202, ['OFP:alternate/ete']),
        ]);
        multi([
            subText(0, 15, 'FINRES'),
            subFmt(19, 5, '%5s', ['OFP:fuel/reserve']),
            subFmt(27, 4, formatSeconds0202, ['OFP:times/reserve_time']),
        ]);
        if (isEtops) {
            multi([
                subText(0, 15, 'ETOPS/ETP'),
                subFmt(19, 5, '%5s', ['OFP:fuel/etops']),
                subFmt(27, 4, formatSeconds0202, ['OFP:times/etopsfuel_time']),
            ]);
        }
        separator(31);
        multi([
            subText(0, 18, 'MINIMUM T/OFF FUEL'),
            subFmt(19, 5, '%5s', ['OFP:fuel/min_takeoff']),
            subFmt(27, 4,
                func (flow, enrouteFuel, contTime, alternateTime, reserveTime) {
                    return formatSeconds0202(
                        fuelToSeconds(flow, enrouteFuel) +
                        contTime +
                        alternateTime +
                        reserveTime
                    );
                },
                [ 'OFP:fuel/avg_fuel_flow'
                , 'OFP:fuel/enroute_burn'
                , 'OFP:times/contfuel_time'
                , 'OFP:alternate/ete'
                , 'OFP:times/reserve_time'
                ]),
        ]);
        separator(31);
        multi([
            subText(0, 15, 'EXTRA'),
            subFmt(19, 5, '%5s', ['OFP:fuel/extra']),
            subFmt(27, 4, formatSeconds0202, ['OFP:times/extrafuel_time']),
        ]);
        separator(31);
        multi([
            subText(0, 18, 'T/OFF FUEL'),
            subFmt(19, 5, '%5s', ['OFP:fuel/plan_takeoff']),
            subFmt(27, 4,
                func (flow, enrouteFuel, contTime, alternateTime, reserveTime, extraTime) {
                    return formatSeconds0202(
                        fuelToSeconds(flow, enrouteFuel) +
                        contTime +
                        alternateTime +
                        reserveTime +
                        extraTime
                    );
                },
                [ 'OFP:fuel/avg_fuel_flow'
                , 'OFP:fuel/enroute_burn'
                , 'OFP:times/contfuel_time'
                , 'OFP:alternate/ete'
                , 'OFP:times/reserve_time'
                , 'OFP:times/extrafuel_time'
                ]),
        ]);
        multi([
            subText(0, 15, 'TAXI'),
            subFmt(13, 4, '%4s', ['OFP:origin/iata_code']),
            subFmt(19, 5, '%5s', ['OFP:fuel/taxi']),
            subFmt(27, 4, formatSeconds0202, ['OFP:times/taxi_out']),
        ]);
        separator(31);
        multi([
            subText(0, 18, 'BLOCK FUEL'),
            subFmt(19, 5, '%5s', ['OFP:fuel/plan_ramp']),
            subFmt(27, 4,
                func (flow, enrouteFuel, contTime, alternateTime, reserveTime, extraTime, taxiTime) {
                    return formatSeconds0202(
                        fuelToSeconds(flow, enrouteFuel) +
                        contTime +
                        alternateTime +
                        reserveTime +
                        extraTime +
                        taxiTime
                    );
                },
                [ 'OFP:fuel/avg_fuel_flow'
                , 'OFP:fuel/enroute_burn'
                , 'OFP:times/contfuel_time'
                , 'OFP:alternate/ete'
                , 'OFP:times/reserve_time'
                , 'OFP:times/extrafuel_time'
                , 'OFP:times/taxi_out'
                ]),
        ]);
        multi([
            subText(0, 18, 'PIC EXTRA'),
            subEntry(19, 5, 'OFP:fuel/pic_extra'),
        ]);
        multi([
            subText(0, 18, 'TOTAL FUEL'),
            subEntry(19, 5, 'OFP:fuel/total'),
        ]);
        multi([
            subText(0, 18, 'REASON FOR PIC EXTRA'),
            subEntry(19, 12, 'OFP:fuel/pic_extra_reason'),
        ]);
        separator();
        plain('FMC INFO:');
        multi([
            subText(0, 18, 'FINRES+ALTN'),
            subFmt(19, 5, func (finres, extra) {
                return sprintf('%5s', finres + extra);
            }, ['OFP:fuel/reserve', 'OFP:fuel/alternate_burn'])
        ]);
        multi([
            subText(0, 18, 'TRIP+TAXI'),
            subFmt(19, 5, func (trip, taxi) {
                return sprintf('%5s', trip + taxi);
            }, ['OFP:fuel/enroute_burn', 'OFP:fuel/taxi'])
        ]);
        separator();
        plain('NO TANKERING RECOMMENDED (P)');
        separator();
        plain('I HEREWITH CONFIRM THAT I HAVE PERFORMED A THOROUGH SELF BRIEFING');
        plain('ABOUT THE DESTINATION AND ALTERNATE AIRPORTS OF THIS FLIGHT');
        plain('INCLUDING THE APPLICABLE INSTRUMENT APPROACH PROCEDURES, AIRPORT');
        plain('FACILITIES, NOTAMS AND ALL OTHER RELEVANT PARTICULAR INFORMATION.');
        newline();
        multi([
            subFmt(0, 30, 'DISPATCHER: %s', ['OFP:crew/dx']),
            subFmt(32, 33, func (name) {
                return sprintf('%33s', 'PIC NAME: ' ~ string.uc(name));
            }, ['OFP:crew/cpt'])
        ]);
        newline();
        plain('TEL: +1 800 555 0199                 PIC SIGNATURE: .............');

        pageBreak();

        # Page 2

        return items;
    },

    paginate: func (items, pageSize=nil) {
        if (pageSize == nil)
            pageSize = me.metrics.rows;
        var pages = [];
        var page = [];
        var pushPage = func {
            append(pages, page);
            page = [];
        };
        var toc = [];
        foreach (var item; items) {
            if (item.type == 'page-break') {
                pushPage();
                continue;
            }
            if (size(page) >= pageSize) {
                pushPage();
            }
            if (item.type == 'toc-entry') {
                append(toc, { title: item.title, page: size(pages) });
            }
            else {
                append(page, item);
            }
        }
        if (size(page) > 0) {
            pushPage();
        }
        debug.dump(toc);
        return [pages, toc];
    },

    renderSubItem: func (pageGroup, y, item) {
        var renderText = func (text) {
            pageGroup
                .createChild('text')
                .setText(substr(text, 0, item.w))
                .setFontSize(me.metrics.fontSize, 1)
                .setFont(font_mapper('mono'))
                .setColor(0, 0, 0)
                .setTranslation(me.metrics.paddingLeft + item.x * me.metrics.charWidth, y);
        };
        if (item.type == 'text') {
            renderText(item.text);
        }
        elsif (item.type == 'formatted') {
            var args = [];
            foreach (var argSpec; item.args) {
                append(args, me.getFormatArg(argSpec));
            }
            if (typeof(item.format) == 'func')
                renderText(call(item.format, args));
            else
                renderText(call(sprintf, [item.format] ~ args));
        }
        elsif (item.type == 'entry') {
            var val = nil; # me.getFormatArg(item.path);
            if (val == nil)
                renderText('.................................');
            else
                renderText(val);
        }
    },

    getFormatArg: func(argSpec) {
        if (typeof(argSpec) == 'scalar' and substr(argSpec ~ '', 0, 4) == 'OFP:') {
            return me.getOFPValue(substr(argSpec, 4));
        }
        else {
            return argSpec;
        }
    },

    renderItem: func (pageGroup, y, item) {
        var renderText = func (text) {
            pageGroup
                .createChild('text')
                .setText(text)
                .setFontSize(me.metrics.fontSize, 1)
                .setFont(font_mapper('mono'))
                .setColor(0, 0, 0)
                .setTranslation(me.metrics.paddingLeft, y);
        };
        if (item.type == 'text') {
            renderText(item.text);
        }
        elsif (item.type == 'separator') {
            renderText(
                substr(
                    '--------------------------------------------------------------------',
                    0, item.length));
        }
        elsif (item.type == 'formatted') {
            var args = [];
            foreach (var argSpec; item.args) {
                append(args, me.getFormatArg(argSpec));
            }
            renderText(call(sprintf, [item.format] ~ args));
        }
        elsif (item.type == 'multi') {
            foreach (var subItem; item.items) {
                me.renderSubItem(pageGroup, y, subItem);
            }
        }
    },

    renderPage: func(pageGroup, pageNumber, pageData) {
        var y = me.metrics.headerHeight + me.metrics.paddingTop + me.metrics.lineHeight;
        var schedOut = unixToDateTime(me.getOFPValue('times/sched_out'));
        var pageHeading =
                sprintf(
                    '%s %i/%02i %s/%s-%s',
                    me.getOFPValue('general/icao_airline'),
                    me.getOFPValue('general/flight_number'),
                    schedOut.day,
                    monthNames3[schedOut.month],
                    me.getOFPValue('origin/iata_code'),
                    me.getOFPValue('destination/iata_code'));

        pageGroup.createChild('path')
                 .rect(0, 0, me.metrics.pageWidth, me.metrics.headerHeight)
                 .setColor(0, 0, 0,)
                 .setColorFill(0.9, 0.9, 0.9);
        pageGroup.createChild('text')
                 .setAlignment('center-top')
                 .setMaxWidth(me.metrics.pageWidth)
                 .setText(pageHeading)
                 .setFont(font_mapper('sans', 'bold'))
                 .setFontSize(16, 1)
                 .setColor(0, 0, 0)
                 .setColorFill(1, 1, 0)
                 .setTranslation(me.metrics.pageWidth / 2, (me.metrics.headerHeight - 13) / 2);
        pageGroup.createChild('text')
                 .setAlignment('right-top')
                 .setMaxWidth(me.metrics.pageWidth)
                 .setText(sprintf('Page %i', pageNumber))
                 .setFont(font_mapper('sans', 'normal'))
                 .setFontSize(12, 1)
                 .setColor(0, 0, 0)
                 .setColorFill(1, 1, 0)
                 .setTranslation(me.metrics.pageWidth - me.metrics.paddingLeft, (me.metrics.headerHeight - 10) / 2);
        foreach (var item; pageData) {
            me.renderItem(pageGroup, y, item);
            y += me.metrics.lineHeight;
        }
    },

    renderOFP: func () {
        var self = me;
        me.contentGroup.removeAllChildren();
        me.contentGroup.createChild('path')
                       .rect(me.metrics.marginLeft, me.metrics.marginTop, me.metrics.pageWidth, me.metrics.pageHeight)
                       .setColor(0.2, 0.2, 0.2)
                       .setColorFill(1.0, 1.0, 1.0);
        me.pages = [];
        var pagesData = [];
        var toc = [];
        (pagesData, toc) = me.paginate(me.collectOFPItems());
        var pageNumber = 1;
        foreach (var pageData; pagesData) {
            var pageGroup = me.contentGroup
                                .createChild('group')
                                .setTranslation(me.metrics.marginLeft, me.metrics.marginTop);
            me.renderPage(pageGroup, pageNumber, pageData);
            pageGroup.hide();
            append(me.pages, pageGroup);
            pageNumber += 1;
        }
        if (me.currentPage >= size(me.pages)) {
            me.currentPage = 0;
        }
        if (size(me.pages) > 0) {
            me.pages[me.currentPage].show();
            me.makePager(size(me.pages), func() {
                foreach (var p; self.pages) {
                    p.hide();
                }
                if (self.currentPage < size(self.pages)) {
                    self.pages[self.currentPage].show();
                }
            }, me.contentGroup);
        }
    },
};

registerApp('paperwork', 'Paperwork', 'paperwork.png', PaperworkApp);

