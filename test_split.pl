#!/usr/bin/perl -w

use strict;

my $category;
my $name;
my $extra;

my $partialpathname = "security/logcheck/things";

($category, $name, $extra) = split/\//,$partialpathname, 2;

print "$category\n";
print "$name\n";
print "$extra\n";
