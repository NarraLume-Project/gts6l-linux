# Guia: Adaptando o Port para Outras Distribuições Linux

[![Language: English](https://img.shields.io/badge/Language-English-blue.svg)](DISTRO_PORTING.md) [![Português](https://img.shields.io/badge/Vers%C3%A3o-Portugu%C3%AAs-green.svg)](#)

> [!NOTE]
> [🇺🇸 Click here to read this guide in English](DISTRO_PORTING.md)

---

A arquitetura deste port é **independente de distribuição**. O suporte de hardware reside inteiramente no firmware UEFI, no Kernel Linux 6.12 Mainline e em interfaces e padrões universais do Linux (KMS/DRM, V4L2, ALSA UCM2, Libinput e udev).

Dessa forma, você pode adaptar este projeto com facilidade para **Arch Linux ARM, Debian, Ubuntu, postmarketOS, Alpine ou openSUSE**.

---

## 🏗️ Arquitetura Técnica

1. **Camada de Firmware:** O Project Mu / EDK2 UEFI disponibiliza serviços EFI padrão, tabelas ACPI/SMBIOS e o framebuffer nativo na resolução de 2560x1600.
2. **Bootloader:** Qualquer gerenciador EFI padrão (`systemd-boot`, `GRUB2` ou `rEFInd`) carrega a imagem do kernel (`Image`) e o arquivo DTB correspondente (`sm8150-samsung-gts6l.dtb`).
3. **Subsistema Gráfico:** Opera via driver de framebuffer `simpledrm`, pareado com a GPU Adreno 640 em modo render-only através da camada Mesa `kmsro` / `freedreno`.
4. **Entrada de Toque e Caneta:** Touchscreen (`fts1ba90a`) e mesa digitalizadora S-Pen (`wacom_w9021`) comunicam-se via eventos `evdev` com o `libinput`.
5. **Áudio:** Os amplificadores digitais Cirrus CS35L41 são controlados via perfis de áudio ALSA UCM2.

---

## 📋 Requisitos para a Nova Distribuição

Independentemente da distribuição escolhida, certifique-se de cumprir os seguintes pontos:

### 1. Arquitetura
- O pacote do sistema raiz (Rootfs) deve ser compilado para **AArch64 (`arm64`)**.

### 2. Stack Gráfica
- **Mesa:** Deve conter suporte aos drivers `freedreno`, `kmsro` e `swrast` (ex: pacote `mesa-dri-drivers` ou `mesa`).
- **Compositor Gráfico:** Ambientes Wayland (KWin Wayland, Mutter, Sway, Weston) funcionam nativamente sobre o `simpledrm`. No X11, recomenda-se o driver `modesetting`.

### 3. Módulos e Kernel
- Utilize o pacote pré-compilado `modules-6.12.tar.gz` ou compile o kernel da distribuição usando o `gts6l_defconfig`.
- Ative o carregamento dos módulos na inicialização via `/etc/modules-load.d/tabs6.conf`.

### 4. Blobs de Firmware
- Extraia e copie os binários da Qualcomm e Cirrus para `/lib/firmware/` conforme instruído em [`etc/firmware/README.md`](../etc/firmware/README.md).

---

## 🚀 Roteiro Prático: Passo a Passo

### Exemplo: Instalando Arch Linux ARM ou Debian

```bash
# 1. Monte as partições de destino
mount /dev/block/by-name/userdata /mnt/rootfs
mount /dev/block/by-name/cache /mnt/esp

# 2. Extraia o rootfs AArch64 da sua distribuição
tar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C /mnt/rootfs/

# 3. Instale os módulos de kernel do Tab S6
tar -xzpf bin/modules-6.12.tar.gz -C /mnt/rootfs/

# 4. Copie a sobreposição de configurações deste repositório
cp etc/modules-load.d/tabs6.conf /mnt/rootfs/etc/modules-load.d/
cp etc/udev/rules.d/99-tabs6.rules /mnt/rootfs/etc/udev/rules.d/
cp etc/systemd/system/tabs6-*.service /mnt/rootfs/etc/systemd/system/
mkdir -p /mnt/rootfs/etc/alsa/ucm2/sm8150-samsung-gts6l/
cp etc/alsa/ucm2/sm8150-samsung-gts6l/* /mnt/rootfs/etc/alsa/ucm2/sm8150-samsung-gts6l/

# 5. Extraia os firmwares do hardware
./etc/firmware/extract_firmware.sh /mnt/rootfs/lib/firmware

# 6. Copie os binários de boot para a partição ESP
cp bin/Image /mnt/esp/Image
cp bin/sm8150-samsung-gts6l.dtb /mnt/esp/sm8150-samsung-gts6l.dtb

# 7. Configure a entrada de inicialização do bootloader (ex: systemd-boot)
cat << 'EOF' > /mnt/esp/loader/entries/arch.conf
title Arch Linux ARM (Galaxy Tab S6)
linux /Image
devicetree /sm8150-samsung-gts6l.dtb
options root=PARTLABEL=userdata rootwait rw quiet loglevel=4
EOF
```

---

## 🧩 Distribuições sem Systemd (Alpine, Void, postmarketOS)

Caso utilize runit ou OpenRC:
1. **Módulos:** Insira os nomes dos módulos de `etc/modules-load.d/tabs6.conf` no arquivo `/etc/modules`.
2. **Serviço de Carga da Bateria:** Configure o script `tools/tabs6-charge.sh` em um script local OpenRC (`/etc/local.d/tabs6-charge.start`).
3. **Botão Power e Suspensão:** Execute os daemons `tools/tabs6-powerkeyd.py` e `tools/tabs6-idled.py` através do supervisor de serviços do seu sistema.
