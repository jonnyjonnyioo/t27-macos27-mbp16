# T27 — AGENT-AMD — OOB `next=10` RUN AUDIT

**Scope:** verificare se le due code terminali sono una sequenza intenzionale del linker AMD o una generazione errata dell’ultimo record; confrontare le 8 transizioni target/T6; cercare run di 8+ `next=10` negli altri provider; verificare catene che terminano `next=0` dopo sequenze equivalenti; cercare provenienza del generatore.

**Modalità:** sola lettura; tail target/T6, scan di tutti i run `next=10` nei 172 provider; nessuna modifica, patch, build o download.

**Esito:** le ultime 8 transizioni sono `next=10`, ma **non sono una coda isolata**: appartengono a run di **88** (X5400) e **66** (AMDSupport) `next=10`. Nel globale ci sono **24 run ≥8**, di cui **18 terminano `next=0`** e solo **2** sono OOB. La sequenza 8×10 **non è speciale**; H3 “linker error” resta **UNPROVEN**, con evidenza contraria a una firma delle 8 transizioni. T27 resta **OPEN**.

---

## 1. Correzione: run terminali

| Provider | Run terminale | Start run | Ultimo | Esito |
|---|---:|---:|---:|---|
| X5400HWLibs | **88** | `0xC8A` | `0xFF0` | OOB |
| AMDSupport | **66** | `0xD6A` | `0xFF4` | OOB |

**PROVEN:** le ultime 8 transizioni sono la parte finale di run di 88/66.
**PROVEN:** non sono una sequenza isolata di 8.
**CORREZIONE:** il precedente “coda di 8” descriveva solo le ultime 8, non l’intero run.

---

## 2. Tail target/T6

| Offset | X5400 target | X5400 T6 | AMDSupport target | AMDSupport T6 |
|---:|---|---|---|---|
| `0xFAA`/`0xFAE` | `0x8CA67BA` | `0x8C9A7BA` | `0x13BB9990` | `0x13BAD990` |
| `0xFB4`/`0xFB8` | `0x8CA685E` | `0x8C9A85E` | `0x13BB9740` | `0x13BAD740` |
| `0xFBE`/`0xFC2` | `0x8CA6965` | `0x8C9A965` | `0x13BB9740` | `0x13BAD740` |
| `0xFC8`/`0xFCC` | `0x8CA6426` | `0x8C9A426` | `0x13BB9740` | `0x13BAD740` |
| `0xFD2`/`0xFD6` | `0x8CA6426` | `0x8C9A426` | `0x13BB9740` | `0x13BAD740` |
| `0xFDC`/`0xFE0` | `0x8CA6426` | `0x8C9A426` | `0x13BB9740` | `0x13BAD740` |
| `0xFE6`/`0xFEA` | `0x8CA6426` | `0x8C9A426` | `0x13BB9740` | `0x13BAD740` |
| **`0xFF0`/`0xFF4`** | **`0x8CA6426`** | **`0x8C9A426`** | **`0x13BB99E0`** | **`0x13BAD9E0`** |

**PROVEN:** target traslato di **0xC000**.
**PROVEN:** `next=10` identico in tutti gli 8 slot.
**PROVEN:** struttura target/T6 identica.

---

## 3. Run globali ≥8

| Voce | Valore |
|---|---:|
| Run ≥8 | **24** |
| Terminano `next=0` | **18** |
| Terminano OOB | **2** |
| Terminano con altro `next` | **4** |
| Provider coinvolti | **18** |
| Run massimo | **125** |

### Lunghezze

| Lunghezza | Run |
|---:|---:|
| **125** | **12** |
| 91 | 1 |
| **88** | **1** |
| 86 | 1 |
| 78 | 1 |
| 75 | 1 |
| 46 | 1 |
| 38 | 1 |
| 36 | 1 |
| 33 | 1 |
| altre | 3 |

**PROVEN:** run di 8+ `next=10` sono comuni.
**PROVEN:** 18 run equivalenti terminano `next=0`.
**PROVEN:** solo 2 run sono OOB.

