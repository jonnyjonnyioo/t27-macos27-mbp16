# T27 — AGENT-AMD — DYLD PARSER VALIDATION

**Scope:** correggere l’interpretazione di `seg_info_offset`, `page_count`, `page_start`, `next` e `segment_offset`; ricostruire X4000 e X4000HWLibs dal SystemKC 25G342; verificare l’aritmetica e la coerenza con i segmenti Mach-O.

**Modalità:** sola lettura; parsing `LC_DYLD_CHAINED_FIXUPS` e `LC_SEGMENT_64`; nessuna modifica, build o boot.

**Esito:** il parser precedente leggeva `page_count` all’inizio di `starts_in_segment`, saltando l’header di 22 byte; usava `page_size=0x4000` invece di `0x1000`; decodificava `next` a 11 bit invece di 12; usava `segment.fileoff` invece di `entry + segment_offset`. Corretti questi quattro errori, i dati sono coerenti: **X4000 59 catene / 1.993 puntatori / 0 auth / 0 cacheLevel 2**; **X4000HWLibs 163 catene / 1.161 puntatori / 18 auth / 3 cacheLevel 2**. I **118** sono **ritirati**. **0/12** target raw coincide. T27 resta **OPEN**.

---

## 1. Errori corretti

| # | Errore | Correzione |
|---:|---|---|
| 1 | `page_count` letto a `seg_info+0` | `size:4, page_size:2, pointer_format:2, segment_offset:8, max_valid_pointer:4, page_count:2` |
| 2 | `page_start` letto a `seg_info+2` | `page_start` a **`seg_info+22`** |
| 3 | `page_size` assunto `0x4000` | **`0x1000`** |
| 4 | `next` letto a 11 bit | **12 bit** (`bits 51..62`), stride **4** |
| 5 | slot calcolato da `segment.fileoff` | **`entry + segment_offset + page*page_size + start`** |
| 6 | `seg_info_offset=0` trattato come struttura | **0 = nessun fixup** |

**PROVEN:** `page_count` è a **+20** e `page_start[]` a **+22**; la struttura `dyld_chained_starts_in_segment` inizia con `size`.
**PROVEN:** `page_size=0x1000` e `pointer_format=11`.
**PROVEN:** `segment_offset` è relativo al provider, non assoluto.

---

## 2. Metadati corretti

| Provider | Segmento | `size` | `page_size` | `page_count` | Pagine usate | `segment_offset` | Puntatori |
|---|---|---:|---:|---:|---:|---:|---:|
| X4000 | `__DATA` | 140 | `0x1000` | **58** | **54** | `0x3F7000` | 1.993* |
| X4000 | `__DATA_CONST` | 34 | `0x1000` | **5** | **5** | `0x431000` | * |
| X4000HWLibs | `__DATA` | 5664 | `0x1000` | **2.820** | **162** | `0x29D000` | 1.161* |
| X4000HWLibs | `__DATA_CONST` | 26 | `0x1000` | **1** | **1** | `0xDA1000` | * |

\* totale per provider, entrambi i segmenti.

**PROVEN:** X4000 ha **59** catene (54+5) e **1.993** puntatori.
**PROVEN:** X4000HWLibs ha **163** catene (162+1) e **1.161** puntatori.
**PROVEN:** i `page_count` coincidono con `vmsize/page_size`: X4000 `__DATA` 58, X4000HWLibs `__DATA` 2.820.
**PROVEN:** `entry + segment_offset` coincide con il `fileoff` del segmento.

---

## 3. Aritmetica

| Provider | `size` | `22 + 2*page_count` | Esito |
|---|---:|---:|---|
| X4000 `__DATA` | 140 | 138 | **+2 padding** |
| X4000 `__DATA_CONST` | 34 | 32 | **+2 padding** |
| X4000HWLibs `__DATA` | 5664 | 5662 | **+2 padding** |
| X4000HWLibs `__DATA_CONST` | 26 | 24 | **+2 padding** |

**PROVEN:** tutti i `size` sono coerenti con `page_count` e con 2 byte di padding.
**PROVEN:** nessuna struttura supera i limiti del `datasize` 226/5742.

---

## 4. Catene e auth

| Provider | Catene | Puntatori | `isAuth=1` | `cacheLevel=2` | Target `cacheLevel=2` |
|---|---:|---:|---:|---:|---|
| X4000 | **59** | **1.993** | **0** | **0** | — |
| X4000HWLibs | **163** | **1.161** | **18** | **3** | `0x18C0074D`, `0x18C00EFC`, `0x18C00002` |

**PROVEN:** X4000 non ha auth.
**PROVEN:** X4000HWLibs ha **18 auth** e **3 cacheLevel 2**.
**PROVEN:** i 3 target sono diversi dai 12 raw.
**PROVEN:** **0/12** target raw coincide con un auth slot.

---

## 5. I 3 `cacheLevel=2` reali

| Sorgente | Raw | Target | Segmento | Pagina | Start |
|---:|---|---|---|---:|---:|
| `0xA99B60` | `0x8000000698C0074D` | `0x18C0074D` | `__DATA` | 277 | `0xB20` |
| `0xDB9980` | `0x8000200698C00EFC` | `0x18C00EFC` | `__DATA` | 1077 | `0x940` |
| `0xF80198` | `0x8000200598C00002` | `0x18C00002` | `__DATA` | 1532 | `0x18` |

**PROVEN:** sono 3 slot distinti, tutti in X4000HWLibs `__DATA`.
**UNPROVEN:** struttura proprietaria, xref, raggiungibilità e validità dei target.

---

## 6. Confronto con il 118

| Gruppo | Quantità | Stato |
|---|---:|---|
| 118 precedenti | 118 | **RITIRATI** |
| X4000 cacheLevel 2 corretti | **0** | **PROVEN** |
| X4000HWLibs cacheLevel 2 corretti | **3** | **PROVEN** |
| 12 raw | 12 | **separati** |
| Match 12 raw | **0** | **PROVEN** |

**PROVEN:** il 118 non è più usato.
**PROVEN:** il totale corretto è **3**, non 118.
**PROVEN:** i 12 raw non sono questi 3.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Errore `page_count`? | **SÌ — header 22 B** |
| Errore `page_size`? | **SÌ — 0x1000** |
| Errore `next`? | **SÌ — 12 bit** |
| Errore `segment_offset`? | **SÌ — relativo all’entry** |
| X4000 catene/puntatori? | **59 / 1.993** |
| X4000HWLibs catene/puntatori? | **163 / 1.161** |
| X4000 auth / cache2? | **0 / 0** |
| X4000HWLibs auth / cache2? | **18 / 3** |
| 12 raw coincidono? | **NO — 0/12** |
| 118 valido? | **NO — ritirato** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il parser è corretto; i conteggi validi sono **X4000 59/1.993/0/0** e **X4000HWLibs 163/1.161/18/3**. I **118** erano un artefatto e sono **ritirati**. I 12 raw restano separati e **0/12** coincide con gli slot reali. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
