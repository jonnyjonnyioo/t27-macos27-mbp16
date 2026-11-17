# T27 — AGENT-AMD — OOB BYTE LAYOUT RECONSTRUCTION

**Scope:** ricostruire le finestre `0xFE0–0x1010` di X5400HWLibs e AMDSupport in target/T6; identificare record allineati e non allineati; cercare slot omessi, sovrapposti o duplicati shiftati; verificare se `next=10` è una continuazione strutturale o una distanza normale.

**Modalità:** sola lettura; dump byte, walk globale delle 3.828 catene, parsing chained; nessuna modifica, patch, build o download.

**Esito:** **`next=10` non è un sentinel**: compare **2.244 volte** su 501.435 slot ed è una **distanza normale**. Solo **2** catene lo hanno come **ultimo** `next`, ed entrambe sono le OOB. H1/H4/H9 sono **contradette**; H2 è **supportata**; H3 resta **indiziaria**; H6 è **limitata ai due successori**; H7 **contradetta**; H8 **UNPROVEN**. T27 resta **OPEN**.

---

## 1. Correzione globale

| Valore | Conteggio |
|---|---:|
| Slot totali | **501.435** |
| Catene | **3.828** |
| `next=0` | **3.826** |
| `next=10` totali | **2.244** |
| `next=8` | **384.028** |
| `next=16` | **46.414** |
| `next=48` | **33.119** |
| `next=32` | **15.509** |
| `next=24` | **11.864** |
| Valori distinti | **166** |

**PROVEN:** `next=10` è una distanza normale, usata **2.244** volte.
**PROVEN:** solo **2** catene terminano con `next=10`.
**PROVEN:** le due terminazioni `10` sono le due OOB.
**CORREZIONE:** il dato precedente “`next=10` solo 2” valeva **solo per l’ultimo slot**, non per tutti gli slot.

---

## 2. Finestra X5400HWLibs

**Target, pagina 3475, base `0x9C78000`, `0xFE0–0x1010`:**

```
0000500002022664ca480000500003022664ca480000500004022664ca48000000000502da68ca48000050000001da68ca48000050000001
```

**T6, pagina 3475, base `0x9C6C000`:**

```
00005000020226a4c94800005000030226a4c94800005000040226a4c948000000000502daa8c948000050000001daa8c948000050000001
```

| Offset | Target raw | T6 raw | `next` |
|---:|---|---|---:|
| `0xFE0` | `0x6426020200500000` | `0xA426020200500000` | 3204 / 1156 |
| `0xFE8` | `0x02030050000048CA` | `0x02030050000048C9` | 64 / 64 |
| `0xFF0` | `0x0005000048CA6426` | `0x0005000048C9A426` | **10 / 10** |
| `0xFF8` | `0x000048CA64260204` | `0x000048C9A4260204` | **0 / 0** |
| `0x1000` | `0x48CA68DA02050000` | `0x48C9A8DA02050000` | 2329 / 2329 |
| `0x1008` | `0x68DA010000500000` | `0xA8DA010000500000` | 3355 / 1307 |

**PROVEN:** i byte target/T6 conservano la struttura con shift target `0xC000`.
**PROVEN:** `0xFF8` è un record con `next=0`.
**PROVEN:** il successore `0xFFA` è una lettura non allineata che usa 6 byte del record `0xFF8` e 2 byte della pagina successiva.

---

## 3. Finestra AMDSupport

**Target, pagina 33, base `0x13C13000`, `0xFE0–0x1010`:**

```
4097bb530000500004024097bb53000050000502e099bb53000050000002109dbb53000000000500109dbb53000050000100109dbb530000
```

**T6, pagina 33, base `0x13C07000`:**

```
40d7ba5300005000040240d7ba53000050000502e0d9ba5300005000000210ddba5300000000050010ddba5300005000010010ddba530000
```

| Offset | Target raw | T6 raw | `next` |
|---:|---|---|---:|
| `0xFE0` | `0x50000053BB9740` | `0x50000053BAD740` | **10 / 10** |
| `0xFE8` | `0x53BB97400204` | `0x53BAD7400204` | 0 / 0 |
| `0xFF0` | `0x50000502E099BB53` | `0x50000502E0D9BA53` | 2679 / 2679 |
| `0xFF4` | `0x0005000053BB99E0` | `0x0005000053BAD9E0` | **10 / 10** |
| `0xFF8` | `0x9D10020000500000` | `0xDD10020000500000` | 930 / 2978 |
| `0xFFE` | `0x0000000053BB9D10` | `0x0000000053BADD10` | **0 / 0** |
| `0x1000` | `0x0005000000053BB` | `0x0005000000053BA` | 0 / 0 |
| `0x1008` | `0x50000053BB9D10` | `0x50000053BADD10` | **10 / 10** |

**PROVEN:** `next=10` compare già a `0xFE0` e a `0x1008`.
**PROVEN:** `0xFE0` e `0x1008` sono next validi **dentro** la pagina.
**PROVEN:** il successore `0xFFE` legge 2 byte della pagina 33 e 6 byte della pagina 34.
**PROVEN:** il successore è una copia shiftata del record `0x1008`.

---

## 4. Record allineati e non allineati

