#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="${ASSETS_DIR:-$(pwd)/assets}"
mkdir -p "$ASSETS_DIR"

echo "[INFO] Downloading ARM FS kernel/bootloader bundle..."
# Contains vmlinux and bootloaders for ARM FS runs.  [3](https://www.gem5.org/documentation/general_docs/fullsystem/guest_binaries)
K_TARBALL="aarch-system-20220707.tar.bz2"
K_URL="http://dist.gem5.org/dist/v22-0/arm/${K_TARBALL}"
curl -L "$K_URL" -o "$ASSETS_DIR/$K_TARBALL"
tar -xjf "$ASSETS_DIR/$K_TARBALL" -C "$ASSETS_DIR"

# Try to pick a 32-bit (AArch32) kernel path from the tarball layout
# (You can adjust this path after extracting if needed.)
KERNEL=$(find "$ASSETS_DIR" -type f -name "vmlinux" | head -n1)
if [[ -z "$KERNEL" ]]; then
  echo "[ERROR] Could not locate vmlinux in extracted tarball."
  exit 1
fi
cp "$KERNEL" "$ASSETS_DIR/vmlinux-armv7"

echo "[INFO] Downloading a 32-bit ARM disk image (AArch32)..."
# Older but works for quick tests; you can replace with a different AArch32 image later.  [3](https://www.gem5.org/documentation/general_docs/fullsystem/guest_binaries)
DISK_BZ="linux-aarch32-ael.img.bz2"
DISK_URL="http://dist.gem5.org/dist/current/arm/disks/${DISK_BZ}"
curl -L "$DISK_URL" -o "$ASSETS_DIR/$DISK_BZ"
bunzip2 -f "$ASSETS_DIR/$DISK_BZ"

echo "[OK] Assets in: $ASSETS_DIR"
ls -lh "$ASSETS_DIR"