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

declare -r description="Check 3ware cards"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

list_adapt ()
{
    tw_cli show | awk '/^c[0-9]*/ {print $1}'
}

get_fw ()
{
    tw_cli /$1 show firmware | sed -e 's/.*= //'
}

nargs ()
{
    echo $#
}

diagconfig ()
{
    [ $(id -u) -eq 0 ] || return 1
    which tw_cli >/dev/null 2>&1 || return 1

    local hosts=$(list_adapt)
    local host=$(list_adapt | tail -1)
    local num=$(nargs $hosts)

    echo "DIAG_TW_NUM=\"$num\""
    if [ $num -gt 0 ]; then
        echo "DIAG_TW_FW=\"$(get_fw $host)\""
    fi
}

diag_handle_args "$@"
[ $(id -u) -eq 0 ] || diag_plan_skip "test requires root"
[ -n "$DIAG_TW_NUM" ] || diag_plan_skip "not configured"
which tw_cli >/dev/null 2>&1 || diag_plan_skip "tw_cli is not installed"
hosts=$(list_adapt)
num=$(nargs $hosts)
diag_plan $(($num + 1))

if [ $num -eq $DIAG_TW_NUM ]; then
    diag_ok "$num cards"
else
    diag_fail "$num cards, expected $DIAG_TW_NUM"
fi
for host in $hosts; do
    fw=$(get_fw $host)
    h=${host##*/}
    if [ -z "$DIAG_TW_FW" ]; then
        diag_skip "$h fw '$fw', expected value not configured"
    elif [ "$fw" != "$DIAG_TW_FW" ]; then
        diag_fail "$h fw '$fw', expected '$DIAG_TW_FW'"
    else
        diag_ok "$h fw '$fw'"
    fi
done

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
