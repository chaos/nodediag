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

declare -r description="Check infiniband config"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

diagconfig ()
{
    which ibstat >/dev/null 2>&1 || return 1

    local port rate ca
    local i=0

    echo "DIAG_INFINIBAND_RETRIES=0"
    echo "DIAG_INFINIBAND_RETRY_SEC=10"
    for ca in $(ibstat -l); do
        for port in $(seq 1 2); do
            dev="$ca $port"
            rate=$(ibstat $dev 2>/dev/null | grep Rate:|sed -e 's/Rate: //')
            if [ -n "$rate" ]; then
                echo "DIAG_INFINIBAND_DEV[$i]=\"$dev\""
                echo "DIAG_INFINIBAND_RATE[$i]=\"$rate\""
                i=$(($i+1))
            fi
        done
    done
}


diag_handle_args "$@"

numdev=${#DIAG_INFINIBAND_DEV[@]}
[ $(id -u) -eq 0 ] || diag_plan_skip "test requires root"
[ $numdev -gt 0 ] || diag_plan_skip "not configured"
which ibstat 2>/dev/null 1>&2 || diag_plan_skip "ibstat is unavailable"
diag_plan $(($numdev * 2))

for i in $(seq 0 $(($numdev - 1))); do
    dev=${DIAG_INFINIBAND_DEV[$i]}

    # check the port guid to make sure it is not 0x0000000000000000
    portguid=$(/usr/sbin/ibstat $dev | awk '/Port GUID:/ { print $3 }')
    if [ "$portguid" = "0x0000000000000000" ]; then
        diag_fail "$dev port guid is 0x0000000000000000"
    fi

    # If link comes up late, configure retries here
    retries=${DIAG_INFINIBAND_RETRIES:-"0"}
    retrysec=${DIAG_INFINIBAND_RETRY_SEC:-"10"}
    linkup=0
    while [ $retries -ge 0 ] && [ $linkup -eq 0 ]; do
        gotlink=$(ibstat $dev | awk '/Physical state:/ { print $3 }')
        if [ "$gotlink" == "LinkUp" ]; then
            linkup=1
        else
            retries=$(($retries - 1))
            if [ $retries -ge 0 ]; then
                diag_msg "$dev will retry in $retrysec seconds"
                sleep $retrysec
            fi
        fi
    done
    if [ $linkup -eq 0 ]; then
        diag_fail "$dev state $gotlink, expected LinkUp"
    else
        diag_ok "$dev state $gotlink" >&2
    fi

    # now that link is up, check the speed
    speed=${DIAG_INFINIBAND_RATE[$i]}
    if [ -n "$speed" ]; then
        gotspeed=$(/usr/sbin/ibstat $dev | awk '/Rate:/ { print $2 }')
        if [ "$speed" != "$gotspeed" ]; then
            diag_fail "$dev rate $gotspeed, expected $speed"
        else
            diag_ok "$dev rate $gotspeed"
        fi
    else
        diag_skip "$dev rate not configured"
    fi
done

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
