# T27 — AGENT-AMD — OOB HYPOTHESES CLASSIFICATION

**Scope:** verificare staticamente H1–H5 sulle due OOB; chiarire la semantica di `next=10`; confrontare terminatori, metadati e transizioni con gli altri provider; cercare implementazioni locali equivalenti.

**Modalità:** sola lettura; scan globale dei 172 provider, parsing chained, confronto con sorgenti locali `hao-runtime/src/macho.c` e Stela `chained_fixups.rs`; nessun download, modifica, build o patch.

**Esito:** **3.828 catene**, **501.435 slot**, terminatori finali **`next=0` ×3.826** e **`next=10` ×2**; i due `next=10` sono **esattamente** le due OOB. H1 e H4 sono **contradette come terminatori normali**; H2 e H3 restano **UNPROVEN** come causa, H5 **UNPROVEN**. AMDSupport ha **2 byte** residui, non 6. T27 resta **OPEN**.

---

## 1. Sorgenti locali

| Fonte | Presenza | Rilevanza |
|---|---|---|
| `fixup-chains.h` | **NO** | nessuna definizione Apple |
| `kcformat.c` | **NO** | nessun generatore KC |
| QEMU source | **NO** | nessuna emulazione |
| `hao-runtime/src/macho.c` | **SÌ** | loader generico ARM64E/64, **non 11** |
| Stela `chained_fixups.rs` | **SÌ** | formati **1/2/6/9/12**, **non 11** |
| BootKC `fixup_value` | **NO** | loader kernel non simbolizzato |

**PROVEN:** non esiste un’implementazione locale del formato 11.
**PROVEN:** i loader locali non coprono il formato AMD.

---

## 2. Terminatori globali

| Ultimo `next` | Catene | Percentuale |
|---:|---:|---:|
| **0** | **3.826** | **99,948%** |
| **10** | **2** | **0,052%** |
| altro | **0** | **0%** |
| **Totale** | **3.828** | **100%** |

**PROVEN:** il terminatore normale è **`next=0`**.
**PROVEN:** `next=10` compare **solo** nelle due OOB.
**PROVEN:** non ci sono altri terminatori.

---

## 3. Le due OOB

| Provider | Pagina | Ultimo offset | `next` | Residuo | Necessario |
|---|---:|---:|---:|---:|---:|
| **X5400HWLibs** | **3475** | `0xFF0` | **10** | **6** | **8** |
| **AMDSupport** | **33** | `0xFF4` | **10** | **2** | **8** |

**PROVEN:** entrambe hanno `next=10` sull’ultimo slot.
**PROVEN:** AMDSupport ha **2 byte** residui, non 6.
**PROVEN:** entrambe richiedono 8 byte.

---

## 4. Validazione nei loader locali

| Controllo | `macho.c` | Stela |
|---|---|---|
| `page_start` | **sì** | **sì** |
| `page_count` | **sì** | **sì** |
| `page_size` | **sì** | **sì** |
| `next` | **sì** | **sì** |
| limite **segmento** | **sì** | **sì** |
| limite **pagina** | **NO** | **sì (metadati)** |
| formato **11** | **NO** | **NO** |
| `fixup_value` kernel | **NO** | **NO** |

**PROVEN:** `macho.c` controlla `in_range(off, 8, seg_len)`, non il bordo pagina.
**PROVEN:** con `next=10` il successore resta nel segmento ma esce dalla pagina.
**UNPROVEN:** il loader kernel 26B131.

---

## 5. Classificazione H1–H5

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H1** | `next=10` è un terminatore | **CONTRADETTA come normale / UNPROVEN come speciale** | 3.826 catene finiscono con **0**; solo le 2 OOB hanno **10** |
| **H2** | `next=10` è distanza; il loader controlla il bordo | **SUPPORTATA come distanza / UNPROVEN come controllo** | distanza 10 crossing; `macho.c` non controlla la pagina |
| **H3** | il linker ha serializzato male l’ultimo `next` | **SUPPORTATA in via indiziaria / UNPROVEN** | struttura identica target/T6 e 2 provider |
| **H4** | l’ultimo slot è un sentinel non seguito | **CONTRADETTA come generale / UNPROVEN** | 3.826 catene normali finiscono con `0` |
| **H5** | il loader rifiuta l’intera catena | **UNPROVEN** | nessun codice o trace |

**PROVEN:** H1/H4 non spiegano il terminatore normale.
**PROVEN:** H2 è compatibile con la distanza, ma il controllo non è provato.
**UNPROVEN:** H3 e H5.

---

## 6. Semantica di `next=10`

| Aspetto | Valore |
|---|---|
| Terminatore normale | **0** |
| `next=10` normale | **NO** |
| `next=10` nelle OOB | **2/2** |
| Successore | **fuori pagina** |
| Successore nel segmento | **SÌ** |
| Byte residui | **6 / 2** |
| Byte necessari | **8** |
| Decisione loader | **UNPROVEN** |

**PROVEN:** `next=10` non è il terminatore normale.
**PROVEN:** il successore è oltre la pagina ma dentro il segmento.
**UNPROVEN:** se il loader lo legga, lo ignori o rifiuti.

---

## 7. Confronto con gli altri provider

| Gruppo | Catene | Ultimo `next=10` | OOB |
|---|---:|---:|---:|
| X5400HWLibs | **188** | **1** | **1** |
| AMDSupport | **432** | **1** | **1** |
| Altri 170 provider | **3.208** | **0** | **0** |
| **Totale** | **3.828** | **2** | **2** |

**PROVEN:** solo i due provider OOB hanno `next=10`.
**PROVEN:** gli altri 170 provider terminano con `next=0`.
**PROVEN:** l’anomalia è localizzata, non globale.

---

## 8. Metadati e transizioni

| Provider | `size` | `page_count` | `22+2*pc` | Pad | Prime transizioni |
|---|---:|---:|---:|---:|---|
| X5400HWLibs | **10.764** | **5.370** | **10.762** | **+2** | 8, 96, 32 |
| AMDSupport | **98** | **37** | **96** | **+2** | 8, 8, 8 |

**PROVEN:** metadati coerenti.
**PROVEN:** stride 1 byte.
**PROVEN:** nessun errore di `page_start` o `page_count`.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Terminatore normale | **`next=0`** |
| `next=10` normale? | **NO** |
| H1 | **CONTRADETTA come normale** |
| H2 | **SUPPORTATA come distanza / UNPROVEN** |
| H3 | **INDIZIARIA / UNPROVEN** |
| H4 | **CONTRADETTA come generale** |
| H5 | **UNPROVEN** |
| AMDSupport residuo | **2 byte** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il terminatore normale è **`next=0`** in **3.826/3.828** catene. I due **`next=10`** sono esclusivamente le OOB: X5400 con **6 byte** residui e AMDSupport con **2**. H1/H4 non sono terminatori generali; H2 è una distanza compatibile ma senza prova del controllo pagina; H3 è indiziaria; H5 è priva di evidenza. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun download/modifica/build/patch/boot.
