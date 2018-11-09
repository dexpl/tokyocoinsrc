#!/bin/bash

# Legacy:
#tc=$(rpm -E %_srcrpmdir)/tokyocoin-1.1-4.fc29.src.rpm
#basedir=${HOME}/projects/tc.mingw
#mock="mock --config-opts=basedir=${basedir} -r ${chrootconf}"
#[ -d "${basedir}" ] || mkdir -p "${basedir}"
#${mock} --chroot "chmod +x ${srcbasedir}/leveldb/build_detect_platform"
#${mock} --chroot "rpm -ihv /$(basename ${tc})"
#${mock} --chroot 'rpmbuild -bp --nodeps $(rpm -E %_specdir/tokyocoin.spec)'
#srcbasedir=$(${mock} --chroot 'rpm -E %_builddir')/tokyocoinsrc-1.1/src/
#[ -f "${makefile}" ] && ${mock} --copyin "${makefile}" ${srcbasedir}

set -e

mydir="$(dirname "$(readlink -f "${0}")")"
topdir="$(git -C "${mydir}" rev-parse --show-toplevel)"
chrootconf="${mydir}/epel-7-x86_64-trashcoin.cfg"
makefile=makefile.linux-mingw
deps+=" mingw32-boost-static"
deps+=" mingw32-libdb-static"
deps+=" mingw32-openssl-static"
deps+=" mingw32-winpthreads-static"
deps+=" mingw32-zlib-static"
mock="mock -r ${chrootconf}"
mockroot=$(${mock} --print-root-path)

cd "${topdir}"
gitbranch=$(git rev-parse --abbrev-ref HEAD)
archivedir="/tmp/tokyocoin.${gitbranch}"
chrootarchivedir="$(basename "${archivedir}")"
chrootsrcdir="${chrootarchivedir}/src"
[ -d "${archivedir}" ] && find "${archivedir}" -delete
mkdir "${archivedir}"
git archive --format=tar ${gitbranch} | tar -xC "${archivedir}"
[ -f ${mockroot}/.initialized ] || ${mock} --init
[ -e ${mockroot}/${chrootarchivedir} ] && ${mock} --chroot "find ${chrootarchivedir} -delete"
${mock} --copyin "${archivedir}" /
${mock} --install ${deps}
echo ${mock}
${mock} --chroot "cd ${chrootsrcdir}; make -f ${makefile} USE_UPNP=- STATIC=1"
