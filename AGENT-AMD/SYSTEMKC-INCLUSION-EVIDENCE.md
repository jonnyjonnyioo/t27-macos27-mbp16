# T27 — AGENT-AMD — SYSTEMKC INCLUSION EVIDENCE

**Scope:** verificare se esistono prove strutturali **indipendenti** che colleghino `AMDRadeonX6100HWLibs` e gli altri componenti AMD alla `SystemKernelExtensions.kc` 25G342, oltre alla sola corrispondenza dei pool.  
**Modalità:** sola lettura; `otool -l`, `dwarfdump`, SHA-256, lettura in memoria di `__PRELINK_INFO`; nessuna estrazione, copia, scrittura, build o boot.  
**Esito:** la SystemKC 25G342 contiene **172 `LC_FILESET_ENTRY`** e gli **stessi 172 bundle ID** di `systemkc-all`; contiene **28 bundle AMD**, inclusi i sei della catena. I sei UUID sono presenti come **16 byte raw**, una volta ciascuno. L’inclusione dei **moduli** è quindi **PROVEN**; l’identità **`e521` a livello di `__text`/sezioni** è ora **PROVEN** da `X6100-EMBEDDED-IDENTITY.md`. Resta **UNPROVEN** l’identità del **file completo** e della firma.

---

## 1. Collezione sorgente

| Campo | Valore |
|---|---|
| Percorso | `HAO-PROJECT/Sessions/<SESSION>/work/root-full/System/Library/KernelCollections/SystemKernelExtensions.kc` |
| Dimensione | **369.213.440 B** |
| SHA-256 | **`b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7`** |
| UUID | **`93336203-88E3-AA73-08FC-7C9F4D7B21E0`** |
| Tipo | `Mach-O 64-bit x86_64` |
| Load commands | **689** |
| `LC_FILESET_ENTRY` | **172** |
| `LC_BUILD_VERSION` | 1 |
| `LC_UUID` | 1 |
| `LC_DYLD_CHAINED_FIXUPS` | 1 |
| `__PRELINK_INFO` | offset 245.760, size **1.359.872 B** |

L’hash coincide con quello registrato in `donor-source-kc.txt` per la `SystemKernelExtensions.kc` 25G342. La collezione non è stata modificata.

---

## 2. Prova diretta: `LC_FILESET_ENTRY`

`otool -l` espone 172 entry con `entry_id` **bundle ID** e `fileoff`:

| Bundle ID | `fileoff` | UUID | Occorrenze UUID raw |
|---|---|---:|---:|
| `com.apple.kext.AMDSupport` | 330.481.664 | `736ECBBA-C9C9-3AF7-BE6A-EB1944DB515B` | **1** |
| `com.apple.kext.AMDRadeonX6000Framebuffer` | 200.622.080 | `F527F501-CD46-34D0-AEB3-C8E5C8ADF2C8` | **1** |
| `com.apple.kext.AMDRadeonX6000HWServices` | 203.866.112 | `4A753C5A-7010-390E-B234-0DB2765A37E9` | **1** |
| `com.apple.kext.AMDRadeonServiceManager` | 2.768.896 | `53316747-531F-3003-97A7-4B51226A731D` | **1** |
| `com.apple.kext.AMDRadeonX6000` | 198.971.392 | `1540D089-EE2D-3339-B5A8-2024F9E38581` | **1** |
| `com.apple.kext.AMDRadeonX6100HWLibs` | **232.185.856** | `533D1262-BE83-3507-B48A-FDB91C9D8793` | **1** |

**Perché è una prova indipendente dal pool:** gli `entry_id` e i `fileoff` sono nei load commands della collezione, non nei nomi dei file estratti. La ricerca dei sei UUID come **16 byte binari** restituisce **1 occorrenza ciascuno**; la ricerca ASCII degli stessi UUID restituisce 0, quindi la corrispondenza non dipende da una stringa di report.

### 2.1 Altri identificatori

- `AMDRadeonX6100_AMDRadeonHWLibs`: **85** occorrenze in `__PRELINK_INFO`/stringhe della collezione.
- `AMDRadeonX6100HWLibs`: **9** occorrenze come stringa; **5** come bundle ID completo.
- `X6100HWLibs` è un **PlugIn** dentro `AMDRadeonX6000HWServices`, non un bundle top-level separato.

---

## 3. Confronto dell’intero set, non solo dei sei

| Misura | SystemKC 25G342 | `systemkc-all` |
|---|---:|---:|
| Bundle ID / file | **172** | **172** |
| ID unici | 172 | 172 |
| Differenze di set | **0** | **0** |
| Bundle AMD | **28** | **28** |
| `X6100HWLibs` | 1 | 1 |

**PROVEN:** l’insieme dei 172 `entry_id` della SystemKC è **identico** all’insieme dei 172 nomi di file di `systemkc-all`; non ci sono ID solo nell’una o solo nell’altra. Il pool contiene **28 AMD**, non sei: i sei della catena sono un **sottoinsieme rilevante** dei 28.

Questa è una correzione materiale a `SYSTEMKC-PROVENANCE.md`, che elencava solo i sei componenti della catena e poteva far intendere che il pool ne contenesse solo sei.

---

## 4. Cosa dicono gli output preesistenti

