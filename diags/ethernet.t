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

# FIXME: is this test redundant with network.t?  Should it go away/

PATH=/sbin:/bin:/usr/sbin:/usr/bin

declare -r description="Check ethernet config"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

getlink()
{
    ethtool $dev 2>/dev/null| awk '/Link detected:/ { print $3 }'
}
getspeed()
{
    ethtool $dev | awk '/Speed:/ { print $2 }'
}
getduplex()
{
    ethtool $dev | awk '/Duplex:/ { print $2 }'
}

diagconfig ()
{
    local file dev link speed duplex
    local i=0

    shopt -s nullglob
    for file in /sys/class/net/eth*; do
        dev=`basename $file`
        link=`getlink $dev`
        [ "$link" == "yes" ] || continue
        speed=`getspeed $dev`
        duplex=`getduplex $dev`
        echo "DIAG_ETHERNET_DEV[$i]=\"$dev\""
        echo "DIAG_ETHERNET_SPEED[$i]=\"$speed\""
        echo "DIAG_ETHERNET_DUPLEX[$i]=\"$duplex\""
        i=$(($i+1))
    done
    shopt -u nullglob
}

diag_handle_args "$@"
numdev=${#DIAG_ETHERNET_DEV[@]}
[ $(id -u) -eq 0 ] || diag_plan_skip "test requires root"
[ $numdev -gt 0 ] || diag_plan_skip "not configured"
diag_plan $(($numdev * 3))

for i in $(seq 0 $(($numdev - 1))); do
    dev=${DIAG_ETHERNET_DEV[$i]}
    speed=${DIAG_ETHERNET_SPEED[$i]}
    duplex=${DIAG_ETHERNET_DUPLEX[$i]}
    gotlink=`getlink $dev`
    if [ "$gotlink" != "yes" ]; then
        diag_fail "$dev link $gotlink"
    else
        diag_ok "$dev link $gotlink"
    fi
    if [ -n "$speed" ]; then
        gotspeed=`getspeed $dev`
        if [ "$speed" != "$gotspeed" ]; then
            diag_fail "$dev speed $gotspeed, expected $speed"
        else
            diag_ok "$dev speed $gotspeed"
        fi
    else
        diag_skip "$dev speed not configured"
    fi

    if [ -n "$duplex" ]; then
        gotduplex=`getduplex $dev`
        if [ "$duplex" != "$gotduplex" ]; then
            diag_fail "$dev duplex $gotduplex, expected $duplex"
        else
            diag_ok "$dev duplex $gotduplex"
        fi
    else
        diag_skip "$dev duplex not configured"
    fi
done
exit 0

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
