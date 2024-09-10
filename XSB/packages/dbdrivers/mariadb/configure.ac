## File:      configure.in
## Author(s): kifer
## Contact:   xsb-contact@cs.sunysb.edu
## 
## Copyright (C) The Research Foundation of SUNY, 2024 - 2025
## 
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
##

dnl  Autoconf script for XSB
dnl  To rebuild the `configure' script from this, execute the command
dnl	autoconf
dnl  in the directory containing this script.
dnl
dnl

AC_PREREQ([2.71])dnl

AC_INIT
AC_CONFIG_SRCDIR([mariadb_driver_config.P])

SHELL=/bin/sh

AC_ARG_WITH(mariadb-libdir,
[  --with-mariadb-libdir=DIR	   the directory where the MariaDB library lives])
AC_ARG_WITH(mariadb-incdir,
[  --with-mariadb-incdir=DIR	   the directory of MariaDB include files])


AC_ARG_WITH(mysql-libdir,
[  --with-mysql-libdir=DIR	   ignored])
AC_ARG_WITH(mysql-incdir,
[  --with-mysql-incdir=DIR	   ignored])
AC_ARG_WITH(odbc-libdir,
[  --with-odbc-libdir=DIR	   ignored])
AC_ARG_WITH(odbc-incdir,
[  --with-odbc-incdir=DIR	   ignored])
AC_ARG_WITH(mysqlembedded-libdir,
[  --with-mysqlembedded-libdir=DIR	   ignored])
AC_ARG_WITH(mysqlembedded-incdir,
[  --with-mysqlembedded-incdir=DIR	   ignored])

build_dir="`pwd`"
# strip the last three directories and possibly trailing slashes
topdir=`echo "${build_dir}" | sed 's,/[[^/]][[^/]]*/*/[[^/]][[^/]]*/*/[[^/]][[^/]]*/*$,,'`


# Tell where the autoconf scripts are
AC_CONFIG_AUX_DIR(../../../build)

dnl Check configuration for a Unix variant
if test -z "$with_config"; then
echo '
- You did not tell me what kind of host system you want to configure.
- I will attempt to guess the kind of system this is.
' 1>&6
    AC_CANONICAL_HOST
    canonical=$host
    configuration=$host_alias
fi


# make sure new files are readable 
umask 022

/bin/rm -f config.cache

with_mariadb=
mariadb_error=

if test -z "$with_mariadb_libdir" ; then
   if test -d `mariadb_config --variable=pkglibdir 2> /dev/null` ; then
      libdir="`mariadb_config --variable=pkglibdir 2> /dev/null`"
   elif test -d /usr/lib/mariadb ; then
      libdir="/usr/lib/mariadb"
   elif test -d /usr/local/mariadb/lib ; then
      libdir="/usr/local/mariadb/lib"
   else
      echo "***Configuring MariaDB failed: cannot find installation; please use the option --with-mariadb-libdir"
      exit 1
   fi
else
   libdir=$with_mariadb_libdir
fi

if test -z "$with_mariadb_incdir" ; then
   if test -d `mariadb_config --variable=pkgincludedir 2> /dev/null` ; then
       incdir="`mariadb_config --variable=pkgincludedir 2> /dev/null`"
   elif test -d /usr/include/mariadb ; then
       incdir="/usr/include/mariadb"
   elif test -d /usr/local/mariadb/include ; then
       incdir="/usr/local/mariadb/include"
   else
      echo "***Configuring MariaDB failed: cannot find installation; please use the option --with-mariadb-incdir"
      exit 1
   fi
else
   incdir=$with_mariadb_incdir
fi

# check if libmariadbclient.so can be found
# If the MariaDB library is missing, set mariadb_error
# If libmariadbclient.so is not in a standard place, we must use --with-mariadb-libdir
if test -n "$libdir" ; then
   LDFLAGS="-L${libdir} ${LDFLAGS}"
fi

# Here we provide additional directories to check headers in
# AC_CHECK_HEADERS uses CPPFLAGS to find the include path.
#
# If any of the headers is not in a standard place, use --with-mariadb-incdir
if test -n "${incdir}"; then
   CPPFLAGS=" -I${incdir} ${CPPFLAGS}"
   CFLAGS="-I${incdir} ${CPFLAGS}"
fi

echo $incdir
echo $libdir

AC_CHECK_LIB(mariadbclient, main, , mariadb_error=yes)
AC_CHECK_HEADERS(mysql.h , with_mariadb=yes, mariadb_error=yes)

if test "$mariadb_error" = "yes"; then
echo ""
AC_MSG_WARN([ ****Your system is missing mysql.h or mysql_com.h, which are required for MariaDB support
****MariaDB driver will be disabled])
echo ""

support=no
else
support=yes
fi

CFLAGS="`mariadb_config --cflags 2> /dev/null`"
LDFLAGS="`mariadb_config --libs 2> /dev/null`"

AC_SUBST(support)
AC_SUBST(libdir)
AC_SUBST(CFLAGS)
AC_SUBST(LDFLAGS)


(
echo "  MariaDB support:                                  $support"
echo "  MariaDB library directory:                        $libdir"
echo "  MariaDB header directory:                         $incdir"
echo "  MariaDB C Flags:                                  $CFLAGS"
echo "  MariaDB Loader Flags:                             $LDFLAGS"
echo ""
) | tee Installation_summary

AC_CONFIG_FILES([mariadb_init.P:mariadb_init.in])
AC_OUTPUT
