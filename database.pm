#!/usr/bin/perl
#
# $Id: database.pm,v 1.2 2001-12-22 04:30:39 dan Exp $
#
# Copyright (c) 2001 DVL Software
#

package FreshPorts::Database;

use strict;
use DBI;
use Sys::Syslog;

require config;

sub GetDBHandle {
   my $dbh_pg = DBI->connect('DBI:Pg:dbname=' . $FreshPorts::Config::dbname, $FreshPorts::Config::user, $FreshPorts::Config::password);
   if ($dbh_pg->{Active}) {
      $dbh_pg->{AutoCommit} = 0;

      if (!$dbh_pg) {
         Sys::Syslog::syslog('warning', "could not connect to FreshPorts2");
         die "could not connect to FreshPorts2\n";
      }
   }

   return $dbh_pg;
}

1;