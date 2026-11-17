# T27 — AGENT-AMD — OOB CONTRACT VS RUNTIME

**Scope:** stabilire se le 2 anomalie violano il contratto strutturale del formato chained-fixup AMD o sono una particolarità legittima del loader Apple; ricostruire il contratto dai metadati disponibili; confrontare le 2 OOB con le 18 catene lunghe corrette; analizzare `next=10`, page-bound e dimensione minima; cercare controlli pagina nei binari.

**Modalità:** sola lettura; metadati, matrice 24 run, simboli/stringhe BootKC, disassemblaggio mirato; nessuna modifica, patch, build o download.

**Esito:** il contratto locale **non documenta** una regola esplicita di page-bound per il formato 11. L’invariante osservato è però netto: **tutti** gli slot correnti e **123/124** successori stanno nella pagina; solo i 2 terminali no. La validità strutturale è **condizionata al page-bound**; il comportamento runtime resta **UNPROVEN**. **H2 SUPPORTATA**; **H3 INDIZIARIA**; **H5/H8 UNPROVEN**. T27 resta **OPEN**.

---

## 1. Contratto ricostruito dai metadati

| Elemento | Valore | Evidenza |
|---|---|---|
| `pointer_format` | **11** | `LC_DYLD_CHAINED_FIXUPS` |
| `page_size` | **0x1000** | starts record |
| `page_count` | **5370 / 37** | starts record |
| `page_start` | **< page_size** | tutte le pagine |
| Slot | **8 byte** | walk |
| `next` | **byte distance** | scale test |
| Terminatore | **0** | 3.826 catene |
| Page-bound esplicito | **NO** | nessun header locale |
| Formato 11 nei loader locali | **NO** | macho/Stela |

**PROVEN:** il contratto osservato usa slot da 8 byte e `next` in byte.
**PROVEN:** il page-bound esplicito non è documentato localmente.
**PROVEN:** non esistono loader locali del formato 11.

---

## 2. Invariante osservato

| Elemento | Valore |
|---|---:|
| Slot correnti fuori pagina | **0** |
| Successori interni fuori pagina | **0** |
| Successori terminali fuori pagina | **2** |
| `next=10` totali | **2.244** |
| `next=10` OOB | **2** |
| Catene normali | **3.826** |

**PROVEN:** lo slot corrente è sempre dentro pagina.
**PROVEN:** solo 2 successori sono fuori pagina.
**PROVEN:** l’invariante “slot interamente nella pagina” vale per tutti tranne 2.

---

## 3. Le 2 OOB vs le 18 lunghe corrette

| Elemento | 2 OOB | 18 corrette |
|---|---|---|
| Next finale | **10** | **0** |
| Residuo dopo slot | **8 / 4** | **0 / 2 / 76 / …** |
| Successore | **fuori pagina** | **nessuno** |
| Page-start | `0x698` / `0x0` | varie |
| Segment offset | 4542464 / 811008 | vari |
| Run length | **88 / 66** | **33–125** |
| Target/T6 | **identici** | **identici** |

**PROVEN:** le OOB non hanno page-start o segment offset comune.
**PROVEN:** non sono le uniche vicine al page-end.
**PROVEN:** l’unica differenza è il `next` finale.

---

## 4. `next=10`, page-bound, 8 byte

| Test | Esito |
|---|---|
| `off+8<=page_end` | **124/124** |
| `off+10+8<=page_end` | **123/124** |
| Violazioni | **2** |
| Residuo successore | **-2 / -6** |
| Page-bound documentato | **NO** |
| Page-bound osservato | **SÌ, implicito** |

**PROVEN:** il record corrente entra sempre.
**PROVEN:** il successore non entra in 2 casi.
**PROVEN:** il page-bound è implicito nell’invariante, non documentato.

---

## 5. Ricerca nei binari

| Ricerca | Esito |
|---|---|
| Simboli `fixup_value` | **assenti** |
| Simboli `chained` | **assenti** |
| Stringhe `chained fixup` | **assenti** |
| Page-bound in `readPrelinkedExtensions` | **nessuno** |
| Disassemblaggio mirato | **simboli lldb corrotti** |
| Controllo pagina equivalente | **non trovato** |

**PROVEN:** BootKC non espone un loader chained.
**PROVEN:** il disassemblaggio noto non mostra page-bound.
**LIMITE:** il symbol table BootKC ha offset invalidi; il lookup lldb fallisce.
**UNPROVEN:** un controllo pagina in codice non simbolizzato.

---

## 6. Evidenza di accettazione/rifiuto

| Evidenza | Esito |
|---|---|
| Boot/trace | **assente** |
| Log loader | **assente** |
| Test runtime | **assente** |
| Accettazione provata | **NO** |
| Rifiuto provato | **NO** |

**PROVEN:** nessuna evidenza runtime.
**UNPROVEN:** accettazione o rifiuto.

---

## 7. Validità strutturale vs runtime

| Livello | Esito |
|---|---|
| Struttura con page-bound | **2 catene invalide in coda** |
| Struttura con segment-bound | **slot leggibile ma non dichiarato** |
| Contratto locale esplicito | **assente** |
| Particolarità Apple | **UNPROVEN** |
| Runtime | **UNPROVEN** |

**PROVEN:** la validità dipende dalla regola di page-bound.
**PROVEN:** con page-bound, le 2 code sono strutturalmente invalide.
**PROVEN:** senza page-bound, il successore è comunque fuori pagina e non dichiarato.
**UNPROVEN:** la scelta del loader.

---

## 8. H2/H3/H5/H8

| # | Ipotesi | Stato | Evidenza |
|---:|---|---|---|
| **H2** | distanza + bound | **SUPPORTATA** | 2.244 distanze; 2 OOB |
| **H3** | linker error | **INDIZIARIA** | coda non terminata; page-start corretto |
| **H5** | loader rifiuta | **UNPROVEN** | nessun loader/trace |
| **H8** | slot omesso | **UNPROVEN** | nessun conteggio in-band |

**PROVEN:** H2 spiega la geometria.
**PROVEN:** H3 resta indiziaria.
**UNPROVEN:** H5/H8.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| Page-bound documentato? | **NO** |
| Page-bound osservato? | **SÌ, implicito** |
| Slot correnti fuori pagina | **0** |
| Successori fuori pagina | **2** |
| Struttura invalida con page-bound | **SÌ, 2 code** |
| Particolarità Apple | **UNPROVEN** |
| Runtime | **UNPROVEN** |
| H2 | **SUPPORTATA** |
| H3 | **INDIZIARIA** |
| H5/H8 | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il contratto locale non documenta esplicitamente il page-bound, ma l’invariante osservato è che ogni slot sta nella pagina: tutti i 124 slot correnti e 123/124 successori lo rispettano; solo 2 code lo violano. Con page-bound le 2 catene sono strutturalmente invalide; senza page-bound il successore resta fuori pagina e non dichiarato. Una particolarità legittima del loader Apple non è provata. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,25 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna scrittura/patch/build/download.
