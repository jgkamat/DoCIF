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
	docker build -t "${BASEIMAGE_REPO}:in_progress"  -f "${DOCKERFILE}" .
	if [ -n "$SETUP_COMMAND" ]; then
		docker run \
			   --entrypoint="/bin/bash" \
			   -v ${PROJECT_ROOT}:/home/developer/project ${BASEIMAGE_REPO}:in_progress \
			   -c "${SETUP_COMMAND}"
	else
		echo "[WARN] No setup command was supplied. Using bare baseimage environment." >&2
	fi

	docker commit "$(docker ps -aq | head -n1)" ${BASEIMAGE_REPO}:${CACHING_SHA:-latest}

	if [ -n "$DOCKER_PASSWORD" -a -n "$DOCKER_EMAIL" -a -n "$DOCKER_USERNAME" ]; then
		docker login -e $DOCKER_EMAIL -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
		# Exit on failed login
		if [ $? -ne 0 ]; then
			echo "[WARN] Docker login FAILED. This most likeley means invalid credentials Exiting..." >&2
			exit 1
		fi

		if [ "$PUSH_BASEIMAGE" = "true" ]; then
			docker push ${BASEIMAGE_REPO}:${CACHING_SHA:-latest}
		fi
	else
		echo "[WARN] Docker credentials not found. Skipping push." >&2
	fi
fi

docker tag -f ${BASEIMAGE_REPO}:${CACHING_SHA:-latest} ${BASEIMAGE_REPO}:current
