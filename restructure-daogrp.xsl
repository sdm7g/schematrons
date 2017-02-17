<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:xtf="http://cdlib.org/xtf"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns="urn:isbn:1-931666-22-9"
    exclude-result-prefixes="xs xd xi xtf xsi"
    version="2.0">


    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>restructure uva-sc EAD daogrp's</xd:p>
            <xd:p>split the TEI text transcriptions out into a separate dao and keep the image links in the
             daogrp for a more logical grouping for ArchivesSpace importing of resources with digital objects.
            </xd:p>
            <xd:p>This stylesheet makes some assumptions that are only incidentally true of our guides. </xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:output method="xml" indent="yes"  />

    <!-- one time (so far) additions: template enabled/disabled by changing mode  #default|none --> 
    <xsl:param name="index"  select="document('/projects/MSS/index.xhtml')/xhtml:html/xhtml:body" />
    <xsl:param name="XTF">http://xtf.lib.virginia.edu/xtf/view?docId=legacy_mss/uvaBook/tei/booker_letters/</xsl:param>
    <xsl:template match="ead:daogrp[ead:daoloc[contains(@xlink:href, 'http://etext.lib.virginia.edu/civilwar/booker/index.html#' )]]" mode="none" >
        <xsl:variable name="numb" select="substring-after(ead:daoloc/@xlink:href,'#')" />
        <xsl:message select="$numb" />
        <xsl:variable name="href"  select="$index//xhtml:a[@name=$numb]/../(following-sibling::xhtml:blockquote[1]//xhtml:a)[1]/@href"   />
        <xsl:message select="$href" />
        <xsl:variable name="baseref" select="substring-before( tokenize($href,'/')[last()], '.html'  )"/>
        <xsl:element name="dao">
            <xsl:attribute name="xlink:type">simple</xsl:attribute>
            <xsl:attribute name="xlink:href" select="concat($XTF, $baseref, '.xml')" />
            <xsl:attribute name="xlink:role">text-tei-transcripted</xsl:attribute>
            <xsl:attribute name="xlink:title">Text transcription</xsl:attribute>
        </xsl:element>
    </xsl:template>
    <!-- end conditional template -->

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>
 
    <!-- Don't copy default xlink attribs for empty href : -->
    <xsl:template match="@xlink:*[../@xlink:href='']" />
    
 
    <xsl:template match="ead:daogrp[contains(ead:daoloc[ last() ]/@xlink:href, '.xml')]" >
        <xsl:copy>
            <xsl:apply-templates select="@*"  />
            <xsl:apply-templates select="*[not(local-name()='daoloc')]"/>
            <xsl:apply-templates select="ead:daoloc[not(contains( @xlink:href, '.xml' ))]" />
        </xsl:copy>
        <xsl:apply-templates select="ead:daoloc[contains(@xlink:href,'.xml')]" />
    </xsl:template>
    
   <xsl:template  match="ead:daoloc[contains(@xlink:href,'.xml')]">
       <xsl:element name="dao" >
           <xsl:attribute name="xlink:type">simple</xsl:attribute>
           <xsl:attribute name="xlink:role">text-tei-transcripted</xsl:attribute>
           <xsl:apply-templates select="@*[name()!='role'][name()!='type']" />
           <xsl:if test="not(@xlink:title)" >
               <xsl:attribute name="xlink:title">Text transcription</xsl:attribute>
           </xsl:if>
       </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>