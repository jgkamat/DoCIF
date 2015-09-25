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
	   $(eval echo \"$(${DIR}/../util/docker_common.sh print_cache_flags)\") \
	   -v ${PROJECT_ROOT}:${GIT_CLONE_ROOT} \
	   -v ${CIRCLE_ARTIFACTS:-/tmp/}:/tmp/build_artifacts \
	   $(eval echo \"$(${DIR}/../util/docker_common.sh print_environment_flags)\") \
	   -e ${GH_USER_VAR}=${GH_USERNAME} \
	   -e ${GH_EMAIL_VAR}=${GH_EMAIL} \
	   -e ${GH_STATUS_TOKEN_VAR}=${GH_STATUS_TOKEN} \
	   --entrypoint /bin/bash \
	   ${BASEIMAGE_REPO}:${CACHING_SHA:-latest} \
	   -c "${DOCKER_PROJECT_ROOT}$(echo ${DOCIF_ROOT} | sed "s%${PROJECT_ROOT}%%g")/util/${TEST_CMD}"

EXIT=$?
if [ $EXIT -ne 0 ]; then
	exit $EXIT
fi

# Commit the latest image
docker commit "$(docker ps -aq | head -n1)" ${IMAGE_NAME_CI}:${COMMIT_SHA}
