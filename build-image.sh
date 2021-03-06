#!/bin/bash

set -eo pipefail

docker_image_name="${1:-"malston/alert-webhook"}"
docker_image_tag="${2:-"0.1.1"}"

make build-linux

docker build -t "${docker_image_name}:${docker_image_tag}" .

docker login
docker tag "${docker_image_name}:${docker_image_tag}" "${docker_image_name}:${docker_image_tag}"
docker push "${docker_image_name}:${docker_image_tag}"
