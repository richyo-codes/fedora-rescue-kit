#!/usr/bin/env bash
set -euo pipefail

# Usage: LIMIT=30 IMAGE_NAME=localhost/fedora-rescue-bootc:test ./analyze-bootc-image.sh
IMAGE_NAME=${IMAGE_NAME:-localhost/fedora-rescue-bootc:44}
LIMIT=${LIMIT:-25}

if ! [[ $LIMIT =~ ^[1-9][0-9]*$ ]]; then
  echo "LIMIT must be a positive integer." >&2
  exit 2
fi

sudo podman image inspect \
  --format 'Image size: {{.Size}} bytes' \
  "$IMAGE_NAME"

exec sudo podman run \
  --rm \
  --pull=never \
  --env "LIMIT=$LIMIT" \
  --entrypoint /bin/bash \
  "$IMAGE_NAME" \
  -lc 'rpm -qa --qf "%{INSTALLSIZE}\t%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n" \
    | sort -nr -k1,1 \
    | head -n "$LIMIT" \
    | awk -F "\t" "{ printf \"%8.1f MiB  %s\\n\", \$1 / 1024 / 1024, \$2 }"'
