#!/usr/bin/perl

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
