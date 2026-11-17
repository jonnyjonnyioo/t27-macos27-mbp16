# T27 — AGENT-AMD — NAVI 14 COVERAGE

**Scope:** stabilire se la catena X6000 costituisce il percorso AMD completo per Navi 14 (`0x7340`) e identificare componenti mancanti rispetto all’hardware reale; ricostruire personalità, provider, interfacce e dipendenze.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, plist `PRELINK_INFO`, `system_profiler`; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che la famiglia X6000 copre staticamente Navi 14: acceleratore, framebuffer, HWServices e HWLibs hanno personalità coerenti e tutte le dipendenze sono soddisfatte. **PROVEN** che X6000HWServices pubblica l’interfaccia X6000 e X6000HWLibs la matcha con `Load6000`. **PROVEN** che X5400 appartiene alla famiglia X5000 e non a Navi 14. **UNPROVEN** l’accelerazione runtime. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 96 | `de9f18fb4959cb8453ad586fcd83a2fd050b3b30dac814a4c1d99470ac609b22` |
| Report 97 | `8909fa19c965d2db639ca2f42426151230074e293ee0e61fa87a9ac18f09ee3a` |
| Report 98 | `4e2d91b4299c77152a7d975ffb692704c0a8fc9f2310c5f6a405c9e07b54046b` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Catena Navi 14

```text
GPU 0x7340
  -> AMDRadeonX6000            (accelerator, IOPCIDevice)
  -> AMDRadeonX6000Framebuffer (controller, IOPCIDevice)
  -> AMDRadeonX6000HWServices  (Navi HWServices, IOPCIDevice)
     -> pubblica X6000 Interface
        -> AMDRadeonX6000HWLibs (Load6000)
```

| Componente | Personalità | `IOClass` | Provider |
|---|---|---|---|
| Accelerator | `AMDNavi14GraphicsAccelerator` | `AMDRadeonX6000_AMDNavi14GraphicsAccelerator` | `IOPCIDevice` |
| Framebuffer | `AMDRadeonNavi14Controller` | `AMDRadeonX6000_AmdRadeonControllerNavi14` | `IOPCIDevice` |
| HWServices | `AMD Radeon X6000 HW Services` | `AMDRadeonX6000_AMDRadeonHWServicesNavi` | `IOPCIDevice` |
| HWLibs | `AMDRadeonHWLibs` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |

**PROVEN:** tutte le personalità Navi 14 sono nella famiglia X6000.
**PROVEN:** X6000HWLibs usa `Load6000`.
**PROVEN:** X6000HWLibs richiede l’interfaccia X6000; X6000HWServices è la personalità Navi della stessa famiglia. Il matching provider resta **UNPROVEN**.

---

## 3. Matching

| Kext | Match | Esito |
|---|---|---|
| X6000 accelerator | `0x73401002`…`0x734F1002` | **MATCH** |
| X6000 framebuffer | `0x73401002`…`0x734F1002` | **MATCH** |
| X6000HWServices | include `0x73401002` | **MATCH** |
| X6000HWLibs | `Load6000` | **MATCH** |
| X5400HWLibs | `Load5400` + X5000 Interface | **NO MATCH** |

**PROVEN:** i quattro componenti X6000 matchano la GPU o l’interfaccia X6000.
**REFUTED:** un match X5400 con Navi 14.

---

## 4. Dipendenze

### X6000 accelerator

| Dipendenza | Richiesta | Presente | Versione |
|---|---:|---|---:|
| `IOAcceleratorFamily2` | `2.0.0` | **SÌ** | `487.4.4` |
| `IOGraphicsFamily` | `1.0.0b1` | **SÌ** | `600` |
| `IOPCIFamily` | `1.0.0b1` | **SÌ** | `2.9` |
| `IOSurface` | `87.0` | **SÌ** | `393.5.11` |
| `kpi.*` | `8.0.0` | **SÌ** | `25.6.0` |

### X6000 framebuffer

