# T27 — AGENT-AMD — X6100 PROVIDER RESOLUTION

**Scope:** verificare se i **8.544** puntatori chained-fixup di `AMDRadeonX6100HWLibs` embedded nella `SystemKernelExtensions.kc` 25G342 cadono in provider realmente presenti nella collezione, e confrontare il risultato con `OSBundleLibraries` e i simboli importati.  
**Modalità:** sola lettura; parsing Mach-O, `LC_FILESET_ENTRY`, `__PRELINK_INFO`, segmenti, chained-fixups, `nm`; SHA-256. Nessuna estrazione, copia, scrittura, build o boot.  
**Esito:** **7.658/8.544** target ricadono in X6100 (**89,63%**); **886/8.544** ricadono, come contenimento KC-relativo, in **tre altri bundle AMD presenti**: `AMDRadeonX4000HWLibs` **877**, `AMD10000Controller` **8**, `AMDRadeonX4400HWLibs` **1**. **0** target non risolti, **0** sovrapposizioni, **0** target verso provider Apple. Però `OSBundleLibraries` di X6100 dichiara **solo IOPCIFamily + kpi**, **nessuna dipendenza AMD**, e `nm -u` non contiene nomi AMD; inoltre `basePointers` non è serializzato. Quindi il **contenimento grezzo** è **PROVEN**, la **risoluzione assoluta/provider** è **UNPROVEN**: non si può affermare che X6100 dipenda davvero da quei tre bundle. `IOPCIFamily`, dichiarata, **non è nella SystemKC**; è nella BootKC. **T27 resta OPEN.**

---

## 1. Input e stato del report runtime

| Input | Stato | Uso |
|---|---|---|
| `X6100-RUNTIME-ADDRESSES.md` | **creato** | base-0 relativa, target, limiti assoluti |
| `AMD-SYSTEMKC-28-INVENTORY.md` | disponibile | 28 bundle AMD, UUID, fileoff, prelink size |
| `X6100-FIXUP-VALIDATION.md` | disponibile | 8.544 puntatori, livelli, target |
| `SYSTEMKC-INCLUSION-EVIDENCE.md` | disponibile | 172 fileset entry, UUID embedded |

`X6100-RUNTIME-ADDRESSES.md` stabilisce che la KC è **base-0** e che `indirizzo = basePointers[cacheLevel] + target`; `basePointers` e `kernelSlide` hanno **0 occorrenze** nella KC. Il presente report usa quindi i target come **coordinate KC-relative**, non come indirizzi assoluti.

---

## 2. Identità della collezione

| Campo | Valore |
|---|---|
| SystemKC | `HAO-PROJECT/Sessions/<SESSION>/work/root-full/System/Library/KernelCollections/SystemKernelExtensions.kc` |
| SHA-256 | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| Dimensione | **369.213.440 B** |
| Build | **25G342 / 26.7.3** |
| UUID | `93336203-88E3-AA73-08FC-7C9F4D7B21E0` |
| Architettura | **x86_64** |
| `LC_FILESET_ENTRY` | **172** |
| `_PrelinkInfoDictionary` | **180** |
| Bundle AMD | **28** |

**PROVEN:** la collezione contiene i 28 bundle AMD dell’inventario; X6100 ha `entry_id` e `LC_FILESET_ENTRY` propri.

---

## 3. Conteggio per classi

| Classe | Puntatori | Quota | `cacheLevel` |
|---|---:|---:|---|
| **Interni X6100** | **7.658** | **89,63%** | 1 |
| **Esterni grezzi — `AMDRadeonX4000HWLibs`** | **877** | **10,26%** | 0 |
| **Esterni grezzi — `AMD10000Controller`** | **8** | **0,09%** | 0 |
| **Esterni grezzi — `AMDRadeonX4400HWLibs`** | **1** | **0,01%** | 0 |
| **Non risolti / fuori segmento** | **0** | **0%** | — |
| **Apple provider** | **0** | **0%** | — |
| **Totale** | **8.544** | **100%** | — |

**Somma:** `7.658 + 877 + 8 + 1 = 8.544`. **Esterni totali:** **886** (10,37%); **interni + esterni = 8.544**. **Nessun target esterno a X6100 cade fuori dai segmenti mappati.**

### 3.1 Per livello

