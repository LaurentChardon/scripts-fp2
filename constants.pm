# $Id: constants.pm,v 1.1 2001-11-09 16:30:15 dan Exp $
#

package FreshPorts::Constants;

use strict;

#
# Database sequence IDs
#

$FreshPorts::Constants::commit_log_seq		= "commit_log_id_seq";
$FreshPorts::Constants::ports_id_seq		= "ports_id_seq";
$FreshPorts::Constants::category_id_seq		= "categories_id_seq";

$FreshPorts::Constants::ADD					= 'Add';
$FreshPorts::Constants::MODIFY				= 'Modify';
$FreshPorts::Constants::REMOVE				= 'Remove';

$FreshPorts::Constants::FreeBSD				= 'FreeBSD';


$FreshPorts::Constants::FILE_MAKEFILE		= "Makefile";
$FreshPorts::Constants::FILE_DESCRIPTION	= "pkg-descr";
$FreshPorts::Constants::FILE_COMMENT		= "pkg-comment";
$FreshPorts::Constants::FILE_MAKEFILECOMMON	= "Makefile.common";
$FreshPorts::Constants::FILE_MAKEFILEMAN	= "files/Makefile.man";

%FreshPorts::Constants::FilesWhichPromptRefresh = (
	$FreshPorts::Constants::FILE_MAKEFILE			=> 1,
	$FreshPorts::Constants::FILE_DESCRIPTION		=> 2,
	$FreshPorts::Constants::FILE_COMMENT			=> 4,
	$FreshPorts::Constants::FILE_MAKEFILECOMMON		=> 8,
	$FreshPorts::Constants::FILE_MAKEFILEMAN		=> 16,
);

#
# These are the directories/entries
# which FreshPorts does not track
#
$FreshPorts::Constants::IgnoredItems = "Attic|distfiles|Mk|Tools|Templates|Makefile|pkg";

1;
