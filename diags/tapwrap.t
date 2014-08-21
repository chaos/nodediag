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
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version.
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
PATH=/sbin:/bin:/usr/sbin:/usr/bin

declare -r diagdir=${NODEDIAGDIR:-/etc/nodediag.d}

listold()
{
    pushd $diagdir >/dev/null
    shopt -s nullglob 
    GLOBIGNORE="*.t:functions:functions-*"; echo *; unset GLOBIGNORE
    shopt -u nullglob
    popd >/dev/null
}

declare -r testnames=$(listold)
declare -r description="Run non-TAP tests: ${testnames:-(none)}"

source $diagdir/functions-tap || exit 1

diagconfig()
{
    local name
    for name in $testnames; do $diagdir/$name -c; done
}
nargs()
{
    echo $#
}

diag_handle_args "$@"
numtests=$(nargs $testnames)
[ $numtests -gt 0 ] || diag_plan_skip "all tests are TAP compliant"
diag_plan $numtests

diag_sanity && testopts="-s"

for name in $testnames; do
    $diagdir/$name $testopts 2>&1 | while read line; do
        diag_msg "$line"
    done
    rc=${PIPESTATUS[0]}
    msg="non-TAP test $name exited with status $rc"
    case $rc in
        0)  diag_ok $msg ;;
        2)  diag_skip $msg ;;
        *)  diag_fail $msg ;;
    esac
done
exit 0

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
