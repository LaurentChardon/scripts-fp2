#!/usr/bin/perl
#
# $Id: commit_log_ports.pm,v 1.1 2001-11-11 02:10:42 dan Exp $
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

	#
	# if id is supplied, we are updating. otherwise we are inserting.
	# if parent_id is supplied, it will be used.  Otherwise, it will
	# be derived from pathname.  if parent_id is set, it is assumed
	# that pathname is correct.
	# if name is not supplied, it will be derived from pathname.
	# 

	my $dbh = $this->{dbh}; # just a short cut...
	my $sth;
	my $sql;
	my @row;

	# get the name if not supplied
	if (!$this->{commit_log_id} || !$this->{port_id}) {
		Sys::Syslog::syslog('warning', "FreshPorts::CommitLogPort neither commit_log_id nor port_id supplied");
		die "FreshPorts::CommitLogPort neither commit_log_id nor port_id supplied";
	}

	# we are inserting
	$sql = "insert into commit_log_port (commit_log_id, port_id) values \
				($this->{commit_log_id}, $this->{port_id})";

	print "sql is $sql\n";

	$sth = $this->{dbh}->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr);
		die "Could not execute SQL $sql ... maybe invalid? ". $dbh->errstr;
	}
}

1;