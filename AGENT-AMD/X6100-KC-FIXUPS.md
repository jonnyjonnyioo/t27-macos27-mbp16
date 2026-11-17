# T27 — AGENT-AMD — X6100 KC FIXUPS

**Scope:** verificare come la SystemKC 25G342 trasformi `X6100HWLibs` `e521…` nell’immagine Mach-O embedded: `LC_DYLD_CHAINED_FIXUPS`, rebasing, indirizzi VM, fileoff, sezioni e le differenze S_ZEROFILL.  
**Modalità:** sola lettura; parsing Mach-O in memoria, `otool`-equivalent, SHA-256. Nessuna estrazione, copia, scrittura, build o boot.  
**Esito:** la KC **aggiunge** `LC_DYLD_CHAINED_FIXUPS` rispetto a `e521`; la tabella contiene **0 import** e **154 catene / 8.544 puntatori**: **153 catene (8.538 puntatori) in `__DATA`** e **1 catena (6 puntatori) in `__DATA_CONST`**. Gli indirizzi VM di `e521` coincidono con quelli della KC; le 9 sezioni file-backed sono byte-identiche. Otto sezioni hanno fileoff KC = fileoff `e521` + **232.185.856**; `__DATA_CONST,__kalloc_type` ha **+232.189.952** per un gap di 4.096 B nella KC. `__common`/`__bss` sono **S_ZEROFILL con offset 0**: i 2.016 B non sono una differenza reale. `dyld_info -fixups` termina con un’asserzione sulla KC.

---

## 1. Layout dei tre oggetti

| Segmento | KC vmaddr | KC fileoff | KC size | `e521` vmaddr | `e521` fileoff | `e521` size | `00b6` vmaddr | `00b6` fileoff |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `__TEXT` | 232.185.856 | 232.185.856 | 3.858.432 | **232.185.856** | 0 | 3.858.432 | 0 | 0 |
| `__DATA` | 236.044.288 | 236.044.288 | 12.541.952 | **236.044.288** | 3.858.432 | 12.541.952 | 3.858.432 | 3.858.432 |
| `__DATA_CONST` | 248.590.336 | 248.590.336 | 4.096 | **248.590.336** | 16.400.384 | 4.096 | 16.404.480 | 16.400.384 |
| `__LINKEDIT` | 356.106.240 | 356.106.240 | **12.953.207** | **356.106.240** | 16.404.480 | 581.360 | 16.408.576 | 16.404.480 |

**PROVEN:** `e521` e KC hanno gli **stessi vmaddr** per tutti e quattro i segmenti. `00b6` è linkato a base 0. La KC usa fileoff assoluti; `e521` usa fileoff relativi.

La `__LINKEDIT` della KC è **12.953.207 B** contro 581.360 B di `e521`: è una linkedit condivisa/estesa della collezione, non una copia della linkedit standalone. Per questo il file `e521` non è una slice contigua della KC.

---

## 2. Traslazione delle sezioni

Il contenuto delle 9 sezioni file-backed è byte-identico a `e521`. **Otto** sezioni hanno fileoff KC = fileoff `e521` + **232.185.856**; `__DATA_CONST,__kalloc_type` è traslata di **+232.189.952** perché la KC inserisce **4.096 B** prima del segmento `__DATA_CONST`.

| Sezione | `e521` fileoff | KC fileoff | Delta | Contenuto |
|---|---:|---:|---:|---|
| `__TEXT,__text` | 2.400 | 232.188.256 | +232.185.856 | **EXACT** |
| `__TEXT,__cstring` | 2.364.726 | 234.550.582 | +232.185.856 | EXACT |
| `__TEXT,__const` | 2.873.152 | 235.059.008 | +232.185.856 | EXACT |
| `__DATA,__got` | 3.858.432 | 236.044.288 | +232.185.856 | EXACT |
| `__DATA,__mod_init_func` | 3.858.664 | 236.044.520 | +232.185.856 | EXACT |
| `__DATA,__mod_term_func` | 3.858.688 | 236.044.544 | +232.185.856 | EXACT |
| `__DATA,__const` | 3.858.720 | 236.044.576 | +232.185.856 | EXACT |
| `__DATA,__data` | 3.924.624 | 236.110.480 | +232.185.856 | EXACT |
| `__DATA_CONST,__kalloc_type` | 16.400.384 | 248.590.336 | **+232.189.952** | EXACT |

**PROVEN:** tutte le sezioni file-backed sono identiche; la KC è una **serializzazione con fileoff assoluti** dell’immagine `e521`. La traslazione non è uniforme per `__DATA_CONST`: la KC ha **4.096 B di gap** prima di quel segmento, mentre il contenuto della sezione resta identico.

---

## 3. `LC_DYLD_CHAINED_FIXUPS`

La KC embedded ha il comando **`0x80000034` (LC_DYLD_CHAINED_FIXUPS)**, assente in `e521` e `00b6`.

| Campo | Valore |
|---|---|
| `dataoff` | **369.155.882** |
| `datasize` | **6.228 B** |
| `fixups_version` | 0 |
| `starts_offset` | 28 |
| `imports_offset` | 6.228 |
| `symbols_offset` | 6.228 |
| `imports_count` | **0** |
| `imports_format` | 1 |
| `symbols_format` | 0 |
| `seg_count` | 4 |

### 3.1 Start per segmento

