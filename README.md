# Fedora Rescue Kit

Copyright (C) 2026 Rich Young

Fedora Rescue Kit is a small Fedora/Red Hat-based rescue distribution inspired
by SystemRescue. It is designed for disk recovery, hardware inspection,
network/PXE work, and learning how the modern Red Hat image-building stack fits
together.

The project uses Podman to build an OCI image, bootc as the operating-system
image model, and image-builder to turn that image into bootable artifacts. The
Fedora boot chain uses Fedora's signed shim and bootloader, so generated disk
images can boot with Secure Boot enabled.

## What It Includes

- Fedora 44 bootc base image.
- Console-first boot with `liveuser` autologin and passwordless sudo.
- Sway, Foot, GParted, and common terminal compatibility packages.
- Disk and filesystem recovery tools including `ddrescue`, TestDisk, LVM,
  mdadm, SMART, NVMe, and filesystem utilities.
- Network diagnostics and PXE/TFTP tooling.
- `fed-toolbox`, a reusable rootless Fedora container for temporary packages.
- Raw, qcow2, and HTTP-rootfs PXE artifacts through image-builder.

The image does not enable SSH and does not accept credentials during the build.
Authentication, public-key provisioning, cloud-init, and persistent home
storage are intentionally deferred until their interface is designed cleanly.

## Build

Install Podman and the host `image-builder` package, then build the OCI image:

```bash
./build-bootc.sh
```

Generate a raw disk image:

```bash
IMAGE_TYPE=raw ./build-bootc-artifact.sh
```

Other useful artifact types:

```bash
IMAGE_TYPE=qcow2 ./build-bootc-artifact.sh
IMAGE_TYPE=pxe-tar-xz ./build-bootc-artifact.sh
```

Build outputs are written to `bootc-out/`. The scripts use rootful Podman so
the image is available to image-builder's osbuild process.

## PXE

The PXE artifact is an HTTP-rootfs live rescue environment. Extract it and
render the supplied GRUB menu:

```bash
IMAGE_TYPE=pxe-tar-xz ./build-bootc-artifact.sh
mkdir -p bootc-out/pxe-tree
tar -xJf bootc-out/image/pxe.tar.xz -C bootc-out/pxe-tree
./customize-pxe-grub.sh bootc-out/pxe-tree
```

Serve the generated TFTP files and HTTP root filesystem from a PXE server. The
GRUB template includes normal and 115200-baud serial-console entries.

## Container Workflow

The rescue image is the environment you boot for recovery and diagnostics. Use
`fed-toolbox` when temporary packages are needed without rebuilding the image:

```bash
fed-toolbox
dnf install -y btop
```

The toolbox is a normal rootless Fedora container and is the main container
workflow demonstrated by this project.

Inspect an image before artifact generation:

```bash
./shell-bootc-image.sh
./analyze-bootc-image.sh
```

## Default Login

The local console autologins as `liveuser`. It has passwordless sudo for rescue
operations. There is no configured remote login in this public profile.

## Repository Layout

```text
bootc/Containerfile.rescue    Fedora bootc image definition
bootc/rootfs/                 Files copied into the image
build-bootc.sh                OCI image build
build-bootc-artifact.sh       image-builder artifact conversion
customize-pxe-grub.sh         PXE GRUB menu renderer
docs/                         Focused workflow notes
```
