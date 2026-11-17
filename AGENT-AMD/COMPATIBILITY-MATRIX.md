# T27 — AGENT-AMD — COMPATIBILITY MATRIX 25G342 → 26B131

**Scope:** sette kext Navi14, driver Metal recuperato, GLDriver, matching PCI, simboli, dipendenze, UUID/architetture e ricerca di sostituti AMD in 26B131.  
**Modalità:** read-only; nessuna compilazione, patch, firma, installazione, `kextload` o boot.  
**Esito:** **COMPATIBLE = 0**; **POTENTIALLY COMPATIBLE = 0**; i kext donor restano **UNPROVEN**; MTL/GL/Shared sono **INCOMPATIBLE** per il target. Nessun sostituto AMD esiste in 26B131.

---

## 1. Matrice principale

| Componente | Build | Arch | UUID | PCI Navi14 | Simboli / ABI | Dipendenze 26B131 | Classe |
|---|---|---|---|---|---|---|---|
| root2 `AMDRadeonX6000.kext` | 25G325 / 7.1.8 | x86_64 | `1540D089-EE2D-3339-B5A8-2024F9E38581` | `7340/41/43/47/4F` (metadati) | 28 import diretti; ABI non testata | AMD/IOKit non presenti | **UNPROVEN** |
| root2 `AMDRadeonX6000Framebuffer.kext` | 25G325 / 7.1.8 | x86_64 | `F527F501-CD46-34D0-AEB3-C8E5C8ADF2C8` | Navi14 controller | 25 import; ABI non testata | AMD/IOKit non presenti | **UNPROVEN** |
| root2 `AMDRadeonX6000HWServices.kext` | 25G325 / 7.1.8 | x86_64 | `4A753C5A-7010-390E-B234-0DB2765A37E9` | servizio Navi | 19 import; ABI non testata | AMD/IOKit non presenti | **UNPROVEN** |
| root2 `AMDRadeonX6000HWLibs.kext` | 25G325 / 1.0 | x86_64 | `5CD4BC0C-C225-365F-A872-C885575B9A19` | libreria hardware | 24 import; ABI non testata | AMD/IOKit non presenti | **UNPROVEN** |
| root2 `AMDSupport.kext` | 25G325 / 7.1.8 | x86_64 | `736ECBBA-C9C9-3AF7-BE6A-EB1944DB515B` | infrastruttura | 23 import; ABI non testata | AMD/IOKit non presenti | **UNPROVEN** |
| root2 `AMDFramebuffer.kext` | 25G325 / 7.1.8 | x86_64 | `2723D92D-6032-3051-9874-A87DE97B25CB` | generico | 30 import; ABI non testata | AMD/IOKit non presenti | **UNPROVEN** |
| root2 `AMDRadeonServiceManager.kext` | 25G325 / 7.1.8 | x86_64 | `53316747-531F-3003-97A7-4B51226A731D` | gestione servizi | 21 import; ABI non testata | AMD/IOKit non presenti | **UNPROVEN** |
| root3 `AMDRadeonX6000.kext` | 25G342/26B116 / 7.1.8 | x86_64 | `1540D089-EE2D-3339-B5A8-2024F9E38581` | `7340` ecc. | 28 import; ABI non testata | AMD/IOKit non presenti | **UNPROVEN** |
| MTL driver HAO-68 | sistema 25G342; SDK 25G325 | x86_64h | `F89F483D-39AC-368D-B9D9-FB689179EFD2` | stringhe GFX10/Navi14 | 663 undefined; deps assenti | Metal/MPS/IOAccel assenti | **INCOMPATIBLE** |
| GLDriver root25 | 25G342 / 26.7 | x86_64h | `346DD4A5-26E9-3F13-9E16-BF2329A590D2` | GFX10 | OpenGL, non Metal | deps assenti | **INCOMPATIBLE** |
| `AMDRadeonX6000Shared` | 25G342 | — | — | riferimento MTL | **nessun Mach-O** | non disponibile | **INCOMPATIBLE** |
| target 26B131 AMD | 26B131 | — | — | — | 0 bundle AMD | — | **INCOMPATIBLE** (assente) |
| KDK 26B131 AMD | 26B131/26B116 | — | — | — | 0 bundle AMD | — | **INCOMPATIBLE** (assente) |

> **T27 fingerprint (16 Nov 2026):** root3 contiene **5/6** binari con SHA identico a `systemkc-all` (`AMDSupport`, `X6000Framebuffer`, `X6000HWServices`, `ServiceManager`, `X6000`); `X6100HWLibs` è assente. Root2 ha **0/6** match esatti; root25 non ha binari AMD. Dettaglio: `AMD-POOL-FINGERPRINTS.md`.

`COMPATIBLE = 0` e `POTENTIALLY COMPATIBLE = 0`: non c’è una prova ABI né una catena di dipendenze 26B131. I sette kext sono `UNPROVEN`, non “potenzialmente compatibili”: la differenza è che manca anche il test minimo.

---

## 2. Perché i kext sono UNPROVEN

### 2.1 Architettura e matching PCI

Tutti i sette binari root2 sono **x86_64**; il target è x86_64. Il matching PCI è presente nei metadati:

