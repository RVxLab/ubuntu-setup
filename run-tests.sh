#!/bin/bash

set -e

if ! (command -v docker > /dev/null)
then
    echo "Docker is required to run tests"
    exit 1
fi

docker build -f "./Dockerfile-test-ubuntu18.04" .
docker build -f "./Dockerfile-test-debian-buster" .
