# T27 — AGENT-AMD — OOB SUCCESSOR BYTE ANALYSIS

**Scope:** esaminare gli 8 byte disponibili agli ultimi slot e al successore; confrontare raw target/T6; analizzare le catene adiacenti; verificare limiti di segmento/pagina; aggiornare H1–H5 e separare nuove ipotesi.

**Modalità:** sola lettura; dump dei byte, walk delle catene adiacenti, parsing `LC_FILESET_ENTRY`/chained; nessuna scrittura, patch, build o download.

**Esito:** i due successori **non sono slot reali**: a `0xFFA`/`0xFFE` l’8-byte read è una **copia shiftata** di un pointer vicino o dei byte della pagina successiva. Entrambi decodificano `next=0`, ma **non** sono terminazioni legittime. H1/H4 restano **contradette come normali**; H2 **supportata come distanza**; H3 **indiziaria**; H5 **UNPROVEN**. T27 resta **OPEN**.

---

## 1. Finestra byte X5400HWLibs

**Pagina 3475, base 0x9C78000, ultimo slot 0xFF0, `next=10`.**

| Offset | Byte | Raw | `next` |
|---:|---|---|---:|
| `0xFF0` | `2664ca4800005000` | `0x0050000048CA6426` | **10** |
| `0xFF8` | `04022664ca480000` | `0x000048CA64260204` | **0** |
| `0xFFA` | `2664ca4800000000` | `0x0000000048CA6426` | **0** |
| `0x1000` | `00000502da68ca48` | `0x48CA68DA02050000` | 2329 |
| `0x1008` | `000050000001da68` | `0x68DA010000500000` | 3355 |

**PROVEN:** l’ultimo slot è interamente disponibile.
**PROVEN:** il successore `0xFFA` è un read **non allineato**.
**PROVEN:** il raw a `0xFFA` è `0x48CA6426`, **copia shiftata di 2 byte** del raw a `0xFF8`.
**PROVEN:** a `0xFF8` esiste un raw con `next=0`.
**PROVEN:** il successore non è uno slot dichiarato.

---

## 2. Finestra byte AMDSupport

**Pagina 33, base 0x13C13000, ultimo slot 0xFF4, `next=10`.**

| Offset | Byte | Raw | `next` |
|---:|---|---|---:|
| `0xFF4` | `e099bb5300000500` | `0x0050000053BB99E0` | **10** |
| `0xFF8` | `000050000002109d` | `0x9D10020000500000` | 930 |
| `0xFFE` | `109dbb5300000000` | `0x0000000053BB9D10` | **0** |
| `0x1000` | `bb53000000000500` | `0x0005000000053BB` | **0** |
| `0x1008` | `109dbb5300005000` | `0x0005000053BB9D10` | **10** |

**PROVEN:** l’ultimo slot è interamente disponibile.
**PROVEN:** il successore `0xFFE` è un read **non allineato** che attraversa il bordo pagina.
**PROVEN:** `0xFFE` legge 2 byte della pagina 33 e 6 byte della pagina 34.
**PROVEN:** il raw a `0xFFE` è `0x53BB9D10`, **copia shiftata di 2 byte** del raw a `0x1008`.
**PROVEN:** il successore non è uno slot dichiarato.

---

## 3. Decodifica del successore

| Provider | Offset | Raw | Target | Cache | Div | AddrDiv | Key | `next` | Auth |
|---|---:|---|---:|---:|---:|---:|---:|---:|---|
| X5400HWLibs | `0xFFA` | `0x48CA6426` | `0x8CA6426` | 1 | 0 | 0 | 0 | **0** | 0 |
| AMDSupport | `0xFFE` | `0x53BB9D10` | `0x13BB9D10` | 1 | 0 | 0 | 0 | **0** | 0 |

**PROVEN:** entrambi decodificano formalmente come pointer validi con `next=0`.
**PROVEN:** X5400 ha lo **stesso target** dell’ultimo slot.
**PROVEN:** AMDSupport ha un target **diverso** dall’ultimo slot.
**PROVEN:** i valori derivano da byte vicini, non da slot indipendenti.

---

## 4. Catene adiacenti

| Provider | Pagina | Start | Catena | Ultimo offset | Ultimo `next` | Esito |
|---|---:|---:|---:|---:|---:|---|
| X5400HWLibs | 3474 | `0xFFFF` | — | — | — | nessuna |
| X5400HWLibs | **3475** | **0x698** | **188** | **0xFF0** | **10** | **OOB** |
| X5400HWLibs | 3476 | `0x4` | 37 | `0x16C` | **0** | normale |
| AMDSupport | 32 | `0x0` | 479 | `0xFF8` | **0** | normale |
| AMDSupport | **33** | **0x0** | **432** | **0xFF4** | **10** | **OOB** |
| AMDSupport | 34 | `0x8` | 59 | `0x24C` | **0** | normale |

