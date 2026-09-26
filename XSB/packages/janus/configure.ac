## File:      configure.ac

dnl  This script is run by the main configure script in XSB/build
dnl  If this script is changed, run
dnl	autoconf
dnl  here.


AC_PREREQ([2.71])
AC_INIT([janus_xsb],[1.0])

AC_CONFIG_MACRO_DIR([./m4])

AC_ARG_WITH(preferred-python,
[  --with-preferred-python=X      indicate the preferred version of python to build with])

source ./configvars.sh

if test -n "${with_preferred_python}" ; then
    # used in the macro called below;
    # if not set, the below macro choses the latest installed
    ac_preferred_python=$with_preferred_python
fi

AX_PYTHON

PYTHON_LIBDIR=`dirname "$PYTHON_LIB"`
PYTHON_LIB_NAME=`basename "$PYTHON_LIB"`
PYTHON_CONFLIBDIR=`dirname "$PYTHON_CONFLIB"`
PYTHON_CONFLIB_NAME=`basename "$PYTHON_CONFLIB"`

echo
echo The Python configuration variables have been set as follows:
echo PYTHON_BIN=$PYTHON_BIN
echo PYTHON_LIB=$PYTHON_LIB
echo PYTHON_LIB_NAME=$PYTHON_LIB_NAME
echo PYTHON_LIBDIR=$PYTHON_LIBDIR
echo PYTHON_EXTRA_LIB=$PYTHON_EXTRA_LIB
echo PYTHON_CONFLIB=$PYTHON_CONFLIB
echo PYTHON_CONFLIB_NAME=$PYTHON_CONFLIB_NAME
echo PYTHON_CONFLIBDIR=$PYTHON_CONFLIBDIR
echo PYTHON_INCLUDE_DIR=$PYTHON_INCLUDE_DIR
echo XSBCONFIG_LIBDIR=$XSBCONFIG_LIBDIR
echo XSBCONFIG_EMUDIR=$XSBCONFIG_EMUDIR
echo XSBCONFIG_BINDIR=$XSBCONFIG_BINDIR
echo XSB_ROOTDIR=$XSB_ROOTDIR
echo

rm -f *.xwam *.so *.dylib

support1=no
message1_hint0=
message1_hint1=
message1_hint2=
message1_hint3=
if test -z "$PYTHON_BIN" ; then
   message1="  Janus_xsb:       Python not found"
   message1_hint0="  Janus_xsb hint:  Use --with-preferred-python=python3.X or activate the intended virtualenv/conda env before running ./configure."
elif test -z "$PYTHON_LIB" ; then
   message1="  Janus_xsb:       Python shared library (libpython3.so) not found"
   message1_hint0="  Janus_xsb hint:  Verify this interpreter has shared-library support enabled."
elif test -z "$PYTHON_INCLUDE_DIR" ; then
   message1="  Janus_xsb:       Python include directory not found"
   message1_hint0="  Janus_xsb hint:  Install Python development headers for the selected interpreter."
elif test -z "$PYTHON_CONFLIB" ; then
   message1="  Janus_xsb:       Could not locate a loadable Python runtime library for this interpreter"
   message1_hint0="  Janus_xsb hint:  Check these values:"
   message1_hint1="      $PYTHON_BIN -c \"import sys,sysconfig; print(sys.executable); print('INSTSONAME=',sysconfig.get_config_var('INSTSONAME')); print('LDLIBRARY=',sysconfig.get_config_var('LDLIBRARY')); print('LIBDIR=',sysconfig.get_config_var('LIBDIR')); print('PYTHONFRAMEWORKPREFIX=',sysconfig.get_config_var('PYTHONFRAMEWORKPREFIX'))\""
   message1_hint2="  Janus_xsb hint:  Homebrew users: ensure your env is created from a brewed Python (for example: brew install python@3.12)."
   message1_hint3="  Janus_xsb hint:  MacPorts users: install a matching python3X package and recreate your env from that interpreter."
elif test "$pip_not_installed" = "1" ; then
   message1="  Janus_xsb:       pip is not installed"
   message1_hint0="  Janus_xsb hint:  Run '$PYTHON_BIN -m ensurepip --upgrade' or install pip for this interpreter."
else
   support1=yes
fi

