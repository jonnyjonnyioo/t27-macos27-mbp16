# T27 — AGENT-AMD — ALTERNATIVE PATHS

**Scope:** determinare se esistono percorsi alternativi, indipendenti dall’ereditarietà X5000/X6000, che consentano il caricamento di X5400 sulla Radeon Pro 5300M (`0x7340`); analizzare tutte le personalità Navi 14, i provider dell’interfaccia X5000, alias, factory e dipendenze.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, fileset, symbol table, plist `PRELINK_INFO`, `system_profiler`; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che Navi 14 è coperta solo dalla famiglia X6000 e che l’interfaccia X5000 è registrata esclusivamente in X5000HWServices. **REFUTED** l’esistenza di un provider alternativo o di un percorso statico indipendente da `Load5400`. **UNPROVEN** il caricamento runtime di X5400. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 96 | `de9f18fb4959cb8453ad586fcd83a2fd050b3b30dac814a4c1d99470ac609b22` |
| Report 97 | `8909fa19c965d2db639ca2f42426151230074e293ee0e61fa87a9ac18f09ee3a` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Personalità Navi 14

| Kext | Personalità | `IOClass` | Match |
|---|---|---|---|
| `AMDRadeonX6000` | `AMDNavi14GraphicsAccelerator` | `AMDRadeonX6000_AMDNavi14GraphicsAccelerator` | `0x73401002`…`0x734F1002` |
| `AMDRadeonX6000Framebuffer` | `AMDRadeonNavi14Controller` | `AMDRadeonX6000_AmdRadeonControllerNavi14` | `0x73401002`…`0x734F1002` |
| `AMDRadeonX6000HWServices` | `AMD Radeon X6000 HW Services` | `AMDRadeonX6000_AMDRadeonHWServicesNavi` | include `0x73401002` |
| `AMDRadeonX5400HWLibs` | `AMDRadeonHWLibs` | `AMDRadeonX5400_AMDRadeonHWLibsX5400` | **nessun match Navi 14** |

**PROVEN:** Navi 14 è gestita da tre personalità X6000.
**PROVEN:** X5400 non ha personalità Navi 14.
**REFUTED:** un’associazione diretta X5400 ↔ `0x7340`.

---

## 3. Provider dell’interfaccia X5000

| Evidenza | Esito |
|---|---|
| Simboli X5000 Interface | **solo in X5000HWServices** |
| Altri kext con la classe | **nessuno** |
| Altri kext con il letterale | **nessuno** |
| Registrazione dinamica | **non osservata** |
| Alias | **nessuno** |
| Factory IOKit | **nessuna** |

**PROVEN:** l’unico publisher della classe X5000 è X5000HWServices.
**PROVEN:** X5000HWServices non matcha `0x7340`.
**REFUTED:** un provider X5000 alternativo.

---

## 4. Dipendenze

| Kext | Dipendenze principali | AMDSupport? |
|---|---|---|
| `AMDRadeonX6000` | IOAcceleratorFamily2, IOGraphicsFamily, IOPCIFamily, IOSurface, kpi | **NO** |
| `AMDRadeonX6000Framebuffer` | AppleGraphicsDeviceControl, IOACPIFamily, IOGraphicsFamily, IOPCIFamily, kpi | **NO** |
| `AMDRadeonX6000HWServices` | IOACPIFamily, IOGraphicsFamily, IOPCIFamily, kpi | **NO** |
| `AMDRadeonX6000HWLibs` | IOPCIFamily, kpi | **NO** |
| `AMDRadeonX5400HWLibs` | IOPCIFamily, kpi | **NO** |

**PROVEN:** nessuna dipendenza della famiglia X6000 richiede AMDSupport.
**PROVEN:** X5400 non dipende da X6000.
**REFUTED:** una catena di dipendenza AMDSupport → X6000 → X5400.

---

## 5. Percorsi indipendenti da `Load5400`

| Percorso | Esito |
|---|---|
| Seconda personalità X5400 | **assente** |
| Alias `Load5400` | **assente** |
| Factory dinamica | **assente** |
| Caricamento forzato | **non previsto** |
| Dipendenza da X6000 | **assente** |
| Dipendenza da AMDSupport | **assente** |

**PROVEN:** X5400 ha una sola personalità.
**PROVEN:** `Load5400` compare solo nella personalità X5400.
**REFUTED:** un percorso statico indipendente.

---

## 6. Catena reale su Navi 14

```text
GPU 0x7340
  -> X6000 accelerator
  -> X6000 framebuffer
  -> X6000 HWServices (Navi)
     -> X6000 HWLibs
        -> X6000 Interface

X5400
  -> provider X5000 Interface
     -> X5000HWServices (solo Vega)
        -> nessun match 0x7340
```

| Passo | Esito |
|---|---|
| GPU → X6000 | **PROVEN** |
| X6000 → X6000 Interface | **PROVEN** |
| X6000 Interface → X5000 Interface | **REFUTED** |
| X5000HWServices → `0x7340` | **REFUTED** |
| X5400 → provider X5000 | **UNPROVEN** |
| X5400 caricato | **UNPROVEN** |

---

## 7. Classificazione

| Affermazione | Esito |
|---|---|
| Navi 14 usa X6000 | **PROVEN** |
| X5400 è associato a Navi 14 | **REFUTED** |
| X5000 Interface ha un solo publisher | **PROVEN** |
| X5000HWServices matcha `0x7340` | **REFUTED** |
| X6000 fornisce X5000 Interface | **REFUTED** |
| X6000 pubblica `Load5400` | **REFUTED** |
| Percorso alternativo statico | **REFUTED** |
| Caricamento runtime X5400 | **UNPROVEN** |

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Provider alternativo X5000 | **NO** |
| Alias/factory | **NO** |
| X5400 su Navi 14 | **NO, staticamente** |
| X5400 dipende da X6000 | **NO** |
| X5400 dipende da AMDSupport | **NO** |
| Percorso indipendente da `Load5400` | **NO** |
| X5400 caricato | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** Navi 14 è gestita esclusivamente dalla famiglia X6000 (`AMDRadeonX6000`, `X6000Framebuffer`, `X6000HWServices`). L’interfaccia X5000 è registrata solo in X5000HWServices, che non matcha `0x7340`; X6000 non la fornisce, non pubblica `Load5400` e non ha dipendenze verso AMDSupport o X5400. Non esiste un provider alternativo, un alias, una factory o un percorso statico indipendente da `Load5400`: il caricamento statico di X5400 su `0x7340` è **REFUTED**. Il caricamento runtime resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
