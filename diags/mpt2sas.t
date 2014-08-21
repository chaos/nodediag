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

declare -r description="Check mpt2sas cards"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

list_adapt ()
{
    local host

    shopt -s nullglob
    for host in /sys/class/scsi_host/*; do
        grep -q mpt2sas $host/proc_name && echo $host
    done
    shopt -u nullglob
}

nargs ()
{
    echo $#
}

diagconfig ()
{
    [ $(id -u) -eq 0 ] || return 1

    local hosts=$(list_adapt)
    local host=$(list_adapt | tail -1)
    local num=$(nargs $hosts)

    echo "DIAG_MPT2SAS_NUM=\"$num\""
    if [ $num -gt 0 ]; then
        echo "DIAG_MPT2SAS_FW=\"$(cat $host/version_fw$)\""
        echo "DIAG_MPT2SAS_BIOS=\"$(cat $host/version_bios)\""
    fi
}

diag_handle_args "$@"
[ $(id -u) -eq 0 ] || diag_plan_skip "test requires root"
[ -n "$DIAG_MPT2SAS_NUM" ] || diag_plan_skip "not configured"
hosts=$(list_adapt)
num=$(nargs $hosts)
diag_plan $((($num * 2) + 1))

if [ $num -ne $DIAG_MPT2SAS_NUM ]; then
    diag_fail "$num cards, expected $DIAG_MPT2SAS_NUM"
else
    diag_ok "$num cards"
fi
for host in $hosts; do
    fw="$(cat $host/version_fw)"
    h=${host##*/}
    if [ -z "$DIAG_MPT2SAS_FW" ]; then
        diag_skip "$h fw '$fw', expected value not configured"
    elif [ "$fw" != "$DIAG_MPT2SAS_FW" ]; then
        diag_fail "$h fw '$fw', expected '$DIAG_MPT2SAS_FW'"
    else
        diag_ok "$h fw '$fw'"
    fi
    bios="$(cat $host/version_bios)"
    if [ -z "$DIAG_MPT2SAS_BIOS" ]; then
        diag_skip "$h bios '$bios', expected value not configured"
    elif [ "$bios" != "$DIAG_MPT2SAS_BIOS" ]; then
        diag_fail "$h bios '$bios', expected '$DIAG_MPT2SAS_BIOS'"
    else
        diag_ok "$h bios '$bios'"
    fi
done
exit 0

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
