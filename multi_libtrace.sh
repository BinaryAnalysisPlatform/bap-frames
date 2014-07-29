#!/bin/bash
cd libtrace
./autogen.sh
cd ..
mkdir -p _build/libtrace-32
pushd _build/libtrace-32
PREFIX=$PREFIX CPPFLAGS="$CPPFLAGS -m32" CXXFLAGS="$CXXFLAGS -m32" LDFLAGS="$LDFLAGS -m32" ../../libtrace/configure
make
popd
mkdir -p _build/libtrace-64
pushd _build/libtrace-64
PREFIX=$PREFIX ../../libtrace/configure
make
popd
