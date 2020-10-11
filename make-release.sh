#!/bin/bash
rm -rf ./release
mkdir -p ./release/E-jet-family
cp -R \
    Data \
    Documentation \
    DualControl \
    Embraer170-set.xml \
    Embraer175E2-set.xml \
    Embraer175-set.xml \
    Embraer190-set.xml \
    Embraer195-set.xml \
    EmbraerLineage1000-set.xml \
    Engines \
    ERJ170.xml \
    ERJ175-E2.xml \
    ERJ175.xml \
    ERJ17x-copilot-set.xml \
    ERJ190.xml \
    ERJ195.xml \
    ERJ-set-common.xml \
    ERJ-sound.xml \
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
    XMLs \
    ./release/E-jet-family/
cd release
zip -r E-jet-family.zip E-jet-family
