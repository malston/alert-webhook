#!/bin/bash

set -eo pipefail

docker_image_name="${1:-"malston/alert-webhook"}"
docker_image_tag="${2:-"0.1.0"}"
project="${3:-"prometheus"}"

make build-linux

docker build -t "${docker_image_name}:${docker_image_tag}" .

if [[ -z "${HARBOR_ADMIN_PASSWORD}" ]]; then
  echo "Enter the password for the harbor administrator account: "
  read -rs HARBOR_ADMIN_PASSWORD
fi

if [[ -z "${HARBOR_URL}" ]]; then
  echo "Enter the dns hostname for harbor: (e.g. harbor.example.com)"
  read -r HARBOR_URL
fi

docker login "https://${HARBOR_URL}" --username admin --password "${HARBOR_ADMIN_PASSWORD}"
docker tag "${docker_image_name}:${docker_image_tag}" "${HARBOR_URL}/${project}/${docker_image_name}:${docker_image_tag}"
docker push "${HARBOR_URL}/${project}/${docker_image_name}:${docker_image_tag}"
