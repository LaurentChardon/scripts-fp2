#!/usr/bin/perl

use strict;
use DBI;
use element;

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

my ($dbh, $element);

$dbh = GetDBHandle();

$element = FreshPorts::Element->new($dbh);
$element->{id} = 4;
$element->FetchByID();

print "id                   = $element->{id}\n";
print "name                 = $element->{name}\n";
print "parent_id            = $element->{parent_id}\n";
print "directory_file_flag  = $element->{directory_file_flag}\n";
print "status               = $element->{status}\n";
print "pathname             = $element->{pathname}\n";
$element = FreshPorts::Element->new($dbh);

$element->{pathname} = '/ports/pkg/COMMENT';
$element->FetchByName();

print "id                   = $element->{id}\n";
print "name                 = $element->{name}\n";
print "parent_id            = $element->{parent_id}\n";
print "directory_file_flag  = $element->{directory_file_flag}\n";
print "status               = $element->{status}\n";
print "pathname             = $element->{pathname}\n";

$dbh->disconnect();
