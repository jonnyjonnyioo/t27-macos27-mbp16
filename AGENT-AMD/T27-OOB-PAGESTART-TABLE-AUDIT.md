# T27 — AGENT-AMD — OOB PAGE-START TABLE AUDIT

**Scope:** ricostruire le page-start table di X5400HWLibs e AMDSupport, incluse le pagine adiacenti; verificare page-start, slot, dimensione e ultimo record; confrontare target/T6; analizzare i 2 byte eccedenti; classificare H2/H3/H5/H8.

**Modalità:** sola lettura; parsing completo di `LC_DYLD_CHAINED_FIXUPS`, `starts_in_image`, `dyld_chained_starts_in_segment`, page-start table; walk delle catene a start singolo; nessuna modifica, build, patch o download.

**Esito:** le page-start table sono **identiche** target/T6 (stessi digest), i 2 byte eccedenti sono **`0000`** di padding e le page-start delle pagine anomale sono corrette. L’OOB **non** deriva da un errore della page-start table né da una lunghezza dichiarata diversa: deriva dall’ultimo `next=10`, che è una distanza normale ma supera il bordo pagina. **H2 SUPPORTATA**; **H3 INDIZIARIA**; **H5/H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. Correzione di scope

| Voce | Valore |
|---|---:|
| Catene a start singolo percorse | **3.828** |
| Slot a start singolo | **501.435** |
| Pagine multi-start X5400 | **5.125** |
| Pagine multi-start AMDSupport | **2** |
| Pagine multi-start percorse | **0** |

**PROVEN:** i totali **3.828/501.435/2.244** riguardano **solo le pagine a start singolo**.
**PROVEN:** le pagine multi-start non sono state percorse.
**CONSEGUENZA:** `next=10` resta una distanza normale, ma **2.244 è un limite inferiore**, non il totale assoluto.

---

## 2. Page-start table completa

| Provider | `size` | `page_count` | `22+2*pc` | Pad | Digest page-start | Non-FFFF | Multi | Catene singole | Slot singoli | OOB |
|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|
| X5400HWLibs target | **10.764** | **5.370** | **10.762** | **2** | `b3b3d97243ba515a09d20691472ee1ad74c383f55f45bda771a97b949d17c684` | **245** | **5.125** | **245** | **11.232** | **1** |
| X5400HWLibs T6 | **10.764** | **5.370** | **10.762** | **2** | `b3b3d97243ba515a09d20691472ee1ad74c383f55f45bda771a97b949d17c684` | **245** | **5.125** | **245** | **11.232** | **1** |
| AMDSupport target | **98** | **37** | **96** | **2** | `82d442b7ac42aae0d3aa2915501a3ada9d392e8675291454c66e9aa7b667cd2a` | **35** | **2** | **35** | **16.191** | **1** |
| AMDSupport T6 | **98** | **37** | **96** | **2** | `82d442b7ac42aae0d3aa2915501a3ada9d392e8675291454c66e9aa7b667cd2a` | **35** | **2** | **35** | **16.191** | **1** |

**PROVEN:** i digest page-start sono identici target/T6.
**PROVEN:** `page_count`, `size` e padding sono identici.
**PROVEN:** le catene singole e gli slot singoli coincidono.
**PROVEN:** esiste **1 OOB** per provider.

---

## 3. Pagine adiacenti

| Provider | Pagina | Target start | T6 start |
|---|---:|---:|---:|
| X5400HWLibs | 3474 | `0xFFFF` | `0xFFFF` |
| X5400HWLibs | **3475** | **0x698** | **0x698** |
| X5400HWLibs | 3476 | `0x0004` | `0x0004` |
| AMDSupport | 32 | `0x0000` | `0x0000` |
| AMDSupport | **33** | **0x0000** | **0x0000** |
| AMDSupport | 34 | `0x0008` | `0x0008` |

**PROVEN:** le page-start delle pagine anomale sono corrette e identiche.
**PROVEN:** le pagine adiacenti hanno start validi.
**PROVEN:** nessuna page-start punta a `0xFFA`/`0xFFE`.

---

## 4. Ultimo record

