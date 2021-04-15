#!/bin/bash
rm -rf ./release
mkdir -p ./release/E-jet-family
cp -R \
    Data \
    Documentation \
    DualControl \
    Embraer170-set.xml \
    Embraer175-set.xml \
    Embraer190-set.xml \
    Embraer195-set.xml \
    EmbraerLineage1000-set.xml \
    Engines \
    E17x-copilot-set.xml \
    common.xml \
    sound.xml \
    FDM \
    Fonts \
    gui \
    License.txt \
    Models \
    Nasal \
    README.md \
    Sounds \
    Splash \
    Systems \
    Thanks.txt \
    thumbnail.jpg \
    ./release/E-jet-family/
cd release
zip -r E-jet-family.zip E-jet-family
