#!/usr/bin/perl
#
# $Id: element.pm,v 1.1.1.1 2001-11-05 05:16:33 dan Exp $
#

package FreshPorts::Element;
#require Exporter;

use strict;
use File::Basename;

$FreshPorts::Element::Active	= 'A';
$FreshPorts::Element::Deleted	= 'D';

sub new {
	my $this		= {};
	my $class		= shift;
	$this->{dbh}	= shift;
	bless $this;
	$this->_initialize();
	return $this
}

sub _initialize {
}

sub CreateNewByName {
	my $this						= shift;

	$this->{pathname}				= shift;
	$this->{directory_file_flag}	= shift;
	$this->{status}					= shift;

	$this->{name} = File::Basename::basename($this->{pathname});

	my $sth;
	my $sql;
	my @row;

	$sql = "select Element_Add('$this->{pathname}', '$this->{directory_file_flag}')";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	$sth->execute ||
		die "Could not execute SQL $sql ... maybe invalid?";

	@row = $sth->fetchrow_array();

	$sth->finish();

	$this->{id} = $row[0];

	# after saving, make sure you read everything back in
	return $this->{id};
}

sub FetchByID {
	my $this	= shift;
	my $id		= shift;

	my $dbh		= $this->{dbh};

	my $sql = "select *, element_pathname(id) as pathname from element where id = $id";
#	print "sql = '$sql'\n";

	my $sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid?";
	}

	my $row = $sth->fetchrow_hashref();

	$sth->finish();

	$this->{id} 			= $row->{id};
	$this->{name}			= $row->{name};
	$this->{parent_id}		= $row->{parent_id};
	$this->{directory_file_flag}	= $row->{directory_file_flag};
	$this->{status}			= $row->{status};
	$this->{pathname}		= $row->{pathname};

	return $this->{id};
}

sub FetchByName {
	# obtain the element based on the id supplied
	my $this		= shift;
	my $filename	= shift;

	my $dbh			= $this->{dbh};

	my ($sql, $sth, @row);

	my $quoted_filename = $dbh->quote($filename);
	$sql = "select Pathname_ID($quoted_filename)";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid?";
	}

	@row = $sth->fetchrow_array();

	$sth->finish();
print "id = '$row[0]'\n";
	return $this->FetchByID($row[0]);
}

1;

