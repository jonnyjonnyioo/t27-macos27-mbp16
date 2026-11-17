# T27 — AGENT-AMD — EXCLUDE LIST

**Scope:** determinare se X5400 e AMDSupport sono esclusi o eleggibili nel percorso `addKextsFromKextCollection`; ricostruire `createExcludeListFromPrelinkInfo`, il formato della lista e i metadati delle due entry; separare eleggibilità statica e caricamento runtime.

**Modalità:** sola lettura; BootKC 26B131, SystemKC, disassemblaggio, simboli, plist `PRELINK_INFO`; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN** che la exclude list proviene da `com.apple.driver.KextExcludeList` nel `PRELINK_INFO` del BootKC e che i bundle ID `com.apple.kext.AMDSupport` e `com.apple.kext.AMDRadeonX5400HWLibs` **non** compaiono nella lista. **PROVEN** la loro presenza nel SystemKC. **UNPROVEN** il caricamento runtime. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 90 | `38b8eaa62d4c71ae8762ed8fb50ca58caea3a398efadf7a7ce76330ed5fef68e` |
| Report 91 | `ff83147a9f1495cd5d182f0f54ccc79df45e95494425e1dd1d40d004152d8a3a` |
| Report 92 | `771347abf31cb0e6f333861efc6569135059e1f91cc8ceb606e47f288c40a1b2` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. `createExcludeListFromPrelinkInfo`

| Offset | Evidenza |
|---:|---|
| `0xa34a20` | inizio funzione |
| `0xa34a5e` | `leaq "com.apple.driver.KextExcludeList"` |
| `0xa34a65` | `call 0x48a270` |
| `0xa34ad7` | `leaq "CFBundleIdentifier"` |
| `0xa34b21` | `call 0xa34e70` (`updateExcludeList`) |
| `0xa34b39` | stringa `Missing OSKextExcludeList dictionary` |

**PROVEN:** la funzione legge `com.apple.driver.KextExcludeList`.
**PROVEN:** usa `CFBundleIdentifier`.
**PROVEN:** chiama `updateExcludeList`.
**PROVEN:** la lista mancante produce un messaggio diagnostico.

---

## 3. Provenienza della lista

| Elemento | Valore |
|---|---|
| Sezione | `__PRELINK_INFO,__info` |
| File offset BootKC | `11517952` (`0xAFC000`) |
| Dimensione | `4538368` byte |
| Chiave `KextExcludeList` | offset `0x30E916` nella sezione |
| Chiave `OSKextExcludeList` | offset `0x30EE78` nella sezione |
| Formato | dizionario bundle ID → versione |

**PROVEN:** la lista è nel `PRELINK_INFO` del BootKC.
**PROVEN:** è un dizionario di bundle ID.
**PROVEN:** il SystemKC non contiene la lista.

---

## 4. Contenuto della lista

| Ricerca | Esito |
|---|---|
| `AMDSupport` | **NOT FOUND** |
| `X5400` | **NOT FOUND** |
| `com.apple.kext.AMDSupport` | **assente** |
| `com.apple.kext.AMDRadeonX5400HWLibs` | **assente** |

**PROVEN:** i due bundle ID non sono nella exclude list.
**PROVEN:** la lista contiene invece kext di terze parti.
**REFUTED:** l’esclusione statica delle due entry.

---

## 5. Metadati delle entry

| Provider | Bundle ID | Entry vmaddr | `cacheLevel` |
|---|---|---:|---:|
| AMDSupport | `com.apple.kext.AMDSupport` | `0x13B2C000` | **1** |
| X5400 | `com.apple.kext.AMDRadeonX5400HWLibs` | `0x8A90000` | **1** |

**PROVEN:** i bundle ID sono nel SystemKC.
**PROVEN:** `CFBundleIdentifier` è presente nei rispettivi dizionari.
**PROVEN:** `cacheLevel=1` dai report precedenti.
**UNPROVEN:** l’associazione runtime entry → oggetto.

---

## 6. Condizioni di esclusione

| Condizione | Evidenza |
|---|---|
| Lista assente | messaggio diagnostico |
| Bundle ID nella lista | **filtro** |
| Bundle ID non nella lista | **eleggibile** |
| Filtro diretto `X5400` | **NO** |
| Filtro diretto `AMDSupport` | **NO** |
| Altre condizioni osservate | **nessuna** |

**PROVEN:** l’unica condizione osservata è la presenza nella exclude list.
**UNPROVEN:** eventuali controlli successivi dentro `init`.

---

## 7. Eleggibilità

| Kext | Nella lista? | Esito statico |
|---|---|---|
| AMDSupport | **NO** | **ELIGGIBILE** |
| X5400 | **NO** | **ELIGGIBILE** |

**PROVEN:** staticamente non sono esclusi.
**UNPROVEN:** che vengano effettivamente selezionati e caricati a runtime.

---

## 8. Evidenze runtime

| Evidenza | Esito |
|---|---|
| Boot log | **assente** |
| Trace `createExcludeList` | **assente** |
| Trace `addKexts` | **assente** |
| Trace `init` | **assente** |
| Trace `loadExecutable` | **assente** |
| `ioreg`/DeviceTree | **assente** |

**PROVEN:** non ci sono log o trace preesistenti.
**UNPROVEN:** il caricamento runtime.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Lista presente | **SÌ, `com.apple.driver.KextExcludeList`** |
| Lista nel BootKC | **SÌ, `PRELINK_INFO`** |
| AMDSupport nella lista | **NO** |
| X5400 nella lista | **NO** |
| Esclusione statica | **REFUTED** |
| Eleggibilità statica | **SÌ per entrambi** |
| Caricamento runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `createExcludeListFromPrelinkInfo` (`0xa34a20`) legge `com.apple.driver.KextExcludeList` (`0xa34a5e`) e costruisce la lista da `OSKextExcludeList` nel `PRELINK_INFO` del BootKC. I bundle ID `com.apple.kext.AMDSupport` e `com.apple.kext.AMDRadeonX5400HWLibs` non compaiono: staticamente sono **eleggibili**, non esclusi. Resta **UNPROVEN** che vengano selezionati e caricati a runtime. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,23 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
