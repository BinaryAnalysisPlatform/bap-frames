#!/bin/bash

set -ex

aclocal
autoconf
autoheader
automake --add-missing --copy
