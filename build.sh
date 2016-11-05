#!/bin/bash

set -x

usage() {
  base="$(basename "$0")"
  cat <<EOUSAGE
usage: $base arch
Install specific packages to build grafana for either armv6 or armv7
Available arch:
  $base armv6
  $base armv7
EOUSAGE
}

install_phjs() {
  PHJSURL="https://github.com/fg2it/phantomjs-on-raspberry/releases/download/${PHJSV}"
  PHJS=/tmp/${ARM}/phantomjs
  mkdir -p /tmp/${ARM}
  curl -sSL ${PHJSURL}/phantomjs -o ${PHJS}
  chmod a+x ${PHJS}
}

armv6_install_cross(){
  cd /tmp
  git clone https://github.com/fg2it/cross-rpi1b.git
  CROSSPATH="/tmp/cross-rpi1b/arm-rpi-4.9.3-linux-gnueabihf/bin/"
  CC=${CROSSPATH}/arm-linux-gnueabihf-gcc
  CXX=${CROSSPATH}/arm-linux-gnueabihf-g++
}

armv7_install_cross() {
  echo "deb http://emdebian.org/tools/debian/ jessie main" > /etc/apt/sources.list.d/crosstools.list
  curl -sSL http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -
  dpkg --add-architecture armhf
  apt-get update
  apt-get install -y crossbuild-essential-armhf
  CC=arm-linux-gnueabihf-gcc
  CXX=arm-linux-gnueabihf-g++
}

build() {
  cd $GOPATH/src/github.com/grafana/grafana
  go run build.go                   \
     -pkg-arch=armhf                \
     -goarch=${ARM}                 \
     -cgo-enabled=1                 \
     -cc=$CC                        \
     -cxx=$CXX                      \
     -phjs=${PHJS}                  \
         build                      \
         pkg-deb
}

if [ "$#" -ne 1 ]; then
	usage >&2
	exit 1
fi

ARM="$1"

if [ "$ARM" = "armv6" ]; then
  PHJSV="v2.1.1-wheezy-jessie-armv6"
  armv6_install_cross
elif [ "$ARM" = "armv7" ]; then
  PHJSV="v2.1.1-wheezy-jessie"
  armv7_install_cross
else
  echo >&2 'error: unknown arch:' "$ARM"
  usage >&2
  exit 1
fi


install_phjs
build
