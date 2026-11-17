# T27 — AGENT-AMD — X6100 CHAINED-FIXUP VALIDATION

**Scope:** validare la tabella `LC_DYLD_CHAINED_FIXUPS` dell’eseguibile `AMDRadeonX6100HWLibs` embedded nella `SystemKernelExtensions.kc` 25G342: page-start, catene, puntatori, `cacheLevel`, `isAuth`, target e confronto con `e521`.  
**Modalità:** sola lettura; parsing Mach-O e chained-fixups in memoria; SHA-256; nessuna estrazione, copia, build, boot, `kmutil create`, `kextload`, modifica EFI/NVRAM/T2/SIP/AMFI.  
**Esito:** **154 catene / 8.544 puntatori**, **0 import**, **tutti `isAuth=0`**. `__DATA` ha **3.063 pagine / 153 page-start / 153 catene / 8.538 puntatori**; `__DATA_CONST` ha **1 pagina / 1 page-start / 1 catena / 6 puntatori**. Il traversal completo non trova multi-start, cicli, OOB o target zero. **8.544/8.544 valori encoded coincidono con `e521`** usando la base corretta di `__DATA_CONST`; i 6 apparenti disallineamenti precedenti erano un errore di mapping di **4.096 B**, non differenze reali. I target `cacheLevel=1` cadono nel range della KC; i target `cacheLevel=0` cadono sotto la KC e la base assoluta non è nella tabella. **T27 resta OPEN.**

---

## 1. Coordinate e identità

