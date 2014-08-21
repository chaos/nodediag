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

declare -r description="Check EDAC ECC type"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

nargs ()
{
    echo $#
}
eccglob()
{
    shopt -s nullglob
    echo /sys/devices/system/edac/mc/mc*/csrow*/edac_mode
    shopt -u nullglob
}
firsttype()
{
    local csrows=$(eccglob)

    if [ -n "$csrows" ]; then
        set $csrows
        cat $1
    fi
}
diagconfig ()
{
    local ecctype=$(firsttype)
    [ -z "$ecctype" ] && return 1
    echo "DIAG_ECC_TYPE=\"$ecctype\""
}

diag_handle_args "$@"
[ -n "$DIAG_ECC_TYPE" ] || diag_plan_skip "not configured"

csrows=$(eccglob)
num=$(nargs $csrows)
diag_plan $(($num + 1))
if [ $num -eq 0 ]; then
    diag_fail "ECC is not enabled"
else
    diag_ok "ECC is enabled"
    for csrow in $csrows; do
        ecctype="$(cat $csrow)";
        if [ "$ecctype" != "$DIAG_ECC_TYPE" ]; then
            diag_fail "$csrow: $ecctype, expected $DIAG_ECC_TYPE"
        else
            diag_ok "$csrow: $ecctype"
        fi
    done
fi

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
