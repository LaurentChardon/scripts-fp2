# $Id: config.pm,v 1.5 2001-12-05 01:50:35 dan Exp $
#

package FreshPorts::Config;

$FreshPorts::Config::scriptpath			= "/home/dan/src/dev";

$FreshPorts::Config::dbname				= 'FreshPorts2Test';
$FreshPorts::Config::user				= 'dan';
$FreshPorts::Config::password			= '';

$FreshPorts::Config::path_to_ports		= '/home/lists-test/ports';	# path to ports tree
$FreshPorts::Config::ports_prefix		= 'ports';			# where in the cvs tree are ports?

$FreshPorts::Config::DailySummaryDir	= "/usr/websites/fp2.freshports.org/www/archives"; # no trailing /

1;
