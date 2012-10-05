#!/bin/bash
##############################################################################
# Copyright (c) 2011, Lawrence Livermore National Security, LLC.
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
#
# To add a dmi test:
# 1) Add your dmi_check () line to main
# 2) Add corresponding dmi_config () line to diagconfig ()
# 3) Increment the diag_plan () parameter
#
# N.B. values in the sysconfig file that are to be tested can contain regex
# characters.  First a direct match is tested, then a regex.  This creates
# some ambiguity but it allows the direct match to contain regex chars
# e.g. "Opteron(tm)" in cputype.
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin
declare -r description="Check dmi table values"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

# Usage: ...|diag_normalize_whitespace
# Remove any hash delimited comments and convert any amount of whitespace
# into one space.  Remove leading and trailing spaces.
dmi_normalize_whitespace()
{
    sed -e 's/#.*//' -e 's/[[:space:]]\+/\ /g' -e 's/[[:space:]]\+$//g' \
                                               -e 's/^[[:space:]]\+//g'
}

# Usage: diag_test_dmi keyword wantval
# Check if all values of keyword in dmitable match wantval.
dmi_check()
{
    local keyword="$1"
    shift
    local wantval=$(echo $* |dmi_normalize_whitespace)
    local val=$(dmidecode -s $keyword|tail -1|dmi_normalize_whitespace)
    if [ -z "$wantval" ]; then
        diag_skip "$keyword not configured"
    elif [ "$val" != "$wantval" ] && ! [[ "$val" =~ $wantval ]]; then
        diag_fail "$keyword is '$val', expected '$wantval'"
    else
        diag_ok "$keyword is '$val'"
    fi
}

# Usage: dmi_stanza "<stanza title>"
# Filters dmidecode output by stanza title.
dmi_stanza()
{
    dmidecode | awk '/'"$1"'$/,/^$/'
}

getmemtot()
{
    local n
    local total=0

    for n in `dmi_stanza "Memory Device" | awk '/Size:.*MB/ { print $2 }'`; do
        [ "$n" != "No" ] && total=$(($total + $n))
    done
    echo $total
}

getmemtype()
{
    local n

    for n in $(dmi_stanza "Memory Device" | awk '/Type:/ { print $2 }'); do
        [ "$n" != "Unknown" ] && [ "$n" != "Flash" ] && echo "$n"
    done
}

# Note: skip flash devices (speed < 100mhz)
getmemspeed()
{
    local n

    for n in $(dmi_stanza "Memory Device" | awk '/\tSpeed:/ { print $2 }'); do
        [ "$n" != "Unknown" ] && [ $n -gt 100 ] && echo "$n"
    done
}

dmi_check_memtot()
{
    local wantval="$1"

    if [ -z "$wantval" ]; then
        diag_skip "memtot not configured"
        return
    fi
    local memtot=$(getmemtot)
    if [ "$memtot" != "$wantval" ] && ! [[ "$memtot" =~ $wantval ]]; then
        diag_fail "memtot is '$memtot' MB, expected '$wantval' MB"
        return
    fi
    diag_ok "memtot is '$memtot' MB"
}

dmi_check_memtype()
{
    local wantval="$1"
    local name
    local i=0

    if [ -z "$wantval" ]; then
        diag_skip "memtype not configured"
        return
    fi
    for name in $(getmemtype); do
        i=$(($i + 1))
        if [ "$name" != "$wantval" ] && ! [[ "$name" =~ $wantval ]]; then
            diag_fail "memtype($i) is '$name', expected '$wantval'"
            return
        fi
    done
    diag_ok "memtype($i) is '$name'"
}

dmi_check_memspeed()
{
    local wantval="$1"
    local speed
    local i=0

    if [ -z "$wantval" ]; then
        diag_skip "memspeed not configured"
        return
    fi
    for speed in $(getmemspeed); do
        i=$(($i + 1))
        if [ "$speed" != "$wantval" ] && ! [[ "$speed" =~ $wantval ]]; then
            diag_fail "memspeed($i) '$speed' MHz, expected '$wantval' MHz"
            return
        fi
    done
    diag_ok "memspeed($i) is '$speed' MHz"
}

# Usage: diag_config_dmi keyword variable
dmi_config()
{
    local val=$(dmidecode -s $1|tail -1|dmi_normalize_whitespace)
    echo "$2=\"$val\""
} 

diagconfig ()
{
    [ "$(id -u)" -eq 0 ] || return 1
    which dmidecode >/dev/null 2>&1 || return 1

    dmi_config bios-release-date        "DIAG_BIOS_DATE"
    dmi_config processor-frequency      "DIAG_CPUFREQ_MHZ"
    dmi_config processor-version        "DIAG_CPU_VERSION"
    dmi_config baseboard-product-name   "DIAG_MOTHERPROD_NAME"
    dmi_config baseboard-version        "DIAG_MOTHERVER_NUM"

    local memtype=$(getmemtype|tail -1)
    if [ -n "$memtype" ]; then
        echo "DIAG_MEMTYPE_NAME=\"$memtype\""
    fi

    local memspeed=$(getmemspeed | tail -1)
    if [ -n "$memspeed" ]; then
        echo "DIAG_MEMSPEED_MHZ=\"$memspeed\""
    fi

    local memtot=$(getmemtot)
    if [ -n "$memtot" ]; then
        echo "DIAG_MEMORY_TOTAL_MB=\"$memtot\""
    fi 
}

##
## MAIN
##

diag_handle_args "$@"
[ "$(id -u)" -eq 0 ] || diag_plan_skip "test requires root"
which dmidecode >/dev/null 2>&1 || diag_plan_skip "dmidecode not installed"

diag_plan 8

dmi_check bios-release-date         "${DIAG_BIOS_DATE}"
dmi_check processor-frequency       "${DIAG_CPUFREQ_MHZ}"
dmi_check processor-version         "${DIAG_CPU_VERSION}"
dmi_check baseboard-product-name    "${DIAG_MOTHERPROD_NAME}"
dmi_check baseboard-version         "${DIAG_MOTHERVER_NUM}"
dmi_check_memtot                    "${DIAG_MEMORY_TOTAL_MB}"
dmi_check_memtype                   "${DIAG_MEMTYPE_NAME}"
dmi_check_memspeed                  "${DIAG_MEMSPEED_MHZ}"

exit 0

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
