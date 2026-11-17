# T27 — AGENT-AMD — OOB `next=10` CORRELATION

**Scope:** confrontare i 246 record X5400HWLibs e i 37 AMDSupport con i metadati; analizzare posizione e distribuzione dei 124 `next=10` per provider; confrontare i 2 terminali con i 122 interni; cercare correlazioni con offset, allineamento, target e pagina successiva.

**Modalità:** sola lettura; walk di tutte le catene dei due provider in target/T6; nessuna modifica, patch, build o download.

**Esito:** **124 `next=10` per provider**, di cui **123 interni con successore in pagina** e **1 terminale**. Tutti gli interni hanno residuo pagina **≥12** e successore dentro la pagina; i 2 terminali hanno residuo **6/2** e successore fuori pagina. Nessun successore coincide con una page-start. L’unica firma dei terminali è **residuo < 8**. **H2 SUPPORTATA**; **H3 INDIZIARIA**; **H5/H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. Record per provider

| Provider | Catene | Segmenti | Slot | Lunghezza min/mediana/max |
|---|---:|---|---:|---|
| X5400HWLibs | **246** | `__DATA` 245, `__DATA_CONST` 1 | **11.238** | **1 / 4 / 503** |
| AMDSupport | **37** | `__DATA` 35, `__DATA_CONST` 2 | **16.387** | **59 / 471 / 504** |
| X5400HWLibs T6 | **246** | identici | **11.238** | identici |
| AMDSupport T6 | **37** | identici | **16.387** | identici |

**PROVEN:** target/T6 hanno gli stessi conteggi e le stesse lunghezze.
**PROVEN:** X5400 ha molte catene corte; AMDSupport ha catene lunghe.

---

## 2. Distribuzione dei 124 `next=10`

| Provider | `next=10` | Interni in pagina | Terminali |
|---|---:|---:|---:|
| X5400HWLibs | **124** | **123** | **1** |
| AMDSupport | **124** | **123** | **1** |

### Offset modulo 8

| Mod 8 | X5400 | AMDSupport |
|---:|---:|---:|
| 0 | 31 | 31 |
| 2 | 31 | 32 |
| 4 | 31 | 31 |
| 6 | 31 | 30 |

**PROVEN:** la distribuzione è uniforme.
**PROVEN:** `next=10` non è legato a un solo allineamento.
**PROVEN:** il passo 10 alterna l’allineamento.

---

## 3. Residuo pagina

| Provider | Sequenza residui | Minimo interno | Terminale |
|---|---|---:|---:|
| X5400HWLibs | 876, 866, …, 16, 6 | **16** | **6** |
| AMDSupport | 652, 642, …, 12, 2 | **12** | **2** |

**PROVEN:** i residui diminuiscono di 10.
**PROVEN:** i 123 interni hanno residuo **≥12**.
**PROVEN:** i 2 terminali hanno residuo **6/2**.
**PROVEN:** solo i terminali hanno residuo **<8**.

---

## 4. Successore

| Provider | Successori dentro pagina | Successori fuori pagina | Successori = page-start |
|---|---:|---:|---:|
| X5400HWLibs | **123** | **1** | **0** |
| AMDSupport | **123** | **1** | **0** |

**PROVEN:** tutti i successori interni sono nella pagina.
**PROVEN:** i 2 terminali sono fuori pagina.
**PROVEN:** nessun successore coincide con una page-start.
**PROVEN:** i successori non sono slot dichiarati.

---

## 5. Terminale vs interno

| Caratteristica | Interni (123) | Terminali (2) |
|---|---|---|
| Residuo ≥8 | **SÌ** | **NO (6/2)** |
| Successore in pagina | **SÌ** | **NO** |
| Successore page-start | **NO** | **NO** |
| Offset mod 8 | 0/2/4/6 | 0/4 |
| Target | variabile | variabile |
| `next` | 10 | 10 |

**PROVEN:** l’unica differenza è il residuo.
**PROVEN:** non c’è una firma di target o allineamento.
**PROVEN:** il terminale è la stessa struttura dell’interno, ma senza spazio per 8 byte.

---

## 6. Target e pagina successiva

| Provider | Terminale target | Successore target | Page-start successiva |
|---|---:|---:|---:|
| X5400HWLibs | `0x8CA6426` | `0x8CA6426` | `0x4` |
| AMDSupport | `0x13BB9D10` | `0x13BB9D10` | `0x8` |

**PROVEN:** la pagina successiva inizia a `0x4`/`0x8`.
**PROVEN:** il successore a `0xFFA`/`0xFFE` non coincide con l’inizio pagina.
**PROVEN:** il successore legge byte di padding e della pagina successiva.

---

## 7. Il parser interpreta male la fine?

| Test | Esito |
|---|---|
| `next` è una distanza? | **SÌ** |
| 123 interni con residuo sufficiente? | **SÌ** |
| Terminali fuori pagina? | **SÌ** |
| Successore è page-start? | **NO** |
| Successore è slot reale? | **NO** |
| Errore di formato del parser? | **NO** |
| Errore di fine catena? | **UNPROVEN** |

**PROVEN:** il parser applica correttamente il limite pagina.
**PROVEN:** il successore non è uno slot dichiarato.
**UNPROVEN:** se il loader kernel usi un limite diverso.

---

## 8. Classificazione H2/H3/H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H2** | distanza + bound | **SUPPORTATA** | `next=10` normale; 123 interni con residuo sufficiente; 2 fuori pagina |
| **H3** | linker/incompletezza | **INDIZIARIA** | ultimo `next` non azzerato; nessun successore reale |
| **H5** | loader rifiuta | **UNPROVEN** | nessun codice/trace |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |

**PROVEN:** H2 spiega la geometria.
**PROVEN:** H3 resta la spiegazione indiziaria della coda.
**UNPROVEN:** H5/H8.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `next=10` per provider | **124** |
| Interni con successore in pagina | **123** |
| Terminali | **1** |
| Residuo terminale | **6 / 2** |
| Successore reale | **NO** |
| Successore page-start | **NO** |
| Firma unica terminale | **residuo <8** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5/H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i 124 `next=10` per provider sono una sequenza regolare con passo 10; 123 interni hanno spazio sufficiente e successore in pagina, mentre i 2 terminali hanno residuo 6/2 e successore fuori pagina. Non esiste una firma di target o allineamento: l’unica differenza è il residuo. Il parser applica correttamente il limite pagina; non è provato che il loader kernel faccia lo stesso. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,25 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
