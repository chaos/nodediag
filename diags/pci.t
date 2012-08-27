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

declare -r description="Check PCI cards"

source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

normalize_whitespace()
{
  sed -e 's/#.*//' -e 's/[[:space:]]\+/\ /g' \
      -e 's/[[:space:]]\+$//g' -e 's/^[[:space:]]\+//g'
}
getname()
{
  lspci -s $1 2>/dev/null| awk -F':' '{print $3}'|normalize_whitespace
}

# Get bus width for specified slot
getspeed()
{
  lspci -s $1 -vv 2>/dev/null| awk '{gsub(",","")} /LnkSta:/ {print $3}'
}

# Get bus width for specified slot
getwidth()
{
  lspci -s $1 -vv 2>/dev/null| awk '{gsub(",","")} /LnkSta:/ {print $5}'
}

# List pci slots, filtering out bridges and common built-in devices
lspci_filtered()
{
  local line

  lspci -m | while read line; do
  eval set $line
  case "$2" in
    "PCI bridge"|"Host bridge"|"ISA bridge"|"SMBus"|"RAM memory"|"USB Controller"|"IDE interface")
      ;;
    *)
      echo $1
      ;;
  esac
done
}
diagconfig()
{
    [ $(id -u) -eq 0 ] || return 1
    which lspci >/dev/null 2>&1 || return 1

    local location name speed width
    local i=0

    shopt -s nullglob
    for dev in $(lspci_filtered); do
        speed=$(getspeed $dev)
        [ "$speed" != "unknown" ] && [ ! -z "$speed" ] || continue
        name=$(getname $dev)
        width=$(getwidth $dev)
        echo "DIAG_PCI_SLOT[$i]=\"$dev\""
        echo "DIAG_PCI_NAME[$i]=\"$name\""
        echo "DIAG_PCI_SPEED[$i]=\"$speed\""
        echo "DIAG_PCI_WIDTH[$i]=\"$width\""
        echo '#'
        i=$(($i+1))
    done
    shopt -u nullglob
}

diag_handle_args "$@"
numdev=${#DIAG_PCI_SLOT[@]}
[ $(id -u) -eq 0 ] || diag_plan_skip "test requires root"
which lspci >/dev/null 2>&1 || diag_plan_skip "lspci is not installed"
[ $numdev -gt 0 ] || diag_plan_skip "not configured"
diag_plan $(($numdev * 3))

for i in $(seq 0 $(($numdev - 1))); do
    location=${DIAG_PCI_SLOT[$i]}
    name=$(echo ${DIAG_PCI_NAME[$i]}|normalize_whitespace)
    speed=${DIAG_PCI_SPEED[$i]}
    width=${DIAG_PCI_WIDTH[$i]}

    if [ -n "$name" ] && [ -n "$location" ] ; then
        gotname=$(getname $location)
        if [ "$name" != "$gotname" ] && ! [[ "$gotname" =~ $name ]]; then
            diag_fail "$location name $gotname, expected $name"
        else
            diag_ok "$location name $gotname"
        fi
    else
        diag_skip "$location name not configured"
    fi

    if [ -n "$speed" ] && [ -n "$location" ] ; then
        gotspeed=$(getspeed $location)
        if [ "$speed" != "$gotspeed" ]; then
            diag_fail "$location speed $gotspeed, expected $speed"
        else
            diag_ok "$location speed $gotspeed"
        fi
    else
        diag_skip "$location speed not configured"
    fi

    if [ -n "$width" ] && [ -n "$location" ] ; then
        gotwidth=$(getwidth $location)
        if [ "$width" != "$gotwidth" ]; then
            diag_fail "$location width $gotwidth, expected $width"
        else
            diag_ok "$location width $gotwidth"
        fi
    else
        diag_skip "$location width not configured"
    fi

done
exit 0

# vi: expandtab sw=4 ts=4
# vi: syntax=sh
