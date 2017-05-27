#!/bin/bash

source vars

DOCKERFILE="${1:-Dockerfile}"

docker build -t "${REPO_NAME}/${APP_NAME}:${TAG}" -f ${DOCKERFILE} .

# If the build was successful (0 exit code)...
if [ $? -eq 0 ]; then
  echo
  echo "Build of ${REPO_NAME}/${APP_NAME}:${TAG} completed OK"
  echo

  # log build details to builds file
  echo "`date` => ${REPO_NAME}/${APP_NAME}:${TAG}" >> builds

# The build exited with an error.
else
  echo "Build failed!"
  exit 1

fi
