#!/usr/bin/perl -w

package FreshPorts::VerifyPort;

use element;
use category;
use port;

require Exporter;
require Sys::Syslog;

@ISA	= qw(Exporter);
@EXPORT	= qw(InitialiseNewMessage EnsureCategoryAndPortExist RefreshPortsAssociatedWithMessage);

#
# WARNING: this hash is filled up during the processing of a single
# message.  You must call InitialiseNewMessage() at the start of each
# new message.

my %PortsChecked;	# contains an element class object.
					# $PortsChecked{$category . "/" . $port} = [$port_id, $category_id];

sub InitialiseNewMessage() {
	undef %PortsChecked;
}

sub RefreshPortsAssociatedWithMessage($;$) {
	#
	# This function will refresh all ports associated with a given message.
	# The ports refreshed appear in %PortsChecked.
	# This variable is updated by EnsureCategoryAndPortExist and reset by
	# InitialiseNewMessage.
	#
	my $commit_log_id	= shift;
	my $Files			= shift;

	my $portname;		# of the form "$category/$port"
	my $port;			# of the form "$port_id/$category_id"

	my $action;
	my $filename;
	my $revision;
	my $value;

    my $subtree;
    my $category_name;
    my $port_name;
    my $extra;

	print "\n\nThat message is all done under Commit ID = '$commit_log_id'\n";

	print "the size of \@Files is ", scalar(@{$Files}), "\n";
	foreach $value (@{$Files}) {
		($action, $filename, $revision) = @$value;

		($subtree, $category_name, $port_name, $extra) = split/\//,$filename, 4;
		print "$action, $filename, $revision, $subtree, $category_name, $port_name, $extra\n";

		# is this file is in the ports tree?
		if ($subtree eq $FreshPorts::Config::ports_prefix) {
			print "yes, this file is in the ports tree\n";
			$index = $FreshPorts::Constants::FilesWhichPromptRefresh{$extra};
			if ($index) {
				print "yes, it's a File Which Prompts Refresh\n";
				# find the port for this filename....
				$port = $PortsChecked{"$category_name/$port_name"};
				if ($port) {
					$port->{needs_refresh} |= $index;
				} else {
					Sys::Syslog::syslog('warning', "could not find port '$category/$port' in hash.");
					die "could not find port '$category/$port' in hash.";
				}
			}
		}
	}


	print "\n\n\n********** These are the ports which must be updated\n\n\n";

	print "There are ", scalar(keys %PortsChecked), " key/value pairs in %PortsChecked\n";

	while (($portname, $port) = each %PortsChecked) {
		print "port = $portname, port_id = '$port->{id}', category_id='$port->{category_id}', needs_refresh='$port->{needs_refresh}'\n";

#		MarkPortAsRefreshNeeded($port_id, $commit_id, $action, $entry, $dbh);
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
	print "subtree  = '$subtree'\ncategory = '$category_name'\nport     = '$port_name'\nentry    = '$extra'\n";

	# first, we ignore all non-port tree items
	if ($subtree ne "ports") {
		# we don't process non-ports tree entries
		return;
	}

	if (index($FreshPorts::Constants::IgnoredItems, $category_name) != -1 || index($FreshPorts::Constants::IgnoredItems, $port_name) != -1) {
		# certain items are definitely not ports.
		# so we don't care about them here
		return;
	}

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
	}

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

Sys::Syslog::setlogsock('unix');
Sys::Syslog::openlog('FreshPorts', 'cons, pid', 'user');

1;