| Campo | Valore | Evidenza |
|---|---|---|
| SystemKC | `HAO-PROJECT/Sessions/<SESSION>/work/root-full/System/Library/KernelCollections/SystemKernelExtensions.kc` | percorso |
| SHA-256 SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` | `shasum -a 256` |
| Build SystemKC | **25G342 / 26.7.3** | `__PRELINK_INFO` / inventory |
| Size SystemKC | **369.213.440 B** | `wc -c` |
| UUID SystemKC | `93336203-88E3-AA73-08FC-7C9F4D7B21E0` | `LC_UUID` |
| Embedded `fileoff` X6100 | **232.185.856** | `LC_FILESET_ENTRY` |
| Architettura | **x86_64** | Mach-O |
| Immagine codice | **`e521…`** | `X6100-EMBEDDED-IDENTITY.md` |
| Percorso `e521` | `HAO-PROJECT/Sessions/<SESSION>/work/systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` | percorso |
| SHA-256 `e521` completo | **`e521d3cce8f9bb027642897fed8754ff4d9ef66dd08a8d13ab318e0c2db01bb5`** | `shasum -a 256` |
| Size `e521` | **16.985.840 B** | `wc -c` |
| SHA-256 `e521 __text` | `19dcb85d59d7a1f63b36a6a9218392b9bd0ee347432199b530607965f32a7126` | `X6100-EMBEDDED-IDENTITY.md` |
| Embedded `__TEXT,__text` | offset **232.188.256**, size **2.362.326** | parsing Mach-O |
| `LC_DYLD_CHAINED_FIXUPS` | `dataoff` **369.155.882**, `datasize` **6.228** | parsing load command |

**Fonte:** SystemKC e `e521` sono i file locali sopra; la build 25G342 è quella dell’inventario; l’architettura è letta dall’header. **Nessun** dato proviene dal target 26B131, che non è disponibile.

---

## 2. Header della tabella

| Campo | Valore |
|---|---:|
| `fixups_version` | 0 |
| `starts_offset` | 28 |
| `imports_offset` | 6.228 |
| `symbols_offset` | 6.228 |
| `imports_count` | **0** |
| `imports_format` | 1 |
| `symbols_format` | 0 |
| `seg_count` | 4 |

**MISURATO:** `imports_count=0` e `imports_offset == symbols_offset == datasize`: non ci sono bind/import; la tabella contiene solo rebasing. `seg_count=4` copre `__TEXT`, `__DATA`, `__DATA_CONST`, `__LINKEDIT`.

---

## 3. Page-start e catene

### 3.1 Conteggi per segmento

| Indice | Segmento | `page_count` | Start non-`NONE` | Catene | Puntatori | `pointer_format` |
|---:|---|---:|---:|---:|---:|---:|
| 0 | `__TEXT` | 0 | 0 | 0 | 0 | — |
| 1 | `__DATA` | **3.063** | **153** | **153** | **8.538** | **11** |
| 2 | `__DATA_CONST` | **1** | **1** | **1** | **6** | **11** |
| 3 | `__LINKEDIT` | 0 | 0 | 0 | 0 | — |

**MISURATO:** le pagine `__DATA` coperte dalla tabella sono **3.063**; solo **153** hanno uno start valido. `__DATA_CONST` ha **una** pagina e **un** page-start. Totale **154 catene / 8.544 puntatori**.

`__DATA`:
- primo page-start valido: **page 0, offset 0**;
- ultimo page-start valido: **page 3061, offset 608**;
- page 3062 non ha start;
- **153** page-start, tutti singoli (`multi=0`).

`__DATA_CONST`:
- page-start: **page 0, offset 16**;
- **1** page-start singolo (`multi=0`);
- catena di **6** puntatori.

### 3.2 Lunghezze delle catene

| Segmento | Catene | Lunghezza min | Lunghezza max |
|---|---:|---:|---:|
| `__DATA` | 153 | **1** | **503** |
| `__DATA_CONST` | 1 | **6** | **6** |
| **Totale** | **154** | **1** | **503** |

Distribuzione `__DATA` (lunghezza: catene): `1:64, 2:35, 3:2, 4:5, 7:1, 28:2, 40:1, 43:1, 85:8, 86:5, 108:1, 110:1, 129:1, 132:1, 159:1, 178:1, 202:1, 203:1, 204:1, 205:2, 206:1, 221:1, 247:1, 248:1, 254:4, 255:2, 257:1, 279:1, 293:1, 316:1, 366:1, 383:1, 442:1, 503:1`.

**MISURATO:** nessuna catena attraversa il confine di pagina; nessun `next` porta fuori dalla pagina; nessun ciclo; nessun doppio start. La catena `__DATA_CONST` percorre gli offset **16, 48, 16, 48, 16, 0** (`next`) nella pagina, quindi termina a **+160** e resta nella sezione `__kalloc_type` di **192 B**.

---

## 4. Puntatori, `isAuth` e target

### 4.1 Conteggi globali

| Proprietà | Valore |
|---|---:|
| Puntatori totali | **8.544** |
| `isAuth=1` | **0** |
| `isAuth=0` | **8.544** |
| Catene totali | **154** |
| Import / bind | **0** |
| Target zero | **0** |

**MISURATO:** tutti i puntatori sono rebase non autenticati; non ci sono bind. Non ci sono target zero.

### 4.2 `cacheLevel`

| `cacheLevel` | Puntatori | Target minimo | Target massimo | Target zero |
|---:|---:|---:|---:|---:|
| **1** | **7.658** | **232.188.320** | **248.584.800** | 0 |
| **0** | **886** | **1.758.400** | **43.261.008** | 0 |
| **Totale** | **8.544** | — | — | **0** |

**Target `cacheLevel=1`:** **7.658** valori, tutti nel range **232.188.320–248.584.800**. Questo range cade dentro i segmenti mappati della KC: `__TEXT` inizia a **232.185.856**, `__DATA` termina a **248.586.240**, e il massimo osservato (**248.584.800**) è **1.440 B sotto** la fine di `__DATA`. Non è una prova di indirizzo assoluto: `cacheLevel` seleziona una base, e la base non è serializzata nella tabella.

**Target `cacheLevel=0`:** **886** valori, range **1.758.400–43.261.008**, interamente **sotto** la KC (`__TEXT` parte a 232.185.856). Sono coerenti con un rebase verso la base kernel/cache, ma la base e la loro risoluzione assoluta restano **UNPROVEN**.

**Limite strutturale:** `dyld_chained_fixups_header` non contiene un array `basePointers`; le basi sono fornite dal loader/kernel. La tabella permette di misurare `target`, `cacheLevel`, `next`, `diversity`, `addrDiv`, `key` e `isAuth`, non di ricostruire da sola l’indirizzo VM finale. Per questo il report non dichiara “tutti i target risolti”.

### 4.3 Formato

`pointer_format=11` è **`DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`**, non `DYLD_CHAINED_PTR_64_KERNEL_CACHE` (che è **8**). Fonte documentale: Apple `mach-o/fixup-chains.h` (`https://github.com/apple-oss-distributions/xnu/blob/main/EXTERNAL_HEADERS/mach-o/fixup-chains.h`). La premessa del prompt 27 che indicava 11 come formato “64” è errata; la struttura usata è quella **x86_64 kernel cache** con `target:30`, `cacheLevel:2`, `diversity:16`, `addrDiv:1`, `key:2`, `next:12`, `isAuth:1`, stride 1.

---

## 5. Confronto encoded KC vs `e521`

### 5.1 Mapping corretto

| Segmento | Base KC | Base `e521` | Nota |
|---|---:|---:|---|
| `__DATA` | 236.044.288 | 3.858.432 | stesso offset relativo |
| `__DATA_CONST` | **248.590.336** | **16.400.384** | la KC ha **4.096 B di gap** prima del segmento |

La KC ha:
- `__DATA_CONST` `segment_offset` = **16.404.480** (relativo alla base KC);
- `__DATA_CONST` fileoff = **248.590.336**;
- `e521` `__DATA_CONST` fileoff = **16.400.384**;
- differenza dei fileoff = **232.189.952** (4.096 B in più rispetto alle altre sezioni).

