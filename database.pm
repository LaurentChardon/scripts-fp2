#!/usr/bin/perl

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