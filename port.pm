#!/usr/bin/perl
# $Id: port.pm,v 1.14 2001-11-25 03:36:52 dan Exp $
#

package FreshPorts::Port;
require Exporter;
require	config;
require	element;
require utilities;

use File::PathConvert;
use strict;
use config;
use constants;

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
	$this->{needs_refresh}		= 0;

#	$this->{portname}			= '';
	$this->{short_description}	= '';
	$this->{long_description}	= '';
	$this->{version}			= '';
	$this->{revision}			= '';
	$this->{maintainer}			= '';
	$this->{homepage}			= '';
	$this->{master_sites}		= '';
	$this->{extract_suffix}		= '';
	$this->{package_exists}		= '';
	$this->{depends_build}		= '';
	$this->{depends_run}		= '';
	$this->{forbidden}			= '';
	$this->{broken}				= '';

print "$FreshPorts::Constants::commit_log_seq\n";
print "$FreshPorts::Constants::ports_seq\n";
print "$FreshPorts::Constants::commit_log_elements_seq\n";
}

sub _GetValuesFromRow {
	my $this = shift;
	my $row  = shift;

	$this->{id} 				= $row->{id};
	$this->{element_id}			= $row->{element_id};
	$this->{category_id}		= $row->{category_id};
	$this->{needs_refresh}		= $row->{needs_refresh};
	$this->{category}			= $row->{category};
	$this->{name}				= $row->{name};

	$this->{short_description}	= $row->{short_description};
	$this->{long_description}	= $row->{long_description};
	$this->{version}			= $row->{version};
	$this->{revision}			= $row->{revision};
	$this->{maintainer}			= $row->{maintainer};
	$this->{homepage}			= $row->{homepage};
	$this->{master_sites}		= $row->{master_sites};
	$this->{extract_suffix}		= $row->{extract_suffix};
	$this->{package_exists}		= $row->{package_exists};
	$this->{depends_build}		= $row->{depends_build};
	$this->{depends_run}		= $row->{depends_run};
	$this->{forbidden}			= $row->{forbidden};
	$this->{broken}				= $row->{broken};
	$this->{last_commit_id}     = $row->{last_commit_id};
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

# correct this sql to update all fields...

		$sql = "update ports  \
				set \
				needs_refresh		= $this->{needs_refresh},
				short_description	= " . $dbh->quote($this->{short_description})	. ", \
				long_description	= " . $dbh->quote($this->{long_description})	. ", \
				version				= " . $dbh->quote($this->{version})				. ", \
				revision			= " . $dbh->quote($this->{revision})			. ", \
				maintainer			= " . $dbh->quote($this->{maintainer})			. ", \
				homepage			= " . $dbh->quote($this->{homepage})			. ", \
				master_sites		= " . $dbh->quote($this->{master_sites})		. ", \
				extract_suffix		= " . $dbh->quote($this->{package_exists})		. ", \
				depends_build		= " . $dbh->quote($this->{depends_build})		. ", \
				depends_run			= " . $dbh->quote($this->{depends_run})			. ", \
				forbidden			= " . $dbh->quote($this->{forbidden})			. ", \
				broken				= " . $dbh->quote($this->{broken})				. ", \
				last_commit_id		= $this->{last_commit_id} \
				where id = $this->{id}";

print "sql = $sql\n";

		$sth = $this->{dbh}->prepare($sql);
		$sth->execute ||
			die "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr;
	} else {
		# we are inserting
		# do we really need to quote these things?

		if (!$this->{category_id} && $this->{partialpathname}) {
			#
			# we have a partial name but no element.
			# let's get the element
			#
			$this->{element_id} = $this->_FetchElementIDByPartialPathName();
		}

		if (!$this->{element_id} || !$this->{category_id}) {
			Sys::Syslog::syslog('warning', "Cannot create new port.  Insufficient data");
			die "Cannot create new port.  Insufficient data";
		}

		#
		# update this sql to insert all fields?

		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::ports_seq, $dbh);

		#
		# we might be creating a new port for a port which has just been deleted.
		# we don't want to do this if the port has been deleted.
		# that sounds odd... but anything can happen...
		#
		if (!defined($this->{deleted})) {
			if (!defined($this->{name}) || !defined($this->{category})) {
				Sys::Syslog::syslog('warning', "Cannot _GetNeedsRefreshForNewPort.  Insufficient data");
				die "Cannot _GetNeedsRefreshForNewPort.  Insufficient data";
			}
			if (!$this->_GetNeedsRefreshForNewPort()) {
				Sys::Syslog::syslog('warning', "Cannot _GetNeedsRefreshForNewPort.  Fetch failed");
				die "Cannot _GetNeedsRefreshForNewPort.  Fetch failed";
			}
		}

		$sql = "insert into ports (id, element_id, category_id, needs_refresh) values ( \
				$this->{id}, \
				$this->{element_id}, \ 
				$this->{category_id}, \
				$this->{needs_refresh})";

		print "sql is $sql\n";

		$sth = $this->{dbh}->prepare($sql);
		if (!$sth->execute) {
			Sys::Syslog::syslog('warning', "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr);
			die "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr;
		}

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

	$sql = "select ports.*, categories.name as category, element.name as name \
              from ports, categories, element \
             where ports.id          = $this->{id} \
               and ports.category_id = categories.id \
               and ports.element_id  = element.id";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr;
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();

	# no sense setting values if we didn't get anything...
	if ($row) {
		$this->_GetValuesFromRow($row);
	}

	return $this->{id};
}

