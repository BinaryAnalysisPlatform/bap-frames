#!/bin/bash -e

display_usage() { 
    echo -e \
"Test bap trace plugins with arm binaries\n"\
"Usage: $0 <arm-binaries>\n"\
"  <arm-binaries> - path to arm binaries folder clonned from\n"\
"                   https://github.com/BinaryAnalysisPlatform/arm-binaries\n"\
"example:\n"\
"  QEMU_LD_PREFIX=$HOME/libs/armel ./test/tracedump-test.sh ../arm-binaries"
} 

if [[ ("$#" -ne 1) || ($1 == "--help") || ($1 == "-h") ]] 
then
    display_usage
    exit 0
fi

ARM_BINARIES="$(realpath $1)"

cd "$(dirname "$0")"

if [ ! -f ../tracedump.native ]; then
    echo "executable tracedump.native not found, build bap-traces library first"
    exit 1
fi

if ! which qemu-arm > /dev/null; then
    echo "qemu-arm not found, build and install qemu-tracer first"
    exit 1
fi

if ! which bap-tracedump > /dev/null; then
    echo "bap-tracedump not found, install bap-tracedump from bap opam repository"
    exit 1
fi

TEST_FILES="uname who whoami pinky pwd uptime tty nproc du"

trap error ERR
error() {
    echo "[FAILED]"
    exit -1
}

for f in $TEST_FILES; do
    for b in `find $ARM_BINARIES -type f -name "*_$f"`; do
        printf '%-70s' $b
        if [ "$f" == "du" ]; then
            qemu-arm -tracefile /tmp/$f.frames $b /tmp >/dev/null
        else
            qemu-arm -tracefile /tmp/$f.frames $b >/dev/null
        fi
        bap-tracedump file:///tmp/$f.frames >/dev/null
        echo "[OK]"
    done
done
