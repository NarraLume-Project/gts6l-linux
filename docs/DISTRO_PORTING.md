# Guide: Adapting the Port to Other Linux Distributions

[![Language: English](https://img.shields.io/badge/Language-English-blue.svg)](#) [![Português](https://img.shields.io/badge/Vers%C3%A3o-Portugu%C3%AAs-green.svg)](DISTRO_PORTING.pt-BR.md)

> [!NOTE]
> [🇧🇷 Clique aqui para ler este guia em Português](DISTRO_PORTING.pt-BR.md)

---

The architecture of this port is **distribution-agnostic**. The hardware abstraction lives entirely in the UEFI firmware, the mainline Linux 6.12 kernel, and standard Linux userspace APIs (KMS/DRM, V4L2, ALSA UCM2, Libinput, and systemd/udev).

You can easily adapt this port to **Arch Linux ARM, Debian, Ubuntu, postmarketOS, Alpine, or openSUSE**.

---

## 🏗️ Technical Architecture

1. **Firmware Layer:** Project Aloha EDK2 UEFI exposes standard EFI services, ACPI/SMBIOS, and an EFI GOP framebuffer at 2560x1600.
2. **Bootloader:** Standard EFI executable (`systemd-boot`, `GRUB2`, or `rEFInd`) loads `Image` + DTB (`sm8150-samsung-gts6l.dtb`).
3. **Display Subsystem:** Runs on `simpledrm` over the bootloader framebuffer, paired with Adreno 640 render-only GPU via Mesa `kmsro` / `freedreno`.
4. **Input Subsystem:** Touchscreen (`fts1ba90a`) and S-Pen Digitizer (`wacom_w9021`) communicate via standard `evdev` events to `libinput`.
5. **Sound:** Cirrus CS35L41 digital amplifiers are controlled through ALSA UCM2 profiles.

---

## 📋 General Porting Checklist

Whatever distribution you choose, ensure the following requirements are met:

### 1. Architecture
- The rootfs tarball must be built for **AArch64 (`arm64`)**.

### 2. Graphics Stack
- **Mesa:** Must include `freedreno`, `kmsro`, and `swrast` drivers (e.g. `mesa-dri-drivers` or `mesa`).
- **Compositor:** Wayland compositors (KWin Wayland, Mutter, Sway, Weston) work natively over `simpledrm`. For X11, the `modesetting` driver is recommended.

### 3. Kernel Modules & Config
- Deploy the precompiled `modules-6.12.tar.gz` to `/lib/modules/` or compile your distribution's kernel using `gts6l_defconfig`.
- Enable auto-loading of the core drivers via `/etc/modules-load.d/tabs6.conf`.

### 4. Firmware Blobs
- Copy the required Qualcomm and Cirrus blobs into `/lib/firmware/` following [`etc/firmware/README.md`](../etc/firmware/README.md).

---

## 🚀 Quick Porting Recipe: Step-by-Step

### Example: Installing Arch Linux ARM or Debian

```bash
# 1. Mount your target partitions
mount /dev/block/by-name/userdata /mnt/rootfs
mount /dev/block/by-name/cache /mnt/esp

# 2. Extract your distro's base AArch64 rootfs
tar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C /mnt/rootfs/

# 3. Install the precompiled Tab S6 kernel modules
tar -xzpf bin/modules-6.12.tar.gz -C /mnt/rootfs/

# 4. Copy the hardware configuration overlay from this repo
cp etc/modules-load.d/tabs6.conf /mnt/rootfs/etc/modules-load.d/
cp etc/udev/rules.d/99-tabs6.rules /mnt/rootfs/etc/udev/rules.d/
cp etc/systemd/system/tabs6-*.service /mnt/rootfs/etc/systemd/system/
mkdir -p /mnt/rootfs/etc/alsa/ucm2/sm8150-samsung-gts6l/
cp etc/alsa/ucm2/sm8150-samsung-gts6l/* /mnt/rootfs/etc/alsa/ucm2/sm8150-samsung-gts6l/

# 5. Extract and copy device firmware
./etc/firmware/extract_firmware.sh /mnt/rootfs/lib/firmware

# 6. Copy boot binaries to ESP
cp bin/Image /mnt/esp/Image
cp bin/sm8150-samsung-gts6l.dtb /mnt/esp/sm8150-samsung-gts6l.dtb

# 7. Add an entry to your bootloader configuration (e.g. systemd-boot)
cat << 'EOF' > /mnt/esp/loader/entries/arch.conf
title Arch Linux ARM (Galaxy Tab S6)
linux /Image
devicetree /sm8150-samsung-gts6l.dtb
options root=PARTLABEL=userdata rootwait rw quiet loglevel=4
EOF
```

---

## 🧩 Non-Systemd Distributions (Alpine, Void, postmarketOS)

If using runit or OpenRC:
1. **Modules:** Add the driver names from `etc/modules-load.d/tabs6.conf` to `/etc/modules`.
2. **Charging Service:** Convert `tools/tabs6-charge.sh` into an OpenRC local service (`/etc/local.d/tabs6-charge.start`).
3. **Power Button & Sleep:** Run `tools/tabs6-powerkeyd.py` and `tools/tabs6-idled.py` via your init supervisor.
