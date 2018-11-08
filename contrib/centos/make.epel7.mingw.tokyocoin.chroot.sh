#!/bin/bash

tc=$(rpm -E %_srcrpmdir)/tokyocoin-1.1-4.fc29.src.rpm
basedir=${HOME}/projects/tc.mingw/static
makefile=${HOME}/projects/tokyocoinsrc/src/makefile.linux-mingw
deps="$(rpm -E %_rpmdir)/noarch/mingw32-boost-1.60.0-1.el7.noarch.rpm"
deps+=" $(rpm -E %_rpmdir)/noarch/mingw32-boost-static-1.60.0-1.el7.noarch.rpm"
deps+=" $(rpm -E %_rpmdir)/noarch/mingw32-libdb-5.3.28-3.el7.noarch.rpm"
deps+=" $(rpm -E %_rpmdir)/noarch/mingw32-libdb-static-5.3.28-3.el7.noarch.rpm"
deps+=" mingw32-openssl-static"
deps+=" mingw32-winpthreads-static"
deps+=" mingw32-zlib-static"
mock="mock --config-opts=basedir=${basedir} -r epel-7-x86_64"

set -e
[ -d "${basedir}" ] || mkdir -p "${basedir}"
[ -f $(${mock} --print-root-path)/.initialized ] || ${mock} --init
${mock} --install ${deps}
${mock} --copyin ${tc} /
${mock} --chroot "rpm -ihv /$(basename ${tc})"
${mock} --chroot 'rpmbuild -bp --nodeps $(rpm -E %_specdir/tokyocoin.spec)'
srcbasedir=$(${mock} --chroot 'rpm -E %_builddir')/tokyocoinsrc-1.1/src/
${mock} --chroot "chmod +x ${srcbasedir}/leveldb/build_detect_platform"
[ -f "${makefile}" ] && ${mock} --copyin "${makefile}" ${srcbasedir}
echo ${mock}
