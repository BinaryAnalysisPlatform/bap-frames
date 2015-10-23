#!/bin/bash -e

DEBOOTSTRAP_DIR=/usr/share/debootstrap
UBUNTU_KEYRING=/usr/share/keyrings/ubuntu-archive-keyring.gpg
DEBIAN_KEYRING=/usr/share/keyrings/debian-archive-keyring.gpg

if [ ! -d "$DEBOOTSTRAP_DIR" ] || [ ! -f "$DEBIAN_KEYRING" ]; then
  echo "this script requires debootstrap and debian-archive-keyring to be installed"
  exit 1
fi

# this is ubuntu specific i think
fetcharch() {
  ARCH="$1"
  DISTRO="$2"
  SUITE="$3"
  exec 4>&1
  SHA_SIZE=256
  DEBOOTSTRAP_CHECKSUM_FIELD="SHA$SHA_SIZE"
  TARGET="$ARCH"
  TARGET="$(echo "`pwd`/$TARGET")"
  HOST_ARCH=`/usr/bin/dpkg --print-architecture`
  HOST_OS=linux
  USE_COMPONENTS=main
  RESOLVE_DEPS=true
  export DEBOOTSTRAP_CHECKSUM_FIELD

  mkdir -p "$TARGET" "$TARGET/debootstrap"

  . $DEBOOTSTRAP_DIR/functions
  . $DEBOOTSTRAP_DIR/scripts/$SUITE

  if [ $DISTRO == "ubuntu" ]; then
    KEYRING=$UBUNTU_KEYRING
    MIRRORS="$DEF_MIRROR"
  elif [ $DISTRO == "debian" ]; then
    KEYRING=$DEBIAN_KEYRING
    MIRRORS="http://ftp.us.debian.org/debian"
  else
    echo "need a distro"
    exit 1
  fi

  download_indices
  work_out_debs

  all_debs=$(resolve_deps $LIBS)
  echo "$all_debs"
  download $all_debs

  choose_extractor
  extract $all_debs
}

#rm -rf libs
mkdir -p libs
cd libs

LIBS="libc-bin libstdc++6 libcap2"
fetcharch armel ubuntu precise
# mini debootstrap 