sub FetchByPartialPathName {
	# obtain the port based on the pathname supplied
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

	$this->{element_id} = $this->_FetchElementIDByPartialPathName();
	#
	# if there is no element corresponding to this port anme, we can't find anything...
	#
	if (!$this->{element_id}) {
		return $this->{element_id};
	}

	$tmp = $dbh->quote($this->{name});
	$sql = "select ports.*, categories.name as category, element.name as name \
              from ports, categories, element \
             where ports.element_id  = $this->{element_id} \
               and ports.category_id = categories.id \
               and ports.element_id  = element.id";
	print "sql = '$sql'\n";

	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid? " . $dbh->errstr;
	}

	$row = $sth->fetchrow_hashref();

	$sth->finish();

	# no sense setting values if we didn't get anything...
	if ($row) {
		$this->_GetValuesFromRow($row);
	}

	return $this->{id};
}

sub _FetchElementIDByPartialPathName {
	# obtain the element based on the pathname supplied
	my $this = shift;

	my $dbh;

	$dbh = $this->{dbh};
	if (!$dbh) {
		die " no database handle!";
	}

 	my $element;

	$element = FreshPorts::Element->new($dbh);
	$element->{pathname} = "$FreshPorts::Config::ports_prefix/$this->{partialpathname}";
	$this->{element_id} = $element->FetchByName();

	return $this->{element_id};
}

sub _GetNeedsRefreshForNewPort {
	my $this = shift;

	my $result = 0;	# return 0 for fail
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


	my $category	= $this->{category};
	my $port		= $this->{name};

	if (!defined($category) || !defined($port)) {
		Sys::Syslog::syslog('warning', "Cannot _GetNeedsRefreshForNewPort.  Insufficient data");
		die "Cannot _GetNeedsRefreshForNewPort.  Insufficient data";
	}

	print "category = $category\n";
	print "port     = $port\n";

	#
	# fetch the makefile for this port
	#
	my $DESTDIR	= "$FreshPorts::Config::path_to_ports/$category/$port";
	my $SRCDIR	= "$FreshPorts::Config::ports_prefix/$category/$port";
	my $FILE	= $FreshPorts::Constants::FILE_MAKEFILE;

	my $FetchAttempts = 5;

	while ($FetchAttempts) {
		`sh $FreshPorts::Config::scriptpath/fetch-cvs-file.sh $DESTDIR $SRCDIR $FILE`;

		if (($? >> 8)) {
			#
			# This might be a nice place to retry a fetch, or send an email
			#
			print "that fetch failed.  What do to?\n";

			# and we're outta here
			# fetch failed
			# sleep, then try again
			Sys::Syslog::syslog('warning', "sleeping after fetch failed for ($DESTDIR $SRCDIR $FILE)");
			print "fetch failed, sleeping...\n";
			sleep 10;
			$FetchAttempts--;

		} else {
			# fetch worked
			last;
		}
    }

	#
	# if we succeeded in our fetch..
	if ($FetchAttempts) {
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
			if ($DESCR ne "$FreshPorts::Config::path_to_ports/$category/$port/$entry") {
				print "this port has it's own $entry\n";
				my $index = $FreshPorts::Constants::FilesWhichPromptRefresh{$entry};
				if ($index) {
				print "index = $index\n";
				$this->{needs_refresh} |= $index;
				}
			} else {
				print "this port uses $DESCR\n";
			}

			$entry = $FreshPorts::Constants::FILE_COMMENT;

			$COMMENT = File::PathConvert::realpath($COMMENT);
			if ($COMMENT ne "$FreshPorts::Config::path_to_ports/$category/$port/$entry") {
				print "this port has it's own $entry\n";
				my $index = $FreshPorts::Constants::FilesWhichPromptRefresh{$entry};
				if ($index) {
					print "index = $index\n";
					$this->{needs_refresh} |= $index;
				}
			} else {
				print "this port uses $COMMENT\n";
			}

			$result = 1; # if we get here, we did good..

		} else {
			print "error executing make command: " . ($? >> 8) . "\n";
			Sys::Syslog::syslog('warning', "error executing make command: Error Code = " . ($? >> 8));
			die "error executing make command: Error Code = " . ($? >> 8) . "\n";
		}
	}

	print "\nand from _GetNeedsRefreshForNewPort we get needs_refresh = $this->{needs_refresh}\n";

	return $result;
}