| Indice | Segmento | `page_count` | Start non-`NONE` | Catene | Puntatori | `pointer_format` |
|---:|---|---:|---:|---:|---:|---:|
| 0 | `__TEXT` | 0 | 0 | 0 | 0 | — |
| 1 | `__DATA` | **3.063** | **153** | **153** | **8.538** | 11 |
| 2 | `__DATA_CONST` | **1** | **1** | **1** | **6** | 11 |
| 3 | `__LINKEDIT` | 0 | 0 | 0 | 0 | — |

**MISURATO:** i fixup sono in **entrambi** `__DATA` e `__DATA_CONST`. `__DATA` ha **3.063 pagine**, **153 page-start validi** e **153 catene**; `__DATA_CONST` ha **1 pagina**, **1 page-start** e **1 catena di 6 puntatori**. Totale **154 catene / 8.544 puntatori**. `imports_count=0`: **nessun bind/import**, solo rebasing.

`__DATA_CONST` ha 4.096 B; la sezione `__kalloc_type` è 192 B e contiene i 6 puntatori della catena. La catena parte da **offset 16** della pagina; i valori `next` sono **16, 48, 16, 48, 16, 0**, quindi le posizioni sono **16, 32, 80, 96, 144, 160**, tutte dentro la sezione. La tabella è stata decodificata catena per catena; dettagli in `X6100-FIXUP-VALIDATION.md`.

### 3.2 `dyld_info`

```text
$ dyld_info -fixups SystemKernelExtensions.kc
Assertion failed: (_usedCount < _allocCount), function push_back, file Array.h, line 68.
```

`dyld_info` **non gestisce** questa KC e termina con asserzione. Nessun output di fixup è stato usato; i dati sopra vengono dal parsing diretto della tabella.

---

## 4. Perché 2.016 B non sono una differenza

`__common` e `__bss` hanno:

```text
flags = 0x1   (S_ZEROFILL)
offset = 0
```

Non hanno byte di file propri: il loro contenuto runtime è zero-fill. Il confronto precedente leggeva l’offset 0 (l’inizio del file), non la sezione, e produceva:

- 697 + 1.319 = **2.016 B** apparenti per `e521`;
- 690 + 1.309 = **1.999 B** apparenti per `00b6`.

**Correzione:** questi byte sono **N/A**, non differenze. Le sezioni file-backed sono **9/9 identiche a `e521`** e **0** hanno differenze reali. Per `00b6`, le differenze reali sono **56.727 B** in 7 sezioni file-backed; i 1.999 B delle S_ZEROFILL sono esclusi.

---

## 5. Interpretazione

### PROVEN

- La KC ha `LC_DYLD_CHAINED_FIXUPS`; `e521` e `00b6` non lo hanno.
- La tabella contiene **0 import**; i fixup sono in **`__DATA` (153 catene / 8.538 puntatori)** e **`__DATA_CONST` (1 catena / 6 puntatori)**: **154 catene / 8.544 puntatori**.
- `e521` e KC hanno gli stessi vmaddr per i quattro segmenti.
- Le 9 sezioni file-backed sono byte-identiche; 8 hanno fileoff KC = fileoff `e521` + 232.185.856, `__DATA_CONST` ha +232.189.952 per il gap di 4.096 B.
- `__common`/`__bss` sono S_ZEROFILL, offset 0; i 2.016 B sono N/A.
- `00b6` ha `LC_CODE_SIGNATURE`; la KC no; `00b6` è linkato a base 0.
- `dyld_info -fixups` va in asserzione sulla KC.

### INFERRED

- La KC serializza l’immagine **`e521` rebased** con fileoff assoluti e chained fixup.
- I fixup in `__DATA` e `__DATA_CONST` servono a ricollocare i puntatori dell’immagine prelinkata; la distribuzione 153/1 è misurata, non dedotta.
- `00b6` è la variante standalone firmata, non l’immagine della collezione.

### UNPROVEN

- Hash del file completo embedded: linkedit condivisa, nessuna slice contigua.
- Validità semantica di ogni catena di fixup e comportamento a runtime.
- ABI e caricamento su 26B131.
- Firma/entitlements/SIP/AMFI dell’immagine embedded.

---

## 6. Conclusione

| Domanda | Risposta |
|---|---|
| La KC aggiunge chained fixups? | **SÌ, `LC_DYLD_CHAINED_FIXUPS`** |
| Quanti import? | **0** |
| Dove sono i fixup? | **`__DATA` 153 catene/8.538 puntatori + `__DATA_CONST` 1 catena/6 puntatori** |
| `e521` ha gli stessi vmaddr? | **SÌ, tutti e 4 i segmenti** |
| Le sezioni file-backed sono identiche? | **SÌ, 9/9** |
| I 2.016 B sono reali? | **NO: S_ZEROFILL, offset 0, N/A** |
| `00b6` è l’embedded? | **NO a livello di codice: 56.727 B reali di differenza** |
| File completo/firma/runtime? | **UNPROVEN** |
| T27 è GO? | **NO — OPEN** |

La trasformazione è coerente: **`e521` è l’immagine prelinkata con vmaddr della KC**; la collezione la serializza con fileoff assoluti, aggiunge una tabella chained-fixup senza import e usa una `__LINKEDIT` condivisa. Il codice è `e521`; l’identità del file completo e il runtime su 26B131 restano **UNPROVEN**.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, build o boot. Spazio libero **12.909.664 KiB** (circa **12,31 GiB**) > **10 GiB**.
