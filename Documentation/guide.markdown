# Embraer E-Jet Family for FlightGear

# User Guide

![Parked at EHAM](images/parked-eham.jpg)

## Introduction

The Embraer E-Jet family is a series of narrow-body short- to medium-range
twin-engine jet airliners, carrying 66 to 124 passengers commercially,
manufactured by Brazilian aerospace manufacturer Embraer. The aircraft family
was first introduced at the Paris Air Show in 1999 and entered production in
2002. The series has been a commercial success primarily due to its ability to
efficiently serve lower-demand routes while offering many of the same amenities
and features of larger jets. The aircraft is used by mainline and regional
airlines around the world but has proven particularly popular with regional
airlines in the United States. (Source:
[wikipedia](https://en.wikipedia.org/wiki/Embraer_E-Jet_family#E-190_and_195)).

This package for FlightGear includes the following types:

### E170

![E170](images/E170.jpg)

The original E-Jet, first to enter production. Seats 66-78 passengers, powered
by two GE CF34-8E engines.

### E175

![E175](images/E175.jpg)

A slight stretch of the E170, using the same wing, engines, flight deck and
systems. Seats 76-88 passengers.

### E190

![E190](images/E190.jpg)

A further stretch of the E175, with a larger wing, more powerful GE CF34-10E
engines, improved avionics, increased range, and faster cruise speed. Seats
96-114 passengers.

### E195

![E195](images/E195.jpg)

A slightly stretched, but otherwise identical, variant of the E190. Seats
100-124 passengers.

### Lineage 1000

![Lineage1000](images/Lineage1000.jpg)

A luxury bizjet conversion of the E190. The lower deck is filled entirely with
an additional fuel tank, increasing the aircraft's range to a whopping 4600
nmi; the upper deck can be configured to the customer's needs, and may include
a double-sized galley, master suite with a king-size double bed and bathroom,
large flatscreen, etc. A cargo compartment is also situated on the upper deck.
Typical configurations seat 12-19 passengers and their luggage.

## Preflight

Before taking off, the wheel chocks and safety cones should be removed. This
can be done via the "E-jet-family" / "Airport Operations" menu. Also make sure
the doors are all closed, and the fuel truck is disconnected. The status of all
doors can be monitored on the Systems page on the MFD.

## Flight Deck Overview

![Flight Deck](images/flightdeck-overview.jpg)

- **PFD1/2**: primary flight display, shows key information about the state of
  the aircraft, including airspeed, vertical speed, attitude, autopilot, and
  primary navigation.
- **MFD1/2**: multi-function display, shows navigation information and system
  status.
- **EFIS (EICAS)**: displays information about the status of the engines,
  flight controls, etc., and any warnings/errors that may exist.
- **Glareshield Panel** (GSP), used to control the autopilot and autothrottle.
- **MCDU1/2**, the primary interface to the flight management system (FMS),
  also used to tune the aircraft's radios (NAV1/2, COM1/2, XPDR, TCAS, ADF1/2)
- **Engine Controls**, used to start and stop the engines. The startup process
  is highly automated, so usually, it is enough to put the knobs in the right
  position and watch the aircraft start itself.
- **Speedbrake** and **Throttle Levers** function as usual.
- **Flap Lever** controls flaps and leading-edge slats. There are 6 settings;
  flaps 1 through 4 are used for takeoff and approach, flaps 5 and 6 (FULL) for
  landing. Selecting flaps 5 or 6 automatically arms the ground spoilers. Note
  that use of flaps 6 is not authorized for CAT-II landings.
- **Parking Brake** functions as usual.

## MFD's and CCD's

The real E-Jet uses a device known as the CCD (Cursor Control Device) to
provide a point-and-click style GUI on the EFIS screens, particularly the MFD.
The CCD consists of a trackpad, an "enter" button, three screen selector
buttons, and a two-ring twist knob for data entry. The pilot can use the screen
selector to move a cursor between PFD, MFD and EICAS screens; the touchpad
moves the cursor within the selected screen; the "enter" button selects
on-screen GUI elements; and the twist knob serves as a dynamic dial for various
inputs, such as map range etc.

Because we cannot provide a physical CCD in flightgear, the FlightGear E-Jet
emulates this functionality by allowing you to click directly onto the MFD, and
using the mouse scroll wheel to emulate the twist knob. Specifically, the
mapping works as follows:

- Mouse click: position CCD cursor on clicked screen (currently only MFD is
  supported), at the position of the click, and then click the CCD "enter"
  button
- Scroll wheel: twist outer ring of CCD data entry knob.
- Shift + scroll wheel: twist inner ring of CCD data entry knob.

## Startup Procedure

The E-Jet has a largely automatic engine start procedure, driven by the FADEC
(Fully Autonomous Digital Engine Control).

On the ground, there are several ways of starting the engines; the engine
start itself is the same, what differs is how we set up the aircraft to feed
electricity, bleed air, and fuel to the engines so that they can start.

### Engine Start - Ground Power Unit (GPU) Connected

This is the preferred method at airports that have ground power units
available.

- GPU AC POWER - ON
- IDG 1 - AUTO
- IDG 2 - AUTO
- AC BUS TIE - AUTO
- TRU 1 - ON
- TRU ESS - ON
- TRU 2 - ON
- BATTERY 1 - ON
- BATTERY 2 - ON
- DC BUS TIES - AUTO
- THRUST LEVERS - IDLE
- FUEL PUMPS (AC1, AC2, AC3 (Lineage 1000 only), DC) - AUTO
- ENGINE 1 IGNITION - AUTO
- ENGINE 1 STARTER - START
- ENGINE 1 N2 - >50%
- ENGINE 1 STARTER - VERIFY ON
- ENGINE 2 IGNITION - AUTO
- ENGINE 2 STARTER - START
- ENGINE 2 N2 - >50%
- ENGINE 2 STARTER - VERIFY ON
- ENGINE 1 BLEED - ON
- ENGINE 2 BLEED - ON
- GPU AC POWER - OFF
- GPU - DISCONNECT

### Engine Start - Ground Power Unit (GPU) Connected, Single-Engine Taxi

This procedure can be used if a lengthy taxi or hold on the ground is expected.
Only the #1 engine is started at the gate, the #2 engine is started using
cross-bleed from #1 just before takeoff.

- GPU AC POWER - ON
- IDG 1 - AUTO
- IDG 2 - AUTO
- AC BUS TIE - AUTO
- TRU 1 - ON
- TRU ESS - ON
- TRU 2 - ON
- BATTERY 1 - ON
- BATTERY 2 - ON
- DC BUS TIES - AUTO
- THRUST LEVERS - IDLE
- FUEL PUMPS (AC1, AC2, AC3 (Lineage 1000 only), DC) - AUTO
- ENGINE 1 IGNITION - AUTO
- ENGINE 1 STARTER - START
- ENGINE 1 N2 - >50%
- ENGINE 1 STARTER - VERIFY ON
- GPU AC POWER - OFF
- GPU - DISCONNECT

#### Before Takeoff

- ENGINE 1 BLEED - ON
- ENGINE 2 IGNITION - AUTO
- ENGINE 2 STARTER - START
- ENGINE 2 N2 - >50%
- ENGINE 2 STARTER - VERIFY ON
- ENGINE 2 BLEED - ON

### Engine Start - Ground Power Unit (GPU) Not Connected

Without ground power, we can use the APU to provide electricity and bleed air.

- IDG 1 - AUTO
- IDG 2 - AUTO
- AC BUS TIE - AUTO
- TRU 1 - ON
- TRU ESS - ON
- TRU 2 - ON
- BATTERY 1 - ON
- BATTERY 2 - ON
- DC BUS TIES - AUTO
- APU GEN - AUTO
- APU - START
- APU RPM - WAIT FOR 100%
- APU BLEED - ON
- THRUST LEVERS - IDLE
- FUEL PUMPS (AC1, AC2, AC3 (Lineage 1000 only), DC) - AUTO
- ENGINE 1 IGNITION - AUTO
- ENGINE 1 STARTER - START
- ENGINE 1 N2 - >50%
- ENGINE 1 STARTER - VERIFY ON
- ENGINE 2 IGNITION - AUTO
- ENGINE 2 STARTER - START
- ENGINE 2 N2 - >50%
- ENGINE 2 STARTER - VERIFY ON
- ENGINE 1 BLEED - ON
- ENGINE 2 BLEED - ON
- APU GEN - OFF
- APU BLEED - OFF
- APU - OFF

### Engine Start - Ground Power Unit (GPU) Not Connected, Cross-Bleed Start

An alternative method, starting the #1 engine using the APU, and then
performing a cross-bleed start once #1 is running. This method can also be
adapted for a single-engine taxi.

- IDG 1 - AUTO
- IDG 2 - AUTO
- AC BUS TIE - AUTO
- TRU 1 - ON
- TRU ESS - ON
- TRU 2 - ON
- BATTERY 1 - ON
- BATTERY 2 - ON
- DC BUS TIES - AUTO
- APU GEN - AUTO
- APU - START
- APU RPM - WAIT FOR 100%
- APU BLEED - ON
- THRUST LEVERS - IDLE
- FUEL PUMPS (AC1, AC2, AC3 (Lineage 1000 only), DC) - AUTO
- ENGINE 1 IGNITION - AUTO
- ENGINE 1 STARTER - START
- ENGINE 1 N2 - >50%
- ENGINE 1 STARTER - VERIFY ON
- ENGINE 1 BLEED - ON
- APU GEN - OFF
- APU BLEED - OFF
- APU - OFF
- ENGINE 2 IGNITION - AUTO
- ENGINE 2 STARTER - START
- ENGINE 2 N2 - >50%
- ENGINE 2 STARTER - VERIFY ON
- ENGINE 2 BLEED - ON

## Autopilot

### Glareshield Panel Controls

![Glareshield Panel](images/glareshield-panel.jpg)

#### Captain-side:

- 1: **QNH knob**. Rotate: select QNH. Push: select standard QNH
  (1013 hPa / 29.92 inHg). Rotate ring: switch hPa / inHg.
- 2: **Minimums knob**. Rotate: select minimums. Rotate ring:
  switch RA (radio) / BARO (barometric) minimums.
- 3: **Course knob**. Rotate: select course for NAV1. Push: select
  direct course for NAV1.
- 12: **FD button**. Enable/disable Flight Director.

#### First Officer-side:

- 10: **QNH knob**. Rotate: select QNH. Push: select standard QNH
  (1013 hPa / 29.92 inHg). Rotate ring: switch hPa / inHg.
- 11: **Minimums knob**. Rotate: select minimums. Rotate ring:
  switch RA (radio) / BARO (barometric) minimums.
- 9: **Course knob**. Rotate: select course for NAV2. Push: select
  direct course for NAV2.
- 25: **FD button**. Enable/disable Flight Director.

#### Shared controls:

- 4: **Heading knob**. Rotate: move heading bug. Push: set heading bug to
  current heading.
- 5: **Speed knob**. Rotate: select target speed. Push: switch KIAS / Mach.
  Rotate ring: switch manual selection / FMS managed speed.
- 6: **Altitude knob**. Rotate: select target altitude in 100ft increments.
  Shift-rotate: select target altitude in 1000ft increments. Push: toggle ft/m
  (NOT IMPLEMENTED YET).
- 7: **FPA knob**. Select flight path angle when in FPA mode.
- 8: **V/S wheel**. Select vertical speed when in VS mode.
- 13: **NAV button**. Select NAV lateral mode. When navigation source is FMS1
  or FMS2, engage LNAV mode (track flight plan); when navigation source is NAV1
  or NAV2, engage VOR mode (track VOR radial).
- 14: **APP button**. Arms lateral and vertical approach mode: lateral mode LOC
  (localizer) is armed, and becomes active when the localizer is captured;
  vertical mode GS (glideslope) is armed, and becomes active when the
  glideslope is intercepted. Before intercept, the currently selected lateral
  and vertical modes remain active.
- 15: **HDG button**. Selects the lateral HDG mode; if HDG mode is already
  active, selects "wings level" mode instead.
- 16: **AP button**. Engages / disconnects the autopilot.
- 17: **YD button**. Turns the Yaw Damper on or off. In normal flight, the yaw
  damper should always be on.
- 18: **SRC button**. Switches navigation source between the captain's side
  (NAV1 / FMS1) and the first officer's side (NAV2 / FMS2).
- 19: **A/T button**. Engages / disengages autothrottle.
- 20 **VNAV button**. Turns VNAV (vertical navigation) on or off. In VNAV mode,
  the FMS automatically selects vertical modes for the autopilot to match the
  vertical profile calculated from the current flightplan. The aircraft will
  not, however, climb or descend through the selected altitude.
- 21 **FLCH button**. Selects FLCH (Flight Level Change) vertical mode. If the
  selected target altitude is higher than the current altitude, FLCH will
  command climb thrust, and speed-with-pitch, in order to achieve the optimal
  climb rate to the target altitude. If the selected target altitude is lower
  than the current altitude, FLCH will command idle thrust, and
  speed-with-pitch, in order to achieve an optimal descent path. In both cases,
  the selected airspeed will be maintained. If A/T is off, the pilot is
  responsible for setting appropriate thrust for the climb or descent.
- 22 **ALT button**. Selects ALT hold mode. This will also set the target
  altitude to the nearest multiple of 100 ft of the current altitude. Note that
  you do not normally need this button, because in all climb and descent modes,
  the aircraft automatically levels off at the target altitude, and switches to
  ALT mode by itself.
- 23 **FPA button**. Selects FPA mode (flight path angle). When this button is
  pushed, the aircraft will hold the current flight path angle until
  intercepting the target altitude; by turning the FPA knob (7), the flight path
  angle can be adjusted.
- 24 **VS button**. Selects VS mode (vertical speed). When this button is
  pushed, the aircraft will hold the current vertical speed until
  intercepting the target altitude; by turning the VS wheel (8), the flight path
  angle can be adjusted.

### PFD Autopilot Mode Annunciations

![Autopilot Annunciations](images/pfd-autopilot.jpg)

- 1 **Speed target**. Displays the current speed target in KIAS or Mach. In
  FMS Managed Speed mode, this display will be magenta; in Manual Speed mode,
  it will be blue.
- 2 **Autothrottle Mode**. Upper = active, lower = armed. SPDt means speed
  with throttle, SPDe means speed with elevator. TO, GA and HOLD are special
  modes for takeoff and go-around.
- 3 **AP and AT engagement**. Upper = AP engaged, lower = AT engaged.
- 4 **Nav source**. Left = captain side, right = FO side. (NOT IMPLEMENTED
  YET).
- 5 **Lateral mode**. Upper = active, lower = armed. TRACK = track runway
  heading (takeoff / go-around), ROLL = roll hold,
  HDG = track selected heading, VOR = track VOR
  heading, LOC = track ILS localizer, LNAV = track FMS route. (Note that ROLL
  will command 0° bank if bank angle is less than 6° upon activation).
- 6 **Vertical mode**. Upper = active, lower = armed. TO = takeoff, GA =
  go-around, FLCH = flight level change, FPA = flight path angle, VS = vertical
  speed, GS = ILS glideslope. If VNAV is active, modes are selected by the FMS,
  and labelled VTO, VGA, VFLCH, VFPA. (VNAV never selects VS, so VVS does not
  exist; VNAV should be disabled before arming APPR, so VGS is not a thing
  either).
- 7 **Altitude target**. In VNAV mode: the altitude to which you are cleared to
  climb or descend. VNAV will follow the calculated profile, but never climb
  or descend past this altitude. In non-VNAV mode: the altitude at which to
  level off.
- 8 **FPA / VS target**. The currently selected vertical speed or flight path
  angle. In VNAV mode, the FMS will set this.
- 9 **Autoland annunciation**. Left, white = armed, right, green = active.
  APPR1 means CAT-I autoland, APPR2 means CAT-II autoland.

### Basic Autopilot Usage

Under normal conditions, you will only use the following procedures:

- Before takeoff: confirm that the autopilot is in TO mode (push the TOGA
  button, "Q" key on the keyboard, if not). Select your initial climb altitude
  using the ALT SEL knob. If flying an FMS route, push NAV to arm LNAV mode;
  otherwise, set the heading bug to the runway heading, and push HDG to arm HDG
  mode. Select an appropriate airspeed target for the departure using the SPD
  SEL knob (typically between 180-220 kts).
- Line up on the runway, set 40% thrust, wait for the engines to stabilize,
  then set takeoff thrust. At VR, pull up, retract gear on positive climb,
  retract flaps as appropriate, enable AP and AT. Once sufficient altitude is
  achieved, the autopilot will switch the lateral mode to LNAV or HDG, and the
  vertical mode to FLCH, and the autothrottle will switch from TO to SPDe. The
  aircraft now climbs to the selected altitude at climb thrust.
- In flight, the procedure for climbing or descending to a different altitude
  is: 1. select target altitude 2. push FLCH. This will select appropriate
  modes for both the AT and the AP, and the aircraft will level off
  automatically.
- To speed up or slow down, simply turn the SPD SEL knob.
- When passing FL290, the aircraft will automatically switch between KIAS and
  Mach speed target selection.
- To deviate from the flight plan and just fly a heading, push the HDG SEL knob
  to synchronize the heading bug with the current heading, then push the HDG
  button to switch to HDG mode, and then rotate the HDG SEL knob to turn to the
  desired heading. Pushing NAV will revert back to LNAV mode, and the aircraft
  will immediately turn to navigate to the current waypoint.
- When approaching your destination, make sure you have the correct ILS
  frequency selected on NAV1; fly on a suitable intercept heading (either using
  the FMS flightplan, or manually in HDG mode) and altitude, then push APP to
  arm LOC and GS mode. If all goes well, the LOC and GS modes will
  automatically engage when the localizer and glideslope are intercepted.
- Once established on the glideslope, extend landing gear, set flaps as
  appropriate, and reduce speed with the SPD SEL knob. The APPR1 annunciations
  should appear on the top of the PFD, first the white one, then the green.
  Disengage AP and AT around 1000 ft AGL, and manually land the aircraft.

### Autopilot disconnection

The autopilot will disconnect under the following circumstances:

- Pushing the AP disconn button on the yoke or the Z key (normal disconnect)
- Pushing the AP button on the glareshield panel while the autopilot is active
  (normal disconnect)
- Small inputs on the yoke or rudder for more than 5 seconds (non-normal
  disconnect)
- Large inputs on the yoke or rudder (non-normal disconnect)
- Various failures (non-normal disconnect, not implemented)

When the autopilot disconnects, the AP annunciation on the PFD will flash red,
and there will be an aural alert "AUTOPILOT, AUTOPILOT", until you push the
yoke button or the AP button on the glareshield panel again.

### TCS (Touch Control Steering)

The autopilot can be temporarily bypassed without disconnecting it entirely,
using the TCS button (W key in most views, including all cockpit views).

While the TCS button is depressed, the rudder and yoke controls will
temporarily control the aircraft; when the TCS button is released, the
autopilot resumes its previously selected modes.

If the lateral mode was ROLL before using TCS, then releasing TCS will
re-synchronize aircraft roll attitude with the autopilot; otherwise, it will
resume the previously commanded heading or NAV course.

If the vertical mode was FPA, then releasing TCS will sync the FPA target to
the current FPA. If the vertical mode was VS, then releasing TCS will sync the
VS target to the current vertical speed. In all other modes, the target will
remain unaffected.

### Advanced Autopilot Usage: VNAV

In VNAV mode, the autopilot automatically attempts to follow a vertical profile
derived from the active flight plan and configured cruise altitude. However, it
will never climb or descend beyond the selected target altitude, and if at any
point it levels off at the target altitude, it will hold that altitude even
when the target altitude is changed, until one of two things happens:

- A waypoint is reached that triggers the VNAV logic to initiate another
  altitude change (typically, this is a waypoint with an altitude restriction)
- The pilot pushes the FLCH button to manually force the autopilot into VFLCH
  mode. The autopilot will then climb or descend in FLCH mode until
  intercepting the profile, and then switch to VFPA or VALT mode.

It is highly recommended to disable VNAV when trying to intercept the ILS,
because any VNAV-induced autopilot mode changes will disengage / disarm APP
mode.

### Advanced Autopilot Usage: FMS Managed Speed

In FMS Managed Speed mode, the FMS will automatically select speed targets
appropriate for the current flight phase, and according to speed restrictions
on the flight plan. In order for this to work, the following things should be
configured correctly:

- An active flight plan (via Route Manager, or the RTE and FPL pages in the
  MCDU)
- Performance settings for all flight phases (via the E-Jet family >
  Performance Config menu, or via the PERF INIT and PERFORMANCE > TAKEOFF and
  PERFORMANCE > LANDING pages in the MCDU)

Managed speed will use the following logic:

- During takeoff, target V2 until reaching V2, then target V2 + 10 until
  reaching the final segment altitude, then target VFS (final segment speed),
  then departure speed; when vertical AP mode switches to FLCH, target climb
  speed.
- During climbs, target climb speed (default: 280 kts), but respect low
  altitude limit (default: 250 kts below 10,000 ft / FL100), and interpolate
  speed between limit and limit + 2000 ft to produce a gradual speed-up that
  does not arrest the climb entirely. At FL290, switch to climb Mach (default:
  Mach .73).
- Once levelled off after reaching cruise altitude, speed up to configured
  cruise speed (default: 300 kts below FL290, Mach .77 above FL290).
- When descending, select descent speed (default: 290 kts / Mach .77), but
  respect low-altitude limit (default: 250 kts below 10,000 ft / FL100), using
  the same interpolation as for the climb.
- For the approach (within 15 nmi from the destination), reduce speed to
  initial approach speed.
- When flaps are set during the approach phase, reduce speed for the next flap
  setting, down to final approach speed (Vref + 5 or Vref + 10).
- Speed restrictions in the flight plan overrule the above when they are lower
  (e.g., a speed restriction of 220 KIAS on the departure will prevent the
  aircraft from speeding up to 250 KIAS for the climb).

### Autoland

All flavors of E-Jet in this package are equipped with CAT-II autoland.

The aircraft has two precision approach modes: APPR1 (CAT-I ILS approach,
manual landing), and APPR2 (CAT-II ILS approach, autoland). The BARO/RA knob on
the active side selects the desired approach type: "BARO" for CAT-I, "RA" for
CAT-II. Autoland is only possible when APPR2 has successfully engaged.

Conditions for *arming APPR1*:

- Arrival runway configured as part of the current MCDU flightplan
  (NAV -> ARRIVAL)
- Correct ILS frequency set on the selected NAV src on the active side
- APP mode armed or engaged

Conditions for *arming APPR2*:

- BARO/RA set to "RA" on both PFD's (Captain and FO)
- Same minimums altitude set on both PFD's
- Arrival runway configured as part of the current MCDU flightplan
- Correct ILS frequency set on both NAV radios
- Captain's NAV SRC set to NAV1
- FO's NAV SRC set to NAV2
- APP mode armed or engaged

The armed approach mode is annunciated on the PFD in white. If the BARO/RA knob
on the active side is set to "BARO", only APPR1 will arm, requiring a manual
landing. If the BARO/RA knob on the active side is set to "RA", but one or more
of the other conditions are not met, an amber "APPR1 ONLY" annunciation
displays, indicating that despite RA being selected, only APPR1 can be engaged.

Below 1500 ft, the armed approach mode engages, producing a green annunciation.
APPR2, however, can only be engaged if **flaps 5** is set. If all the
conditions for APPR2 are met except flaps, the APPR2 mode will remain armed
until flaps 5 is set, or the aircraft descends below 800 ft AGL.

At 800 ft AGL, the best possible approach mode locks in and cannot be upgraded
anymore. If at this point APPR2 was armed, but flaps 5 isn't set, the approach
downgrades to APPR1.

Procedure for a CAT-II approach and autoland:

DURING DESCENT:
- ARRIVAL RUNWAY - CONFIGURED IN MCDU FPL
- NAV1 FREQUENCY - SET TO ILS FREQUENCY
- NAV2 FREQUENCY - SET TO ILS FREQUENCY
- CAPTAIN'S NAV SRC - LOC1 OR FMS + PREVIEW LOC1
- FO'S NAV SRC - LOC2 OR FMS + PREVIEW LOC2
- BARO/RA - RA ON BOTH SIDES
- MINIMUMS - SET AND MATCHING ON BOTH SIDES
- ALTIMETERS - SET TO LOCAL QNH
- AUTOBRAKE - AS NEEDED

APPROACH:
- APP MODE - ARM
- APPR MODE ANNUNCIATION - VERIFY WHITE APPR2
- LOCALIZER - INTERCEPT
- GLIDESLOPE - INTERCEPT

AT 1500 FT:
- APPR MODE ANNUNCIATION - VERIFY WHITE APPR2
- FLAPS - 5
- APPR MODE ANNUNCIATION - VERIFY GREEN APPR2

AT 800 FT:
- APPR MODE ANNUNCIATION - VERIFY GREEN APPR2

TOUCHDOWN:
- THROTTLE - VERIFY IDLE
- REVERSERS - DEPLOY AS NEEDED
- THROTTLE - REVERSE THRUST AS NEEDED
- SPOILERS - VERIFY EXTENDED
- AUTOPILOT - DISENGAGE

60 KNOTS:
- THROTTLE - IDLE
- BRAKE - MANUALLY

40 KNOTS:
- REVERSERS - STOW

## Flight Controls

### Throttles

The E-Jet family is equipped with a FADEC system and TRS (Thrust Rating
System).

The normal operative range of the throttle levers is between 0 and 95%
of their travel range; the top 5% command "takeoff reserve" thrust when in
TOGA mode, or "max continuous" thrust in normal flight, overriding the normal
thrust limits.

### TRS (Thrust Rating System)

Thrust limits are governed by the TRS, and can be configured via the MCDU, in
the "PERF" -> "TAKEOFF" screen.

For the takeoff, three TRS modes are available, labelled TO-1, TO-2 and TO-3;
TO-1 delivers full normal takeoff performance, TO-2 and TO-3 provide downrated
engine thrust for lighter takeoffs, longer runways, and/or cool and low
conditions. In addition, there are three "FLEX-TO" modes, which automatically
provide the same absolute thrust as the non-FLEX takeoff mode would in standard
conditions, up to actual TO-1 thrust (that is, if the FLEX mode would require
a higher thrust setting than normal TO-1, TO-1 thrust will be provided
instead). **NOTE** FLEX takeoff is not yet implemented in the FG E-Jets.

Go-around mode (GA) always uses the same thrust limit as TO-1.

For the climb, two modes are available: CLB-1 (full climb thrust) and CLB-2
(downrated climb thrust). The appropriate one is selected automatically based
on TO mode selection.

In cruise, the engine is downrated to CRZ after 90 seconds of level
unaccelerated flight; it automatically switches back to CLB-1 or CLB-2 when
significant accelerations or climbs are commanded.

Advancing the throttle levers to more than 95% of their travel range engages
"TOGA RES" (TO/GA Reserve) mode when close to the ground, or "MAX CON" when in
the air, overriding the above ratings and driving the engines to max N1. Hence,
it is advisable to stop the throttle levers just short of firewalling them in
order to set takeoff / go-around thrust.

Note that the autoflight system will never command TOGA RES or MAX CON thrust;
hence, to extract maximum climb performance from the aircraft, it is necessary
to disengage the autothrottle.

### Thrust Reversers

Thrust reversers may only be deployed (DEL key) after touchdown, and with the
thrust lever in the IDLE position.

For a normal landing, deploy reversers immidately after main landing gear
touchdown, gently forward thrust lever to full reverse; retard at 60 kts,
cancel reversers at 40 kts.

For a rejected takeoff, full reverse thrust may be used until the aircraft has
come to a full stop.

### Flaps

The flap lever controls flaps, slats, and ground spoilers. Settings 1 through 4
are for takeoff and approach, and extend flaps and slats. Settings 5 and FULL
(6) are for landing, and additionally arm ground spoilers. Settings 4 and 5 are
identical, except that flaps 5 arms ground spoilers while flaps 4 does not
(because flaps 4 is for takeoff / approach, but flaps 5 is for landing).

### Speedbrake

The speedbrake lever controls spoiler deployment to increase drag and reduce
lift in flight, typically to achieve a rapid descent. The speedbrake lever in
this simulation has 5 positions (up, 1/4, 1/2, 3/4, full), which you can cycle
with the Ctrl-B key (and backwards with Ctrl-Shift-B). For a detailed
description of spoiler functionality see below, under Fly-By-Wire.

### Autobrakes

The autobrake knob is used to configure automatic braking for landing and
rejected takeoff. It has the following positions:

- **RTO**, used for rejected takeoff. In this position, the autobrake system
  will apply maximum brakes when there is weight-on-wheels, and the thrust
  levers are retarded to the idle position or the thrust reversers are
  deployed. Brakes remain applied until the pilots input brakes (switching to
  manual braking), or wheel rotations speed reaches zero, or the autobrake knob
  is rotated to the "OFF" position.
- **OFF**: no autobrake whatsoever.
- **LOW**: at touchdown, apply brakes to achieve a constant deceleration of
  0.175g until manual brake input, wheel speed < 60 kts, or autobrake knob
  turned into OFF position
- **MED**: at touchdown, apply brakes to achieve a constant deceleration of
  0.3g until manual brake input, wheel speed < 60 kts, or autobrake knob turned
  into OFF position
- **HI**: at touchdown, apply maximum brakes until manual brake input, wheel
  speed < 60 kts, or autobrake knob turned into OFF position

In the LOW and MED modes, deploying reversers will reduce brake wear and
heating, but will not change the required landing distance or deceleration
rate.

### Fly-By-Wire

The E-Jet has an open-loop FBW system controlling the elevator, rudder, and
spoilers.

The system provides the following functionality:

#### Elevator

- **Elevator Thrust Compensation (ETC)**: the FBW automatically changes
  elevator deflection to compensate for the pitch-up moment resulting from
  higher power settings. This feature is disabled when close to the ground, so
  as to not interfere with takoff rotation and landing flare.
- **Tail Strike Avoidance (TSA)**: close to the ground, the FBW limits maximum
  pitch to avoid tailstrikes. As the pitch attitude approaches the limit,
  elevator authority is reduced.
- **Mach Compensation**: At high Mach numbers, elevator authority is reduced to
  compensate for the increased effectiveness of control surfaces.

#### Rudder

- **Yaw Damper**

#### Spoilers

The spoiler system consists of 10 spoiler panels, in 4 groups. On each wing,
there is an outboard group of 3 multi-function spoiler panels, and an inboard
group of 2 ground spoilers.

The multi-function spoilers are used for the following purposes:

- **Speedbrake**, according to speedbrake lever. Speedbrakes automatically retract
  when flaps 2 or higher is selected.
- **Ground spoilers.** When flaps 5 of FULL is selected, and the speedbrake
  lever is in the "UP" position, the spoilers will extend fully upon
  weight-on-wheels, and retract when either TOGA is activated, or airspeed
  drops below 60 knots. Ground spoilers also deploy when a rejected takeoff is
  detected.
- **Roll control.** Multi-function spoilers deploy asymmetrically to support
  aileron input (the ailerons themselves are actuated mechanically, and do not
  offer FBW features).
- **Steep approach configuration.** (This feature is available as an option in
  the real aircraft; the FG model has it on all types in the family). The STEEP
  APPROACH button on the center pedestal activates steep approach mode; when
  this mode is selected, and flaps 2 or higher are selected, the spoilers will
  deploy 50%, +/- elevator input. This allows the aircraft to descend on a
  steep glide path while keeping the engines running at about 55% N1, and
  increases vertical controllability. The steep approach mode automatically
  disarms when weight-on-wheels is detected, or when TOGA is activated.
  Retracting flaps to UP or flaps 1 disables steep approach, but keeps it
  armed. Steep approach cannot be armed or engaged on the ground.

The inboard ground spoilers only deploy as ground spoilers, together with the
outboard panels, and follow the same logic.

#### FBW Laws

Each FBW channel has 2 laws: "Normal Law", in which all of the above
functionality is available, and "Direct Law", in which control surfaces mirror
raw control inputs, except spoilers, which simply will not deploy at all.

Direct Law is activated whenever there is a failure that may indicate a
malfunction that makes Normal Law unusable or unsafe; it is also possible to
manually select Direct Law using the three guarded pushbuttons on the center
pedestal, above the engine controls.

The currently selected law for the rudder and elevator channels can also be
monitored on the MFD's "Flight Controls" page.

## SimBrief Import Feature

The SimBrief import feature has been removed, as the SimBrief import add-on
provides the exact same functionality. You can download it from

https://github.com/tdammers/fg-simbrief-addon

## MCDU Route Entry

The FMS supports entering airway routes, just like the real aircraft. However,
because the way airway data is exposed to aircraft models from FG core is
insufficient for this, the E-Jet relies on finding and parsing the airway data
file itself. To make this work, you need to have a file named
`/NavData/awy/awy.dat` in one of your scenery directories (the propery tree has
a list of all the directories to look in under `/sim/fg-scenery`; you can
configure these through the launcher, or by passing one or more `--fg-scenery`
arguments to the `fgfs` binary on startup).

FlightGear ships with a severely outdated `awy.dat.gz` as part of FGDATA; this
file will not work as-is, but if you want to use it for the E-Jet, you can
simply un-gzip it.

To check which nav data has been loaded, consult the FMS "NAV IDENT" page. It
should show an indication of the loaded dataset, as well as the date range of
validity, based on the self-reported AIRAC cycle in the loaded file, if any. If
no file has been loaded, this will be reported as "19SEP 16OCT/13", and
"FG-MINIMAL", indicating that only basic navigation data is available (no
airways). If you have an awy.dat from Navigraph, it will be reported as
"NAVIGRAPH", with dates corresponding to the reported AIRAC cycle; awy.dat
files from XPlane will also work, and report as "AWYXP700" or similar.

## Electronic Flight Bag (EFB)

The EFB is a virtual tablet that can be used to view charts in PDF format. See
the [EFB documentation](./EFB.markdown) for details on how to get content into
the EFB.

General operation:

- The screen is clickable, simulating a **touchscreen**
- LMB clicking on the case flips between portrait and landscape **orientation**
- Mouse wheel on the case adjusts **brightness**
- MMB clicking on the case operates the **power** button

## CPDLC / ACARS

The E-Jet Family supports in-sim [CPDLC (Controller-Pilot Data Link
Communications)](https://en.wikipedia.org/wiki/Controller%E2%80%93pilot_data_link_communications),
controlled via the MCDU.

Three transport backends are provided:

- **"NONE"**, a dummy backend that never becomes available. This backend can be
  used to effectively disable the entire CPDLC system.
- **"FGMP"**: this backend connects to IRC via FG's built-in CPDLC API, on FG
  versions that support it. It becomes available whenever you are connected to
  the FG Multiplayer environment.
  *Side note:* FG's built-in CPDLC API does not implement MIN/MRN, and because
  of this, matching replies to requests is a best guess, based on message types
  and sequencing. If you use the FGMP backend, it is recommended that you do
  not issue a new request until all previous dialogs have been closed, as
  uplinks referring to older requests may otherwise be incorrectly interpreted
  as replies to the newer request.
- **"HOPPIE"**: this connects to [Hoppie's ACARS](http://www.hoppie.nl/acars/),
  an HTTP-based ACARS/CPDLC environment used for VATSIM and other networks. To
  use the Hoppie backend, you will need to install and configure the [Hoppie
  ACARS addon](https://github.com/tdammers/fg-hoppie-acars). The Hoppie backend
  will become available when the Hoppie ACARS addon is loaded and connected.
  *Side note:* The Hoppie system does not transmit ICAO 4444 standard message
  codes, instead, it transmits formatted messages in plaintext, using '@' signs
  to mark variables. As a result, the CPDLC system will only understand
  messages correctly if they are spelled exactly as specified in ICAO doc 4444,
  and if variables are marked with '@'. Any deviation from this will cause the
  CPDLC system to downgrade such messages to "FREE TEXT"; you will still be
  able to read them and issue standard and free text replies, but variables
  will not be detected, and message-specific reply options will not be given.

### Usage

First, select the backend you want to use. On the MCDU, press the `NAV` button,
then select `ATC` (LSK 1R), and then, on page 2, `DATALINK CFG` (LSK 1L).
Select the backend you want to use, and return to page 1 of the `ATC INDEX`
page.

On the `LOGON/STATUS` page, the `DATALINK STATUS` line tells you whether the
transport is working; if it says "READY", then you are connected to the
selected transport. In the middle of the screen, between "FLT ID" and "ACT
CTR", you can see which backend is currently in use.

You can use the `LOGON TO` field to enter a station you want to log on to, and
then push `SEND` (LSK R1) to request a logon. The remaining logon process, as
well as handovers, and automatic.

The `LOG` page lists recent messages, both uplinks (from ATC to you) and
downlinks (from you to ATC). This should be largely self-explanatory. Use the
LSK's on the right to open a message, read it, and possibly respond to it.

The remaining items on the `ATC INDEX` page allow you to compose downlinks from
predefined standard templates to initiate a new dialog.
