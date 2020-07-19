#!/bin/bash

source vars

#If there is a locally built image present, prefer that over the
#one in the registry, we're going to assume you're working on changes
#to the image.

if [[ ! -f builds ]]; then
  LATESTIMAGE=${REPO_NAME}/${APP_NAME}:latest
else
  LATESTIMAGE=`tail -1 builds | awk '{print $8}'`
fi
echo
echo "Starting $APP_NAME..."
echo
echo -n "Container ID: "
docker run \
--detach=true \
--name="${APP_NAME}" \
--restart=always \
-e FULL_NAME="${FULL_NAME}" \
-e EMAIL_ADDRESS="${EMAIL_ADDRESS}" \
-e GPG_PASSWORD="${GPG_PASSWORD}" \
-e HOSTNAME="${HOSTNAME}" \
-v ${APTLY_DATADIR}:/opt/aptly \
-v ${GPG_DATA}:/root/.gnupg \
-p ${DOCKER_HOST_PORT}:80 \
${LATESTIMAGE}
# Other useful options
#--log-driver=syslog \ # if you want Docker logs to go to syslog (Linux)
# -p DOCKERHOST_PORT:CONTAINER_PORT \
# -e "ENVIRONMENT_VARIABLE_NAME=VALUE" \
# -v /DOCKERHOST/PATH:/CONTAINER/PATH \
