# $Id: utilities.pm,v 1.7 2001-12-22 04:30:44 dan Exp $
#
#
# Copyright (c) 2001 DVL Software
#
package FreshPorts::Utilities;

require Sys::Syslog;

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

sub FetchFile($;$;$) {
	#
	# fetch a file
	# into the given path
	# returns 1 if fetched.
	# zero otherwise.
	#
	my $DESTDIR	= shift;
	my $SRCDIR	= shift;
	my $FILE	= shift;

	my $result  = 0;

	`sh $FreshPorts::Config::scriptpath/fetch-cvs-file.sh $DESTDIR $SRCDIR $FILE`;

	my $FetchAttempts = 5;

	while ($FetchAttempts) {
		`sh $FreshPorts::Config::scriptpath/fetch-cvs-file.sh $DESTDIR $SRCDIR $FILE`;

		if (($? >> 8)) {
			#
			# This might be a nice place to retry a fetch, or send an email
			#
			print "that fetch failed.  What do to?\n";

			# and we're outta here
			# fetch failed
			# sleep, then try again

			Sys::Syslog::syslog('warning', "sleeping after fetch failed for ($DESTDIR $SRCDIR $FILE)");
			print "fetch failed, sleeping...\n";
			sleep 10;
			$FetchAttempts--;

		} else {
			# fetch worked
			last;
		}
    }

	#
	# if we succeeded in our fetch..
	if ($FetchAttempts) {
		$result = 1;
	}
}

#
# make sure we init only once...
#
$FreshPorts::Utilities::syslog_init = 0;

sub InitSyslog() {
	if (!$FreshPorts::Utilities::syslog_init) {
		Sys::Syslog::setlogsock('unix');
		Sys::Syslog::openlog('FreshPorts', 'cons, pid', 'user');
		$FreshPorts::Utilities::syslog_init = 1;
	}
}

1;
