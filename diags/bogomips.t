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

declare -r description="Check CPU bogomips"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

getbogomips ()
{
    awk '/bogomips[[:space:]]:/ {printf "%.0f\n",$3}' /proc/cpuinfo
}

diagconfig ()
{
    local val=`getbogomips|tail -1`

    echo "DIAG_BOGOMIPS_TARGET=$val"
    echo "DIAG_BOGOMIPS_PLUSMINUS=`expr $val / 1000`"
}

diag_handle_args "$@"
[ -n "$DIAG_BOGOMIPS_TARGET" ] || diag_plan_skip "not configured"
[ -n "$DIAG_BOGOMIPS_PLUSMINUS" ] || diag_plan_skip "not configured"


diag_plan 1

declare -i bm
declare -i bogomips_failed=0
for bm in $(getbogomips); do
    if [ `expr $bm + $DIAG_BOGOMIPS_PLUSMINUS` -lt $DIAG_BOGOMIPS_TARGET ] \
    || [ `expr $bm - $DIAG_BOGOMIPS_PLUSMINUS` -gt $DIAG_BOGOMIPS_TARGET ]; then
        diag_fail "$bm is out of range, expected $DIAG_BOGOMIPS_TARGET +/- $DIAG_BOGOMIPS_PLUSMINUS"
        bogomips_failed=1
        break
    fi
done
[ $bogomips_failed -eq 0 ] && diag_ok "all cpus are within +/- $DIAG_BOGOMIPS_PLUSMINUS of $DIAG_BOGOMIPS_TARGET" 

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
