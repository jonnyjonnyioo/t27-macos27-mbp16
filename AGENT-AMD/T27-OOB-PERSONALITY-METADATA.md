# T27 — AGENT-AMD — PERSONALITY METADATA

**Scope:** analizzare la struttura interna della personality X6000HWLibs, confrontare tutte le personality AMD, verificare `IOKitPersonalities`, `OSBundleLibraries`, `OSBundleRequired`, `LoadPlugIn`, `IOProviderClass`, `IOClass`, `IOProbeScore`, `IOResourceMatch` e distinguere metadati da attivazione.

**Modalità:** sola lettura; plist XML di SystemKC estratto e interpretato con `plistlib`; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che X6000HWLibs è una personality completa ma priva di `IOProbeScore`, `OSBundleRequired` e `IOResourceMatch`; **PROVEN** che nessun altro bundle la referenzia. **UNPROVEN** l’attivazione runtime. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| Report 131 | `be9e6438f281be907a6e811cda2960cafff9728db30b5359019768a01f288800` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Plist

| Test | Esito |
|---|---|
| `<plist>` | `0x3C08E` |
| Kext unici | **172** |
| HWLibs | **16** |
| HWServices | **3** |
| Framebuffer | **1** |
| Parse | **OK** |

**PROVEN:** il plist è valido.
**PROVEN:** i bundle sono 172.
**UNPROVEN:** il runtime.

---

## 3. HWLibs

| Bundle | IOClass | Provider | Load | Score |
|---|---|---|---|---:|
| X4000 | `...HWLibsCAIL` | X4000 Interface | `Load4000` | `10` |
| X4100 | `...HWLibsCAIL` | X4000 Interface | `Load4100` | `10` |
| X4400 | `...HWLibsCAIL` | X4000 Interface | `Load4400` | `10` |
| X4700 | `...HWLibsCAIL` | X4000 Interface | `Load4700` | `10` |
| X5000 | `...HWLibsX5000` | X5000 Interface | `Load5000` | **assente** |
| X5100 | `...HWLibsX5100` | X5000 Interface | `Load5100` | **assente** |
| X5200 | `...HWLibsX5200` | X5000 Interface | `Load5200` | **assente** |
| X5400 | `...HWLibsX5400` | X5000 Interface | `Load5400` | **assente** |
| X5700 | `...HWLibsX5700` | X5000 Interface | `Load5700` | **assente** |
| X6000 | `...HWLibsX6000` | X6000 Interface | `Load6000` | **assente** |
| X6100 | `...HWLibsX6100` | X6000 Interface | `Load6100` | **assente** |
| X6200 | `...HWLibsX6200` | X6000 Interface | `Load6200` | **assente** |
| X6300 | `...HWLibsX6300` | X6000 Interface | `Load6300` | **assente** |
| X6700 | `...HWLibsX6700` | X6000 Interface | `Load6700` | **assente** |
| X6800 | `...HWLibsX6800` | X6000 Interface | `Load6800` | **assente** |
| X6810 | `...HWLibsX6810` | X6000 Interface | `Load6810` | **assente** |

**PROVEN:** 16 HWLibs.
**PROVEN:** `IOProbeScore` solo per X4000.
**PROVEN:** X5000/X6000 non hanno score.
**UNPROVEN:** l’effetto dello score.

---

## 4. X6000HWLibs

| Campo | Valore |
|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX6000HWLibs` |
| `CFBundleExecutable` | `AMDRadeonX6000HWLibs` |
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| `IOMatchCategory` | `AMDRadeonHWLibs` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch` | `{LoadPlugIn: Load6000}` |
| `IOProbeScore` | **assente** |
| `IOResourceMatch` | **assente** |
| `OSBundleRequired` | **assente** |
| `IOPCITunnelCompatible` | `true` |
| `IOPersonalityPublisher` | `com.apple.kext.AMDRadeonX6000HWLibs` |

**PROVEN:** la personality è completa.
**PROVEN:** non ha score/required/resource-match.
**PROVEN:** il match è dichiarativo.
**UNPROVEN:** l’attivazione.

---

## 5. Dipendenze

| Dipendenza | X6000HWLibs |
|---|---|
| `com.apple.iokit.IOPCIFamily` | `2.9` |
| `com.apple.kpi.bsd` | `16.0` |
| `com.apple.kpi.iokit` | `16.0` |
| `com.apple.kpi.libkern` | `16.0` |
| `com.apple.kpi.mach` | `16.0` |
| HWServices | **assente** |

