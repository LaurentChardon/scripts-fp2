# $Id: utilities.pm,v 1.1 2001-11-09 20:53:12 dan Exp $
#

package FreshPorts::Utilities;


# =================================

sub ReadFile($) {

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


1;
