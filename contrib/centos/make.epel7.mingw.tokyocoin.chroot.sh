#!/bin/bash

set -e

mydir="$(dirname "$(readlink -f "${0}")")"
chrootconf="${mydir}/epel-7-x86_64-trashcoin.cfg"

while getopts ':c:d:' opt
do
	case ${opt} in
		c ) chrootconf="${OPTARG}" ;;
		d ) mydir="$(readlink -f "${OPTARG}")" ;;
		\:) echo "Option ${OPTARG} requires an argument">&2 ;;
		* ) echo "${OPTARG}: unknown option">&2 ;; # Default.
	esac
done
shift $(($OPTIND - 1))

topdir="$(git -C "${mydir}" rev-parse --show-toplevel)"
project=tokyocoin
distfile=${project}.tar
distdir=/srv/distr/tmp
makefile=makefile.linux-mingw
deps+=" mingw32-boost-static"
deps+=" mingw32-libdb-static"
deps+=" mingw32-openssl-static"
deps+=" mingw32-winpthreads-static"
deps+=" mingw32-zlib-static"
#deps+=" mingw32-qt"
deps+=" mingw32-qt5-qmake"
deps+=" mingw32-qt5-qtbase-static"
deps+=" mingw32-qt5-qtdeclarative-static"
mock="mock -r ${chrootconf}"
mockroot=$(${mock} --print-root-path)
qmake=mingw32-qmake-qt5

[ -r "${conf}" ] && . "${conf}"
cd "${topdir}"
gitbranch=$(git rev-parse --abbrev-ref HEAD)
archivedir="/tmp/${project}.${gitbranch}"
chrootarchivedir="$(basename "${archivedir}")"
chrootsrcdir="${chrootarchivedir}/src"
[ -d "${archivedir}" ] && find "${archivedir}" -delete
mkdir "${archivedir}"
git archive --format=tar ${gitbranch} | tar -xC "${archivedir}"
[ -f ${mockroot}/.initialized ] || ${mock} --init
[ -e ${mockroot}/${chrootarchivedir} ] || ${mock} --copyin "${archivedir}" /
${mock} --install ${deps}
echo ${mock}
${mock} --chroot "make -C ${chrootsrcdir} -f ${makefile} USE_UPNP=-; make -C ${chrootsrcdir} -f ${makefile} USE_UPNP=-"
${mock} --chroot "make -C ${chrootsrcdir} -f ${makefile} USE_UPNP=-; make -C ${chrootsrcdir} -f ${makefile} USE_UPNP=- STATIC=1"
#${mock} --chroot "cd ${chrootarchivedir}; ${qmake} BOOST_THREAD_LIB_SUFFIX=-mt LIBS+=-Wl,-Bstatic RELEASE=1 USE_UPNP=-; mingw32-make"
${mock} --chroot "cd ${chrootarchivedir}; ${qmake} BOOST_THREAD_LIB_SUFFIX=-mt LIBS+=-Wl,-Bstatic RELEASE=1 USE_UPNP=-; mingw32-make"
${mock} --chroot "cd ${chrootarchivedir}; find . -name *.exe -type f | tar -cf ${distfile} -T-"
${mock} --copyout ${distfile} ${distdir}
