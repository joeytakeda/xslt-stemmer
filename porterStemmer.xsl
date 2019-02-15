<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:jt="http://github.com/joeytakeda"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    version="2.0">
    <xd:doc>
        <xd:desc>
            <xd:p>Author: Joey Takeda (http://github.com/joeytakeda)</xd:p>
            <xd:p>Created: February 2019</xd:p>
            <xd:p>This is an XSLT implementation of the Porter Stemmer, an English language stemmer first described 
                in <xd:a href="https://www.emeraldinsight.com/doi/abs/10.1108/eb046814">Porter, Martin. "An algorithm for suffix stripping," <xd:i>Program</xd:i>, 14.3:130−137</xd:a>.
                Detailed information can be found on <xd:a href="https://tartarus.org/martin/PorterStemmer/">his website</xd:a>.
                This code has been inspired primarily by the Javascript implementation, which can be found <xd:a href="https://github.com/kristopolous/Porter-Stemmer">here</xd:a>.
            </xd:p>
            <xd:p>While this XSLT implementation does follow the algorithm described by Porter, it departs from the published version 
                as per information on his website. As well, it takes a slightly unorthodox approach to determine whether or not the character "Y"
                functions as a vowel or a consonant. See the function <xd:ref name="jt:translateToCV">jt:translateToCV</xd:ref> for more details. Basically,
                the function takes an input token and turns all unamibiguous vowels [aeiou] simply into the letter "a" and all unambigious consonants [^aeiou]
                to the letter "b". It then determines whether or not the "y" character functions as a consonant (if it begins a token or it follows a vowel) and converts
                it to an "a" or a "b", depending on the context.</xd:p>
        </xd:desc>
        <xd:param name="debug">A simple switch for debugging information</xd:param>
    </xd:doc>
    
    
    <!--**************************************************************
       *                                                            * 
       *                    Parameters                              *
       *                                                            *
       **************************************************************-->
    
    <xsl:param name="debug" select="'false'"/>
    
    
    <!--**************************************************************
       *                                                            * 
       *                    Variables                               *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>The $v variable denotes a vowel and is here reprsented by the vowel 'a'</xd:desc>
    </xd:doc>
    <xsl:variable name="v">a</xsl:variable>
    
    <xd:doc>
        <xd:desc>The $c variable denotes a single consonant and is here represented by the consonant 'b'.</xd:desc>
    </xd:doc>
    <xsl:variable name="c">b</xsl:variable>
    
    <xd:doc>
        <xd:desc>The $C variable denotes a sequence of consonants.</xd:desc>
    </xd:doc>
    <xsl:variable name="C" select="concat($c,'+')"/>
    
    <xd:doc>
        <xd:desc>The $V variable denotes a sequence of vowels.</xd:desc>
    </xd:doc>
    <xsl:variable name="V" select="concat($v,'+')"/>
    
    <xd:doc>
        <xd:desc>The $seq2 variable lists, as a sequence of strings,
        the match strings and the replacements (in the form match:replace) for 
        step2.</xd:desc>
    </xd:doc>
    <xsl:variable name="seq2"
        select="
        'ational:ate',
        'tional:tion',
        'enci:ence',
        'anci:ance', 
        'izer:ize',
        'bli:ble', (: DEPATURE FROM PUBLISHED ALGORITHM: abli:able:)
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
        'logi:log' (: DEPATURE FROM PUBLISHED ALGORITHM: logi:log does not exist :)
        "
        as="xs:string+"/>
    
    <xd:doc>
        <xd:desc>The $seq3 variable lists, as a sequence of strings,
            the match strings and the replacements (in the form match:replace) for 
            step3.</xd:desc>
    </xd:doc>
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
    <xd:doc>
        <xd:desc>The $seq4 variable lists, as a sequence of strings,
            the match strings and the replacements (in the form match:replace) for 
            step3.</xd:desc>
    </xd:doc>
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
    
    <xd:doc>
        <xd:desc>$seq2Rex is $seq2 turned into a simple regex for faster processing.</xd:desc>
    </xd:doc>
    <xsl:variable name="seq2Rex" select="jt:makeRex($seq2)" as="xs:string"/>
    
    <xd:doc>
        <xd:desc>$seq3Rex is $seq3 turned into a simple regex for faster processing.</xd:desc>
    </xd:doc>
    <xsl:variable name="seq3Rex" select="jt:makeRex($seq3)" as="xs:string"/>
    
    <xd:doc>
        <xd:desc>$seq4Rex is $seq4 turned into a simple regex for faster processing.</xd:desc>
    </xd:doc>
    <xsl:variable name="seq4Rex" select="jt:makeRex($seq4)" as="xs:string"/>
    
    
    <!--**************************************************************
       *                                                            * 
       *                    Functions: Main Stemming                *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>The main stemming function, to be called with a single string argument.</xd:desc>
        <xd:param name="token">The token to stem.</xd:param>
    </xd:doc>
   <xsl:function name="jt:stem" as="xs:string">
       <xsl:param name="token" as="xs:string"/>

       <xsl:choose>
           <!--If the input token is greater than 2 characters long
               then stem-->
           <xsl:when test="string-length($token) gt 2">
               <xsl:value-of select="jt:stem($token, 0)"/>
           </xsl:when>
           
           <!--If the string is less than 3 characters, then just 
           return the token-->
           <xsl:otherwise>
               <xsl:value-of select="$token"/>
           </xsl:otherwise>
       </xsl:choose>
   </xsl:function>
    
    <xd:doc>
        <xd:desc>The main stemming function, which iterates through some integer
        ($i) to determine which step to do.</xd:desc>
        <xd:param name="token">The token, which is modified in each step.</xd:param>
        <xd:param name="i">The iteration (from 0 to 8)</xd:param>
    </xd:doc>
    
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
    
    
    <!--**************************************************************
       *                                                            * 
       *                    Functions: Steps                        *
       *                                                            *
       **************************************************************-->
    <xd:doc>
        <xd:desc>Step 1a</xd:desc>
        <xd:param name="token">The input token (from step 0; i.e. the input)</xd:param>
    </xd:doc>
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
    
    <xd:doc>
        <xd:desc>Step 1b</xd:desc>
        <xd:param name="token">The input token (from step 1a)</xd:param>
    </xd:doc>
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
    
    <xd:doc>
        <xd:desc>Step 1b1, which is not an official "step" in the algorithm, but is required if the final two
        conditions in step 1b are met; this function is only called from within step1b and not from the main
        jt:stem() function.</xd:desc>
        <xd:param name="token">The input token (from step1b)</xd:param>
    </xd:doc>
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
    
    <xd:doc>
        <xd:desc>Step 1c</xd:desc>
        <xd:param name="token">The input token (from step1b)</xd:param>
    </xd:doc>
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
  
    <xd:doc>
        <xd:desc>Step 2</xd:desc>
        <xd:param name="token">The input token (from step1c)</xd:param>
    </xd:doc>
  <xsl:function name="jt:step2" as="xs:string">
      <xsl:param name="token"/>
      
      <!--$proceed is a boolean value that evaluates to "true" iff the input $token
          matches the sequence of values provided in $seq2 (i.e. ends with one those
          prefixes)-->
      <xsl:variable name="proceed" select="matches($token,$seq2Rex)" as="xs:boolean"/>
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
    


    <xd:doc>
        <xd:desc>Step 4</xd:desc>
        <xd:param name="token">The input token (from step2)</xd:param>
    </xd:doc>
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
    
    
    <xd:doc>
        <xd:desc>Step 4</xd:desc>
        <xd:param name="token">The input token (from step3)</xd:param>
    </xd:doc>
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
    
    <xd:doc>
        <xd:desc>Step 5a</xd:desc>
        <xd:param name="token">The input token (from step4)</xd:param>
    </xd:doc>
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
    
    <xd:doc>
        <xd:desc>Step 5b</xd:desc>
        <xd:param name="token">The input token (from step5a)</xd:param>
    </xd:doc>
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
    
    
    <!--**************************************************************
       *                                                            * 
       *                    Functions: M Tests                      *
       *                                                            *
       **************************************************************-->
        
    
    <!--The m value of any word can be defined as 
        [C] (VC)^m [V] 
        where [C] and [V] denote an arbitrary presence of a sequence of consonants and vowels-->
    
    <!--These functions are inspired by the Javascript implementation mentioned above;
        not that we don't care what the actual M value is, but just whether or not it is 0, 1, or greater
        than 1-->
    
    <xd:doc>
        <xd:desc>Determines whether or not the M value is greater than 0</xd:desc>
        <xd:param name="token">The input token</xd:param>
    </xd:doc>
    <xsl:function name="jt:mGt0" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:value-of select="matches(jt:translateToCV($token),concat('^(',$C,')?',$V,$C))"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Determines whether or not the M value is equal to 1</xd:desc>
        <xd:param name="token">The input token</xd:param>
    </xd:doc>
    <xsl:function name="jt:mEq1" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:value-of select="matches(jt:translateToCV($token),concat('^(',$C,')?',$V,$C,'(',$V,')?$'))"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Determines whether or not the M value is greater than 1</xd:desc>
        <xd:param name="token">The input token</xd:param>
    </xd:doc>
    <xsl:function name="jt:mGt1" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:value-of select="matches(jt:translateToCV($token),concat('^(',$C,')?',$V, $C, $V, $C))"/>
    </xsl:function>
    
    
    <!--**************************************************************
       *                                                            * 
       *                    Functions: Conditions                   *
       *                                                            *
       **************************************************************-->
    
    <xd:doc>
        <xd:desc>Determines whether or not the string ends with a double consonant (denoted by *d in the algorithm).</xd:desc>
        <xd:param name="token">The input token.</xd:param>
    </xd:doc>
    <xsl:function name="jt:endsWithDoubleConsonant" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:variable name="lastTwo" select="replace($token,'.+(\w{2})$','$1')"/>
        <xsl:value-of select="matches(jt:translateToCV($lastTwo),concat('^',$c,$c,'$')) and substring($lastTwo,1,1) = substring($lastTwo,2,1)"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Determines whether or not a string contains a vowel (denoted by  *v* in the algorithm).</xd:desc>
        <xd:param name="token">The input token.</xd:param>
    </xd:doc>
    <xsl:function name="jt:containsVowel" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:value-of select="matches(jt:translateToCV($token),$v)"/>
    </xsl:function>
    <xd:doc>
        <xd:desc>Determines whether or not a string ends with the sequence "cvc" where c is some consonant and
            v is some vowel (denoted by  *o in the algorithm).</xd:desc>
        <xd:param name="token">The input token.</xd:param>
    </xd:doc>
    <xsl:function name="jt:endsCVC" as="xs:boolean">
        <xsl:param name="token"/>
        <xsl:value-of select="matches(jt:translateToCV($token),concat($c,$v,$c,'$')) and not(matches($token,'[wxy]$'))"/>
    </xsl:function>
    
    
    <!--**************************************************************
       *                                                            * 
       *                    Functions: Utilities                    *
       *                                                            *
       **************************************************************-->
    <xd:doc>
        <xd:desc>A simple function trim a suffix away from a token.</xd:desc>
        <xd:param name="token">The input string.</xd:param>
        <xd:param name="suffix">The suffix to trim.</xd:param>
    </xd:doc>
    <xsl:function name="jt:trim">
        <xsl:param name="token"/>
        <xsl:param name="suffix"/>
        <xsl:value-of select="replace($token,concat($suffix,'$'),'')"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Turns a sequence of strings (denoted by x:y) into a regular expression comprised
            just of "x" values.</xd:desc>
        <xd:param name="seq">The input sequence of strings, which may or may not have values with ':'</xd:param>
    </xd:doc>
    <xsl:function name="jt:makeRex" as="xs:string">
        <xsl:param name="seq"/>
        <xsl:value-of select="concat(string-join(for $n in $seq return concat('(',replace($n,':.+',''),')'),'|'),'$')"/>
    </xsl:function>

    <xd:doc>
        <xd:desc>This function is a slightly faster recursive version of the regular XSLT 2.0 for-each instruction. It takes a sequence of values
        and checks whether or not a token matches that item in the sequence [$seq[$i]]. If it does, then it checks whether or not the M value
        is correct. If it does, then it performs the replacement; otherwise it ends the loop and returns the regular value.</xd:desc>
        <xd:param name="token">The input token to check</xd:param>
        <xd:param name="seq">A sequence of strings, in the format "x(:y)?," where "x" denotes the value to match and "y" denotes 
        the value that should be replaced; if "y" is absent, then "x" should simply be trimmed.</xd:param>
        <xd:param name="i">The current iteration (i.e. position in the sequence).</xd:param>
        <xd:param name="mFx">A string value that denotes which m value function (as described above) the token should be evaluated
        against.</xd:param>
    </xd:doc>
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
   
   <xd:doc>
       <xd:desc>This function, as described above, performs four replacements:
       
       1) Replace all unambiguous vowels [aeiou] with 'a'
       2) Replace all unambiguous consonants [^aeiou] with 'b'
       3) Replace all 'y's that either immediately follow a vowel or begins with the consonant token ('b')
       4) Replace all 'y' characters with the vowel token.
       
       Note that this function should only be called in instances where the result of the outer function is a boolean value;
       in other words, at no point should the results of this function be output.
       </xd:desc>
       <xd:param name="token">The token to translate into the consonant/vowel system.</xd:param>
   </xd:doc>
   <xsl:function name="jt:translateToCV" as="xs:string?">
       <xsl:param name="token" as="xs:string?"/>
       <xsl:value-of select="replace(replace(replace(replace($token,'[aeiou]','a'),'[^aeiouy]','b'),'^y|(a)y','$1b'),'y','a')"/>  
   </xsl:function>
   
   
</xsl:stylesheet>