#!/usr/bin/perl -w

package FreshPorts::VerifyPort;

use strict;
use element;
use category;
use port;
use commit_log_port;
use utilities;

require Sys::Syslog;

#
# WARNING: this hash is filled up during the processing of a single
# message.  You must call InitialiseNewMessage() at the start of each
# new message.

sub InitialiseNewMessage() {
}

sub _CompileListOfPorts($;$;$) {
	my $commit_log_id	= shift;
	my $Files			= shift;
	my $dbh				= shift;

	my %ListOfPorts;		# returned from this function
	my %CategoriesChecked;	# contains category class objects.

	my $value;
	my $category;
	my $port;

	print "STARTING _CompileListOfPorts ................................\n";

	foreach $value (@{$Files}) {
		my ($action, $filename, $revision, $commit_log_element_id) = @$value;

		my ($subtree, $category_name, $port_name, $extra) = split/\//,$filename, 4;
		print "FILE ==: $action, $filename, $revision, $subtree, $category_name, ";
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
				if ($ListOfPorts{"$category_name/$port_name"}) {
					print "but we have already seen the port $category_name/$port_name\n\n";
					# we've already added this port to the list of ports for this commit
				} else {
					#
					# check that the category exists.  and the port.
					# But we don't create any ports yet.
					# we do that, if necessary, later.
					#

					print "checking for category='$category_name'\n";

					$category = $CategoriesChecked{$category_name};
					if (!defined($category)) {
						$category = FreshPorts::Category->new($dbh);
						$category->{name} = $category_name;
						my $category_id = $category->FetchByName();

						if (defined($category_id)) {
							print "Category $category_name has ID = $category_id\n";
						} else {
							# we need to create this catgory.
							# remember to grab ports/<category>/pkg/COMMENT
							print "creating new category $category_name\n";
							Sys::Syslog::syslog('warning', "creating new category $category_name");

							$category->{is_primary} = 1;
							$category_id = $category->save();
							if (!defined($category_id)) {
								Sys::Syslog::syslog('warning', "failed to create new category $category_name");
								die "failed to create new category $category_name";
							}

						$CategoriesChecked{$category_name} = $category;
						}
					} else {
						print "found that category $category_name in the cache\n";
					}

					print "checking for port='$category_name/$port_name'\n";

					$port = $ListOfPorts{"$category_name/$port_name"};
					if (!$port) {
						print "* * * we'll have to create that port!\n";
						$port = FreshPorts::Port->new($dbh);

						# this is all that's needed to retrieve a port which exists
						$port->{partialpathname}	= "$category_name/$port_name";


						$port->FetchByPartialPathName();
						#
						# the above fetch may have failed.
						# in which case, $port->{id} will not be defined
						# we will take advantage of that later.
						# for now, all we want is a complete list of ports.
						#
						if (!defined($port->{id})) {
							#
							# these are the values needed to create a new port
							#
							$port->{category_id}	= $category->{id};
							$port->{name}			= $port_name;
							$port->{category}		= $category_name;
						}

print "SETTING CATEGORY =  $port->{category_id}\n";
						$ListOfPorts{"$category_name/$port_name"} = $port;
					} else {
						print "found that port $category_name/$port_name in the cache\n";
					}

					#
					# $port now contains the port for this file.
					# let's adjust the needs_refresh value.
					#
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
						my $index = $FreshPorts::Constants::FilesWhichPromptRefresh{$extra};
						if ($index) {
							print "yes, it's a File Which Prompts Refresh (index = $index)\n";
							$port->{needs_refresh} |= $index;
							print "needs_refresh is now $port->{needs_refresh}\n";
						}
					}
				}
			} else {
				print "... but is on the list of IgnoredItems!\n\n";
			}
		} else {
			print "that file isn't in the ports tree\n";
		}
	}	

	print "ENDING _CompileListOfPorts ................................\n";

	return %ListOfPorts;
}

sub SaveChangesToPortsTree($;$;$;$) {
	my $commit_date		= shift;
	my $commit_log_id	= shift;
	my $Files			= shift;
	my $dbh				= shift;

	my %ListOfPorts;

#
# %Files will contain a hash of all the files associated with this commit
# We will do three things
#   1 - populate PortsChecked with a list of ports 
#   2 - ensure said ports and their categories exit
#   3 - set needs_refresh on each port according to the files touched
#       by this commit
#


	#
	# This list of ports may not all be in the database.
	# We'll deal with that as we go along.
	#
	%ListOfPorts = _CompileListOfPorts($commit_log_id, $Files, $dbh);

	#
	# only do this stuff if we actually have any ports to update...
	#
	if (scalar %ListOfPorts) {

		#
		# for each port, ensure that we save away the new needs_refresh value
		# This will also create any ports which need to be created
		#
		while (my ($portname, $port) = each %ListOfPorts) {
			print "port = $portname, port_id = '";
			if (defined($port->{id})) {
				print $port->{id};
			}

			print "', category_id='";
			if (defined($port->{category_id})) {
				print $port->{category_id};
			}

			print "', needs_refresh='$port->{needs_refresh}'\n";

			$port->{last_commit_id} = $commit_log_id;

			$port->save();
		}

		_RecordPortFilesTouchedByThatCommit($commit_log_id, $Files, \%ListOfPorts, $dbh);

		_DeleteDeletedPorts(\%ListOfPorts, $dbh);

		# create the daily summaries
		CreateDailySummary($commit_date, $dbh);
	}

	return %ListOfPorts;
}

