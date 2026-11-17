# T27 — AGENT-AMD — MATCH RUNTIME

**Scope:** ricostruire il percorso di matching runtime tra Navi, `LoadPlugIn=Load6000` e personality X6000HWLibs, senza confondere matching e avvio del plugin; verificare i chiamanti di `getMatchProperty` e confrontare X5000.

**Modalità:** sola lettura; BootKC, SystemKC, X6000HWServices, X5000HWServices; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **PROVEN** che `getMatchProperty` è nello slot vtable `0x878` e che nessuna delle funzioni IOKit esaminate (`probe`, `start`, `matchPropertyTable`, `propertyMatching`) lo invoca. **UNPROVEN** il chiamante runtime. **PROVEN** che `Load6000` è una proprietà di matching, non un avvio. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6000HWServices | `2aa47ceee99969d3eba360fe558a3fbcd7e69c4bea2cd76704350a9bdfafe453` |
| X5000HWServices | `8a88fe7276968d3b124c9ff7ccf26d18b5e918fc339ab3681dfcb5a2cbd3cfbf` |
| Report 129 | `58920009f89bcfd2ee0eac9b6433fa819d4db90cbbd209b5f3ca103fa121ca73` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Slot 0x878

| Elemento | Valore |
|---|---|
| vtable Navi | `0xC26F078` |
| slot | `0x878` |
| entry | `0xC26F8F0` |
| raw | `0x4C26CBE0` |
| livello | `1` |
| target | `0xC26CBE0` |
| simbolo | `Navi::getMatchProperty()` |

**PROVEN:** lo slot punta a `getMatchProperty`.
**PROVEN:** il target è `0xC26CBE0`.
**UNPROVEN:** il chiamante.

---

## 3. Call-site indiretti

| Immagine | `call *0x878` | `jmp *0x878` |
|---|---:|---:|
| BootKC | ≥10 | ≥10 |
| SystemKC | ≥10 | ≥6 |
| X6000HWServices | **0** | **0** |

**PROVEN:** lo slot è usato indirettamente nel kernel.
**PROVEN:** non c’è un call-site in HWServices.
**UNPROVEN:** la funzione chiamante.

---

## 4. Funzioni IOKit esaminate

| Funzione | Indirizzo | Slot usati | `0x878` |
|---|---:|---|---|
| `IOService::probe` | `0xA94E60` | — | **NO** |
| `IOService::start` | `0xA94E70` | — | **NO** |
| `IOService::matchPropertyTable` | `0xA95AB0` | `0x680`, `0x2D8`, `0x88`, `0x120`, `0x38` | **NO** |
| `IOService::matchPropertyTable` | `0xA95AD0` | `0x680`, `0x2D8`, `0x88`, `0x120`, `0x38` | **NO** |
| `IOService::propertyMatching` | `0xAAA640` | `0x1A0`, `0x1C0`, `0x28` | **NO** |
| `IOService::propertyMatching` | `0xAAA710` | `0x1A0`, `0x1C0`, `0x28` | **NO** |

**PROVEN:** queste funzioni non chiamano `0x878`.
**UNPROVEN:** il percorso effettivo.

---

## 5. IOPropertyMatch

| Campo | Valore |
|---|---|
| `IOPropertyMatch` | dict |
| `LoadPlugIn` | `Load6000` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOMatchCategory` | `AMDRadeonHWLibs` |
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |

**PROVEN:** la proprietà è dichiarata.
**PROVEN:** `Load6000` è un valore, non una funzione.
**UNPROVEN:** il consumo runtime.

---

## 6. Dipendenze

| Dipendenza | X6000HWLibs |
|---|---|
| `com.apple.iokit.IOPCIFamily` | `2.9` |
| `com.apple.kpi.bsd` | `16.0` |
| `com.apple.kpi.iokit` | `16.0` |
| `com.apple.kpi.libkern` | `16.0` |
| `com.apple.kpi.mach` | `16.0` |
| HWServices | **assente** |

**PROVEN:** HWLibs non dichiara HWServices in `OSBundleLibraries`.
**PROVEN:** il legame è `IOProviderClass`, non una dipendenza di linkage.
**UNPROVEN:** il runtime.

---

## 7. X5000

| Elemento | X5000 |
|---|---|
| `Load5000` | `0x457D1AA` |
| `Abstract::start` | `0x457C970` |
| `findPlugIn` | `0x457CD30` |
| `IOMatchCategory` | `0x457D3B7` |
| `AMDRadeonHWLibs` | `0x457D3E0` |
| vtable slot `0x878` | **UNPROVEN** |

**PROVEN:** lo schema statico è equivalente.
**UNPROVEN:** il runtime e lo slot X5000.

---

## 8. Matching vs avvio

| Azione | Indirizzo | Esito |
|---|---|---|
| `getMatchProperty` | `0xC26CBE0` | restituisce `Load6000` |
| Finder | `0xC26DC80` | trova HWLibs |
| `*0x20` | `0xA1DF30` | `OSObject::release(int)` |
| start plugin | **NO** | **UNPROVEN** |

**PROVEN:** `*0x20` non avvia.
**PROVEN:** il Finder non avvia.
**UNPROVEN:** chi avvia il plugin.

---

## 9. STOP

| Criterio | Esito |
|---|---|
| Chiamante `getMatchProperty` | **NO** |
| Mapping slot | **SÌ** |
| Funzioni IOKit esaminate | **NO 0x878** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Slot `0x878` | `getMatchProperty` |
| Caller statico | **UNPROVEN** |
| `probe`/`start` | **NO 0x878** |
| `matchPropertyTable` | **NO 0x878** |
| `propertyMatching` | **NO 0x878** |
| `Load6000` | proprietà |
| `*0x20` | release |
| Matching statico | **PROVEN** |
| Runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `Navi::getMatchProperty` è nello slot vtable `0x878` (`0xC26F8F0` → `0x4C26CBE0` → `0xC26CBE0`), ma non esiste un chiamante statico dimostrabile: `IOService::probe`, `IOService::start`, `IOService::matchPropertyTable` e `IOService::propertyMatching` non usano lo slot `0x878`; in HWServices non c’è alcun call-site. `Load6000` è una proprietà di matching restituita da `getMatchProperty`, non una funzione, e `*0x20` sul plugin HWLibsX6000 è `OSObject::release(int)`, non `start`. Il matching statico (`IOPropertyMatch`, `IOProviderClass`, `IOMatchCategory`) è **PROVEN**; il chiamante runtime e l’avvio restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,2 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
