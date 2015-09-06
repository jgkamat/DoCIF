#!/bin/bash
# Runs the autoupdate script for api documentation
set -e

DIR=$(cd $(dirname $0) ; pwd -P)
source ${DIR}/docker_common.sh

if [ "$GH_TOKEN" = "" ]; then
	echo "Github token not set!"
	exit 1
fi

# Entrypiont is needed to preserve exit code
docker run \
	   $(${DIR}/../util/docker_common.sh print_cache_flags) \
	   -v ${PROJECT_ROOT}:/home/developer/project \
	   -v ${CIRCLE_ARTIFACTS:-/tmp/}:/tmp/build_artifacts \
	   $(${DIR}/../util/docker_common.sh print_environment_flags) \
	   -e CIRCLE_BUILD_NUM=${CIRCLE_BUILD_NUM} \
	   -e CIRCLE_ARTIFACTS=${CIRCLE_ARTIFACTS} \
	   -e GH_USERNAME=${GH_USERNAME} \
	   -e ${GH_EMAIL_VAR}=${GH_EMAIL} \
	   -e ${GH_STATUS_TOKEN_VAR}=${GH_STATUS_TOKEN} \
	   --entrypoint /bin/bash \
	   ${IMAGE_NAME_BASE}:${CACHING_SHA:-latest} "bash -c cd /home/developer/project && $API_AUTOUPDATE_COMMAND"
