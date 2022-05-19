var machToTAS = func (mach, alt) {
    return mach * ((alt - 29000) / (41000 - 29000) * (573 - 591) + 591);
};

var iasToTAS = func (ias, alt) {
    return ias * ((alt - 10000) / (30000 - 10000) * (1.62411 - 1.16219) + 1.16219);
};

var PilotSpeedFfMode = {
    new: func () {
        return {
            parents: [PilotSpeedFfMode],
            groundspeed: 120,
            info: nil,
            progress: {
                dist: 0.0,
                distRemaining: 0.0,
                alt: 0.0,
                fob: 0.0,
                ta: 0.0,
            },
            perfSchedule: nil,
        };
    },

    init: func(info) {
        me.groundspeed = math.max(120, info.groundspeed);
        me.info = info;
        me.progress = {
            dist: 0.0,
            distRemaining: info.totalDist,
            alt: info.currentAlt,
            fob: info.fob,
            ta: info.time,
        };
        me.calculateSchedule();
        me.calculateCruiseDescent();
    },

    calculateSchedule: func {
        me.perfSchedule = {
            # altitudes are top end of range
            # altitudes in feet
            # tas in knots (nmi/min)
            # vs in ft/min
            # ff in lbs/h
            climb: [
                {
                    # Initial climbout: V2+10, up to 1300 ft
                    alt: 1300,
                    tas: 160,
                    vs: 3400,
                    ff: 7000,
                },
                {
                    # Climb to 10k: IAS 250, at FL075
                    alt: 10000,
                    tas: 280,
                    vs: 3000,
                    ff: 7000,
                },
                {
                    # IAS 290, FL125
                    alt: 15000,
                    tas: 346,
                    vs: 2800,
                    ff: 7000,
                },
                {
                    # IAS 290, FL220
                    alt: 29000,
                    tas: 400,
                    vs: 2200,
                    ff: 7000,
                },
                {
                    # Mach .75, FL350
                    alt: 43000,
                    tas: 430,
                    vs: 1800,
                    ff: 7000,
                }
            ],
            cruise: {
                tas: ( (me.info.cruiseAlt >= 28500)
                        ? machToTAS(me.info.cruiseMach, me.info.cruiseAlt)
                        : iasToTAS(me.info.cruiseIAS, me.info.cruiseAlt)
                     ),
                alt: me.info.cruiseAlt,
                ff: 2500,
            },
            # altitudes are bottom end of range
            descent: [
                {
                    # Mach .77, FL350
                    alt: 29000,
                    tas: 444,
                    vs: 2100,
                    ff: 540,
                },
                {
                    # IAS 290, FL220
                    alt: 10000,
                    tas: 400,
                    vs: 2200,
                    ff: 540,
                },
                {
                    # IAS 230, FL060
                    alt: 3000,
                    tas: 250,
                    vs: 1600,
                    ff: 540,
                },
                {
                    # IAS 140, down to ground
                    alt: -2000,
                    tas: 140,
                    vs: 1200,
                    ff: 540,
                }
            ],
        };
    },

    calculateCruiseDescent: func {
        var alt = me.info.cruiseAlt;
        var te = 0.0;
        var dist = 0.0;
        foreach (var entry; me.perfSchedule.descent) {
            if (entry.alt >= alt) continue;
            var nextAlt = math.max(entry.alt, me.info.landingAlt);
            var timeToNextAltSeconds = 60 * (alt - nextAlt) / entry.vs;
            te += 60.0;
            alt = nextAlt;
            dist += entry.tas * timeToNextAltSeconds / 3600.0;
            if (alt <= me.info.landingAlt) break;
        }
        me.perfSchedule.cruiseDescent = {
            time: te,
            dist: dist,
        };
    },

    estimateWaypoint: func(dist, wpid) {
        var distRemaining = me.info.totalDist - dist;

        # printf("WAYPOINT: [%6.1f] %s", dist, wpid);

        # Climb
        foreach (var entry; me.perfSchedule.climb) {
            # Are we past TOD?
            if (me.progress.distRemaining <= me.perfSchedule.cruiseDescent.dist) break;

            # Waypoint already reached?
            if (me.progress.dist >= dist) break;

            # Have we already climbed past this segment?
            if (me.progress.alt > entry.alt) continue;

            var nextAlt = math.min(entry.alt, me.info.cruiseAlt);
            var timeToNextAltSeconds = 60 * (nextAlt - me.progress.alt) / entry.vs;
            var nextDist = math.min(dist, me.progress.dist + entry.tas * timeToNextAltSeconds / 3600.0);
            var timeToDistSeconds = math.abs(nextDist - me.progress.dist) * 3600.0 / entry.tas;
            var fuel = timeToDistSeconds * entry.ff / 3600.0;
            nextAlt = me.progress.alt + entry.vs * timeToDistSeconds / 60.0;
            # printf("- climb %5.0f -> %5.0f: %2.0f min, %3.1f nmi to %3.1f nmi, %1.0f lbs",
            #     me.progress.alt,
            #     nextAlt,
            #     timeToDistSeconds / 60.0,
            #     nextDist - me.progress.dist,
            #     nextDist,
            #     fuel);
            me.progress.dist = nextDist;
            me.progress.distRemaining = me.info.totalDist - nextDist;
            me.progress.fob -= fuel;
            me.progress.ta += timeToDistSeconds;
            me.progress.alt = nextAlt;

            # Have we reached the waypoint yet?
            if (me.progress.dist >= dist) break;
        }

        # Cruise
        if (me.progress.dist < dist and me.progress.distRemaining > me.perfSchedule.cruiseDescent.dist) {
            var nextDist = math.min(dist, me.info.totalDist - me.perfSchedule.cruiseDescent.dist);
            var timeToDistSeconds = math.abs(nextDist - me.progress.dist) * 3600.0 / me.perfSchedule.cruise.tas;
            var fuel = timeToDistSeconds * me.perfSchedule.cruise.ff / 3600.0;
            # printf("- cruise %5.0f: %2.0f min, %3.1f nmi to %3.1f nmi, %1.0f lbs",
            #     me.progress.alt,
            #     timeToDistSeconds / 60.0,
            #     nextDist - me.progress.dist,
            #     nextDist,
            #     fuel);
            me.progress.dist = nextDist;
            me.progress.distRemaining = me.info.totalDist - nextDist;
            me.progress.fob -= fuel;
            me.progress.ta += timeToDistSeconds;
            me.progress.alt = me.info.cruiseAlt;
        }

        # Descent
        foreach (var entry; me.perfSchedule.descent) {
            # Have we reached the waypoint yet?
            if (me.progress.dist >= dist) break;


            # Have we already descended past this segment?
            if (me.progress.alt <= entry.alt) continue;

            var nextAlt = math.max(entry.alt, me.info.landingAlt);
            var timeToNextAltSeconds = 60 * (me.progress.alt - nextAlt) / entry.vs;
            var nextDist = math.min(dist, me.progress.dist + entry.tas * timeToNextAltSeconds / 3600.0);
            var timeToDistSeconds = math.abs(nextDist - me.progress.dist) * 3600.0 / entry.tas;
            var fuel = timeToDistSeconds * entry.ff / 3600.0;
            nextAlt = me.progress.alt - entry.vs * timeToDistSeconds / 60.0;
            # printf("- descend %5.0f -> %5.0f: %2.0f min, %3.1f nmi to %3.1f nmi, %1.0f lbs",
            #     me.progress.alt,
            #     nextAlt,
            #     timeToDistSeconds / 60.0,
            #     nextDist - me.progress.dist,
            #     nextDist,
            #     fuel);
            me.progress.dist = nextDist;
            me.progress.distRemaining = me.info.totalDist - nextDist;
            me.progress.fob -= fuel;
            me.progress.ta += timeToDistSeconds;
            me.progress.alt = nextAlt;
        }

        # printf("At %s: %5.0f, %02.0f%02.0fz, %1.0f lbs",
            wpid,
            me.progress.alt, 
            math.floor(me.progress.ta / 3600.0),
            math.fmod(math.floor(me.progress.ta / 60.0), 60),
            me.progress.fob);

        return {
            ta: me.progress.ta,
            fob: me.progress.fob,
        };
    },

};
