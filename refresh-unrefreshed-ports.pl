#!/usr/bin/perl -w

use strict;
use portschange;
 
use DBI;

my $dbh = DBI->connect('dbi:mysql:freshportschange','root','xyzzy');

my $maxlength=0;
my $dirname='';
my $porttorefresh;
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

#print "press enter to continue ";<STDIN>;

foreach $porttorefresh (@PORTS) {
    my $port;
    my $category;
    my $needs_refresh;
    my $FetchWorked;

    print "found $porttorefresh";

   ($category, $port, $needs_refresh) = split /:/,$porttorefresh, 3;

   RefreshOnePort($category, $port, $needs_refresh, $dbh);

#   print "press enter to continue ";<STDIN>;

}

$dbh->disconnect();

`touch /usr/local/etc/freshports/msgs/lastupdate`
