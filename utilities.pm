# $Id: utilities.pm,v 1.4 2001-11-23 04:51:39 dan Exp $
#

package FreshPorts::Utilities;


# =================================

sub ReadFile($) {

	my $file = shift;
	my $content;

	open F,$file;
	if (stat F) {
		$content = "";
		while(<F>){
			$content .= $_;
		}
	} else {
		Sys::Syslog::syslog('warning', "cannot open file $file");
		die "cannot open file $file";
	}

	close F;

	return $content;
}

#
# make sure we init only once...
#
$FreshPorts::Utilities::syslog_init = 0;

sub InitSyslog() {
	if ($FreshPorts::Utilities::syslog_init) {
		Sys::Syslog::setlogsock('unix');
		Sys::Syslog::openlog('FreshPorts', 'cons, pid', 'user');
		$FreshPorts::Utilities::syslog_init = 1;
	}
}

1;
