# XSLT Porter Stemmer

This is an XSLT 2.0 implementation of the [Porter Stemmer Algorithm](https://tartarus.org/martin/PorterStemmer/).

# How to Use

To use this module, import porterStemmer.xsl into your stylesheet. Currently, you can use the stylesheet from the raw versioned served from Github. For every token you would like to stem, call:

```
<xsl:value-of select="jt:stem($token)"/>
```

