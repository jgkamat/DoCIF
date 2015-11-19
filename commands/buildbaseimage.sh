#!/bin/bash
# Builds our baseimage if needed
set -e

DIR=$(cd $(dirname $0) ; pwd -P)
source ${DIR}/../util/docker_common.sh

if [ -n "$CACHING_SHA" ] && curl -s https://registry.hub.docker.com/v1/repositories/${BASEIMAGE_REPO}/tags |  fgrep -q "\"name\": \"${CACHING_SHA}\""; then
	# The tag currently exists, and can be pulled
	docker pull ${BASEIMAGE_REPO}:${CACHING_SHA}
else
	# The tag does not exist, let's build it!
	set +e
	docker build -t "${BASEIMAGE_REPO}:in_progress"  -f "${DOCKERFILE}" .
	if [ $? -ne 0 ]; then
		echo "[ERR] The Dockerfile build FAILED. Please report this if using the default dockerfile. Exiting..." >&2
		${DOCIF_ROOT}/util/maketest.sh --fail
		exit 1
	fi
	set -e

	if [ -n "$SETUP_COMMAND" ]; then
		set +e
		docker run \
			   --entrypoint="" \
			   $(eval echo \"$(${DIR}/../util/docker_common.sh print_cache_flags)\") \
			   $(eval echo \"$(${DIR}/../util/docker_common.sh print_environment_flags)\") \
			   -v ${PROJECT_ROOT}:${GIT_CLONE_ROOT} ${BASEIMAGE_REPO}:in_progress \
			   "${SETUP_COMMAND}"
		if [ $? -ne 0 ]; then
			echo "[ERR] Your setup command FAILED. Exiting..." >&2
			${DOCIF_ROOT}/util/maketest.sh --fail
			exit 1
		fi
		set -e
	else
		echo "[WARN] No setup command was supplied. Using bare baseimage environment." >&2
	fi

	docker commit "$(docker ps -aq | head -n1)" ${BASEIMAGE_REPO}:${CACHING_SHA:-latest}

	if [ -n "$DOCKER_PASSWORD" -a -n "$DOCKER_EMAIL" -a -n "$DOCKER_USERNAME" ]; then
		docker login -e $DOCKER_EMAIL -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
		# Exit on failed login
		if [ $? -ne 0 ]; then
			echo "[WARN] Docker login FAILED. This most likeley means invalid credentials. Exiting..." >&2
			exit 1
		fi

		if [ "$PUSH_BASEIMAGE" = "true" ]; then
			set +e
			docker push ${BASEIMAGE_REPO}:${CACHING_SHA:-latest}
			if [ $? -ne 0 ]; then
				echo "[WARN] The push to the source repository FAILED. This usually means the dockerhub is down." >&2
			fi
			set -e
		fi
	else
		echo "[WARN] Docker credentials not found. Skipping push." >&2
	fi
fi

docker tag -f ${BASEIMAGE_REPO}:${CACHING_SHA:-latest} ${BASEIMAGE_REPO}:current
