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

declare -r description="Check installed memory type"
declare -r sanity=1

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions

# Note: skip flash devices
getmemtype()
{
    local n

    for n in `diag_dmi_stanza "Memory Device" | awk '/Type:/ { print $2 }'`; do
        [ "$n" != "Unknown" ] && [ "$n" != "Flash" ] && echo "$n"
    done
}

diagconfig()
{
    local memtype=`getmemtype|tail -1`

    [ -n "$memtype" ] || return 1
    echo "DIAG_MEMTYPE_NAME=\"$memtype\""
}

diag_handle_args "$@"
diag_check_root
diag_check_defined "DIAG_MEMTYPE_NAME"

for name in `getmemtype`; do
    if [ "$name" != "$DIAG_MEMTYPE_NAME" ]; then
        diag_fail "device $name, expected $DIAG_MEMTYPE_NAME"
    fi
done
diag_ok "device $name"
