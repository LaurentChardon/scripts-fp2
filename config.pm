# $Id: config.pm,v 1.6 2001-12-05 23:49:43 dan Exp $
#

package FreshPorts::Config;

$FreshPorts::Config::scriptpath			= "/home/dan/src/dev";

$FreshPorts::Config::dbname				= 'FreshPorts2Test';
$FreshPorts::Config::user				= 'dan';
$FreshPorts::Config::password			= '';

$FreshPorts::Config::path_to_tree		= '/home/lists-test';							# where on disk is the ports tree?
$FreshPorts::Config::path_to_ports		= $FreshPorts::Config::path_to_tree . '/ports';	# path to ports tree
$FreshPorts::Config::ports_prefix		= 'ports';										# where in the cvs tree are ports?

$FreshPorts::Config::DailySummaryDir	= "/usr/websites/fp2.freshports.org/www/archives"; # no trailing /

1;
