#!/usr/bin/perl

use strict;

my $hash = {};

$hash->{things}=1;
if ($hash->{things}) {
	print "things\n";
} else {
	print "nothing\n";
}
