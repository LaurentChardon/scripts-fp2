#!/usr/bin/perl
#
# $Id: commit_log_element.pm,v 1.2 2001-12-22 04:30:38 dan Exp $
#
# Copyright (c) 2001 DVL Software
#


package FreshPorts::CommitLogElement;

use strict;

require constants;


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
	#
	# This function works only for inserts, not for updates
	#
	my $this = shift;

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

print "$FreshPorts::Constants::commit_log_seq\n";
print "$FreshPorts::Constants::ports_seq\n";
print "$FreshPorts::Constants::commit_log_elements_seq\n";


	if (!$this->{id}) {
		print "getting id from '" . "$FreshPorts::Constants::commit_log_elements_seq\n";
		$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Constants::commit_log_elements_seq, $dbh);
		# we are inserting
		$sql = "insert into commit_log_elements(id, commit_log_id, element_id, revision_name, change_type) values \
					($this->{id}, $this->{commit_log_id}, $this->{element_id}, " . $dbh->quote($this->{revision_name}) . ", " 
					 . $dbh->quote($this->{change_type}) . ")";

		print "sql is $sql\n";

		$sth = $this->{dbh}->prepare($sql);
		if (!$sth->execute) {
			Sys::Syslog::syslog('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr);
			die "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr;
		}
	} else {
		Sys::Syslog::syslog('warning', "FreshPorts::CommitLogElements::save works for updates only");
		die "FreshPorts::CommitLogElements::save works for updates only";
	}
}

1;