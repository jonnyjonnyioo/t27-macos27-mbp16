# T27 — AGENT-AMD — DIPENDENZE E PROVIDER

**Scope:** verificare se X5400 e AMDSupport soddisfano dipendenze e matching del provider oltre alla exclude list; estrarre `OSBundleLibraries`, `OSBundleRequired`, bundle ID e personalità; classificare separatamente dipendenze soddisfatte, mancanti o indeterminate.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, plist `PRELINK_INFO`, `system_profiler`; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che tutte le `OSBundleLibraries` di X5400 e AMDSupport sono presenti con versione sufficiente. **PROVEN** che la GPU è `AMD Radeon Pro 5300M`, device `0x7340`, e che `AMDRadeonX6000HWServices` la matcha. **PROVEN** che `AMDRadeonX5000HWServices` matcha solo ID Vega e che X5400 richiede `AMDRadeonX5000_AMDRadeonHWServicesInterface`. **UNPROVEN** il matching X5400 sul device `0x7340` e il caricamento runtime. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 91 | `ff83147a9f1495cd5d182f0f54ccc79df45e95494425e1dd1d40d004152d8a3a` |
| Report 92 | `771347abf31cb0e6f333861efc6569135059e1f91cc8ceb606e47f288c40a1b2` |
| Report 93 | `516daa4e342f8cb04c4574950889a6c06d67100bbb1dda7e6dcd5a97e27da1a2` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Metadati kext

| Campo | AMDSupport | X5400 |
|---|---|---|
| Bundle ID | `com.apple.kext.AMDSupport` | `com.apple.kext.AMDRadeonX5400HWLibs` |
| `CFBundleVersion` | `7.0.1` | `1.0` |
| `CFBundleShortVersionString` | `7.1.8` | `1.0` |
| `OSBundleCompatibleVersion` | `7.0.1` | `1.0` |
| `OSBundleRequired` | `Safe Boot` | assente |
| Sorgente | SystemKC | SystemKC |

**PROVEN:** i metadati sono nel `PRELINK_INFO` del SystemKC.

---

## 3. Dipendenze AMDSupport

| Dipendenza | Richiesta | Presente | Versione | Esito |
|---|---:|---|---:|---|
| `com.apple.AppleGraphicsDeviceControl` | `3.0.0` | **SÌ** | `8.1.12` | **SODDISFATTA** |
| `com.apple.iokit.IOACPIFamily` | `1.2` | **SÌ** | `1.4` | **SODDISFATTA** |
| `com.apple.iokit.IOGraphicsFamily` | `1.3` | **SÌ** | `600` | **SODDISFATTA** |
| `com.apple.iokit.IOPCIFamily` | `1.2` | **SÌ** | `2.9` | **SODDISFATTA** |
| `com.apple.kpi.bsd` | `10.0.0` | **SÌ** | `25.6.0` | **SODDISFATTA** |
| `com.apple.kpi.iokit` | `10.0.0` | **SÌ** | `25.6.0` | **SODDISFATTA** |
| `com.apple.kpi.libkern` | `10.0.0` | **SÌ** | `25.6.0` | **SODDISFATTA** |
| `com.apple.kpi.mach` | `10.0.0` | **SÌ** | `25.6.0` | **SODDISFATTA** |
| `com.apple.kpi.unsupported` | `10.0.0` | **SÌ** | `25.6.0` | **SODDISFATTA** |

**PROVEN:** tutte le dipendenze sono presenti e le versioni richieste sono superate.

---

## 4. Dipendenze X5400

| Dipendenza | Richiesta | Presente | Versione | Esito |
|---|---:|---|---:|---|
| `com.apple.iokit.IOPCIFamily` | `2.9` | **SÌ** | `2.9` | **SODDISFATTA** |
| `com.apple.kpi.bsd` | `16.0` | **SÌ** | `25.6.0` | **SODDISFATTA** |
| `com.apple.kpi.iokit` | `16.0` | **SÌ** | `25.6.0` | **SODDISFATTA** |
| `com.apple.kpi.libkern` | `16.0` | **SÌ** | `25.6.0` | **SODDISFATTA** |
| `com.apple.kpi.mach` | `16.0` | **SÌ** | `25.6.0` | **SODDISFATTA** |

