# T27 — AGENT-AMD — GLOBAL MULTI-START AUDIT

**Scope:** completare lo scan globale includendo tutte le pagine, distinguere START_NONE, start singolo e MULTI, ricostruire ogni catena, contare globalmente catene/slot/next/terminatori/OOB, identificare anomalie aggiuntive, confrontare i risultati precedenti e produrre statistiche per provider.

**Modalità:** sola lettura; parsing di tutti i 172 provider con `LC_DYLD_CHAINED_FIXUPS`, page-start table, walk delle catene; nessuna modifica, patch, build o download.

**Esito:** **0 pagine multi-start reali**. Le 5.125 “multi” del report precedente erano **START_NONE `0xFFFF`**, non `0x8000`. Lo scan globale è quindi **completo**: **3.828 catene**, **501.435 slot**, **2.244 `next=10`**, **2 ultimi `next=10`**, **2 OOB**. Nessuna anomalia aggiuntiva. **H2 SUPPORTATA**; **H3 INDIZIARIA**; **H5/H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. Globale completo

| Voce | Valore |
|---|---:|
| Provider con chained fixups | **172** |
| Pagine totali | **64.039** |
| START_NONE (`0xFFFF`) | **60.211** |
| Start singolo | **3.828** |
| MULTI reali (`0x8000`) | **0** |
| Catene | **3.828** |
| Slot | **501.435** |
| `next=10` totali | **2.244** |
| Ultimi `next=10` | **2** |
| OOB | **2** |
| Valori `next` distinti | **166** |

**PROVEN:** non esistono pagine multi-start reali.
**PROVEN:** lo scan globale è completo.
**PROVEN:** le 5.125 pagine X5400 erano **START_NONE**, non MULTI.
**PROVEN:** le 2 pagine AMDSupport erano **START_NONE**, non MULTI.

---

## 2. Page-start table

| Provider | `size` | `page_count` | `22+2*pc` | Pad | Digest page-start | NONE | Singolo | MULTI | Catene | Slot | OOB |
|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|
| X5400HWLibs target | **10.764** | **5.370** | **10.762** | **2** | `b3b3d97243ba515a09d20691472ee1ad74c383f55f45bda771a97b949d17c684` | **5.125** | **245** | **0** | **245** | **11.232** | **1** |
| X5400HWLibs T6 | **10.764** | **5.370** | **10.762** | **2** | `b3b3d97243ba515a09d20691472ee1ad74c383f55f45bda771a97b949d17c684` | **5.125** | **245** | **0** | **245** | **11.232** | **1** |
| AMDSupport target | **98** | **37** | **96** | **2** | `82d442b7ac42aae0d3aa2915501a3ada9d392e8675291454c66e9aa7b667cd2a` | **2** | **35** | **0** | **35** | **16.191** | **1** |
| AMDSupport T6 | **98** | **37** | **96** | **2** | `82d442b7ac42aae0d3aa2915501a3ada9d392e8675291454c66e9aa7b667cd2a` | **2** | **35** | **0** | **35** | **16.191** | **1** |

**PROVEN:** digest page-start identici target/T6.
**PROVEN:** `size`, `page_count`, padding e conteggi identici.
**PROVEN:** nessuna pagina MULTI.
**PROVEN:** 1 OOB per provider.

---

## 3. Pagine adiacenti

| Provider | Pagina | Target start | T6 start | Tipo |
|---|---:|---:|---:|---|
| X5400HWLibs | 3474 | `0xFFFF` | `0xFFFF` | NONE |
| X5400HWLibs | **3475** | **0x698** | **0x698** | singolo |
| X5400HWLibs | 3476 | `0x0004` | `0x0004` | singolo |
| AMDSupport | 32 | `0x0000` | `0x0000` | singolo |
| AMDSupport | **33** | **0x0000** | **0x0000** | singolo |
| AMDSupport | 34 | `0x0008` | `0x0008` | singolo |

**PROVEN:** le pagine anomale sono singole.
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
| X5400HWLibs target/T6 | `starts_record + 10.762` | **`0000`** | padding |
| AMDSupport target/T6 | `starts_record + 96` | **`0000`** | padding |

**PROVEN:** i 2 byte sono zero.
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
| MULTI reali | **0** |
| Page-start verso 0xFFA/0xFFE | **nessuna** |
| Errore page-start | **CONTRADETTO** |

**PROVEN:** la page-start table non è la causa.
**PROVEN:** l’anomalia è nel contenuto dell’ultimo record.

---

## 7. Lunghezza effettiva

| Provider | Catene | Ultimo | `next` | Campo lunghezza |
|---|---:|---:|---:|---|
| X5400HWLibs | **246** | **0xFF0** | **10** | **assente** |
| AMDSupport | **37** | **0xFF4** | **10** | **assente** |

