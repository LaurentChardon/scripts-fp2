#!/usr/bin/perl -w

package FreshPorts::VerifyPort;

use element;
use category;
use port;
use commit_log_port;
use utilities;

#require Exporter;
require Sys::Syslog;

#
# WARNING: this hash is filled up during the processing of a single
# message.  You must call InitialiseNewMessage() at the start of each
# new message.

my %PortsChecked;	# contains an element class object.

sub InitialiseNewMessage() {
	undef %PortsChecked;
}

sub SetNeedsRefreshForPortsAssociatedWithMessage($;$) {
	#
	# This function will refresh all ports associated with a given message.
	# The ports refreshed appear in %PortsChecked.
	# This variable is updated by EnsureCategoryAndPortExist and reset by
	# InitialiseNewMessage.
	#
	my $commit_log_id	= shift;
	my $Files			= shift;

	my $portname;			# of the form "$category/$port"
	my $port;				# of type FreshPorts::Element
	my $commit_log_port;	# of type FreshPorts::CommitLogPort

	my $action;
	my $filename;
	my $revision;
	my $commit_log_element_id;
	my $value;

	my $subtree;
	my $category_name;
	my $port_name;
	my $extra;

	$commit_log_port = FreshPorts::CommitLogPort->new($dbh);

	print "\n\nThat message is all done under Commit ID = '$commit_log_id'\n";

	print "the size of \@Files is ", scalar(@{$Files}), "\n";

	#
	# in this loop assign a value to needs_refresh for each port
	#
	foreach $value (@{$Files}) {
		($action, $filename, $revision, $commit_log_element_id) = @$value;

		($subtree, $category_name, $port_name, $extra) = split/\//,$filename, 4;
		print "$action, $filename, $revision, $subtree, $category_name, ";
		if (defined($port_name)) {
			print "$port_name, ";
		}

		if (defined($extra)) {
			print "$extra, ";
		}

		print "$commit_log_element_id\n";

		# is this file is in the ports tree?
		# e.g. ports/LEGAL won't get through here because $port_name will not be defined.
		if ($subtree eq $FreshPorts::Config::ports_prefix && defined($category_name) && defined($port_name)) {
			print "yes, this file is in the ports tree\n";

			if (!defined($FreshPorts::Constants::IgnoredItems{$category_name}) && !defined($FreshPorts::Constants::IgnoredItems{$port_name})) {
				# find the port for this filename....
				$port = $PortsChecked{"$category_name/$port_name"};
				if (!$port) {
					Sys::Syslog::syslog('warning', "could not find port '$category/$port' in hash.");
					die "could not find port '$category/$port' in hash.";
				}

				#
				# if we just deleted the Makefile for this port, there's no sense in refreshing the port.
				# because it's been deleted.
				#
				if ($extra eq $FreshPorts::Constants::FILE_MAKEFILE && $action eq $FreshPorts::Constants::REMOVE ) {
					#
					# we are deleted (local value, never actually saved to db)
					#
					$port->{deleted}		= 1;
					$port->{needs_refresh}	= 0;
					print "THIS PORT HAS BEEN DELETED\n";
				}

				#
				# make sure this commit isn't deleting us...
				# NOTE: {deleted} may have been set while processing a previous file name
				#
				if (!defined($port->{deleted})) {
					$index = $FreshPorts::Constants::FilesWhichPromptRefresh{$extra};
					if ($index) {
						print "yes, it's a File Which Prompts Refresh\n";
						$port->{needs_refresh} |= $index;
					}
				}

				#
				# record which files go with what port...
				#
				$commit_log_port->{commit_log_id}			= $commit_log_id;
				$commit_log_port->{port_id}					= $port->{id};
				$commit_log_port->{commit_log_element_id}	= $commit_log_element_id;
				$commit_log_port->save();
			} else {
				print "... but is on the list of IgnoredItems!\n\n";
			}
		}
	}


	print "\n\n\n********** These are the ports which must be updated\n\n\n";

	print "There are ", scalar(keys %PortsChecked), " key/value pairs in %PortsChecked\n";

	#
	# for each port, refresh that port
	#
	while (($portname, $port) = each %PortsChecked) {
		print "port = $portname, port_id = '$port->{id}', category_id='$port->{category_id}', needs_refresh='$port->{needs_refresh}'\n";

		$port->{last_commit_id} = $commit_log_id;

		$port->save();
	}
}

sub RefreshAllPortsTouchedByCommit() {
#
# given the ports touched by this commit
# refresh each of them
#

	while (($portname, $port) = each %PortsChecked) {
		print "port = $portname, port_id = '$port->{id}', category_id='$port->{category_id}', needs_refresh='$port->{needs_refresh}'\n";

		$port->RefreshFromFiles();
	}
}



