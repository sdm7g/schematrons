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
    <xsl:param name="iiif_manifest_prefix"><!-- http://localhost:9000/ --></xsl:param>
    <!-- ASpace plugin now resolving AppConfig[:iiif_service] prefix at runtime
         so we can switch easier from tests to production -->

    <xsl:param name="components" select="document($component_xml)"/>
    <xsl:param name="unitid_audience">internal</xsl:param>

    <!-- identity transform is the default -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Don't copy default xlink attribs for empty href : -->
    <xsl:template match="@xlink:*[../@xlink:href='']" />
    

    <xsl:template match="ead:dao|ead:daoloc"> <!-- mark existing dao role -->
        <xsl:copy>
            <xsl:apply-templates select="@*" />
            <xsl:choose>
                <xsl:when test="not(@xlink:role) and  (lower-case(@xlink:title)='text') and contains(@xlink:href,'/tei/')">
                    <xsl:attribute name="xlink:role">text-tei-transcripted</xsl:attribute>
                    <xsl:if test="not(./@xlink:title) or ./@xlink:title = ''" >
                        <xsl:attribute name="xlink:title">Text transcription (TEI)</xsl:attribute>
                    </xsl:if>
                    <xsl:if test="not(daodesc)" >
                        <daodesc><p>Text Transcription (TEI)</p></daodesc>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="not(@xlink:role) or @xlink:role = ''">
                    <xsl:attribute name="xlink:role">legacy-image</xsl:attribute>
                    <xsl:if test="not(daodesc)">
                    <daodesc><p>Legacy digital objects</p></daodesc>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message select="."></xsl:message>
                </xsl:otherwise>
            </xsl:choose>            
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
                <xsl:comment select="concat( local-name(.),': ',.)"/>
            </xsl:for-each>
            <xsl:text>&#xa;&#x09;</xsl:text>

            <xsl:if test="not(parent::ead:archdesc)">
                <xsl:apply-templates select="node()"/>
            </xsl:if>
            

            <xsl:choose>
                <xsl:when test="count($component) = 0"> 
                    <xsl:message>No component found for <xsl:value-of select="$myid"/> :
                        <xsl:value-of select="saxon:path()"/></xsl:message>
                </xsl:when>
            <xsl:when test="count($component) > 1">
                    <xsl:comment>
                        WARNING: More than one component matching id: <xsl:value-of select="$myid"/>
                    </xsl:comment>
                    <xsl:message> WARNING: More than one component matching id: <xsl:value-of
                            select="$myid"/> : <xsl:value-of select="saxon:path()"/></xsl:message>
            </xsl:when>
                <!-- Otherwise OK: <xsl:otherwise></xsl:otherwise>  -->
            </xsl:choose>
            
            <!--  Warning issued above if &gt 1 or 0 but for simplicity, we process for-each here even though we hope there is only one. -->
            <xsl:for-each select="$component">
                <xsl:element name="unitid">
                    <xsl:attribute name="audience" select="$unitid_audience"/>
                    <xsl:attribute name="label">component_id</xsl:attribute>
                    <xsl:attribute name="type">uva-lib</xsl:attribute>
                    <xsl:attribute name="identifier" select="./pid" />
                    <xsl:value-of select="./pid"/>
                    <xsl:element name="extptr">
                        <xsl:attribute name="xlink:type">simple</xsl:attribute>
                        <xsl:attribute name="xlink:href"
                            select="concat($ts_component_url, ./component-id)" />
                        <xsl:attribute name="title">Tracksys component</xsl:attribute>
                    </xsl:element>
               </xsl:element>


            <xsl:if test="./master-files/master-file">

                <xsl:element name="dao">
                    <xsl:attribute name="xlink:type">simple</xsl:attribute>
                    <xsl:attribute name="xlink:role">image-service-manifest</xsl:attribute>
                    <xsl:attribute name="xlink:title" select="substring(concat('IIIF-manifest: ', normalize-space(./desc)),1,255)"/>
                    <xsl:attribute name="xlink:href" select="concat($iiif_manifest_prefix, ./pid )"></xsl:attribute>
                    <daodesc><p><xsl:value-of select="normalize-space(./desc)"/></p></daodesc>
                </xsl:element>

                <daogrp xlink:type="extended">
                    <daodesc><p><xsl:value-of select="./desc"/></p></daodesc>
                    <xsl:for-each select="./master-files/master-file">
                        <xsl:element name="daoloc">
                            <xsl:attribute name="xlink:type">locator</xsl:attribute>
                            <xsl:attribute name="xlink:title" select="title"/>
                            <xsl:attribute name="id" select="translate(pid, ':', '_')"/>
                            <xsl:attribute name="xlink:href"
                                select="concat($iiif_prefix, pid, $iiif_suffix)"/>
                            <xsl:attribute name="xlink:role">image-master</xsl:attribute>
                        </xsl:element>
                    </xsl:for-each>
                </daogrp>
            </xsl:if>


            </xsl:for-each>
            

        </xsl:copy>
    </xsl:template>



</xsl:stylesheet>
