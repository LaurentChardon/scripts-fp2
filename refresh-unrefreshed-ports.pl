#!/usr/bin/perl -w

use strict;
use portschange;
 
use DBI;

my $BASEDIR = "/usr/ports";



# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# DO NOT MODIFY THE BELOW VALUES WITHOUT ALSO CHANGING THE SAME VALUES IN updates.pl

my %FilesWhichPromptRefresh = (
   "Makefile"    => "1",
   "pkg/DESCR"   => "2",
   "pkg/COMMENT" => "4",
);

# DO NOT MODIFY THE ABOVE VALUES WITHOUT ALSO CHANGING THE SAME VALUES IN updates.pl

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


my $IGNOREDCATS  = "Attic|distfiles|Mk|Tools|Templates|pkg|distributed|CVS|\\.\\.|\\.";


#my $STARTWITHDIR  = "/usr/ports/x11-fonts";
my $STARTWITHDIR = "";

#print "connecting to freshportschange... press enter to continue";<STDIN>;

my $dbh = DBI->connect('dbi:mysql:freshportschange','root','xyzzy');

my $maxlength=0;
my $dirname='';
my @PORTS;
my $sql;
my $sth;
my @row;

#
# get a list of ports to update
#

$sql = "select ports.id, categories.name, ports.name, needs_refresh \
        from ports, categories \
        where categories.id       = ports.primary_category_id \
          and ports.needs_refresh <> 0";

$sth = $dbh->prepare($sql);
$sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

while (@row=$sth->fetchrow_array) {
   print "now processing @row\n";
   push @PORTS, "$row[1]:$row[2]:$row[3]"
}

print "press enter to continue ";<STDIN>;

foreach $dirname (@PORTS) {
    my $port;
    my $category;
    my $needs_refresh;

    print "found $dirname";

   ($category, $port, $needs_refresh) = split /:/,$dirname, 3;

   $dirname = "$BASEDIR/$category";
   print " which becomes $dirname : $port\n";

   # now find out what needs to be refreshed....

   print "needs_refresh = $needs_refresh\n";

   while ((my $key, my $value) = each %FilesWhichPromptRefresh) {
      if ($needs_refresh & $value) {
         print "now fetching $key\n";
         `sh fetch-cvs-file.sh $category $port $key`
      }
   }

#   print "press enter to continue "; <STDIN>;
   print "refreshing port...\n";
   
   RefreshPort($dirname, $port, $dbh);

#   print "press enter to continue ";<STDIN>;
}

$dbh->disconnect();

`touch /usr/local/etc/freshports/msgs/lastupdate`
