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

declare -r description="Check ethernet config"
declare -r sanity=1

source /etc/nodediag.d/functions

diagconfig ()
{
    local file dev link speed duplex
    local i=0

    shopt -s nullglob
    for file in /sys/class/net/eth*; do
        dev=`basename $file`
        link=`ethtool $dev 2>/dev/null| awk '/Link detected:/ { print $3 }'`
        [ "$link" == "yes" ] || continue
        speed=`ethtool $dev | awk '/Speed:/ { print $2 }'`
        duplex=`ethtool $dev | awk '/Duplex:/ { print $2 }'`
        echo "DIAG_ETHERNET_DEV[$i]=\"$dev\""
        echo "DIAG_ETHERNET_SPEED[$i]=\"$speed\""
        echo "DIAG_ETHERNET_DUPLEX[$i]=\"$duplex\""
        i=$(($i+1))
    done
    shopt -u nullglob
}


diag_handle_args "$@"
diag_check_defined "DIAG_ETHERNET_DEV"
diag_check_root

i=0
for dev in ${DIAG_ETHERNET_DEV[@]}; do
    gotlink=`ethtool $dev | awk '/Link detected:/ { print $3 }'`
    if [ "$gotlink" != "yes" ]; then
        diag_fail "$dev link $gotlink"
    fi
    diag_msg "$dev link $gotlink"
    speed=${DIAG_ETHERNET_SPEED[$i]}
    if [ -n "$speed" ]; then
        gotspeed=`ethtool $dev | awk '/Speed:/ { print $2 }'`
        if [ "$speed" != "$gotspeed" ]; then
            diag_fail "$dev speed $gotspeed, expected $speed"
        fi
        diag_msg "$dev speed $gotspeed"
    fi
    duplex=${DIAG_ETHERNET_DUPLEX[$i]}
    if [ -n "$duplex" ]; then
        gotduplex=`ethtool $dev | awk '/Duplex:/ { print $2 }'`
        if [ "$duplex" != "$gotduplex" ]; then
            diag_fail "$dev duplex $gotduplex, expected $duplex"
        fi
        diag_msg "$dev duplex $gotduplex"
    fi
    i=$(($i + 1))
done
diag_ok "$i devices checked"