| `cacheLevel` | Interni X6100 | Esterni AMD | Totale |
|---:|---:|---:|---:|
| 1 | **7.658** | **0** | **7.658** |
| 0 | **0** | **886** | **886** |
| **Totale** | **7.658** | **886** | **8.544** |

**MISURATO:** la separazione è netta: **livello 1 = X6100**, **livello 0 = esterni grezzi**. Non è una prova di binding: la base `cacheLevel` non è serializzata.

---

## 4. Provider esterni grezzi: identità e range

### 4.1 `AMDRadeonX4000HWLibs`

| Campo | Valore |
|---|---|
| `entry_id` | `com.apple.kext.AMDRadeonX4000HWLibs` |
| UUID | **`DFD77453-7CFD-3F72-8BFE-779582EA4E73`** |
| `LC_FILESET_ENTRY.fileoff` | **7.237.632** (`0x6E7000`) |
| `LC_FILESET_ENTRY.vmaddr` | **7.237.632** (`0x6E7000`) |
| `_PrelinkExecutableLoadAddr` | **7.237.632** |
| `_PrelinkExecutableSize` | **2.739.696 B** |
| Target | **877** |
| Range target | **0x91C1F0–0x12AA5C0** |
| Segmenti | `__REGION18`, `__REGION19` |
| Sorgenti | `__DATA,__const` **870**, `__DATA,__got` **7** |

**PROVEN:** il bundle è presente nella SystemKC con UUID, entry, fileoff, vmaddr e prelink size coerenti; i 877 target ricadono nei suoi segmenti. **Non è dichiarato** in `OSBundleLibraries` di X6100.

### 4.2 `AMD10000Controller`

| Campo | Valore |
|---|---|
| `entry_id` | `com.apple.kext.AMD10000Controller` |
| UUID | **`B52EC43A-4077-3460-A1F5-4BC94CE9CCF7`** |
| `LC_FILESET_ENTRY.fileoff` | **1.605.632** (`0x188000`) |
| `LC_FILESET_ENTRY.vmaddr` | **1.605.632** (`0x188000`) |
| `_PrelinkExecutableLoadAddr` | **1.605.632** |
| `_PrelinkExecutableSize` | **382.670 B** |
| Target | **8** |
| Range target | **0x1AD4C0–0x1AF250** |
| Segmento | `__REGION0` |
| Sorgente | `__DATA,__got` **8** |

**PROVEN:** bundle presente, UUID e coordinate coerenti; 8 target nel suo `__got`. **Non dichiarato** da X6100.

### 4.3 `AMDRadeonX4400HWLibs`

| Campo | Valore |
|---|---|
| `entry_id` | `com.apple.kext.AMDRadeonX4400HWLibs` |
| UUID | **`02740323-FC2D-30DF-9FD4-2106BE3F3131`** |
| `LC_FILESET_ENTRY.fileoff` | **34.152.448** (`0x2092000`) |
| `LC_FILESET_ENTRY.vmaddr` | **34.152.448** (`0x2092000`) |
| `_PrelinkExecutableLoadAddr` | **34.152.448** |
| `_PrelinkExecutableSize` | **3.006.332 B** |
| Target | **1** |
| Target | **0x2941C50** |
| Segmento | `__REGION25` |
| Sorgente | `__DATA,__got` **1** |

**PROVEN:** bundle presente, UUID e coordinate coerenti; 1 target nel suo `__got`. **Non dichiarato** da X6100.

---

## 5. `__got` e sezioni sorgente

### 5.1 Distribuzione per sezione

| Sezione X6100 | Puntatori | Interni | Esterni | Note |
|---|---:|---:|---:|---|
| `__DATA,__const` | **4.506** | **3.636** | **870** | 870 tutti X4000HWLibs |
| `__DATA,__data` | **3.997** | **3.997** | **0** | nessun esterno |
| `__DATA,__got` | **29** | **13** | **16** | 7 X4000, 8 AMD10000, 1 X4400 |
| `__DATA_CONST,__kalloc_type` | **6** | **6** | **0** | — |
| `__DATA,__mod_init_func` | **3** | **3** | **0** | — |
| `__DATA,__mod_term_func` | **3** | **3** | **0** | — |
| **Totale** | **8.544** | **7.658** | **886** | — |

**PROVEN:** gli esterni sono **870 cost + 16 got**; **nessun esterno in `__data`**. La quota esterna è concentrata in `__const` per X4000HWLibs.

### 5.2 `__got` (29 puntatori)