**PROVEN:** non esiste un campo di lunghezza.
**PROVEN:** la lunghezza è determinata dal walk fino a `next=0`.
**PROVEN:** target/T6 hanno la stessa struttura.

---

## 8. Distribuzione globale `next`

| `next` | Conteggio |
|---:|---:|
| **8** | **384.028** |
| **16** | **46.414** |
| **48** | **33.119** |
| **32** | **15.509** |
| **24** | **11.864** |
| **0** | **3.826** |
| **10** | **2.244** |
| **40** | **1.067** |
| altri | **3.364** |
| **Totale** | **501.435** |

**PROVEN:** `next=10` è una distanza normale.
**PROVEN:** solo 2 catene terminano con `10`.
**PROVEN:** le 2 terminazioni `10` sono le 2 OOB.

---

## 9. Statistiche per provider

### Top 8 per slot

| Provider | Catene | Slot | `next=10` | Ultimo 10 | OOB |
|---|---:|---:|---:|---:|---:|
| `com.apple.kext.AMDRadeonX4000` | 59 | 26.377 | 0 | 0 | 0 |
| `com.apple.kext.AMDRadeonX6000` | 57 | 25.197 | 0 | 0 | 0 |
| `com.apple.kext.AMDRadeonX5000` | 54 | 23.649 | 0 | 0 | 0 |
| `com.apple.kext.AMDRadeonX6000Framebuffer` | 130 | 18.468 | 125 | 0 | 0 |
| `com.apple.kext.AMDSupport` | **37** | **16.387** | **124** | **1** | **1** |
| `com.apple.kext.AMDRadeonX5000HWLibs` | 214 | 12.593 | 125 | 0 | 0 |
| `com.apple.plugin.IOgPTPPlugin` | 25 | 11.820 | 0 | 0 | 0 |
| `com.apple.driver.AppleIntelICLGraphics` | 33 | 11.519 | 0 | 0 | 0 |

### Provider con OOB

| Provider | Catene | Slot | `next=10` | Ultimo 10 | OOB |
|---|---:|---:|---:|---:|---:|
| `com.apple.kext.AMDSupport` | 37 | 16.387 | 124 | 1 | **1** |
| `com.apple.kext.AMDRadeonX5400HWLibs` | 246 | 11.238 | 124 | 1 | **1** |

**PROVEN:** solo due provider hanno OOB.
**PROVEN:** nessuna anomalia aggiuntiva.
**PROVEN:** statistiche complete in `T27-PROVIDER-STATS.tsv` (172 provider).

---

## 10. Confronto vecchio/nuovo

| Voce | Precedente | Nuovo | Esito |
|---|---:|---:|---|
| Catene | 3.828 | **3.828** | **uguale** |
| Slot | 501.435 | **501.435** | **uguale** |
| `next=10` | 2.244 | **2.244** | **uguale** |
| Ultimi `next=10` | 2 | **2** | **uguale** |
| OOB | 2 | **2** | **uguale** |
| MULTI X5400 | 5.125 | **0** | **corretto** |
| MULTI AMDSupport | 2 | **0** | **corretto** |

**PROVEN:** i totali precedenti erano già corretti.
**PROVEN:** l’unico errore era la classificazione `0xFFFF` come MULTI.
**PROVEN:** nessuna anomalia aggiuntiva.
**LIMITE:** il vecchio algoritmo testava `st & 0x8000` prima di `st == 0xFFFF`.

---

## 11. Classificazione H2/H3/H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H2** | distanza + bound | **SUPPORTATA** | `next=10` normale; successore fuori pagina |
| **H3** | errore linker | **INDIZIARIA** | ultimo `next` non azzerato; page-start corretto |
| **H5** | loader rifiuta | **UNPROVEN** | nessun codice/trace |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |
| **H1/H4/H9** | sentinel/terminatore | **CONTRADETTE** | `next=10` usato 2.244 volte |

**PROVEN:** H2 è la spiegazione più semplice.
**PROVEN:** la page-start table non è la causa.
**UNPROVEN:** H3/H5/H8.

---

## 12. Conclusione

| Domanda | Risposta |
|---|---|
| Pagine MULTI reali | **0** |
| Scan globale completo | **SÌ** |
| Catene/slot | **3.828 / 501.435** |
| `next=10` | **2.244** |
| Ultimi `next=10` | **2** |
| OOB | **2** |
| Errore page-start | **NO** |
| Anomalie aggiuntive | **NESSUNA** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5/H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** non esistono pagine multi-start reali; le 5.125/2 “multi” erano `START_NONE`. Lo scan globale è completo e conferma **3.828 catene**, **501.435 slot**, **2.244 `next=10`**, **2 ultimi `next=10`** e **2 OOB**. L’OOB non deriva dalla page-start table: l’ultimo record ha `next=10`, distanza normale, ma il successore cade oltre il bordo pagina. H2 resta la spiegazione più semplice; H3 è indiziaria; H5/H8 restano UNPROVEN. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,25 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
