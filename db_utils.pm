#
# $Id: db_utils.pm,v 1.3 2001-12-22 04:30:39 dan Exp $
#
# Copyright (c) 2001 DVL Software
#
package FreshPorts::Database;

sub GetNextValue($;$) {
	my $sequence = shift;
	my $dbh      = shift;
	my $sth;
	my $sql;
	my @row;

	$sql = "select nextval('$sequence')";

	if (!$debug) {
	$sth = $dbh->prepare($sql);
	if (!$sth->execute) {
		Sys::Syslog::syslog('warning', "Could not execute SQL $sql");
		die "Could not execute SQL $sql ... maybe invalid?";
		}

	@row = $sth->fetchrow_array();

	$sth->finish();
	}

	return $row[0];
}

1;
