#
# $Id: config.pm,v 1.7 2001-12-22 04:30:38 dan Exp $
#
# Copyright (c) 2001 DVL Software
#

package FreshPorts::Config;

$FreshPorts::Config::scriptpath			= "/home/lists-test/scripts";

$FreshPorts::Config::dbname				= 'FreshPorts2TestLists';
$FreshPorts::Config::user				= 'dan';
$FreshPorts::Config::password			= '';

$FreshPorts::Config::path_to_tree		= '/home/lists-test';							# where on disk is the ports tree?
$FreshPorts::Config::path_to_ports		= $FreshPorts::Config::path_to_tree . '/ports';	# path to ports tree
$FreshPorts::Config::ports_prefix		= 'ports';										# where in the cvs tree are ports?

$FreshPorts::Config::DailySummaryDir	= "/home/lists-test/src/www/archives"; # no trailing /

1;
