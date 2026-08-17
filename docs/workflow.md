# Build Workflow

This repository has one build path:

```text
Fedora bootc base image
        |
        v
Podman builds the OCI image
        |
        v
image-builder / osbuild creates raw, VM, or PXE artifacts
```

`bootc/Containerfile.rescue` describes the operating system. Files under
`bootc/rootfs/` provide the small amount of local configuration and helper
tooling. The image is intentionally console-first and does not contain
project-specific credentials.

The build-time initramfs configuration in
`bootc/rootfs/usr/lib/dracut/dracut.conf.d/40-fedora-rescue-pxe.conf` enables
the modules required for the HTTP-rootfs PXE artifact. It does not add custom
kernel modules.

## Raw Image

```bash
./build-bootc.sh
IMAGE_TYPE=raw ./build-bootc-artifact.sh
```

Verify the output before writing it to removable media. `bmaptool` is preferred
when image-builder produces a matching `.bmap` file; otherwise use a carefully
verified `dd` target.

## PXE Image

```bash
IMAGE_TYPE=pxe-tar-xz ./build-bootc-artifact.sh
mkdir -p bootc-out/pxe-tree
tar -xJf bootc-out/image/pxe.tar.xz -C bootc-out/pxe-tree
./customize-pxe-grub.sh bootc-out/pxe-tree
```

PXE is a live rescue boot, not an installer. A future installation workflow can
be added separately without making the rescue image responsible for credentials
or target-disk policy.
