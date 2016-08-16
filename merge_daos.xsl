<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="urn:isbn:1-931666-22-9"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output method="xml" indent="yes" />

    <xsl:param name="basedir" select="base-uri()" ></xsl:param>
    <xsl:param name="basename" select="tokenize(base-uri(),'/')[last()]"></xsl:param>
    <xsl:param name="component_xml" select="resolve-uri(concat('ts_components/',$basename))"></xsl:param>
    <xsl:param name="linkto"></xsl:param>
    <xsl:param name="ts_component_url">http://tracksys.lib.virginia.edu/admin/components/</xsl:param>
    <!--<xsl:param name="ts_api_url">http://localhost:3000/api/iiif/</xsl:param>-->
    <xsl:param name="iiif_prefix">http://iiif.lib.virginia.edu/iiif/</xsl:param>
    <xsl:param name="iiif_suffix">/full/,680/0/default.jpg</xsl:param>

    <xsl:param name="components" select="document($component_xml)" />
 
    <!-- identity transform is the default -->
    <xsl:template match="@*|node()" >
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>
    
 
    <xsl:template match="ead:did">
        
        <xsl:variable name="myid" >
            <xsl:choose>
                <xsl:when test="parent::ead:archdesc">
                    <xsl:value-of select="/ead:ead/@id"/>
                </xsl:when>
                <xsl:when test="normalize-space(../@id) != ''">
                    <xsl:value-of select="string(../@id)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'viu00000'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:message select="$myid" />
        <xsl:variable name="component" select="$components//(child|object)[string(ead-id)=$myid]"/>
        
        <xsl:copy>
            <xsl:apply-templates select="@*" />
            
            <xsl:for-each select="$component/(ead-id|ead-id-cache|level|desc|pid|in_dl)">
                <xsl:text>&#xa;&#x09;</xsl:text>
                <xsl:comment select="." />
            </xsl:for-each>

            <!-- Generate links to components in Tracksys: put this near the top -->
            <xsl:choose>
                <xsl:when test="count($component) > 1">
                    <xsl:comment>
                        WARNING: More than one component matching id: <xsl:value-of select="$myid"/>
                    </xsl:comment>
                    <xsl:message>
                        WARNING: More than one component matching id: <xsl:value-of select="$myid"/>
                    </xsl:message>
                    <xsl:for-each select="$component">
                        <xsl:call-template name="linkcomponent">
                            <xsl:with-param name="warn">*WARNING* DUPLICATE</xsl:with-param>
                            <xsl:with-param name="id" select="string(./component-id)"/>
                            <xsl:with-param name="pid" select="string(./pid)" />
                            <xsl:with-param name="in_dl" select="./in-dl='true'" />
                        </xsl:call-template>                    
                    </xsl:for-each>              
                </xsl:when>
                <xsl:when test="count($component) = 1">
                    <xsl:call-template name="linkcomponent">
                        <xsl:with-param name="id" select="string($component/component-id)"/>
                        <xsl:with-param name="pid" select="string($component/pid)" />
                        <xsl:with-param name="in_dl" select="./in-dl='true'" />
                    </xsl:call-template>         
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>No component found.</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:apply-templates select="node()" />

            <xsl:if test="$component/master-files/master-file">
                <daogrp xlink:type="extended" id="{generate-id()}">
                    <xsl:for-each select="$component/master-files/master-file">
                        <xsl:element name="daoloc">
                            <xsl:attribute name="xlink:type">locator</xsl:attribute>
                            <xsl:attribute name="xlink:title" select="pid" />
                            <xsl:attribute name="id" select="translate(pid,':', '_' )"/>
                            <xsl:choose>
                                <xsl:when test="$linkto='dl-thumb'">
                                    <xsl:attribute name="xlink:href" select="dl-thumb" />
                                </xsl:when>
                                <xsl:when test="$linkto='static-thumb'">
                                    <xsl:attribute name="xlink:href" select="static-thumb" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="xlink:href" select="concat($iiif_prefix,pid,$iiif_suffix)" />
                                </xsl:otherwise>
                            </xsl:choose>                          
                            <xsl:comment select="dl-thumb" />
                            <xsl:comment select="static-thumb" />
                        </xsl:element>
                    </xsl:for-each> 
                </daogrp>
            </xsl:if>   
            
        </xsl:copy>
       
    </xsl:template>


    <xsl:template name="linkcomponent">
        <xsl:param name="warn" />
        <xsl:param name="id" />
        <xsl:param name="pid" />
        <xsl:param name="in_dl" />
        <xsl:element name="dao">
            <xsl:attribute name="xlink:type">simple</xsl:attribute>
            <xsl:attribute name="xlink:title" select="concat( 'Component Tracksys URL ', $warn)" />                
            <xsl:attribute name="xlink:href" select="concat($ts_component_url,$id)"></xsl:attribute>
        </xsl:element>
  <!--      <xsl:element name="dao">
            <xsl:attribute name="xlink:type">simple</xsl:attribute>
            <xsl:attribute name="xlink:title">
                <xsl:choose>
                    <xsl:when test="$in_dl">iiif manifest</xsl:when>
                    <xsl:otherwise>iiif manifest [Not in DL]</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:attribute name="xlink:href" select="concat($ts_api_url,$pid)"/>
        </xsl:element>-->

        <xsl:if test="$in_dl">
            <xsl:comment>in_dl? == true</xsl:comment>
<!--            <xsl:element name="dao">
                <xsl:attribute name="xlink:type">simple</xsl:attribute>
                <xsl:attribute name="xlink:title">iiif display</xsl:attribute>
                <xsl:attribute name="xlink:href" select="concat($ts_api_url,$pid,'/display')"/>
            </xsl:element>   -->             
        </xsl:if>


    </xsl:template>

 
</xsl:stylesheet>