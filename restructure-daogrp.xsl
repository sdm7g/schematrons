<?xml version="1.0" encoding="UTF-8"?>
<!-- restructure uva-sc EAD daogrp's 
     split the TEI text transcriptions out into a separate dao 
     and keep the image links in the daogrp
     for a more logical grouping for ArchivesSpace importing of 
     resources with digital objects. 
    This stylesheet makes some assumptions that are only incidentally true of our guides. 
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    xmlns="urn:isbn:1-931666-22-9"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    version="2.0">
 
    <xsl:output method="xml" indent="yes"  />

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
           <xsl:apply-templates select="@*" />
       </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>