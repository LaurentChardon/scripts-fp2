#!/usr/bin/perl
#
# $Id: commit_log_ports.pm,v 1.2 2001-11-11 08:35:54 dan Exp $
#

package FreshPorts::CommitLogPort;

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

#	# get the name if not supplied
#	if (!$this->{commit_log_id} || !$this->{port_id} || !$this->{commit_log_element_id}) {
#		Sys::Syslog::syslog('warning', "FreshPorts::CommitLogPort neither commit_log_id nor port_id supplied");
#		die "FreshPorts::CommitLogPort neither commit_log_id nor port_id supplied";
#	}

	# we are inserting
	$sql = "insert into commit_log_port (commit_log_id, port_id, commit_log_element_id) values \
				($this->{commit_log_id}, $this->{port_id}, $this->{commit_log_element_id})";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr);
		die "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr;
	}
}

1;