#!/usr/bin/perl
#
# $Id: element.pm,v 1.4 2001-11-08 19:03:09 dan Exp $
#

package FreshPorts::Element;

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

sub save {
	my $this = shift;

	#
	# if id is supplied, we are updating. otherwise we are inserting.
	# if parent_id is supplied, it will be used.  Otherwise, it will
	# be derived from pathname.  if parent_id is set, it is assumed
	# that pathname is correct.
	# if name is not supplied, it will be derived from pathname.
	# 

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	# get the name if not supplied
	if (!$this->{name}) {
		if (!$this->{pathname}) {
			die "neither name nor pathname supplied";
		}
		$this->{name} = File::Basename::basename($this->{pathname});
	}

	if (!$this->{status}) {
		$this->{status} = $FreshPorts::Element::Active;
	}

	# if we don't have the parent id, derive it from the pathname
	if (!$this->{parent_id}) {
		#
		# our parent's name is the basename of our pathname
		# i.e. our path name - our name.
		#
		if (!$this->{pathname}) {
			die "neither parent_id nor pathname supplied";
		}

		#
		# my parent's name is my name less the last directory/file.
		#
		my $parent_name = File::Basename::dirname($this->{pathname});

		#
		# fetch the element with that name
		#
		my $parent = FreshPorts::Element->new($dbh);
		$parent->{pathname} = $parent_name;
		$this->{parent_id} = $parent->FetchByName();
	}

	if ($this->{id}) {
		# we are updating
		$sql = "update element  \
				set \
				name      = " . $dbh->quote($this->{name}) . ", \
				parent_id = $this->{parent_id}, \
				directory_file_flag = " . $dbh->quote($this->{directory_file_flag}) . ", \
				status    = " . $dbh->quote($this->{status}) . " \
				 where id = $this->{id}";
		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			die "Could not execute SQL $sql ... maybe invalid?";
	} else {
		# we are inserting
		$sql = "select Element_Add(	'$this->{pathname}', \
									'$this->{directory_file_flag}')";

#		print "sql is $sql\n";

		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			die "Could not execute SQL $sql ... maybe invalid?";

		@row = $sth->fetchrow_array();

		$sth->finish();

		$this->{id} = $row[0];
	}

	# after saving, return the ID
	return $this->{id};
}

sub FetchByID {
	my $this	= shift;

	my $dbh		= $this->{dbh};

	my $sql = "select *, element_pathname(id) as pathname from element where id = $this->{id}";
	print "sql = '$sql'\n";

	my $sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid?";
	}

	my $row = $sth->fetchrow_hashref();

	$sth->finish();

	$this->{id} 				= $row->{id};
	$this->{name}				= $row->{name};
	$this->{parent_id}			= $row->{parent_id};
	$this->{directory_file_flag}= $row->{directory_file_flag};
	$this->{status}				= $row->{status};
	$this->{pathname}			= $row->{pathname};

	print "found id = $this->{id}\n";

	return $this->{id};
}

sub FetchByName {
	# obtain the element based on the pathname supplied
	my $this	= shift;

	my $dbh		= $this->{dbh};
	if (!$dbh) {
		die " no database handle!";
	}

	my ($sql, $sth, @row);

	my $tmp = $dbh->quote("things");
	$sql = "select Pathname_ID(" . $dbh->quote($this->{pathname}) . ")";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid?";
	}

	@row = $sth->fetchrow_array();

	$sth->finish();
	$this->{id} = $row[0];

	print "found id = $this->{id}\n";

	# now that we have the ID for this name, let's fetch it...
	#
	if ($this->{id}) {
		return $this->FetchByID();
	} else {
		return $this->{id};
	}
}

1;