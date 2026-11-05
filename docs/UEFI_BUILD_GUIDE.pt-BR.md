# Guia: Como Compilar o Firmware UEFI para o Galaxy Tab S6

[![Language: English](https://img.shields.io/badge/Language-English-blue.svg)](UEFI_BUILD_GUIDE.md) [![Português](https://img.shields.io/badge/Vers%C3%A3o-Portugu%C3%AAs-green.svg)](#)

> [!NOTE]
> [🇺🇸 Click here to read this guide in English](UEFI_BUILD_GUIDE.md)

---

Este guia fornece o passo a passo completo para compilar o **firmware UEFI Project Mu / EDK2** para os tablets **Samsung Galaxy Tab S6 LTE (`SM-T865`) e Wi-Fi (`SM-T860`)** a partir do repositório dedicado de código-fonte: [NarraLume-Project/mu-msm-gts6l](https://github.com/NarraLume-Project/mu-msm-gts6l).

---

## 🛠️ Requisitos e Toolchain

### Sistema Recomendado:
- Ubuntu 24.04 LTS, Ubuntu 22.04 LTS ou WSL2 no Windows.
- Pelo menos 16 GB de espaço livre em disco.
- Compilador cruzado AArch64 e LLVM/Clang.

### 1. Instalação dos Pacotes do Sistema

```bash
sudo apt update
sudo apt install -y uuid-dev clang llvm gcc-aarch64-linux-gnu lld git mono-devel \
                    build-essential iasl nasm python3 python3-pip python3-venv \
                    gettext locales gnupg ca-certificates curl
```

### 2. Instalação do NuGet

O utilitário NuGet é necessário pelo sistema de build Stuart para restaurar dependências de pacotes da plataforma:

```bash
sudo curl -o /usr/local/bin/nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
```

---

## 📥 Clonando o Repositório

Clone o repositório dedicado do UEFI:

```bash
git clone https://github.com/NarraLume-Project/mu-msm-gts6l.git
cd mu-msm-gts6l
```

---

## ⚙️ Configuração do Ambiente de Build

Defina as variáveis de ambiente necessárias para o compilador cruzado AArch64 Clang/LLVM:

```bash
export CLANGPDB_BIN=/usr/lib/llvm-38/bin/
export CLANGPDB_AARCH64_PREFIX=aarch64-linux-gnu-
```

Crie e ative um ambiente virtual Python:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r pip-requirements.txt
```

---

## 🔨 Comandos de Compilação

A compilação é automatizada pelo script `build_uefi.py`.

### Para o Samsung Galaxy Tab S6 LTE (`SM-T865`):

```bash
python3 build_uefi.py -d samsung-gts6l -r RELEASE
```

### Para o Samsung Galaxy Tab S6 Wi-Fi (`SM-T860`):

```bash
python3 build_uefi.py -d samsung-gts6lwifi -r RELEASE
```

> [!TIP]
> Caso necessite de logs detalhados de depuração via console serial, altere `-r RELEASE` para `-r DEBUG`.

---

## 📦 Arquivo Binário Gerado

Ao término do processo de compilação, o arquivo binário do Firmware Volume UEFI estará em:

```text
Build/SurfaceDuo1-AARCH64/RELEASE_CLANG38/FV/SM8150_EFI_NOSB.fd
```

---

## 📲 Empacotando para o Bootloader da Samsung

O bootloader primário da Samsung (ABL) não inicializa arquivos EFI brutos. O binário `.fd` gerado deve ser encapsulado no formato aceito pelo aparelho utilizando as ferramentas da pasta `samsung_handoff/`:

```bash
cd samsung_handoff

# Desempacota o boot original da Samsung
magiskboot unpack stock-boot.img

# Injeta o firmware UEFI no kernel do boot
./DualBootKernelPatcher ./kernel ../Build/SurfaceDuo1-AARCH64/RELEASE_CLANG38/FV/SM8150_EFI_NOSB.fd \
                        ./patched_kernel Config/DualBoot.Sm8150.cfg ShellCode.TabS6UEFI.bin

cp patched_kernel kernel

# Remonta mantendo as assinaturas AVB e trailers da Samsung
magiskboot repack stock-boot.img uefi-boot.img

# Cria o arquivo .tar.md5 para gravação via Odin
tar -H ustar -c uefi-boot.img vbmeta-flags3.img > boot-uefi.tar
md5sum -t boot-uefi.tar >> boot-uefi.tar
mv boot-uefi.tar boot-uefi.tar.md5
```

O arquivo final `boot-uefi.tar.md5` pode agora ser gravado na partição **AP** pelo Odin3 ou Heimdall.
