# $Id: utilities.pm,v 1.2 2001-11-20 17:03:44 dan Exp $
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


1;
