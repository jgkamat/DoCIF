#!/bin/bash
#
# Runs tests and reports on them to github
#
# USAGE: ./maketest [--pending | --fail]

DIR=$(cd $(dirname $0) ; pwd -P)
source ${DIR}/docker_common.sh

# Get sha sum
SUCCESS=true
# Allow for use of the link_prefix in other programs, if they need it
export LINK_PREFIX="https://circle-artifacts.com/gh/${GITHUB_REPO}/${CIRCLE_BUILD_NUM}/artifacts/0$CIRCLE_ARTIFACTS/"
ARTIFACT_DIR="/tmp/build_artifacts"
mkdir -p ${ARTIFACT_DIR}
PENDING=false
FAIL_ALL_TESTS=false
SHORTNAMES=( )

if [ -z "$GH_USERNAME" -o -z "$GH_STATUS_TOKEN" ]; then
	echo "[WARN] GH_STATUS TOKEN or USERNAME empty. Not updating statuses." >&2
	SEND_STATUS_TOKENS=false
else
	SEND_STATUS_TOKENS=true
fi

start_pending() {
	if ! $SEND_STATUS_TOKENS; then
		return 0
	fi

	SHORTNAME="$1"
	>/dev/null curl -s -u $GH_USERNAME:$GH_STATUS_TOKEN \
		-X POST https://api.github.com/repos/${GITHUB_REPO}/statuses/${COMMIT_SHA} \
		-H "Content-Type: application/json" \
		-d '{"state":"pending", "description": "This check is pending. Please wait.", "context": '"\"circle/$SHORTNAME\""', "target_url": "'"${PENDING_URL}"'"}'
}

fail_test() {
	if ! $SEND_STATUS_TOKENS; then
		return 0
	fi

	SHORTNAME="$1"
	>/dev/null curl -s -u $GH_USERNAME:$GH_STATUS_TOKEN \
		-X POST https://api.github.com/repos/${GITHUB_REPO}/statuses/${COMMIT_SHA} \
		-H "Content-Type: application/json" \
		-d '{"state":"failure", "description": "This check failed due to an internal error.", "context": '"\"circle/$SHORTNAME\""', "target_url": "'"${PENDING_URL}"'"}'
}

# A function to run a command. Takes in a command name, shortname and description.
ci_task() {
	CMD="$(echo $@ | awk 'BEGIN { FS = ";" } ; { print $1 }')"
	SHORTNAME="$(echo $@ | awk 'BEGIN { FS = ";" } ; { print $2 }')"
	DESCRIPTION="$(echo $@ | awk 'BEGIN { FS = ";" } ; { print $3 }')"

	SHORTNAMES+=("${SHORTNAME}")

	if [ "$PENDING" = "true" -o "$FAIL_ALL_TESTS" = "true" ]; then
		return 0
	fi


	bash -c "${CMD} 2>&1" | tee "${ARTIFACT_DIR}/${SHORTNAME}.txt"
	CMD_STATUS=${PIPESTATUS[0]}

	if [ "${CMD_STATUS}" = "0" ]; then
		if $SEND_STATUS_TOKENS; then
			>/dev/null curl -s -u $GH_USERNAME:$GH_STATUS_TOKEN \
			 -X POST https://api.github.com/repos/${GITHUB_REPO}/statuses/${COMMIT_SHA} \
			 -H "Content-Type: application/json" \
			 -d '{"state":"success", "description": '"\"${DESCRIPTION}\""', "context": '"\"circle/${SHORTNAME}\""', "target_url": '""\"${LINK_PREFIX}${SHORTNAME}.txt\""}"
		fi
		RETURN="passed"
	else
		if $SEND_STATUS_TOKENS; then
			>/dev/null curl -s -u $GH_USERNAME:$GH_STATUS_TOKEN \
			 -X POST https://api.github.com/repos/${GITHUB_REPO}/statuses/${COMMIT_SHA} \
			 -H "Content-Type: application/json" \
			 -d '{"state":"failure", "description": '"\"${DESCRIPTION}\""', "context": '"\"circle/${SHORTNAME}\""', "target_url": '""\"${LINK_PREFIX}${SHORTNAME}.txt\""}"
		fi
		# Fail all tests once completed
		SUCCESS=false

		RETURN="failed"
	fi
}

if [ "$1" = "--pending" ]; then
	PENDING=true
elif [ "$1" = "--fail" ]; then
	FAIL_ALL_TESTS=true
fi

if [ "$PENDING" != "true" ]; then
	(
		# If we are in the container, go to the git root
		cd ${GIT_CLONE_ROOT}
		# TODO figure out if we really need this. This really should be done before DoCIF even runs.
		git submodule sync && git submodule update --init || true && git submodule sync && git submodule update --init
	)
else
	# If we are in the host, just go for it (we're already at the git root)
	git submodule sync && git submodule update --init || true && git submodule sync && git submodule update --init
fi

# Go to root so we can make.
if [ "$PENDING" != "true" ]; then
	# We don't want to CD during the pending phase, as we are not in the docker container yet
	cd ${DOCKER_PROJECT_ROOT}
fi

# Clean
for i in "${CACHE_DIRECTORIES[@]}"; do
	i="$(echo $i | sed 's/~/${HOME}/')"		# Sanitize i
	i="$(eval echo "$i")"
	if [ -d "$i" ]; then
		sudo chown -R `whoami`:`whoami` "$i"
	else
		echo "[WARN] Cache directory '$i' not found! Creating an empty one." >&2
		mkdir -p "$i"
		sudo chown -R `whoami`:`whoami` "$i"
	fi
done

if [ "$PENDING" != "true" ]; then
	sh -c "$CLEAN_COMMAND"
fi

TBL_RESULTS=""
for i in "${TEST_COMMANDS[@]}"; do
	RETURN="pending"
	ci_task "$i"
	TBL_RESULTS="$(printf "%s\n%s%s%s" "$TBL_RESULTS" "$i" ";" "$RETURN")"
done

# This script needs to be run prior with the --pending flag if you want to see pending flags
if [ "$PENDING" = "true" ]; then
	for i in "${SHORTNAMES[@]}"; do
		start_pending ${i}
	done
fi

if [ "$FAIL_ALL_TESTS" = "true" ]; then
	for i in "${SHORTNAMES[@]}"; do
		fail_test ${i}
	done
fi

if command -v column >/dev/null 2>&1; then
	printf "\nResults:\n"
	printf "%s\n" "$TBL_RESULTS" | column -t -s ';'
fi

if $SUCCESS; then
	exit 0
fi
exit 1
