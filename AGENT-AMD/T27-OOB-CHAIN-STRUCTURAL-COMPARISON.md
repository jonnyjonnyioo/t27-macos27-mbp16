# T27 — AGENT-AMD — OOB CHAIN STRUCTURAL COMPARISON

**Scope:** determinare se le due anomalie OOB derivino da un’errata interpretazione di `next`, da un attraversamento di pagina o da differenze strutturali tra provider; ricostruire tutti i puntatori delle pagine 3475 di X5400HWLibs e 33 di AMDSupport; confrontare SystemKC 25G342 con il donor T6.

**Modalità:** sola lettura; parsing `LC_FILESET_ENTRY`, `LC_DYLD_CHAINED_FIXUPS`, `starts_in_image`, `dyld_chained_starts_in_segment`, catene stride 1; nessuna patch, build o boot.

**Esito:** le due catene hanno **struttura identica** nel target e in T6: **188** e **432** slot, stessi offset, stessi `next`, stesso `page_start`. Cambiano solo la base pagina e i target, spostati di **0xC000**. L’OOB è quindi **strutturale e sistematico**, non un errore di stride o di larghezza di `next`. **Correzione:** AMDSupport ha **2 byte** residui, non 6. T27 resta **OPEN**.

---

## 1. Metadati e basi pagina

| Provider | KC | Entry | Page | Page base | Page end | `page_start` | `size` | `page_count` | `22+2*pc` | Pad |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| **X5400HWLibs** | 25G342 | `0x8A90000` | **3475** | `0x9C78000` | `0x9C79000` | **0x698** | **10.764** | **5.370** | **10.762** | **+2** |
| X5400HWLibs | T6 | `0x8A84000` | **3475** | `0x9C6C000` | `0x9C6D000` | **0x698** | **10.764** | **5.370** | **10.762** | **+2** |
| **AMDSupport** | 25G342 | `0x13B2C000` | **33** | `0x13C13000` | `0x13C14000` | **0x0** | **98** | **37** | **96** | **+2** |
| AMDSupport | T6 | `0x13B20000` | **33** | `0x13C07000` | `0x13C08000` | **0x0** | **98** | **37** | **96** | **+2** |

**PROVEN:** `size` è coerente con `page_count` in tutti e quattro i casi.
**PROVEN:** il padding è **+2 byte** in tutti.
**PROVEN:** T6 sposta la pagina di **0xC000** in entrambi i provider.

---

## 2. Catene complete

| Provider | KC | Slot | Primo offset | Ultimo offset | Ultimo `next` | Successore | Residuo | Necessario | OOB |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| **X5400HWLibs** | 25G342 | **188** | `0x698` | `0xFF0` | **10** | `0xFFA` | **6** | **8** | **SÌ** |
| X5400HWLibs | T6 | **188** | `0x698` | `0xFF0` | **10** | `0xFFA` | **6** | **8** | **SÌ** |
| **AMDSupport** | 25G342 | **432** | `0x0` | `0xFF4` | **10** | `0xFFE` | **2** | **8** | **SÌ** |
| AMDSupport | T6 | **432** | `0x0` | `0xFF4` | **10** | `0xFFE` | **2** | **8** | **SÌ** |

**PROVEN:** le lunghezze sono identiche tra target e T6.
**PROVEN:** gli offset dell’ultimo slot sono identici.
**PROVEN:** AMDSupport ha **2 byte** residui, non 6.
**PROVEN:** in tutti i casi servono **8 byte** per il successore.

---

## 3. Digest del walk completo

| Provider | KC | Slot | SHA-256 offset+raw | SHA-256 offset+next |
|---|---|---:|---|---|
| X5400HWLibs | 25G342 | **188** | `9992FB78C97B047403E1C368D49E6AF4226A6E06B2DAFB03D6B5A342BE852D90` | `AE88088AEC3194183C90E4B91EFAE66DEC5E451C6CBCB4B483F5151C3077C94A` |
| X5400HWLibs | T6 | **188** | `6B6D8706057A340261B30F9B2A2D59EB40E30C0B03BB67C15B0DB4AF666DC220` | `AE88088AEC3194183C90E4B91EFAE66DEC5E451C6CBCB4B483F5151C3077C94A` |
| AMDSupport | 25G342 | **432** | `B00BAF7D6265A53443CB5760AEFF8B79C550FB600E8B47E4B514D8B1ED713659` | `E83BBD8EEFA7D204159E7FA32F3F07D1A5371413D1BD3C7DD82273434290C302` |
| AMDSupport | T6 | **432** | `3C44ADC25952D8E22777A38505A7BCC32AF81B476000E2C6B424C34ABE1DA87D` | `E83BBD8EEFA7D204159E7FA32F3F07D1A5371413D1BD3C7DD82273434290C302` |

