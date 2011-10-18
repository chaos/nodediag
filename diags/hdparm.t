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

declare -r description="Check hard drive read performance"

# no diagconfig() == no reasonable default config

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

diag_handle_args "$@"

numdev=${#DIAG_HDPARM_DEV[@]}
[ $(id -u) -eq 0 ] || diag_plan_skip "test requires root"
[ $numdev -gt 0 ] || diag_plan_skip "not configured"
diag_sanity && diag_plan_skip "takes too long for sanity testing"
diag_plan $numdev

for i in $(seq 0 $(($numdev - 1))); do
    dev=${DIAG_HDPARM_DEV[$i]}
    if [ ! -b $dev ]; then
        diag_fail "$dev: is not a block device"
    elif ! [ -n "${DIAG_HDPARM_MIN_MBSEC[$i]}" ]; then
        diag_skip "$dev: performance test not configured"
    else
        speed=${DIAG_HDPARM_MIN_MBSEC[$i]}
        gotspeed=`hdparm -t $dev | awk '/.*reads:/ { printf "%d", $11 }'`
        if [ $gotspeed -lt $speed ]; then
            diag_fail "$dev speed $gotspeed MB/s, expected $speed $MB/s"
        else
            diag_ok "$dev speed $gotspeed MB/s"
        fi
    fi
done
exit 0

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
