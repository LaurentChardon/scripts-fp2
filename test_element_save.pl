#!/usr/bin/perl

use strict;
use DBI;
use element;
use database;

require config;

my ($dbh, $element, $name);

$dbh = FreshPorts::Database::GetDBHandle();

#$name = "/delete/me/" . time();
$name = "/src/fake/me2.txt";

print "CREATING element with name = '$name'\n";


$element = FreshPorts::Element->new($dbh);
$element->{pathname} = $name;
$element->{directory_file_flag} = 'F';

$element->save();

print "AFTER CREATION\n";

print "id                   = $element->{id}\n";
print "name                 = $element->{name}\n";
print "parent_id            = $element->{parent_id}\n";
print "directory_file_flag  = $element->{directory_file_flag}\n";
print "status               = $element->{status}\n";
print "pathname             = $element->{pathname}\n";

$element = FreshPorts::Element->new($dbh);
$element->{pathname} = $name;


print "\nAFTER READING IT BACK IN\n";

$element->FetchByName();

print "id                   = $element->{id}\n";
print "name                 = $element->{name}\n";
print "parent_id            = $element->{parent_id}\n";
print "directory_file_flag  = $element->{directory_file_flag}\n";
print "status               = $element->{status}\n";
print "pathname             = $element->{pathname}\n";

print "\nAND SAVING IT AGAIN....\n";

$element->{directory_file_flag} = 'D';
$element->save();

$element = FreshPorts::Element->new($dbh);
$element->{pathname} = $name;
print "\nAFTER READING IT BACK IN\n";

$element->FetchByName();

print "id                   = $element->{id}\n";
print "name                 = $element->{name}\n";
print "parent_id            = $element->{parent_id}\n";
print "directory_file_flag  = $element->{directory_file_flag}\n";
print "status               = $element->{status}\n";
print "pathname             = $element->{pathname}\n";


$dbh->commit();
$dbh->disconnect();
