#!/usr/bin/perl

use strict;
use DBI;
use element;
use category;
use database;

use Sys::Syslog;

require config;

my ($dbh, $category, $name);

$dbh = FreshPorts::Database::GetDBHandle();

$name = "japanese";

print "CREATING category with name = '$name'\n";


$category = FreshPorts::Category->new($dbh);
$category->{name} = $name;
$category->{is_primary} = 1;

print "about to save\n";

my $id = $category->save();

if (!$id) {
	print "no id found....\n";
}

print "AFTER CREATION\n";

print "id                   = $category->{id}\n";
print "is_primary           = $category->{is_primary}\n";
print "element_id           = $category->{element_id}\n";
print "name                 = $category->{name}\n";
print "description          = $category->{description}\n";

$category = FreshPorts::Category->new($dbh);
$category->{name} = $name;


print "\nAFTER READING IT BACK IN\n";

$category->FetchByName();

print "id                   = $category->{id}\n";
print "is_primary           = $category->{is_primary}\n";
print "element_id           = $category->{element_id}\n";
print "name                 = $category->{name}\n";
print "description          = $category->{description}\n";

print "\nAND SAVING IT AGAIN....\n";

$category->{description} = $category->{description} . ' - this silly suffix added during testing';
$category->save();

$category = FreshPorts::Category->new($dbh);
$category->{id} = $id;
print "\nAFTER READING IT BACK IN\n";

$category->FetchByID();

print "id                   = $category->{id}\n";
print "is_primary           = $category->{is_primary}\n";
print "element_id           = $category->{element_id}\n";
print "name                 = $category->{name}\n";
print "description          = $category->{description}\n";

$dbh->commit();
$dbh->disconnect();
