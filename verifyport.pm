#!/usr/bin/perl -w

package FreshPorts::VerifyPort;

use category;
use port;

require Exporter;
require Sys::Syslog;

@ISA	= qw(Exporter);
@EXPORT	= qw(InitialiseNewMessage EnsureCategoryAndPortExist);

#
# WARNING: this hash is filled up during the processing of a single
# message.  You must call InitialiseNewMessage() at the start of each
# new message.

my %PortsChecked;

sub InitialiseNewMessage() {
	%PortsChecked = ();
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

	#
	# These are the directories/entries
	# which FreshPorts does not track
	#
	my $ignoredirs = "Attic|distfiles|Mk|Tools|Templates|Makefile|pkg";


	my $subtree;
	my $category;
	my $port;
	my $extra;

	($subtree, $category, $port, $extra) = split/\//,$filename, 4;

	print "\nEnsureCategoryAndPortExist starts:\n";
	print "element_id  = '$element_id'\nfilename = '$filename'\n";
	print "subtree  = '$subtree'\ncategory = '$category'\nport     = '$port'\nentry    = '$extra'\n";

	# first, we ignore all non-port tree items
	if ($subtree ne "ports") {
		# we don't process non-ports tree entries
		return;
	}

	if (index($ignoredirs, $category) != -1) {
		# certain items are definitely not ports.
		# so we don't care about them here
		return;
	}

	print "processing above entry...\n";

	if ($PortsChecked{"$category/$port"}) {
		print " we have already checked $category/$port\n";
		# we have already checked this port.
		# therefore it should already be in the database
	} else {
		my $category_id = GetCategory($category, $dbh);

		if (defined($category_id)) {
			print "Category $category has ID = $category_id\n";
		} else {
			# we need to create this catgory.
			# remember to grab ports/<category>/pkg/COMMENT
			Sys::Syslog::syslog('warning', "creating new category $category");

			$category_id = CreateCategory($category, $dbh);
			if (!defined($category_id)) {
				Sys::Syslog::syslog('warning', "failed to create new category $category");
				die "failed to create new category $category";
			}
		}

		my $port_id = GetPort("$category/$port", $dbh);
		if (defined($port_id)) {
			print "Port $port has ID = $port_id\n";
		} else {
			# we need to create this port
			# This will be an insert, rather than just an update
			# we we would do later below
			Sys::Syslog::syslog('warning', "creating new port $port");
			$port_id = CreatePort($element_id, $category_id, $dbh);

			if (!defined($port_id)) {
				Sys::Syslog::syslog('warning', "failed to create new port $category/$port");
				die "failed to create new port $category/$port";
			}
		}

		# add this port to the hash
		$PortsChecked{$category . "/" . $port} = [$port_id, $category_id];
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

sub GetNextValue($;$) {
   my $sequence = shift;
   my $dbh      = shift;
   my $sth;
   my $sql;
   my @row;

   $sql = "select nextval('$sequence')";

   $sth = $dbh->prepare($sql);
   $sth->execute ||
           die "Could not execute SQL $sql ... maybe invalid?";

   @row = $sth->fetchrow_array();

   $sth->finish();

   return $row[0];
}

sub CreatePort($;$;$) {
#
# create a new entry in the Ports table and return the id
# The other fields will be populated later using the same
# mechanism as is used for updating a port.
#
	my $element_id	= shift;
	my $category_id	= shift;
	my $dbh			= shift;

	my $port;

	$port = FreshPorts::Port->new($dbh);
	$port->{element_id}  = $element_id;
	$port->{category_id} = $category_id;

	$port->save();

	return $port->{id};
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
