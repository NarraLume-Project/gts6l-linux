# Galaxy Tab S6 Linux Installation Guide (SM-T865 / SM-T860)

[![Language: English](https://img.shields.io/badge/Language-English-blue.svg)](#) [![Português](https://img.shields.io/badge/Vers%C3%A3o-Portugu%C3%AAs-green.svg)](INSTALLATION.pt-BR.md)

> [!NOTE]
> [🇧🇷 Clique aqui para ler este guia de instalação em Português](INSTALLATION.pt-BR.md)

---

This guide walks you through installing native mainline Linux (such as Fedora 44 KDE, Debian, or Ubuntu) on your Samsung Galaxy Tab S6 LTE (`SM-T865`, `gts6l`) or Wi-Fi (`SM-T860`, `gts6lwifi`).

---

## ⚠️ Prerequisites & Precautions

1. **Unlocked Bootloader:** Unlocking will factory reset your device and permanently trip Knox (0x1). Ensure you have backed up all personal data.
2. **PC Tools:**
   - Windows PC with Samsung USB Drivers installed and [Odin3 v3.14.4](https://odindownload.com/).
   - Alternatively, Linux/macOS with `heimdall-flash` and `adb` / `fastboot`.
3. **USB Cable:** High-quality USB-C to USB-A cable connected directly to a motherboard USB port.
4. **Files from this repository:**
   - Pre-packaged UEFI bootloader: `bin/boot-uefi.tar.md5`
   - Kernel image: `bin/Image`
   - Device Tree: `bin/sm8150-samsung-gts6l.dtb` (for LTE) or `bin/sm8150-samsung-gts6lwifi.dtb` (for Wi-Fi)
   - Precompiled kernel modules: `bin/modules-6.12.tar.gz`
   - Rootfs archive (e.g. Fedora 44 aarch64 rootfs or your distribution of choice)

---

## Phase 1: Unlock Bootloader

1. On the tablet in Android: Go to **Settings > About Tablet > Software Information** and tap **Build Number** 7 times to enable Developer Options.
2. Go to **Settings > Developer Options** and enable **OEM Unlocking** and **USB Debugging**.
3. Power off the tablet. Hold **Volume Up + Volume Down** simultaneously and connect the USB cable to your PC.
4. When the turquoise Warning screen appears, long-press **Volume Up** to unlock the bootloader. Confirm the prompt (this wipes all user data).
5. Boot back into Android setup once, connect to Wi-Fi to confirm OEM Unlocking remains grayed out / enabled in Developer Options.

---

## Phase 2: Flash the UEFI Bootloader via Odin

Samsung's primary bootloader (ABL) validates boot images against AVB signatures. Our `boot-uefi.tar.md5` contains the stock Samsung v1 boot container patched with Project Aloha's SM8150 UEFI payload via DualBootKernelPatcher and Magiskboot:

1. Power off the tablet. Hold **Volume Up + Volume Down** and connect the USB cable to enter **Download Mode**.
2. Press **Volume Up** once to continue into Download Mode.
3. Open **Odin3 v3.14.4** on your PC. Verify the `ID:COM` box lights up blue/cyan.
4. In Odin, click the **AP** button and select `bin/boot-uefi.tar.md5`.
5. Leave BL, CP, and CSC empty.
6. Under Options, leave **Auto Reboot** and **F. Reset Time** checked.
7. Click **Start**. The tablet will flash the UEFI boot image and reboot.

> [!TIP]
> After flashing, the tablet will chainload into Project Aloha UEFI and initialize the 2560x1600 framebuffer.

---

## Phase 3: Partitioning UFS Internal Storage

You can perform partitioning either via TWRP recovery or using a live EFI Linux shell:

1. Boot into TWRP Recovery (hold **Power + Volume Up** during power on).
2. Open a terminal via ADB:
   ```bash
   adb shell
   ```
3. Locate the UFS block devices:
   - On the Tab S6, internal UFS storage is `/dev/block/sda` (LUN 0, main user data).
   - `/dev/block/by-name/cache` (~1.2 GB) is repurposed as the **EFI System Partition (ESP)**.
   - `/dev/block/by-name/userdata` (~110 GB+) is used for the **Linux Rootfs**.

4. Format the ESP partition as FAT32:
   ```bash
   mkfs.vfat -F 32 -n "ESP" /dev/block/by-name/cache
   ```

5. Format the Linux rootfs partition as EXT4:
   ```bash
   mkfs.ext4 -L "fedora_root" -O ^metadata_csum /dev/block/by-name/userdata
   ```

---

## Phase 4: Deploying Linux Rootfs & System Overlay

1. Mount the partitions in your recovery environment:
   ```bash
   mkdir -p /mnt/rootfs /mnt/esp
   mount /dev/block/by-name/userdata /mnt/rootfs
   mount /dev/block/by-name/cache /mnt/esp
   ```

2. Extract your chosen AArch64 rootfs (e.g. Fedora, Debian, Arch):
   ```bash
   tar -xpf fedora-rootfs.tar.xz -C /mnt/rootfs/
   ```

3. Extract the kernel modules:
   ```bash
   tar -xzpf bin/modules-6.12.tar.gz -C /mnt/rootfs/
   ```

4. Apply the hardware configuration files from this repository:
   ```bash
   cp etc/modules-load.d/tabs6.conf /mnt/rootfs/etc/modules-load.d/
   cp etc/udev/rules.d/99-tabs6.rules /mnt/rootfs/etc/udev/rules.d/
   cp etc/systemd/system/tabs6-*.service /mnt/rootfs/etc/systemd/system/
   mkdir -p /mnt/rootfs/etc/alsa/ucm2/sm8150-samsung-gts6l/
   cp etc/alsa/ucm2/sm8150-samsung-gts6l/* /mnt/rootfs/etc/alsa/ucm2/sm8150-samsung-gts6l/
   ```

5. Enable the hardware services in rootfs:
   ```bash
   chroot /mnt/rootfs /bin/bash -c "
     systemctl enable tabs6-charge.service
     systemctl enable tabs6-powerkeyd.service
     systemctl enable tabs6-idled.service
     systemctl enable tabs6-wifi.service
   "
   ```

6. Extract device firmware blobs:
   Follow [`etc/firmware/README.md`](../etc/firmware/README.md) to place required GPU, DSP, and Wi-Fi blobs into `/mnt/rootfs/lib/firmware/`.

---

## Phase 5: Setting up the ESP (systemd-boot)

1. Create the EFI directory tree on `/mnt/esp`:
   ```bash
   mkdir -p /mnt/esp/EFI/BOOT /mnt/esp/EFI/systemd /mnt/esp/loader/entries
   ```

2. Copy the kernel and device tree to the ESP:
   ```bash
   cp bin/Image /mnt/esp/Image
   cp bin/sm8150-samsung-gts6l.dtb /mnt/esp/sm8150-samsung-gts6l.dtb
   ```

3. Install `systemd-boot` AArch64 binary:
   ```bash
   cp /mnt/rootfs/usr/lib/systemd/boot/efi/systemd-bootaarch64.efi /mnt/esp/EFI/BOOT/BOOTAA64.EFI
   ```

4. Configure `/mnt/esp/loader/loader.conf`:
   ```ini
   default linux.conf
   timeout 3
   console-mode max
   ```

5. Create `/mnt/esp/loader/entries/linux.conf`:
   ```ini
   title Linux Mainline (Galaxy Tab S6)
   linux /Image
   devicetree /sm8150-samsung-gts6l.dtb
   options root=PARTLABEL=userdata rootwait rw quiet loglevel=4 console=tty0 earlycon
   ```

6. Unmount partitions cleanly:
   ```bash
   umount /mnt/esp
   umount /mnt/rootfs
   sync
   ```

---

## Phase 6: First Boot & Lifeline

1. Reboot the tablet:
   ```bash
   reboot
   ```
2. The tablet will initialize through Project Aloha UEFI, show the `systemd-boot` menu, and boot into your Linux distribution.
3. **Emergency USB Lifeline:** The kernel and userspace are preconfigured to enable composite USB networking (RNDIS) on the Type-C port:
   - Tablet IP: `192.168.42.1`
   - Host PC IP: `192.168.42.2`
   - Access the device via SSH:
     ```bash
     ssh root@192.168.42.1
     ```
   - Serial console is also available via ACM `/dev/ttyACM0` (or `COMx` on Windows).
