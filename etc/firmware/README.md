# Device Firmware Blobs for Samsung Galaxy Tab S6

This repository does **not** distribute proprietary binary firmware blobs (Qualcomm Hexagon DSPs, Adreno GPU zap shaders, or Cirrus Logic audio DSP binaries).

To comply with licensing and ensure hardware cryptographic compatibility (as certain blobs are signed with Samsung's device-specific OEM keys), firmware must be extracted directly from your device's stock `vendor` and `modem` partitions.

## Required Firmware Locations in `/lib/firmware/`:

1. **GPU (Adreno 640):**
   - `/lib/firmware/qcom/a630_zap.mbn` (Signed Samsung GPU zap shader)
   - `/lib/firmware/qcom/a630_sqe.fw`
2. **Wi-Fi & Bluetooth (WCN3990):**
   - `/lib/firmware/ath10k/WCN3990/hw1.0/firmware-5.bin`
   - `/lib/firmware/ath10k/WCN3990/hw1.0/board-2.bin`
   - `/lib/firmware/qcom/crnv21.bin`
3. **Audio (Cirrus CS35L41 & CS48L33):**
   - `/lib/firmware/cirrus/cs35l41-dsp1-spk-prot.bin`
   - `/lib/firmware/cirrus/cs35l41-dsp1-spk-prot.wmfw`
4. **Hexagon Subsystems (ADSP, SLPI):**
   - `/lib/firmware/qcom/sm8150/adsp.*`
   - `/lib/firmware/qcom/sm8150/slpi.*`

## Automated Extraction:

Run the included extraction script on your tablet while booted into Linux (or chroot):
```bash
sudo ./extract_firmware.sh /lib/firmware
```
