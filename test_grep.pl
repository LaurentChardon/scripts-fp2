#!/usr/bin/perl

use strict;

print `grep zope-zwiki-0.9.4.tgz packages.exists`;

print "result = " . ($? >> 8) . "\n";