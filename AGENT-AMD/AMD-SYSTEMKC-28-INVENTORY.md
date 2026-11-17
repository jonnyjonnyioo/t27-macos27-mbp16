# T27 — AGENT-AMD — 28 BUNDLE SYSTEMKC INVENTORY

**Scope:** inventario completo dei 28 bundle AMD della `SystemKernelExtensions.kc` 25G342, con `LC_FILESET_ENTRY`, UUID embedded, dimensione prelink, presenza nei pool/root e mappa delle dipendenze dei sei componenti Navi14.  
**Modalità:** sola lettura; `otool -l`, parsing Mach-O, `__PRELINK_INFO`, `Info.plist`, SHA-256. Nessuna estrazione, copia, scrittura, build o boot.  
**Esito:** la SystemKC contiene **28 bundle AMD** e **172 fileset entries**; `systemkc-all` ha gli stessi **172 bundle ID** e gli stessi **28 AMD**. Root2 ha **28/28 bundle e 28/28 binari**; root3 ha **6 bundle AMD, 5 dei sei Navi14 e nessun X6100**; root25 è **25G342 / 26.7.3**, ha **28 `Info.plist` ma 0/28 binari**. Le dipendenze dei sei sono soddisfatte nel donor SystemKC+BootKC, ma non esiste una prova di runtime su 26B131.

---

## 1. Sorgente e metodo

| Campo | Valore |
|---|---|
| SystemKC | `<SESSION>/work/root-full/System/Library/KernelCollections/SystemKernelExtensions.kc` |
| SHA-256 | **`b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7`** |
| Dimensione | **369.213.440 B** |
| `LC_FILESET_ENTRY` | **172** |
| `_PrelinkInfoDictionary` | **180** |
| Bundle AMD | **28** |

I 172 `entry_id` sono stati confrontati con i 172 nomi di `systemkc-all`: **differenza 0**; i 28 AMD sono presenti in entrambi. Ogni entry è stata aperta al proprio `fileoff` per leggere `LC_UUID`; `_PrelinkExecutableSize` viene da `__PRELINK_INFO` ed è la dimensione dell’**eseguibile prelinkato**, non del file Mach-O completo.

---

## 2. Inventario dei 28 AMD

`Pool` = file in `systemkc-all`; `R2`, `R3`, `R25` = **binario** presente in root2/root3/root25, non solo `Info.plist`. `Pool SHA` è troncato a 12 hex.