sub ExtractValuesFromMakefile {
	my $this = shift;

	my $result;
	my $makecommand;

	my $MakefileDirectory = "$FreshPorts::Config::path_to_ports/$this->{category}/$this->{name}";

	#
	# if we don't change the working dir, stuff like descrpath will not
	# contain /usr/ports/...etc.  It will look more like this:
	#     /usr/home/dan/walkports/
	# That's because DESCR is defined as .{CURDIR}/etc more or less
	#
	chdir "$MakefileDirectory";

	# we create this directory because it helps us to locate problems
	#
	# create this directory to catch errors
	# such as the pre-everything having only one ':'
	#
	mkdir "pkg",0;

	$makecommand = "make -V PORTNAME -V PKGNAME -V DESCR -V CATEGORIES -V PORTVERSION -V PORTREVISION " .
		" -V COMMENT -V MAINTAINER -V EXTRACT_SUFX -V MASTER_SITES " .
		" -V BUILD_DEPENDS -V RUN_DEPENDS -V FORBIDDEN -V BROKEN -f $MakefileDirectory/$FreshPorts::Constants::FILE_MAKEFILE";

	print "makecommand = $makecommand\n";

	(my $portname, my $packagename, my $descrpath, my $categories, my $portversion, my $portrevision, my $commentfile,
	 my $maintainer, my $extractsuffix, my $mastersites, my $builddepends,
	 my $rundepends, my $forbidden, my $broken) = split(/\n/s, `$makecommand`);

	# save this for later reference
	$result = $?;

	# remove previously created directory
	rmdir "pkg";

	#
	# we need to check this return value.  if it fails, we need to know
	#

	if ($result == 0) {

		print " portname     ='$this->{name}'\n";
		print " packagename  ='$portname'\n";
		print " category     ='$this->{category}'\n";
		print " packagename  ='$packagename'\n";
		print " descrpath    ='$descrpath'\n";
		print " categories   ='$categories'\n";
		print " portversion  ='$portversion'\n";
		print " portrevision ='$portrevision'\n";
		print " commentfile  ='$commentfile'\n";
		print " maintainer   ='$maintainer'\n";
		print " extractsuffix='$extractsuffix'\n";
		print " mastersites  ='$mastersites'\n";
		print " builddepends ='$builddepends'\n";
		print " rundepends   ='$rundepends'\n";

		(my $longdescription, my $homepage) = _GetDescrAndHomePage($descrpath);
		my $shortdescription = FreshPorts::Utilities::ReadFile($commentfile);

		my $packageexists = _PackageExists($packagename . ".tgz");

		print "12 $shortdescription\n";
		print "13 $longdescription\n";
		print "14 ";
		if (defined($homepage)) {
			print "$homepage";
		}
		print "\n";

		print "15 $packageexists\n";
		print "16 $forbidden\n";
		print "17 $broken\n";

		print "\n ---------------------------------------- \n";

		# convert a few values to zero if not defined.
		if (!defined($forbidden)) {
			$forbidden = '';
		}

		if (!defined($broken)) {
			$broken = '';
		}

		# put everything into the hash...

		$this->{portname}			= $portname;
		$this->{short_description}	= $shortdescription;
		$this->{long_description}	= $longdescription;
		$this->{version}			= $portversion;
		$this->{revision}			= $portrevision;
		$this->{maintainer}			= $maintainer;
		$this->{homepage}			= $homepage;
		$this->{master_sites}		= $mastersites;
		$this->{extract_suffix}		= $extractsuffix;
		$this->{package_exists}		= $packageexists;
		$this->{depends_build}		= $builddepends;
		$this->{depends_run}		= $rundepends;
		$this->{forbidden}			= $forbidden;
		$this->{broken}				= $broken;

	} else {
		$result = -1;
	}

	return $result;
}

