#!/usr/bin/perl
#
# $Id: commit_log_port_elements.pm,v 1.1 2001-12-22 04:52:42 dan Exp $
#
# Copyright (c) 2001 DVL Software
#

package FreshPorts::CommitLogPortElements;

use strict;


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

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	# we are inserting
	$sql = "insert into commit_log_port_elements (commit_log_id, port_id, commit_log_element_id) values \
				($this->{commit_log_id}, $this->{port_id}, $this->{commit_log_element_id})";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr);
		die "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr;
	}
}

1;