---

## 4. Esempi con terminazione `next=0`

| Provider | Pagina | Run | Start | Ultimo | Esito |
|---|---:|---:|---:|---:|---|
| X4000HWLibs | 1620 | **91** | `0xC6A` | `0xFF8` | `next=0` |
| X4400HWLibs | 3250 | **125** | `0x3DA` | `0x8BC` | `next=0` |
| X4700HWLibs | 1620 | **125** | `0x7CA` | `0xCAC` | `next=0` |
| X5200HWLibs | 4179 | **38** | `0xE7A` | `0xFF6` | `next=0` |
| X5400HWLibs | 3476 | **36** | `0x004` | `0x16C` | `next=0` |

**PROVEN:** la stessa sequenza `next=10` termina normalmente con `0`.
**PROVEN:** non c’è una regola “8×10 = errore”.
**PROVEN:** il problema è il page-end, non la lunghezza del run.

---

## 5. Pattern di allineamento

| Elemento | Valore |
|---|---|
| Passo | **10 byte** |
| Offset mod 8 | **0/2/4/6** |
| Target | stabile o variabile |
| Terminazione normale | **0** |
| Terminazione anomala | **fuori pagina** |
| Run 125 | **12** |

**PROVEN:** il passo 10 alterna l’allineamento.
**PROVEN:** i run lunghi non sono allineati a 8.
**PROVEN:** la terminazione normale resta `0`.

---

## 6. Provenienza del generatore

| Ricerca | Esito |
|---|---|
| Linker ID nei metadati | **assente** |
| Versione generatore | **assente** |
| Firma linkers | **assente** |
| Pattern condiviso | **18 provider AMD** |
| Stessa struttura T6 | **SÌ** |

**PROVEN:** nessun identificatore di versione.
**PROVEN:** pattern condiviso tra provider AMD.
**UNPROVEN:** il generatore responsabile.

---

## 7. H3

| Ipotesi | Stato | Evidenza |
|---|---|---|
| 8×10 è una firma speciale | **CONTRADETTA** | 24 run ≥8; 18 normali |
| Il linker ha sbagliato l’ultimo record | **UNPROVEN** | nessun errore dimostrato |
| Il linker non ha rispettato il page-end | **INDIZIARIA** | 2/24 run OOB |
| Il linker ha generato una coda incompleta | **INDIZIARIA** | ultimo `next` non azzerato |

**PROVEN:** 8×10 non è speciale.
**PROVEN:** H3 “errore dell’ultimo record” non è dimostrata.
**INDIZIARIO:** page-end non rispettato.

---

## 8. H2/H3/H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H2** | distanza + bound | **SUPPORTATA** | run normali; 2 OOB al page-end |
| **H3** | linker error | **UNPROVEN / indiziaria** | 18 run normali; 2 OOB |
| **H5** | loader rifiuta | **UNPROVEN** | nessun loader/trace |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |

**PROVEN:** H2 resta la spiegazione più semplice.
**PROVEN:** H3 non è supportata come firma delle 8 transizioni.
**UNPROVEN:** H5/H8.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Coda isolata di 8? | **NO — run 88/66** |
| Run ≥8 globali | **24** |
| Run normali `next=0` | **18** |
| Run OOB | **2** |
| 8×10 speciale? | **NO** |
| Target/T6 | **identici, shift 0xC000** |
| H3 “ultimo record errato” | **UNPROVEN** |
| H3 “page-end non rispettato” | **INDIZIARIA** |
| H2 | **SUPPORTATA** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le ultime 8 transizioni non sono una coda isolata: sono la parte finale di run di 88/66 `next=10`. Nel globale ci sono 24 run ≥8, 18 terminano `next=0` e solo 2 sono OOB. La sequenza 8×10 non è speciale; H3 “linker error” resta UNPROVEN, mentre “page-end non rispettato” è indiziaria. H2 resta la spiegazione più semplice. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,25 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
