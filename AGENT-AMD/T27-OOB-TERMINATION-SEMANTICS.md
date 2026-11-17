# T27 — AGENT-AMD — OOB TERMINATION SEMANTICS

**Scope:** verificare se `next=10` negli ultimi slot è una continuazione intenzionale oltre pagina o un errore di terminazione; analizzare i 4 casi con `next` finale 988/20/28/252; confrontare le 2 OOB con terminazioni `next=0` a residuo 0/2; verificare il successore teorico OOB; cercare regole documentate del formato 11.

**Modalità:** sola lettura; walk dei 4 successori, confronto con page-start e pagina successiva; nessuna modifica, patch, build o download.

**Esito:** i 4 `next` finali 988/20/28/252 sono **distanze byte valide**: i successori sono dentro pagina e terminano `next=0`. I 2 successori OOB sono **fuori pagina**, non coincidono con page-start e non sono record validi. Non c’è evidenza di continuazione intenzionale oltre pagina; l’errore di terminazione resta **INDIZIARIO**. **H2 SUPPORTATA**; **H3 INDIZIARIA**; **H5/H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. I 4 casi con `next` finale diverso

| Provider | Pag | End | Next | Successor | Succ raw | Succ next | Walk | Ultimo | Esito |
|---|---:|---:|---:|---:|---|---:|---:|---:|---|
| X4100HWLibs | 1331 | `0x83C` | **988** | `0xC18` | `0x40000042090210` | 8 | 8 | `0xCF0` | **next0** |
| X6000Framebuffer | 47 | `0xB6C` | **20** | `0xB80` | `0x4000004BFFF7D5` | 8 | 2 | `0xB88` | **next0** |
| X6200HWLibs | 3771 | `0x1CC` | **28** | `0x1E8` | `0x4000004EEF9018` | 8 | 162 | `0x900` | **next0** |
| X6300HWLibs | 2561 | `0x1EC` | **252** | `0x2E8` | `0x80000050ED9330` | 16 | 4 | `0x318` | **next0** |

**PROVEN:** tutti i successori sono dentro pagina.
**PROVEN:** tutti terminano `next=0`.
**PROVEN:** `next` è una distanza byte per valori arbitrari.
**PROVEN:** non esiste una regola “solo 0/10”.

---

## 2. Successore teorico OOB

| Provider | Ultimo | Next | Successore | Finestra 8B | Next | Target | Page-start | Next page raw |
|---|---:|---:|---:|---|---:|---:|---:|---|
| X5400HWLibs | `0xFF0` | 10 | `0xFFA` | `0x48CA6426` | **0** | `0x8CA6426` | **NO** | `0x48CA68DA02050000` |
| AMDSupport | `0xFF4` | 10 | `0xFFE` | `0x53BB9D10` | **0** | `0x13BB9D10` | **NO** | `0x50000000053BB` |

**PROVEN:** la finestra 8B è dentro il segmento.
**PROVEN:** la finestra attraversa il bordo pagina.
**PROVEN:** non coincide con una page-start.
**PROVEN:** non coincide con il raw della pagina successiva.
**PROVEN:** è una copia shiftata di byte vicini.

---

## 3. OOB vs `next=0` a residuo 0/2

| Provider | End | Next | Residuo | Esito |
|---|---:|---:|---:|---|
| X4000HWLibs | `0xFF8` | **0** | **0** | **next0** |
| X5200HWLibs | `0xFF6` | **0** | **2** | **next0** |
| X6200HWLibs | `0xFF6` | **0** | **2** | **next0** |
| X6300HWLibs | `0xFF8` | **0** | **0** | **next0** |
| **X5400HWLibs** | **`0xFF0`** | **10** | **8** | **OOB** |
| **AMDSupport** | **`0xFF4`** | **10** | **4** | **OOB** |

**PROVEN:** altre run arrivano a 0/2 byte dal bordo e terminano `0`.
**PROVEN:** le OOB hanno più residuo (8/4) ma `next=10`.
**PROVEN:** l’OOB non dipende dal residuo minimo.

---

## 4. Correlazioni

| Variabile | OOB | Normali |
|---|---|---|
| Next finale | **10** | **0** |
| Residuo | **8 / 4** | **0 / 2 / 76 / …** |
| Run length | **88 / 66** | **33–125** |
| Page-start | **0x698 / 0x0** | varie |
| Segment offset | **4542464 / 811008** | vari |
| Pagina successiva | **0x4 / 0x8** | varie |
| Target/T6 | **identici** | **identici** |

**PROVEN:** nessuna correlazione esclusiva oltre `next=10`.
**PROVEN:** lunghezza e residuo non sono predittivi.

---

## 5. Continuazione intenzionale oltre pagina?

| Test | Esito |
|---|---|
| Successore in pagina | **NO** |
| Successore page-start | **NO** |
| Successore = raw pagina successiva | **NO** |
| Successore record valido | **NO** |
| Next del successore | **0** |
| Continuazione intenzionale | **CONTRADETTA** |

**PROVEN:** il successore non è un record dichiarato.
**PROVEN:** non è la pagina successiva.
**PROVEN:** non c’è evidenza di continuazione intenzionale.

---

## 6. Regole documentate formato 11

| Fonte | Presenza | Regola `next=10` |
|---|---|---|
| `fixup-chains.h` | **NO** | **nessuna** |
| Stela | **NO formato 11** | **nessuna** |
| hao-runtime | **NO formato 11** | **nessuna** |
| QEMU/XNU/ld64 | **NO** | **nessuna** |
| Documentazione AMD | **NO** | **nessuna** |

**PROVEN:** nessuna regola locale documenta `next=10`.
**PROVEN:** nessuna terminazione speciale.

---

## 7. H2/H3/H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H2** | distanza + bound | **SUPPORTATA** | 4 next arbitrari validi; 2 OOB |
| **H3** | terminazione errata | **INDIZIARIA** | successore OOB non valido; nessun next0 |
| **H3** | continuazione intenzionale | **CONTRADETTA** | successore non page-start/record |
| **H5** | loader rifiuta | **UNPROVEN** | nessun loader/trace |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |

**PROVEN:** H2 è l’unica semantica compatibile.
**PROVEN:** H3 “continuazione” è contraddetta.
**INDIZIARIO:** H3 “terminazione errata”.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| 4 next 988/20/28/252 | **distanze valide** |
| Successori | **dentro pagina, next0** |
| OOB successore | **fuori pagina** |
| OOB page-start | **NO** |
| OOB record valido | **NO** |
| Continuazione intenzionale | **NO** |
| Terminazione errata | **INDIZIARIA** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5/H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i `next` 988/20/28/252 sono distanze byte valide e i loro successori terminano `next=0`. I successori OOB sono fuori pagina, non sono page-start e non coincidono con la pagina successiva. Non c’è evidenza di continuazione intenzionale oltre pagina; una terminazione errata resta indiziaria. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,25 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
