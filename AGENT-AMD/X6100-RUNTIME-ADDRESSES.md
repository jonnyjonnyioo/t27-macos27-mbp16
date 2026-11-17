# T27 — AGENT-AMD — X6100 RUNTIME ADDRESSES

**Scope:** stabilire quali indirizzi dei **8.544** puntatori chained-fixup X6100 sono ricostruibili dai metadati della `SystemKernelExtensions.kc` 25G342 e quali richiedono basi esterne.  
**Modalità:** sola lettura; parsing Mach-O, `__PRELINK_INFO`, `LC_FILESET_ENTRY`, `LC_SEGMENT_64`, chained-fixups; SHA-256. Nessuna estrazione, copia, scrittura, build o boot.  
**Esito:** la KC è linkata a **base 0** e colloca X6100 a **0xDD6E000 = 232.185.856**. Sono ricostruibili i **target relativi** e la loro appartenenza ai segmenti; **non** sono ricostruibili gli indirizzi assoluti perché **`basePointers` e il kernel slide non sono serializzati**. `basePointers` e `kernelSlide` hanno **0 occorrenze** nella KC; `X6100` non contiene una base assoluta. **T27 resta OPEN.**

---

## 1. Coordinate

| Campo | Valore | Evidenza |
|---|---|---|
| SystemKC | `HAO-PROJECT/Sessions/<SESSION>/work/root-full/System/Library/KernelCollections/SystemKernelExtensions.kc` | percorso |
| SHA-256 | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` | `shasum -a 256` |
| Dimensione | **369.213.440 B** | `wc -c` |
| Build | **25G342 / 26.7.3** | inventory / `__PRELINK_INFO` |
| UUID KC | `93336203-88E3-AA73-08FC-7C9F4D7B21E0` | `LC_UUID` / `_PrelinkKCID` |
| Architettura | **x86_64** | Mach-O |
| `__PRELINK_INFO,__info` | offset **245.760**, size **1.359.872** | `LC_SEGMENT_64` |
| Entry X6100 | `fileoff` **232.185.856**, `vmaddr` **232.185.856** | `LC_FILESET_ENTRY` |

---

## 2. Metadati X6100

### 2.1 `LC_FILESET_ENTRY`

| Campo | Valore |
|---|---:|
| `entry_id` | `com.apple.kext.AMDRadeonX6100HWLibs` |
| `vmaddr` | **232.185.856** (`0xDD6E000`) |
| `fileoff` | **232.185.856** (`0xDD6E000`) |

### 2.2 `__PRELINK_INFO`

`__PRELINK_INFO,__info` è un plist XML terminato a **1.351.132 B** e seguito da padding NUL. Contiene **180 `_PrelinkInfoDictionary`**; la voce X6100 ha:

| Chiave | Valore |
|---|---:|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX6100HWLibs` |
| `OSBundleUUID` | `533D1262-BE83-3507-B48A-FDB91C9D8793` |
| `_PrelinkExecutableLoadAddr` | **232.185.856** (`0xDD6E000`) |
| `_PrelinkExecutableSourceAddr` | **232.185.856** (`0xDD6E000`) |
| `_PrelinkExecutableSize` | **3.857.192 B** |
| `_PrelinkKmodInfo` | **236.110.480** (`0xE12C290`) |
| `_PrelinkBundlePath` | `/System/Library/Extensions/AMDRadeonX6000HWServices.kext/Contents/PlugIns/AMDRadeonX6100HWLibs.kext` |
| `OSBundleLibraries` | `IOPCIFamily 2.9`, `kpi.bsd/iokit/libkern/mach 16.0` |

**PROVEN:** `_PrelinkExecutableLoadAddr` coincide con il `vmaddr` del `LC_FILESET_ENTRY`. **Non è un indirizzo assoluto**: è la coordinata KC-relativa usata dall’immagine.

### 2.3 Segmenti X6100 nella KC

