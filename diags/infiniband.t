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

declare -r description="Check infiniband config"
declare -r sanity=1

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions

diag_handle_args "$@"
diag_check_defined "DIAG_INFINIBAND_DEV"
diag_check_root

[ -x /usr/sbin/ibstat ] || diag_skip "ibstat is unavailable"

i=0
for dev in "${DIAG_INFINIBAND_DEV[@]}"; do

    # If link comes up late, configure retries here
    retries=${DIAG_INFINIBAND_RETRIES:-"0"}
    retrysec=${DIAG_INFINIBAND_RETRY_SEC:-"10"}
    linkup=0
    while [ $retries -ge 0 ] && [ $linkup -eq 0 ]; do
        gotlink=`/usr/sbin/ibstat $dev | awk '/Physical state:/ { print $3 }'`
        if [ "$gotlink" == "LinkUp" ]; then
            diag_msg "$dev state $gotlink" >&2
            linkup=1
        else
            retries=$(($retries - 1))
            if [ $retries -ge 0 ]; then
                diag_msg "$dev will retry in $retrysec seconds"
                sleep $retrysec
            else
                diag_fail "$dev state $gotlink, expected LinkUp"
            fi
        fi
    done

    # now that link is up, check the speed
    speed=${DIAG_INFINIBAND_RATE[$i]}
    if [ -n "$speed" ]; then
        gotspeed=`/usr/sbin/ibstat $dev | awk '/Rate:/ { print $2 }'`
        if [ "$speed" != "$gotspeed" ]; then
            diag_fail "$dev rate $gotspeed, expected $speed"
        fi
        diag_msg "$dev rate $gotspeed"
    fi
    i=$(($i + 1))
done
diag_ok "$i devices checked"
