#!/bin/bash
##############################################################################
# Copyright (c) 2011, Lawrence Livermore National Security, LLC.
# Produced at the Lawrence Livermore National Laboratory.
# Written by Jim Garlick <garlick@llnl.gov>.
# LLNL-CODE-461827
# All rights reserved.
#
# This file is part of nodediag.
# For details, see http://code.google.com/p/nodediag.
# Please also read the files DISCLAIMER and COPYING supplied with nodediag.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License (as published by the
# Free Software Foundation) version 2, dated June 1991.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the IMPLIED WARRANTY OF
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# terms and conditions of the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
##############################################################################

declare -r diagdir=${NODEDIAGDIR:-/etc/nodediag.d}
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
            echo "ok $num # skip" "non-TAP test $t returned EXIT_SKIP"
            ;;
        $EXIT_FAIL)
            echo "not ok $num" "- non-TAP test $t returned EXIT_FAIL"
            ;;
        $EXIT_PASS)
            echo "ok $num" "- non-TAP test $t returned EXIT_PASS"
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
            *.t|functions*)
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
if [ $count -eq 0 ]; then
    echo "1..0 # Skipped: all tests are TAP compliant"
else
    echo "1..$count"
fi

num=1
for file in $oldfiles; do
    testold $num $file
    num=$(($num + 1))
done
exit 0

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