| Fonte | Esito |
|---|---|
| `HAO-81/deliverables/AMD-SYSTEMKC-ANALYSIS.md` | documenta `kmutil inspect -A` sulla SystemKC reale: **28 bundle AMD**, inclusi i sei; **report**, non stdout grezzo |
| `HAO-71/evidence/kmutil-hao71.log` | riporta solo le dimensioni reali delle KC (67.600.384 / 369.213.440); **nessun elenco membri** |
| `T16/.../kc-rebuild/sys-kmutil.txt` | riguarda una **SystemKC costruita** da 15.958.016 B, UUID `3540549A…`; **non** la SystemKC 25G342 |
| `kmutil inspect` sulla sorgente | **nessun output grezzo archiviato** |
| `kcditto` | **nessun output archiviato** |
| log di estrazione `ipsw`/`kcditto` per-pool | **assente** |

La prova della §2 non dipende da questi output: è stata ottenuta dai load commands della collezione.

---

## 5. Variante binaria: cosa non è provato

Le due varianti note:

| Variante | Byte | SHA-256 | Firma |
|---|---:|---|---|
| `e521` in `systemkc-all` | 16.985.840 | `e521d3cc…` | NO |
| `00b6` in root2/KDK25 | 17.256.336 | `00b6214e…` | SÌ |

Ricerca byte-per-byte nella SystemKC:

```text
e521 full-file match: -1
00b6 full-file match: -1
e521 first 64 B:       -1
00b6 first 64 B:       -1
```

La collezione contiene una rappresentazione **embedded/rebased**, non un file Mach-O autonomo contiguo. Poiché `e521` e `00b6` condividono lo stesso UUID, l’UUID presente nella KC **non distingue** le due varianti.

**Quindi:**

- inclusione del **modulo X6100** nella SystemKC: **PROVEN**;
- presenza dell’UUID `533D1262…`: **PROVEN**;
- identità **`e521` vs `00b6`** a livello di **`__text`/sezioni**: **PROVEN `e521`**; `00b6` differisce di 21.383 B in `__text`;
- identità del **file completo** (linkedit/firma) e hash del binario caricato: **UNPROVEN**.

---

## 6. Classificazione

### 6.1 PROVEN

- La SystemKC 25G342 ha SHA **`b4b618bf…`**, 369.213.440 B, UUID **`93336203…`**.
- Contiene **172 `LC_FILESET_ENTRY`**.
- Gli stessi **172 bundle ID** sono in `systemkc-all`; differenza di set **0**.
- La collezione contiene **28 bundle AMD**; il pool ne contiene **28**.
- I sei componenti della catena hanno `entry_id` e UUID raw presenti:
  - `AMDSupport`
  - `AMDRadeonX6000Framebuffer`
  - `AMDRadeonX6000HWServices`
  - `AMDRadeonServiceManager`
  - `AMDRadeonX6000`
  - `AMDRadeonX6100HWLibs`
- `X6100HWLibs` ha `fileoff` **232.185.856** e UUID `533D1262…` una volta.
- `tahoe-bootkc-all` ha **0 AMD**.

### 6.2 INFERRED

- `systemkc-all` è l’estrazione della SystemKC 25G342: 172/172 ID e 28/28 AMD coincidono, ma manca un log di estrazione per-pool.
- `staged` è una copia di lavoro del pool; non è una fonte indipendente.
- I sei bundle sono quelli usati dalla catena HAO; la collezione ne contiene altri 22 AMD non rilevanti per questa catena.

### 6.3 UNPROVEN

- Che il **file completo** embedded sia byte-identico a `e521` o `00b6`: la KC ha `__LINKEDIT` condivisa e non una slice contigua. L’identità `e521` di `__text`/sezioni è **PROVEN**.
- Che tutti i 172 file siano byte-identici alla collezione, senza modifiche/filtri.
- Che la collezione sia stata effettivamente caricata dal kernel con questi sei bundle.
- L’ABI e la compatibilità con 26B131.
- La presenza AMD nella target 26B131: **assente** nei materiali; nessun boot.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Esiste una prova indipendente dal pool? | **SÌ**: `LC_FILESET_ENTRY` della SystemKC |
| I sei bundle sono nella SystemKC? | **PROVEN** |
| I loro UUID sono nella collezione? | **PROVEN**, 1 raw hit ciascuno |
| Il set completo coincide con il pool? | **PROVEN**: 172/172 ID |
| Quanti AMD contiene la SystemKC? | **28**, non sei |
| La variante è `e521` o `00b6`? | **`e521` per `__text`/sezioni; file completo UNPROVEN** |
| `systemkc-all` è l’estrazione della SystemKC? | **INFERRED**, non loggato |
| La collezione è stata caricata su 26B131? | **NO / BLOCKED** |
| T27 è GO? | **NO — OPEN** |

La SystemKC 25G342 contiene strutturalmente i sei moduli AMD della catena, e l’intero set di 172 bundle ID coincide con `systemkc-all`. Il `__text` embedded è byte-identico a `e521` e `00b6` differisce di 21.383 B; questo **non** dimostra che l’intero file `e521` sia embedded né che la collezione sia caricabile su 26B131: file completo, ABI e runtime restano **UNPROVEN**. Vedi `X6100-EMBEDDED-IDENTITY.md`.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, scrittura, build o boot. Spazio libero 12.926.764 KiB (12,33 GiB) > 10 GiB.
