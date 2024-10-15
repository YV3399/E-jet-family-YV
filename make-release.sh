#!/bin/bash
rm -rf ./release
mkdir -p ./release/E-jet-family
cp -R \
    common.xml \
    COPYING.md \
    Data \
    Documentation \
    DualControl \
    E17x-copilot-set.xml \
    Embraer170-set.xml \
    Embraer175-set.xml \
    Embraer190-set.xml \
    Embraer195-set.xml \
    EmbraerLineage1000-set.xml \
    Engines \
    FDM \
    Fonts \
    gui \
    License.txt \
    Models \
    Nasal \
    README.md \
    Sounds \
    sound.xml \
    Splash \
    Systems \
    Thanks.txt \
    thumbnail.jpg \
    WebPanel \
    ./release/E-jet-family/
cd release
zip -r E-jet-family.zip E-jet-family
