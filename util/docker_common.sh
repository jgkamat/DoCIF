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
	echo "An internal error occured. Please report this"
}

# TODO check to see if outside repo actually exists
get_repo_root() {
	# Get outside of DoCIF
	cd ${DOCIF_DIR}/../
	echo $(git rev-parse --show-toplevel)
}

# Run commands if requested
while (( ${#} )); do
	case "${1}" in
		get_repo_root )
			get_repo_root; shift 1 ;;
		* )
			usage >&2; break ;;
	esac
done
