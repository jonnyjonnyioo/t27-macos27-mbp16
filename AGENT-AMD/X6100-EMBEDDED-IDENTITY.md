# T27 — AGENT-AMD — X6100 EMBEDDED IDENTITY

**Scope:** identificare quale variante `AMDRadeonX6100HWLibs` (`e521…` di `systemkc-all` o `00b6…` di root2) corrisponde all’eseguibile embedded nella `SystemKernelExtensions.kc` 25G342.  
**Modalità:** sola lettura e confronto in memoria; `otool`-equivalent parsing Mach-O, SHA-256, confronto sezione per sezione. Nessuna estrazione, copia, scrittura, build o boot.  
**Esito:** il `__text` embedded ha lo **stesso SHA-256 di `e521`**; `00b6` differisce di **21.383 byte**. `e521` coincide in **9/9 sezioni file-backed** (16.395.381 B identici, **0 differenze reali**); le 2 sezioni S_ZEROFILL `__common`/`__bss` non sono confrontabili. `00b6` coincide in **2/9 sezioni file-backed** (1.492.465 B identici, **56.727 B diversi**); le 2 S_ZEROFILL hanno 1.999 B apparenti esclusi. L’identità **a livello di codice/sezioni** è `e521`; l’identità del **file completo**, firma e runtime restano **UNPROVEN**.

---

## 1. Coordinate dell’embedded

| Campo | Valore |
|---|---|
| SystemKC | `<SESSION>/work/root-full/System/Library/KernelCollections/SystemKernelExtensions.kc` |
| SHA-256 SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| `LC_FILESET_ENTRY` X6100 `fileoff` | **232.185.856** |
| `__TEXT` embedded | offset **232.185.856**, size **3.858.432 B** |
| `__TEXT,__text` embedded | offset **232.188.256**, size **2.362.326 B** |
| `_PrelinkExecutableSize` | **3.857.192 B** |
| UUID embedded | `533D1262-BE83-3507-B48A-FDB91C9D8793` |
| Load commands embedded | **9** |

`_PrelinkExecutableSize` è la dimensione prelinkata, non il file completo; non coincide con `__TEXT` (3.858.432 B) né con i 16.985.840 B di `e521`.

---

## 2. Hash di `__text`

| Fonte | Offset `__text` | Size | SHA-256 `__text` |
|---|---:|---:|---|
| SystemKC embedded | 232.188.256 | 2.362.326 | **`19dcb85d59d7a1f63b36a6a9218392b9bd0ee347432199b530607965f32a7126`** |
| `e521` (`systemkc-all`) | 2.400 | 2.362.326 | **`19dcb85d59d7a1f63b36a6a9218392b9bd0ee347432199b530607965f32a7126`** |
| `00b6` (root2) | 2.400 | 2.362.326 | `c65134cb6051663b727aecf8fea3401e89547cae77fcd83af4410194a51c45cf` |

**`__text` embedded = `e521` byte-per-byte.** `00b6` differisce in **21.383 / 2.362.326 B**; è esattamente il delta `__text` già misurato tra le due varianti. L’UUID è condiviso e non discrimina.

---

## 3. Confronto per sezione

`__text` e le sezioni `__TEXT` sono identiche a `e521`. Le due differenze `e521` sono `__common` e `__bss` (zero-fill, non codice). `00b6` differisce in tutte le sezioni di codice e in gran parte di `__DATA`.

| Sezione | Size | `e521` | `00b6` |
|---|---:|---|---|
| `__TEXT,__text` | 2.362.326 | **EXACT** | DIFF **21.383** |
| `__TEXT,__cstring` | 508.425 | EXACT | EXACT |
| `__TEXT,__const` | 984.040 | EXACT | EXACT |
| `__DATA,__got` | 232 | EXACT | DIFF **123** |
| `__DATA,__mod_init_func` | 24 | EXACT | DIFF **12** |
| `__DATA,__mod_term_func` | 24 | EXACT | DIFF **12** |
| `__DATA,__const` | 65.904 | EXACT | DIFF **18.088** |
| `__DATA,__data` | 12.474.214 | EXACT | DIFF **17.084** |
| `__DATA,__common` | 1.528 | **N/A S_ZEROFILL** | **N/A S_ZEROFILL** |
| `__DATA,__bss` | 2.796 | **N/A S_ZEROFILL** | **N/A S_ZEROFILL** |
| `__DATA_CONST,__kalloc_type` | 192 | EXACT | DIFF **25** |

**Totali (solo sezioni file-backed):**

| Variante | Sezioni file-backed exact | Sezioni file-backed diff | Byte identici | Byte diversi reali |
|---|---:|---:|---:|---:|
| `e521` | **9/9** | **0/9** | **16.395.381** | **0** |
| `00b6` | 2/9 | 7/9 | 1.492.465 | **56.727** |