**PROVEN:** i digest `offset+next` sono **identici** target/T6 per entrambi i provider.
**PROVEN:** i digest `offset+raw` differiscono.
**PROVEN:** **0 mismatch** di offset o `next` nel confronto a coppie.

---

## 4. Prime transizioni

| Provider | Prime transizioni | Stride |
|---|---|---:|
| X5400HWLibs | `0x698 → 0x6A0` (8), `→ 0x700` (96), `→ 0x720` (32) | **1 byte** |
| AMDSupport | `0x0 → 0x8` (8), `→ 0x10` (8), `→ 0x18` (8) | **1 byte** |

**PROVEN:** le distanze sono in byte.
**PROVEN:** uno stride 4 produrrebbe offset diversi.
**PROVEN:** `next` è un offset in byte, non un numero di slot.

---

## 5. Code delle catene

| Provider | KC | Ultimi raw |
|---|---|---|
| X5400HWLibs | 25G342 | `0x050000048CA6965`, `0x050000048CA6426` ×5 |
| X5400HWLibs | T6 | `0x050000048C9A965`, `0x050000048C9A426` ×5 |
| AMDSupport | 25G342 | `0x050000053BB9740` ×5, `0x050000053BB99E0` |
| AMDSupport | T6 | `0x050000053BAD740` ×5, `0x050000053BAD9E0` |

**PROVEN:** la coda X5400 è **5 raw identici**.
**PROVEN:** la coda AMDSupport è **5 raw identici + 1 diverso**.
**PROVEN:** la differenza numerica target/T6 è **0xC000**, coerente con lo shift di pagina.

---

## 6. Interpretazione di `next`

| Ipotesi | Evidenza | Grado |
|---|---|---|
| Stride errato | **offset+next identici target/T6** | **ESCLUSA** |
| `next` a 11 bit | valori **< 2048** su queste pagine | **NON DISTINGUIBILE** |
| `next` in slot | transizioni 8/96/32 | **ESCLUSA** |
| `next=10` terminatore | ultimo slot in tutti i casi | **POSSIBILE** |
| `next=10` distanza reale | successore a 6/2 byte dal bordo | **POSSIBILE** |
| Errore di pagina | `page_start` e metadati coerenti | **ESCLUSA** |

**PROVEN:** non è un errore di stride.
**PROVEN:** non è un errore di `page_start` o `page_count`.
**UNPROVEN:** se `next=10` sia un terminatore o una distanza.

---

## 7. Ipotesi sulla causa

| # | Ipotesi | Stato |
|---:|---|---|
| H1 | `next=10` è un terminatore; il loader non lo segue | **UNPROVEN** |
| H2 | `next=10` è una distanza; il loader controlla il bordo e si ferma | **UNPROVEN** |
| H3 | il linker ha serializzato male l’ultimo `next` | **UNPROVEN** |
| H4 | l’ultimo slot è un sentinel e il successore non è mai letto | **UNPROVEN** |
| H5 | il loader rifiuta l’intera catena | **UNPROVEN** |

**PROVEN:** tutte le ipotesi sono compatibili con i dati statici.
**UNPROVEN:** la scelta effettiva del loader.

---

## 8. Evidenza BootKC

| Elemento | Esito |
|---|---|
| `fixup_value` | **assente** |
| controllo `next+8 <= page_end` | **non trovato** |
| loader chained | **non identificato** |
| `readPrelinkedExtensions` | **non valida i limiti di pagina** |
| `addKextsFromKextCollection` | **33 indirette vtable, nessuna PE** |

**PROVEN:** il BootKC non fornisce un controllo statico del bordo pagina.
**UNPROVEN:** il comportamento runtime.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Stride corretto? | **SÌ — 1 byte** |
| `next` corretto? | **SÌ — offset byte** |
| Target e T6 hanno la stessa struttura? | **SÌ — 0 mismatch** |
| Cambia solo la base? | **SÌ — +0xC000** |
| OOB sistematico? | **SÌ — 2/2 provider, 2/2 KC** |
| Causa prima? | **UNPROVEN** |
| Impatto runtime? | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le due OOB **non derivano da un errore di interpretazione** di stride o `next`: target e T6 hanno **offset e `next` identici**, **188/432 slot**, e differiscono solo per la base pagina e i target, spostati di **0xC000**. L’anomalia è **strutturale e sistematica**: l’ultimo slot ha `next=10` e lascia **6 byte** in X5400 e **2 byte** in AMDSupport, meno degli 8 necessari. La causa prima e il comportamento del loader restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna patch/build/boot.
