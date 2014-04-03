Randexp
    by Michael Alves Lobo
    https://github.com/kairel/strrand_regex

== DESCRIPTION:

Generate random string from most regular expressions.

== REQUIREMENTS:
 
* none!
 
== INSTALL:
 
  $ sudo gem install strrand_regex

== USAGE:

Generate string from regular expressions.

  StrrandRegex::random_regex('[A-Z][a-z]{8}\d')
    # => ""nsqEd5rzud""
