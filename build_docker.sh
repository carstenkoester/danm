#!/bin/sh -e

BUILD_TAG=$(git describe --tags)
VERSION=$(git rev-parse --short=8 HEAD)
if ! [ -z "$(git status --porcelain)" ]
then
  export VERSION="${VERSION}_dirty"
fi

for a in netwatcher svcwatcher webhook danmbin
do
  echo Building: ${netwatcher}
  docker build \
    --build-arg BUILD_TAG=${BUILD_TAG} \
    --build-arg VERSION=${VERSION} \
    --tag ${a}:${VERSION} \
    --target ${a} \
    --file scm/build/Dockerfile \
    .
done
