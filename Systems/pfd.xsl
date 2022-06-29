<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:param name="index"/>
    <xsl:output method="xml" indent="yes" />
    <xsl:variable name="otherIndex">
        <xsl:choose>
            <xsl:when test="$index=0">1</xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:template match="/">
        <!-- Following comment only pertains to the output of this template,
             not the template itself. -->
        <xsl:comment><![CDATA[
DO NOT HAND EDIT THIS FILE

This file (pfd]]><xsl:value-of select="$index + 1"/><![CDATA[.xml) has been
generated from a template and will be overwritten when build.sh
runs. If you want make changes to the PFD XML, edit pfd.xsl and
re-run build.sh.
]]></xsl:comment>
        <PropertyList>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>AP Annunciator State</name>
                <type>gain</type>
                <gain>1</gain>
                <input>
                    <condition>
                        <and>
                            <property>instrumentation/annun/ap-disconnect-warning</property>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/blink-state</property>
                        </and>
                    </condition>
                    <value>3</value>
                </input>
                <input>
                    <condition>
                        <property>instrumentation/annun/ap-disconnect-warning</property>
                    </condition>
                    <value>2</value>
                </input>
                <input>
                    <condition>
                        <property>it-autoflight/output/ap1</property>
                    </condition>
                    <value>1</value>
                </input>
                <input>
                    <value>0</value>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fma/ap</output>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>AP Annunciator State</name>
                <type>gain</type>
                <gain>1</gain>
                <input>
                    <condition>
                        <and>
                            <property>instrumentation/annun/at-disconnect-warning</property>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/blink-state</property>
                        </and>
                    </condition>
                    <value>3</value>
                </input>
                <input>
                    <condition>
                        <property>instrumentation/annun/at-disconnect-warning</property>
                    </condition>
                    <value>2</value>
                </input>
                <input>
                    <condition>
                        <property>it-autoflight/output/athr</property>
                    </condition>
                    <value>1</value>
                </input>
                <input>
                    <value>0</value>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fma/at</output>
            </filter>
            <!-- Altitude tape -->
            <filter>
                <name>Alt Tape Offset</name>
                <type>gain</type>
                <gain>1</gain>
                <period>
                    <min>0</min>
                    <max>1000</max>
                </period>
                <input>
                    <expression>
                        <floor>
                            <property>instrumentation/altimeter[<xsl:value-of select="$index"/>]/indicated-altitude-ft</property>
                        </floor>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/alt-tape-offset</output>
            </filter>
            <filter>
                <name>Alt Bug Offset</name>
                <type>gain</type>
                <gain>1</gain>
                <input>
                    <expression>
                        <floor>
                            <difference>
                                <property>instrumentation/altimeter[<xsl:value-of select="$index"/>]/indicated-altitude-ft</property>
                                <property>controls/flight/selected-alt</property>
                            </difference>
                        </floor>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/alt-bug-offset</output>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Alt Tape Thousands</name>
                <type>gain</type>
                <gain>1</gain>
                <input>
                    <expression>
                        <floor>
                            <div>
                                <property>instrumentation/altimeter[<xsl:value-of select="$index"/>]/indicated-altitude-ft</property>
                                <value>1000</value>
                            </div>
                        </floor>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/alt-tape-thousands</output>
            </filter>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>FPA</name>
                <type>gain</type>
                <input>
                    <condition>
                        <greater-than>
                            <property>velocities/groundspeed-kt</property>
                            <value>40</value>
                        </greater-than>
                    </condition>
                    <expression>
                        <atan2>
                            <product>
                                <property>velocities/vertical-speed-fps</property>
                                <value>0.5925</value>
                            </product>
                            <property>velocities/groundspeed-kt</property>
                        </atan2>
                    </expression>
                </input>
                <input>
                    <value>0</value>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fpa-rad</output>
            </filter>
            <filter>
                <name>FPA deg</name>
                <type>gain</type>
                <gain>57.29577951308232</gain>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/fpa-rad</property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fpa-deg</output>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Track Error</name>
                <type>gain</type>
                <gain>1</gain>
                <input>
                    <expression>
                        <difference>
                            <property>orientation/track-magnetic-deg</property>
                            <property>orientation/heading-magnetic-deg</property>
                        </difference>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/track-error-deg</output>
            </filter>

            <!-- SLAVING -->

            <filter>
                <name>Slave minimums mode</name>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/slaved</property>
                    </condition>
                </enable>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$otherIndex"/>]/minimums-mode</property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-mode</output>
            </filter>
            <filter>
                <name>Slave minimums baro</name>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/slaved</property>
                    </condition>
                </enable>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$otherIndex"/>]/minimums-baro</property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-baro</output>
            </filter>
            <filter>
                <name>Slave minimums radio</name>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/slaved</property>
                    </condition>
                </enable>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$otherIndex"/>]/minimums-radio</property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-radio</output>
            </filter>
            <filter>
                <name>Slave altimeter qnh mode</name>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/slaved</property>
                    </condition>
                </enable>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$otherIndex"/>]/qnh-mode</property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/qnh-mode</output>
            </filter>
            <filter>
                <name>Slave altimeter setting hpa</name>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/slaved</property>
                    </condition>
                </enable>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$otherIndex"/>]/setting-hpa</property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/setting-hpa</output>
            </filter>
            <filter>
                <name>Slave altimeter setting inhg</name>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/slaved</property>
                    </condition>
                </enable>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$otherIndex"/>]/setting-inhg</property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/setting-inhg</output>
            </filter>

            <!-- MINIMUMS -->
            <!-- mk-viii does not support actual baro minimums, so we provide fake
                 radio minimums based on configured baro minimums, current barometric
                 altitude, and current radar altimeter reading. -->
            <filter>
                <name>Fake baro minimums</name>
                <type>gain</type>
                <gain>1</gain>
                <input>
                    <expression>
                        <dif>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-baro</property>
                            <dif>
                                <property>instrumentation/altimeter[<xsl:value-of select="$index"/>]/indicated-altitude-ft</property>
                                <property>position/gear-agl-ft</property>
                            </dif>
                        </dif>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-fake-baro</output>
            </filter>

            <!-- forward either fake-baro or radio minimums to mk-viii -->
            <filter>
                <name>Forward minimums</name>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <equals>
                            <property>controls/flight/nav-src/side</property>
                            <value>0</value>
                        </equals>
                    </condition>
                </enable>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-mode</property>
                            <value>0</value>
                        </equals>
                    </condition>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-radio</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-mode</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-fake-baro</property>
                </input>
                <output>instrumentation/mk-viii/inputs/arinc429/decision-height</output>
            </filter>

            <filter>
                <type>derivative</type>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-radio</property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-radio-rate</output>
                <filter-time>1.0</filter-time>
            </filter>

            <filter>
                <type>derivative</type>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-baro</property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-baro-rate</output>
                <filter-time>1.0</filter-time>
            </filter>

            <filter>
                <type>derivative</type>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-mode</property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-mode-rate</output>
                <filter-time>1.0</filter-time>
            </filter>

            <logic>
                <input>
                    <or>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-radio-rate</property>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-baro-rate</property>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-mode-rate</property>
                    </or>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-delta</output>
            </logic>

            <flipflop>
                <name>Minimums changed</name>
                <type>monostable</type>
                <debug type="bool">false</debug>
                <time>
                    <value>20</value>
                </time>
                <S>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-delta</property>
                </S>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-changed</output>
            </flipflop>

            <filter>
                <name>Minimums reference alt</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-reference-altitude</output>
                <input>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-mode</property>
                    </condition>
                    <property>instrumentation/altimeter[<xsl:value-of select="$index"/>]/indicated-altitude-ft</property>
                </input>
                <input>
                    <property>position/gear-agl-ft</property>
                </input>
            </filter>
            <filter>
                <name>Minimums decision alt</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-decision-altitude</output>
                <input>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-mode</property>
                    </condition>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-baro</property>
                </input>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-radio</property>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Radio altitude</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/radio-alt</output>
                <input>
                    <expression>
                        <floor>
                            <property>position/gear-agl-ft</property>
                        </floor>
                    </expression>
                </input>
                <min>0</min>
                <max>4000</max>
            </filter>

            <logic>
                <name>Minimums indicator visible</name>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-indicator-visible</output>
                <input>
                    <less-than>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-reference-altitude</property>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-decision-altitude</property>
                    </less-than>
                </input>
            </logic>
            <logic>
                <name>Radio altimeter visible</name>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/radio-altimeter-visible</output>
                <input>
                    <or>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-indicator-visible</property>
                        <less-than>
                            <property>position/gear-agl-ft</property>
                            <value>4000</value>
                        </less-than>
                    </or>
                </input>
            </logic>
            <logic>
                <name>Minimums visible</name>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-visible</output>
                <input>
                    <or>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-indicator-visible</property>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/minimums-changed</property>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/radio-altimeter-visible</property>
                    </or>
                </input>
            </logic>

            <!-- Various -->
            <logic>
                <name>Airspeed Alive</name>
                <input>
                    <greater-than>
                        <property>instrumentation/airspeed-indicator/indicated-speed-kt</property>
                        <value>40</value>
                    </greater-than>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/airspeed-alive</output>
            </logic>

            <predict-simple>
                <name>airspeed predictor</name>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <input>instrumentation/airspeed-indicator/indicated-speed-kt</input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/airspeed-lookahead-10s</output>
                <seconds>10.0</seconds>
                <filter-gain>0.0</filter-gain>
            </predict-simple>
            
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Pitchscale</name>
                <type>gain</type>
                <gain>1.0</gain>
                <input>
                    <expression>
                        <table>
                            <property>orientation/pitch-deg</property>
                            <entry>
                                <ind>90</ind><dep>90</dep>
                            </entry>
                            <entry>
                                <ind>10</ind><dep>16.666</dep>
                            </entry>
                            <entry>
                                <ind>0</ind><dep>0</dep>
                            </entry>
                            <entry>
                                <ind>-10</ind><dep>-16.666</dep>
                            </entry>
                            <entry>
                                <ind>-90</ind><dep>-90</dep>
                            </entry>
                        </table>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/pitch-scale</output>
            </filter>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>FPA Pitchscale</name>
                <type>gain</type>
                <gain>1.0</gain>
                <input>
                    <expression>
                        <table>
                            <property>it-autoflight/input/fpa</property>
                            <entry>
                                <ind>90</ind><dep>90</dep>
                            </entry>
                            <entry>
                                <ind>10</ind><dep>16.666</dep>
                            </entry>
                            <entry>
                                <ind>0</ind><dep>0</dep>
                            </entry>
                            <entry>
                                <ind>-10</ind><dep>-16.666</dep>
                            </entry>
                            <entry>
                                <ind>-90</ind><dep>-90</dep>
                            </entry>
                        </table>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fpa-pitch-scale</output>
            </filter>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>FPA scale</name>
                <type>gain</type>
                <gain>1.0</gain>
                <input>
                    <expression>
                        <table>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/fpa-deg</property>
                            <entry>
                                <ind>90</ind><dep>90</dep>
                            </entry>
                            <entry>
                                <ind>10</ind><dep>16.666</dep>
                            </entry>
                            <entry>
                                <ind>0</ind><dep>0</dep>
                            </entry>
                            <entry>
                                <ind>-10</ind><dep>-16.666</dep>
                            </entry>
                            <entry>
                                <ind>-90</ind><dep>-90</dep>
                            </entry>
                        </table>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fpa-scale</output>
            </filter>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>FD pitch scale</name>
                <type>gain</type>
                <gain>1.0</gain>
                <input>
                    <expression>
                        <table>
                            <sum>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/fpa-deg</property>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/fd/vert-offset-deg</property>
                            </sum>
                            <entry>
                                <ind>90</ind><dep>90</dep>
                            </entry>
                            <entry>
                                <ind>10</ind><dep>16.666</dep>
                            </entry>
                            <entry>
                                <ind>0</ind><dep>0</dep>
                            </entry>
                            <entry>
                                <ind>-10</ind><dep>-16.666</dep>
                            </entry>
                            <entry>
                                <ind>-90</ind><dep>-90</dep>
                            </entry>
                        </table>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fd/pitch-scale</output>
            </filter>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>FD pitch bar</name>
                <type>gain</type>
                <gain>1.0</gain>
                <input>
                    <condition>
                        <less-than>
                            <property>position/gear-agl-ft</property>
                            <value>10</value>
                        </less-than>
                    </condition>
                    <property>fms/vspeeds-effective/departure/pitch</property>
                </input>
                <input>
                    <expression>
                        <sum>
                            <property>it-autoflight/fd/pitch-bar</property>
                            <property>orientation/pitch-deg</property>
                        </sum>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fd/pitch-bar-deg</output>
            </filter>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>FD pitch bar scale</name>
                <type>gain</type>
                <gain>1.0</gain>
                <input>
                    <expression>
                        <table>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/fd/pitch-bar-deg</property>
                            <entry>
                                <ind>90</ind><dep>90</dep>
                            </entry>
                            <entry>
                                <ind>10</ind><dep>16.666</dep>
                            </entry>
                            <entry>
                                <ind>0</ind><dep>0</dep>
                            </entry>
                            <entry>
                                <ind>-10</ind><dep>-16.666</dep>
                            </entry>
                            <entry>
                                <ind>-90</ind><dep>-90</dep>
                            </entry>
                        </table>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fd/pitch-bar-scale</output>
            </filter>

            <!-- VMO -->
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>VMO</name>
                <type>gain</type>
                <gain>1.0</gain>
                <input>
                    <condition>
                        <equals>
                            <property>controls/flight/flaps</property>
                            <value>0</value>
                        </equals>
                    </condition>
                    <expression>
                        <table>
                            <property>position/altitude-ft</property>
                            <entry>
                                <ind>0</ind><dep>300</dep>
                            </entry>
                            <entry>
                                <ind>8000</ind><dep>300</dep>
                            </entry>
                            <entry>
                                <ind>10000</ind><dep>320</dep>
                            </entry>
                            <entry>
                                <ind>29000</ind><dep>320</dep>
                            </entry>
                            <entry>
                                <ind>41000</ind><dep>244</dep>
                            </entry>
                        </table>
                    </expression>
                </input>
                <input>
                    <condition>
                        <greater-than>
                            <property>controls/flight/flaps</property>
                            <value>0.0</value>
                        </greater-than>
                    </condition>
                    <expression>
                        <table>
                            <property>controls/flight/flaps</property>
                            <entry>
                                <ind>0.1</ind><dep>230</dep>
                            </entry>
                            <entry>
                                <ind>0.2</ind><dep>215</dep>
                            </entry>
                            <entry>
                                <ind>0.3</ind><dep>200</dep>
                            </entry>
                            <entry>
                                <ind>0.4</ind><dep>180</dep>
                            </entry>
                            <entry>
                                <ind>0.5</ind><dep>180</dep>
                            </entry>
                            <entry>
                                <ind>0.6</ind><dep>165</dep>
                            </entry>
                        </table>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/vmo</output>
            </filter>

            <!-- HSI bearings -->
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Circle Bearing</name>
                <type>gain</type>
                <gain>1</gain>
                <period>
                    <min>0</min>
                    <max>360</max>
                </period>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[0]/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <expression>
                        <difference>
                            <property>instrumentation/nav[0]/heading-deg</property>
                            <property>orientation/heading-magnetic-deg</property>
                        </difference>
                    </expression>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[0]/source</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <property>instrumentation/adf[0]/indicated-bearing-deg</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[0]/source</property>
                            <value>3</value>
                        </equals>
                    </condition>
                    <expression>
                        <difference>
                            <property>autopilot/route-manager/wp[0]/bearing-deg</property>
                            <property>orientation/heading-magnetic-deg</property>
                        </difference>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[0]/bearing</output>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Circle Bearing Visible</name>
                <type>gain</type>
                <gain>1</gain>
                <period>
                    <min>0</min>
                    <max>360</max>
                </period>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[0]/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/in-range</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[0]/source</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <property>instrumentation/adf[0]/in-range</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[0]/source</property>
                            <value>3</value>
                        </equals>
                    </condition>
                    <property>autopilot/route-manager/active</property>
                </input>
                <input>
                    <value>0</value>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[0]/visible</output>
            </filter>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Diamond Bearing</name>
                <type>gain</type>
                <gain>1</gain>
                <period>
                    <min>0</min>
                    <max>360</max>
                </period>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[1]/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <expression>
                        <difference>
                            <property>instrumentation/nav[1]/heading-deg</property>
                            <property>orientation/heading-magnetic-deg</property>
                        </difference>
                    </expression>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[1]/source</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <property>instrumentation/adf[1]/indicated-bearing-deg</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[1]/source</property>
                            <value>3</value>
                        </equals>
                    </condition>
                    <expression>
                        <difference>
                            <property>autopilot/route-manager/wp[0]/bearing-deg</property>
                            <property>orientation/heading-magnetic-deg</property>
                        </difference>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[1]/bearing</output>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Diamond Bearing Visible</name>
                <type>gain</type>
                <gain>1</gain>
                <period>
                    <min>0</min>
                    <max>360</max>
                </period>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[1]/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/in-range</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[1]/source</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <property>instrumentation/adf[1]/in-range</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[1]/source</property>
                            <value>3</value>
                        </equals>
                    </condition>
                    <property>autopilot/route-manager/active</property>
                </input>
                <input>
                    <value>0</value>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/bearing[1]/visible</output>
            </filter>

            <!-- groundspeed -->
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Groundspeed</name>
                <type>gain</type>
                <gain>1</gain>
                <input>
                    <expression>
                        <floor>
                            <sum>
                                <property>velocities/groundspeed-kt</property>
                                <value>0.5</value>
                            </sum>
                        </floor>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/groundspeed-kt</output>
            </filter>

            <!-- wind speed -->
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Wind speed</name>
                <type>gain</type>
                <gain>1</gain>
                <input>
                    <expression>
                        <floor>
                            <sum>
                                <property>environment/wind-speed-kt</property>
                                <value>0.5</value>
                            </sum>
                        </floor>
                    </expression>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/wind-speed-kt</output>
            </filter>

            <!-- HSI/NAV/DME -->
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>DME source</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/dme-source</output>
                <input>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                    </condition>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                </input>
                <input>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/preview</property>
                    </condition>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/preview</property>
                </input>
                <input>
                    <value>0</value>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>DME hold</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/dme/hold</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/dme-source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/dme[0]/hold</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/dme-source</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <property>instrumentation/dme[1]/hold</property>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>DME in range</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/dme/in-range</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/dme-source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/dme[0]/in-range</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/dme-source</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <property>instrumentation/dme[1]/in-range</property>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>DME Dist</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/dme/dist10</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/dme-source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <expression>
                        <floor>
                            <product>
                                <property>instrumentation/dme[0]/indicated-distance-nm</property>
                                <value>10</value>
                            </product>
                        </floor>
                    </expression>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/dme-source</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <expression>
                        <floor>
                            <product>
                                <property>instrumentation/dme[1]/indicated-distance-nm</property>
                                <value>10</value>
                            </product>
                        </floor>
                    </expression>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>DME ETE seconds</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/dme/ete-sec</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/dme-source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <expression>
                        <floor>
                            <product>
                                <property>instrumentation/dme[0]/indicated-time-min</property>
                                <value>60</value>
                            </product>
                        </floor>
                    </expression>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/dme-source</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <expression>
                        <floor>
                            <product>
                                <property>instrumentation/dme[1]/indicated-time-min</property>
                                <value>60</value>
                            </product>
                        </floor>
                    </expression>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>DME ETE unit</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/dme/ete-unit</output>
                <input>
                    <condition>
                        <less-than>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/dme/ete-sec</property>
                            <value>60</value>
                        </less-than>
                    </condition>
                    <value>0</value>
                </input>
                <input>
                    <value>1</value>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>DME ETE</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/dme/ete</output>
                <input>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/dme/ete-unit</property>
                    </condition>
                    <expression>
                        <floor>
                            <div>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/dme/ete-sec</property>
                                <value>60</value>
                            </div>
                        </floor>
                    </expression>
                </input>
                <input>
                    <expression>
                        <floor>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/dme/ete-sec</property>
                        </floor>
                    </expression>
                </input>
            </filter>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Course source</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/course-source</output>
                <input>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                    </condition>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                </input>
                <input>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/preview</property>
                    </condition>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/preview</property>
                </input>
                <input>
                    <value>0</value>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Course source type</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/course-source-type</output>
                <input>
                <update-interval-secs type="double">0.1</update-interval-secs>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                    </condition>
                    <!-- NAV -->
                    <value>1</value>
                </input>
                <input>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/preview</property>
                    </condition>
                    <!-- PREVIEW -->
                    <value>2</value>
                </input>
                <input>
                    <!-- OFF -->
                    <value>0</value>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS Source</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</output>
                <input>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                    </condition>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                </input>
                <input>
                    <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/preview</property>
                </input>
            </filter>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Nav Selected Radial</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/selected-radial</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/course-source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/radials/selected-deg</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav/course-source</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/radials/selected-deg</property>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>HSI heading</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/hsi/heading</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/radials/selected-deg</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/radials/selected-deg</property>
                </input>
                <input>
                    <property>instrumentation/gps/desired-course-deg</property>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>HSI deflection</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/hsi/deflection</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/heading-needle-deflection-norm</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/heading-needle-deflection-norm</property>
                </input>
                <input>
                    <product>
                        <property>instrumentation/gps/cdi-deflection</property>
                        <value>0.1</value>
                    </product>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>HSI from flag</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/hsi/from-flag</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/from-flag</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/nav-src</property>
                            <value>2</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/from-flag</property>
                </input>
                <input>
                    <value>-1</value>
                </input>
            </filter>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS GS Needle</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/gs-needle</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/gs-needle-deflection-norm</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/gs-needle-deflection-norm</property>
                </input>
            </filter>
            <logic>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS GS In Range</name>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/gs-in-range</output>
                <input>
                    <or>
                        <and>
                            <equals>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                                <value>1</value>
                            </equals>
                            <property>instrumentation/nav[0]/gs-in-range</property>
                        </and>
                        <and>
                            <equals>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                                <value>2</value>
                            </equals>
                            <property>instrumentation/nav[1]/gs-in-range</property>
                        </and>
                    </or>
                </input>
            </logic>
            <logic>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS Has GS</name>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/has-gs</output>
                <input>
                    <or>
                        <and>
                            <equals>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                                <value>1</value>
                            </equals>
                            <property>instrumentation/nav[0]/has-gs</property>
                        </and>
                        <and>
                            <equals>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                                <value>2</value>
                            </equals>
                            <property>instrumentation/nav[1]/has-gs</property>
                        </and>
                    </or>
                </input>
            </logic>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS LOC Needle</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/loc-needle</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/heading-needle-deflection-norm</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/heading-needle-deflection-norm</property>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS LOC Bearing</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/bearing</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/heading-deg</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/heading-deg</property>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS LOC Bearing Error</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/bearing-error</output>
                <period>
                    <min>-180</min>
                    <max>180</max>
                </period>
                <input>
                    <expression>
                        <difference>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/bearing</property>
                            <property>orientation/heading-deg</property>
                        </difference>
                    </expression>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS LOC Heading</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/heading</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/radials/target-radial-deg</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/radials/target-radial-deg</property>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS LOC Heading Error</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/heading-error</output>
                <period>
                    <min>-180</min>
                    <max>180</max>
                </period>
                <input>
                    <expression>
                        <difference>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/heading</property>
                            <property>orientation/heading-deg</property>
                        </difference>
                    </expression>
                </input>
            </filter>
            <logic>
                <name>ILS LOC In Range</name>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/loc-in-range</output>
                <input>
                    <or>
                        <and>
                            <equals>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                                <value>1</value>
                            </equals>
                            <property>instrumentation/nav[0]/in-range</property>
                        </and>
                        <and>
                            <equals>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                                <value>2</value>
                            </equals>
                            <property>instrumentation/nav[1]/in-range</property>
                        </and>
                    </or>
                </input>
            </logic>
            <logic>
                <name>ILS Has LOC</name>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/has-loc</output>
                <input>
                    <or>
                        <and>
                            <equals>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                                <value>1</value>
                            </equals>
                            <property>instrumentation/nav[0]/nav-loc</property>
                        </and>
                        <and>
                            <equals>
                                <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                                <value>2</value>
                            </equals>
                            <property>instrumentation/nav[1]/nav-loc</property>
                        </and>
                    </or>
                </input>
            </logic>

            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS crosstrack</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/crosstrack-error-m</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/crosstrack-error-m</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/crosstrack-error-m</property>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS GS distance</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/gs-distance</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/gs-distance</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/gs-distance</property>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS crosstrack heading error</name>
                <type>gain</type>
                <gain>57.29577951308232</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/crosstrack-heading-error-deg</output>
                <input>
                    <expression>
                        <atan2>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/crosstrack-error-m</property>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/gs-distance</property>
                        </atan2>
                    </expression>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS runway width view angle</name>
                <type>gain</type>
                <gain>57.29577951308232</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/runway-width-deg</output>
                <input>
                    <expression>
                        <atan2>
                            <property>fms/approach-conditions/runway-width-m</property>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/gs-distance</property>
                        </atan2>
                    </expression>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>ILS GS direct deg</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/gs-direct-deg</output>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[0]/gs-direct-deg</property>
                </input>
                <input>
                    <condition>
                        <equals>
                            <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/ils/source</property>
                            <value>1</value>
                        </equals>
                    </condition>
                    <property>instrumentation/nav[1]/gs-direct-deg</property>
                </input>
            </filter>
            <!-- WAYPOINTS -->
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Waypoint Dist</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/waypoint/dist10</output>
                <input>
                    <expression>
                        <floor>
                            <product>
                                <property>autopilot/route-manager/wp/dist</property>
                                <value>10</value>
                            </product>
                        </floor>
                    </expression>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Waypoint ETE unit</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/waypoint/ete-unit</output>
                <input>
                    <condition>
                        <less-than>
                            <property>autopilot/route-manager/wp/eta-seconds</property>
                            <value>60</value>
                        </less-than>
                    </condition>
                    <value>0</value>
                </input>
                <input>
                    <value>1</value>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>Waypoint ETE</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/waypoint/ete</output>
                <input>
                    <condition>
                        <property>instrumentation/pfd[<xsl:value-of select="$index"/>]/waypoint/ete-unit</property>
                    </condition>
                    <expression>
                        <floor>
                            <div>
                                <property>autopilot/route-manager/wp/eta-seconds</property>
                                <value>60</value>
                            </div>
                        </floor>
                    </expression>
                </input>
                <input>
                    <expression>
                        <floor>
                            <property>autopilot/route-manager/wp/eta-seconds</property>
                        </floor>
                    </expression>
                </input>
            </filter>

            <!-- VSI -->
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>VSI Needle</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/vsi-needle-deg</output>
                <input>
                    <expression>
                        <table>
                            <property>instrumentation/vertical-speed-indicator/indicated-speed-fpm</property>
                            <entry><ind>-5000</ind><dep>-60</dep></entry>
                            <entry><ind>-3000</ind><dep>-45</dep></entry>
                            <entry><ind>-1000</ind><dep>-30</dep></entry>
                            <entry><ind>-500</ind><dep>-15</dep></entry>
                            <entry><ind>0</ind><dep>0</dep></entry>
                            <entry><ind>500</ind><dep>15</dep></entry>
                            <entry><ind>1000</ind><dep>30</dep></entry>
                            <entry><ind>3000</ind><dep>45</dep></entry>
                            <entry><ind>5000</ind><dep>60</dep></entry>
                        </table>
                    </expression>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>VSI Needle Target</name>
                <type>gain</type>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/vsi-target-deg</output>
                <input>
                    <expression>
                        <table>
                            <property>it-autoflight/input/vs</property>
                            <entry><ind>-5000</ind><dep>-60</dep></entry>
                            <entry><ind>-3000</ind><dep>-45</dep></entry>
                            <entry><ind>-1000</ind><dep>-30</dep></entry>
                            <entry><ind>-500</ind><dep>-15</dep></entry>
                            <entry><ind>0</ind><dep>0</dep></entry>
                            <entry><ind>500</ind><dep>15</dep></entry>
                            <entry><ind>1000</ind><dep>30</dep></entry>
                            <entry><ind>3000</ind><dep>45</dep></entry>
                            <entry><ind>5000</ind><dep>60</dep></entry>
                        </table>
                    </expression>
                </input>
            </filter>

            <!-- FD -->
            <logic>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>FD Visible</name>
                <input>
                    <property>it-autoflight/input/fd<xsl:value-of select="$index + 1"/></property>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fd/visible</output>
            </logic>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fd/lat-offset-deg</output>
                <input>
                    <expression>
                        <div>
                            <property>it-autoflight/fd/roll-bar</property>
                            <property>it-autoflight/config/cmd/roll-kp</property>
                        </div>
                    </expression>
                </input>
            </filter>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fd/vert-offset-deg</output>
                <input>
                    <property>it-autoflight/fd/pitch-bar</property>
                </input>
            </filter>

            <!-- FPA -->
            <logic>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>FPA Visible</name>
                <input>
                    <or>
                        <!-- GS armed -->
                        <property>it-autoflight/output/appr-armed</property>
                        <!-- GS captured -->
                        <equals>
                            <property>it-autoflight/output/vert</property>
                            <value>2</value>
                        </equals>
                        <!-- FPA mode -->
                        <equals>
                            <property>it-autoflight/output/vert</property>
                            <value>5</value>
                        </equals>
                    </or>
                </input>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fpa/visible</output>
            </logic>
            <filter>
                <update-interval-secs type="double">0.1</update-interval-secs>
                <name>FPA target</name>
                <type>gain</type>
                <gain>1</gain>
                <output>instrumentation/pfd[<xsl:value-of select="$index"/>]/fpa/target</output>
                <input>
                    <!-- FPA mode -->
                    <condition>
                        <equals>
                            <property>it-autoflight/output/vert</property>
                            <value>5</value>
                        </equals>
                    </condition>
                    <property>it-autoflight/input/fpa</property>
                </input>
                <input>
                    <condition>
                        <or>
                            <property>it-autoflight/output/appr-armed</property>
                            <equals>
                                <property>it-autoflight/output/vert</property>
                                <value>2</value>
                            </equals>
                        </or>
                    </condition>
                    <!-- TODO: figure out how to get the actual glideslope angle -->
                    <value>-3.0</value>
                </input>
            </filter>

        </PropertyList>
    </xsl:template>
</xsl:stylesheet>
