# message-types.nas
#
# Copyright (C) 2020  Henning Stahlke
# Copyright (C) 2022  Tobias Dammers
#
# Adapted from:
#
# cpdlc.nas --- CPDLC library
# Copyright (C) 2020  Henning Stahlke
#
# This file is part of FlightGear.
#
# FlightGear is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# FlightGear is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FlightGear.  If not, see <http://www.gnu.org/licenses/>.
#
# Author:   Henning Stahlke
# Created:  2020-11-14
#

var ARG_FL_ALT = 1;
var ARG_SPEED = 2;
var ARG_NAVPOS = 3;
var ARG_ROUTE = 4;
var ARG_XPDR = 5;
var ARG_CALLSIGN = 6;
var ARG_FREQ = 7;
var ARG_TIME = 8;
var ARG_DIRECTION  = 9;
var ARG_DEGREES = 10;
var ARG_ATIS_CODE = 11;
var ARG_DEVIATION_TYPE = 12;
var ARG_ENDURANCE = 13; #remaining fuel as time in seconds
var ARG_LEGTYPE = 14;
var ARG_TEXT = 15;
var ARG_INTEGER = 16;
var ARG_REASON = 17;
var ARG_CLEARANCE_TYPE = 18;
var ARG_POSREP = 19;
var ARG_DISTANCE = 20;
var ARG_PROCEDURE = 21;
var ARG_SPEED_TYPE = 22;
var ARG_FACILITY = 23;
var ARG_ALTIMETER = 24;
var ARG_DATA_AUTHORITY = 25;
var ARG_VSPEED = 26;
var ARG_MINUTES = 27;


#keys according to tables in ICAO doc 4444
var responses = {
    # W/U in Doc 4444
    w: {id: "RSPD-1", txt: "WILCO"},    
    u: {id: "RSPD-2", txt: "UNABLE"},   
    # A/N in Doc 4444
    a: {id: "RSPD-5", txt: "AFFIRM"},
    n: {id: "RSPD-6", txt: "NEGATIVE"},

    s: {id: "RSPD-3", txt: "STANDBY"},  
    r: {id: "RSPD-4", txt: "ROGER"},
    # need clarification
    # single Y in Doc 4444 means any?
};

# These are not in ICAO Doc 4444; we use these to inject system events into the
# message log, but we never send or receive these.
var pseudo_messages = {
    "CONX-1": { txt: "LOGON TO $1", args: [ARG_FACILITY] },
    "CONX-2": { txt: "LOGOFF", args: [] },
    "CONX-3": { txt: "HANDOVER TO $1 FROM $2", args: [ARG_FACILITY, ARG_FACILITY] },
    "CONX-4": { txt: "DATALINK $1 UP", args: [ARG_TEXT] },
    "CONX-5": { txt: "DATALINK $1 DOWN", args: [ARG_TEXT] },
    "CONX-6": { txt: "LOGON ERROR $1", args: [ARG_TEXT] },
};

