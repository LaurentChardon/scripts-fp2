#
# $Id: config.pm,v 1.1.1.1 2001-11-05 05:16:32 dan Exp $
#

package FreshPorts::Config;

$FreshPorts::Config::scriptpath		= "/home/dan/src/freshports2/scripts";

#
# Database sequence IDs
#

$FreshPorts::Config::commit_log_seq		= "commit_log_id_seq";
$FreshPorts::Config::ports_id_seq		= "ports_id_seq";
$FreshPorts::Config::category_id_seq	= "categories_id_seq";

$FreshPorts::Config::ADD         = 'Add';
$FreshPorts::Config::MODIFY      = 'Modify';
$FreshPorts::Config::REMOVE      = 'Remove';

$FreshPorts::Config::dbname		= 'FreshPorts2Test';
$FreshPorts::Config::user		= 'dan';
$FreshPorts::Config::password	= '';


$FreshPorts::Config::prefix_ports	= 'ports';

$FreshPorts::Config::FreeBSD		= 'FreeBSD';


1;
