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

declare -r description="Check network config"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

getmode() {
    cat /sys/class/net/$1/mode 2>/dev/null
}
getmtu() {
    cat /sys/class/net/$1/mtu 2>/dev/null
}
getduplex() {
    cat /sys/class/net/$1/duplex 2>/dev/null
}
getspeed() {
    cat /sys/class/net/$1/speed 2>/dev/null
}

diagconfig ()
{
    local file dev
    local i=0

    shopt -s nullglob 
    for file in /sys/class/net/*; do
        if test -h $file/device; then
            dev=${file##*/}
            echo "DIAG_NETWORK_DEV[$i]=\"$dev\""
            test -n "$(getmtu $dev)" \
                && echo "DIAG_NETWORK_MTU[$i]=\"$(getmtu $dev)\""
            test -n "$(getmode $dev)" \
                && echo "DIAG_NETWORK_MODE[$i]=\"$(getmode $dev)\""
            test -n "$(getduplex $dev)" \
                && echo "DIAG_NETWORK_DUPLEX[$i]=\"$(getduplex $dev)\""
            test -n "$(getspeed $dev)" \
                && echo "DIAG_NETWORK_SPEED[$i]=\"$(getspeed $dev)\""
            i=$(($i+1))
        fi
    done        
    shopt -u nullglob 
}

diag_handle_args "$@"
numdev=${#DIAG_NETWORK_DEV[@]}
[ $numdev -gt 0 ] || diag_plan_skip "not configured"

numtests=$numdev
for i in $(seq 0 $(($numdev - 1))); do
    [ -n "${DIAG_NETWORK_MTU[$i]}" ] && numtests=$(($numtests + 1))
    [ -n "${DIAG_NETWORK_MODE[$i]}" ] && numtests=$(($numtests + 1))
    [ -n "${DIAG_NETWORK_SPEED[$i]}" ] && numtests=$(($numtests + 1))
done
diag_plan $(($numtests))

for i in $(seq 0 $(($numdev - 1))); do
    dev=${DIAG_NETWORK_DEV[$i]}
    mtu=${DIAG_NETWORK_MTU[$i]}
    mode=${DIAG_NETWORK_MODE[$i]}
    duplex=${DIAG_NETWORK_DUPLEX[$i]}
    speed=${DIAG_NETWORK_SPEED[$i]}
    if [ -d /sys/class/net/$dev ]; then
        diag_ok "$dev exists"
    else
        diag_fail "$dev does not exst"
    fi
    if [ -n "$mtu" ]; then
        gotmtu="$(getmtu $dev)"
        if [ "$mtu" != "$gotmtu" ]; then
            diag_fail "$dev mtu '$gotmtu', expected '$mtu'"
        else
            diag_ok "$dev mtu '$gotmtu'"
        fi
    fi
    if [ -n "$mode" ]; then
        gotmode="$(getmode $dev)"
        if [ "$mode" != "$gotmode" ]; then
            diag_fail "$dev mtu '$gotmode', expected '$mode'"
        else
            diag_ok "$dev mode '$gotmode'"
        fi
    fi
    if [ -n "$duplex" ]; then
        gotduplex="$(getduplex $dev)"
        if [ "$duplex" != "$gotduplex" ]; then
            diag_fail "$dev duplex '$gotduplex', expected '$duplex'"
        else
            diag_ok "$dev duplex '$gotduplex'"
        fi
    fi
    if [ -n "$speed" ]; then
        gotspeed="$(getspeed $dev)"
        if [ "$speed" != "$gotspeed" ]; then
            diag_fail "$dev speed '$gotspeed', expected '$speed'"
        else
            diag_ok "$dev speed '$gotspeed'"
        fi
    fi
done

# vi: expandtab sw=4 ts=4
# vi: syntax=sh