#-- messages from ATC to aircraft --
# do not add "s" to r_opts, it is added automatically 
var uplink_messages = {
    "SYSU-1": { txt: "ERROR $1", args: [ARG_TEXT], r_opts: [] },
    "SYSU-2": { txt: "NEXT DATA AUTHORITY $1", args: [ARG_DATA_AUTHORITY], r_opts: [] },
    "SYSU-3": { txt: "MESSAGE NOT SUPPORTED BY THIS ATC UNIT", args: [], r_opts: [] },
    "SYSU-4": { txt: "LOGICAL ACKNOWLEDGEMENT", args: [], r_opts: [] },
    "SYSU-5": { txt: "USE OF LOGICAL ACKNOWLEDGEMENT PROHIBITED", args: [], r_opts: [] },
    "SYSU-6": { txt: "LATENCY TIME VALUE $1", args: [ARG_TEXT], r_opts: [] }, # should have its own type, but we're not handling this
    "SYSU-7": { txt: "MESSAGE RECEIVED TOO LATE, RESEND MESSAGE OR CONTACT BY VOICE", args: [], r_opts: [] },

    "RTEU-1": { txt: "$1", args: [ARG_TEXT], r_opts: ["w","u"] },
    "RTEU-2": { txt: "PROCEED DIRECT TO $1", args: [ARG_NAVPOS], r_opts: ["w","u"] },
    "RTEU-3": { txt: "AT TIME $1 PROCEED DIRECT TO $2", args: [ARG_TIME, ARG_NAVPOS], r_opts: ["w","u"] },
    "RTEU-4": { txt: "AT $1 PROCEED DIRECT TO $2", args: [ARG_NAVPOS, ARG_NAVPOS], r_opts: ["w","u"] },
    "RTEU-5": { txt: "AT $1 PROCEED DIRECT TO $2", args: [ARG_FL_ALT, ARG_NAVPOS], r_opts: ["w","u"] },
    "RTEU-6": { txt: "CLEARED TO $1 VIA $2", args: [ARG_NAVPOS, ARG_ROUTE], r_opts: ["w","u"] },
    "RTEU-7": { txt: "CLEARED $1", args: [ARG_ROUTE], r_opts: ["w","u"] },
    "RTEU-8": { txt: "CLEARED $1", args: [ARG_PROCEDURE], r_opts: ["w","u"] },
    "RTEU-9": { txt: "AT $1 CLEARED $2", args: [ARG_NAVPOS, ARG_ROUTE], r_opts: ["w","u"] },
    "RTEU-10": { txt: "AT $1 CLEARED $2", args: [ARG_NAVPOS, ARG_PROCEDURE], r_opts: ["w","u"] },
    "RTEU-11": { txt: "AT $1 HOLD INBOUND TRACK $2 $3 TURNS $4 LEGS", args: [ARG_NAVPOS, ARG_DEGREES, ARG_DIRECTION, ARG_LEGTYPE], r_opts: ["w","u"] },
    "RTEU-12": { txt: "AT $1 HOLD AS PUBLISHED", args: [ARG_NAVPOS], r_opts: ["w","u"] },
    "RTEU-13": { txt: "EXPECT FURTHER CLEARANCE AT $1", args: [ARG_TIME], r_opts: ["r"] },
    "RTEU-14": { txt: "EXPECT $1", args: [ARG_CLEARANCE_TYPE], r_opts: ["r"] },
    "RTEU-15": { txt: "CONFIRM ASSIGNED ROUTE", args: [], r_opts: ["y"], replies: [{type:"RTED-9"}] },
    "RTEU-16": { txt: "REQUEST POSITION REPORT", args: [], r_opts: ["y"], replies: [{type:"RTED-5"}] },
    "RTEU-17": { txt: "ADVISE ETA $1", args: [ARG_NAVPOS], r_opts: ["y"], replies: [{type:"RTED-10", args:['$1', '']}] },

    "LATU-1": { txt: "OFFSET $1 $2 OF ROUTE", args: [ARG_DISTANCE, ARG_DIRECTION], r_opts: ["w","u"] },
    "LATU-2": { txt: "AT $1 OFFSET $2 $3 OF ROUTE", args: [ARG_NAVPOS, ARG_DISTANCE, ARG_DIRECTION], r_opts: ["w","u"] },
    "LATU-3": { txt: "AT TIME $1 OFFSET $2 $3 OF ROUTE", args: [ARG_TIME, ARG_DISTANCE, ARG_DIRECTION], r_opts: ["w","u"] },
    "LATU-4": { txt: "REJOIN ROUTE", args: [], r_opts: ["w","u"] },
    "LATU-5": { txt: "REJOIN ROUTE BEFORE PASSING $1", args: [ARG_NAVPOS], r_opts: ["w","u"] },
    "LATU-6": { txt: "REJOIN ROUTE BEFORE TIME $1", args: [ARG_TIME], r_opts: ["w","u"] },
    "LATU-7": { txt: "EXPECT BACK ON ROUTE BEFORE PASSING $1", args: [ARG_NAVPOS], r_opts: ["r"] },
    "LATU-8": { txt: "EXPECT BACK ON ROUTE BEFORE TIME $1", args: [ARG_TIME], r_opts: ["r"] },
    "LATU-9": { txt: "RESUME OWN NAVIGATION", args: [], r_opts: ["w","u"] },
    "LATU-10": { txt: "CLEARED TO DEVIATE UP TO $1 OF ROUTE", args: [ARG_DISTANCE], r_opts: ["w","u"] },
    "LATU-11": { txt: "TURN $1 HEADING $2", args: [ARG_DIRECTION, ARG_DEGREES], r_opts: ["w","u"] },
    "LATU-12": { txt: "TURN $1 GROUND TRACK $2", args: [ARG_DIRECTION, ARG_DEGREES], r_opts: ["w","u"] },
    "LATU-13": { txt: "TURN $1 $2 DEGREES", args: [ARG_DIRECTION, ARG_DEGREES], r_opts: ["w","u"] },
    "LATU-14": { txt: "CONTINUE PRESENT HEADING", args: [], r_opts: ["w","u"] },
    "LATU-15": { txt: "AT $1 FLY HEADING $2", args: [ARG_NAVPOS, ARG_DEGREES], r_opts: ["w","u"] },
    "LATU-16": { txt: "FLY HEADING $1", args: [ARG_DEGREES], r_opts: ["w","u"] },
    "LATU-17": { txt: "REPORT CLEAR OF WEATHER", args: [], r_opts: ["w","u"] },
    "LATU-18": { txt: "REPORT BACK ON ROUTE", args: [], r_opts: ["w","u"] },
    "LATU-19": { txt: "REPORT PASSING $1", args: [ARG_NAVPOS], r_opts: ["w","u"] },

    "LVLU-1": { txt: "EXPECT HIGHER AT TIME $1", args: [ARG_TIME], r_opts: ["r"] },
    "LVLU-2": { txt: "EXPECT HIGHER AT $1", args: [ARG_NAVPOS], r_opts: ["r"] },
    "LVLU-3": { txt: "EXPECT LOWER AT TIME $1", args: [ARG_TIME], r_opts: ["r"] },
    "LVLU-4": { txt: "EXPECT LOWER AT $1", args: [ARG_NAVPOS], r_opts: ["r"] },
    "LVLU-5": { txt: "MAINTAIN $1", args: [ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-6": { txt: "CLIMB TO $1", args: [ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-7": { txt: "AT TIME $1 CLIMB TO $2", args: [ARG_TIME, ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-8": { txt: "AT $1 CLIMB TO $2", args: [ARG_NAVPOS, ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-9": { txt: "DESCEND TO $1", args: [ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-10": { txt: "AT TIME $1 DESCEND TO $2", args: [ARG_TIME, ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-11": { txt: "AT $1 DESCEND TO $2", args: [ARG_NAVPOS, ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-12": { txt: "CLIMB TO REACH $1 BEFORE TIME $2", args: [ARG_FL_ALT, ARG_TIME], r_opts: ["w","u"] },
    "LVLU-13": { txt: "CLIMB TO REACH $1 BEFORE PASSING $2", args: [ARG_FL_ALT, ARG_NAVPOS], r_opts: ["w","u"] },
    "LVLU-14": { txt: "DESCEND TO REACH $1 BEFORE TIME $2", args: [ARG_FL_ALT, ARG_TIME], r_opts: ["w","u"] },
    "LVLU-15": { txt: "DESCEND TO REACH $1 BEFORE PASSING $2", args: [ARG_FL_ALT, ARG_NAVPOS], r_opts: ["w","u"] },
    "LVLU-16": { txt: "STOP CLIMB AT $1", args: [ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-17": { txt: "STOP DESCENT AT $1", args: [ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-18": { txt: "CLIMB AT $1 OR GREATER", args: [ARG_VSPEED], r_opts: ["w","u"] },
    "LVLU-19": { txt: "CLIMB AT $1 OR LESS", args: [ARG_VSPEED], r_opts: ["w","u"] },
    "LVLU-20": { txt: "DESCEND AT $1 OR GREATER", args: [ARG_VSPEED], r_opts: ["w","u"] },
    "LVLU-21": { txt: "DESCEND AT $1 OR LESS", args: [ARG_VSPEED], r_opts: ["w","u"] },
    "LVLU-22": { txt: "EXPECT $1 $2 AFTER DEPARTURE", args: [ARG_FL_ALT, ARG_MINUTES], r_opts: ["r"] },
    "LVLU-23": { txt: "REPORT LEAVING $1", args: [ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-24": { txt: "REPORT MAINTAINING $1", args: [ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-25": { txt: "REPORT PRESENT LEVEL", args: [], r_opts: ["y"],
                            replies: [{type:"LVLD-9", args:['']},
                                      {type:"LVLD-13", args:['']},
                                      {type:"LVLD-14", args:['']},
                                     ] },
    "LVLU-26": { txt: "REPORT REACHING BLOCK $1 TO $2", args: [ARG_FL_ALT, ARG_FL_ALT], r_opts: ["w","u"] },
    "LVLU-27": { txt: "CONFIRM ASSIGNED LEVEL", args: [], r_opts: ["y"], replies: [{type:"LVLD-11", args:['']}] },
    "LVLU-28": { txt: "ADVISE PREFERRED LEVEL", args: [], r_opts: ["y"], replies: [{type:"LVLD-12", args:['']}] },
    "LVLU-29": { txt: "ADVISE TOP OF DESCENT", args: [], r_opts: ["y"], replies: [{type:"LVLD-18", args:['']}] },
    "LVLU-30": { txt: "WHEN CAN YOU ACCEPT $1", args: [ARG_FL_ALT], r_opts: ["y"], replies: [{type:"LVLD-15", args:['$1', '']}, {type:"LVLD-16", args:['$1', '']}, {type:"LVLD-17", args:['$1']}] },
    "LVLU-31": { txt: "CAN YOU ACCEPT $1 AT $2", args: [ARG_FL_ALT, ARG_TEXT], r_opts: ["a", "n"] },
    "LVLU-32": { txt: "CAN YOU ACCEPT $1 AT TIME $2", args: [ARG_FL_ALT, ARG_TIME], r_opts: ["a", "n"] },

    "CSTU-1": { txt: "CROSS $1 AT $2", args: [ARG_NAVPOS, ARG_FL_ALT], r_opts: ["w","u"] },
    "CSTU-2": { txt: "CROSS $1 AT OR ABOVE $2", args: [ARG_NAVPOS, ARG_FL_ALT], r_opts: ["w","u"] },
    "CSTU-3": { txt: "CROSS $1 AT OR BELOW $2", args: [ARG_NAVPOS, ARG_FL_ALT], r_opts: ["w","u"] },
    "CSTU-4": { txt: "CROSS $1 AT TIME $2", args: [ARG_NAVPOS, ARG_TIME], r_opts: ["w","u"] },
    "CSTU-5": { txt: "CROSS $1 BEFORE TIME $2", args: [ARG_NAVPOS, ARG_TIME], r_opts: ["w","u"] },
    "CSTU-6": { txt: "CROSS $1 AFTER TIME $2", args: [ARG_NAVPOS, ARG_TIME], r_opts: ["w","u"] },
    "CSTU-7": { txt: "CROSS $1 BETWEEN TIME $2 AND TIME $3", args: [ARG_NAVPOS, ARG_TIME, ARG_TIME], r_opts: ["w","u"] },
    "CSTU-8": { txt: "CROSS $1 AT $2", args: [ARG_NAVPOS, ARG_SPEED], r_opts: ["w","u"] },
    "CSTU-9": { txt: "CROSS $1 AT $2 OR LESS", args: [ARG_NAVPOS, ARG_SPEED], r_opts: ["w","u"] },
    "CSTU-10": { txt: "CROSS $1 AT $2 OR GREATER", args: [ARG_NAVPOS, ARG_SPEED], r_opts: ["w","u"] },
    "CSTU-11": { txt: "CROSS $1 AT TIME $2 AT $3", args: [ARG_NAVPOS, ARG_TIME, ARG_FL_ALT], r_opts: ["w","u"] },
    "CSTU-12": { txt: "CROSS $1 BEFORE TIME $2 AT $3", args: [ARG_NAVPOS, ARG_TIME, ARG_FL_ALT], r_opts: ["w","u"] },
    "CSTU-13": { txt: "CROSS $1 AFTER TIME $2 AT $3", args: [ARG_NAVPOS, ARG_TIME, ARG_FL_ALT], r_opts: ["w","u"] },
    "CSTU-14": { txt: "CROSS $1 AT $2 AT $3", args: [ARG_NAVPOS, ARG_FL_ALT, ARG_SPEED], r_opts: ["w","u"] },
    "CSTU-15": { txt: "CROSS $1 AT TIME $2 AT $3 AT $4", args: [ARG_NAVPOS, ARG_TIME, ARG_FL_ALT, ARG_SPEED], r_opts: ["w","u"] },

    "SPDU-1":  { txt: "EXPECT SPEED CHANGE AT TIME $1", args: [ARG_TIME], r_opts: ["r"] },
    "SPDU-2":  { txt: "EXPECT SPEED CHANGE AT $1", args: [ARG_NAVPOS], r_opts: ["r"] },
    "SPDU-3":  { txt: "EXPECT SPEED CHANGE AT $1", args: [ARG_FL_ALT], r_opts: ["r"] },
    "SPDU-4":  { txt: "MAINTAIN $1", args: [ARG_SPEED], r_opts: ["w","u"] },
    "SPDU-5":  { txt: "MAINTAIN PRESENT SPEED", args: [], r_opts: ["w","u"] },
    "SPDU-6":  { txt: "MAINTAIN $1 OR GREATER", args: [ARG_SPEED], r_opts: ["w","u"] },
    "SPDU-7":  { txt: "MAINTAIN $1 OR LESS", args: [ARG_SPEED], r_opts: ["w","u"] },
    "SPDU-8":  { txt: "MAINTAIN $1 TO $2", args: [ARG_SPEED, ARG_SPEED], r_opts: ["w","u"] },
    "SPDU-9":  { txt: "INCREASE SPEED TO $1", args: [ARG_SPEED], r_opts: ["w","u"] },
    "SPDU-10": { txt: "INCREASE SPEED TO $1 OR GREATER", args: [ARG_SPEED], r_opts: ["w","u"] },
    "SPDU-11": { txt: "REDUCE SPEED TO $1", args: [ARG_SPEED], r_opts: ["w","u"] },
    "SPDU-12": { txt: "REDUCE SPEED TO $1 OR LESS", args: [ARG_SPEED], r_opts: ["w","u"] },
    "SPDU-13": { txt: "RESUME NORMAL SPEED", args: [], r_opts: ["w","u"] },
    "SPDU-14": { txt: "NO SPEED RESTRICTION", args: [], r_opts: ["r"] },
    "SPDU-15": { txt: "REPORT $1 SPEED", args: [ARG_SPEED_TYPE], r_opts: ["y"], replies: [{type:"SPDD-3", args:['$1', '']}] },
    "SPDU-16": { txt: "CONFIRM ASSIGNED SPEED", args: [], r_opts: ["y"], replies: [{type:"SPDD-4"}] },
    "SPDU-17": { txt: "WHEN CAN YOU ACCEPT $1", args: [ARG_SPEED], r_opts: ["y"], replies: [{type:"SPDD-5", args:['$1','']}, {type:"SPDD-6", args:['$1']}] },

    "ADVU-1":  { txt: "$1 ALTIMETER $2", args: [ARG_FACILITY, ARG_ALTIMETER], r_opts: ["r"] }, 
    "ADVU-2":  { txt: "SERVICE TERMINATED", args: [], r_opts: ["r"] }, 
    "ADVU-3":  { txt: "IDENTIFIED $1", args: [ARG_TEXT], r_opts: ["r"] }, 
    "ADVU-4":  { txt: "IDENTIFICATION LOST", args: [], r_opts: ["r"] }, 
    "ADVU-5":  { txt: "ATIS $1", args: [ARG_ATIS_CODE], r_opts: ["r"] }, 
    "ADVU-6":  { txt: "REQUEST AGAIN WITH NEXT ATC UNIT", args: [], r_opts: [] }, 
    "ADVU-7":  { txt: "TRAFFIC IS $1", args: [ARG_TEXT], r_opts: ["r"] }, 
    "ADVU-8":  { txt: "REPORT SIGHTING AND PASSING OPPOSITE DIRECTION $1", args: [ARG_TEXT], r_opts: ["w", "u"] }, 
    "ADVU-9":  { txt: "SQUAWK $1", args: [ARG_XPDR], r_opts: ["w","u"] }, 
    "ADVU-10": { txt: "STOP SQUAWK", args: [], r_opts: ["w","u"] }, 
    "ADVU-11": { txt: "STOP ADS-B TRANSMISSION", args: [], r_opts: ["w","u"] }, 
    "ADVU-12": { txt: "SQUAWK MODE C", args: [], r_opts: ["w","u"] }, 
    "ADVU-13": { txt: "STOP SQUAWK MODE C", args: [], r_opts: ["w","u"] }, 
    "ADVU-14": { txt: "CONFIRM SQUAWK CODE", args: [], r_opts: ["y"], replies: [{type: "ADVD-1"}] }, 
    "ADVU-15": { txt: "SQUAWK IDENT", args: [], r_opts: ["w","u"] }, 
    "ADVU-16": { txt: "ACTIVATE ADS-C", args: [], r_opts: ["w","u"] }, 
    "ADVU-17": { txt: "ADS-C OUT OF SERVICE REVERT TO VOICE POSITION REPORTS", args: [], r_opts: ["w","u"] }, 
    "ADVU-18": { txt: "RELAY TO $1", args: [], r_opts: ["w","u"] }, 
    "ADVU-19": { txt: "$1 DEVIATION DETECTED. VERIFY AND ADVISE", args: [ARG_DEVIATION_TYPE], r_opts: ["w","u"] }, 

    "COMU-1":  { txt: "CONTACT $1 $2", args: [ARG_CALLSIGN, ARG_FREQ], r_opts: ["w","u"] },
    "COMU-2":  { txt: "AT $1 CONTACT $2 $3", args: [ARG_NAVPOS, ARG_CALLSIGN, ARG_FREQ], r_opts: ["w","u"] },
    "COMU-3":  { txt: "AT TIME $1 CONTACT $2 $3", args: [ARG_TIME, ARG_CALLSIGN, ARG_FREQ], r_opts: ["w","u"] },
    "COMU-4":  { txt: "SECONDARY FREQUENCY $1", args: [ARG_FREQ], r_opts: ["r"] },
    "COMU-5":  { txt: "MONITOR $1 $2", args: [ARG_CALLSIGN, ARG_FREQ], r_opts: ["w","u"] },
    "COMU-6":  { txt: "AT $1 MONITOR $2 $3", args: [ARG_NAVPOS, ARG_CALLSIGN, ARG_FREQ], r_opts: ["w","u"] },
    "COMU-7":  { txt: "AT TIME $1 MONITOR $2 $3", args: [ARG_TIME, ARG_CALLSIGN, ARG_FREQ], r_opts: ["w","u"] },
    "COMU-8":  { txt: "CHECK STUCK MICROPHONE $1", args: [ARG_FREQ], r_opts: [] },
    "COMU-9":  { txt: "CURRENT ATC UNIT $1", args: [ARG_CALLSIGN], r_opts: [] },

    "EMGU-1": { txt: "REPORT ENDURANCE AND PERSONS ON BOARD", args: [], r_opts: ["y"], replies: [{type:"EMGD-3"}] }, 
    "EMGU-2": { txt: "IMMEDIATELY", args: [], r_opts: ["y"] },
    "EMGU-3": { txt: "CONFIRM ADS-C EMERGENCY", args: [], r_opts: ["a","n"] }, 

    "SUPU-1": { txt: "WHEN READY", args: [], r_opts: [] },
    "SUPU-2": { txt: "DUE TO $1", args: [ARG_REASON], r_opts: [] },
    "SUPU-3": { txt: "EXPEDITE", args: [], r_opts: [] },
    "SUPU-4": { txt: "REVISED $1", args: [ARG_REASON], r_opts: [] },

    "RSPU-1": { txt: "UNABLE", args: [], r_opts: [] },
    "RSPU-2": { txt: "STANDBY", args: [], r_opts: [] },
    "RSPU-3": { txt: "REQUEST DEFERRED", args: [], r_opts: [] },
    "RSPU-4": { txt: "ROGER", args: [], r_opts: [] },
    "RSPU-5": { txt: "AFFIRM", args: [], r_opts: [] },
    "RSPU-6": { txt: "NEGATIVE", args: [], r_opts: [] },
    "RSPU-7": { txt: "REQUEST FORWARDED", args: [], r_opts: [] },
    "RSPU-8": { txt: "CONFIRM REQUEST", args: [], r_opts: [] },

    "TXTU-1":  { txt: "$1", args: [ARG_TEXT], r_opts: ["r"] },
    "TXTU-2":  { txt: "$1", args: [ARG_TEXT], r_opts: [] },
    "TXTU-3":  { txt: "$1", args: [ARG_TEXT], r_opts: [] },
    "TXTU-4":  { txt: "$1", args: [ARG_TEXT], r_opts: ["w","u"] },
    "TXTU-5":  { txt: "$1", args: [ARG_TEXT], r_opts: ["a","n"] },
};

#-- messages from aircraft to ATC --
var downlink_messages = {
    "SYSD-1": { txt: "ERROR $1", args: [ARG_TEXT], r_opts: [] },
    "SYSD-2": { txt: "LOGICAL ACKNOWLEDGEMENT", args: [], r_opts: [] },
    "SYSD-3": { txt: "NOT CURRENT DATA AUTHORITY", args: [], r_opts: [] },
    "SYSD-4": { txt: "CURRENT DATA AUTHORITY", args: [], r_opts: [] },
    "SYSD-5": { txt: "NOT AUTHORIZED NEXT DATA AUTHORITY $1 $2", args: [ARG_DATA_AUTHORITY, ARG_DATA_AUTHORITY], r_opts: [] },
    "SYSD-6": { txt: "MESSAGE RECEIVED TOO LATE, RESEND MESSAGE OR CONTACT BY VOICE", args: [], r_opts: [] },
    "SYSD-7": { txt: "AIRCRAFT CPDLC INHIBITED", args: [], r_opts: [] },

    "RTED-1": { txt: "REQUEST DIRECT TO $1", args: [ARG_NAVPOS], r_opts: ["y"] },
    "RTED-2": { txt: "REQUEST $1", args: [ARG_TEXT], r_opts: ["y"] },
    "RTED-3": { txt: "REQUEST CLEARANCE $1", args: [ARG_ROUTE], r_opts: ["y"] },
    "RTED-4": { txt: "REQUEST $1 CLEARANCE", args: [ARG_CLEARANCE_TYPE], r_opts: ["y"] },
    "RTED-5": { txt: "POSITION REPORT $1", args: [ARG_POSREP], r_opts: ["y"] },
    "RTED-6": { txt: "REQUEST HEADING $1", args: [ARG_DEGREES], r_opts: ["y"] },
    "RTED-7": { txt: "REQUEST GROUND TRACK $1", args: [ARG_DEGREES], r_opts: ["y"] },
    "RTED-8": { txt: "WHEN CAN WE EXPECT BACK ON ROUTE", args: [], r_opts: ["y"] },
    "RTED-9": { txt: "ASSIGNED ROUTE $1", args: [ARG_ROUTE], r_opts: [] },
    "RTED-10": { txt: "ETA $1 TIME $2", args: [ARG_NAVPOS, ARG_TIME], r_opts: [] },

    "LATD-1": { txt: "REQUEST OFFSET $1 $2 OF ROUTE", args: [ARG_DISTANCE, ARG_DIRECTION], r_opts: ["y"] },
    "LATD-2": { txt: "REQUEST WEATHER DEVIATION UP TO $1 OF ROUTE", args: [ARG_DISTANCE], r_opts: ["y"] },
    "LATD-3": { txt: "CLEAR OF WEATHER", args: [], r_opts: [] },
    "LATD-4": { txt: "BACK ON ROUTE", args: [], r_opts: [] },
    "LATD-5": { txt: "DIVERTING TO $1 VIA $2", args: [ARG_NAVPOS, ARG_ROUTE], r_opts: ["y"] },
    "LATD-6": { txt: "OFFSETTING $1 $2 OF ROUTE", args: [ARG_DISTANCE, ARG_DIRECTION], r_opts: ["y"] },
    "LATD-7": { txt: "DEVIATING $1 $2 OF ROUTE", args: [ARG_DISTANCE, ARG_DIRECTION], r_opts: ["y"] },
    "LATD-8": { txt: "PASSING $1", args: [ARG_NAVPOS], r_opts: [] },

    "LVLD-1": { txt: "REQUEST LEVEL $1", args: [ARG_FL_ALT], r_opts: ["y"] },
    "LVLD-2": { txt: "REQUEST CLIMB TO $1", args: [ARG_FL_ALT], r_opts: ["y"] },
    "LVLD-3": { txt: "REQUEST DESCENT TO $1", args: [ARG_FL_ALT], r_opts: ["y"] },
    "LVLD-4": { txt: "AT $1 REQUEST $2", args: [ARG_NAVPOS, ARG_FL_ALT], r_opts: ["y"] },
    "LVLD-5": { txt: "AT TIME $1 REQUEST $2", args: [ARG_TIME, ARG_FL_ALT], r_opts: ["y"] },
    "LVLD-6": { txt: "WHEN CAN WE EXPECT LOWER LEVEL", args: [], r_opts: ["y"] },
    "LVLD-7": { txt: "WHEN CAN WE EXPECT HIGHER LEVEL", args: [], r_opts: ["y"] },
    "LVLD-8": { txt: "LEAVING LEVEL $1", args: [ARG_FL_ALT], r_opts: [] },
    "LVLD-9": { txt: "MAINTAINING LEVEL $1", args: [ARG_FL_ALT], r_opts: [] },
    "LVLD-10": { txt: "REACHING BLOCK $1 TO $2", args: [ARG_FL_ALT, ARG_FL_ALT], r_opts: [] },
    "LVLD-11": { txt: "ASSIGNED LEVEL $1", args: [ARG_FL_ALT], r_opts: [] },
    "LVLD-12": { txt: "PREFERRED LEVEL $1", args: [ARG_FL_ALT], r_opts: [] },
    "LVLD-13": { txt: "CLIMBING TO $1", args: [ARG_FL_ALT], r_opts: [] },
    "LVLD-14": { txt: "DESCENDING TO $1", args: [ARG_FL_ALT], r_opts: [] },
    "LVLD-15": { txt: "WE CAN ACCEPT $1 AT TIME $2", args: [ARG_FL_ALT, ARG_TIME], r_opts: [] },
    "LVLD-16": { txt: "WE CAN ACCEPT $1 AT $2", args: [ARG_FL_ALT, ARG_NAVPOS], r_opts: [] },
    "LVLD-17": { txt: "WE CANNOT ACCEPT $1", args: [ARG_FL_ALT], r_opts: [] },
    "LVLD-18": { txt: "TOP OF DESCENT $1 TIME $2", args: [ARG_TEXT, ARG_TIME], r_opts: [] },

    "ADVD-1": { txt: "SQUAWKING $1", args: [ARG_XPDR], r_opts: [] },
    "ADVD-2": { txt: "TRAFFIC $1", args: [ARG_TEXT], r_opts: [] },

    "SPDD-1": { txt: "REQUEST $1", args: [ARG_SPEED], r_opts: ["y"] },
    "SPDD-2": { txt: "WHEN CAN WE EXPECT $1", args: [ARG_SPEED], r_opts: ["y"] },
    "SPDD-3": { txt: "$1 SPEED $2", args: [ARG_SPEED_TYPE, ARG_SPEED], r_opts: [] },
    "SPDD-4": { txt: "ASSIGNED SPEED $1", args: [ARG_SPEED], r_opts: [] },
    "SPDD-5": { txt: "WE CAN ACCEPT $1 AT TIME $2", args: [ARG_SPEED, ARG_TIME], r_opts: [] },
    "SPDD-6": { txt: "WE CANNOT ACCEPT $1", args: [ARG_SPEED], r_opts: [] },

    "RSPD-1": { txt: "WILCO", args: [], r_opts: [] }, 
    "RSPD-2": { txt: "UNABLE", args: [], r_opts: [] }, 
    "RSPD-3": { txt: "STANDBY", args: [], r_opts: [] }, 
    "RSPD-4": { txt: "ROGER", args: [], r_opts: [] }, 
    "RSPD-5": { txt: "AFFIRM", args: [], r_opts: [] }, 
    "RSPD-6": { txt: "NEGATIVE", args: [], r_opts: [] },    
    
    "COMD-1": { txt: "REQUEST VOICE CONTACT $1", args: [ARG_FREQ], r_opts: ["y"] }, 
    "COMD-2": { txt: "RELAY FROM $1", args: [ARG_TEXT], r_opts: ["n"] }, 

    "EMGD-1": { txt: "PAN PAN PAN", args: [], r_opts: ["y"] }, 
    "EMGD-2": { txt: "MAYDAY MAYDAY MAYDAY", args: [], r_opts: ["y"] }, 
    "EMGD-3": { txt: "$1 ENDURANCE AND $2 POB", args: [ARG_ENDURANCE, ARG_INTEGER], r_opts: ["y"] }, 
    "EMGD-4": { txt: "CANCEL EMERGENCY", args: [], r_opts: ["y"] }, 

    "SUPD-1": { txt: "DUE TO $1", args: [ARG_REASON], r_opts: [] },

    "TXTD-1": { txt: "$1", args: [ARG_TEXT], r_opts: ["y"] },
    "TXTD-2": { txt: "$1", args: [ARG_TEXT], r_opts: [] },
};

var formatMessagePart = func (type, args) {
    if (args == nil) args = [];
    var messageType =
            contains(pseudo_messages, type) ? pseudo_messages[type] :
            contains(uplink_messages, type) ? uplink_messages[type] :
            contains(downlink_messages, type) ? downlink_messages[type] :
            nil;
    if (messageType == nil) {
        return '[' ~ type ~ '] ' ~ string.join(' ', args);
    }
    var txt = messageType.txt;
    for (var i = 0; i < size(args); i += 1) {
        txt = string.replace(txt or '', '$' ~ (i + 1), args[i] or '');
    }
    # debug.dump("FORMAT", type, args, messageType, txt);
    return txt;
};

var formatMessage = func (parts) {
    var formattedParts = [];
    foreach (var part; parts) {
        append(formattedParts, formatMessagePart(part.type, part.args));
    }
    return string.join(' ', formattedParts);
};

var formatMessagePartFancy = func (type, args) {
    if (args == nil) args = [];
    var messageType =
            contains(pseudo_messages, type) ? pseudo_messages[type] :
            contains(uplink_messages, type) ? uplink_messages[type] :
            contains(downlink_messages, type) ? downlink_messages[type] :
            nil;
    if (messageType == nil) {
        debug.dump('INVALID MESSAGE', type, args);
        return [];
    }
    var words = split(' ', messageType.txt);
    if (substr(type, 0, 3) == 'TXT') {
        words = ['FREE', 'TEXT'] ~ words;
    }
    var line = [];
    var elems = [];
    foreach (var word; words) {
        if (substr(word, 0, 1) == '$') {
            if (size(line) > 0) {
                append(elems, { type: 0, value: string.join(' ', line) });
                line = [];
            }
            var i = int(substr(word, 1)) - 1;
            var value = args[i];
            if (value == nil or value == '') {
                value = '----------------';
            }
            append(elems, { type: messageType.args[i], value: value });
        }
        else {
            append(line, word);
        }
    }
    if (size(line) > 0) {
        append(elems, { type: 0, value: string.join(' ', line) });
        line = [];
    }
    return elems;
};

var formatMessageFancy = func (parts) {
    var formattedParts = [];
    foreach (var part; parts) {
        append(formattedParts, formatMessagePartFancy(part.type, part.args));
    }
    return formattedParts;
};

var messageRA = func (type) {
    var messageType =
            contains(uplink_messages, type) ? uplink_messages[type] :
            contains(downlink_messages, type) ? downlink_messages[type] :
            nil;
    if (messageType == nil) return '';
    return string.uc(string.join('', messageType.r_opts));
};

var messageFromNode = func (node) {
    var msg = node.getValues();
    if (typeof(msg.parts) != 'vector') msg.parts = [msg.parts];
    foreach (var part; msg.parts) {
        if (typeof(part.args) != 'vector') part.args = [part.args];
    }
    return msg;
};