| # | Bundle ID | fileoff | UUID embedded | Prelink size | Pool | Pool byte | Pool SHA | R2 | R3 | R25 |
|---:|---|---:|---|---:|---|---:|---|---|---|---|
| 1 | `com.apple.kext.AMD10000Controller` | 1.605.632 | `b52ec43a-4077-3460-a1f5-4bc94ce9ccf7` | 382.670 | SÌ | 718.024 | `4cc04d310773` | SÌ | NO | NO |
| 2 | `com.apple.kext.AMD9500Controller` | 2.121.728 | `738cbe3c-2cd3-38ae-9140-055dcad52abd` | 384.992 | SÌ | 719.424 | `173851d0fdcd` | SÌ | NO | NO |
| 3 | `com.apple.kext.AMDFramebuffer` | 2.600.960 | `2723d92d-6032-3051-9874-a87de97b25cb` | 144.260 | SÌ | 234.936 | `54033d995b2d` | SÌ | SÌ | NO |
| 4 | `com.apple.kext.AMDRadeonServiceManager` | 2.768.896 | `53316747-531f-3003-97a7-4b51226a731d` | 11.976 | SÌ | 52.176 | `bdb566f37ce2` | SÌ | SÌ | NO |
| 5 | `com.apple.kext.AMDRadeonX4000` | 2.793.472 | `5d0b64fe-9944-3382-a0fa-26d1cac4bc01` | 4.153.480 | SÌ | 4.851.280 | `8578aa4c88c9` | SÌ | NO | NO |
| 6 | `com.apple.kext.AMDRadeonX4000HWServices` | 7.208.960 | `d4bc2b2b-a6f3-30f1-b9ed-defcfd8723a0` | 8.939 | SÌ | 54.912 | `adb5a11c8160` | SÌ | NO | NO |
| 7 | `com.apple.kext.AMDRadeonX4000HWLibs` | 7.237.632 | `dfd77453-7cfd-3f72-8bfe-779582ea4e73` | 2.739.696 | SÌ | 14.754.424 | `1d483e3016eb` | SÌ | NO | NO |
| 8 | `com.apple.kext.AMDRadeonX4100HWLibs` | 21.532.672 | `3c1cf907-8a39-33bc-913a-c0744c61b545` | 1.360.574 | SÌ | 12.946.088 | `facfc91f25cb` | SÌ | NO | NO |
| 9 | `com.apple.kext.AMDRadeonX4400HWLibs` | 34.152.448 | `02740323-fc2d-30df-9fd4-2106be3f3131` | 3.006.332 | SÌ | 18.626.072 | `47ae22c7d1cc` | SÌ | NO | NO |
| 10 | `com.apple.kext.AMDRadeonX4700HWLibs` | 52.264.960 | `2e7244e3-bc29-375e-bd7c-13212b4cdd98` | 3.006.356 | SÌ | 18.626.072 | `c76727477698` | SÌ | NO | NO |
| 11 | `com.apple.kext.AMDRadeonX5000` | 70.377.472 | `e27efb64-de35-3ce5-b3ab-a32218b495d3` | 2.244.296 | SÌ | 2.897.864 | `c7a0dfd861be` | SÌ | NO | NO |
| 12 | `com.apple.kext.AMDRadeonX5000HWServices` | 72.855.552 | `d596268c-b01d-361d-aef0-0fd7374a499d` | 9.211 | SÌ | 54.912 | `a7f9d3012825` | SÌ | NO | NO |
| 13 | `com.apple.kext.AMDRadeonX5000HWLibs` | 72.884.224 | `98779cea-e395-3829-a5b9-fea1ca9e11b4` | 6.036.348 | SÌ | 37.625.368 | `039791ef8ac1` | SÌ | NO | NO |
| 14 | `com.apple.kext.AMDRadeonX5100HWLibs` | 109.793.280 | `06edaec9-2438-351d-b0ca-6c065c06449e` | 3.625.328 | SÌ | 11.698.760 | `9ed1c149e90c` | SÌ | NO | NO |
| 15 | `com.apple.kext.AMDRadeonX5200HWLibs` | 120.860.672 | `c9b62e3a-9104-3636-b42c-7b1694be0531` | 4.518.880 | SÌ | 25.134.576 | `94299cd7a31a` | SÌ | NO | NO |
| 16 | `com.apple.kext.AMDRadeonX5400HWLibs` | 145.293.312 | `0bc3f48b-d341-3367-8dbb-b274e7e2dc0b` | 4.538.824 | SÌ | 27.248.528 | `92e3166d301d` | SÌ | NO | NO |
| 17 | `com.apple.kext.AMDRadeonX5700HWLibs` | 171.835.392 | `1b16f5e6-63ce-3e6f-90df-96aed9c623a6` | 4.933.528 | SÌ | 27.843.232 | `84d7b7cd3a5e` | SÌ | NO | NO |
| 18 | `com.apple.kext.AMDRadeonX6000` | 198.971.392 | `1540d089-ee2d-3339-b5a8-2024f9e38581` | 1.401.048 | SÌ | 2.090.264 | `2734aaf7bf33` | SÌ | SÌ | NO |
| 19 | `com.apple.kext.AMDRadeonX6000Framebuffer` | 200.622.080 | `f527f501-cd46-34d0-aeb3-c8e5c8adf2c8` | 2.661.080 | SÌ | 3.452.992 | `a24694296022` | SÌ | SÌ | NO |
| 20 | `com.apple.kext.AMDRadeonX6000HWServices` | 203.866.112 | `4a753c5a-7010-390e-b234-0db2765a37e9` | 9.163 | SÌ | 55.008 | `cc7aaca45446` | SÌ | SÌ | NO |
| 21 | `com.apple.kext.AMDRadeonX6000HWLibs` | 203.894.784 | `5cd4bc0c-c225-365f-a872-c885575b9a19` | 5.548.140 | SÌ | 28.865.520 | `a6a1040fef26` | SÌ | NO | NO |
| 22 | **`com.apple.kext.AMDRadeonX6100HWLibs`** | **232.185.856** | **`533d1262-be83-3507-b48a-fdb91c9d8793`** | **3.857.192** | SÌ | **16.985.840** | **`e521d3cce8f9`** | SÌ | NO | NO |
| 23 | `com.apple.kext.AMDRadeonX6200HWLibs` | 248.594.432 | `dbb13b6a-1a5f-36e7-b1b0-ad9bc28dd590` | 3.854.752 | SÌ | 21.448.616 | `1281fc923c3c` | SÌ | NO | NO |
| 24 | `com.apple.kext.AMDRadeonX6300HWLibs` | 269.463.552 | `ba862b7e-a5a5-3dfd-ad6e-5ca15153f905` | 4.050.700 | SÌ | 15.421.320 | `0c9d5ee4d561` | SÌ | NO | NO |
| 25 | `com.apple.kext.AMDRadeonX6700HWLibs` | 284.315.648 | `db4069df-e5c3-3ad3-8d4c-14a0b2b5fc6f` | 4.319.784 | SÌ | 22.373.152 | `730c306a339d` | SÌ | NO | NO |
| 26 | `com.apple.kext.AMDRadeonX6800HWLibs` | 306.110.464 | `277b8059-8c8e-3a34-8b72-194ae937aae1` | 4.493.084 | SÌ | 13.367.568 | `d772a62d0033` | SÌ | NO | NO |
| 27 | `com.apple.kext.AMDRadeonX6810HWLibs` | 318.922.752 | `dbe47500-dafb-3947-a685-edfae59e1368` | 4.415.420 | SÌ | 12.088.048 | `8ef0ad511384` | SÌ | NO | NO |
| 28 | `com.apple.kext.AMDSupport` | 330.481.664 | `736ecbba-c9c9-3af7-be6a-eb1944db515b` | 807.584 | SÌ | 1.415.088 | `c569698b689d` | SÌ | SÌ | NO |

