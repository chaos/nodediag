#!/bin/bash
##############################################################################
# Copyright (c) 2010, Lawrence Livermore National Security, LLC.
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

PATH=/sbin:/bin:/usr/sbin:/usr/bin

declare -r description="Check number of CPU cores"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

cpucount_online()
{
    grep 'processor[[:space:]]:' /proc/cpuinfo|wc -l
}

cpucount_present()
{
    ls -d1 /sys/devices/system/cpu/cpu* | grep 'cpu[0-9][0-9]*'|wc -l
}

cpucount_test()
{
    local name=$1
    local expected=$2
    local actual=$3
    if [ "$expected" != "$actual" ]; then
        diag_fail "cpucount $name $actual, expected $expected"
    else
        diag_ok "cpucount $name $actual"
    fi
}

diagconfig()
{
    echo "DIAG_CPUCOUNT=\"$(cpucount_present)\""
    echo "DIAG_CPUCOUNT_ONLINE=\"$(cpucount_online)\""
}

diag_handle_args "$@"
#  If DIAG_CPUCOUNT_ONLINE is not set, use DIAG_CPUCOUNT as the
#   number of cpus online (i.e. online cpucount == present cpucount)
#
DIAG_CPUCOUNT_ONLINE=${DIAG_CPUCOUNT_ONLINE:-${DIAG_CPUCOUNT}}

declare -i n=0
[ -n "$DIAG_CPUCOUNT" ] && let n++
[ -n "$DIAG_CPUCOUNT_ONLINE" ] && let n++
[ $n -eq 0 ] && diag_plan_skip "not configured"

diag_plan $n

cpus_present=$(cpucount_present)
cpus_online=$(cpucount_online)

if [ -n "$DIAG_CPUCOUNT" ]; then
    cpucount_test "present" $DIAG_CPUCOUNT $cpus_present
fi
if [ -n "$DIAG_CPUCOUNT_ONLINE" ]; then
    cpucount_test "online " $DIAG_CPUCOUNT_ONLINE $cpus_online
fi

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
