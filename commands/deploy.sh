#!/bin/bash
# Pushes the baseimage to the master tag
set -e

DIR=$(cd $(dirname $0) ; pwd -P)
source ${DIR}/../docker_common.sh

if [ "$PUSH_BASEIMAGE" = "false" ]; then
	exit 0
fi

docker tag -f ${BASEIMAGE_REPO}:current ${BASEIMAGE_REPO}:master

if [ -n "$DOCKER_PASS" -o -n "$DOCKER_USER" -o -n "$DOCKER_EMAIL" ]; then
    docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
	docker push ${BASEIMAGE_REPO}:master
fi
