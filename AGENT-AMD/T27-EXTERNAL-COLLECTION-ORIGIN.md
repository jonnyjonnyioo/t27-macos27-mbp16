# T27 — AGENT-AMD — EXTERNAL COLLECTION ORIGIN

**Scope:** verificare se i tre target X4000HWLibs (`0x18C0074D`, `0x18C00EFC`, `0x18C00002`) provengano da una collection esterna; cercare metadati di boot, DeviceTree, BootManifest, Preboot, log, `kcformat.c`, `kcgen` e dyld; verificare mappe runtime/manifest che associno indici di collection a basi.

**Modalità:** sola lettura; scansione di root-full, SystemKC, BootKC e report T27. Nessuna rete, download, modifica o boot.

**Esito:** **nessun** file `AuxiliaryKernelExtensions`, `BootManifest`, `DeviceTree`, `Preboot`, `kcformat.c` o `kcgen` è presente in root-full. BootKC contiene solo **riferimenti simbolici** (`_collection_base_pointers`, `IOGetBootManifestHash`, `IODeviceTree`), **non** una mappa serializzata. **0** manifest runtime, **0** basi, **0** UUID/vmaddr/fileoff candidati. `cacheLevel=2` resta **invalido** secondo il mapping noto (`KCKind` 0/1/3; 2 non mappato) e **UNPROVEN** come collection esterna. T27 resta **OPEN**.

---

## 1. File cercati

| Nome | Occorrenze in root-full | Esito |
|---|---:|---|
| `AuxiliaryKernelExtensions*` | **0** | **assente** |
| `BootManifest*` | **0** | **assente come file** |
| `DeviceTree*` | **0** | **assente come file** |
| `Preboot*` | **0** | **assente** |
| `kcformat.c` | **0** | **assente** |
| `kcgen*` | **0** | **assente** |

**PROVEN:** root-full non contiene questi file.
**PROVEN:** `CoreServices` contiene solo `SystemVersion.plist`.
**PROVEN:** non c’è una copia locale del codice `kcformat.c`/`kcgen`.

---

## 2. Stringhe nei KC

| Stringa | SystemKC | BootKC |
|---|---:|---:|
| `AuxiliaryKernelExtensions` | **0** | **0** |
| `basePointers` | **0** | **0** |
| `collection_base_pointers` | **0** | **1** |
| `kc_kind2index` | **0** | **0** |
| `KCKindAuxiliary` | **0** | **0** |
| `BootManifest` | **0** | **1** |
| `DeviceTree` | **24** | **67** |

**PROVEN:** `collection_base_pointers` in BootKC è un **nome di simbolo** (`._collection_base_pointers`), non un array serializzato.
**PROVEN:** `BootManifest` è il simbolo `_IOGetBootManifestHash`, non un manifest.
**PROVEN:** `DeviceTree` è il simbolo `IODeviceTree`, non un albero serializzato.
**PROVEN:** nessuna stringa `AuxiliaryKernelExtensions` nei KC.

---

## 3. Metadati di boot

| Fonte | Contenuto | Mappa basi? |
|---|---|---|
| SystemKC `__PRELINK_INFO` | `_BootKCID`, `_PrelinkKCID`, versione | **NO** |
| BootKC | simboli `_collection_base_pointers`, `_IOGetBootManifestHash`, `IODeviceTree` | **NO** |
| `SystemVersion.plist` | versione sistema | **NO** |
| BootManifest file | **assente** | **—** |
| DeviceTree file | **assente** | **—** |
| Preboot | **assente** | **—** |
| Log runtime | **non disponibili** | **—** |

**PROVEN:** nessuna fonte contiene una mappa `indice → base`.
**PROVEN:** `collection_base_pointers` è solo un simbolo, non dati.
**UNPROVEN:** il valore runtime dell’array.

---

## 4. `cacheLevel=2`

| Fonte | `cacheLevel=2` |
|---|---|
| `kcformat.c` (report) | **non mappato** |
| `kc_kind2index` (report) | **caso invalido** |
| `KCKindAuxiliary` | **3, non 2** |
| Base `basePointers[2]` | **assente** |
| Significato alternativo | **nessuna prova** |

**PROVEN:** il mapping noto assegna **0/1/3**; **2** non ha `KCKind`.
**PROVEN:** non c’è una base serializzata.
**UNPROVEN:** un significato alternativo di `cacheLevel=2`.
**UNPROVEN:** una collection esterna con indice 2.

---

## 5. Mappe runtime/manifest

| Verifica | Risultato |
|---|---:|
| Manifest con basi | **0** |
| Mappa indice → base | **0** |
| UUID/vmaddr/fileoff candidati | **0** |
| `_PrelinkExecutableSize` candidato | **0** |
| Riferimenti a `0x18C00000` | **0** fuori dal report 52 |
| Target nei tre KC | **0** |

**PROVEN:** non esiste una mappa runtime/manifest locale.
**PROVEN:** i tre target restano fuori da SystemKC e BootKC.
**UNPROVEN:** la collection esterna e la sua base.

---

## 6. Confronto con i tre target

| Target | SystemKC | BootKC | AuxKC locale | Manifest | Base |
|---|---|---|---|---|---|
| `0x18C00002` | **NO** | **NO** | **assente** | **0** | **UNPROVEN** |
| `0x18C0074D` | **NO** | **NO** | **assente** | **0** | **UNPROVEN** |
| `0x18C00EFC` | **NO** | **NO** | **assente** | **0** | **UNPROVEN** |

**PROVEN:** nessuno dei tre è nelle immagini disponibili.
**PROVEN:** nessun manifest li associa.
**UNPROVEN:** una collection esterna.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| AuxiliaryKernelExtensions locale? | **NO** |
| BootManifest/DeviceTree/Preboot file? | **NO** |
| `kcformat.c`/`kcgen` locali? | **NO** |
| Mappa indice → base? | **NO** |
| `collection_base_pointers` serializzato? | **NO — solo simbolo** |
| `cacheLevel=2` alternativo? | **UNPROVEN** |
| Collection esterna? | **UNPROVEN** |
| Target attribuiti? | **NO — 0** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** non esistono metadati, manifest o mappe runtime che associno `cacheLevel=2` a una base o a una collection esterna. `collection_base_pointers`, `BootManifest` e `DeviceTree` sono **soli simboli** in BootKC; i file e le AuxKC sono **assenti**. I tre target restano **non attribuiti**; l’ipotesi esterna è **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna rete/download/modifica/build/boot.
