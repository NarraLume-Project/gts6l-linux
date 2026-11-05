# Status de Suporte de Hardware no Galaxy Tab S6

[![Language: English](https://img.shields.io/badge/Language-English-blue.svg)](HARDWARE_STATUS.md) [![Português](https://img.shields.io/badge/Vers%C3%A3o-Portugu%C3%AAs-green.svg)](#)

> [!NOTE]
> [🇺🇸 Click here to read this hardware table in English](HARDWARE_STATUS.md)

---

## 📊 Tabela de Status dos Subsistemas

| Subsistema | Status | Driver / Mecanismo | Detalhes Técnicos e Observações |
|---|---|---|---|
| **Bootloader UEFI** | ✅ Funcionando | Project Aloha EDK2 / DualBootKernelPatcher | Inicialização em cadeia bem-sucedida a partir do ABL da Samsung; framebuffer configurado em 2560x1600. |
| **Armazenamento Interno** | ✅ Funcionando | Driver Linux UFS (`ufs_qcom`) | Armazenamento UFS 3.0 de alta velocidade totalmente funcional; correção `BRANCH_HALT_SKIP` elimina travamentos por timeout do TrustZone. |
| **Exibição de Tela** | ✅ Funcionando | `simpledrm` sobre o framebuffer EFI GOP | Resolução nativa WQXGA (2560x1600) a 60 Hz. Controle de brilho via software e renderização estável. |
| **Aceleração Gráfica (GPU)** | ✅ Funcionando | Adreno 640 (`msm` / freedreno) | Nó render-only pareado com simpledrm via Mesa KMSRO. Suporte completo a OpenGL 3.3 e Vulkan no KDE Plasma. |
| **Tela de Toque (Touchscreen)** | ✅ Funcionando | STMicro `fts1ba90a` (SEC-TS) | Multitouch, gestos e rejeição de palma operando perfeitamente via GPI-DMA no barramento QUP2. |
| **Mesa Digitalizadora / S-Pen** | ✅ Funcionando | Wacom `w9021` (`drivers/input/...`) | Rastreamento absoluto de coordenadas X/Y, 4096 níveis de pressão, inclinação, proximidade/hover e botão lateral. |
| **Reprodução de Áudio** | ✅ Funcionando | 4x Cirrus `CS35L41` via Secondary TDM | Alto-falantes quádruplos AKG operacionais com perfil ALSA UCM2 e servidor de áudio PipeWire. |
| **Captura de Áudio (Microfones)** | ✅ Funcionando | Cirrus `CS48L33` via Quinary MI2S | Gravação de microfone funcionando via declaração de source direta no PipeWire. |
| **Wi-Fi** | ✅ Funcionando | Qualcomm `ath10k_snoc` (WCN3990) | Wi-Fi 802.11ac dual-band até 866.7 Mbps. Carveout de memória movido para região de RAM DDR do HLOS para evitar conflito com TrustZone. |
| **Bluetooth** | ✅ Funcionando | Qualcomm `hci_qca` em UART | Bluetooth 5.0 estável para pareamento e conexão contínua de fones, teclados e mouses. |
| **Medição de Bateria** | ✅ Funcionando | Samsung `sm5705_fuelgauge` em I2C | Leitura precisa de porcentagem de carga, voltagem, corrente e estado de alimentação. |
| **Controle de Carga** | ✅ Funcionando | `tabs6-charge.service` | Mantém corrente de carregamento contínua em 2000 mA mesmo após desconexões/renegociações do cabo. |
| **USB Type-C e Host** | ✅ Funcionando | Controlador dual-role Qualcomm `dwc3` | Modo USB 2.0 Host alimenta hubs, pendrives, teclados e mouses; modo periférico provê rede RNDIS de emergência. |
| **Botões Físicos** | ✅ Funcionando | PMIC PON e PM8150L GPIO12 | Botão Power, Volume Menos (PMIC PON) e Volume Mais (PM8150L GPIO12) reportam eventos corretamente. |
| **Gerenciamento de Energia** | ✅ Funcionando | PMIC `PS_HOLD` | Desligamento e reinicialização limpos via registrador PS_HOLD, contornando falhas de firmware do PSCI. |
| **Suspensão e Retomada** | ✅ Funcionando | `s2idle` e `tabs6-idled.py` | Estado de suspensão de baixo consumo; retorno rápido em 1.5s sem perda de toque ou travamento de Wi-Fi. |
| **Sensores de Rotação** | ✅ Funcionando | LSM6DSO via DSP Hexagon SLPI | Rotação automática de tela com acelerômetro via libssc e iio-sensor-proxy. |
| **Chamadas Telefônicas (Modem)** | 🟡 Em Progresso | Modem Qualcomm Subsystem | Reconhecimento de chip SIM e dados móveis ativos; áudio de chamadas de voz via mainline em desenvolvimento. |
| **Câmeras** | 🔴 Não Funcional | Qualcomm Spectra 380 ISP / CAMSS | Requer integração de drivers de sensor e pontes CSI-2; não disponível no momento. |
| **Leitor Biométrico** | 🔴 Não Funcional | Sensor óptico sob a tela | Sensor proprietário restrito ao ambiente seguro (Secure World); sem driver aberto disponível. |
