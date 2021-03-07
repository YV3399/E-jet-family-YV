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
    E170.xml \
    E175-E2.xml \
    E175.xml \
    E17x-copilot-set.xml \
    E190.xml \
    E195.xml \
    common.xml \
    sound.xml \
    FDM \
    gui \
    License.txt \
    Lineage1000.xml \
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
