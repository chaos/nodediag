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

declare -r description="Check installed memory speed"
declare -r sanity=1

source /etc/nodediag.d/functions

# Note: skip flash devices (speed < 100mhz)
getmemspeed()
{
    local n

    for n in `diag_dmi_stanza "Memory Device" | awk '/Speed:/ { print $2 }'`; do
        [ "$n" != "Unknown" ] && [ $n -gt 100 ] && echo "$n"
    done
}

diagconfig()
{
    local speed=`getmemspeed | tail -1`
   
    [ -n "$speed" ] || return 1
    echo "DIAG_MEMSPEED_MHZ=\"$speed\""
}

diag_handle_args "$@"
diag_check_root
diag_check_defined "DIAG_MEMSPEED_MHZ"

for speed in `getmemspeed`; do
    if [ "$speed" != "$DIAG_MEMSPEED_MHZ" ]; then
        diag_fail "device $speed MHz, expected $DIAG_MEMSPEED_MHZ MHz"
    fi
done
diag_ok "device $speed MHz"
