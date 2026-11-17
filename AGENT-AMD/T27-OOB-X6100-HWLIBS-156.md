# T27 — AGENT-AMD — X6100 HWLIBS / LOAD6100 (156)

**Scope:** verificare se `AMDRadeonX6100HWLibs` è effettivamente caricabile e associabile a `AMDRadeonX6000_AMDRadeonHWServicesNavi` con `LoadPlugIn=Load6100`; analizzare personality completa, `CFBundleIdentifier`, `OSBundleLibraries`, dipendenze, architettura/requisiti, presenza nei KC e concorrenza con X6000. Sola lettura; nessun boot/trace/modifica/build/download.

**Esito:** **PROVEN** che la personality X6100 è staticamente coerente: `IOClass=AMDRadeonX6100_AMDRadeonHWLibsX6100`, `IOProviderClass=...HWServicesInterface`, `IOMatchCategory=AMDRadeonHWLibs`, `LoadPlugIn=Load6100`; la classe è in **SystemKC** con 78 simboli classe/base e i metodi `probe`/`attach`/`start`/`stop`. **PROVEN** che le dipendenze dichiarate sono soddisfatte e che `LSMinimumSystemVersion=26.7` è rispettato da macOS **26.7.3**. **UNPROVEN** l’attach runtime; **UNPROVEN** la presenza del binario standalone nel root estratto, dove `Contents/MacOS` manca per tutti gli HWLibs. **PROVEN** che X6100 non è in BootKC. T27 resta **OPEN**.

---

## 1. SHA-256 e ambiente

| Artefatto | SHA-256 |
|---|---|
| X6100HWLibs `Info.plist` | `414fa880bf31cfbdd5a0007825961c6cc9e231afba5210e563507b510deb86a1` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| X6100HWLibs executable | **assente nel root estratto** |

**Ambiente:** macOS `26.7.3`, build `25G342`; `LSMinimumSystemVersion=26.7` è quindi soddisfatto.
**PROVEN:** la versione minima dichiarata non è un blocco.

---

## 2. Bundle X6100

Percorso:

```text
/System/Library/Extensions/AMDRadeonX6000HWServices.kext/Contents/PlugIns/
  AMDRadeonX6100HWLibs.kext
```

Contenuto osservato:

| Elemento | Stato |
|---|---|
| `Contents/Info.plist` | presente |
| `Contents/version.plist` | presente |
| `Contents/_CodeSignature/CodeResources` | presente |
| `Contents/MacOS/AMDRadeonX6100HWLibs` | **assente** |
| `Contents/MacOS/` | **assente** |

**PROVEN:** nel root estratto il bundle non contiene l’eseguibile dichiarato da `CFBundleExecutable=AMDRadeonX6100HWLibs`.
**PROVEN:** lo stesso schema vale per X6000 e X6200: nessuno dei tre ha `Contents/MacOS` nel root.
**INFERRED:** il codice è incorporato nella kernel collection; il bundle è una “personality shell” con metadati e firma, non un kext caricabile dal solo filesystem.
**UNPROVEN:** la presenza dell’eseguibile nel sistema live fuori dal root estratto.

### 2.1 `version.plist`

| Campo | Valore |
|---|---|
| `BuildVersion` | `21` |
| `CFBundleShortVersionString` | `1.0` |
| `CFBundleVersion` | `1.0` |
| `ProjectName` | `GPUDriversAMD` |
| `SourceVersion` | `7001011000000` |

**PROVEN:** il bundle è della famiglia `GPUDriversAMD`, versione 1.0.

---

## 3. Personality e identificatori

### 3.1 `Info.plist`