**PROVEN:** tutte le dipendenze sono presenti e le versioni richieste sono superate.

---

## 5. Personalità

| Kext | Personalità | `IOClass` | `IOProviderClass` | Match |
|---|---|---|---|---|
| AMDSupport | `ATI Support` | `AMDSupport` | `IOPCIDevice` | `IOPCIMatch 0x00001002&0x0000FFFF`; `IOPCIClassMatch 0x03000000&0xFF000000` |
| X5400 | `AMDRadeonHWLibs` | `AMDRadeonX5400_AMDRadeonHWLibsX5400` | `AMDRadeonX5000_AMDRadeonHWServicesInterface` | `IOPropertyMatch LoadPlugIn=Load5400` |
| X5000HWServices | `AMD Radeon X5000 HW Services` | `AMDRadeonX5000_AMDRadeonHWServicesVega` | `IOPCIDevice` | ID Vega `0x6860`…`0x69AF`, `0x66A0`…`0x66AF` |
| X6000HWServices | `AMD Radeon X6000 HW Services` | `AMDRadeonX6000_AMDRadeonHWServicesNavi` | `IOPCIDevice` | include `0x73401002` |

**PROVEN:** AMDSupport matcha qualsiasi controller display AMD (`0x1002`, classe `0x03000000`).
**PROVEN:** X5000HWServices non include `0x7340`.
**PROVEN:** X6000HWServices include `0x73401002`.
**PROVEN:** X5400 richiede la classe provider X5000, non la classe Navi X6000.

---

## 6. Hardware

| Campo | Valore |
|---|---|
| GPU | `AMD Radeon Pro 5300M` |
| Device ID | `0x7340` |
| Vendor | `0x1002` |
| Fonte | `system_profiler SPDisplaysDataType` |

**PROVEN:** la GPU è Navi 14 `0x7340`.
**PROVEN:** il device è AMD (`0x1002`).
**UNPROVEN:** l’eventuale ereditarietà tra la classe Navi X6000 e l’interfaccia X5000.

---

## 7. Matching provider

| Kext | Provider richiesto | Provider disponibile | Esito |
|---|---|---|---|
| AMDSupport | `IOPCIDevice` AMD display | GPU `0x7340` | **MATCH STATICO** |
| X5400 | `AMDRadeonX5000_AMDRadeonHWServicesInterface` | X5000HWServices solo Vega | **NON DIMOSTRATO** |
| X5400 | `LoadPlugIn=Load5400` | X6000HWServices Navi `0x7340` | **NON DIMOSTRATO** |

**PROVEN:** AMDSupport ha un match statico con la GPU.
**PROVEN:** X5000HWServices non matcha `0x7340`.
**UNPROVEN:** che X5400 trovi un provider X5000 sul device Navi.

---

## 8. Classificazione

| Kext | Dipendenze | Exclude list | Provider | Runtime |
|---|---|---|---|---|
| AMDSupport | **SODDISFATTE** | **ASSENTE** | **MATCH STATICO** | **UNPROVEN** |
| X5400 | **SODDISFATTE** | **ASSENTE** | **NON DIMOSTRATO** | **UNPROVEN** |

**PROVEN:** le dipendenze non sono il blocco.
**PROVEN:** la exclude list non è il blocco.
**UNPROVEN:** il provider X5400 è il punto critico.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Dipendenze AMDSupport | **TUTTE SODDISFATTE** |
| Dipendenze X5400 | **TUTTE SODDISFATTE** |
| Exclude list | **NESSUNA DELLE DUE** |
| AMDSupport provider | **MATCH STATICO** |
| X5400 provider | **NON DIMOSTRATO** |
| X5000HWServices su `0x7340` | **NO** |
| X6000HWServices su `0x7340` | **SÌ** |
| Caricamento runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le dipendenze di X5400 e AMDSupport sono tutte presenti e le versioni richieste sono superate; la exclude list non contiene nessuno dei due. AMDSupport ha un match statico con la GPU AMD `0x7340`. X5400 richiede il provider `AMDRadeonX5000_AMDRadeonHWServicesInterface`, ma X5000HWServices matcha solo ID Vega e la GPU è Navi 14 `0x7340`, gestita da X6000HWServices. Il matching X5400 sul device reale resta **NON DIMOSTRATO**; il caricamento runtime resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
