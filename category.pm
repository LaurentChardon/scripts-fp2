#!/usr/bin/perl
#
# $Id: category.pm,v 1.1.1.1 2001-11-05 05:16:32 dan Exp $
#

package FreshPorts::Category;
require Exporter;
require	config;

use strict;
use config;
use db_utils;

# =================================

sub _initialize {
}

# =================================

sub new {
	my $this		= {};
	my $class		= shift;

	$this->{dbh}	= shift;

	bless $this;
	$this->_initialize();
	return $this;
}

sub create {
	my $this				= shift;

	$this->{name}			= shift;
	$this->{is_primary}		= shift;

	print "* * * name = $this->{name}\n";

	# create a new entry in the category table
	# we only create primary categories here.

	# enhancement:
	# note that ports/<category>/pkg/COMMENT contains the category description.
	# one day, we might want to start using that.
	#
	# Dan Langille 2001.03.26
	#

#	my $element_id = "$FreshPorts::Config::prefix_ports" . "/$this->{name}";

	$this->{description} = _description_fetch("$this->{name}");

	$this->{id} = FreshPorts::Database::GetNextValue($FreshPorts::Config::category_id_seq, $this->{dbh});

	my ($system, $name, $description);

	my $system = 

	my $sql = "insert into categories (id, is_primary, element_id, name, description) values \
				($this->{id}, $this->{is_primary}, '$this->{element_id}', $this->{dbh}->quote($this->{name}), $this->{dbh}->quote($this->{description}))";

	print "\n",$sql, "\n";

	my $sth = $this->{dbh}->prepare($sql);

	$sth->execute ||
			die "Could not execute insert categories SQL statement ... maybe invalid?";

	$this->{id} = $sth->{'mysql_insertid'};

	return $this;
}

# =================================

sub _description_fetch {
	my $category	= shift;

	my $DESTDIR		= "/usr/ports/$category/pkg";
	my $SRCDIR		= "ports/$category/pkg";
	my $FILE		= "COMMENT";

#	print "FreshPorts::Config::scriptpath=$FreshPorts::Config::scriptpath\n";
	print "DESTDIR=$DESTDIR\n";
	print "SRCDIR =$SRCDIR\n";
	print "FILE   =$FILE\n";

	`sh $FreshPorts::Config::scriptpath/fetch-cvs-file.sh $DESTDIR $SRCDIR $FILE`;

	my $description = _ReadFile("$DESTDIR/$FILE");

	return $description;
}

# =================================

sub _ReadFile($) {

   my $file = shift;
   my $content;

   open F,$file;

   $content = "";
   while(<F>){
      $content .= $_;
   }

   close F;

   return $content;
}
