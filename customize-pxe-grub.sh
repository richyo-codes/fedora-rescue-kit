#!/usr/bin/env bash
set -euo pipefail

# Usage: ./customize-pxe-grub.sh bootc-out/bootc-pxe-tree
PXE_TREE=${1:?usage: customize-pxe-grub.sh PXE_TREE_DIRECTORY}
GRUB_CFG="$PXE_TREE/grub.cfg"
TEMPLATE=${GRUB_TEMPLATE:-bootc/pxe-grub.cfg.template}

[[ -f $GRUB_CFG ]] || {
  echo "Generated PXE grub.cfg not found: $GRUB_CFG" >&2
  exit 2
}
[[ -f $TEMPLATE ]] || {
  echo "GRUB template not found: $TEMPLATE" >&2
  exit 2
}

mapfile -t linux_lines < <(sed -n 's/^[[:space:]]*linux \/vmlinuz //p' "$GRUB_CFG")
[[ ${#linux_lines[@]} -ge 1 ]] || {
  echo "Expected an HTTP-rootfs kernel entry in $GRUB_CFG" >&2
  exit 2
}

render_cmdline() {
  local console=$1
  shift
  local arg
  local -a args=()

  for arg in "$@"; do
    case "$arg" in
      console=tty0|console=ttyS0*) ;;
      *) args+=("$arg") ;;
    esac
  done
  # The PXE squashfs contains image-builder's UUID-backed /boot fstab entry.
  # There is no local boot device in a live network boot, so ignore it.
  printf '%s %s fstab=no rd.fstab=no' "${args[*]}" "$console"
}

read -r -a http_args <<<"${linux_lines[0]}"

http_normal=$(render_cmdline 'console=tty0' "${http_args[@]}")
http_serial=$(render_cmdline 'console=tty0 console=ttyS0,115200n8' "${http_args[@]}")

tmp=$(mktemp "${GRUB_CFG}.XXXXXX")
trap 'rm -f "$tmp"' EXIT

awk \
  -v http_normal="$http_normal" \
  -v http_serial="$http_serial" \
  '{
    gsub(/@HTTP_NORMAL_CMDLINE@/, http_normal)
    gsub(/@HTTP_SERIAL_CMDLINE@/, http_serial)
    print
  }' "$TEMPLATE" >"$tmp"

mv "$tmp" "$GRUB_CFG"
rm -f "$PXE_TREE/combined.img"
trap - EXIT
echo "Wrote HTTP-rootfs GRUB menu and removed combined.img: $GRUB_CFG"
