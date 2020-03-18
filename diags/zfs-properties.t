#!/bin/bash
# check that ZFS dataset properties are set as specified

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

declare -r description="Check zfs dataset properties"

# Source functions
source ${NODEDIAGDIR:-/etc/nodediag.d}/functions-tap || exit 1

function diagconfig {
	local idx=0

	for dataset in $(list_datasets); do
		echo "DIAG_ZFS_DATASET_NAME[$idx]=^${dataset}$"
		echo "DIAG_ZFS_RECORDSIZE[$idx]=$(getprop ${dataset} recordsize)"
		echo "DIAG_ZFS_DNODESIZE[$idx]=$(getprop ${dataset} dnodesize)"
		echo "DIAG_ZFS_XATTR[$idx]=$(getprop ${dataset} xattr)"
		echo "DIAG_ZFS_CANMOUNT[$idx]=$(getprop ${dataset} canmount)"
		echo "DIAG_ZFS_COMPRESSION[$idx]=$(getprop ${dataset} compression)"
		echo '#'
		idx=$((idx+1))
	done
}

function getprop {
	local fname="getprop"
	local dataset=$1
	local propname=$2

	if [ -z "$dataset" ]; then
		echo "BUG: $fname missing argument dataset" >&2
		exit 1
	fi

	if [ -z "$propname" ]; then
		echo "BUG: $fname missing argument propname" >&2
		exit 1
	fi

	zfs list -H -o ${propname} ${dataset} 2>/dev/null
}

function verify_property {
	local fname="verify_property"
	local dataset=$1
	local propname=$2
	local expectedval=$3

	if [ -z "$dataset" ]; then
		echo "BUG: $fname missing argument dataset" >&2
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

	propval=$(getprop ${dataset} ${propname})

	if [ -z "${propval}" ] ; then
		diag_fail "dataset ${dataset} property ${propname} does not exist" >&2
	elif [ "${propval}" != ${expectedval} ] ; then
		diag_fail "dataset ${dataset} property ${propname} is ${propval}, expected ${expectedval}" >&2
	else
		diag_ok "dataset ${dataset} property ${propname} is ${propval}" >&2
	fi
}

function handle_test {
	local fname="handle_test"
	local action=$1
	local dataset=$2
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
			verify_property ${dataset} ${propname} ${expectedval}
		fi
	fi
}

function foreach_dataset_and_property {
	local action=$1

	for dataset in $(list_datasets)
	do
		for idx in ${!DIAG_ZFS_DATASET_NAME[@]}
		do
			datasetregex=${DIAG_ZFS_DATASET_NAME[$idx]}

			if [[ ! ${dataset} =~ ${datasetregex} ]]; then
				continue
			fi

			handle_test $action ${dataset} recordsize  ${DIAG_ZFS_RECORDSIZE[$idx]}
			handle_test $action ${dataset} dnodesize   ${DIAG_ZFS_DNODESIZE[$idx]}
			handle_test $action ${dataset} xattr       ${DIAG_ZFS_XATTR[$idx]}
			handle_test $action ${dataset} canmount    ${DIAG_ZFS_CANMOUNT[$idx]}
			handle_test $action ${dataset} compression ${DIAG_ZFS_COMPRESSION[$idx]}

		done
	done
}

function list_datasets {
	zfs list -H | awk '{print $1}'
}

which zfs >/dev/null 2>&1 || diag_plan_skip "zfs not installed"

[ -z "$(list_datasets)" ] &&  diag_plan_skip "no ZFS datasets" >&2

diag_handle_args "$@"

#
# Count tests and declare them
#
num_tests=0
foreach_dataset_and_property count_tests
[ $num_tests -eq 0 ] &&  diag_plan_skip "no ZFS dataset checks" >&2
diag_plan $num_tests

#
# Perform the tests
#

foreach_dataset_and_property  do_tests

exit 0
