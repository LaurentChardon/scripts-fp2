#!/usr/bin/perl
#
# $Id: old-freshports.pm,v 1.1 2001-11-09 16:30:15 dan Exp $
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


#PortCreate ($port, $category, $categoryid, $timestamp, $commitdescription, $dbh) {
sub PortCreate($;$;$;$;$;$) {
   my $port              = shift;
   my $category          = shift;
   my $categoryid        = shift;
   my $timestamp         = shift;
   my $commitdescription = shift;
   my $dbh               = shift;


   my $needs_refresh;

   $needs_refresh = GetNeedsRefreshForNewPort($category, $port);

   # no such port.  create it.
   my $sql = "insert into ports (name, primary_category_id, " .
          "date_created, needs_refresh, " .
          "status, package_exists, short_description) values (";

   # we assume above that the package does not exist until we are told otherwise.

   # we don't get a version when inserting, so we must fake it by supplying a name.
   # and the date created is this timestamp.  we used to use current_time,
   # but that defaults to local time, which is not necessarily the same time zone
   # which can give things like created > last_update.
   $sql .= "'$port', $categoryid, " .
           "'$timestamp', $needs_refresh, 'A', 'N', " . $dbh->quote($commitdescription) . ")";

   print "$sql\n";

   my $sth = $dbh->prepare($sql);

   $sth->execute ||
      die "Could not execute PortCreate SQL statement ... maybe invalid?";

   my $PortID = $sth->{'mysql_insertid'};

   print "newly created port has ID = $PortID\n";

#   $sql = "insert into newports (name, primary_category_id) values ('$port', $categoryid)";
#
#   $sth = $dbh->prepare($sql);
#
#   $sth->execute ||
#      die "Could not execute SQL port insert statement ... $sql maybe invalid?";

   return $PortID;
}

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
