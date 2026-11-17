# T27 — AGENT-04 — AMD NAVI14 / RADEON PRO 5300M

**Scope:** X6000, Framebuffer, HWLibs, SMU, firmware, UCLK, gMux, eDP, Metal, WindowServer.  
**Mode:** read-only. **Nessun boot, nessun test GPU, nessun Metal.**  
**Stato:** **BLOCKED per il target; codice donor presente, compatibilità 26B131 UNPROVEN.**

---

## 1. Hardware e codice disponibile

| Voce | Valore | Fonte |
|---|---|---|
| GPU | AMD Radeon Pro 5300M, Navi14 | target / T25 |
| PCI ID | `1002:7340` (altri Navi14 `7341/7343/7347/734F`) | T25 metadati |
| iGPU | Intel UHD Graphics 630 | target |
| Display | eDP interno + gMux | T25 |
| Driver macOS osservato | famiglia `AMDRadeonX6000` 7.1.8 | root2 25G325 |

### 1.1 Bundle AMD

Root2 contiene i sette bundle x86_64 Apple-signed:

- `AMDRadeonX6000.kext` — `8874ae65…`;
- `AMDRadeonX6000Framebuffer.kext` — `d037b095…`;
- `AMDRadeonX6000HWServices.kext` — `9d50f380…`;
- `AMDRadeonX6000HWLibs.kext` — `7d078501…`;
- `AMDSupport.kext` — `b222e4bc…`;
- `AMDFramebuffer.kext` — `0e79c809…`;
- `AMDRadeonServiceManager.kext` — `6b7586dc…`.

Questi bundle sono **build 25G325/7.1.8**, non 26B131. Nel target 26B131 e nel KDK 26B131 i bundle AMD sono **assenti**.

Il driver Metal userspace **esiste** come binario recuperato dalla dyld shared cache del sistema 25G342; l’SDK di compilazione è 25G325: `AMDRadeonX6000MTLDriver`, 7.716.152 B, x86_64h, SHA-256 `f4c8ef463b57792e7a982c4a4eb1b0d1c81098e1c4ee186c2ef13935c4bb9ff0`, `minos 26.7`, non firmato. Non è un bundle 26B131 e il bundle root25 non contiene l’eseguibile. Dettaglio in `AGENT-AMD/METAL-USERSPACE-REPORT.md`.

### 1.2 Cosa provano i metadati

Gli ID Navi14 sono presenti nelle personalità; esistono classi x86_64 per acceleratore e controller. Questo prova **solo** che il codice donor dichiara il supporto metadata. Non prova:

- caricamento contro kernel 26B131;
- inizializzazione GPU/SMU;
- firmware/VBIOS compatibile;
- UCLK stabile;
- gMux/eDP;
- Metal o WindowServer.

---

## 2. Matrice di maturità

| Livello | Stato | Evidenza |
|---|---|---|
| PCI ID nei metadati | **VERIFIED (metadata)** | `1002:7340` e altri ID Navi14 |
| Codice x86_64 donor | **PRESENTE** | 7 bundle root2 25G325 |
| Dipendenze IOKit | **PARZIALE** | IOGraphics/IOAccelerator/IOSurface presenti come build diverse |
| Build 26B131 | **ASSENTE** | target/KDK no AMD |
| Kernel 26B131 | **UNPROVEN** | nessun test |
| GPU init / SMU / firmware | **UNPROVEN** | nessun boot |
| UCLK | **UNPROVEN** | prove Linux, non macOS |
| gMux / eDP / backlight | **BLOCKED** | nessun test, nessun pannello |
| Metal | **BLOCKED** | driver 25G-series recuperato, non firmato e non 26B131; bundle incompleto |
| WindowServer | **BLOCKED** | dipende da Metal/display |

---

## 3. UCLK e firmware: separazione Linux/macOS

La fonte Linux DRI-devel documenta, su tre MacBookPro16,1:

- tabelle VBIOS/`umc_info` non allineate;
- SMU hang/CATERR con tabella stock;
- correzione tramite tabella addestrata;
- la patch v5 **rinvia** UCLK, non corregge i livelli.

Queste sono prove **Linux/amdgpu**. Non dimostrano:

- che macOS usi la stessa tabella;
- che il driver Apple sia affetto o immune;
- che la VBIOS locale del MacBookPro16,1 sia quella osservata;
- che il primo boot macOS sia stabile.

Nel binario Apple compare la stringa `UCLK`, ma questo è solo un nome, non una prova di comportamento. **UCLK su macOS 26B131: UNPROVEN.**

---

## 4. eDP, gMux, Metal

Non esiste una prova locale di:

- inizializzazione del pannello eDP interno;
- commutazione gMux;
- backlight;
- accelerazione Metal su Navi14;
- WindowServer su Navi14;
- sleep/wake con display interno.

Un display esterno non è una prova del pannello interno. HAO ha un desktop verificato su MacBookPro9,2/HD 4000; è un’altra GPU e un altro percorso display.

---

## 5. Conclusione

**La Radeon Pro 5300M non è dichiarabile compatibile con 26B131.** Il codice donor esiste, ma è 25G325/7.1.8 e non è mai stato caricato contro il kernel target.

**Stato:** **BLOCKED** per display interno, Metal e WindowServer; **UNPROVEN** per GPU init e UCLK.  
**Handoff:** l’integratore deve mantenere separati “codice presente”, “binario Metal recuperato” e “display funzionante”; nessuna fase desktop può essere dichiarata prima di un test GPU controllato.
