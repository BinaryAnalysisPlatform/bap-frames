#!/bin/bash
cd libtrace
./autogen.sh
cd ..
mkdir libtrace-32
pushd libtrace-32
PREFIX=$PREFIX CPPFLAGS="$CPPFLAGS -m32" CXXFLAGS="$CXXFLAGS -m32" LDFLAGS="$LDFLAGS -m32" ../libtrace/configure
make
popd
mkdir libtrace-64
pushd libtrace-64
PREFIX=$PREFIX ../libtrace/configure
make
popd
