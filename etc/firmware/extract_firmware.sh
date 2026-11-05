#!/bin/bash
# Script to extract required device firmware blobs directly from the tablet's stock vendor/modem partitions
set -euo pipefail

DEST_DIR="${1:-/lib/firmware}"
MNT_DIR="/mnt/vendor_stock"

echo "=== Galaxy Tab S6 Firmware Extractor ==="

mkdir -p "$MNT_DIR"
mkdir -p "$DEST_DIR/qcom"
mkdir -p "$DEST_DIR/cirrus"

# If running on device:
if [ -b "/dev/disk/by-partlabel/vendor" ]; then
    echo "Mounting device vendor partition..."
    mount -o ro /dev/disk/by-partlabel/vendor "$MNT_DIR"
elif [ -f "vendor.img" ]; then
    echo "Mounting vendor.img..."
    mount -o ro -t ext4 vendor.img "$MNT_DIR"
else
    echo "Notice: vendor partition or vendor.img not found. Please provide path to vendor image."
fi

if [ -d "$MNT_DIR/firmware" ]; then
    echo "Copying Adreno 640 zap shader and firmware..."
    cp -v "$MNT_DIR/firmware/image/a630_zap."* "$DEST_DIR/qcom/" 2>/dev/null || true
    cp -v "$MNT_DIR/firmware/image/a630_sqe."* "$DEST_DIR/qcom/" 2>/dev/null || true

    echo "Copying Qualcomm DSP firmware (ADSP, SLPI, CDSP)..."
    cp -v "$MNT_DIR/firmware/image/adsp"* "$DEST_DIR/qcom/" 2>/dev/null || true
    cp -v "$MNT_DIR/firmware/image/slpi"* "$DEST_DIR/qcom/" 2>/dev/null || true
    cp -v "$MNT_DIR/firmware/image/cdsp"* "$DEST_DIR/qcom/" 2>/dev/null || true

    echo "Copying WCN3990 Wi-Fi and Bluetooth firmware..."
    cp -v "$MNT_DIR/firmware/image/wlanmdsp."* "$DEST_DIR/qcom/" 2>/dev/null || true
fi

if [ -d "$MNT_DIR/etc/firmware" ]; then
    echo "Copying Cirrus CS35L41 & CS48L33 speaker calibration..."
    cp -rv "$MNT_DIR/etc/firmware/cs35l41"* "$DEST_DIR/cirrus/" 2>/dev/null || true
    cp -rv "$MNT_DIR/etc/firmware/cs48l3"* "$DEST_DIR/cirrus/" 2>/dev/null || true
fi

umount "$MNT_DIR" 2>/dev/null || true
rmdir "$MNT_DIR" 2>/dev/null || true

echo "=== Firmware extraction finished. Blobs saved to $DEST_DIR ==="
