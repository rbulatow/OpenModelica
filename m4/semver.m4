AC_SUBST(SOURCE_REVISION)

AC_MSG_CHECKING([for revision])
SOURCE_REVISION=`$ac_pwd/common/semver.sh $PACKAGE_NAME`
AC_MSG_RESULT([$SOURCE_REVISION])