**Nota:** `Prelink size` per X6100 è 3.857.192 B, mentre il file `systemkc-all` è 16.985.840 B: sono misure diverse (eseguibile prelinkato vs Mach-O completo).

---

## 3. Presenza nei root

| Sorgente | Bundle AMD | Binari AMD | Note |
|---|---:|---:|---|
| SystemKC 25G342 | **28** | n/a (embedded) | 172 fileset entries |
| `systemkc-all` | **28** | **28** | stessi 172 ID della SystemKC |
| root2 | **28** | **28** | X6100 = `00b6214e…`, 17.256.336 B |
| root3 | **6** | **6** | 5 dei sei Navi14; **X6100 assente** |
| root25 | **28** | **0** | solo `Info.plist`/`_CodeSignature`/`version.plist`; **nessun `Contents/MacOS`** |

Root25 è la volume montato `<DONOR_VOLUME>`: `SystemVersion.plist` riporta **25G342 / macOS 26.7.3**, quindi **non è 26B131**. La presenza dei 28 bundle senza binari non è una fonte eseguibile.

Root3 contiene `AMDFramebuffer`, `AMDRadeonServiceManager`, `AMDRadeonX6000`, `AMDRadeonX6000Framebuffer`, `AMDRadeonX6000HWServices`, `AMDSupport`: **cinque** dei sei componenti Navi14, **X6100 assente**. Root3 non può quindi fornire la catena completa.

---

## 4. Dipendenze dei sei componenti Navi14

Le `OSBundleLibraries` della SystemKC sono state confrontate con gli `Info.plist` reali di root2/root3/root25. Per i sei bundle, **root2 e root25 hanno gli stessi set della SystemKC**; root3 coincide per i cinque presenti.

| Bundle | `CFBundleExecutable` | `OSBundleLibraries` (sintesi) | Dipendenze mancanti nel donor |
|---|---|---|---|
| `AMDSupport` | `AMDSupport` | `AppleGraphicsDeviceControl`, `IOACPIFamily`, `IOGraphicsFamily`, `IOPCIFamily`, `kpi.bsd/iokit/libkern/mach/unsupported` | **nessuna** |
| `AMDRadeonX6000Framebuffer` | `AMDRadeonX6000Framebuffer` | `AppleGraphicsDeviceControl`, `IOACPIFamily`, `IOGraphicsFamily`, `IOPCIFamily`, `kpi.*` | **nessuna** |
| `AMDRadeonX6000HWServices` | `AMDRadeonX6000HWServices` | `IOACPIFamily`, `IOGraphicsFamily`, `IOPCIFamily`, `kpi.*` | **nessuna** |
| `AMDRadeonServiceManager` | `AMDRadeonServiceManager` | `IOPCIFamily`, `kpi.bsd/iokit/libkern` | **nessuna** |
| `AMDRadeonX6000` | `AMDRadeonX6000` | `IOAcceleratorFamily2`, `IOGraphicsFamily`, `IOPCIFamily`, `IOSurface`, `kpi.*` | **nessuna** |
| **`AMDRadeonX6100HWLibs`** | **`AMDRadeonX6100HWLibs`** | **`IOPCIFamily`, `kpi.bsd/iokit/libkern/mach`** | **nessuna** |

### 4.1 Dove sono risolte

| Dipendenza | SystemKC/pool | BootKC | Root2 | Root25 (solo plist) |
|---|---|---|---|---|
| `com.apple.AppleGraphicsDeviceControl` | **SÌ** | NO | SÌ | SÌ |
| `com.apple.iokit.IOAcceleratorFamily2` | **SÌ** | NO | SÌ | SÌ |
| `com.apple.iokit.IOGraphicsFamily` | **SÌ** | NO | SÌ | SÌ |
| `com.apple.iokit.IOACPIFamily` | NO | **SÌ** | SÌ | SÌ |
| `com.apple.iokit.IOPCIFamily` | NO | **SÌ** | SÌ | SÌ |
| `com.apple.iokit.IOSurface` | NO | **SÌ** | SÌ | SÌ |
| `com.apple.kpi.*` | built-in | built-in | plist | plist |