| Segmento KC | vmaddr | fileoff | filesize | Corrispondenza |
|---|---:|---:|---:|---|
| `__REGION63` | **0xDD6E000** | 232.185.856 | 3.858.432 | X6100 `__TEXT` |
| `__REGION64` | **0xE11C000** | 236.044.288 | 12.546.048 | X6100 `__DATA` + 4.096 B padding |
| `__REGION65` | **0xED13000** | 248.590.336 | 4.096 | X6100 `__DATA_CONST` |

La KC ha `__TEXT` a **vmaddr 0** e `fileoff 0`: è una collezione **base-0 relativa**. La `__TEXT` della KC non contiene un valore di slide assoluta.

---

## 3. Target misurati

| `cacheLevel` | Puntatori | Target minimo | Target massimo |
|---:|---:|---:|---:|
| 1 | **7.658** | **232.188.320** (`0xDD6E9A0`) | **248.584.800** (`0xED11A60`) |
| 0 | **886** | **1.758.400** (`0x1AD4C0`) | **43.261.008** (`0x2941C50`) |
| **Totale** | **8.544** | — | — |

**MISURATO:** i target `cacheLevel=1` cadono in X6100 `__TEXT`/`__DATA`. I target `cacheLevel=0` cadono nella parte bassa della KC e **non** in X6100.

Il target è il campo a **30 bit** di `dyld_chained_ptr_64_kernel_cache_rebase`; la formula documentata è:

```text
indirizzo = basePointers[cacheLevel] + target
```

`basePointers` non è un campo di `dyld_chained_fixups_header` e non è presente nei metadati della KC. `basePointers` e `kernelSlide` hanno **0 occorrenze** nella KC; `__PRELINK_INFO` espone solo:

```text
KMBuildVersion = KernelManagement_host-487.100.11.700.1
ManagerVersion = 1
OSPrelinkInfoContainsUUIDs = True
_BootKCID = 63c931a6a4c0ab5de2fbd1712b1143db
_PrelinkKCID = 9333620388e3aa7308fc7c9f4d7b21e0
```

Nessuno di questi valori è una base VM o uno slide.

---

## 4. Classificazione degli indirizzi

| Classe | Stato | Valore |
|---|---|---|
| Valore encoded a 64 bit | **PROVEN** | letto dalla catena |
| `target` a 30 bit | **PROVEN** | 0–1.073.741.823 |
| Indirizzo KC-relativo del target | **PROVEN** | `target` (la KC è base 0) |
| Segmento KC del target | **PROVEN** | `__REGION*` per contenimento |
| Indirizzo assoluto VM | **UNPROVEN** | richiede `basePointers`/kernel slide |
| Indirizzo runtime dopo KASLR | **UNPROVEN** | richiede slide del boot |
| Appartenenza al provider | **UNPROVEN** | dipende dalla base e dal binding |

**PROVEN:** la KC è **base-0** per i suoi segmenti; `target` è quindi una coordinata **KC-relativa** e può essere confrontata con i `vmaddr` dei segmenti. **UNPROVEN:** che `basePointers` sia zero; che il target sia l’indirizzo finale; che il kernel usi la stessa base.

**Conclusione parziale:** `X6100-RUNTIME-ADDRESSES` è **RELATIVE_ONLY**. I target assoluti non sono ricostruibili dal solo SystemKC; servono la base del kernel e l’array `basePointers` fornito dal loader. **Nessun GO.**

---

## 5. Collegamento al report provider

Il report `X6100-PROVIDER-RESOLUTION.md` usa questi target come **contenimento KC-relativo**, non come prova di risoluzione assoluta. I provider esterni grezzi sono identificati per segmento/entry, ma la loro validità come dipendenza runtime resta **UNPROVEN**.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, build o boot. Spazio libero **12.910.244 KiB** (circa **12,31 GiB**) > **10 GiB**. **T27 OPEN.**
