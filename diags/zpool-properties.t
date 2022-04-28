#!/bin/bash
# check that ZFS pool properties are set as specified

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

declare -r description="Check zfs pool properties"

# Source functions
source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

function diagconfig {
	local idx=0

	if ! which zpool >/dev/null 2>&1; then
		echo "# zpool command not found"
		return 1
	fi

	for pool in $(list_pools); do
		echo "DIAG_ZPOOL_NAME[$idx]=^${pool}$"
		echo "DIAG_ZPOOL_AUTOREPLACE[$idx]=$(getprop ${pool} autoreplace)"
		echo "DIAG_ZPOOL_MULTIHOST[$idx]=$(getprop ${pool} multihost)"
		echo '#'
		idx=$((idx+1))
	done
}

function getprop {
	local fname="getprop"
	local pool=$1
	local propname=$2

	if [ -z "$pool" ]; then
		echo "BUG: $fname missing argument pool" >&2
		exit 1
	fi

	if [ -z "$propname" ]; then
		echo "BUG: $fname missing argument propname" >&2
		exit 1
	fi

	zpool list -H -o ${propname} ${pool} 2>/dev/null
}

function verify_property {
	local fname="verify_property"
	local pool=$1
	local propname=$2
	local expectedval=$3

	if [ -z "$pool" ]; then
		echo "BUG: $fname missing argument pool" >&2
		exit 1
	fi

	if [ -z "$propname" ]; then
		echo "BUG: $fname missing argument propname" >&2
		exit 1
	fi

	if [ -z "$expectedval" ]; then
		echo "BUG: $fname missing argument expectedval" >&2
		exit 1
	fi

	propval=$(getprop ${pool} ${propname})

	if [ -z "${propval}" ] ; then
		diag_fail "pool ${pool} property ${propname} does not exist" >&2
	elif [ "${propval}" != ${expectedval} ] ; then
		diag_fail "pool ${pool} property ${propname} is ${propval}, expected ${expectedval}" >&2
	else
		diag_ok "pool ${pool} property ${propname} is ${propval}" >&2
	fi
}

function handle_test {
	local fname="handle_test"
	local action=$1
	local pool=$2
	local propname=$3
	local expectedval=$4
	
	if [ -z "$action" ]; then
		echo "BUG: $fname missing argument action" >&2
		exit 1
	fi

	if [ -n "$expectedval" ]; then
		if [ "$action" = "count_tests" ] ; then
			num_tests=$((num_tests+1))
		else
			verify_property ${pool} ${propname} ${expectedval}
		fi
	fi
}

function foreach_pool_and_property {
	local action=$1

	for pool in $(list_pools)
	do
		for idx in ${!DIAG_ZPOOL_NAME[@]}
		do
			poolregex=${DIAG_ZPOOL_NAME[$idx]}

			if [[ ! ${pool} =~ ${poolregex} ]]; then
				continue
			fi

			handle_test $action ${pool} autoreplace ${DIAG_ZPOOL_AUTOREPLACE[$idx]}
			handle_test $action ${pool} multihost   ${DIAG_ZPOOL_MULTIHOST[$idx]}
		done
	done
}

function list_pools {
	zpool list -H | awk '{print $1}'
}

diag_handle_args "$@"

which zpool >/dev/null 2>&1 || diag_plan_skip "zpool command not found"
[ -z "$(list_pools)" ] &&  diag_plan_skip "no ZFS pools" >&2

#
# Count tests and declare them
#
num_tests=0
foreach_pool_and_property count_tests
[ $num_tests -eq 0 ] &&  diag_plan_skip "no ZFS pool checks" >&2
diag_plan $num_tests

#
# Perform the tests
#

foreach_pool_and_property  do_tests

exit 0
