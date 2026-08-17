#!/usr/bin/env bash
set -euo pipefail

# Usage: IMAGE_NAME=localhost/fedora-rescue-bootc:test ./shell-bootc-image.sh
IMAGE_NAME=${IMAGE_NAME:-localhost/fedora-rescue-bootc:44}

exec sudo podman run \
  --rm \
  --interactive \
  --tty \
  --pull=never \
  --entrypoint /bin/bash \
  "$IMAGE_NAME"
