#!/bin/bash
# Pushes the baseimage to the master tag
set -e

DIR=$(cd $(dirname $0) ; pwd -P)
source ${DIR}/../util/docker_common.sh


docker tag -f ${BASEIMAGE_REPO}:current ${BASEIMAGE_REPO}:master

if [ -n "$DOCKER_PASSWORD" -o -n "$DOCKER_USERNAME" -o -n "$DOCKER_EMAIL" ]; then
	if [ "$PUSH_BASEIMAGE" = "true" ]; then
		docker login -e $DOCKER_EMAIL -u $DOCKER_USERNAME -p $DOCKER_PASSWORD

		set +e
		docker push ${BASEIMAGE_REPO}:master
		if [ $? -ne 0 ]; then
			echo "[WARN] The push to the source repository FAILED. This usually means the dockerhub is down." >&2
		fi
		set -e
	fi
fi

if [ -n "$DEPLOY_COMMAND" ]; then
	# Run deploy_command within a docker container
	docker run \
		$(eval echo \"$(${DIR}/../util/docker_common.sh print_cache_flags)\") \
		-v ${PROJECT_ROOT}:/home/developer/project \
		-v ${CIRCLE_ARTIFACTS:-/tmp/}:/tmp/build_artifacts \
		$(eval echo \"$(${DIR}/../util/docker_common.sh print_environment_flags)\") \
		-e ${GH_USER_VAR}=${GH_USERNAME} \
		-e ${GH_EMAIL_VAR}=${GH_EMAIL} \
		-e ${GH_STATUS_TOKEN_VAR}=${GH_STATUS_TOKEN} \
		--entrypoint /bin/bash \
		${BASEIMAGE_REPO}:${CACHING_SHA:-latest} -c "$DEPLOY_COMMAND"
else
	echo "[WARN] No custom DEPLOY_COMMAND." >&2
fi
