#!/usr/bin/perl

use strict;
use DBI;
use element;

require config;
require database;

my ($dbh, $element);

$dbh = FreshPorts::Database::GetDBHandle();

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
