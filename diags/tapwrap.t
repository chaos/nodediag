#!/bin/bash

declare -r diagdir=/etc/nodediag.d
declare -r description="Run any non-TAP tests in $diagdir"
testopts=""

source $diagdir/functions

testold()
{
    local num=$1
    local t=$2
    local line

    $diagdir/$t $testopts 2>&1 | while read line; do
         echo "# $line"
    done
    case ${PIPESTATUS[0]} in
        $EXIT_SKIP)
            echo ok $num "$t" "# skip"
            ;;
        $EXIT_FAIL)
            echo fail $num "$t"
            ;;
        $EXIT_PASS)
            echo ok "$t"
            ;;
    esac
}

listold()
{
    local file

    pushd $diagdir >/dev/null
    shopt -s nullglob
    for file in *; do
        case $file in
            *.t|functions|tap-functions)
                ;;
            *)
                echo -n "$file "
                ;;
        esac
    done
    shopt -u nullglob
    popd >/dev/null
}

#
# MAIN
#

oldfiles=`listold`

opt=""
while getopts "?hdcs" opt; do
    case ${opt} in
        d)  printf "%-16s %s\n" "tapwrap:" "Run non-TAP tests: ${oldfiles:-(none)}"
            exit 0
            ;;
        c)  for file in $oldfiles; do
                $diagdir/$file -c
            done
            exit 0
            ;;
        s)  testopts="$testopts -s"
            ;;
        *)  echo "Usage: tapwrap.t [-dcs]"
            exit 0
         ;;
    esac
done

count=`echo $oldfiles| wc -w`
echo "1..$count"

num=1
for file in $oldfiles; do
    testold $num $file
    num=$(($num + 1))
done
exit 0
