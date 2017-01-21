#!/bin/bash
# Builds our baseimage if needed
set -e
DIR=$(cd $(dirname $0) ; pwd -P)
source ${DIR}/../util/docker_common.sh


if [ -n "${CACHING_SHA:-}" ] && \
	   echo "[INFO] Attempting pull from ${BASEIMAGE_REPO}:${CACHING_SHA}" && \
	   docker pull ${BASEIMAGE_REPO}:${CACHING_SHA} >/dev/null; then
	echo "[INFO] Image ${BASEIMAGE_REPO}:${CACHING_SHA} was successfully pulled!"
else
	# The tag does not exist, let's build it!
	if [ -z "${CACHING_SHA:-}" ]; then
		echo "[INFO] Caching sha not found. Make sure you have SHA files for us to SHA."
	else
		echo "[INFO] Cached baseimage ${BASEIMAGE_REPO}:${CACHING_SHA} not found or failed pull. Building a new image."
	fi

	set +e

	docker build -t "${BASEIMAGE_REPO}:in_progress"  -f "${DOCKERFILE}" .

	if [ $? -ne 0 ]; then
		echo "[ERR] The Dockerfile build FAILED. Please report this if using the default dockerfile. Exiting..." >&2
		${DOCIF_ROOT}/util/maketest.sh --fail
		exit 1
	fi
	set -e

	if [ -n "$SETUP_COMMAND" ]; then
		clean_cid_file "${TMP_FOLDER}/docif_baseimage.cid"

		set +e

		docker run \
			   --cidfile="${TMP_FOLDER}/docif_baseimage.cid" \
			   $(eval echo \"$(${DIR}/../util/docker_common.sh print_cache_flags)\") \
			   $(eval echo \"$(${DIR}/../util/docker_common.sh print_environment_flags)\") \
			   -v ${PROJECT_ROOT}:${GIT_CLONE_ROOT} ${BASEIMAGE_REPO}:in_progress \
			   sh -c "${SETUP_COMMAND}"
		if [ $? -ne 0 ]; then
			echo "[ERR] Your setup command FAILED. Exiting..." >&2
			${DOCIF_ROOT}/util/maketest.sh --fail
			exit 1
		fi

		set -e

		if [ ! -f "${TMP_FOLDER}/docif_baseimage.cid" ]; then
			echo "[ERR] Your setup command did not produce a usable container. This is likely a config or infra issue." >&2
			exit 1
		fi

		docker commit "$(cat ${TMP_FOLDER}/docif_baseimage.cid)" ${BASEIMAGE_REPO}:${CACHING_SHA:-latest}
		rm -f "${TMP_FOLDER}/docif_baseimage.cid"
	else
		echo "[WARN] No setup command was supplied. Using bare baseimage environment." >&2
		docker tag ${BASEIMAGE_REPO}:in_progress ${BASEIMAGE_REPO}:${CACHING_SHA:-latest}
	fi

	if [ -n "$DOCKER_PASSWORD" -a -n "$DOCKER_EMAIL" -a -n "$DOCKER_USERNAME" ]; then

		docker login -e $DOCKER_EMAIL -u $DOCKER_USERNAME -p $DOCKER_PASSWORD

		# Exit on failed login
		if [ $? -ne 0 ]; then
			echo "[WARN] Docker login FAILED. This most likeley means invalid credentials. Exiting..." >&2
			exit 1
		fi

		if [ "$PUSH_BASEIMAGE" = "true" ]; then
			echo "[INFO] Pushing baseimage in the background..."
			echo "[INFO] Pushing to ${BASEIMAGE_REPO}:${CACHING_SHA:-latest}"

			# run in subshell
			nohup sh -c "(
				touch ${TMP_FOLDER}/push_baseimage.lock
				docker push ${BASEIMAGE_REPO}:${CACHING_SHA:-latest}
				echo "${?}" > ${TMP_FOLDER}/push_baseimage.lock
			) >/dev/null 2>&1 &"
		fi

	else
		echo "[WARN] Docker credentials not found. Skipping push." >&2
	fi
fi

docker tag ${BASEIMAGE_REPO}:${CACHING_SHA:-latest} ${BASEIMAGE_REPO}:current
