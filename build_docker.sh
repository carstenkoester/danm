#!/bin/sh -e

if [ -z "${CONTAINER_REGISTRY}" ]
then
  registry_prefix=""
else
  registry_prefix="${CONTAINER_REGISTRY}/"
fi

BUILD_TAG=$(git describe --tags)
VERSION=$(git rev-parse --short=8 HEAD)
if ! [ -z "$(git status --porcelain)" ]
then
  export VERSION="${VERSION}_dirty"
fi

for a in netwatcher svcwatcher webhook danmcni
do
  echo Building: ${a}
  docker build \
    --build-arg BUILD_TAG=${BUILD_TAG} \
    --build-arg VERSION=${VERSION} \
    --tag ${registry_prefix}${a}:${VERSION} \
    --target ${a} \
    --file scm/build/Dockerfile \
    .

  if ! [ -z "${PUSH}" ]
  then
    docker image push ${registry_prefix}${a}:${VERSION}
  fi

  if ! [ -z "${TAG_AS_LATEST}" ]
  then
    docker tag ${registry_prefix}${a}:${VERSION} ${registry_prefix}${a}:latest
    if ! [ -z "${PUSH}" ]
    then
      docker image push ${registry_prefix}${a}:latest
    fi
  fi

done
