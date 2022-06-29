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

This file (iru]]><xsl:value-of select="$index + 1"/><![CDATA[.xml) has been
generated from a template and will be overwritten when build.sh
runs. If you want make changes to the PFD XML, edit pfd.xsl and
re-run build.sh.
]]></xsl:comment>
        <PropertyList>
            <logic>
                <input>
                    <equals>
                        <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/alignment/status</property>
                        <value>1</value>
                    </equals>
                </input>
                <output>/instrumentation/iru[<xsl:value-of select="$index"/>]/outputs/valid</output>
            </logic>
            <filter>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <equals>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/alignment/status</property>
                            <value>1</value>
                        </equals>
                    </condition>
                </enable>
                <input>
                    <expression>
                        <sum>
                            <property>/orientation/pitch-deg</property>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/error/pitch-deg</property>
                        </sum>
                    </expression>
                </input>
                <output>/instrumentation/iru[<xsl:value-of select="$index"/>]/outputs/pitch-deg</output>
            </filter>
            <filter>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <equals>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/alignment/status</property>
                            <value>1</value>
                        </equals>
                    </condition>
                </enable>
                <input>
                    <expression>
                        <sum>
                            <property>/orientation/roll-deg</property>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/error/roll-deg</property>
                        </sum>
                    </expression>
                </input>
                <output>/instrumentation/iru[<xsl:value-of select="$index"/>]/outputs/roll-deg</output>
            </filter>
            <filter>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <equals>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/alignment/status</property>
                            <value>1</value>
                        </equals>
                    </condition>
                </enable>
                <input>
                    <expression>
                        <sum>
                            <property>/orientation/true-heading-deg</property>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/error/true-heading-deg</property>
                        </sum>
                    </expression>
                </input>
                <output>/instrumentation/iru[<xsl:value-of select="$index"/>]/outputs/true-heading-deg</output>
            </filter>
            <filter>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <equals>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/alignment/status</property>
                            <value>1</value>
                        </equals>
                    </condition>
                </enable>
                <input>
                    <expression>
                        <sum>
                            <property>/orientation/heading-magnetic-deg</property>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/error/heading-deg</property>
                        </sum>
                    </expression>
                </input>
                <output>/instrumentation/iru[<xsl:value-of select="$index"/>]/outputs/heading-deg</output>
                <output>/instrumentation/iru[<xsl:value-of select="$index"/>]/outputs/heading-magnetic-deg</output>
            </filter>
            <filter>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <equals>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/alignment/status</property>
                            <value>1</value>
                        </equals>
                    </condition>
                </enable>
                <input>
                    <expression>
                        <sum>
                            <property>/orientation/track-magnetic-deg</property>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/error/heading-deg</property>
                        </sum>
                    </expression>
                </input>
                <output>/instrumentation/iru[<xsl:value-of select="$index"/>]/outputs/track-magnetic-deg</output>
            </filter>
            <filter>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <equals>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/alignment/status</property>
                            <value>1</value>
                        </equals>
                    </condition>
                </enable>
                <input>
                    <expression>
                        <sum>
                            <property>/position/latitude-deg</property>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/error/latitude-deg</property>
                        </sum>
                    </expression>
                </input>
                <output>/instrumentation/iru[<xsl:value-of select="$index"/>]/outputs/latitude-deg</output>
            </filter>
            <filter>
                <type>gain</type>
                <gain>1</gain>
                <enable>
                    <condition>
                        <equals>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/alignment/status</property>
                            <value>1</value>
                        </equals>
                    </condition>
                </enable>
                <input>
                    <expression>
                        <sum>
                            <property>/position/longitude-deg</property>
                            <property>/instrumentation/iru[<xsl:value-of select="$index"/>]/error/longitude-deg</property>
                        </sum>
                    </expression>
                </input>
                <output>/instrumentation/iru[<xsl:value-of select="$index"/>]/outputs/longitude-deg</output>
            </filter>
        </PropertyList>
    </xsl:template>
</xsl:stylesheet>