| Destinazione | Puntatori |
|---|---:|
| X6100 interno | **13** |
| `AMDRadeonX4000HWLibs` | **7** |
| `AMD10000Controller` | **8** |
| `AMDRadeonX4400HWLibs` | **1** |
| **Totale** | **29** |

**MISURATO:** `__got` contiene **16 puntatori esterni grezzi** verso tre bundle AMD e **13 interni**. Non contiene target Apple.

---

## 6. Presenza dei provider nella SystemKC

| Provider | In SystemKC | In BootKC | Target grezzi | Dichiarato da X6100 |
|---|---|---|---|---:|
| `AMDRadeonX4000HWLibs` | **SÌ** | — | **877** | **NO** |
| `AMD10000Controller` | **SÌ** | — | **8** | **NO** |
| `AMDRadeonX4400HWLibs` | **SÌ** | — | **1** | **NO** |
| `IOPCIFamily` | **NO** | **SÌ** (58 occorrenze) | **0** | **SÌ** |
| `IOGraphicsFamily` | **SÌ** | — | **0** | NO |
| `IOAcceleratorFamily2` | **SÌ** | — | **0** | NO |
| `AppleGraphicsDeviceControl` | **SÌ** | — | **0** | NO |
| `IOACPIFamily` | **NO** | **SÌ** (storicamente) | **0** | NO |
| `IOSurface` | **NO** | **SÌ** (storicamente) | **0** | NO |
| `kpi.bsd/iokit/libkern/mach` | built-in | — | **0** | **SÌ** |

**BootKC:** `HAO-PROJECT/Sessions/<SESSION>/work/root-full/System/Library/KernelCollections/BootKernelExtensions.kc`, SHA-256 `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840`, **67.600.384 B**.  
**PROVEN:** `com.apple.iokit.IOPCIFamily` compare **58** volte nella BootKC ed è **assente** dalla SystemKC. La dipendenza dichiarata da X6100 **non è soddisfatta dalla sola SystemKC**; serve la BootKC.

**Nessun target grezzo** cade in un provider Apple. I provider Apple presenti nella SystemKC (`IOGraphicsFamily`, `IOAcceleratorFamily2`, `AppleGraphicsDeviceControl`) **non sono dichiarati** da X6100 e **non ricevono target**.

---

## 7. Simboli importati e coerenza con `OSBundleLibraries`

`OSBundleLibraries` di X6100:

```text
com.apple.iokit.IOPCIFamily = 2.9
com.apple.kpi.bsd = 16.0
com.apple.kpi.iokit = 16.0
com.apple.kpi.libkern = 16.0
com.apple.kpi.mach = 16.0
```

`nm -u` su `e521`:

| Misura | Valore |
|---|---:|
| Simboli non definiti | **348** |
| `LC_DYSYMTAB` undef | **348** |
| Nomi contenenti `AMD` o `Radeon` | **0** |
| C++ (`__ZN…`) | **313** |
| OS/PE (`_OS…`, `_PE…`) | **4** |
| Altri (I/O kit, C) | **31** |
| `IOPCIDevice` | **7** |
| `IOMemoryMap` | **1** |

**PROVEN:** i 348 import non contengono nomi AMD/Radeon; sono coerenti con IOPCIFamily (`IOPCIDevice`) e KPI/OS. **Nessun import simbolico AMD**.

**Contraddizione strutturale:** i target grezzi `cacheLevel=0` cadono in tre bundle AMD, ma:
1. `OSBundleLibraries` non li dichiara;
2. `nm -u` non contiene simboli AMD;
3. `LC_DYLD_CHAINED_FIXUPS.imports_count = 0` (nessun bind; solo rebase);
4. `basePointers` non è serializzato.

Quindi il contenimento grezzo **non prova** che X6100 usi quei provider. Le spiegazioni possibili sono:
- `basePointers[cacheLevel]` non è zero e i target grezzi non sono gli indirizzi finali;
- i puntatori esterni sono riferimenti **dati** prelinkati, non import simbolici, e possono essere **non dichiarati/weak**;
- il mapping grezzo è corretto ma `OSBundleLibraries` è incompleto.

Nessuna delle tre è dimostrata. **Provider resolution = UNPROVEN.**

---

## 8. Sovrapposizioni e non risolti