| Dipendenza | Richiesta | Presente | Versione |
|---|---:|---|---:|
| `AppleGraphicsDeviceControl` | `3.22.0` | **SÌ** | `8.1.12` |
| `IOACPIFamily` | `1.4` | **SÌ** | `1.4` |
| `IOGraphicsFamily` | `2.4.1` | **SÌ** | `600` |
| `IOPCIFamily` | `2.9` | **SÌ** | `2.9` |
| `kpi.*` | `15.0.0` | **SÌ** | `25.6.0` |

### X6000HWServices

| Dipendenza | Richiesta | Presente | Versione |
|---|---:|---|---:|
| `IOACPIFamily` | `1.4` | **SÌ** | `1.4` |
| `IOGraphicsFamily` | `2.4.1` | **SÌ** | `600` |
| `IOPCIFamily` | `2.9` | **SÌ** | `2.9` |
| `kpi.*` | `15.0.0` | **SÌ** | `25.6.0` |

### X6000HWLibs

| Dipendenza | Richiesta | Presente | Versione |
|---|---:|---|---:|
| `IOPCIFamily` | `2.9` | **SÌ** | `2.9` |
| `kpi.*` | `16.0` | **SÌ** | `25.6.0` |

**PROVEN:** tutte le dipendenze X6000 sono soddisfatte.
**PROVEN:** nessuna dipendenza richiede AMDSupport.

---

## 5. Copertura

| Funzione | Componente | Esito |
|---|---|---|
| Enumerazione PCI | AMDSupport / IOPCIDevice | **PRESENTE** |
| Accelerazione | X6000 | **PRESENTE** |
| Framebuffer | X6000Framebuffer | **PRESENTE** |
| HWServices | X6000HWServices | **PRESENTE** |
| HWLibs | X6000HWLibs | **PRESENTE** |
| Interfaccia X6000 | richiesta da X6000HWLibs | **PRESENTE** |
| Interfaccia X5000 | X5000HWServices | **NON Navi 14** |

**PROVEN:** la copertura statica Navi 14 è completa.
**REFUTED:** una lacuna Navi 14 nella famiglia X6000.
**UNPROVEN:** l’accelerazione runtime effettiva.

---

## 6. Ruolo di X5400

| Elemento | Esito |
|---|---|
| Famiglia | **X5000** |
| Provider | **X5000 Interface** |
| Match | **Load5400** |
| GPU coperta | **Vega** |
| Navi 14 | **NO** |
| Caricamento su `0x7340` | **UNPROVEN** |
| Necessario per Navi 14 | **NO** |

**PROVEN:** X5400 è un componente X5000.
**REFUTED:** X5400 necessario per Navi 14.

---

## 7. Classificazione

| Affermazione | Esito |
|---|---|
| X6000 copre Navi 14 | **PROVEN** |
| X6000HWLibs matcha X6000 Interface | **PROVEN** |
| X6000HWLibs richiede X6000 Interface | **PROVEN** |
| Dipendenze X6000 soddisfatte | **PROVEN** |
| X5400 copre Navi 14 | **REFUTED** |
| X5400 necessario a Navi 14 | **REFUTED** |
| Accelerazione runtime | **UNPROVEN** |

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Componenti X6000 presenti | **SÌ, staticamente** |
| Componenti Navi 14 mancanti | **NESSUNO OSSERVATO** |
| X6000HWLibs provider | **X6000 Interface** |
| X5400 su Navi 14 | **NO** |
| X5400 necessario | **NO** |
| Accelerazione runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la famiglia X6000 copre staticamente Navi 14 con acceleratore, framebuffer, HWServices e HWLibs; tutte le personalità matchano `0x7340` o l’interfaccia X6000 e tutte le dipendenze sono soddisfatte. X6000HWLibs richiede l’interfaccia X6000 con `Load6000`; la personalità Navi di X6000HWServices è della stessa famiglia, ma il matching provider resta **UNPROVEN**. X5400 è un componente X5000 con `Load5400`, non necessario e non associato a Navi 14. Non risultano componenti Navi 14 mancanti; l’accelerazione runtime resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