Usare `base KC + segment_offset` per indicizzare `e521` porta a **16.404.496**, cioè **4.096 B oltre** l’inizio di `__DATA_CONST` di `e521`. Questo mapping errato produceva **6 falsi diff**. La base corretta per il confronto è la **sezione `__DATA_CONST` di `e521` a 16.400.384**.

### 5.2 Risultato

| Confronto | Valori | Uguali | Differenze |
|---|---:|---:|---:|
| Tutti i puntatori encoded vs `e521` | **8.544** | **8.544** | **0** |
| `__DATA` | 8.538 | 8.538 | 0 |
| `__DATA_CONST` | 6 | 6 | 0 |

**PROVEN:** i **8.544/8.544** valori encoded della KC coincidono byte-per-byte con i corrispondenti valori di `e521`; le 6 posizioni `__DATA_CONST` (offset di sezione **16, 32, 80, 96, 144, 160**) sono identiche. La sezione `__kalloc_type` (192 B) è identica; non ci sono differenze reali nei puntatori.

**Correzione registrata:** il precedente “6 differenze” era un errore di base (`segment_offset` KC applicato a `e521` senza sottrarre il gap di 4.096 B). Non va riportato come differenza di contenuto.

---

## 6. `dyld_info`

```text
$ dyld_info -fixups SystemKernelExtensions.kc
Assertion failed: (_usedCount < _allocCount), function push_back, file Array.h, line 68.
```

**MISURATO:** `dyld_info` termina con asserzione su questa KC; non è stato usato come fonte. Tutti i conteggi sopra vengono dal parser diretto della tabella e dal traversal delle catene.

---

## 7. Interpretazione e limiti

### PROVEN

- La tabella contiene **154 catene / 8.544 puntatori**.
- `__DATA` ha **3.063 pagine / 153 page-start / 153 catene / 8.538 puntatori**.
- `__DATA_CONST` ha **1 pagina / 1 page-start / 1 catena / 6 puntatori**.
- `imports_count=0`; nessun bind/import.
- Tutti gli **8.544** puntatori hanno `isAuth=0`.
- Nessun target zero, nessun multi-start, nessun OOB, nessun ciclo.
- Lunghezza catene **1–503**; `__DATA_CONST` lunghezza **6**.
- `cacheLevel=1`: **7.658** target in **232.188.320–248.584.800**.
- `cacheLevel=0`: **886** target in **1.758.400–43.261.008**.
- **8.544/8.544** valori encoded coincidono con `e521` con il mapping corretto.
- `pointer_format=11` è **X86_64_KERNEL_CACHE**.

### INFERRED

- La KC ha ricollocato l’immagine `e521` in una cache kernel con rebase a due livelli.
- I target `cacheLevel=1` corrispondono numericamente a locazioni della KC; i target `cacheLevel=0` corrispondono a una base kernel/cache più bassa.
- La catena `__DATA_CONST` ricade nella sezione `__kalloc_type` e non indica overflow.

### UNPROVEN

- Base assoluta `basePointers[0]`/`[1]` e indirizzo VM finale di ogni target: non serializzati nella tabella.
- Correttezza semantica dei target rispetto alla mappa VM del kernel 26B131.
- Caricamento della KC, ABI e runtime su 26B131.
- Firma, entitlements, SIP/AMFI dell’immagine embedded.
- Identità del file completo embedded (linkedit condivisa, nessuna slice contigua).

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Quante catene? | **154** |
| Quanti puntatori? | **8.544** |
| Dove sono? | **`__DATA` 153 catene/8.538 + `__DATA_CONST` 1 catena/6** |
| `__DATA` page_count? | **3.063**, con **153** start validi |
| `__DATA_CONST` page_count? | **1**, con **1** start valido |
| Import? | **0** |
| `isAuth`? | **0 su 8.544** |
| Target zero/OOB/multi-start? | **0 / 0 / 0** |
| Encoded = `e521`? | **8.544/8.544, 0 differenze reali** |
| Target assoluti risolti? | **NO: basi non serializzate; `UNPROVEN`** |
| Runtime 26B131? | **BLOCKED** |
| T27 è GO? | **NO — OPEN** |

La validazione strutturale della tabella è completa e coerente: **154 catene, 8.544 puntatori, 0 import, 0 autenticati, 0 anomalie**, con identità byte-per-byte rispetto a `e521`. Questo **non** prova la risoluzione assoluta dei target, l’ABI o il boot su 26B131. Le percentuali ufficiali restano **94% engineering / 32% first boot / 8% desktop**.

**STOP rispettato:** sola lettura del target e dei file; nessuna estrazione, copia, build, boot o modifica di EFI/NVRAM/T2/SIP/AMFI. Il report è l’unico file scritto. Spazio libero **12.909.664 KiB** (circa **12,31 GiB**) > **10 GiB**.
