# T27 — AGENT-AMD — X6100HWLibs INVESTIGATION

**Scope:** identificazione di `AMDRadeonX6100HWLibs.kext`, componente della catena AMD caricata su 25G342; ricerca in HAO-86, HAO-68/69/71, root2, root3, root25, KDK e target; confronto con `X6000HWLibs`; verifica di identità, architettura, dipendenze, SHA e provenienza.  
**Modalità:** sola lettura; nessun download, compilazione, modifica, `kextload` o boot.  
**Esito:** `X6100HWLibs` **esiste in root2** (annidato in `X6000HWServices`) ed è il componente usato dalla catena reale 25G342; **non** è equivalente a `X6000HWLibs`. La copia root2 ha UUID/versione uguali al kext caricato, ma **hash diverso** da una copia estratta dalla SystemKC; l’ABI 26B131 resta **UNPROVEN**.

---

## 1. Identità del componente

### 1.1 Bundle root2

Percorso:

```text
<SESSION>/work/root2/System/Library/Extensions/
  AMDRadeonX6000HWServices.kext/Contents/PlugIns/
    AMDRadeonX6100HWLibs.kext
```

| Campo | Valore | Fonte |
|---|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX6100HWLibs` | `Info.plist` |
| `CFBundleVersion` | `1.0` | `Info.plist` |
| `CFBundleShortVersionString` | `1.0` | `Info.plist` |
| UUID Mach-O | `533D1262-BE83-3507-B48A-FDB91C9D8793` | `dwarfdump --uuid`, `T25-ROOT2-INVENTORY.csv` |
| Architettura | `x86_64` (non-fat) | `file`, `lipo -info` |
| Binario | `Contents/MacOS/AMDRadeonX6100HWLibs` | filesystem |
| Dimensione binario | **17.256.336 B** | `stat` |
| SHA-256 binario | `00b6214e4771d84f2cda4a9943fceafaac0e632f57fbfda20e6ee5cbf051d61f` | `shasum -a 256` |
| SHA-256 `Info.plist` | `414fa880bf31cfbdd5a0007825961c6cc9e231afba5210e563507b510deb86a1` | `shasum -a 256` |
| SHA-256 `version.plist` | `bd0b19420e72a6c9fe82fdcc177a2662e41c44c7bf99ab339445f020ca3c1119` | `shasum -a 256` |
| `DTSDKBuild` | `25G325` | `Info.plist` |
| `DTPlatformBuild` | `""` | `Info.plist` |
| Firma | `APPLE_SIGNED` (dichiarata nell’inventario) | `T25-ROOT2-INVENTORY.csv` |

**Formato:** `Mach-O 64-bit kext bundle x86_64`, non universale.

### 1.2 Dipendenze dichiarate

`OSBundleLibraries`:

```text
com.apple.iokit.IOPCIFamily   2.9
com.apple.kpi.bsd             16.0
com.apple.kpi.iokit           16.0
com.apple.kpi.libkern         16.0
com.apple.kpi.mach            16.0
```

La catena misurata su 25G342 riporta per X6100: `<19 7 6 3 1>`; il numero e l’ordine sono compatibili con le cinque dipendenze dichiarate. La mappatura puntuale degli indici è in `AMD-KEXT-CHAIN.md`.

### 1.3 Contesto

`X6100HWLibs` è un **plugin** di `AMDRadeonX6000HWServices.kext`, non un bundle top-level. Il parent root2 è `4A753C5A-…`, versione 7.1.8; il parent caricato su 25G342 è lo stesso UUID ma versione 7.0.1.

---

## 2. Evidenza sulla macchina 25G342

Fonte: `<SESSION>/evidence/phase1-drivers.txt`  
SHA-256: `59de359db3f3fc638b825de2b1eb70c04ffee62b86036f4ae7e5304570d88ecb`  
mtime: 16 Nov 2026 02:42:12  
Comando: `kmutil showloaded`.

```text
181 0 0xffffff7f8ea57000 0x3adb28 0x3adb28
com.apple.kext.AMDRadeonX6100HWLibs (1.0)
533D1262-BE83-3507-B48A-FDB91C9D8793 <19 7 6 3 1>
```

| Dato | Valore |
|---|---|
| Caricato | **SÌ** |
| Indice | 181 |
| UUID | `533D1262-BE83-3507-B48A-FDB91C9D8793` |
| Versione | 1.0 |
| Loaded size | `0x3adb28` |
| Dipendenze | `<19 7 6 3 1>` |
| Indirizzo | `0xffffff7f8ea57000` |

``phase0.txt`` (SHA `fc6137a7…`) conferma sulla stessa macchina `1002:7340`, rev `0043`, VBIOS `113-D32207P1-019`, display interno 3072×1920 sotto la Radeon. Questo è **25G342**, non 26B131.

**Limite:** `kmutil showloaded` non fornisce SHA-256 né architettura del file caricato. L’identità UUID/versione è misurata; l’hash del binario in esecuzione **non** è disponibile.

---

## 3. Copie e provenienza

| Posizione | Contenuto | Dimensione | SHA-256 | UUID | Uso |
|---|---|---:|---|---|---|
| `<SESSION>/work/root2/.../X6100HWLibs.kext` | Info + MacOS + version | 17.256.336 | `00b6214e…` | `533D1262…` | **copia completa** |
| `<SESSION>/work/systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` | Mach-O estratto da SystemKC | 16.985.840 | `e521d3cc…` | `533D1262…` | copia KC, **hash diverso** |
| `<SESSION>/work/staged/com.apple.kext.AMDRadeonX6100HWLibs` | Mach-O staged | 16.985.840 | `e521d3cc…` | `533D1262…` | idem |
| `<SESSION>/work/root-full/.../X6100HWLibs.kext` | solo `Info.plist`, `version.plist`, `_CodeSignature` | — | — | — | **nessun MacOS** |
| `<DONOR_VOLUME>/.../X6100HWLibs.kext` (root25) | solo `Info.plist`, `version.plist`, `_CodeSignature` | — | — | — | **nessun MacOS** |
| root3 | assente | — | — | — | — |
| KDK 26B131 | assente | — | — | — | — |
| target 26B131 | assente | — | — | — | — |

### 3.1 Due binari, stesso UUID

Root2 e la copia HAO-65 hanno **lo stesso UUID e la stessa versione**, ma **hash e dimensione diversi**:

```text
root2:  17.256.336 B  SHA 00b6214e…
HAO-65: 16.985.840 B  SHA e521d3cc…
```

Non sono quindi automaticamente lo stesso file. La differenza può essere dovuta all’estrazione dalla SystemKC (contenuto/linkedit diverso), ma **non è dimostrato**: manca un’analisi differenziale. La copia root2 è quella completa; la copia HAO-65 è quella estratta dalla cache.

### 3.2 Root25 e HAO-71: metadati senza binario

Sia root25 sia `HAO-71/root-full` contengono il bundle con `Info.plist`, `version.plist` e `_CodeSignature`, ma **senza `Contents/MacOS`**. Questo spiega perché `T25-HOST-COMPARISON.csv` marca il componente host come `NO_PRIMARY` / `METADATA_MATCH_ONLY` / “host has metadata only”: si riferisce al **filesystem del volume**, non al kext caricato dalla BootKC. La prova di caricamento è `phase1`, non il volume root25.

---

## 4. Confronto con X6000HWLibs

| Campo | X6100HWLibs | X6000HWLibs |
|---|---|---|
| Bundle ID | `com.apple.kext.AMDRadeonX6100HWLibs` | `com.apple.kext.AMDRadeonX6000HWLibs` |
| Versione | 1.0 | 1.0 |
| UUID | `533D1262-BE83-3507-B48A-FDB91C9D8793` | `5CD4BC0C-C225-365F-A872-C885575B9A19` |
| Binario | 17.256.336 B | 29.233.952 B |
| SHA-256 binario | `00b6214e…` | `7d078501…` |
| SHA-256 Info | `414fa880…` | `42599c7c…` |
| Arch | x86_64 | x86_64 |
| Dipendenze | IOPCIFamily + 4 KPI | IOPCIFamily + 4 KPI |
| Caricato su 25G342 | **SÌ** | **NO** |
| Posizione | plugin di HWServices | plugin di HWServices |

**Non sono equivalenti.** Hanno UUID, nome, dimensione e hash diversi. `X6000HWLibs` è presente in root2 ma non è il componente della catena misurata; non va sostituito a X6100 senza una prova.

---

## 5. Ricerca nei materiali

| Materiale | Riferimento | Esito |
|---|---|---|
| HAO-86 `phase1` | X6100 1.0, UUID, deps, indice 181 | **MISURATO** |
| HAO-86 `AMD-DRIVER-STATUS.md` | “X6100HWLibs è il plugin Navi14” | DOCUMENTED |
| HAO-71 `root-full` | bundle senza MacOS | metadata only |
| HAO-68 | nessuna analisi separata di X6100 | **GAP** |
| HAO-69 | nessun riferimento al bundle | **ASSENTE** |
| root2 `T25-ROOT2-INVENTORY.csv` | bundle ID, 17.256.336 B, SHA, UUID, x86_64 | **DOCUMENTED** |
| root2 `T25-HOST-COMPARISON.csv` | host `NO_PRIMARY`, metadata only | **volume, non KC** |
| T16/T13/T11 | bundle installato/citato in T6, UUID 533D1262 | DOCUMENTED (contesto) |
| KDK 26B131 | 0 X6100 | **ABSENT** |
| target 26B131 | 0 X6100 | **ABSENT** |

Nessun manifest di acquisizione root2: la provenienza è `LOCAL_ROOT2;KDK_25G342_TREE_COPY;NO_ACQUISITION_MANIFEST`. Il bundle è firmato Apple secondo l’inventario, ma la firma non è stata rivalidata in questa sessione.

---

## 6. Classificazione

| Classe | Dato |
|---|---|
| **MEASURED** | Caricamento su 25G342: bundle ID, 1.0, UUID, deps, indice 181; GPU/display della stessa macchina |
| **DOCUMENTED** | Bundle root2 completo: 17.256.336 B, SHA `00b6214e…`, x86_64, Info SHA, dipendenze |
| **UNPROVEN** | Corrispondenza esatta root2 ↔ binario caricato (hash host assente); ABI 26B131; trasferibilità |
| **ABSENT** | X6100 in root3, KDK 26B131, target 26B131; binario in root25/HAO-71 |

---

## 7. Conclusione

1. `X6100HWLibs` **esiste** in root2, annidato in `X6000HWServices`: la precedente affermazione “root2 non lo contiene” era errata ed è corretta qui.
2. La catena reale 25G342 usa **X6100HWLibs 1.0**, UUID `533D1262…`; `X6000HWLibs` **non** è caricato e **non** è equivalente.
3. Root2 contiene una copia completa con UUID/versione coerenti, ma **hash diverso** dalla copia SystemKC HAO-65; non è provato che sia lo stesso binario caricato.
4. Root3, KDK 26B131 e target 26B131 non contengono X6100; root25/HAO-71 hanno solo metadati.
5. L’ABI con 26B131 resta **UNPROVEN**; il componente è un candidato documentato, non una prova di compatibilità.
6. **E (display), G (WindowServer), H (desktop): BLOCKED.**

**STOP rispettato:** sola lettura; nessun download, compilazione, modifica, `kextload` o boot. Spazio libero 12.920.044 KiB (12,32 GiB) > 10 GiB.
