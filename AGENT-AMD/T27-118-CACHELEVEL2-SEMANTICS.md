# T27 — AGENT-AMD — 118 CACHELEVEL 2 SEMANTICS

**Scope:** ricostruire e classificare i 118 slot `cacheLevel=2` riportati nel Prompt 49; identificare strutture proprietarie, riferimenti e validità dei target; confrontarli con i 12 raw.

**Modalità:** sola lettura; parsing `LC_DYLD_CHAINED_FIXUPS`, segmenti, sezioni e datasize. Nessuna modifica, build o boot.

**Esito:** i **118 non sono validati**. Il conteggio del Prompt 49 è un **artefatto del parser**: i `page_count` letti non corrispondono ai segmenti e la somma degli start supera il `datasize`. **Nessuno** dei 118 è utilizzabile per una classificazione semantica o per una prova di raggiungibilità. I 12 raw restano separati e **0/12** ha target in un segmento valido X4000/X4000HWLibs. T27 resta **OPEN**.

---

## 1. Perché il 118 va ritirato

| Provider | Segmento | Pagine reali | `page_count` letto | Coerente? |
|---|---|---:|---:|---|
| X4000 | `__TEXT` | **254** | **4** | **NO** |
| X4000 | `__DATA` | **56** | **140** | **NO** |
| X4000 | `__DATA_CONST` | **5** | **34** | **NO** |
| X4000HWLibs | `__DATA` | **2.818** | **5.664** | **NO** |
| X4000HWLibs | `__DATA_CONST` | **1** | **26** | **NO** |

**PROVEN:** i `page_count` non corrispondono alla dimensione dei segmenti.
**PROVEN:** per X4000 la somma degli start dichiarati è **178**; a 2 byte per start sono **356 B**, superiori al `datasize` **226 B**.
**PROVEN:** il `datasize` non può contenere gli start dichiarati.
**Conclusione:** il parser ha letto `seg_info` o `page_start` con un offset/base errato; **43+75=118** non è un dato valido.

---

## 2. Cosa resta valido

| Dato | Valore | Stato |
|---|---|---|
| 172 provider con `LC_DYLD_CHAINED_FIXUPS` | **172/172** | **PROVEN** |
| X4000 standalone con fixup | **NO** | **PROVEN** |
| X4000HWLibs standalone con fixup | **NO** | **PROVEN** |
| X4000 fixup dataoff/size | `0x15FF820E` / **226** | **PROVEN** |
| X4000HWLibs fixup dataoff/size | `0x15FF835C` / **5742** | **PROVEN** |
| 12 target in catene X4000/X4000HWLibs | **0/12** | **PROVEN** |
| 12 target in segmenti X4000/X4000HWLibs | **0/12** | **PROVEN** |
| 0x8B1 provider | **X5200HWLibs** | **PROVEN** |

**PROVEN:** i fixup esistono; il problema è la loro decodifica, non l’assenza.
**PROVEN:** i 12 target non sono in catena e non cadono nei segmenti dei due provider.

---

## 3. Strutture proprietarie

| Struttura | Slot attribuiti | Stato |
|---|---:|---|
| vtable | **0** | **UNPROVEN** |
| GOT | **0** | **UNPROVEN** |
| callback | **0** | **UNPROVEN** |
| tabelle | **0** | **UNPROVEN** |
| dati | **0** | **UNPROVEN** |

**PROVEN:** senza slot validi non si può attribuire alcuna struttura.
**UNPROVEN:** l’esistenza di 118 slot e la loro natura.

---

## 4. Riferimenti e istruzioni

| Verifica | Esito |
|---|---|
| Xref da `__TEXT` a slot | **non eseguibile** |
| Slot in `__DATA`/`__DATA_CONST` | **non validati** |
| Istruzioni che usano gli slot | **non identificate** |
| Validità target nei segmenti | **0/12** |

**PROVEN:** i 12 target non ricadono nei segmenti X4000/X4000HWLibs.
**UNPROVEN:** qualsiasi xref verso i 118.

---

## 5. Confronto con i 12 raw

| Gruppo | Quantità | Slot validi | Target in segmento | Semantica |
|---|---:|---:|---:|---|
| 118 dichiarati | 118 | **0** | **0** | **ritirati** |
| 12 raw | 12 | **0** | **0** | **raw** |
| 9 esterni | 9 | **0** | **0** | **raw** |
| 3 non esterni | 3 | **0** | **0** | **UNPROVEN** |

**PROVEN:** i 12 raw non diventano slot per confronto con i 118.
**PROVEN:** **0/12** target è in un segmento valido.
**UNPROVEN:** i 3 non esterni.

---

## 6. Rischio

| Condizione | Conseguenza |
|---|---|
| 118 non esistono come slot | **nessun effetto** |
| 12 raw non referenziati | **nessun effetto** |
| Fixup reali con `basePointers[2]=0` | **invalid cache level** |
| Catene non decodificate | **rischio non quantificabile** |

**PROVEN:** il rischio da 118 non è calcolabile.
**UNPROVEN:** raggiungibilità e residuo.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| 118 slot validi? | **NO — ritirati** |
| Page count coerenti? | **NO** |
| Datasize sufficiente? | **NO** |
| Strutture proprietarie? | **0 identificate** |
| Xref? | **0** |
| Target 12 in segmenti? | **NO — 0/12** |
| 0x8B1? | **X5200HWLibs** |
| Raggiungibilità? | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i **118** non sono una base valida; il parser ha letto male `seg_info`/`page_start` e il conteggio va **ritirato**. Non ci sono slot, strutture, xref o target validi da classificare. I **12 raw** restano separati e **0/12** cade nei segmenti X4000/X4000HWLibs. `0x8B1` resta **X5200HWLibs**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
