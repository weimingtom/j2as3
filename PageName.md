# Introduction #
Java programmers who move projects to ActionScript deserve some automated help.  This project addresses that need.  Currently two Flex applications are provided by this project:
  * J2AS3 (Java to ActionScript syntax converter)
  * Collections (modeled after the Java 1.4 collections classes)

## Java to ActionScript 3 Converter ##
I found a mention of [j2as3](http://osflash.org/projects/j2as3) [here](http://blog.sharendipity.com/moving-to-flash-part-3)

Unfortunately, the j2as3 download seems to have been non-functional for a long time.  [This](http://thunderheadxpler.blogspot.com/search/label/J2AS3) blog post described an AIR version of the converter.  It was hard to find the source to the AIR file, but I eventually did.  Hopefully others will be able to find this project now.

The code isn't something to be proud of, and has some serious limitations.  Generics are not supported, nor are enums.  If you would like to make improvements to the code, please let me know.

[Here](http://blog.sharendipity.com/moving-to-flash-part-2) is a summary of the differences between Java and ActionScript 3.

I made some improvements:
  * Recurses through a directory tree, converting .java files to .as3
  * Can copy non-Java files ("assets") as it recurses
  * Output formatting improved
  * UI improved (although it still needs work)
  * Reports summary statistics

The progress bar is broken.  If that bothers you, please fix it instead of complaining :)