sub FetchFilesNeedingRefresh {
	# a return of zero indicates success.

	my $this	= shift;
	my $result	= 0;

#	print " now in RefreshOnePort.  press enter to continue\n";
# <STDIN>;

	# now find out what needs to be refreshed....

	print "needs_refresh = $this->{needs_refresh}\n";

	my $FetchWorked = 1;

	# 2000.06.09 - Dan Langille
	#
	# Here is the question I asked in #perl.  Can you tell nobody else
	# was active?
	#
	# I'm having trouble with a hash.  the definition is hardcoded as a
	# constant at the top of the file.  I use the hash in a function
	# which called repeatedly.  In the function I do this: while ((my
	# $key, my $value) = each %FilesWhichPromptRefresh) {...etc  but:
	# 
	# if I exit the while using "last", the next time I call the
	# function, it never enters the while.  I suspect the hash is either
	# being cleared out or needs to be "reset".  sound familiar?
	# 
	# looking at the documentation for values, it mentions that function
	# "resets HASH's iterator".  sounds like something I need.
	# OK.  doing this before the while fixes the problem: keys
	# %FilesWhichPromptRefresh;  <== but there must be a better. way.
	#
	keys %FreshPorts::Constants::FilesWhichPromptRefresh;

	# this is where we fetch the files to disk
	my $DESTDIR	= "$FreshPorts::Config::path_to_ports/$this->{category}/$this->{name}";

	# this is the location in the repository.
	my $SRCDIR	= "$FreshPorts::Config::ports_prefix/$this->{category}/$this->{name}";

	while ((my $FILE, my $value) = each %FreshPorts::Constants::FilesWhichPromptRefresh) {
		if ($this->{needs_refresh} & $value) {
			print "now fetching $FILE\n";
			#
			# should this be path hardcoded?
			# if it isn't, the chdir which occurs in RefreshPort below
			# makes this call fail (because it can't find the script).
			#
         
			`sh $FreshPorts::Config::scriptpath/fetch-cvs-file.sh $DESTDIR $SRCDIR $FILE`;

			if (($? >> 8)) {
				#
				# This might be a good place to refetch, loop. or send an email.
				#
				print "that fetch failed.  What do to?\n";
				$FetchWorked = 0;

				# and we're outta here
				last;
			}
		}
	}

#	print "press enter to continue "; <STDIN>;

	if ($FetchWorked) {
		print "refreshing port...\n";
#		$result = RefreshPort($dirname, $port, $dbh);
	} else {
		print "can't do anything about that port...\n";
		$result = 1;
	}

	return $result;
}


# =================================
sub _GetDescrAndHomePage($) {

	my $file = shift;
	my $url;
	my $DESCR;

	open (F,$file) || die "couldn't open $file: $!";;
	$DESCR = "";
	
	while(<F>){
		$DESCR .= $_;
		if(/WWW:(.*)/) {

#			print "found a home page of $url\n";

			$url = $1;
			$url =~  s/^\s+//g;
		}
	}

	close F;

	my @result = ($DESCR, $url);

	return @result;
}


# =================================
sub _PackageExists($) {
	# returns "Y" if the package exists, "N" otherwise.

	my $package = shift;
	my $exists  = "N";

	my $package_list = "$FreshPorts::Config::scriptpath/packages.exists";

	`grep $package $package_list`;

	if (!$?) {
		$exists = "Y";
	}

	return $exists;
}

sub RefreshFromFiles() {
#
# refresh this port based on the make files associated with it and the value of needs_refresh
#
	my $this    = shift;

	my $result	= 0;

	my $FetchAttempts = 5;

	if ($this->{needs_refresh} > 0) {
		while ($FetchAttempts) {
			if (!$this->FetchFilesNeedingRefresh()) {
				$this->ExtractValuesFromMakefile();
				$this->{needs_refresh} = 0;
				$this->save();
				last;
			} else {
				# fetch failed
				# sleep, then try again
				Sys::Syslog::syslog('warning', "sleeping after fetch failed for ($this->{id}, $this->{category}, $this->{name}, $this->{needs_refresh})");
				print "fetch failed, sleeping...\n";
				sleep 10;
				$FetchAttempts--;
			}
		}
	} else {
		print "this port does not need a refresh\n";
	}

	if (!$FetchAttempts) {
		$result = 1;
	}

	return $result;
}

FreshPorts::Utilities::InitSyslog();

1;