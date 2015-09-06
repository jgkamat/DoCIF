#!/bin/bash
# Builds our circle image which runs tests
set -e

DIR=$(cd $(dirname $0) ; pwd -P)
source ${DIR}/../util/docker_common.sh

if [ "$GH_STATUS_TOKEN" = "" ]; then
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
	   -e GH_EMAIL=${GH_EMAIL} \
	   -e GH_STATUS_TOKEN=${GH_STATUS_TOKEN} \
	   --entrypoint /bin/bash \
	   ${BASEIMAGE_REPO}:${CACHING_SHA:-latest} \
	   /home/developer/project/$(echo ${DOCIF_ROOT} | sed "s%${PROJECT_ROOT}%%g")/util/maketest.sh

EXIT=$?
if [ $EXIT -ne 0 ]; then
	exit $EXIT
fi

# Commit the latest image
docker commit "$(docker ps -aq | head -n1)" ${IMAGE_NAME_CI}:${COMMIT_SHA}
