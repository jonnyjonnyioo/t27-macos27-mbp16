# T27 — AGENT-AMD — DYLD OOB FORENSICS

**Scope:** identificare i due terminatori OOB dell’audit formato 11; ricostruire provider, UUID, segmento, pagina, offset, raw e vicini; verificare la causa e l’impatto.

**Modalità:** sola lettura; parsing SystemKC 25G342. Nessuna correzione, modifica o boot.

**Esito:** i due OOB sono in **X5400HWLibs** e **AMDSupport**, entrambi in `__DATA`. In entrambi l’ultimo slot ha `next=10` e lascia **6 byte** alla fine della pagina, meno degli **8** necessari. **X6100, X4000 e X4000HWLibs non hanno OOB**. I due OOB non contengono auth né `cacheLevel=2`; impatto runtime **UNPROVEN**. T27 resta **OPEN**.

---

## 1. I due OOB

| # | Provider | UUID | Seg | `segment_offset` | Pagina | `page_count` | Start | Ultimo offset | `next` | `nxt` | Page end | Raw |
|---:|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | **X5400HWLibs** | `0BC3F48B-D341-3367-8DBB-B274E7E2DC0B` | `__DATA` | `0x455000` | **3475** | **5370** | `0x698` | `0x9C78FF0` | **10** | `0x9C78FFA` | `0x9C79000` | `0x050000048CA6426` |
| 2 | **AMDSupport** | `736ECBBA-C9C9-3AF7-BE6A-EB1944DB515B` | `__DATA` | `0xC6000` | **33** | **37** | `0x0` | `0x13C13FF4` | **10** | `0x13C13FFE` | `0x13C14000` | `0x050000053BB99E0` |

**PROVEN:** entrambi sono in `__DATA`.
**PROVEN:** entrambi hanno `next=10` sull’ultimo slot.
**PROVEN:** `nxt` è a **6 byte** dalla fine pagina; servono **8 byte** per il puntatore successivo.

---

## 2. Metadati

| Provider | `datasize` | `page_count` | `size` | `22+2*page_count` | Coerente? |
|---|---:|---:|---:|---:|---|
| X5400HWLibs | **10.842** | **5.370** | **10.764** | **10.762** | **SÌ (+2)** |
| AMDSupport | **178** | **37** | **98** | **96** | **SÌ (+2)** |

**PROVEN:** i metadati `page_count`/`size` sono coerenti.
**PROVEN:** l’OOB non nasce da un `page_count` errato.

---

## 3. Vicini di pagina

| Provider | Pagina | Start precedente | Start corrente | Start successivo |
|---|---:|---:|---:|---:|
| X5400HWLibs | 3475 | **0xFFFF** (nessuno) | **0x698** | **0x4** |
| AMDSupport | 33 | **0x0** | **0x0** | **0x8** |

**PROVEN:** la catena OOB è isolata tra due page-start validi.
**PROVEN:** il page-start precedente di X5400 è assente.
**UNPROVEN:** se la catena successiva prosegua correttamente.

---

## 4. Causa

| Elemento | Valore |
|---|---|
| Ultimo slot | **a 6 byte dal page end** |
| `next` | **10** |
| Spazio necessario | **8 byte** |
| Esito | **OOB** |
| Correzione applicata | **nessuna** |

**PROVEN:** il meccanismo è `next=10` su un ultimo slot troppo vicino al bordo.
**INFERRED:** terminatore malformato o catena che eccede la pagina.
**UNPROVEN:** la causa prima (linker, serializzazione o parser).

---

## 5. Confronto con gli altri provider

| Provider | OOB | Auth | CacheLevel 2 |
|---|---:|---:|---:|
| X6100HWLibs | **0** | 0 | 0 |
| X4000 | **0** | 0 | 0 |
| X4000HWLibs | **0** | 0 | 0 |
| X5400HWLibs | **1** | 0 | 0 |
| AMDSupport | **1** | 0 | 0 |

**PROVEN:** X6100, X4000 e X4000HWLibs non hanno OOB.
**PROVEN:** i due OOB sono localizzati a X5400HWLibs e AMDSupport.
**PROVEN:** non contengono auth o cacheLevel 2.

---

## 6. Impatto

| Metrica | Valore |
|---|---:|
| Catene totali | **3.828** |
| OOB | **2** |
| Percentuale | **0,052%** |
| Sovrapposizioni | **0** |
| Cicli | **0** |
| Auth nelle OOB | **0** |
| Impatto sui conteggi | **nessuno** |
| Impatto runtime | **UNPROVEN** |

**PROVEN:** i due OOB non alterano i conteggi di auth/cacheLevel 2.
**UNPROVEN:** se a runtime la catena venga rifiutata o troncata.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Provider OOB | **X5400HWLibs, AMDSupport** |
| Entrambi in `__DATA`? | **SÌ** |
| Causa meccanica | **`next=10`, 6 byte residui** |
| Metadati coerenti? | **SÌ** |
| X6100/X4000/X4000HWLibs OOB? | **NO** |
| Auth/cache2 negli OOB? | **0/0** |
| Correzione? | **NO** |
| Impatto runtime | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i due OOB sono in **X5400HWLibs** e **AMDSupport**, `__DATA`, con `next=10` a 6 byte dal bordo pagina. I metadati sono coerenti; **X6100/X4000/X4000HWLibs** non hanno OOB. Non contengono auth o cacheLevel 2 e non alterano i conteggi. La causa prima e l’impatto runtime restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna correzione/modifica/build/boot.
