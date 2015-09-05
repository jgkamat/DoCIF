#!/bin/bash
#
# Provides common vars if sourced, provides commonly used function if run with args
set -e

COMMON_DIR=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/
DOCIF_DIR=$(cd ${COMMON_DIR} && git rev-parse --show-toplevel)

# TODO replace with project root
ROBOCUP_ROOT="${COMMON_DIR}/../../"
# Get sha sum
# SHA_SUM_SETUP="$(${ROBOCUP_ROOT}/util/docker/getsetupsha.sh)"
# SHA_SUM="$(git rev-parse HEAD)"
# TODO replace with proper vars
# IMAGE_NAME_CI="robojackets/robocup-ci"
# IMAGE_NAME_BASE="robojackets/robocup-baseimage"

usage() {
    echo "An internal error occured. Please report this."
}

# TODO check to see if outside repo actually exists
get_repo_root() {
    # Get outside of DoCIF
    cd ${DOCIF_DIR}/../

	if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
		echo "[ERR] DoCIF is not within a git repository and cannot continue." >&2
		exit 1
	fi

    echo $(git rev-parse --show-toplevel)
}

PROJECT_DIR="$(get_repo_root)"

run_in_project() {
    cd ${PROJECT_DIR}
    $@
}

# Checks to see if a variable is empty or not
check_variable() {
    if [ -z "$(eval echo \$${1})" ]; then
		echo "[ERR] $1 was missing from your config file. DoCIF cannot continue." >&2
		exit 1
	fi
}

# Checks to see if mandatory variables are present.
check_inputs() {
	check_variable TEST_COMMANDS
}

# Source docif config
source_config() {
	cd ${PROJECT_DIR}
	if [ -f "config.docif" ]; then
		source config.docif
	elif [ -n "$(ls "*.docif" | head -n1)" ]; then
		source "$(ls "*.docif" | head -n1)"
	else
		echo "[ERR] No docif config could be found! Exiting!" >&2
		exit 1
	fi
}

# Run commands if requested
while (( ${#} )); do
    case "${1}" in
	get_repo_root )
	    get_repo_root; shift 1 ;;
	run_in_project )
	    run_in_project ${2}; shift 2 ;;
	* )
	    usage >&2; exit 1;;
    esac
done