sub EnsureCategoryAndPortExist($;$;$) {
#
# This function takes an incoming file name, checks
# to see if it's in the ports tree, and if so, ensures the category
# and port exist within the tree.
#

	$element_id	= shift;
	$filename	= shift;
	$dbh		= shift;


	my $subtree;
	my $category_name;
	my $port_name;
	my $extra;

	($subtree, $category_name, $port_name, $extra) = split/\//,$filename, 4;

	print "\nEnsureCategoryAndPortExist starts:\n";
	print "element_id  = '$element_id'\nfilename = '$filename'\n";

	print "subtree  = '$subtree'\n";

	# don't go printing out stuff which does not exist...
	if (defined($category)) {
		print "category = '$category_name'\n";
		if (defined($port_name)) {
			print "port     = '$port_name'\n";
			if (defined($extra)) {
				print "entry    = '$extra'\n";
			}
		}
	}

	# first, we ignore all non-port tree items
	if ($subtree eq $FreshPorts::Config::ports_prefix && defined($category_name) && defined($port_name)) {
		if (!defined($FreshPorts::Constants::IgnoredItems{$category_name}) && !defined($FreshPorts::Constants::IgnoredItems{$port_name})) {

			print "processing above entry...\n";

			if ($PortsChecked{"$category_name/$port_name"}) {
				print " we have already checked $category_name/$port_name\n";
				# we have already checked this port.
				# therefore it should already be in the database
			} else {
				#
				# variables needed only in this block
				#
				my $category;
				my $port;

				print "checking for category='$category_name'\n";

				$category = FreshPorts::Category->new($dbh);
				$category->{name} = $category_name;
				my $category_id = $category->FetchByName();

				if (defined($category_id)) {
					print "Category $category_name has ID = $category_id\n";
				} else {
					# we need to create this catgory.
					# remember to grab ports/<category>/pkg/COMMENT
					Sys::Syslog::syslog('warning', "creating new category $category_name");

					$category->{is_primary} = 1;
					$category_id = $category->save();
					if (!defined($category_id)) {
						Sys::Syslog::syslog('warning', "failed to create new category $category_name");
						die "failed to create new category $category_name";
					}
				}

				print "checking for port='$category_name/$port_name'\n";

				$port = FreshPorts::Port->new($dbh);
				$port->{partialpathname} = "$category_name/$port_name";
				$port->FetchByPartialPathName();
				if (defined($port->{id})) {
					print "Port $port_name has ID = $port->{id}\n";
				} else {
					# we need to create this port
					# This will be an insert, rather than just an update
					# we we would do later below
					Sys::Syslog::syslog('warning', "creating new port $port_name");
					$port = CreatePort($category_name, $port_name, $category_id, $dbh);

					if (!defined($port->{id})) {
						Sys::Syslog::syslog('warning', "failed to create new port $category_name/$port_name");
						die "failed to create new port $category_name/$port_name";
					}
				}

				# add this port to the hash
				$PortsChecked{"$category_name/$port_name"} = $port;

			} # we've already checked this port
		
		} # this is an ignored file

	} # this isn't the ports tree

	print "EnsureCategoryAndPortExist ends\n";
}

sub GetPort($;$) {
	my $port = shift;
	my $dbh  = shift;
	my $sth;
	my $sql;
	my @row;

	$sql = "select GetPort('$port')";
	print "GetPort sql = $sql\n";

	$sth = $dbh->prepare($sql);
	$sth->execute || die "Could not execute SQL $sql ... maybe invalid?";

	@row = $sth->fetchrow_array();

	$sth->finish();

	return $row[0];
}

sub GetCategory($;$) {
	my $category = shift;
	my $dbh      = shift;
	my $sth;
	my $sql;
	my @row;

	$sql = "select GetCategory('$category'::text)";
	print "GetCategory sql = $sql\n";

	$sth = $dbh->prepare($sql);
	$sth->execute || die "Could not execute SQL $sql ... maybe invalid?";

	@row = $sth->fetchrow_array();

	$sth->finish();

	return $row[0];
}

sub CreatePort($;$;$;$) {
#
# create a new entry in the Ports table and return the id
# The other fields will be populated later using the same
# mechanism as is used for updating a port.
#
	my $category_name	= shift;
	my $port_name		= shift;
	my $category_id		= shift;
	my $dbh				= shift;

	my $port;
	my $element;
	my $element_id;

	#
	# obtain the element which corresponds to this port
	#

	$element = FreshPorts::Element->new($dbh);
	$element->{pathname} = "/$FreshPorts::Config::ports_prefix/$category_name/$port_name";

	$element_id = $element->FetchByName();

	if (!$element_id) {
		# create the element
		$element_id = $element->save;
	}

	$port = FreshPorts::Port->new($dbh);
	$port->{element_id}  = $element_id;
	$port->{category_id} = $category_id;
	$port->{category}    = $category_name;
	$port->{name}        = $port_name;

	$port->save();

	return $port;
}

sub CreateCategory($;$) {
	my $name	= shift;
	my $dbh		= shift;

	my $category;

	$category = FreshPorts::Category->new($dbh);
	$category->{name}		= $name;
	$category->{is_primary}	= 1;
	$category->save;

	return $category->{id};
}

FreshPorts::Utilities::InitSyslog();

1;
