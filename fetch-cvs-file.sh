#!/bin/sh

if  [ $# -ne 3 ];
   then echo $0 : usage $0 DESTDIR SRCDIR FILE 1>&2
   exit 1
else
   DESTDIR=$1
   SRCDIR=$2
   FILE=$3

   mkdir -p ${DESTDIR}
   if [ $? -ne 0 ]
   then
      exit 3
   fi

# we don't need this any more.
# But it did help to find the pre-everything bugs
# see also 3BB8479C.16045.406FAE31@localhost
# in the freebsd mailing list archives.
#
#      mkdir /usr/ports/${CATEG}/${PORT}/pkg
#      if [ $? -ne 0 ]
#      then
#         exit 2
#      fi

 FETCHFILE=$DESTDIR/$FILE

 echo about to fetch http://www.freebsd.org/cgi/cvsweb.cgi/~checkout~/$SRCDIR/$FILE?rev=HEAD
 echo fetching into $FETCHFILE

# try to get around any possible caching by using a timestamp as a parameter
#
time=`/bin/date +"%s"`

/usr/local/bin/lynx -source -dump http://www.freebsd.org/cgi/cvsweb.cgi/$SRCDIR/$FILE?rev=HEAD\&abcd=$time > $FETCHFILE
 if [ $? -ne 0 ]
 then
    exit 6
 fi

 exit 0
fi

