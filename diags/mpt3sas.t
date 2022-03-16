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

declare -r description="Check mpt3sas cards"
declare -a MPT3SAS_DEV=[]

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

list_adapt ()
{
    local host
    local i=0

    shopt -s nullglob
    for host in /sys/class/scsi_host/*; do
        if grep -q mpt3sas $host/proc_name; then
            MPT3SAS_DEV[$i]=$host
            i=$((i+1))
        fi
    done
    shopt -u nullglob
}

diag_handle_args "$@"
[ $(id -u) -eq 0 ] || diag_plan_skip "test requires root"
[ -n "$DIAG_MPT3SAS_NUM" ] || diag_plan_skip "not configured"
list_adapt
num=${#MPT3SAS_DEV[@]}
diag_plan $((($num * 2) + 1))

if [ $num -ne $DIAG_MPT3SAS_NUM ]; then
    diag_fail "$num cards, expected $DIAG_MPT3SAS_NUM"
else
    diag_ok "$num cards"
fi
for i in $(seq 0 $(($num - 1))); do
    dev=${MPT3SAS_DEV[$i]}
    fw="$(cat $dev/version_fw)"
    h=${dev##*/}
    if [ -z "$DIAG_MPT3SAS_FW[$i]" ]; then
        diag_skip "$h fw '$fw', expected value not configured"
    elif [ "$fw" != "${DIAG_MPT3SAS_FW[$i]}" ]; then
        diag_fail "$h fw '$fw', expected '$DIAG_MPT3SAS_FW[$i]'"
    else
        diag_ok "$h fw '$fw'"
    fi
    bios="$(cat $dev/version_bios)"
    if [ -z "$DIAG_MPT3SAS_BIOS[$i]" ]; then
        diag_skip "$h bios '$bios', expected value not configured"
    elif [ "$bios" != "${DIAG_MPT3SAS_BIOS[$i]}" ]; then
        diag_fail "$h bios '$bios', expected '$DIAG_MPT3SAS_BIOS[$i]'"
    else
        diag_ok "$h bios '$bios'"
    fi
    i=$(($i+1))
done
exit 0

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
