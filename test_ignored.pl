#!/usr/bin/perl -w

use strict;

use constants;

my $category_name 	= 'editors';
my $port_name		= 'em';

my $entry			= 'Makefile';

print "$entry         = " . $FreshPorts::Constants::FilesWhichPromptRefresh{$entry} . "\n";
print "$category_name = ";
if (defined($FreshPorts::Constants::IgnoredItems{$category_name})) {
	print $FreshPorts::Constants::IgnoredItems{$category_name}
} else {
    print "not found";
}

print "\n";

print "$port_name     = ";
if (defined($FreshPorts::Constants::IgnoredItems{$port_name})) {
	print $FreshPorts::Constants::IgnoredItems{$port_name}
} else {
    print "not found";
}

print "\n";