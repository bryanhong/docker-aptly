#!/bin/bash

source vars

PYTHON=`which python || which python3`

docker inspect ${APP_NAME} > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo "The ${APP_NAME} container doesn't appear to exist, exiting"
fi

CONTAINER_ID=`docker inspect ${APP_NAME} | $PYTHON -c 'import sys, json; print(json.load(sys.stdin)[0]["Id"])'`

docker exec -it ${CONTAINER_ID} /bin/bash
