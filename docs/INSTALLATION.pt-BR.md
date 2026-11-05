# Guia de Instalação do Linux no Galaxy Tab S6 (SM-T865 / SM-T860)

[![Language: English](https://img.shields.io/badge/Language-English-blue.svg)](INSTALLATION.md) [![Português](https://img.shields.io/badge/Vers%C3%A3o-Portugu%C3%AAs-green.svg)](#)

> [!NOTE]
> [🇺🇸 Click here to read this installation guide in English](INSTALLATION.md)

---

Este guia detalha o procedimento completo para instalar o Linux Mainline nativo (como Fedora 44 KDE, Debian ou Ubuntu) no seu Samsung Galaxy Tab S6 LTE (`SM-T865`, `gts6l`) ou Wi-Fi (`SM-T860`, `gts6lwifi`).

---

## ⚠️ Pré-requisitos e Cuidados

1. **Bootloader Desbloqueado:** O desbloqueio restaura o aparelho para as configurações de fábrica e ativa permanentemente o Knox (0x1). Faça backup de todos os seus arquivos pessoais antes de prosseguir.
2. **Ferramentas no Computador:**
   - PC com Windows, Drivers USB da Samsung instalados e [Odin3 v3.14.4](https://odindownload.com/).
   - Alternativamente, máquina com Linux/macOS usando `heimdall-flash` e `adb` / `fastboot`.
3. **Cabo USB:** Cabo USB-C para USB-A de qualidade conectado diretamente a uma porta da placa-mãe.
4. **Arquivos deste repositório:**
   - Bootloader UEFI preparado: `bin/boot-uefi.tar.md5`
   - Imagem do Kernel: `bin/Image`
   - Device Tree compilado: `bin/sm8150-samsung-gts6l.dtb` (LTE) ou `bin/sm8150-samsung-gts6lwifi.dtb` (Wi-Fi)
   - Pacote de módulos compilados: `bin/modules-6.12.tar.gz`
   - Arquivo do sistema raiz (Rootfs, ex: Fedora 44 aarch64 ou outra distribuição)

---

## Etapa 1: Desbloqueio do Bootloader

1. No tablet, dentro do Android: vá em **Configurações > Sobre o tablet > Informações do software** e toque repetidamente em **Número de compilação** até ativar as Opções do Desenvolvedor.
2. Acesse **Opções do desenvolvedor** e ative o **Desbloqueio por OEM** e a **Depuração USB**.
3. Desligue o tablet. Segure **Volume Mais + Volume Menos** juntos e conecte o cabo USB ao computador.
4. Na tela azul/verde de advertência, mantenha pressionado **Volume Mais** para iniciar o desbloqueio. Confirme a operação na tela seguinte (o tablet será formatado).
5. Ligue o Android uma vez, conecte à internet para garantir que o Desbloqueio por OEM permaneça ativado.

---

## Etapa 2: Gravação do Bootloader UEFI pelo Odin

O bootloader primário da Samsung (ABL) valida assinaturas AVB nos pacotes de boot. Nosso arquivo `boot-uefi.tar.md5` contém o kernel stock v1 modificado pelo DualBootKernelPatcher com o payload UEFI do Project Aloha:

1. Desligue o tablet. Segure **Volume Mais + Volume Menos** e conecte o cabo USB ao computador para entrar no **Modo Download**.
2. Pressione **Volume Mais** uma vez para confirmar.
3. Abra o **Odin3 v3.14.4** no PC e confirme se a porta `ID:COM` ficou azul/verde.
4. Clique no botão **AP** e selecione o arquivo `bin/boot-uefi.tar.md5`.
5. Mantenha os campos BL, CP e CSC vazios.
6. Na aba Options, mantenha selecionadas apenas **Auto Reboot** e **F. Reset Time**.
7. Clique em **Start**. O Odin gravará a imagem e o tablet reiniciará.

> [!TIP]
> Ao reiniciar, o tablet iniciará o firmware UEFI do Project Aloha com o painel configurado na resolução nativa de 2560x1600.

---

## Etapa 3: Particionamento do Armazenamento Interno UFS

O particionamento pode ser feito via TWRP Recovery ou através de um Live Shell EFI:

1. Inicie no TWRP Recovery (segure **Power + Volume Mais** ao ligar).
2. Abra o terminal ADB no seu computador:
   ```bash
   adb shell
   ```
3. Mapeie as partições de armazenamento interno:
   - A memória UFS interna é representada por `/dev/block/sda` (LUN 0 principal).
   - A partição `/dev/block/by-name/cache` (~1.2 GB) é convertida para a **Partição de Sistema EFI (ESP)**.
   - A partição `/dev/block/by-name/userdata` (~110 GB+) é utilizada para o **Sistema Raiz (Rootfs)**.

4. Formate a partição ESP em FAT32:
   ```bash
   mkfs.vfat -F 32 -n "ESP" /dev/block/by-name/cache
   ```

5. Formate a partição raiz em EXT4:
   ```bash
   mkfs.ext4 -L "fedora_root" -O ^metadata_csum /dev/block/by-name/userdata
   ```

---

## Etapa 4: Extração do Rootfs e Configurações

1. Monte as partições no ambiente do recovery:
   ```bash
   mkdir -p /mnt/rootfs /mnt/esp
   mount /dev/block/by-name/userdata /mnt/rootfs
   mount /dev/block/by-name/cache /mnt/esp
   ```

2. Extraia o sistema raiz AArch64 desejado:
   ```bash
   tar -xpf fedora-rootfs.tar.xz -C /mnt/rootfs/
   ```

3. Instale os módulos do kernel:
   ```bash
   tar -xzpf bin/modules-6.12.tar.gz -C /mnt/rootfs/
   ```

4. Copie os arquivos de configuração de hardware deste repositório:
   ```bash
   cp etc/modules-load.d/tabs6.conf /mnt/rootfs/etc/modules-load.d/
   cp etc/udev/rules.d/99-tabs6.rules /mnt/rootfs/etc/udev/rules.d/
   cp etc/systemd/system/tabs6-*.service /mnt/rootfs/etc/systemd/system/
   mkdir -p /mnt/rootfs/etc/alsa/ucm2/sm8150-samsung-gts6l/
   cp etc/alsa/ucm2/sm8150-samsung-gts6l/* /mnt/rootfs/etc/alsa/ucm2/sm8150-samsung-gts6l/
   ```

5. Habilite os serviços essenciais de sistema:
   ```bash
   chroot /mnt/rootfs /bin/bash -c "
     systemctl enable tabs6-charge.service
     systemctl enable tabs6-powerkeyd.service
     systemctl enable tabs6-idled.service
     systemctl enable tabs6-wifi.service
   "
   ```

6. Extraia os firmwares proprietários:
   Siga as instruções de [`etc/firmware/README.md`](../etc/firmware/README.md) para salvar os blobs de GPU, DSP e Wi-Fi em `/mnt/rootfs/lib/firmware/`.

---

## Etapa 5: Configuração do Bootloader ESP (systemd-boot)

1. Crie a estrutura de diretórios na partição ESP:
   ```bash
   mkdir -p /mnt/esp/EFI/BOOT /mnt/esp/EFI/systemd /mnt/esp/loader/entries
   ```

2. Copie o kernel e o device tree para a ESP:
   ```bash
   cp bin/Image /mnt/esp/Image
   cp bin/sm8150-samsung-gts6l.dtb /mnt/esp/sm8150-samsung-gts6l.dtb
   ```

3. Instale o executável do `systemd-boot` para AArch64:
   ```bash
   cp /mnt/rootfs/usr/lib/systemd/boot/efi/systemd-bootaarch64.efi /mnt/esp/EFI/BOOT/BOOTAA64.EFI
   ```

4. Crie o arquivo `/mnt/esp/loader/loader.conf`:
   ```ini
   default linux.conf
   timeout 3
   console-mode max
   ```

5. Crie a entrada de inicialização `/mnt/esp/loader/entries/linux.conf`:
   ```ini
   title Linux Mainline (Galaxy Tab S6)
   linux /Image
   devicetree /sm8150-samsung-gts6l.dtb
   options root=PARTLABEL=userdata rootwait rw quiet loglevel=4 console=tty0 earlycon
   ```

6. Desmonte as partições de forma segura:
   ```bash
   umount /mnt/esp
   umount /mnt/rootfs
   sync
   ```

---

## Etapa 6: Primeira Inicialização e Linha de Vida (USB Lifeline)

1. Reinicie o tablet:
   ```bash
   reboot
   ```
2. O tablet iniciará através do UEFI, exibirá o menu do `systemd-boot` e carregará o ambiente Linux.
3. **Linha de Vida USB (Acesso de Emergência):** O sistema está configurado para subir uma rede composta USB RNDIS na porta Type-C:
   - IP do Tablet: `192.168.42.1`
   - IP do Computador: `192.168.42.2`
   - Conexão via SSH:
     ```bash
     ssh root@192.168.42.1
     ```
   - O console serial interativo também está disponível em `/dev/ttyACM0` (porta `COMx` no Windows).
