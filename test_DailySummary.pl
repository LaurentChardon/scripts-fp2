#!/usr/bin/perl
#
# $Id: test_DailySummary.pl,v 1.2 2001-12-22 04:30:41 dan Exp $
#
# Copyright (c) 1999-2001 DVL Software
#
use strict;
use DBI;
use element;

require config;
require database;
require verifyport;

my ($dbh, $element);

$dbh = FreshPorts::Database::GetDBHandle();

FreshPorts::VerifyPort::CreateDailySummary('2001-12-4', $dbh);

$dbh->disconnect();