| Tipo | Offset | Esito |
|---|---|---|
| allineato 8 | `0xFE0`, `0xFE8`, `0xFF0`, `0xFF8`, `0x1000`, `0x1008` | letture canoniche |
| shift 2 | `0xFE2`, `0xFEA`, `0xFF2`, `0xFFA`, `0x1002`, `0x100A` | possibili duplicati |
| shift 6 | `0xFE6`, `0xFEE`, `0xFF6`, `0xFFE`, `0x1006`, `0x100E` | possibili duplicati |

**PROVEN:** il formato 11 usa stride 1 byte: gli slot possono essere non allineati.
**PROVEN:** shift 2/6 producono raw formalmente validi.
**PROVEN:** non ogni raw formalmente valido è uno slot reale.

---

## 5. Duplicati shiftati

| Provider | Offset | Raw | Target | `next` | Ruolo |
|---|---:|---|---:|---:|---|
| X5400 | `0xFF8` | `0x000048CA64260204` | `0x24260204` | **0** | record reale |
| X5400 | `0xFFA` | `0x0000000048CA6426` | `0x8CA6426` | **0** | copia shiftata |
| X5400 | `0xFE6` | `0x50000048CA6426` | `0x8CA6426` | **10** | next valido interno |
| X5400 | `0x100E` | `0x50000048CA68DA` | `0x8CA68DA` | **10** | next valido interno |
| AMDSupport | `0xFF4` | `0x0005000053BB99E0` | `0x13BB99E0` | **10** | ultimo reale |
| AMDSupport | `0xFFE` | `0x0000000053BB9D10` | `0x13BB9D10` | **0** | copia shiftata |
| AMDSupport | `0xFE0` | `0x50000053BB9740` | `0x13BB9740` | **10** | next valido interno |
| AMDSupport | `0x1008` | `0x50000053BB9D10` | `0x13BB9D10` | **10** | next valido interno |

**PROVEN:** `0xFFA`/`0xFFE` sono copie shiftate, non record indipendenti.
**PROVEN:** `next=10` è usato anche da record interni validi.

---

## 6. `next=10` è una continuazione strutturale?

| Test | Esito |
|---|---|
| Frequenza | **2.244** |
| Uso interno | **2.242** |
| Uso come ultimo | **2** |
| Terminatore normale | **0** |
| Successore reale OOB | **NO** |
| Continuazione strutturale | **NO** |

**PROVEN:** `next=10` non è un sentinel.
**PROVEN:** non è una continuazione strutturale speciale.
**PROVEN:** è una distanza normale.
**PROVEN:** l’anomalia è la **posizione dell’ultimo slot**, non il valore `10`.

---

## 7. H1–H9 aggiornate

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H1** | `10` terminatore | **CONTRADETTA** | 2.244 usi come distanza |
| **H2** | `10` distanza + bound | **SUPPORTATA** | distanza normale; successore fuori pagina |
| **H3** | linker bug | **INDIZIARIA** | ultimo slot troppo vicino al bordo |
| **H4** | sentinel | **CONTRADETTA** | 3.826 catene finiscono 0 |
| **H5** | reject | **UNPROVEN** | nessun codice/trace |
| **H6** | artefatto unaligned | **SUPPORTATA solo per i 2 successori** | copie shiftate |
| **H7** | off-by-two/six | **CONTRADETTA** | `10` è normale, non off-by |
| **H8** | slot omesso | **UNPROVEN** | nessun metadato |
| **H9** | sentinel coda | **CONTRADETTA** | `10` normale |

**PROVEN:** H1/H4/H7/H9 non reggono.
**PROVEN:** H2 è la spiegazione più semplice.
**UNPROVEN:** H3/H5/H8.

---

## 8. Limiti e provenienza

| Elemento | Valore |
|---|---|
| X5400 `segment_end` | `0xA3DF000` |
| X5400 `page_end` | `0x9C79000` |
| AMDSupport `segment_end` | `0x13C17000` |
| AMDSupport `page_end` | `0x13C14000` |
| Successori dentro il segmento | **SÌ** |
| Pagina successiva mappata | **SÌ** |
| Linker ID | **assente** |
| `fixups_version` | **0** |
| `imports_count` | **0** |

**PROVEN:** il bordo pagina non è il bordo segmento.
**PROVEN:** nessun linker ID.
**UNPROVEN:** il comportamento del loader kernel.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `next=10` normale? | **SÌ — 2.244 usi** |
| `next=10` sentinel? | **NO** |
| Terminatore normale | **0** |
| Ultimo `10` | **2, entrambe OOB** |
| Successore reale | **NO** |
| H1/H4/H9 | **CONTRADETTE** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5/H8 | **UNPROVEN** |
| AMDSupport residuo | **2 byte** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `next=10` è una **distanza normale**, usata **2.244** volte; non è un terminatore, un sentinel o una continuazione strutturale. Solo due catene lo hanno come ultimo `next`, ed entrambe sono le OOB: l’anomalia è che l’ultimo slot è troppo vicino al bordo pagina per una distanza di 10 byte. H2 spiega la distanza; H3 resta indiziaria; H1/H4/H7/H9 sono contradette; H5/H8 restano UNPROVEN. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
