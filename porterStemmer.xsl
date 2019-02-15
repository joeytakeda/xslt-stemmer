<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    xmlns:jt="http://github.com/joeytakeda"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    version="3.0">
    
   <xsl:param name="debug" select="'false'"/>
    
    <xsl:variable name="c">[^aeiou]</xsl:variable>
    <xsl:variable name="v">[aeiou]</xsl:variable>
    <xsl:variable name="C" select="concat($c,'+')"/>
    <xsl:variable name="V" select="concat($v,'+')"/>
    
    
    <!--Global variables-->
    
    <!--Note that there are TWO departures from the originally
          published paper in the following sequence,
          as per https://tartarus.org/martin/PorterStemmer/:
          
          The first is that 
            "abli:able" 
          was changed to
            "bli:ble"
            
          The second is that an extra condition was added:
            "logi:log"
         -->
    <xsl:variable name="seq2"
        select="
        'ational:ate',
        'tional:tion',
        'enci:ence',
        'anci:ance',
        'izer:ize',
        'bli:ble',
        'alli:al',
        'entli:ent',
        'eli:e',
        'ousli:ous',
        'ization:ize',
        'ation:ate',
        'ator:ate',
        'alism:al',
        'iveness:ive',
        'fulness:ful',
        'ousness:ous',
        'aliti:al',
        'iviti:iv',
        'biliti:ble',
        'logi:log'
        "
        as="xs:string+"/>
    
    <xsl:variable name="seq3"
        select="
        'icate:ic',
        'ative',
        'alize:al',
        'iciti:ic',
        'ical:ic',
        'ful',
        'ness'
        "/>
    
    <xsl:variable name="seq4" 
        select="
        'al',
        'ance',
        'ence',
        'er',
        'ic',
        'able',
        'ible',
        'ant',
        'ement',
        'ment',
        'ent',
        '([st])ion:$1',
        'ou',
        'ism',
        'ate',
        'iti',
        'ous',
        'ive',
        'ize'
        "/>
    
    <xsl:variable name="seq2Rex" select="jt:makeRex($seq2)" as="xs:string"/>
    <xsl:variable name="seq3Rex" select="jt:makeRex($seq3)" as="xs:string"/>
    <xsl:variable name="seq4Rex" select="jt:makeRex($seq4)" as="xs:string"/>
    
    
    
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
 
    
    
   <xsl:function name="jt:stem">
       <xsl:param name="token"/>
       <xsl:choose>
           <xsl:when test="string-length($token) gt 2">
               <xsl:value-of select="jt:stem($token, 0)"/>
           </xsl:when>
           <xsl:otherwise>
               <xsl:value-of select="$token"/>
           </xsl:otherwise>
       </xsl:choose>
   </xsl:function>
    
    <xsl:function name="jt:stem" as="xs:string">
        <xsl:param name="token" as="xs:string"/>
        <xsl:param name="i" as="xs:integer"/>
        
        <xsl:variable name="next" select="$i + 1" as="xs:integer"/>
        <xsl:choose>
            <xsl:when test="$i = 0">
                <xsl:value-of select="jt:stem(jt:step1a($token),$next)"/>
            </xsl:when>
            <xsl:when test="$i = 1">
                <xsl:value-of select="jt:stem(jt:step1b($token),$next)"/>
            </xsl:when>
            <xsl:when test="$i = 2">
                <xsl:value-of select="jt:stem(jt:step1c($token),$next)"/>
            </xsl:when>
            <xsl:when test="$i = 3">
                <xsl:value-of select="jt:stem(jt:step2($token),$next)"/>
            </xsl:when>
            <xsl:when test="$i = 4">
                <xsl:value-of select="jt:stem(jt:step3($token),$next)"/>
            </xsl:when>
            <xsl:when test="$i = 5">
                <xsl:value-of select="jt:stem(jt:step4($token),$next)"/>
            </xsl:when>
            <xsl:when test="$i = 6">
                <xsl:value-of select="jt:stem(jt:step5a($token),$next)"/>
            </xsl:when>
            <xsl:when test="$i = 7">
                <xsl:value-of select="jt:stem(jt:step5b($token),$next)"/>
            </xsl:when>
            <xsl:when test="$i = 8">
                <xsl:value-of select="$token"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    
    
    <xsl:function name="jt:step1a">
        <xsl:param name="token"/>
        
        <xsl:choose>
            <xsl:when test="matches($token,'sses$')">
                <xsl:value-of select="replace($token,'sses$','ss')"/>
            </xsl:when>
            <xsl:when test="matches($token,'ies$')">
                <xsl:value-of select="replace($token,'ies$','i')"/>
            </xsl:when>
            <xsl:when test="matches($token,'ss$')">
                <xsl:value-of select="replace($token,'ss$','ss')"/>
            </xsl:when>
            <xsl:when test="matches($token,'s$')">
                <xsl:value-of select="replace($token,'s$','')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$token"/>
            </xsl:otherwise>                       
        </xsl:choose>
    </xsl:function>
    
    
    <xsl:function name="jt:step1b">
        <xsl:param name="token"/>
        <xsl:choose>
            <xsl:when test="matches($token,'eed$')">
                <xsl:variable name="trim" select="jt:trim($token,'eed')"/>
                <xsl:value-of select="if (jt:mGt0($trim)) then replace($token,'eed$','ee') else $token"/>
            </xsl:when>
            <xsl:when test="matches($token,'ed$')">
                <xsl:value-of select="if (jt:containsVowel(jt:trim($token,'ed'))) then jt:step1b1(replace($token,'ed$','')) else $token"/>
            </xsl:when>
            <xsl:when test="matches($token,'ing$')">
                <xsl:value-of select="if (jt:containsVowel(jt:trim($token,'ing'))) then jt:step1b1(replace($token,'ing$','')) else $token"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$token"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="jt:step1b1" as="xs:string">
        <xsl:param name="token"/>
        <xsl:choose>
            <xsl:when test="matches($token,'at$')">
                <xsl:value-of select="replace($token,'at$','ate')"/>
            </xsl:when>
            <xsl:when test="matches($token,'bl$')">
                <xsl:value-of select="replace($token,'bl$','ble')"/>
            </xsl:when>
            <xsl:when test="matches($token,'iz$')">
                <xsl:value-of select="replace($token,'iz$','ize')"/>
            </xsl:when>
            <xsl:when test="jt:endsWithDoubleConsonant($token) and not(matches($token,'[lsz]$'))">
                <xsl:value-of select="replace($token,'\w$','')"/>
            </xsl:when>
            <xsl:when test="jt:mEq1($token) and jt:endsCVC($token)">
                <xsl:value-of select="concat($token,'e')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$token"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
   <xsl:function name="jt:step1c" as="xs:string">
       <xsl:param name="token"/>
       <xsl:choose>
           <xsl:when test="matches($token,'y$') and jt:containsVowel(replace($token,'y$',''))">
               <xsl:value-of select="replace($token,'y$','i')"/>
           </xsl:when>
           <xsl:otherwise>
               <xsl:value-of select="$token"/>
           </xsl:otherwise>
       </xsl:choose>
   </xsl:function>
    
  <xsl:function name="jt:step2" as="xs:string">
      <xsl:param name="token"/>
      <xsl:variable name="proceed" select="matches($token,$seq2Rex)"/>
      <xsl:choose>
          <xsl:when test="$proceed">
              <xsl:variable name="result" select="jt:iterate($token,$seq2,1,'mGt0')" as="xs:string?"/>
              <xsl:choose>
                  <xsl:when test="$result ne ''">
                      <xsl:value-of select="$result"/>
                  </xsl:when>
                  <xsl:otherwise>
                      <xsl:value-of select="$token"/>
                  </xsl:otherwise>
              </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
              <xsl:value-of select="$token"/>
          </xsl:otherwise>
      </xsl:choose>
    </xsl:function>
    

    
      <xsl:function name="jt:step3" as="xs:string">
          <xsl:param name="token"/>
         
          <xsl:variable name="proceed" select="matches($token,$seq3Rex)" as="xs:boolean"/>
          <xsl:choose>
              <xsl:when test="$proceed">
                  <xsl:variable name="result" select="jt:iterate($token,$seq3,1,'mGt0')" as="xs:string?"/>
                  <xsl:choose>
                      <xsl:when test="$result ne ''">
                          <xsl:value-of select="$result"/>
                      </xsl:when>
                      <xsl:otherwise>
                          <xsl:value-of select="$token"/>
                      </xsl:otherwise>
                  </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                  <xsl:value-of select="$token"/>
              </xsl:otherwise>
          </xsl:choose>
          
    </xsl:function>
    
    
    <xsl:function name="jt:step4" as="xs:string">
        <xsl:param name="token"/>
        <xsl:variable name="proceed" select="matches($token,$seq4Rex)" as="xs:boolean"/>
        <xsl:choose>
            <xsl:when test="$proceed">
                <xsl:variable name="result" select="jt:iterate($token,$seq4,1,'mGt1')" as="xs:string?"/>
                <xsl:choose>
                    <xsl:when test="$result ne ''">
                        <xsl:value-of select="$result"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$token"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$token"/>
            </xsl:otherwise>
        </xsl:choose>
      
       
    </xsl:function>
    
    <xsl:function name="jt:step5a" as="xs:string">
        <xsl:param name="token"/>
        <xsl:choose>
            <xsl:when test="matches($token,'e$') and jt:mGt1(replace($token,'e$',''))">
                <xsl:value-of select="replace($token,'e$','')"/>
            </xsl:when>
            <xsl:when test="matches($token,'e$') and jt:mEq1(replace($token,'e$','')) and not(jt:endsCVC(replace($token,'e$','')))">
                <xsl:value-of select="replace($token,'e$','')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$token"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="jt:step5b" as="xs:string">
        <xsl:param name="token"/>
        <xsl:choose>
            <xsl:when test="matches($token,'l$') and  jt:endsWithDoubleConsonant($token) and jt:mGt1(replace($token,'ll$','l'))">
                <xsl:value-of select="replace($token,'ll$','l')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$token"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
        
    
    <!--The m value of any word can be defined as 
        [C] (VC)^m [V] 
        where [C] and [V] denote an arbitrary presence of a sequence of consonants and vowels-->
    
    <xsl:function name="jt:mGt0" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:value-of select="matches(jt:translateToCV($token),concat('^(',$C,')?',$V,$C))"/>
    </xsl:function>
    
    <xsl:function name="jt:mEq1" as="xs:boolean">
        <xsl:param name="token"/>
        
        <xsl:value-of select="matches(jt:translateToCV($token),concat('^(',$C,')?',$V,$C,'(',$V,')?$'))"/>
    </xsl:function>
    
    <xsl:function name="jt:mGt1" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:value-of select="matches(jt:translateToCV($token),concat('^(',$C,')?',$V, $C, $V, $C))"/>
    </xsl:function>
    
    
   <!--CONDITIONS-->
    
    <xsl:function name="jt:endsWithDoubleConsonant" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:variable name="lastTwo" select="replace($token,'.+(\w{2})$','$1')"/>
        <xsl:value-of select="matches(jt:translateToCV($lastTwo),concat('^',$c,$c,'$')) and substring($lastTwo,1,1) = substring($lastTwo,2,1)"/>
    </xsl:function>
    
    <xsl:function name="jt:containsVowel" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:value-of select="matches(jt:translateToCV($token),$v)"/>
    </xsl:function>
    
    <!--the stem ends cvc, where the second c is not W, X or Y (e.g. -WIL,
-HOP). -->
    <xsl:function name="jt:endsCVC" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:value-of select="matches(jt:translateToCV($token),concat($c,$v,$c,'$')) and not(matches($token,'[wxy]$'))"/>
    </xsl:function>
    
    
    
    <xsl:function name="jt:trim">
        <xsl:param name="token"/>
        <xsl:param name="suffix"/>
        <xsl:value-of select="replace($token,concat($suffix,'$'),'')"/>
    </xsl:function>
    
    
    <xsl:function name="jt:makeRex" as="xs:string">
        <xsl:param name="seq"/>
        <xsl:value-of select="concat(string-join(for $n in $seq return concat('(',replace($n,':.+',''),')'),'|'),'$')"/>
    </xsl:function>

    
    <xsl:function name="jt:iterate" as="xs:string?">
        <xsl:param name="token"/>
        <xsl:param name="seq"/>
        <xsl:param name="i"/>
        <xsl:param name="mFx"/>
        <xsl:variable name="thisItem" select="$seq[$i]" as="xs:string?"/>
        <xsl:if test="exists($thisItem)">
            <xsl:variable name="thisSuffix" select="if (contains($thisItem,':')) then substring-before($thisItem,':') else $thisItem" as="xs:string"/>
            <xsl:variable name="thisReplacement" select="if (contains($thisItem,':')) then substring-after($thisItem,':') else ''" as="xs:string"/>
            <xsl:variable name="regex" select="concat($thisSuffix,'$')"/>
            <xsl:choose>
                <xsl:when test="matches($token,$regex)">
              
                    <xsl:variable name="stem" select="replace($token,$regex,if (contains($thisReplacement,'$')) then $thisReplacement else '')"/>
                    <xsl:variable name="satisfiesM" as="xs:boolean">
                        <xsl:choose>
                            <xsl:when test="$mFx='mGt0'">
                                <xsl:value-of select="jt:mGt0($stem)"/>
                            </xsl:when>
                            <xsl:when test="$mFx='mEq1'">
                                <xsl:value-of select="jt:mEq1($stem)"/>
                            </xsl:when>
                            <xsl:when test="$mFx='mGt1'">
                                <xsl:value-of select="jt:mGt1($stem)"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$satisfiesM">
                            <xsl:value-of select="replace($token,$regex,$thisReplacement)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <!--Longets match not satisfied, so return the token-->
                            <xsl:value-of select="$token"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <!--Otherwise. move on-->
                    <xsl:value-of select="jt:iterate($token,$seq, $i+1, $mFx)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        
    </xsl:function>
   
   <xsl:function name="jt:translateToCV" as="xs:string?">
       <xsl:param name="token" as="xs:string?"/>
       <xsl:value-of select="replace(replace(replace(replace($token,'[aeiou]','a'),'[^aeiouy]','b'),'^y|(a)y','$1b'),'y','a')"/>  
   </xsl:function>
   
   
</xsl:stylesheet>