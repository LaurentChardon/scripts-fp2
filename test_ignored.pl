#!/usr/bin/perl -w
#
# $Id: test_ignored.pl,v 1.2 2001-12-22 04:30:43 dan Exp $
#
# Copyright (c) 2001 DVL Software
#
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