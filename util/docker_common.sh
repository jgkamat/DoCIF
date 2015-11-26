#!/bin/bash
#
# Provides common vars if sourced, provides commonly used function if run with args
set -e
COMMON_DIR=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/
DOCIF_ROOT=$(cd ${COMMON_DIR} && git rev-parse --show-toplevel)

usage() {
	echo "An internal error occured. Please report this."
}

get_repo_root() {
	# Get outside of DoCIF
	cd ${DOCIF_ROOT}/../
	if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
		echo "[ERR] DoCIF is not within a git repository and cannot continue." >&2
		exit 1
	fi
	echo $(git rev-parse --show-toplevel)
}

PROJECT_ROOT="$(get_repo_root)"

gen_temp() {
	# Generates a tmp folder if one does not exist yet.
	if [ -r "/tmp/docif.tmp" ] && [ -d "$(cat /tmp/docif.tmp)" ]; then
		TMP_LOC="$(cat /tmp/docif.tmp)"
	else
		TMP_LOC="$(mktemp -d /tmp/docif.XXXXXXXX)"
		echo "$TMP_LOC" > /tmp/docif.tmp
	fi
	echo "$TMP_LOC"
}

# set TMP_FOLDER
TMP_FOLDER="$(gen_temp)"

run_in_project() {
	cd ${PROJECT_ROOT}
	$@
}

# Checks to see if a variable is empty or not
check_variable() {
	if [ -z "$(eval echo "\$${1}")" ]; then
		echo "[ERR] $1 was missing from your config file. DoCIF cannot continue." >&2
		exit 1
	fi
}

# Source docif config
source_config() {
	cd ${PROJECT_ROOT}
	if [ -f "config.docif" ]; then
		source config.docif
	elif [ -n "$(ls *.docif | head -n1)" ]; then
		source "$(ls *.docif | head -n1)"
	else
		echo "[ERR] No docif config could be found! Exiting!" >&2
		exit 1
	fi
}

get_setup_sha() {
	if [ -z "${SETUP_SHA_FILES[*]}" ]; then
		echo "[WARN] No SHA Files found, caching will not take place" >&2
		return 0
	fi
	for i in "${SETUP_SHA_FILES[@]}"; do
		# prevent variable errors later
		i="$i"
		if [ ! -r $i ]; then
			echo "[ERR] $i was not readable, cannot SHA. Exiting" >&2
			exit 1
		fi
	done
	cd ${PROJECT_ROOT}
	cat ${SETUP_SHA_FILES[*]} | sha256sum | awk '{print $1}'
}

get_commit_sha() {
	cd ${PROJECT_ROOT}
	echo "$(git rev-parse HEAD)"
}

# Source config file!
source_config
CACHING_SHA="$(get_setup_sha)"
COMMIT_SHA="$(get_commit_sha)"
check_variable "TEST_COMMANDS"


print_environment_flags() {
	for i in "${ENV_VARS[@]}"; do
		printf " -e \"${i}\"=\"\${$i}\" "
	done
	printf "\n"
}

print_cache_flags() {
	for i in "${CACHE_DIRECTORIES[@]}"; do
		printf " -v $(echo $i | sed 's/~/${HOME}/' | sed 's/^\./$(pwd)/'):$(echo $i | sed 's%~%/home/developer%' | sed "s%^\.%${DOCKER_PROJECT_ROOT}%") "
	done
	printf "\n"
}

# This converts our secrets to standard variables we can use throughout DoCIF
standardize_env_vars() {
	# Any of these could be empty if you wanted, that turns off features though.
	DOCKER_PASSWORD="$(eval echo "\$${DOCKER_PASSWORD_VAR}")"
	DOCKER_EMAIL="$(eval echo "\$${DOCKER_EMAIL_VAR}")"
	DOCKER_USERNAME="$(eval echo "\$${DOCKER_USER_VAR}")"
	GH_STATUS_TOKEN="$(eval echo "\$${GH_STATUS_TOKEN_VAR}")"
	GH_USERNAME="$(eval echo "\$${GH_USER_VAR}")"
	GH_EMAIL="$(eval echo "\$${GH_EMAIL_VAR}")"
	PENGING_URL="${PENDING_URL:-"https://github.com/jgkamat/DoCIF"}"
	CLEAN_COMMAND="${CLEAN_COMMAND:-"true"}"
	PUSH_BASEIMAGE="${PUSH_BASEIMAGE:-"false"}"
	DOCKER_PROJECT_ROOT="${DOCKER_PROJECT_ROOT:-"/home/developer/project"}"
	GIT_CLONE_ROOT="${GIT_CLONE_ROOT:-"${DOCKER_PROJECT_ROOT}"}"

	if [ -z "$ENV_VARS" ]; then
		ENV_VARS=()
	fi
	ENV_VARS+=("CIRCLE_BUILD_NUM")
	ENV_VARS+=("CIRCLE_ARTIFACTS")
	if [ -z "${CUSTOM_DOCKERFILE}" ]; then
		DOCKERFILE="${DOCIF_ROOT}/commands/Dockerfile"
	else
		DOCKERFILE="${PROJECT_ROOT}/${CUSTOM_DOCKERFILE}"
	fi
}

standardize_env_vars
# Don't run things if being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Run commands if requested
	while (( ${#} )); do
		case "${1}" in
			get_repo_root )
				get_repo_root; shift 1 ;;
			caching_sha )
				echo $CACHING_SHA; shift 1 ;;
			run_in_project )
				run_in_project ${2}; shift 2 ;;
			print_environment_flags )
				print_environment_flags; shift 1 ;;
			print_cache_flags )
				print_cache_flags; shift 1 ;;
			* )
				usage >&2; exit 1;;
		esac
	done
fi
