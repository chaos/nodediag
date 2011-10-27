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

declare -r description="Check Single Bit Memory Error Count" 

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

diagconfig ()
{
    which edac-util 2>/dev/null 1>&2 || return 1
    
    if edac-util -s >/dev/null; then
        echo "DIAG_SBE_COUNT=\"500\""
    else
        return 1
    fi
}

diag_handle_args "$@"

which edac-util 2>/dev/null 1>&2 || diag_plan_skip "edac-util is not installed"
[ -n "$DIAG_SBE_COUNT" ] || diag_plan_skip "not configured"
diag_plan 1

# per Trent: CE count of each reported FRU is compared against the threshold
# FIXME: divide into multiple tests to get more specific data in output?
fail=0
for count in $(edac-util|awk '/Corrected Errors$/ {print $4}'); do
    diag_msg "single bit errors: $count"
    if [ $count -gt ${DIAG_SBE_COUNT} ]; then
        diag_fail "$count SBEs exceeds threshold \(${DIAG_SBE_COUNT}\)"
        # exits
    fi
done
diag_ok "all counts under threshold"

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