sub _RecordPortFilesTouchedByThatCommit($;$;$;$) {
	#
	# This function will populate the commit_log_port table.
	#
	my $commit_log_id	= shift;
	my $Files			= shift;
	my $PortsRef		= shift;
	my $dbh				= shift;

	my %Ports 			= %{$PortsRef};

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
		print "FILE ==: $action, $filename, $revision, $subtree, $category_name, ";
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
				$port = $Ports{"$category_name/$port_name"};
				if (!$port) {
					Sys::Syslog::syslog('warning', "could not find port '$category_name/$port_name' in hash.");
					die "could not find port '$category_name/$port_name' in hash.";
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
}

sub RefreshAllPortsTouchedByCommit($) {
	#
	# given the ports touched by this commit
	# refresh each of them
	#

	my $PortsRef	= shift;
	my %Ports		= %{$PortsRef};

	#
	# refresh each and every port we are told about
	#
	print "# # # # Refreshing ports # # # #\n\n";
	while (my ($portname, $port) = each %Ports) {
		print "port = $portname, port_id = '$port->{id}', category_id='$port->{category_id}', needs_refresh='$port->{needs_refresh}'\n";

		$port->RefreshFromFiles();
	}

	print "# # # # done refreshing ports # # # #\n\n";
}

sub _DeleteDeletedPorts($;$) {
	#
	# For each deleted port, delete the element which corresponds to that port
	#

	my $PortsRef	= shift;
	my %Ports		= %{$PortsRef};
	my $dbh			= shift;

	my $element = FreshPorts::Element->new($dbh);

	#
	# refresh each and every port we are told about
	#
	print "# # # # Deleting deleted ports # # # #\n\n";
	while (my ($portname, $port) = each %Ports) {
		if (defined($port->{deleted})) {
			print "deleting : port = $portname, port_id = '$port->{id}', ' element_id = $port->{element_id}'\n";

			$element->{id} = $port->{element_id};
			if (defined($element->FetchByID())) {
				$element->{status} = $FreshPorts::Element::Deleted;
				$element->save();
			}
		}
	}
}

sub CreateDailySummary($;$) {
#
# create the daily summary for the supplied date.
# CommitDateStart should be the commit date of the message
# which prompted the database update in the first place.
#

	my $CommitDateStart = shift;
	my $dbh             = shift;

	my @myrow;

	my $sql =	"select ports.id, element.name, ports.version " .
				"from ports, commit_log, commit_log_port, element ".
				"where ports.id                      = commit_log_port.port_id ".
				"  and commit_log_port.commit_log_id = commit_log.id ".
				"  and element.id                    = ports.element_id ".
				"  and commit_log.commit_date between '$CommitDateStart'::timestamp and '$CommitDateStart'::timestamp + INTERVAL '1 DAY' " .
				"order by commit_log.commit_date desc";

	print "\$sql='$sql'<BR>\n";

	my $sth = $dbh->prepare($sql);

	$sth->execute ||
		die "Could not execute SQL statement\n--$sql--\n... maybe invalid?";


	print "$sql\n";

#	if ($sth->num_rows) {
#		print "$sth->num_rows rows in that result\n";
#	}

#	print "press enter to continue"; <STDIN>;

	umask(02);
	# create the output file name gradually, ensuring the directories exist

	my $OutputFile = $FreshPorts::Config::DailySummaryDir . "/" . substr($CommitDateStart, 0, 4);

	if (-d $OutputFile) {
		print "'$OutputFile' exists\n";
	} else {
		print "'$OutputFile' does not exist\n";
		print "   trying to mkdir '$OutputFile'\n";
		if (mkdir $OutputFile, 0775) {
		} else {
			print "Could not create directory $OutputFile\n";
			return 1;
		}
	}

	$OutputFile .= "/" . substr($CommitDateStart, 5, 2);
	if (-d $OutputFile) {
		print "'$OutputFile' exists\n";
	} else {
		print "   trying to mkdir '$OutputFile'\n";
		if (mkdir $OutputFile, 0775) {
		} else {
		print "Could not create directory $OutputFile\n";
			return 2;
		}
	}

	$OutputFile .= "/" .  substr($CommitDateStart, 8, 2) . ".inc";
	print "   trying to open '$OutputFile'\n";
	open FILE, ">$OutputFile"  || die "Could not open $OutputFile";
   
	if (*FILE) {
		print "that file was opened.  now writing output\n";
		my $count =0;
		while (@myrow = $sth->fetchrow_array) {
			print FILE '<a href="port-description.php3?port=';
			print FILE $myrow[0] . '"><font size="-1">' . $myrow[1] . " ";
			print FILE $myrow[2] . "</font></a><br>\n";     
			$count++;
		}

		print "i wrote out $count records\n";

		close FILE;
	} else {
		print "could not open $OutputFile\n";
		return 3;
	}
   
	return 0;
}




FreshPorts::Utilities::InitSyslog();

1;