support0=no
CFLAGS_backup="${CFLAGS}"
if test -n "$PYTHON_INCLUDE_DIR" ; then
   CFLAGS="-I$PYTHON_INCLUDE_DIR ${CFLAGS}"
   CPPFLAGS="-I$PYTHON_INCLUDE_DIR ${CPPFLAGS}"
fi
AC_CHECK_HEADERS([Python.h] , [support0=yes], [message0="       Janus_xsb: Python.h not found"], [])
CFLAGS="${CFLAGS_backup}"

# these are likely useless
ldflags="-l$PYTHON_LIB_NAME -L$PYTHON_LIBDIR"
runflags="-Wl,-rpath=$PYTHON_LIBDIR"
if test -n "$PYTHON_INCLUDE_DIR" -a -n "$XSBCONFIG_EMUDIR" ; then
   ccflags="-I$XSBCONFIG_EMUDIR -I$PYTHON_INCLUDE_DIR $ldflags $runflags"
fi

AC_SUBST(ccflags)
AC_SUBST(ldflags)
AC_SUBST(runflags)

AC_SUBST(PYTHON_INCLUDE_DIR)
AC_SUBST(PYTHON_LIB)
AC_SUBST(PYTHON_LIB_NAME)
AC_SUBST(PYTHON_LIBDIR)
AC_SUBST(PYTHON_EXTRA_LIB)
AC_SUBST(PYTHON_CONFLIB)
AC_SUBST(PYTHON_CONFLIB_NAME)
AC_SUBST(PYTHON_CONFLIBDIR)
AC_SUBST(PYTHON_BIN)
AC_SUBST(XSBCONFIG_LIBDIR)
AC_SUBST(XSBCONFIG_EMUDIR)
AC_SUBST(XSBCONFIG_BINDIR)
AC_SUBST(XSB_ROOTDIR)

# these are useless
#LDFLAGS="$ldflags"
#echo ccflags=$ccflags
#echo ldflags=$LDFLAGS
#
#support2=no
#AC_SEARCH_LIBS([Py_Initialize], [], [support2=yes], [message2="       JANUS_XSB: Py_Initialize not found"], [])

AC_CONFIG_FILES([ janus_connect_defs.h:janus_connect_defs.in ])
AC_OUTPUT

if test "$support0" = "yes" -a "$support1" = "yes" ; then
   support=yes
else
   support=no
fi

(
echo "  JANUS_XSB support (XSB to Python connector):        $support"
if test "$support" = "yes"; then
   cat <<EOT
  Python:             $PYTHON_BIN
  Janus_Xsb C flags:      $ccflags
  Janus_Xsb loader flags: $ldflags

EOT
else
    test "$support0" = no && echo "$message0" 
    test "$support1" = no && echo "$message1"
    test "$support1" = no -a -n "$message1_hint0" && echo "$message1_hint0"
    test "$support1" = no -a -n "$message1_hint1" && echo "$message1_hint1"
    test "$support1" = no -a -n "$message1_hint2" && echo "$message1_hint2"
    test "$support1" = no -a -n "$message1_hint3" && echo "$message1_hint3"
fi
) | tee Installation_summary

# set up janus_xsb Python package
setupfile_name=".tmp_janussetup.py"
setupfile_path="'janus-py/$setupfile_name'"
py_includedir="'$PYTHON_INCLUDE_DIR'"


if test -z "$PYTHON_INCLUDE_DIR" -o -z "$PYTHON_BIN" -o "$pip_not_installed" = "1" -o -z "$PYTHON_LIB" -o -z "$PYTHON_CONFLIB" ; then
    echo 'echo "+++ Python does not seem to be configured properly."' > make_janus_pkg.sh
    echo 'echo "+++ Janus_XSB could not determine a usable Python runtime library or packaging setup."' >> make_janus_pkg.sh
    echo 'echo "+++ XSB-Python bridge will not be supported in this installation."' >> make_janus_pkg.sh
    echo 'echo ""' >> make_janus_pkg.sh
else
    AC_CONFIG_FILES([make_janus_pkg.sh:make_janus``_pkg.sh.in])
AC_OUTPUT
fi

AC_SUBST(support)
AC_CONFIG_FILES([janus_info.P:janus_info.in])
AC_OUTPUT

chmod 700 make_janus_pkg.sh
