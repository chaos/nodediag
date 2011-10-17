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
declare -r sanity=1

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions

diagconfig ()
{
    if edac-util -s >/dev/null; then
        echo "DIAG_SBE_COUNT=\"500\""
    else
        return 1
    fi
}

diag_handle_args "$@"
diag_check_defined "DIAG_SBE_COUNT"

# CE count of each reported FRU is compared against the threshold
for count in $(edac-util|awk '/Corrected Errors$/ {print $4}'); do
    if [ $count -gt ${DIAG_SBE_COUNT} ]; then
        diag_fail "$count SBEs exceeds threshold \(${DIAG_SBE_COUNT}\)"
    fi
done
diag_ok "all counts under threshold"
