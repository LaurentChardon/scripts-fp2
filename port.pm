#!/usr/bin/perl
#
# $Id: port.pm,v 1.1 2001-11-09 16:30:15 dan Exp $
#

package FreshPorts::Port;
require Exporter;
require	config;
require	element;

use strict;
use config;

# =================================

sub _initialize {
	my $this = shift;

	#
	# a value of -1 means that the refresh requirements have
	# not yet been established.
	# essentially, this is a newly added port.  some ports
	# are slave ports.  querying the Makefile will provide
	# the locations of the master port files required to
	# refresh this port.
	#
	$this->{needs_refresh} = -1;
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

	print "into FreshPorts::Port::save\n";

	#
	# to save, element_id and category_id must be valid
	# 

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	if ($this->{id}) {
		# we are updating

# correct this sql
		$sql = "update ports  \
				set \
				is_primary		= " . $dbh->quote($this->{is_primary}) . ", \
				element_id		= $this->{element_id}, \
				name			= " . $dbh->quote($this->{name}) . ", \
				description		= " . $dbh->quote($this->{description}) . " \
				needs_refresh	= $this->{needs_refresh} \
				 where id = $this->{id}";
		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			die "Could not execute SQL $sql ... maybe invalid?";
	} else {
		# we are inserting
		# do we really need to quote these things?
		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::ports_id_seq, $dbh);
		$sql = "insert into ports (id, element_id, category_id, needs_refresh) values ( \
				$this->{id}, \
				$this->{element_id}, \ 
				$this->{category_id}, \
				$this->{needs_refresh})";

		print "sql is $sql\n";

		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			die "Could not execute SQL $sql ... maybe invalid?";

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

	$sql = "select * from ports where id = $this->{id}";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid?";
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();

	$this->{id} 			= $row->{id};
	$this->{element_id}		= $row->{element_id};
	$this->{category_id}	= $row->{category_id};

	return $this->{id};
}

sub FetchByPartialPathName {
	# obtain the element based on the pathname supplied
	my $this = shift;

	my $dbh;
	my $sql;
	my $sth;
	my $row;
	my $tmp;

	$dbh = $this->{dbh};
	if (!$dbh) {
		die " no database handle!";
	}

 	my $element;

	$element = FreshPorts::Element->new($dbh);
	$element->{pathname} = "$FreshPorts::Config::ports_prefix/$this->{partialpathname}";
	$this->{element_id} = $element->FetchByName();

	if (!$this->{element_id}) {
		return $this->{element_id};
	}

	$tmp = $dbh->quote($this->{name});
	$sql = "select * \
              from ports, categories \
             where ports.element_id  = $this->{element_id} \
               and ports.category_id = categories.id";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid?";
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();

	$this->{id} 			= $row->{id};
	$this->{element_id}		= $row->{element_id};
	$this->{category_id}	= $row->{category_id};

	return $this->{id};
}

sub GetNeedsRefreshForNewPort() {
	my $this = shift;
	#
	# When a new port is imported, we need to get the
	# makefile and determine whether or not this port
	# uses a description or comments file.  If it does,
	# then we adjust needs_refresh accordingly.
	# Note that some ports use another ports description
	# or comments file.  Therefore we may not have
	# to fetch those files in order to complete
	# the importing of a new port
	#
	# this function tells you what files are needed by first fetching the Makefile
	# and using that to determine the other information.


	my $needs_refresh	= 0;
	my $category		= $this->{category};
	my $port			= $this->{name};

	print "category = $category\n";
	print "port     = $port\n";

	#
	# fetch the makefile for this port
	#
	my $DESTDIR	= "$FreshPorts::Config::path_to_ports/$category/$port";
	my $SRCDIR	= "$FreshPorts::Config::ports_prefix/$category/$port";
	my $FILE	= $FreshPorts::Constants::FILE_MAKEFILE;

	`sh $FreshPorts::Config::scriptpath/fetch-cvs-file.sh $DESTDIR $SRCDIR $FILE`;

	if (($? >> 8)) {
		#
		# This might be a nice place to retry a fetch, or send an email
		#
		print "that fetch failed.  What do to?\n";

		# and we're outta here
	} else {
		print "now doing a chdir to $DESTDIR\n";
		chdir "$DESTDIR";

		#
		# create this directory to catch errors
		# such as the pre-everything having only one ':'
		#
		mkdir "pkg",0;

		my $makecommand = "make -V DESCR -V COMMENT -f $DESTDIR/$FILE";

		# remove previously created directory
		rmdir "pkg";

		print "makecommand = $makecommand\n";
		(my $DESCR, my $COMMENT) = split(/\n/s, `$makecommand`);

		#
		# we need to check this return value.  if it fails, we need to know
		#

		if ($? == 0) {
			print "raw       data DESCR   = $DESCR\n";
			print "raw       data COMMENT = $COMMENT\n";

			#
			# some ports (e.g. korean/netscape47-communicator) use
			# ../ in their path names.  We must remove that in order
			# to find out if have to retrieve a file in our path
			#

			$DESCR   = File::PathConvert::realpath($DESCR);

			print "converted data DESCR   = $DESCR\n";
			print "converted data COMMENT = $COMMENT\n";

			my $entry = $FreshPorts::Constants::FILE_DESCRIPTION;
			if ($DESCR eq "$FreshPorts::Config::path_to_ports/$category/$port/$entry") {
				print "this port has it's own $entry\n";
				my $index = $FreshPorts::Constants::FilesWhichPromptRefresh{$entry};
				if ($index) {
				print "index = $index\n";
				$needs_refresh |= $index;
				}
			} else {
				print "this port uses $DESCR\n";
			}

			$entry = $FreshPorts::Constants::FILE_COMMENT;

			$COMMENT = File::PathConvert::realpath($COMMENT);
			if ($COMMENT eq "$FreshPorts::Config::path_to_ports/$category/$port/$entry") {
				print "this port has it's own $entry\n";
				my $index = $FreshPorts::Constants::FilesWhichPromptRefresh{$entry};
				if ($index) {
					print "index = $index\n";
					$needs_refresh |= $index;
				}
			} else {
				print "this port uses $COMMENT\n";
			}

			print "after all that, needs_refresh = $needs_refresh\n";
		} else {
			print "error executing make command: " . $?;
		}
	}

	return $needs_refresh;
}


1;