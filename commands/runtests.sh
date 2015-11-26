#!/bin/bash
# Builds our circle image which runs tests
set -e
DIR=$(cd $(dirname $0) ; pwd -P)
source ${DIR}/../util/docker_common.sh
TEST_CMD="maketest.sh"
if [ "$1" = "--pending" ]; then
	TEST_CMD="${TEST_CMD} --pending"
fi
# Entrypiont is needed to preserve exit code
docker run \
	--cidfile="${TMP_FOLDER}/docif_tests.cid" \
	$(eval echo \"$(${DIR}/../util/docker_common.sh print_cache_flags)\") \
	-v ${PROJECT_ROOT}:${GIT_CLONE_ROOT} \
	-v ${CIRCLE_ARTIFACTS:-/tmp/}:/tmp/build_artifacts \
	$(eval echo \"$(${DIR}/../util/docker_common.sh print_environment_flags)\") \
	-e ${GH_USER_VAR}=${GH_USERNAME} \
	-e ${GH_EMAIL_VAR}=${GH_EMAIL} \
	-e ${GH_STATUS_TOKEN_VAR}=${GH_STATUS_TOKEN} \
	--entrypoint /bin/bash \
	${BASEIMAGE_REPO}:${CACHING_SHA:-latest} \
	-c "${GIT_CLONE_ROOT}$(echo ${DOCIF_ROOT} | sed "s%${PROJECT_ROOT}%%g")/util/${TEST_CMD}"
EXIT=$?
if [ $EXIT -ne 0 ]; then
	exit $EXIT
fi

if [ ! -f "${TMP_FOLDER}/docif_tests.cid" ]; then
	echo "[ERR] Your tests command did not produce a usable container. This is likely a config or infra issue." >&2
	exit 1
fi
# Commit the latest image
docker commit "$(cat ${TMP_FOLDER}/docif_tests.cid)" ${IMAGE_NAME_CI}:${COMMIT_SHA}
rm "${TMP_FOLDER}/docif_tests.cid"