| Campo | Valore |
|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX6100HWLibs` |
| `CFBundleName` | `AMDRadeonX6100HWLibs` |
| `CFBundleExecutable` | `AMDRadeonX6100HWLibs` |
| `CFBundlePackageType` | `KEXT` |
| `CFBundleVersion` | `1.0` |
| `CFBundleShortVersionString` | `1.0` |
| `OSBundleCompatibleVersion` | `1.0` |
| `LSMinimumSystemVersion` | `26.7` |
| `CFBundleSupportedPlatforms` | `MacOSX` |

**PROVEN:** identificatore e versione sono coerenti con il bundle X6100.
**PROVEN:** `CFBundleIdentifier` della personality coincide con quello del bundle.

### 3.2 Personality `AMDRadeonHWLibs`

| Campo | Valore |
|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX6100HWLibs` |
| `IOClass` | `AMDRadeonX6100_AMDRadeonHWLibsX6100` |
| `IOMatchCategory` | `AMDRadeonHWLibs` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch.LoadPlugIn` | `Load6100` |
| `IOPCITunnelCompatible` | `true` |

**PROVEN:** la personality è unica e richiede esattamente `Load6100`.
**PROVEN:** non ci sono `IOProbeScore`, `IOResourceMatch` o `OSBundleRequired`; la loro assenza non impedisce il match.
**PROVEN:** `IOProviderClass` è la stessa Interface usata da HWServicesNavi.

---

## 4. Dipendenze

`OSBundleLibraries`:

| Libreria | Richiesta | Disponibile | Stato |
|---|---:|---:|---|
| `com.apple.iokit.IOPCIFamily` | `2.9` | `2.9` | **SODDISFATTA** |
| `com.apple.kpi.bsd` | `16.0` | `25.6.0` | **SODDISFATTA** |
| `com.apple.kpi.iokit` | `16.0` | `25.6.0` | **SODDISFATTA** |
| `com.apple.kpi.libkern` | `16.0` | `25.6.0` | **SODDISFATTA** |
| `com.apple.kpi.mach` | `16.0` | `25.6.0` | **SODDISFATTA** |

**PROVEN:** `IOPCIFamily` installato è 2.9.
**PROVEN (dai report di dipendenza già chiusi):** le versioni KPI sono superiori a 16.0.
**PROVEN:** `OSBundleLibraries` **non** include HWServices: non c’è dipendenza circolare.
**PROVEN:** `OSBundleRequired` è assente; il bundle non è marcato come obbligatorio.

**Nota:** `OSBundleCompatibleVersion=1.0` è la versione compatibile del bundle, non una richiesta di dipendenza esterna.

---

## 5. Presenza nei kernel collection

### 5.1 SystemKC

`nm -arch x86_64 -n SystemKC` trova 78 simboli della famiglia `X6100_AMDRadeonHWLibs`, di cui:

| Simbolo | Indirizzo |
|---|---:|
| `HWLibsX6100::MetaClassC1` | `0xdd6e980` |
| `HWLibsX6100` ctor C2 | `0xdd6e9d0` |
| `HWLibsX6100` ctor C1 | `0xdd6ea10` |
| `getMetaClass` | `0xdd6eaf0` |
| `MetaClassC2` | `0xdd6eb10` |
| `MetaClass::alloc` | `0xdd6eb60` |
| `populateFirmwareDirectory` | `0xdd6ec30` |
| vtable `__ZTV…HWLibsX6100` | `0xe11c130` |
| `gMetaClass` | `0xed11a10` |

Base `AMDRadeonX6100_AMDRadeonHWLibs`:

| Metodo | Indirizzo |
|---|---:|
| `probe` | `0xdd6f0b0` |
| `attach` | `0xdd6f120` |
| `start` | `0xdd6f320` |
| `stop` | `0xdd6f3b0` |
| `callPlatformFunction` | `0xdd6f3e0` |
| `createPowerPlayInterface` | `0xdd6f500` |

**PROVEN:** la classe concreta X6100 e la sua base sono presenti in SystemKC.
**PROVEN:** la classe X6100 ha i metodi IOService necessari (`probe`, `attach`, `start`, `stop`) nella base.
**PROVEN:** in SystemKC compare il percorso del bundle X6100.
**PROVEN:** BootKC contiene **0** simboli X6100; la classe non è disponibile nel BootKC.

### 5.2 Conseguenza temporale

**PROVEN:** X6100 è una classe di **SystemKC**, non di BootKC.
**INFERRED:** il matching X6100 non può avvenire prima che SystemKC sia disponibile.
**UNPROVEN:** se HWServices start avvenga prima o dopo il caricamento SystemKC nel boot reale.
Questo è un possibile blocco di timing, non un errore di personality.

---

## 6. Collegamento Load6100 → findPlugIn → IOService

| Passaggio | Evidenza | Stato |
|---|---|---|
| HWServices pubblica `Load6100` per `ATY,Boa` | `getMatchProperty 0xc26cbe0`, `setProperty 0xc26d9d7` | **PROVEN** |
| X6100 richiede `Load6100` | `Info.plist` | **PROVEN** |
| Provider class Interface | Navi → SWIP → Abstract → Interface | **PROVEN** |
| Classe X6100 disponibile | SystemKC, 78 simboli | **PROVEN** |
| Dipendenze | IOPCIFamily 2.9, KPI ≥16 | **PROVEN** |
| `findPlugIn` cerca `IOMatchCategory` | `0xc26dc80` | **PROVEN** |
| `findPlugIn` non verifica `IOClass`/`LoadPlugIn` | solo categoria | **PROVEN** |
| Attach runtime | nessuna prova | **UNPROVEN** |

`findPlugIn` percorre i child, legge `IOMatchCategory` e restituisce il primo child con categoria `AMDRadeonHWLibs`; non controlla `IOClass` né `LoadPlugIn`.

**PROVEN:** il child X6100 è il solo che soddisfa `LoadPlugIn=Load6100` tra le personality note.
**PROVEN:** X6000 richiede `Load6000` e non può soddisfare il target `ATY,Boa`.
**INFERRED:** se X6100 è l’unico child attaccato, `findPlugIn` lo restituisce.
**UNPROVEN:** l’ordine di attach e il ritorno effettivo di `findPlugIn`.

---

## 7. Concorrenza X6100 / X6000

| Personality | `IOClass` | `IOMatchCategory` | `IOProviderClass` | `LoadPlugIn` |
|---|---|---|---|---|
| X6000 | `...HWLibsX6000` | `AMDRadeonHWLibs` | `...HWServicesInterface` | `Load6000` |
| X6100 | `...HWLibsX6100` | `AMDRadeonHWLibs` | `...HWServicesInterface` | `Load6100` |
| X6200 | `...HWLibsX6200` | `AMDRadeonHWLibs` | `...HWServicesInterface` | `Load6200` |
| X6700 | `...HWLibsX6700` | `AMDRadeonHWLibs` | `...HWServicesInterface` | `Load6700` |

**PROVEN:** X6000 e X6100 condividono provider class e `IOMatchCategory`, ma hanno `LoadPlugIn` diversi.
**PROVEN:** sul target `ATY,Boa` solo X6100 ha il valore richiesto.
**PROVEN:** la categoria uguale rende ambigua la selezione di `findPlugIn` se più child sono attaccati.
**UNPROVEN:** se IOKit impedisca due attach della stessa categoria prima di `findPlugIn`.
**RISCHIO STATICO:** `findPlugIn` può restituire X6000/X6200/X6700 se presenti e attaccati, pur non essendo il plugin selezionato da `Load6100`.

---

## 8. Verdetto

| Domanda | Risposta | Stato |
|---|---|---|
| X6100 ha personality coerente con `Load6100`? | **SÌ** | **PROVEN** |
| `CFBundleIdentifier` coerente? | **SÌ** | **PROVEN** |
| Dipendenze soddisfatte? | **SÌ** | **PROVEN** |
| `LSMinimumSystemVersion=26.7` rispettato? | **SÌ, macOS 26.7.3** | **PROVEN** |
| Classe in SystemKC? | **SÌ, 78 simboli** | **PROVEN** |
| Classe in BootKC? | **NO, 0 simboli** | **PROVEN** |
| Binario standalone nel root? | **NO** | **PROVEN nel root; live UNPROVEN** |
| Attach runtime? | non osservato | **UNPROVEN** |
| T27 GO? | **NO** | **OPEN** |

**Risposta netta:** `AMDRadeonX6100HWLibs` è la personality staticamente coerente per Navi 14 `ATY,Boa`: `Load6100`, provider Interface, `IOMatchCategory=AMDRadeonHWLibs`, dipendenze soddisfatte e classe concreta in SystemKC con 78 simboli e i metodi IOService nella base. Non c’è un blocco statico nella personality. Restano **UNPROVEN** l’attach runtime, la presenza del binario standalone nel sistema live e l’ordine temporale rispetto a SystemKC; `findPlugIn` resta ambiguo perché guarda solo la categoria. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **12.309.480 KiB ≈ 11,74 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