**PROVEN:** nessuna dipendenza di linkage da HWServices.
**PROVEN:** il legame è `IOProviderClass`.
**UNPROVEN:** il runtime.

---

## 6. HWServices

| Bundle | IOClass | Provider | Score | Required |
|---|---|---|---:|---|
| X4000 | `...HWServicesPolaris` | `IOPCIDevice` | `65051` | **assente** |
| X5000 | `...HWServicesVega` | `IOPCIDevice` | `65051` | **assente** |
| X6000 | `...HWServicesNavi` | `IOPCIDevice` | `65051` | **assente** |

**PROVEN:** le tre HWServices usano `IOPCIDevice`.
**PROVEN:** score identico `65051`.
**PROVEN:** `LoadHWServices=true`.
**UNPROVEN:** il runtime.

---

## 7. OSBundleRequired

| Bundle | Valore |
|---|---|
| HWLibs (tutte) | **assente** |
| HWServices (tutte) | **assente** |
| X6000Framebuffer | `Safe Boot` |
| AMD10000/9500 | `Safe Boot` |
| AMDSupport | `Safe Boot` |

**PROVEN:** HWLibs non è marcato `Safe Boot`.
**PROVEN:** il framebuffer sì.
**UNPROVEN:** la conseguenza di boot.

---

## 8. IOResourceMatch

| Bundle | `IOResourceMatch` |
|---|---|
| HWLibs (tutte) | **assente** |
| HWServices (tutte) | **assente** |
| AMDRadeonServiceManager | `IOKit` |

**PROVEN:** HWLibs non ha `IOResourceMatch`.
**PROVEN:** ServiceManager sì.
**UNPROVEN:** il runtime.

---

## 9. Cross-reference

| Test | Esito |
|---|---|
| `AMDRadeonX6000HWLibs` in altri bundle | **NO** |
| Self-reference | **SÌ** |
| Altre personality AMD | **NO** |

**PROVEN:** nessun altro bundle referenzia X6000HWLibs.
**PROVEN:** il bundle è autosufficiente nei metadati.
**UNPROVEN:** l’attivazione.

---

## 10. X5000 vs X6000

| Campo | X5000HWLibs | X6000HWLibs |
|---|---|---|
| IOClass | `...HWLibsX5000` | `...HWLibsX6000` |
| Provider | X5000 Interface | X6000 Interface |
| Load | `Load5000` | `Load6000` |
| Score | **assente** | **assente** |
| Required | **assente** | **assente** |
| ResourceMatch | **assente** | **assente** |
| Librerie | 5 | 5 |

**PROVEN:** struttura identica.
**PROVEN:** cambiano solo prefisso, provider e Load.
**UNPROVEN:** equivalenza runtime.

---

## 11. Dichiarativo vs attivazione

| Evidenza | Tipo |
|---|---|
| IOClass | dichiarativa |
| IOProviderClass | dichiarativa |
| IOMatchCategory | dichiarativa |
| IOPropertyMatch | dichiarativa |
| OSBundleLibraries | dichiarativa |
| IOProbeScore | dichiarativa |
| IOResourceMatch | dichiarativa |
| Attivazione | **UNPROVEN** |
| IORegistry | **UNPROVEN** |

**PROVEN:** tutto è metadato.
**UNPROVEN:** l’attivazione effettiva.

---

## 12. Conclusione

| Domanda | Risposta |
|---|---|
| X6000HWLibs | personality completa |
| IOClass | `...HWLibsX6000` |
| Provider | Interface |
| Load | `Load6000` |
| IOProbeScore | **assente** |
| IOResourceMatch | **assente** |
| OSBundleRequired | **assente** |
| Cross-reference | **NO** |
| Attivazione | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** X6000HWLibs è una personality completa con `IOClass=AMDRadeonX6000_AMDRadeonHWLibsX6000`, `IOProviderClass=AMDRadeonX6000_AMDRadeonHWServicesInterface`, `IOMatchCategory=AMDRadeonHWLibs` e `IOPropertyMatch.LoadPlugIn=Load6000`, ma **senza** `IOProbeScore`, `IOResourceMatch` e `OSBundleRequired`. Le 16 personality HWLibs condividono la stessa struttura; solo la famiglia X4000 ha `IOProbeScore=10`; X5000 e X6000 non lo hanno. Nessun altro bundle referenzia `AMDRadeonX6000HWLibs`. Questi sono metadati dichiarativi: non provano l’attivazione runtime, che resta **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
