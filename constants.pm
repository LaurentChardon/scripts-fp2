# $Id: constants.pm,v 1.4 2001-11-23 20:02:30 dan Exp $
#

package FreshPorts::Constants;

use strict;

#
# Database sequence IDs
#

$FreshPorts::Constants::ports_seq				= "ports_id_seq";
$FreshPorts::Constants::commit_log_elements_seq	= "commit_log_elements_id_seq";
$FreshPorts::Constants::commit_log_seq			= "commit_log_id_seq";
$FreshPorts::Constants::system_branch_seq		= "system_branch_id_seq";

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
# These are the entries within /usr/ports/ which we ignore
# and /usr/ports/<category> which FreshPorts does not track
#
%FreshPorts::Constants::IgnoredItems = (
	"Attic"		=> 1,
	"distfiles"	=> 2,
	"Mk"		=> 3,
	"Tools"		=> 4,
	"Templates"	=> 5,
	"Makefile"	=> 6,
	"pkg"		=> 7,
);

1;
