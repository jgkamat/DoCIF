#!/bin/bash
# Builds our circle image which runs tests
set -e
DIR=$(cd $(dirname $0) ; pwd -P)

source ${DIR}/../util/docker_common.sh
TEST_CMD="maketest.sh"

if [ "$1" = "--pending" ]; then
	TEST_CMD="${TEST_CMD} --pending"
fi

# Wait for push to finish if possible
wait_push() {
	if [ -r "${TMP_FOLDER}/push_baseimage.lock" ]; then
		echo "[INFO] Waiting for the baseimage push to complete."

		set +e

		COUNTER=0
		TIMEOUT=600
		# Wait for the push to baseimage to finish
		if [ -f ${TMP_FOLDER}/push_baseimage.lock ]; then
			while [ -z "$(cat ${TMP_FOLDER}/push_baseimage.lock)" ]; do
				sleep 1
				COUNTER="$(expr "$COUNTER" + 1)"
				if [ "$COUNTER" -gt "$TIMEOUT" ]; then
					# Break out of loop by forcing a failure
					echo "[ERR] Push command timed out!" >&2
					echo "1" > "${TMP_FOLDER}/push_baseimage.lock"
				fi
			done
		fi

		if [ "$(cat ${TMP_FOLDER}/push_baseimage.lock)" -ne 0 ]; then
			echo "[WARN] The push to the source repository FAILED. This usually means the dockerhub is down." >&2
		fi
		set -e

		rm -f ${TMP_FOLDER}/push_baseimage.lock
	fi
}

trap "wait_push" EXIT

clean_cid_file "${TMP_FOLDER}/docif_tests.cid"

set +e
docker run \
	--cidfile="${TMP_FOLDER}/docif_tests.cid" \
	$(eval echo \"$(${DIR}/../util/docker_common.sh print_cache_flags)\") \
	-v ${PROJECT_ROOT}:${GIT_CLONE_ROOT} \
	-v ${CIRCLE_ARTIFACTS:-/tmp/}:/tmp/build_artifacts \
	$(eval echo \"$(${DIR}/../util/docker_common.sh print_environment_flags)\") \
	-e ${GH_USER_VAR}=${GH_USERNAME} \
	-e ${GH_EMAIL_VAR}=${GH_EMAIL} \
	-e ${GH_STATUS_TOKEN_VAR}=${GH_STATUS_TOKEN} \
	${BASEIMAGE_REPO}:${CACHING_SHA:-latest} \
	sh -c "${GIT_CLONE_ROOT}$(echo ${DOCIF_ROOT} | sed "s%${PROJECT_ROOT}%%g")/util/${TEST_CMD}"

EXIT=$?
set -e


if [ ! -f "${TMP_FOLDER}/docif_tests.cid" ]; then
	echo "[ERR] Your tests command did not produce a usable container. This is likely a config or infra issue." >&2
	exit 1
fi

# Commit the latest image
docker commit "$(cat ${TMP_FOLDER}/docif_tests.cid)" ${IMAGE_NAME_CI}:${COMMIT_SHA}
rm -f "${TMP_FOLDER}/docif_tests.cid"

if [ $EXIT -ne 0 ]; then
	# Always pass this test (the other te
	exit "$EXIT"
fi

