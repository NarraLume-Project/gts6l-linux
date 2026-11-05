# Guide: Compiling the UEFI Firmware for Galaxy Tab S6

[![Language: English](https://img.shields.io/badge/Language-English-blue.svg)](#) [![Português](https://img.shields.io/badge/Vers%C3%A3o-Portugu%C3%AAs-green.svg)](UEFI_BUILD_GUIDE.pt-BR.md)

> [!NOTE]
> [🇧🇷 Clique aqui para ler este guia em Português](UEFI_BUILD_GUIDE.pt-BR.md)

---

This guide provides instructions for compiling the **Project Mu / EDK2 UEFI firmware** for the **Samsung Galaxy Tab S6 LTE (`SM-T865`) and Wi-Fi (`SM-T860`)** directly from the dedicated source repository: [NarraLume-Project/mu-msm-gts6l](https://github.com/NarraLume-Project/mu-msm-gts6l).

---

## 🛠️ Requirements & Toolchain

### Recommended Build Host:
- Ubuntu 24.04 LTS, Ubuntu 22.04 LTS, or Windows Subsystem for Linux (WSL2).
- Minimum 16 GB of free disk space.
- AArch64 cross-compiler toolchain and LLVM/Clang.

### 1. Install System Packages

```bash
sudo apt update
sudo apt install -y uuid-dev clang llvm gcc-aarch64-linux-gnu lld git mono-devel \
                    build-essential iasl nasm python3 python3-pip python3-venv \
                    gettext locales gnupg ca-certificates curl
```

### 2. Install NuGet

NuGet is required by the Stuart build system to restore platform package dependencies:

```bash
sudo curl -o /usr/local/bin/nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
```

---

## 📥 Cloning the Repository

Clone the dedicated UEFI repository with full submodules and history:

```bash
git clone https://github.com/NarraLume-Project/mu-msm-gts6l.git
cd mu-msm-gts6l
```

---

## ⚙️ Build Environment Setup

Set required environment variables for the AArch64 Clang/LLVM toolchain:

```bash
export CLANGPDB_BIN=/usr/lib/llvm-38/bin/
export CLANGPDB_AARCH64_PREFIX=aarch64-linux-gnu-
```

Create and activate a dedicated Python virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r pip-requirements.txt
```

---

## 🔨 Compiling the Firmware

The compilation is automated via the `build_uefi.py` script.

### For Samsung Galaxy Tab S6 LTE (`SM-T865`):

```bash
python3 build_uefi.py -d samsung-gts6l -r RELEASE
```

### For Samsung Galaxy Tab S6 Wi-Fi (`SM-T860`):

```bash
python3 build_uefi.py -d samsung-gts6lwifi -r RELEASE
```

> [!TIP]
> To generate a build with detailed serial console debugging output enabled, change `-r RELEASE` to `-r DEBUG`.

---

## 📦 Generated Firmware Artifact

When the build finishes, the output UEFI Firmware Volume binary will be generated at:

```text
Build/SurfaceDuo1-AARCH64/RELEASE_CLANG38/FV/SM8150_EFI_NOSB.fd
```

---

## 📲 Packaging into a Samsung Boot Image

Samsung's locked bootloader does not allow booting raw EFI images. The compiled `.fd` must be wrapped into a stock boot container using the tools in the `samsung_handoff/` directory:

```bash
cd samsung_handoff

# Unpack stock boot image
magiskboot unpack stock-boot.img

# Inject UEFI payload into kernel envelope
./DualBootKernelPatcher ./kernel ../Build/SurfaceDuo1-AARCH64/RELEASE_CLANG38/FV/SM8150_EFI_NOSB.fd \
                        ./patched_kernel Config/DualBoot.Sm8150.cfg ShellCode.TabS6UEFI.bin

cp patched_kernel kernel

# Repack with original Samsung AVB & SEANDROIDENFORCE trailers
magiskboot repack stock-boot.img uefi-boot.img

# Package into Odin-flashable tar
tar -H ustar -c uefi-boot.img vbmeta-flags3.img > boot-uefi.tar
md5sum -t boot-uefi.tar >> boot-uefi.tar
mv boot-uefi.tar boot-uefi.tar.md5
```

The resulting `boot-uefi.tar.md5` can now be flashed via the AP slot in Odin3.
