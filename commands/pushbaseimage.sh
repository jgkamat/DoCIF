#!/bin/bash
# Pushes the baseimage to the master tag
set -e

DIR=$(cd $(dirname $0) ; pwd -P)
source ${DIR}/../docker_common.sh

docker tag -f ${BASEIMAGE_REPO}:current ${BASEIMAGE_REPO}:master

if [ -n "$DOCKER_PASS" ]; then
    docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
    docker push ${BASEIMAGE_REPO}:master
fi
