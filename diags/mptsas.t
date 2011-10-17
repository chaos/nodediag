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

declare -r description="Check mptsas cards"
declare -r sanity=1

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions

list_adapt ()
{
    local host

    shopt -s nullglob
    for host in /sys/class/scsi_host/*; do
        grep -q mptsas $host/proc_name && echo $host
    done
    shopt -u nullglob
}

nargs ()
{
    echo $#
}

diagconfig ()
{
    local hosts=`list_adapt`
    local host=`list_adapt | tail -1`
    local num=`nargs $hosts`

    echo "DIAG_MPTSAS_NUM=\"$num\""
    if [ $num -gt 0 ]; then
        echo "DIAG_MPTSAS_FW=\"`cat $host/version_fw`\""
        echo "DIAG_MPTSAS_BIOS=\"`cat $host/version_bios`\""
    fi
}

diag_handle_args "$@"
diag_check_defined "DIAG_MPTSAS_NUM"
diag_check_root

hosts=`list_adapt`
num=`nargs $hosts`
if [ $num -ne $DIAG_MPTSAS_NUM ]; then
    diag_fail "$num cards, expected $DIAG_MPTSAS_NUM"
fi
diag_msg "$num cards"
if [ -n "$DIAG_MPTSAS_FW" ]; then
    for host in $hosts; do
        fw=`cat $host/version_fw`
        if [ $fw != $DIAG_MPTSAS_FW ]; then
            h=`basename $host`
            diag_fail "$h fw $fw, expected $DIAG_MPTSAS_FW"
        fi
        diag_msg "$h fw $fw"
    done
fi
if [ -n "$DIAG_MPTSAS_BIOS" ]; then
    for host in $hosts; do
        bios=`cat $host/version_bios`
        if [ $bios != $DIAG_MPTSAS_BIOS ]; then
            h=`basename $host`
            diag_fail "$h bios $bios, expected $DIAG_MPTSAS_BIOS"
        fi
        diag_msg "$h bios $bios"
    done
fi
diag_ok "$num devices checked"
