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

declare -r description="Check Clock Source type"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

get_clocksources()
{
    local dir
    shopt -s nullglob
    for dir in /sys/devices/system/clocksource/clocksource*; do
        cat $dir/current_clocksource
    done
    shopt -u nullglob
}

diagconfig()
{
    local cs=$(get_clocksources | tail -1)

    if [ -n "$cs" ]; then
        echo "DIAG_CLOCKSOURCE=\"$cs\""
    fi
}

diag_handle_args "$@"
[ -n "$DIAG_CLOCKSOURCE" ] || diag_plan_skip "not configured"

diag_plan $(get_clocksources | wc -w)

for src in $(get_clocksources); do
    if [ "$src" != "$DIAG_CLOCKSOURCE" ]; then
        diag_fail "clocksource $src, expected $DIAG_CLOCKSOURCE"
    else    
        diag_ok "clocksource $src"
    fi
done

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