```text
AMDRadeonX6000_AMDNavi14GraphicsAccelerator:
0x73401002 0x73411002 0x73431002 0x73471002 0x734F1002
```

`AMDRadeonX6000Framebuffer` contiene il controller Navi14. Questo prova il **matching dichiarato**, non il caricamento.

### 2.2 Simboli

Conteggio diretto `nm -u`:

| Binario | Import |
|---|---:|
| root2 X6000 | 28 |
| root2 X6000Framebuffer | 25 |
| root2 X6000HWServices | 19 |
| root2 HWLibs | 24 |
| root2 AMDSupport | 23 |
| root2 AMDFramebuffer | 30 |
| root2 ServiceManager | 21 |
| root3 X6000 | 28 |

Il kernel 26B131 espone 24.399 simboli con `nm -gU`, ma l’intersezione diretta con i 28 import del kext è **0**: non è una prova di incompatibilità, perché i nomi C++/KPI e il linking kext non sono confrontabili con una semplice intersezione. La conclusione corretta è **ABI non verificata**, non “0 simboli risolvibili”.

Il driver MTL ha **663 undefined**; le sue 11 dipendenze framework sono assenti nei materiali (vedi `RUNTIME-CLOSURE-REPORT.md`).

### 2.3 UUID

| Componente | UUID |
|---|---|
| root2 X6000 / root3 X6000 | `1540D089-EE2D-3339-B5A8-2024F9E38581` |
| root2 X6000Framebuffer | `F527F501-CD46-34D0-AEB3-C8E5C8ADF2C8` |
| root2 HWServices | `4A753C5A-7010-390E-B234-0DB2765A37E9` |
| root2 HWLibs | `5CD4BC0C-C225-365F-A872-C885575B9A19` |
| MTL | `F89F483D-39AC-368D-B9D9-FB689179EFD2` |
| GL | `346DD4A5-26E9-3F13-9E16-BF2329A590D2` |

Root2 e root3 X6000 hanno **lo stesso UUID ma hash diverso** (`8874ae65…` vs `2734aaf7…`): non sono automaticamente intercambiabili. Root3 X6000 è invece **identico a `systemkc-all`**; root2 non lo è. Root3 fornisce 5/6 binari esatti, root2 0/6. MTL e GL hanno UUID propri; non esiste un UUID 26B131 correspondente.

---

## 3. Dipendenze

I kext AMD dichiarano dipendenze IOKit (`IOGraphicsFamily`, `IOAcceleratorFamily2`, `IOPCIFamily`, `IOSurface`, `AppleGraphicsDeviceControl`) e, per il framebuffer, `IOACPIFamily`.

Nel target 26B131:

- 0 bundle AMD/ATI;
- 0 `AMDRadeonX6000`, `AMDSupport`, `AMDFramebuffer`, `AMDRadeonServiceManager`;
- nessun binario `Metal.framework` o `IOAccelerator.framework` ai path attesi;
- nessuna coppia KC 26B131 che possa fornire il contesto kext.

Nel KDK 26B131: 0 bundle AMD/ATI. Il KDK usa kext 26B116 per altri componenti, non per AMD.

---

## 4. Ricerca sostituti 26B131

| Ricerca | Risultato |
|---|---|
| `AMD*` / `*Radeon*` in target Extensions | **0** |
| `AMD*` / `*Radeon*` in KDK 26B131 | **0** |
| `AMDRadeonX6000MTLDriver` 26B131 | **ASSENTE** |
| `AMDRadeonX6000GLDriver` 26B131 | **ASSENTE** |
| `AMDRadeonX6000Shared` 26B131 | **ASSENTE** |
| `Metal.framework` binario target | **ASSENTE** |
| `IOAccelerator.framework` binario target | **ASSENTE** |
| `AMDNavi14` / `GFX10` in target | **nessuna interfaccia AMD** |
| Sostituto generico Metal/AMD | **nessuno** |

Il target ha un catalogo di framework (340 top-level) ma i sample non contengono i binari correnti. Non esiste un’interfaccia AMD sostitutiva.

---

## 5. Classificazione finale

| Classe | Componenti | Motivo |
|---|---|---|
| **COMPATIBLE** | **0** | nessuna prova 26B131 |
| **POTENTIALLY COMPATIBLE** | **0** | nessuna ABI/dipendenza verificata; non basta l’x86_64 |
| **INCOMPATIBLE** | MTL 25G342, GL 25G342, Shared, target/KDK AMD | build 26.7, bundle incompleto, deps assenti, nessun AMD 26B131 |
| **UNPROVEN** | 7 kext root2 + X6000 root3 | x86_64 e PCI presenti, ma 25G325/25G342 e nessun test ABI |

**Nessun componente AMD è dichiarabile compatibile con 26B131.**

---

## 6. Conclusione

- **E — display interno:** **BLOCKED**.
- **G — WindowServer:** **BLOCKED**; il driver MTL esiste come prova 25G342, ma la closure fallisce.
- **H — desktop:** **BLOCKED**.
- **UCLK/GPU init:** **UNPROVEN**; le fonti Linux non sono prove macOS.

**STOP rispettato:** sola lettura; nessuna compilazione, patch, firma, installazione, `kextload`, boot o download. Spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB. Nessuna modifica a T16–T26.