**PROVEN:** nel donor, tutte le dipendenze dichiarate dai sei sono presenti tra SystemKC (le tre famiglie IOKit non-AMD), BootKC (le tre famiglie IOKit base) o sono KPI built-in. **X6100 non dipende da un altro AMD**: le sue `OSBundleLibraries` sono solo `IOPCIFamily` + KPI.

**UNPROVEN:** che la stessa risoluzione avvenga su 26B131, che il kernel accetti l’ABI e che i sei vengano caricati.

---

## 5. Varianti X6100

| Fonte | Byte | SHA-256 | Binario |
|---|---:|---|---|
| `systemkc-all` | 16.985.840 | `e521d3cc…` | SÌ |
| root2 | 17.256.336 | **`00b6214e…`** | SÌ |
| root3 | — | — | **NO** |
| root25 | — | — | **NO** (solo bundle) |
| SystemKC embedded | — | non contiguo | UUID condiviso |

`e521` e `00b6` condividono UUID `533D1262…`; la SystemKC non contiene nessuno dei due come file contiguo. Il `__text` embedded è **byte-identico a `e521`** (SHA `19dcb85d…`), mentre `00b6` differisce di **21.383 B**: identità **`e521` a livello di codice/sezioni PROVEN**, identità del **file completo** e firma **UNPROVEN**. Root3 non può risolverla perché X6100 è assente. Vedi `X6100-EMBEDDED-IDENTITY.md`.

---

## 6. Classificazione

### PROVEN

- La SystemKC 25G342 ha **28 bundle AMD** e **172 `LC_FILESET_ENTRY`**.
- I 28 bundle hanno `entry_id`, `fileoff`, UUID embedded e `_PrelinkExecutableSize` letto da `__PRELINK_INFO`.
- I 28 bundle ID coincidono con i 28 file AMD di `systemkc-all`; l’intero set 172/172 coincide.
- Root2 contiene **28/28 bundle e 28/28 binari**.
- Root3 contiene **6 bundle AMD / 6 binari**, ma solo **5 dei sei Navi14**; X6100 è **assente**.
- Root25 è **25G342 / 26.7.3**, contiene **28 `Info.plist`** ma **0/28 binari**.
- Per i sei, le `OSBundleLibraries` della SystemKC coincidono con root2/root25 e con i cinque presenti in root3.
- Le dipendenze dei sei sono risolte nel donor SystemKC+BootKC; nessun AMD dipende da un altro AMD.

### INFERRED

- `systemkc-all` deriva dalla SystemKC 25G342: 172/172 ID e 28/28 AMD coincidono, ma manca un log di estrazione.
- `_PrelinkExecutableSize` descrive l’eseguibile prelinkato, non il file completo.
- Root25 rappresenta i metadati 25G342 del volume target, non una copia eseguibile.

### UNPROVEN

- Che il **file completo** embedded X6100 sia byte-identico a `e521` o `00b6`; l’identità `e521` di `__text`/sezioni è **PROVEN**.
- Che root2/root3/root25 siano byte-identici alla SystemKC per tutti i 28 (sono state confrontate presenza e dichiarazioni, non tutti gli hash).
- Che i sei bundle siano caricati dal kernel su 26B131.
- ABI, firma, SIP/AMFI e compatibilità 26B131.
- La presenza AMD nella target 26B131: **assente** nei materiali; nessun boot.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Quanti AMD nella SystemKC? | **28** |
| I 28 sono nel pool? | **SÌ, 28/28; set 172/172 identico** |
| Root2 è completo? | **SÌ, 28/28 bundle e binari** |
| Root3 è completo per Navi14? | **NO: 5/6; X6100 assente** |
| Root25 è utilizzabile? | **NO: 28 bundle, 0 binari; è 25G342, non 26B131** |
| Le dipendenze dei sei sono risolte nel donor? | **SÌ, nessuna mancante** |
| X6100 è `e521` o `00b6`? | **`e521` per `__text`/sezioni; file completo UNPROVEN** |
| Runtime su 26B131? | **BLOCKED** |
| T27 è GO? | **NO — OPEN** |

La catena AMD è **strutturalmente completa** nel donor: 28 bundle nella SystemKC, 28 nel pool, 28 binari in root2, dipendenze dei sei risolte da SystemKC/BootKC. Root3 e root25 **non** sono sostituti completi: root3 perde X6100, root25 non ha binari. Restano **UNPROVEN** l’identità del file completo, la firma, l’ABI e il runtime su 26B131; il codice embedded è `e521`.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, scrittura, build o boot. Spazio libero 12.929.320 KiB (12,33 GiB) > 10 GiB.
