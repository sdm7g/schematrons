<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xtf="http://cdlib.org/xtf"
    xmlns:ead="urn:isbn:1-931666-22-9" xmlns="urn:isbn:1-931666-22-9"
    exclude-result-prefixes="xs xd xi xtf xsi" version="2.0">

    <!-- https://github.com/YaleArchivesSpace/xslt-files/blob/master/EAD_add_IDs_to_containers.xsl 
         see FAQ in https://github.com/archivesspace/archivesspace/blob/master/UPGRADING_1.5.0.md
         identity transform removed from this stylesheet as it's in the imported stylesheet. 
    <xsl:import href="EAD_add_IDs_to_containers.xsl"/> -->

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b>Sept. 21, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b>Steve Majewski sdm7g@virginia.edu</xd:p>
            <xd:p> ArchivesSpace EAD Import currently has a lot more restrictions that EAD 2002
                schema validation. This stylesheet attempts to fix a number of issues we discovered
                while trying to import our EAD guides. In some cases, the 'fix' papers over a
                problem that needs to be addressed manually. For example, "1 arbitrary_unit" is
                inserted for missing extent's. These need to be tagged for manual review after
                import. </xd:p>
            <xd:p> Comments prefixing the templates indicate the import errors that those templates
                are attempting to fix. </xd:p>
            <xd:p> See also EAD Import/Export maps spreadsheet:
                http://www.archivesspace.org/sites/default/files/EAD-Import-Export-Mapping-20130831.xlsx
            </xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:output indent="yes" method="xml" xpath-default-namespace="ead"/>

    <xsl:param name="urlbase">http://ead.lib.virginia.edu/vivaxtf/view?docId=</xsl:param>
    <xsl:param name="orgdir" >uva-hs/</xsl:param>

    <xsl:variable name="eadfname" select="replace(tokenize(normalize-space(/ead:ead/ead:eadheader/ead:eadid/text()),'\s+')[last()],'&quot;','')"/>
    <xsl:variable name="eadidentifier"  select="replace($eadfname,'.xml', '')"/>

    <!-- Apparently, the value returned by Saxon 9 current-date() is not a valid date according to the EAD schema,
        due to the hour:min time appended to the end. -->
    <xsl:variable name="today" select="replace(string(current-date()), '-\d+:\d+', '')"/>

    <xsl:template match="/">
        <xsl:apply-templates select="node()"/>
    </xsl:template>

    <!--standard identity template, which does all of the copying-->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    

    <xsl:template match="text()" priority="0.8" >
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>


    <!-- ArchivesSpace seems to have trouble with empty anythings   -->

    <xsl:template match="@*[normalize-space() = '']"/>
    <!-- don't copy null attributes -->

    <xsl:template match="ead:unitdate[normalize-space() = '']" priority="0.1"/>
    <!-- don't copy other empty unitdates -->

    <xsl:template match="ead:physloc[normalize-space() = '']"/>     <!-- don't copy empty physloc -->
    <xsl:template match="ead:extent[normalize-space() = '']"/>      <!-- or extents -->
    <xsl:template match="ead:scopecontent[normalize-space() = '']"/>    <!-- don't copy empty scopecontent -->
    <xsl:template match="ead:origination[ead:persname[normalize-space() = '']]"/>    <!-- don't copy -->
    
    <xsl:template match="ead:revisiondesc/ead:change[normalize-space()='']"></xsl:template> <!-- we even have some of these! -->

    <xsl:template match="ead:ead/ead:archdesc/ead:did//ead:unitdate[normalize-space() = '']"
        priority="0.6">
        <xsl:copy>
            <xsl:text>[undated]</xsl:text>
            <xsl:call-template name="log">
                <xsl:with-param name="comment">Required unitdate empty: "[undated]" added by as-prepare.xsl</xsl:with-param>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:unitid/ead:extptr" /> <!-- temporary test -->

    <xsl:template match="/ead:ead/ead:archdesc/ead:did/ead:physdesc[not(ead:extent)]">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <xsl:element name="extent">1 arbitrary_unit</xsl:element>
            <xsl:call-template name="log">
                <xsl:with-param name="comment">Required extent missing: arbitrary value inserted by as-prepare.</xsl:with-param>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>

    
    <xsl:template match="/ead:ead/ead:archdesc/ead:did">
        <xsl:copy>
            <xsl:apply-templates select="@* | *"/>
            <xsl:if test="not(descendant::ead:unitdate)">
                <xsl:element name="unitdate">[undated] <xsl:call-template name="log">
                        <xsl:with-param name="comment">Required unitdate missing: "[undated]" added by as-prepare.xsl</xsl:with-param></xsl:call-template>
                </xsl:element>
            </xsl:if>
            <xsl:if test="not(ead:unittitle)">
                <xsl:element name="unittitle">
                    <xsl:value-of
                        select="/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper"/>
                    <xsl:call-template name="log">
                        <xsl:with-param name="comment">Required unittitle missing: copied from titleproper by as-prepare.xsl</xsl:with-param>
                    </xsl:call-template>
                </xsl:element>
            </xsl:if>
            <xsl:if test="not(ead:unitid)">
                <!-- ArchivesSpace looks in /ead/archdesc/did/unitid for collection number 
                VH sometimes puts it there, but ALWAYS in /ead/eadheader/filedesc/titlestmt/subtitle/num 
                 #<:ValidationException: {:errors=>{"id_0"=>["Property is required but was missing"]}}>      
                 missing archdesc/did/unitid ?  copy value from num[@type='collectionnumber']  -->

                <xsl:element name="unitid">
                    <xsl:attribute name="label">Collection Number</xsl:attribute>
                    <xsl:value-of
                        select="/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:subtitle/ead:num[@type = 'collectionnumber']"/>
                    <xsl:call-template name="log">
                        <xsl:with-param name="comment">Collection number copied from subtitle/num by as-prepare.xsl</xsl:with-param>
                    </xsl:call-template>
                </xsl:element>
            </xsl:if>
            <xsl:if test="not(ead:physdesc)">
                <xsl:element name="physdesc">
                    <xsl:element name="extent">1 arbitrary_unit</xsl:element>
                    <xsl:call-template name="log">
                        <xsl:with-param name="comment">Required physdesc/extent missing: arbitrary value inserted by as-prepare.</xsl:with-param>
                    </xsl:call-template>
                </xsl:element>
            </xsl:if>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="ead:did[not(ead:unittitle) and not(ead:unitdate)]">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <unittitle>[untitled] <xsl:call-template name="log">
                    <xsl:with-param name="comment">unitdate or unittitle required: unittitle [untitled] inserted by as-prepare.xsl</xsl:with-param>
                </xsl:call-template>
            </unittitle>
        </xsl:copy>
    </xsl:template>


    <xsl:template
        match="/ead:ead/ead:archdesc/ead:did/ead:unittitle[ead:unitdate]/text()[ends-with(normalize-space(), ',')]"
        priority="1.1">
        <xsl:variable name="nstext" select="normalize-space()"/>
        <xsl:value-of select="substring($nstext, 1, string-length($nstext) - 1)"/>
    </xsl:template>

    <xsl:template
        match="/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper[ead:date]/text()[ends-with(normalize-space(), ',')]"
        priority="1.1">
        <xsl:variable name="nstext" select="normalize-space()"/>
        <xsl:value-of select="substring($nstext, 1, string-length($nstext) - 1)"/>
    </xsl:template>


    <!--  #<:ValidationException: {:errors=>{"instances/0/container/type_1"=>["Property is required but was missing"], 
                                "instances/0/container/indicator_1"=>["Property is required but was missing"]}}>    
    <xsl:template match="ead:did/ead:container[normalize-space() = '']">
        <xsl:call-template name="log">
            <xsl:with-param name="comment">empty container element removed by as-prepare.xsl</xsl:with-param>
        </xsl:call-template>
    </xsl:template> -->


    <xsl:template match="ead:did/ead:container">
        <xsl:choose>
            <xsl:when test="normalize-space() = ''">
                <xsl:call-template name="log">
                    <xsl:with-param name="comment">empty container element removed by as-prepare.xsl</xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="not(@type)">
                <xsl:copy>
                    <xsl:attribute name="type">
                        <xsl:value-of select="substring-before(normalize-space(), ' ')"/>
                    </xsl:attribute>
                    <xsl:if test="not(@id)">
                        <xsl:attribute name="id" select="generate-id()" />
                    </xsl:if>
                    <xsl:apply-templates select="@*|node()"/>                    
                    <xsl:call-template name="log">
                        <xsl:with-param name="comment">@type added by as-prepare.xsl</xsl:with-param>
                    </xsl:call-template>
                </xsl:copy>               
            </xsl:when>        
            <xsl:when test="matches(@type, '[Bb]ox-[Ff]older' ) and matches(text(),'\d+:\d+')">
                <xsl:variable name="parentid" >
                    <xsl:choose>
                        <xsl:when test="@id"><xsl:value-of select="@id"/></xsl:when>
                        <xsl:otherwise><xsl:value-of select="generate-id()" /></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:element name="container">
                    <xsl:attribute name="type"  select="substring-before(@type,'-')" />
                    <xsl:attribute name="label" select="substring-before(@label,'-')"/>
                    <xsl:if test="not(@id)">
                        <xsl:attribute name="id" select="$parentid" />
                    </xsl:if>
                    <xsl:apply-templates select="@id|@altrender|@audience|@encodinganalog"/>
                    <xsl:value-of select="substring-before(normalize-space(),':')"/>
                </xsl:element>
                <xsl:call-template name="log">
                    <xsl:with-param name="comment">@type=box-folder split  <xsl:value-of select="."/>...</xsl:with-param>
                </xsl:call-template>
                <xsl:element name="container" >
                    <xsl:attribute name="type"  select="substring-after(@type,'-')"/>
                    <xsl:attribute name="label" select="substring-after(@label,'-')" />
                    <xsl:attribute name="parent" select="$parentid" />
                    <xsl:value-of select="substring-after(normalize-space(),':')"></xsl:value-of>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy><xsl:apply-templates select="@*|node()" /></xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

 <!--   <xsl:template match="ead:did/ead:container[not(@type)][normalize-space() != '']">
        <xsl:copy>
            <xsl:attribute name="type">
                <xsl:value-of select="substring-before(normalize-space(), ' ')"/>
            </xsl:attribute>
            <xsl:call-template name="log">
                <xsl:with-param name="comment">@type added by as-prepare.xsl</xsl:with-param>
            </xsl:call-template>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
