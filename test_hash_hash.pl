#!/usr/bin/perl -w

use strict;

my %Updates;
my @Files;
my %Ports;
my %Port;

my ($action, $path, $revision);
my $value;

$Updates{FileAction}	= 'Modify';
$Updates{FilePath}		= 'ports/textproc/Dwordnet/Makefile';
$Updates{FileRevision}	= '1.4';

$Port{NeedsRefresh} = 0;
$Port{id}			= 123;

print "needsrefresh = $Port{NeedsRefresh}\n";
print "id           = $Port{id}\n";

#$Ports{'ports/textproc'} = %Port;
$Ports{'ports/textproc'} = '1234';

print $Ports{"ports/textproc"} . "\n";

#print "needsrefresh = $Ports{"ports/textproc\"}{NeedsRefresh}\n";

push @Files, [$Updates{FileAction}, $Updates{FilePath}, $Updates{FileRevision}];

foreach $value (@Files) {
	($action, $path, $revision) = @$value;
	print "$action, $path, $revision\n";
}

#my $portname;
#my %values;

#while (($portname, %values) = each %Ports) {
#	print "$portname = $values{NeedsRefresh}\n";
#}