| Controllo | Risultato |
|---|---:|
| Target fuori da ogni segmento KC | **0** |
| Target in più di un segmento | **0** |
| Sovrapposizioni tra range interni ed esterni | **0** (`0xDD6E9A0+` vs `≤0x2941C50`) |
| Target verso provider Apple | **0** |
| Target verso bundle AMD assenti | **0** (i tre sono nei 28) |
| Target verso bundle non AMD | **0** |
| Target `cacheLevel=1` esterni | **0** |
| Target `cacheLevel=0` interni | **0** |
| Overflow di pagina/catena | **0** (da `X6100-FIXUP-VALIDATION`) |

**MISURATO:** tutti gli 8.544 target sono contenuti in un solo segmento KC; gli 886 esterni sono tutti in tre bundle AMD presenti. **Nessuna sovrapposizione**.

---

## 9. Classificazione

### PROVEN

- La SystemKC 25G342 contiene **28 bundle AMD**, **172 fileset entry**, **180 prelink entries**.
- X6100 è a `fileoff`/`vmaddr` **232.185.856**, UUID `533D1262…`.
- **8.544** target: **7.658 interni X6100**, **886 esterni grezzi**.
- Gli 886 esterni sono **877 X4000HWLibs + 8 AMD10000Controller + 1 X4400HWLibs**.
- I tre bundle esterni sono **presenti** con UUID, entry, fileoff, vmaddr e prelink size coerenti.
- **0** target non risolti, **0** fuori segmento, **0** sovrapposizioni, **0** target Apple.
- `__got` contiene **16 esterni** (7+8+1) e **13 interni**.
- `OSBundleLibraries` X6100 dichiara **solo IOPCIFamily + kpi**, **nessun AMD**.
- `nm -u` contiene **348** simboli, **0 AMD/Radeon**; `imports_count=0`.
- `IOPCIFamily` è **assente dalla SystemKC** e presente nella BootKC; `IOGraphicsFamily`, `IOAcceleratorFamily2`, `AGDC` sono nella SystemKC ma non dichiarati e senza target.

### INFERRED

- Il contenimento grezzo indica che i puntatori level 0 puntano verso la regione dei tre HWLibs/controller.
- La separazione level 1/level 0 è compatibile con due basi di cache diverse.
- I 16 `__got` esterni sono candidati a riferimenti cross-bundle, ma non sono import simbolici.

### UNPROVEN

- Che `basePointers[cacheLevel]` sia zero.
- Che i target level 0 siano indirizzi finali e che i provider siano davvero X4000/AMD10000/X4400.
- Che X6100 abbia una dipendenza runtime da uno dei tre bundle AMD.
- La compatibilità con `OSBundleLibraries` e l’assenza di dipendenze AMD dichiarate.
- La risoluzione assoluta/KASLR e il caricamento su 26B131.
- ABI, firma, SIP/AMFI.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Quanti target interni a X6100? | **7.658 / 8.544 (89,63%)** |
| Quanti esterni grezzi? | **886 / 8.544 (10,37%)** |
| Verso quali bundle? | **X4000HWLibs 877, AMD10000 8, X4400 1** |
| Sono presenti nella SystemKC? | **SÌ, tutti e tre** |
| Sono dichiarati da X6100? | **NO** |
| Ci sono import AMD? | **NO: 0 nomi AMD/Radeon; imports_count 0** |
| Ci sono target Apple? | **NO** |
| Ci sono non risolti/sovrapposizioni? | **0 / 0** |
| IOPCIFamily è nella SystemKC? | **NO; è nella BootKC** |
| La risoluzione provider è PROVEN? | **NO — UNPROVEN** |
| T27 è GO? | **NO — OPEN** |

Il risultato è **strutturalmente significativo ma non conclusivo**: i target grezzi level 0 ricadono in tre bundle AMD reali, tutti presenti; tuttavia mancano le basi `basePointers`, `OSBundleLibraries` non dichiara alcun AMD e non ci sono import simbolici AMD. Non è quindi possibile affermare che X6100 dipenda da X4000/AMD10000/X4400: è solo **contenimento KC-relativo**. La dipendenza dichiarata `IOPCIFamily` richiede la **BootKC**, non la sola SystemKC. T27 resta **OPEN**; 26B131 resta **BLOCKED**; percentuali ufficiali invariate: **94% engineering / 32% first boot / 8% desktop**.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, build, boot o modifica EFI/NVRAM/T2/SIP/AMFI. Spazio libero **12.910.244 KiB** (circa **12,31 GiB**) > **10 GiB**.
