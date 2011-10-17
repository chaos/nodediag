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

declare -r description="Check network config"
declare -r sanity=1

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions

diagconfig ()
{
    local file dev
    local i=0

    shopt -s nullglob 
    for file in /sys/class/net/*; do
        dev=`basename $file` 
        case $dev in
            eth*)
                echo "DIAG_NETWORK_DEV[$i]=\"$dev\""
                echo "DIAG_NETWORK_MTU[$i]=\"`cat $file/mtu`\""
                i=$(($i+1))
                ;;
            ib*)
                echo "DIAG_NETWORK_DEV[$i]=\"$dev\""
                echo "DIAG_NETWORK_MTU[$i]=\"`cat $file/mtu`\""
                echo "DIAG_NETWORK_MODE[$i]=\"`cat $file/mode`\""
                i=$(($i+1))
                ;;
        esac
    done        
    shopt -u nullglob 
}

diag_handle_args "$@"
diag_check_defined "DIAG_NETWORK_DEV"

i=0
for dev in ${DIAG_NETWORK_DEV[@]}; do
    if [ ! -d /sys/class/net/$dev ]; then
        diag_fail "$dev does not exst"
    fi
    diag_msg "$dev exists"
    mtu=${DIAG_NETWORK_MTU[$i]}
    if [ -n "$mtu" ]; then
        gotmtu=`cat /sys/class/net/$dev/mtu`
        if [ "$mtu" != "$gotmtu" ]; then
            diag_fail "$dev mtu $gotmtu, expected $mtu"
        fi
        diag_msg "$dev mtu $gotmtu"
    fi
    mode=${DIAG_NETWORK_MODE[$i]}
    if [ -n "$mode" ]; then
        gotmode=`cat /sys/class/net/$dev/mode`
        if [ "$mode" != "$gotmode" ]; then
            diag_fail "$dev mode $gotmode, expected $mode"
        fi
        diag_msg "$dev mode $gotmode"
    fi
    i=$(($i + 1))
done
diag_ok "$i devices checked"
