#!/usr/bin/perl

use strict;
use File::Basename;

my $filename = "/usr/local/etc/rc.d/apache.sh/things";

#my ($name,$path,$suffix) = fileparse

print File::Basename::dirname($filename) . "\n";
print File::Basename::basename($filename) . "\n";