-->

    <!--  #<:ValidationException: {:errors=>{"ead_id"=>["Must be 255 characters or fewer"]}}>   -->
    <xsl:template match="ead:eadid">
        <xsl:param name="normtext" select="normalize-space(text())"/>
        <xsl:message select="$eadidentifier" />
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="not(@url)">
                <xsl:attribute name="url" select="concat($urlbase,$orgdir,$eadfname)" />
            </xsl:if>
            <xsl:if test="not(@identifier)">
                <xsl:attribute name="identifier" select="$eadidentifier" />
            </xsl:if>
            <!-- no subelements for eadid -->
            <xsl:choose>
                <xsl:when test="string-length() &lt; 255">
                    <xsl:value-of select="text()"/>
                </xsl:when>
                <xsl:when test="string-length($normtext) &lt; 256">
                    <xsl:value-of select="$normtext"/>
                    <xsl:call-template name="log">
                        <xsl:with-param name="comment">eadid text normalized by as-prepare.xsl</xsl:with-param>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(substring(normalize-space(.), 1, 254), '…')"/>
                    <xsl:call-template name="log">
                        <xsl:with-param name="comment"
                            select="concat('eadid text content truncated by as-prepare.xsl:', '…', substring(normalize-space(.), 254))"
                        />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="ead:ead/ead:eadheader/ead:revisiondesc">
        <xsl:copy>
            <xsl:apply-templates/>
            <xsl:element name="change">
                <xsl:element name="date">
                    <xsl:attribute name="normal" select="$today"/>
                    <xsl:value-of select="$today"/>
                </xsl:element>
                <xsl:element name="item">Converted to ArchivesSpace EAD requirements with as-prepare.xsl.</xsl:element>
            </xsl:element>
        </xsl:copy>

    </xsl:template>


    <xsl:template match="title[@xlink:href = '']">
        <!-- If null href then no xlink attributes are required -->
        <!-- They were accidentally inserted by default in previous XSLT processing step (schema conversion) -->
        <!-- not *required* for ASpace, but makes for a cleaner import if we fix this -->
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="attribute::xlink:type[../@xlink:href = '']"> </xsl:template>

    <xsl:template name="log">
        <xsl:param name="comment"/>
        <xsl:param name="where" select="concat(name(..), '/', name(.), ': ')"/>
        <xsl:message select="concat($where, $comment)"/>
        <xsl:comment select="concat($where, $comment)"/>
    </xsl:template>

</xsl:stylesheet>
