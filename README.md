# E-Jet-Family-YV

## An advanced simulation of the Embraer Family for FlightGear.

This aircraft was modified and updated in a joint effort by the following people @2020:

- Gabriel Hernandez (YV3399)
- D-ECHO
- Tobias Dammers (tdammers / nl256)
 
# Installation

## Recommended Method

- Get the latest release from
  https://github.com/YV3399/E-jet-family-YV/releases/latest
- Unzip in your Aircraft directory

Other installation methods: see bottom of this document. This is necessary
because too many people do not read instructions properly, install things
incorrectly, and then complain about it on discord etc. Sorry for the
inconvenience.

# About

Present pack includes the following Embraer Family variants:

- Embraer 170
- Embraer 175
- Embraer 190
- Embraer 195
- Embraer Lineage 1000
- ~~Embraer 175-E2~~

**A note on the -E2**

The real-world Embraer E-Jet E2 series is a complete overhaul of the original
first-gen E-Jet. The version included in this pack is nowhere near the real
thing; it is included because it was there when I (tdammers) started working on
it, but most of the improvements made to the other models have not been ported
to the E2. In its current state, it should be considered "broken". Doing the E2
right would be a gargantuan task, and I feel that doing it wrong isn't worth
doing at all.

~~Hence, the E2 is provided "as-is"; it probably doesn't work at all, and if it
does, then it is almost guaranteed to be incorrect in all sorts of ways. If
anyone wants to step forward, feel free to send patches - but for the time
being at least, consider the E2 "highly experimental" at best.~~

**Update (2021-03-18):** By now, the E2 has drifted from the rest of the family
to the point of not working at all anymore, so I decided to remove it. If at
any point anyone decides to dig it up and make it work, then resurrecting the
relevant files from git should be no problem; but in its current shape, the
only thing it did was confuse people.

# Further Documentation

See https://github.com/YV3399/E-jet-family-YV/blob/master/Documentation/guide.markdown

This document includes some essential procedures and a quick guide to the
aircraft. It is not a substitute for a full Flight Crew Operating Manual
(FCOM), but it should be enough to get you flying.


# Alternate Installation Instructions

The installation instructions should only be used if you know what you are
doing. If you have made it here and haven't read any installation instructions
yet, then please scroll back up and read again.

## From a github source bundle

- Get a source bundle from
  https://github.com/YV3399/E-jet-family-YV/archive/master.zip (or go to
  https://github.com/YV3399/E-jet-family-YV and click the green "Code" button)
- Unzip in your Aircraft directory
- **REMOVE THE `-YV-master` PART FROM THE DIRECTORY NAME**. The aircraft won't
  work properly if you don't do this.

## Using `git`

- `git clone https://github.com/YV3399/E-jet-family-YV $FGROOT/Aircraft/E-jet-family-YV`
  (replace `$FGROOT` with whatever is suitable - if you don't know what it
  should be, then you probably shouldn't be using this method). If you have a
  github account, you can also clone from
  `git@github.com/YV3399/E-jet-family-YV`, or fork on github and clone from
  your fork instead.