| Provider | Pagina | Ultimo offset | Raw | `next` | Successore | Esito |
|---|---:|---:|---|---:|---:|---|
| X5400HWLibs | 3475 | `0xFF0` | `0x0005000048CA6426` | **10** | `0xFFA` | OOB |
| AMDSupport | 33 | `0xFF4` | `0x0005000053BB99E0` | **10** | `0xFFE` | OOB |

**PROVEN:** l’ultimo record è un pointer valido con `next=10`.
**PROVEN:** il successore è oltre il bordo pagina.
**PROVEN:** il successore non è una page-start.

---

## 5. I 2 byte eccedenti

| Provider | Offset extra | Byte | Tipo |
|---|---|---:|---|
| X5400HWLibs target | `starts_record + 10.762` | **`0000`** | padding |
| X5400HWLibs T6 | `starts_record + 10.762` | **`0000`** | padding |
| AMDSupport target | `starts_record + 96` | **`0000`** | padding |
| AMDSupport T6 | `starts_record + 96` | **`0000`** | padding |

**PROVEN:** i 2 byte sono **zero**.
**PROVEN:** sono padding, non page-start.
**PROVEN:** non spiegano 8 byte mancanti.

---

## 6. Errore di page-start?

| Test | Esito |
|---|---|
| Digest target/T6 | **identici** |
| Start pagina 3475 | **0x698 / 0x698** |
| Start pagina 33 | **0x0 / 0x0** |
| Start adiacenti | **validi** |
| Padding | **0000 / 0000** |
| Page-start verso 0xFFA/0xFFE | **nessuna** |
| Errore page-start | **CONTRADETTO** |

**PROVEN:** la page-start table non è la causa.
**PROVEN:** l’anomalia è nel contenuto dell’ultimo record, non nella tabella.

---

## 7. Lunghezza effettiva della catena

| Provider | Catena | Ultimo | `next` | Campo lunghezza |
|---|---:|---:|---:|---|
| X5400HWLibs | **188** | **0xFF0** | **10** | **assente** |
| AMDSupport | **432** | **0xFF4** | **10** | **assente** |

**PROVEN:** non esiste un campo di lunghezza della catena.
**PROVEN:** la lunghezza è determinata dal walk fino a `next=0`.
**PROVEN:** target/T6 hanno la stessa lunghezza.
**UNPROVEN:** una diversa interpretazione della lunghezza.

---

## 8. Record terminali omessi o conteggi errati

| Ipotesi | Evidenza | Stato |
|---|---|---|
| Record terminale omesso | nessun conteggio in-band | **UNPROVEN** |
| Conteggio errato | page-start e slot coincidono target/T6 | **CONTRADETTO** |
| Slot duplicato | 0xFFA/0xFFE sono copie shiftate | **SUPPORTATO** |
| Slot reale a 0xFFA/0xFFE | nessuna page-start, nessun record | **CONTRADETTO** |

**PROVEN:** non c’è un conteggio degli slot nei metadati.
**PROVEN:** i conteggi target/T6 coincidono.
**UNPROVEN:** l’omissione di un record terminale.

---

## 9. Classificazione H2/H3/H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H2** | distanza + bound | **SUPPORTATA** | `next=10` normale; successore fuori pagina |
| **H3** | errore linker | **INDIZIARIA** | ultimo `next` non azzerato; page-start corretto |
| **H5** | loader rifiuta | **UNPROVEN** | nessun codice/trace |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |
| **H1/H4/H9** | sentinel/terminatore | **CONTRADETTE** | `next=10` usato 2.244 volte come distanza |

**PROVEN:** H2 è la spiegazione più semplice.
**PROVEN:** la page-start table non è la causa.
**UNPROVEN:** H3/H5/H8.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Page-start target/T6 identiche? | **SÌ** |
| Errore page-start? | **NO** |
| Padding 2 byte? | **0000** |
| Lunghezza dichiarata? | **NO** |
| Ultimo `next` | **10** |
| Causa OOB | **distanza oltre pagina** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5 | **UNPROVEN** |
| H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le page-start table sono integre e identiche target/T6; i 2 byte eccedenti sono `0000` di padding; non esiste una lunghezza dichiarata della catena. L’OOB non deriva dalla tabella né da un conteggio errato: l’ultimo record ha `next=10`, distanza normale, ma il successore cade oltre il bordo pagina. H2 resta la spiegazione più semplice; H3 è indiziaria; H5/H8 restano UNPROVEN. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,25 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
