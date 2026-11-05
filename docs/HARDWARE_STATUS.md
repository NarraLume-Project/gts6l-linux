# Galaxy Tab S6 Linux Hardware Support Status

[![Language: English](https://img.shields.io/badge/Language-English-blue.svg)](#) [![Português](https://img.shields.io/badge/Vers%C3%A3o-Portugu%C3%AAs-green.svg)](HARDWARE_STATUS.pt-BR.md)

> [!NOTE]
> [🇧🇷 Clique aqui para ler a tabela de hardware em Português](HARDWARE_STATUS.pt-BR.md)

---

## 📊 Subsystem Status Overview

| Subsystem | Status | Driver / Mechanism | Technical Details & Notes |
|---|---|---|---|
| **UEFI Chainloader** | ✅ Working | Project Aloha EDK2 / DualBootKernelPatcher | Successfully chainloads from Samsung ABL to Project Aloha UEFI; initializes 2560x1600 framebuffer. |
| **Internal Storage** | ✅ Working | Linux UFS driver (`ufs_qcom`) | UFS 3.0 storage fully operational; `BRANCH_HALT_SKIP` clock fix resolves TrustZone timeout hangs. |
| **Display Output** | ✅ Working | `simpledrm` over EFI GOP framebuffer | Native 2560x1600 WQXGA resolution at 60 Hz. Color profiles and software brightness dimming working. |
| **GPU Acceleration** | ✅ Working | Adreno 640 (`msm` / freedreno) | Render-only node paired with simpledrm via Mesa KMSRO. Full OpenGL 3.3 and Vulkan acceleration in KDE Plasma. |
| **Touchscreen** | ✅ Working | STMicro `fts1ba90a` (SEC-TS) | Multitouch, gesture recognition, and palm rejection working via GPI-DMA on QUP2. |
| **S-Pen Digitizer** | ✅ Working | Wacom `w9021` (`drivers/input/...`) | Absolute X/Y coordinate tracking, 4096 pressure levels, tilt, distance/hover, and side stylus button. |
| **Audio Playback** | ✅ Working | 4x Cirrus `CS35L41` via Secondary TDM | Quad AKG speakers functional through ALSA UCM2 audio profile and PipeWire sound server. |
| **Audio Capture** | ✅ Working | Cirrus `CS48L33` via Quinary MI2S | Microphone recording enabled via PipeWire direct source declaration. |
| **Wi-Fi** | ✅ Working | Qualcomm `ath10k_snoc` (WCN3990) | Dual-band 802.11ac Wi-Fi up to 866.7 Mbps. Memory carveout relocated into HLOS DDR to prevent TZ access violation. |
| **Bluetooth** | ✅ Working | Qualcomm `hci_qca` on UART | Bluetooth 5.0 operational. Scans, pairs, and maintains stable connections with mice, keyboards, and audio sinks. |
| **Battery & Fuel Gauge** | ✅ Working | Samsung `sm5705_fuelgauge` on I2C | Real-time battery percentage, voltage, charging state, and current monitoring. |
| **Charging Control** | ✅ Working | `tabs6-charge.service` | Maintains full 2000 mA charging current across cable insertion/re-negotiation. |
| **USB Type-C & Host** | ✅ Working | Qualcomm `dwc3` dual-role controller | Type-C USB 2.0 host mode powers hubs, flash drives, keyboards, and mice; USB device mode provides RNDIS lifeline. |
| **Hardware Buttons** | ✅ Working | PMIC PON & PM8150L GPIO12 | Power button, Volume Down (PMIC PON), and Volume Up (PM8150L GPIO12) register correctly. |
| **Power Management** | ✅ Working | PMIC `PS_HOLD` | Clean poweroff and reboot routed through PMIC PS_HOLD, bypassing broken PSCI firmware calls. |
| **Suspend / Sleep** | ✅ Working | `s2idle` & `tabs6-idled.py` | Low-power sleep states, 1.5s wake-up time, touchscreen and Wi-Fi resume without panic. |
| **Sensors** | ✅ Working | LSM6DSO via Hexagon SLPI DSP | Accelerometer auto-rotation working through libssc and iio-sensor-proxy. |
| **Cellular Calls (Modem)** | 🟡 WIP | Qualcomm Modem Subsystem | SIM detection and data active; voice call routing via mainline audio pipeline in development. |
| **Cameras** | 🔴 Not Working | Qualcomm Spectra 380 ISP / CAMSS | Requires downstream camera sensor drivers and CSI-2 bridge bringup; currently unsupported. |
| **Fingerprint Reader** | 🔴 Not Working | Optical in-display sensor | Proprietary secure-world enclave sensor; no open-source Linux mainline driver exists. |