`__common` e `__bss` hanno `flags=0x1` (**S_ZEROFILL**) e `offset=0`: non hanno byte di file confrontabili. I 2.016 B apparenti per `e521` e i 1.999 B apparenti per `00b6` sono quindi esclusi e **non sono differenze di codice**. **Nessuna sezione file-backed differisce da `e521`.**

---

## 4. Load commands e rebasing

| Fonte | `ncmds` | Comandi |
|---|---:|---|
| SystemKC embedded | **9** | 4×`LC_SEGMENT_64`, `LC_SYMTAB`, `LC_DYSYMTAB`, `LC_UUID`, `LC_SOURCE_VERSION`, **`LC_DYLD_CHAINED_FIXUPS` (0x80000034)** |
| `e521` | 8 | 4×`LC_SEGMENT_64`, `LC_SYMTAB`, `LC_DYSYMTAB`, `LC_UUID`, `LC_SOURCE_VERSION` |
| `00b6` | 9 | 4×`LC_SEGMENT_64`, `LC_SYMTAB`, `LC_DYSYMTAB`, `LC_UUID`, `LC_SOURCE_VERSION`, `LC_CODE_SIGNATURE` |

La KC aggiunge **`LC_DYLD_CHAINED_FIXUPS`** e non contiene `LC_CODE_SIGNATURE`; `00b6` è firmato con `LC_CODE_SIGNATURE`. Questo è compatibile con un **`e521` rebased/chained-fixup** nella collezione, non con una copia del file firmato `00b6`.

Segmenti:

| Segmento | KC fileoff | KC size | `e521` fileoff | `e521` size |
|---|---:|---:|---:|---:|
| `__TEXT` | 232.185.856 | 3.858.432 | 0 | 3.858.432 |
| `__DATA` | 236.044.288 | 12.541.952 | 3.858.432 | 12.541.952 |
| `__DATA_CONST` | 248.590.336 | 4.096 | 16.400.384 | 4.096 |
| `__LINKEDIT` | 356.106.240 | **12.953.207** | 16.404.480 | **581.360** |

La `__LINKEDIT` della KC è **12.953.207 B** e non è confrontabile con i 581.360 B di `e521`: la collezione usa una linkedit condivisa/estesa. La ricerca del file `e521` o `00b6` completo nella KC resta **-1**; non esiste una slice contigua.

---

## 5. Interpretazione

### PROVEN

- Il `__text` embedded e il `__text` di `e521` hanno lo stesso SHA-256.
- Le sezioni di codice (`__text`, `__cstring`, `__const`) sono identiche a `e521`.
- `e521` coincide in **9/9 sezioni file-backed**; **0 differenze reali**; le due S_ZEROFILL `__common`/`__bss` non sono confrontabili.
- `00b6` differisce in **7/9 sezioni file-backed**, incluso `__text` per **21.383 B**; le due S_ZEROFILL non sono confrontabili.
- La KC ha `LC_DYLD_CHAINED_FIXUPS`; `00b6` ha `LC_CODE_SIGNATURE`; `e521` non ha né l’uno né l’altro.

### INFERRED

- L’embedded è la variante **`e521` rebased**, con fixup chained e linkedit della collezione.
- Le differenze `__common`/`__bss` sono effetto di zero-fill/rebasing, non di codice diverso.
- `00b6` è la variante firmata usata su root2, non quella incorporata nella KC.

### UNPROVEN

- Hash dell’**intero file** embedded: non esiste una slice contigua; `__LINKEDIT` è condivisa.
- Firma, entitlements e stato SIP/AMFI dell’embedded.
- ABI e caricamento runtime su 26B131.
- Che la KC sia stata caricata dal kernel target.

---

## 6. Conclusione

| Domanda | Risposta |
|---|---|
| Quale variante è l’embedded? | **`e521` a livello di `__text`/sezioni** |
| `__text` identico? | **SÌ, SHA `19dcb85d…`** |
| `00b6` compatibile? | **NO a livello di codice: 21.383 B di differenze** |
| Tutte le sezioni file-backed coincidono con `e521`? | **SÌ, 9/9; 0 differenze reali. 2 S_ZEROFILL N/A** |
| File completo identico? | **UNPROVEN: linkedit/firma non contigui** |
| Runtime 26B131? | **BLOCKED** |
| T27 è GO? | **NO — OPEN** |

La SystemKC 25G342 incorpora la variante **`e521`**: tutte le **9 sezioni file-backed** sono byte-identiche, e `00b6` è escluso dal confronto `__text` e dalle 7 sezioni file-backed differenti. Le 2 sezioni S_ZEROFILL non sono confrontabili. L’identità del **file completo** resta **UNPROVEN** perché la KC usa una `__LINKEDIT` condivisa e non contiene un Mach-O firmato contiguo. Questo è un **rafforzamento dell’identità del codice**, non una prova di ABI o di boot su 26B131.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, scrittura, build o boot. Spazio libero 12.932.152 KiB (12,33 GiB) > 10 GiB.
