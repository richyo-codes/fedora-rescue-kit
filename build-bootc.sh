#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=${IMAGE_NAME:-localhost/fedora-rescue-bootc:44}
BASE_IMAGE=${BASE_IMAGE:-quay.io/fedora/fedora-bootc:44}
CONTAINERFILE=${CONTAINERFILE:-bootc/Containerfile.rescue}
sudo podman build \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  --tag "$IMAGE_NAME" \
  --file "$CONTAINERFILE" \
  bootc

echo "Built bootc image: $IMAGE_NAME"
