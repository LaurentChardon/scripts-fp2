When installing the scripts, be sure to modify the "use lib" entry
in load_xml_into_db.pl to point to the directory in which 
load_xml_into_db.pl resides.

The following packages are needed to run these scripts:

http://search.cpan.org/search?dist=File-PathConvert
http://www.cpan.org/authors/id/R/RB/RBS/File-PathConvert-0.85.tar.gz

textproc/p5-XML-Node
http://search.cpan.org/search?dist=XML-Node
http://www.cpan.org/authors/id/C/CH/CHANG-LIU/XML-Node-0.10.tar.gz

textproc/p5-XML-Writer
http://search.cpan.org/search?dist=XML-Writer
http://www.cpan.org/authors/id/DMEGG/XML-Writer-0.4.tar.gz

adjust this line in load_xml_into_db.pl:
use lib '/home/lists/scripts';

also need lynx! for the fetch script.