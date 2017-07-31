<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:ead="urn:isbn:1-931666-22-9"
    version="2.0">
    
    <!-- FYI: if your EAD files are not in the EAD namespace, then you will need to change the last two template @match 
    attributes from ead:container to container -->
 
    <!--  A bunch of possible sources to choose a normalized id from  -->
    <xsl:param name="id_param"></xsl:param>
    <xsl:variable name="ead_id" select="/ead:ead/@id"/>
    <xsl:param name="agency" select="/ead:ead/ead:eadheader/ead:eadid/@mainagencycode" />
    <xsl:param name="identifier" select="/ead:ead/ead:eadheader/ead:eadid/@identifier" />
    <xsl:param name="publicid" select="/ead:ead/ead:eadheader/ead:eadid/@publicid" />
    <xsl:param name="mss_num" select="/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper/ead:num" />
    <xsl:param name="basename" select="tokenize(document-uri(/), '/')[last()]"/>
    
    <!--standard identity template, which does all of the copying-->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!--adds an @id attribute to the first container element that doesn't already have an @id or @parent attribute-->
    <xsl:template match="ead:container[not(@id|@parent)][1]">
        <xsl:copy>
            <xsl:attribute name="id">
                <xsl:value-of select="generate-id()"/>
            </xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!--adds a @parent attribute to the following container elements that don't already have an @Id or @parent attribute-->
    <xsl:template match="ead:container[not(@id|@parent)][position() > 1]">
        <xsl:copy>
            <xsl:attribute name="parent">
                <xsl:value-of select="generate-id(../ead:container[not(@id|@parent)][1])"/>
            </xsl:attribute>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- add an id to all c* sections for ArcLight compatability --> 
    
    <xsl:template match="ead:*[starts-with(local-name(),'c0') or local-name()='c'][not(@id)]">
        <xsl:copy>
            <xsl:attribute name="id" ><xsl:value-of select="concat( 'gg_',generate-id())"/></xsl:attribute>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>

    <!-- ArcLight requires simpler eadid contents --> 
    <xsl:template  match="ead:eadid">
        <xsl:copy>
            <xsl:apply-templates select="@*" />
            <xsl:choose>
                <xsl:when test="$ead_id"><xsl:value-of select="concat($agency,':',$ead_id)"/></xsl:when>
                <xsl:when test="$mss_num" ><xsl:value-of select="concat($agency,':',$mss_num)"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="concat($agency,':', $basename )"/> </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
