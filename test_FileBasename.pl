#!/usr/bin/perl
#
# $Id: test_FileBasename.pl,v 1.2 2001-12-22 04:30:41 dan Exp $
#
# Copyright (c) 2001 DVL Software
#
use strict;
use File::Basename;

my $filename = "/usr/local/etc/rc.d/apache.sh/things";

#my ($name,$path,$suffix) = fileparse

print File::Basename::dirname($filename) . "\n";
print File::Basename::basename($filename) . "\n";
