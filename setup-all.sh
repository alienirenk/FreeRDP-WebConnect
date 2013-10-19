#!/bin/bash -
set -e
#Variable which determines if we install prereqs or not
cont=1
if [[ $EUID -ne 0 ]]; then
   echo "In order to install the dependencies of this package, the script must be run as root (or with sudo)"
   echo -n "However, if all dependencies are installed (see README for a list), do you wish to proceed? [y/N] "
   read response
   [[ $response == "y" ]] && cont=2 || exit 1
fi
if [[ $cont -eq 1 ]]; then
	#Get distro (snipper take from alsa-info.sh)
	DISTRO=`grep -ihs "buntu\|SUSE\|Fedora\|Debian\|Kubuntu\|CentOS" /etc/{issue,*release,*version}`
	case $DISTRO in
		*buntu*)
			echo 'Ubuntu distro detected. Installing required packages...'
			yum install -y git svn subversion-svn2cl openssl-devel boost-devel libpng-devel
			yum -y groupinstall "Development tools"
			;;
		Fedora*19)
			echo 'Fedora 19 detected.Installing required packages...'
			;;
		SUSE*)
			echo 'SUSE detected. Installing required packages...'
			;;
		CentOS*)
			echo 'CentOS detected. Installing required packages...'
			yum install -y git svn subversion-svn2cl openssl-devel boost-devel libpng-devel
			yum groupinstall -y "Development tools"
			echo 'Getting cmake 2.8.12 (CentOS has old cmake version)'
			wget http://www.cmake.org/files/v2.8/cmake-2.8.12.tar.gz && tar -xzvf cmake-2.8.12.tar.gz && cd cmake-2.8.12 && ./bootstrap --prefix=/usr && make && make install
			cd ..
			rm -rf cmake-2.8.12 && rm -f cmake-2.8.12.tar.gz
			;;
			*)
			echo 'Distro not found! You shall need git, svn-devel, autotools, gcc, g++, boost, openssl-devel and libpng-devel to successfully build this package.'
			echo 'For tracing to work, libdwarf is also required.'
			;;
	esac
fi
echo ---- Fetching webconnect dependencies into $(dirname `pwd`)/prereqs ----
cd ..
mkdir -p prereqs
mkdir -p $HOME/local
cd prereqs
echo '---- Checking out ehs trunk code ----'
svn checkout svn://svn.code.sf.net/p/ehs/code/trunk ehs-code
cd ehs-code
make -f Makefile.am
./configure --with-ssl --prefix=$HOME/local
echo '---- Starting ehs build ----'
make
echo '---- Finished building ehs ----'
make install
echo '---- Finished installing ehs ----'
cd ..
echo '---- Checking out freerdp master ----'
git clone https://github.com/FreeRDP/FreeRDP.git
cd FreeRDP
mkdir -p build && cd build && cmake -DCMAKE_INSTALL_PREFIX=$HOME/local .. -DLIB_SUFFIX=64
echo '---- Building freerdp ----'
make
echo '---- Finished building freerdp ----'
make install
echo '---- Finished installing freerdp ----'
echo '---- Going back to webconnect ----'
cd ../../../FreeRDP-WebConnect/wsgate/
make -f Makefile.am
./configure
echo '---- Building webconnect ----'
make
echo '---- Finished successfully ----'
echo '---- To run please use `cd wsgate && ./wsgate -c wsgate.mrd.ini` and connect on localhost:8888 ----'