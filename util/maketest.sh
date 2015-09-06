#!/bin/bash
# Runs tests and reports on them to github

DIR=$(cd $(dirname $0) ; pwd -P)
source ${DIR}/docker_common.sh

# Get sha sum
SUCCESS=true
LINK_PREFIX="https://circle-artifacts.com/gh/${GITHUB_REPO}/$CIRCLE_BUILD_NUM/artifacts/0$CIRCLE_ARTIFACTS/"
ARTIFACT_DIR="/tmp/build_artifacts"
PENDING=false
SHORTNAMES=( )

start_pending() {
	if [ -z "$GH_USERNAME" -o -z "$GH_STATUS_TOKEN" ]; then
		echo "[WARN] GH_STATUS TOKEN or USERNAME empty. Not updating statuses." >&2
		return 0
	fi

	SHORTNAME="$1"
	>/dev/null curl -s -u $GH_USERNAME:$GH_STATUS_TOKEN \
	 -X POST https://api.github.com/repos/${GITHUB_REPO}/statuses/${SHA_SUM} \
	 -H "Content-Type: application/json" \
	 -d '{"state":"pending", "description": "This check is pending. Please wait.", "context": '"\"circle/$SHORTNAME\""', "target_url": "'"${PENDING_URL}"'"}'
}

# A function to run a command. Takes in a command name, shortname and description.
ci_task() {
	CMD="$(echo $@ | awk 'BEGIN { FS = ";" } ; { print $1 }')"
	SHORTNAME="$(echo $@ | awk 'BEGIN { FS = ";" } ; { print $2 }')"
	DESCRIPTION="$(echo $@ | awk 'BEGIN { FS = ";" } ; { print $3 }')"

	SHORTNAMES+=("${SHORTNAME}")

	if [ "$PENDING" = "true" ]; then
		return 0
	fi

	${CMD} 2>&1 | tee "${ARTIFACT_DIR}/${SHORTNAME}.txt"

	if [ -z "$GH_USERNAME" -o -z "$GH_STATUS_TOKEN" ]; then
		echo "[WARN] GH_STATUS TOKEN or USERNAME empty. Not updating statuses." >&2
		return 0
	fi

	if [ "${PIPESTATUS[0]}" = "0" ]; then
		>/dev/null curl -s -u $GH_USERNAME:$GH_STATUS_TOKEN \
		 -X POST https://api.github.com/repos/${GITHUB_REPO}/statuses/${SHA_SUM} \
		 -H "Content-Type: application/json" \
		 -d '{"state":"success", "description": '"\"${DESCRIPTION}\""', "context": '"\"circle/${SHORTNAME}\""', "target_url": '""\"${LINK_PREFIX}${SHORTNAME}.txt\""}"
	else
		>/dev/null curl -s -u $GH_USERNAME:$GH_STATUS_TOKEN \
		 -X POST https://api.github.com/repos/${GITHUB_REPO}/statuses/${SHA_SUM} \
		 -H "Content-Type: application/json" \
		 -d '{"state":"failure", "description": '"\"${DESCRIPTION}\""', "context": '"\"circle/${SHORTNAME}\""', "target_url": '""\"${LINK_PREFIX}${SHORTNAME}.txt\""}"
		SUCCESS=false
	fi
}

if [ "$1" = "--pending" ]; then
	PENDING=true
fi

# Go to root so we can make.
cd ${PROJECT_ROOT}

# Clean
sh -c "$CLEAN_COMMAND"
git submodule update --init
for i in ${CACHE_DIRECTORIES[@]}; do
	# Use ${HOME} in this case
	i="$(echo $i | sed 's/~/${HOME}/')"
	sudo chown -R `whoami`:`whoami` "$(eval echo "$i")"
done

for i in ${TEST_COMMANDS[@]}; do
	ci_task "$i"
done

# This script needs to be run prior with the --pending flag if you want to see pending flags
if [ "$PENDING" = "true" ]; then
	for i in ${SHORTNAMES[*]}; do
		start_pending ${i}
	done
fi

if $SUCCESS; then
	exit 0
fi
exit 1
