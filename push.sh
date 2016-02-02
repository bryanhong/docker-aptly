#!/bin/bash

source vars

#This will take the latest locally built image and push it to the repository as
#configured in vars and tag it as latest.

if [[ ! -f builds ]]; then
  echo
  echo "It appears that the Docker image hasn't been built yet, run build.sh first"
  echo
  exit 1
fi

LATESTIMAGE=`tail -1 builds | awk '{print $8}'`

# Flatten is here as an option and not the default because with the export/import
# process we lose Dockerfile attributes like PORT and VOLUMES. Flattening helps if
# we are concerned about hitting the AUFS 42 layer limit or creating an image that
# other containers source FROM

DockerExport () {
  docker export ${APP_NAME} | docker import - ${REPO_NAME}/${APP_NAME}:latest
}

DockerPush () {
  docker push ${REPO_NAME}/${APP_NAME}:latest
}

case "$1" in
  flatten)
    docker inspect ${APP_NAME} > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo "The ${APP_NAME} container doesn't appear to exist, exiting"
      exit 1
    fi
    RUNNING=`docker inspect ${APP_NAME} | python -c 'import sys, json; print json.load(sys.stdin)[0]["State"]["Running"]'`
    if [[ "${RUNNING}" = "True" ]]; then
      echo "Stopping ${APP_NAME} container for export"
      docker stop ${APP_NAME}
      DockerExport
      DockerPush
    else
      DockerExport
      DockerPush
    fi
    ;;
  *)
    docker tag -f ${LATESTIMAGE} ${REPO_NAME}/${APP_NAME}:latest
    DockerPush
esac
