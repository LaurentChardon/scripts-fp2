# $Id: utilities.pm,v 1.3 2001-11-23 03:30:51 dan Exp $
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

sub InitSyslog() {
	Sys::Syslog::setlogsock('unix');
	Sys::Syslog::openlog('FreshPorts', 'cons, pid', 'user');
}

1;
