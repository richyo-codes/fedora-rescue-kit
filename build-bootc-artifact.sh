#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=${IMAGE_NAME:-localhost/fedora-rescue-bootc:44}
OUTPUT_DIR=${OUTPUT_DIR:-$(pwd)/bootc-out}
IMAGE_TYPE=${IMAGE_TYPE:-raw}  # raw, qcow2, pxe-tar-xz, ami, gce, ova, vhd, vmdk, oci, bootc-installer
ROOTFS=${ROOTFS:-ext4}
OUTPUT_OWNER=${OUTPUT_OWNER:-$(id -u):$(id -g)}
CACHE_DIR=${CACHE_DIR:-$(pwd)/bootc-out/.image-builder-cache}
PROGRESS=${PROGRESS:-auto}

# image-builder uses the root Podman storage, matching build-bootc.sh.
[[ "$OUTPUT_DIR" != /* ]] && OUTPUT_DIR="$(pwd)/$OUTPUT_DIR"
[[ "$CACHE_DIR" != /* ]] && CACHE_DIR="$(pwd)/$CACHE_DIR"

case "$IMAGE_TYPE" in
  raw|qcow2|pxe-tar-xz|ami|gce|ova|vhd|vmdk|oci)
    BUILD_ARGS=(--bootc-ref "$IMAGE_NAME" --bootc-default-fs "$ROOTFS")
    ;;
  bootc-installer)
    : "${INSTALLER_IMAGE:?Set INSTALLER_IMAGE to an Anaconda-capable bootc installer image.}"
    BUILD_ARGS=(
      --bootc-ref "$INSTALLER_IMAGE"
      --bootc-installer-payload-ref "$IMAGE_NAME"
      --bootc-default-fs "$ROOTFS"
    )
    ;;
  iso|anaconda-iso)
    echo "IMAGE_TYPE=$IMAGE_TYPE is not supported by image-builder for bootc images." >&2
    echo "Use raw for a directly bootable rescue disk, or bootc-installer with INSTALLER_IMAGE." >&2
    exit 2
    ;;
  *)
    echo "Unsupported IMAGE_TYPE: $IMAGE_TYPE" >&2
    exit 2
    ;;
esac

mkdir -p "$OUTPUT_DIR"

# Keep the build and ownership handoff in one privileged process. Long builds
# can outlive sudo's credential timestamp, otherwise leaving a successful
# artifact root-owned when the final chown prompts again.
sudo bash -euo pipefail -c '
  artifact_output_dir=$1
  artifact_cache_dir=$2
  artifact_progress=$3
  artifact_owner=$4
  artifact_type=$5
  shift 5

  mkdir -p "$artifact_cache_dir"
  image-builder build \
    --output-dir "$artifact_output_dir" \
    --cache "$artifact_cache_dir" \
    --progress "$artifact_progress" \
    "$@" \
    "$artifact_type"
  chown -R "$artifact_owner" "$artifact_output_dir"
' bash \
  "$OUTPUT_DIR" \
  "$CACHE_DIR" \
  "$PROGRESS" \
  "$OUTPUT_OWNER" \
  "$IMAGE_TYPE" \
  "${BUILD_ARGS[@]}"

echo "Wrote ${IMAGE_TYPE} artifact(s) to: $OUTPUT_DIR"
