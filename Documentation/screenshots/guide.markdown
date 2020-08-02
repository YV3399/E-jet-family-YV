# FlightGear Embraer E-Jet Family - User Guide

## Introduction

![Parked at the gate, EHAM](./screenshots/parked-eham.jpg)

The E-Jet family is a series of narrow-body regional airliners, built by
Brazilian aerospace manufacturer Embraer. They offer a high degree of
automation, and features that are normally only found in larger jets. Their
high efficiency on short routes, and their good short-field performance, make
them a popular and commercially successful aircraft with regional airlines
around the world. The E190 is among the largest aircraft certified to operate
at London City Airport (EGLC).

This FlightGear implementation features the following first-generation E-Jet
models:

- **E170**, the oldest and smallest type. Typically seats 66-72 passengers. Two
  GE CF34-8E engines deliver 14,200 lbf thrust each.
- **E175**, a slightly stretched version of the original E170. Same wing, same
  engines; typically seats 76-78.
- **E190**, a further stretch of the E170 fuselage, using a larger wing and
  more powerful GE CF34-10E engines (2x 18,500 lbf thrust). Typically seats
  96-100, and features various improvements over the E170/E175.
- **E195**, a slightly stretched version of the E195; same wing and engines.
  Typically seats 100-116.
- **Lineage 1000**, a luxury bizjet conversion of the E190. The entire lower
  deck is filled with an additional fuel tank, extending the aircraft's range
  to 4,600 nmi; the upper deck can be configured to the client's
  specifications, and may feature a double-sized galley, a 2-person bedroom
  suite, and a full bathroom.

More info at [wikipedia](https://en.wikipedia.org/wiki/Embraer_E-Jet_family).

## Flight Deck Overview

![Flightdeck](./screenshots/flightdeck-overview)

- PFD: combines the functions of the traditional "sixpack", plus a wide range
  of additional information.
- MFD: displays navigation and systems management information.
- EICAS: displays status information about the engines, flight controls, and
  other aircraft systems, as well as alerts.
- MCDU: the main interface to the flight management system (FMS); also used to
  tune the various radios.
- Glareshield Panel: controls autopilot, autothrottle, MFD configuration, and
  configures the altimeter (QNH and minimums).
- Autobrake Control: selects autobrake mode.

## A Typical Flight

### Cold And Dark.

So we just spawned at a gate: B17 at EHAM to be precise. Before starting up the
aircraft, let's gather some key information:

- Flight plan. We will fly into EDDM (Munich Franz-Josef Strauss), and the
  route we will take is: EDUPO Z739 DEGOM L603 TESGA UL603 AKANU. The easiest
  way to get this route loaded up at this time is to save it from, say,
  http://onlineflightplanner.org/ or https://www.skyvector.com/.
