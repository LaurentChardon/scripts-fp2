#!/usr/bin/perl
#
# $Id: category.pm,v 1.4 2001-11-08 23:15:03 dan Exp $
#

package FreshPorts::Category;
require Exporter;
require	config;

use strict;
use config;

# =================================

sub _initialize {
}

# =================================

sub new {
	my $this		= {};
	my $class		= shift;

	$this->{dbh}	= shift;

	bless $this;
	$this->_initialize();
	return $this;
}

sub save {
	my $this = shift;

	print "into FreshPorts::Category::save\n";

	#
	# if id is supplied, we are updating. otherwise we are inserting.
	# if element_id is supplied, it will be used.  Otherwise, it will
	# be derived from name based on /ports/<name>.
	# A new element will be created if necessary.
	#
	# For new categories:
	# description will be obtained from the contents of
	# /ports/<name>/pkg/COMMENT
	# 

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	# get the name if not supplied
	if (!$this->{name}) {
		die "name not supplied";
	}

	if (!$this->{is_primary}) {
		die "is_primary not supplied";
	}

	if (!$this->{description}) {
		$this->{description} = _description_fetch("$this->{name}");
	}

	if ($this->{id}) {
		# we are updating
		$sql = "update categories  \
				set \
				is_primary = " . $dbh->quote($this->{is_primary}) . ", \
				element_id = $this->{element_id}, \
				name      = " . $dbh->quote($this->{name}) . ", \
				description = " . $dbh->quote($this->{description}) . " \
				 where id = $this->{id}";
		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			die "Could not execute SQL $sql ... maybe invalid?";
	} else {
		# we are inserting
		$sql = "select CreateCategory(" . $dbh->quote($this->{name}) . ", \
				" . $dbh->quote($this->{description}) . ", \
				" . $dbh->quote($this->{is_primary}) . ")";

		print "sql is $sql\n";

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

	my $dbh;
	my $sql;
	my $sth;
	my $row;

	$dbh		= $this->{dbh};

	$sql = "select * from categories where id = $this->{id}";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid?";
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();

	$this->{id} 			= $row->{id};
	$this->{is_primary}		= $row->{is_primary};
	$this->{element_id}		= $row->{element_id};
	$this->{name}			= $row->{name};
	$this->{description}	= $row->{description};

	return $this->{id};
}

sub FetchByName {
	# obtain the element based on the pathname supplied
	my $this	= shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;
	my $tmp;

	$dbh		= $this->{dbh};
	if (!$dbh) {
		die " no database handle!";
	}

	$tmp = $dbh->quote($this->{name});
	$sql = "select * from categories where name = $tmp";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid?";
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();

	$this->{id} 			= $row->{id};
	$this->{is_primary}		= $row->{is_primary};
	$this->{element_id}		= $row->{element_id};
	$this->{name}			= $row->{name};
	$this->{description}	= $row->{description};

	return $this->{id};
}

1;

# =================================

sub _description_fetch {
	my $category	= shift;

	my $DESTDIR		= "/usr/ports/$category/pkg";
	my $SRCDIR		= "ports/$category/pkg";
	my $FILE		= "COMMENT";

#	print "FreshPorts::Config::scriptpath=$FreshPorts::Config::scriptpath\n";
	print "DESTDIR=$DESTDIR\n";
	print "SRCDIR =$SRCDIR\n";
	print "FILE   =$FILE\n";

	`sh $FreshPorts::Config::scriptpath/fetch-cvs-file.sh $DESTDIR $SRCDIR $FILE`;

	my $description = _ReadFile("$DESTDIR/$FILE");

	# get rid of the trailing CR/LF.
	chomp $description;

	return $description;
}

# =================================

sub _ReadFile($) {

   my $file = shift;
   my $content;

   open F,$file;

   $content = "";
   while(<F>){
      $content .= $_;
   }

   close F;

   return $content;
}
