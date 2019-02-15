<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    xmlns:jt="http://github.com/joeytakeda"
    version="2.0">
    
    <xsl:include href="../porterStemmer.xsl"/>
    
    <!--This is the test driver for the porter stemmer; the details of which
        are fully described in the file-->
    <xsl:variable name="testDoc" select="unparsed-text('input.txt')"/>
    <xsl:variable name="resultDoc" select="unparsed-text('expected_results.txt')"/>
    
    <xsl:variable name="testTokens" select="for $n in tokenize($testDoc,'\n+') return normalize-space($n)"/>
    <xsl:variable name="resultTokens" select="for $n in tokenize($resultDoc,'\n+') return normalize-space($n)"/>
    <xsl:template match="/">
        <xsl:value-of select="jt:stem('gyved')"/>
    </xsl:template>
    
    <xsl:template name="test">
        <xsl:result-document href="output.txt" method="text">
            <xsl:for-each select="$testTokens">
                <xsl:variable name="original" select="."/>
                <xsl:variable name="thisPos" select="position()"/>
                <xsl:variable name="expectedResult" select="$resultTokens[$thisPos]"/>
                <xsl:variable name="stem" select="jt:stem(.)"/>
                <xsl:if test="$stem ne $expectedResult">
                    <xsl:message>
                        ERROR: <xsl:value-of select="$original"/> == <xsl:value-of select="$stem"/> =/= <xsl:value-of select="$expectedResult"/>
                    </xsl:message>
                </xsl:if>
                <xsl:value-of select="jt:stem(normalize-space(.))"/><xsl:text>&#xA;</xsl:text>
            </xsl:for-each>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>