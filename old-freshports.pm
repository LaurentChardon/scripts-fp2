#!/usr/bin/perl
#
# $Id: old-freshports.pm,v 1.2 2001-11-09 19:36:08 dan Exp $
#
# Port Updater for FreshPorts
# takes output of LogMunger and updates the database
# written by Dan Langille
# copyright 2000 DVL Software
#

use DBI;
use strict;
package Freshports::Makefile;
#use lib '/home/freshports.org/scripts';
#use ports;

use port-utils;

my $Debug = 0;


print "%%%%% - starting main loop " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
while ((my $CategoryPort, my @PortIDChangePortID) = each %Ports) {
   $NumPorts++;

   print " looking at $CategoryPort ";

   $PortID = $Ports{$CategoryPort}[0];

   print " which has a port id of $PortID\n";

   my $sql = "select needs_refresh from ports where id = $PortID";

   my $sth = $dbh->prepare($sql);
   $sth->execute ||
        die "Could not execute SQL $sql ... maybe invalid?";

   if (my @row=$sth->fetchrow_array) {
  
      my $NeedsRefresh = $row[0];

      if ($NeedsRefresh > 0) {
         ($category, $port) = split /\//,$CategoryPort, 2;

         print "about refresh $category, $port, $NeedsRefresh\n";

         print "%%%%% - refreshing $category/$port " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

         RefreshOnePort($category, $port, $NeedsRefresh, $dbh);

         print "%%%%% - refreshed $category/$port " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";
      } else {
         print " ---- that port didn't need refreshing\n";
      }

   } else {
      #
      # well, we couldn't read that port.
      # it'd be nice if we could tell someone....
      #
      print "that read failed\n";
   }
}

print "%%%%% - main loop done " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

if ($NumPorts) {
   print "number of ports updated by that message '$NumPorts'\n";
   #
   # make sure the daily summaries are up to date.
   # note: the timestamp thoughout one input is the same.
   # remember to supply only the YYYY/MM/DD part of the time stamp

   (my $DateOnly) = split/ /,$timestamp, 3;
   print "%%%%% - creating daily summary " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

   CreateDailySummary($DateOnly, $dbh);

   print "%%%%% - daily summary done " . `date "+%Y-%m-%d %H:%M:%S"` . "\n";

} else  {
   print "no ports where updated by that message.  very strange.\n";
}

$dbh->disconnect();


#
# and let the www world know that the database has updated 
# and therefore their cache files are out of date
#
`touch /home/freshports.org/scripts/lastupdate`;

print "finish " . `date "+%Y-%m-%d %H:%M:%S"`;

}

1;