**PROVEN:** le pagine adiacenti terminano con `next=0`.
**PROVEN:** solo le due pagine OOB hanno `next=10`.
**PROVEN:** la catena AMDSupport pagina 32 termina a `0xFF8`, a 8 byte dal bordo.

---

## 5. Limiti di segmento e pagina

| Provider | Segmento | `segment_end` | `page_end` | Successore | Dentro segmento? |
|---|---|---:|---:|---:|---|
| X5400HWLibs | `__DATA` | `0xA3DF000` | `0x9C79000` | `0x9C78FFA` | **SÌ** |
| AMDSupport | `__DATA` | `0x13C17000` | `0x13C14000` | `0x13C13FFE` | **SÌ** |

**PROVEN:** entrambi i successori sono **dentro il segmento**.
**PROVEN:** il bordo pagina **non** coincide con la fine del segmento.
**PROVEN:** entrambi hanno una pagina successiva mappata.
**UNPROVEN:** la regione assoluta a runtime.

---

## 6. Confronto target/T6

| Elemento | Target | T6 | Delta |
|---|---:|---:|---:|
| X5400 ultimo raw | `0x0050000048CA6426` | ` 0x0050000048C9A426` | **0xC000** |
| X5400 `0xFF8` raw | `0x000048CA64260204` | `0x000048C9A4260204` | **0xC000** |
| X5400 successore | `0x48CA6426` | `0x48C9A426` | **0xC000** |
| AMDSupport ultimo raw | `0x0050000053BB99E0` | ` 0x0050000053BAD9E0` | **0xC000** |
| AMDSupport successore | `0x53BB9D10` | `0x53BADD10` | **0xC000** |

**PROVEN:** i campi `cache/diversity/addrDiv/key/next` sono invarianti.
**PROVEN:** il target è traslato di **0xC000**.
**PROVEN:** la struttura dei byte è identica.

---

## 7. H1–H5 aggiornate

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H1** | `next=10` è terminatore | **CONTRADETTA come normale / UNPROVEN speciale** | successore già `next=0`; 3.826 catene finiscono 0 |
| **H2** | distanza con bound check | **SUPPORTATA come distanza / UNPROVEN controllo** | successore dentro il segmento; `macho.c` controlla solo il segmento |
| **H3** | linker ha serializzato male | **SUPPORTATA indiziariamente / UNPROVEN** | successore = copia shiftata; target/T6 identici |
| **H4** | ultimo slot sentinel | **CONTRADETTA come generale / UNPROVEN** | 3.826 catene normali finiscono 0 |
| **H5** | loader rifiuta la catena | **UNPROVEN** | nessun codice/trace |

**PROVEN:** H1/H4 non sono terminatori generali.
**PROVEN:** H2 è compatibile con la distanza.
**UNPROVEN:** H3 e H5.

---

## 8. Nuove ipotesi

| # | Ipotesi | Stato | Nota |
|---:|---|---|---|
| **H6** | successore non allineato artefatto | **UNPROVEN** | `0xFFA`/`0xFFE` sono copie shiftate |
| **H7** | off-by-two/off-by-six nel `next` | **UNPROVEN** | X5400 salterebbe `0xFF8`, che è `next=0` |
| **H8** | linker ha emesso `next` per uno slot omesso | **UNPROVEN** | nessun metadato di provenienza |
| **H9** | `10` è un sentinel per coda corrotta | **UNPROVEN** | normale `0`; solo 2 casi |

**PROVEN:** H6 descrive i byte; **non** prova la causa.
**PROVEN:** H7 è compatibile con X5400, **non** con AMDSupport.
**UNPROVEN:** H8/H9.

---

## 9. Provenienza linker

| Metadato | Valore |
|---|---|
| `fixups_version` | **0** |
| `imports_count` | **0** |
| `imports_format` | **1** |
| `symbols_format` | **0** |
| Linker ID | **assente** |
| Build version | **non linker** |

**PROVEN:** nessun identificatore del linker.
**PROVEN:** nessun metadata di generazione fixup.
**UNPROVEN:** la toolchain responsabile.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Successore reale? | **NO** |
| Successore dentro il segmento? | **SÌ** |
| Successore `next=0`? | **SÌ, ma artefatto** |
| H1 normale? | **NO** |
| H2 distanza? | **SÌ / controllo UNPROVEN** |
| H3 linker? | **INDIZIARIA** |
| H4 generale? | **NO** |
| H5 reject? | **UNPROVEN** |
| AMDSupport residuo | **2 byte** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** gli 8 byte al successore sono leggibili e dentro il segmento, ma `0xFFA`/`0xFFE` **non sono slot reali**: sono copie shiftate di 2 byte di un pointer vicino o della pagina successiva. Entrambe decodificano `next=0`, quindi un loader che legge il successore **non faulta necessariamente**, ma il valore non è una terminazione legittima. H2 resta la spiegazione più semplice della distanza; H3 resta indiziaria; H1/H4 non sono terminatori generali; H5 non è provata. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
