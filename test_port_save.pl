#!/usr/bin/perl

use strict;
use DBI;
use element;
use category;
use port;
use database;

use File::Basename;
use Sys::Syslog;

require config;

my ($dbh, $port, $name);

$dbh = FreshPorts::Database::GetDBHandle();

$name = "security/acid1";

print "CREATING port = '$name'\n";


# get the element corresponding to this port
my $element = FreshPorts::Element->new($dbh);
$element->{pathname} = "/ports/$name";

my $element_id = $element->FetchByName();

if (!$element_id) {
	# create the element
	$element_id = $element->save;
}

my $category = FreshPorts::Category->new($dbh);
$category->{name} = File::Basename::dirname($name);
my $category_id = $category->FetchByName();
if (!$category_id) {
	$category_id->save;
}


$port = FreshPorts::Port->new($dbh);
$port->{element_id}  = $element_id;
$port->{category_id} = $category_id;

print "about to save\n";

my $id = $port->save();

if (!$id) {
	print "no id found....\n";
}

print "AFTER CREATION\n";

print "id                   = $port->{id}\n";
print "element_id           = $port->{element_id}\n";
print "category_id          = $port->{category_id}\n";



print "\nAFTER READING IT BACK IN\n";
$port = FreshPorts::Port->new($dbh);
$port->{id} = $id;

$port->FetchByID();

print "id                   = $port->{id}\n";
print "element_id           = $port->{element_id}\n";
print "category_id          = $port->{category_id}\n";


print "\n\n\n\ FETCHING by $name\n";

$port = FreshPorts::Port->new($dbh);
$port->{partialpathname} = $name;
$port->FetchByPartialPathName();

print "id                   = $port->{id}\n";
print "element_id           = $port->{element_id}\n";
print "category_id          = $port->{category_id}\n";

$dbh->commit();
$dbh->disconnect();