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
declare -r sanity=0

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions

diag_handle_args "$@"
diag_check_defined "DIAG_HDPARM_DEV"
diag_check_root

i=0
for dev in ${DIAG_HDPARM_DEV[@]}; do
    if [ ! -b $dev ]; then
        diag_fail "$dev is not a block device"
    fi
    diag_msg "$dev is a block device"
    if [ -n "${DIAG_HDPARM_MIN_MBSEC[$i]}" ]; then
        speed=${DIAG_HDPARM_MIN_MBSEC[$i]}
        gotspeed=`/sbin/hdparm -t $dev | awk '/.*reads:/ { printf "%d", $11 }'`
        if [ $gotspeed -lt $speed ]; then
            diag_fail "$dev speed $gotspeed MB/s, expected $speed $MB/s"
        fi
        diag_msg "$dev speed $gotspeed MB/s"
    fi
    i=$(($i + 1))
done
diag_ok "$i devices checked"
