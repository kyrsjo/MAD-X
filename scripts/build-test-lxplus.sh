#! /bin/bash
# run:
# bash scripts/build-test-lxplus.sh [noecho] [clone|update] [nobuild] [cleanall] [notest]

# env settings
export PATH="`pwd`:$PATH"

# error handler
check_error ()
{
	if [ "$?" != "0" ] ; then
		echo -e "\nERROR: $1"
		[ "$2" != "no-exit" ] && exit 1
	fi
}

# store lxplus node name in a file
uname -n > build-test-lxplus.run

# I/O redirection
rm -f build-test-lxplus.out
if [ "$1" = "noecho" ] ; then
	shift
	exec > build-test-lxplus.out 2>&1
	check_error "redirection with noecho failed"
else
	exec > >(tee build-test-lxplus.out) 2>&1
	check_error "redirection with tee failed"
fi

echo -e "\n===== Start of build and tests ====="
echo "Date  : `date`"
echo "UserId: `whoami`"
echo "System: `uname -m -n -r -s`"
echo "Script: $0 $@"
echo "Shell : `echo $SHELL`"
echo "User  : `echo $USER`"
echo "Home  : `echo $HOME`"
echo "Lang  : `echo $LANG`"
echo "PWD   : `echo $PWD`"

echo -e "\n===== Git clone/update ====="
if [ "$1" = "clone" ] ; then
	shift
	update="clone"
	rm -rf madx-nightly && \
  git clone https://github.com/MethodicalAcceleratorDesign/MAD-X.git madx-nightly && \
  cd madx-nightly
  check_error "git clone failed"
elif [ "$1" = "update" ] ; then
	shift # faster "clone", may need to fetch twice for old git version on lxplus.
	update="update"
	[ -d madx-nightly ] && cd madx-nightly && echo "moving down to madx-nightly"
  git fetch && \
  git fetch --tags && \
	git reset --hard origin/master && \
	git clean -xdf
  check_error "git update failed"
else
	update=""
	echo "Skipped (no explicit request)."
fi

echo -e "\n===== Git info ====="
git log -1 --format="Branch:  %d%nCommit:   %H%nAuthor:   %an <%ae>%nDate:     %ad (%ar)%nSubject:  %s"

lasttest=`git for-each-ref refs/tags --sort=-committerdate --format='%(refname)' --count=1`
echo -e "\nFiles changed since (last) release: ${lasttest##*/}"
git diff --name-status $lasttest

echo -e "\n===== Release number ====="
cat VERSION

################################################################################
if [ "$1" = "nobuild" ] ; then
	echo -e "\nBuild and tests skipped (explicit request)."
  echo -e "\nFinish: `date`"
  echo -e "\n===== End ====="
	rm -f build-test-lxplus.run
	exit
fi
################################################################################

echo -e "\n===== Clean build ====="
if [ "$1" = "cleanall" ] ; then
	shift
	make cleanall
	check_error "make cleanall failed"
else
	echo "Skipped (no explicit request)."
fi

echo -e "\n===== Gnu build ====="
source /afs/cern.ch/sw/lcg/contrib/gcc/max/i686-slc6/setup.sh
gcc      --version
g++      --version
gfortran --version

make all-linux32-gnu
check_error "make all-linux32-gnu failed" "no-exit"

source /afs/cern.ch/sw/lcg/contrib/gcc/max/x86_64-slc6/setup.sh
gcc      --version
g++      --version
gfortran --version

make all-linux64-gnu
check_error "make all-linux64-gnu failed" "no-exit"

echo -e "\n===== Intel build ====="
source /afs/cern.ch/sw/lcg/contrib/gcc/max/i686-slc6/setup.sh
source /afs/cern.ch/sw/IntelSoftware/linux/all-setup.sh ia32
icc      --version
ifort    --version

make all-linux32-intel
check_error "make all-linux32-intel failed" "no-exit"

source /afs/cern.ch/sw/lcg/contrib/gcc/max/x86_64-slc6/setup.sh
source /afs/cern.ch/sw/IntelSoftware/linux/all-setup.sh intel64
icc      --version
ifort    --version

make all-linux64-intel
check_error "make all-linux64-intel failed" "no-exit"

echo -e "\n===== NagFor build ====="
export PATH="${PATH}:/afs/cern.ch/sw/fortran/nag2012/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/afs/cern.ch/sw/fortran/nag2012/lib"
export NAG_KUSARI_FILE="/afs/cern.ch/sw/fortran/nag2012/lib/nag.licence.5.2,lxlicen04.cern.ch:"

make madx-linux32-nagfor
check_error "make madx-linux32-nagfor failed" "no-exit"

make madx-linux65-nagfor
check_error "make madx-linux64-nagfor failed" "no-exit"

echo -e "\n===== Lahey 32 build ====="
source /afs/cern.ch/sw/lcg/contrib/gcc/max/i686-slc6/setup.sh
export PATH="${PATH}:/afs/cern.ch/sw/fortran/lahey/lf9562e/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/afs/cern.ch/sw/fortran/lahey/lf9562e/lib"

make madx-linux32-lahey
check_error "make madx-linux32-lahey failed" "no-exit"

echo -e "\n===== Binaries dependencies ====="
make infobindep
check_error "make infobindep failed" "no-exit"

echo -e "\n===== Tests pointless files ====="
make cleantest && make infotestdep
check_error "make infotestdep failed" "no-exit"

echo -e "\n===== Running tests (long) ====="
if [ "$1" = "notest" ] ; then
	shift
	echo "Skipped (explicit request)."
else
	echo ""

	echo -e "\n===== Testing madx-linux32-intel ====="
	make madx-linux32-intel && ls -l madx32 && make cleantest && make tests-all COMP=intel ARCH=32 NOCOLOR=yes
	check_error "make tests-all for madx-linux32-intel failed"  "no-exit"

	echo -e "\n===== Testing madx-linux64-intel ====="
	make madx-linux64-intel && ls -l madx64 && make cleantest && make tests-all COMP=intel ARCH=64 NOCOLOR=yes
	check_error "make tests-all for madx-linux64-intel failed" "no-exit"

	echo -e "\n===== Testing madx-linux32-gnu ====="
	make madx-linux32-gnu && ls -l madx32 && make cleantest && make tests-all COMP=gnu ARCH=32 NOCOLOR=yes
	check_error "make tests-all for madx-linux32-gnu failed"  "no-exit"

	echo -e "\n===== Testing madx-linux64-gnu ====="
	make madx-linux64-gnu && ls -l madx64 && make cleantest && make tests-all COMP=gnu ARCH=64 NOCOLOR=yes
	check_error "make tests-all for madx-linux64-gnu failed"  "no-exit"
fi

# restore the default version
make madx-linux32-gnu > /dev/null && make madx-linux64-gnu > /dev/null
check_error "unable to restore the default version"

# date & end marker
echo -e "\nFinish: `date`"
echo -e "\n===== End of build and tests ====="

# cleanup lxplus node
rm -f build-test-lxplus.run
