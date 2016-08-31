<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="urn:isbn:1-931666-22-9"
    xmlns:ead="urn:isbn:1-931666-22-9" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:saxon="http://saxon.sf.net/" exclude-result-prefixes="xs" version="2.0">

    <xsl:output method="xml" indent="yes"/>

    <xsl:param name="basedir" select="base-uri()"/>
    <xsl:param name="basename" select="tokenize(base-uri(), '/')[last()]"/>
    <xsl:param name="component_xml"
        select="resolve-uri(concat('ts_components/', $basename), $basedir)"/>
    <xsl:param name="linkto"/>
    <xsl:param name="ts_component_url"
        >http://tracksys.lib.virginia.edu/admin/components/</xsl:param>
    <!--<xsl:param name="ts_api_url">http://localhost:3000/api/iiif/</xsl:param>-->
    <xsl:param name="iiif_prefix">http://iiif.lib.virginia.edu/iiif/</xsl:param>
    <xsl:param name="iiif_suffix">/full/,680/0/default.jpg</xsl:param>

    <xsl:param name="components" select="document($component_xml)"/>

    <!-- identity transform is the default -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="ead:dao|ead:daogrp"> <!-- mark existing dao's as legacy -->
        <xsl:copy>
            <xsl:apply-templates select="@*" />
            <daodesc>Legacy digital objects</daodesc>
            <xsl:apply-templates select="node()" />
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:did">

        <xsl:variable name="myid">
            <xsl:choose>
                <xsl:when test="parent::ead:archdesc">
                    <xsl:value-of select="/ead:ead/@id"/>
                </xsl:when>
                <xsl:when test="normalize-space(../@id) != ''">
                    <xsl:value-of select="string(../@id)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>No did/@id or ead/@id <xsl:value-of select="saxon:path()"
                        /></xsl:message>
                    <xsl:value-of select="'viu00000'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!--<xsl:message select="$myid" />-->
        <xsl:variable name="component"
            select="$components//(child | object)[string(ead-id) = $myid]"/>

        <xsl:copy>
            <xsl:apply-templates select="@*"/>

            <xsl:if test="parent::ead:archdesc">
                <xsl:apply-templates select="node()"/>
            </xsl:if>


            <xsl:for-each select="$component/(ead-id | ead-id-cache | level | desc | pid | in_dl)">
                <xsl:text>&#xa;&#x09;</xsl:text>
                <xsl:comment select="."/>
            </xsl:for-each>
            <xsl:text>&#xa;&#x09;</xsl:text>

            <!-- Generate links to components in Tracksys: put this near the top -->

            <xsl:choose>
                <xsl:when test="count($component) > 1">
                    <xsl:comment>
                        WARNING: More than one component matching id: <xsl:value-of select="$myid"/>
                    </xsl:comment>
                    <xsl:message> WARNING: More than one component matching id: <xsl:value-of
                            select="$myid"/> : <xsl:value-of select="saxon:path()"/></xsl:message>
                    <xsl:for-each select="$component">
                        <xsl:element name="dao">
                            <xsl:attribute name="xlink:type">simple</xsl:attribute>
                            <xsl:attribute name="xlink:href"
                                select="concat($ts_component_url, ./component-id)"/>
                            <xsl:attribute name="xlink:title"
                                select="substring(concat('Tracksys:[', /level, ']: ', normalize-space(./desc)), 1, 255)"
                            />
                            <daodesc>Tracksys component links</daodesc>
                        </xsl:element>

                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="count($component) = 1">
                    <xsl:element name="dao">
                        <xsl:attribute name="xlink:type">simple</xsl:attribute>
                        <xsl:attribute name="xlink:href"
                            select="concat($ts_component_url, normalize-space($component/component-id))"/>
                        <xsl:attribute name="xlink:title"
                            select="substring(concat('Tracksys:[', $component/level, ']: ', normalize-space($component/desc)), 1, 255)"
                        />
                        <daodesc>Tracksys component links</daodesc>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>No component found for <xsl:value-of select="$myid"/> :
                            <xsl:value-of select="saxon:path()"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:if test="not(parent::ead:archdesc)">
                <xsl:apply-templates select="node()"/>
            </xsl:if>

            <xsl:if test="$component/master-files/master-file">
                <daogrp xlink:type="extended">
                    <daodesc><xsl:value-of select="$component/desc"/></daodesc>
                    <xsl:for-each select="$component/master-files/master-file">
                        <xsl:element name="daoloc">
                            <xsl:attribute name="xlink:type">locator</xsl:attribute>
                            <xsl:attribute name="xlink:title" select="title"/>
                            <xsl:attribute name="id" select="translate(pid, ':', '_')"/>
                            <xsl:attribute name="xlink:href"
                                select="concat($iiif_prefix, pid, $iiif_suffix)"/>
                        </xsl:element>
                    </xsl:for-each>
                </daogrp>
            </xsl:if>

        </xsl:copy>
    </xsl:template>



</xsl:stylesheet>
