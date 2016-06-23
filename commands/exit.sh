#!/bin/bash
# Builds our circle image which runs tests
set -e
DIR=$(cd $(dirname $0) ; pwd -P)

source ${DIR}/../util/docker_common.sh

exit "$(cat ${TMP_FOLDER}/exit_code)"
