#!/usr/bin/perl -w

use strict;

my %Updates;
my @Files;

my ($action, $path, $revision);
my $value;

$Updates{FileAction}	= 'Modify';
$Updates{FilePath}		= 'ports/textproc/Dwordnet/Makefile';
$Updates{FileRevision}	= '1.4';

push @Files, [$Updates{FileAction}, $Updates{FilePath}, $Updates{FileRevision}];

foreach $value (@Files) {
	($action, $path, $revision) = @$value;
	print "$action, $path, $revision\n";
}