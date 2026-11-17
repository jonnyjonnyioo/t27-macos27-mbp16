# T27 — AGENT-AMD — CACHELEVEL 2 SLOT RECONSTRUCTION

**Scope:** recuperare i 12 indirizzi sorgente esatti dei puntatori auth con `cacheLevel=2`; rianalizzare le catene DYLD (`page_start`, `next`, slot, segmento); registrare provider, UUID, indirizzo KC-relativo, sezione e offset.

**Modalità:** sola lettura; parsing SystemKC, `LC_FILESET_ENTRY`, scan delle parole encoded negli intervalli dei provider, confronto con i report 41/43/46/47. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** **0/12** slot sorgente sono recuperabili con certezza. I report 41/43/46/47 **non contengono gli slot**. La rianalisi dei provider trova **più occorrenze** per quasi tutti i target e **zero** per `0x8B1` in X4000HWLibs; `0x8B1` compare invece in **X5200HWLibs**. Quindi le parole encoded **non sono slot univoci** e la fonte dichiarata per `0x8B1` è **contraddetta**. Reachability resta **UNPROVEN**. T27 resta **OPEN**.

---

## 1. Perché gli slot mancano

| Report | Slot | Target | Raw |
|---|---:|---:|---:|
| `T27-AUTH-TARGET-RESOLUTION` | **NO** | **SÌ** | **NO** |
| `T27-AUTH-POINTER-COMPARATIVE-ANALYSIS` | **NO** | **SÌ** | **NO** |
| `T27-CACHELEVEL2-INVALID-POINTERS` | **NO** | **SÌ** | **esempi** |
| `T27-CACHELEVEL2-REACHABILITY` | **NO** | **SÌ** | **esempi** |

**PROVEN:** nessun report contiene i 12 offset sorgente.
**PROVEN:** senza offset non si può attribuire `page_start`, `next` o sezione.

---

## 2. Catene DYLD

| Provider | `LC_DYLD_CHAINED_FIXUPS` | `page_start`/`next` | Slot auth certi |
|---|---|---|---|
| X4000 | **non nel binario standalone** | **non disponibili** | **0** |
| X4000HWLibs | **non nel binario standalone** | **non disponibili** | **0** |
| X6100 | **sì, già analizzato** | **sì** | **1** noto |

**PROVEN:** per X4000/X4000HWLibs non c’è una tabella `LC_DYLD_CHAINED_FIXUPS` standalone da cui leggere `page_start` e `next`.
**PROVEN:** i 56 auth non sono stati ricavati da una catena X4000 verificata; sono parole encoded trovate nei dati.
**UNPROVEN:** che le 12 parole siano slot di fixup.

---

## 3. Conteggio occorrenze

| Target | Provider dichiarato | Occorrenze nel range | Primo offset | Univoco? |
|---:|---|---:|---:|---|
| `0x3F8C007F` | X4000 | **365** | `0x3B6300` | **NO** |
| `0x3E8203F2` | X4000 | **2** | `0x3BD000` | **NO** |
| `0x334FE856` | X4000HWLibs | **2** | `0x7BC010` | **NO** |
| `0x1780000E` | X4000HWLibs | **3** | `0x9A4530` | **NO** |
| `0x20A` | X4000HWLibs | **4** | `0x9B3B08` | **NO** |
| `0x4A6` | X4000HWLibs | **3** | `0xA50700` | **NO** |
| `0x16400001` | X4000HWLibs | **97** | `0x9B3AD0` | **NO** |
| `0x8B1` | X4000HWLibs | **0** | — | **NO — assente** |
| `0x1A000002` | X4000HWLibs | **85** | `0x9B7DD8` | **NO** |

**PROVEN:** **8/9** target hanno più di una occorrenza; **0x8B1** non compare nel provider dichiarato.
**PROVEN:** il primo offset non è lo slot: è solo la prima occorrenza.
**UNPROVEN:** quale occorrenza, se esiste, sia la slot.

---

## 4. `0x8B1`

| Verifica | Esito |
|---|---|
| In X4000HWLibs | **0 occorrenze** |
| In X5200HWLibs | **2 occorrenze** (`0x7EA5330`, `0xA1FE360`) |
| Fonte dichiarata | **X4000HWLibs** |
| Fonte compatibile | **X5200HWLibs** |
| Conclusione | **fonte dichiarata contraddetta** |

**PROVEN:** `0x8B1` non è in X4000HWLibs.
**PROVEN:** compare in X5200HWLibs.
**UNPROVEN:** che sia una slot di fixup o un semplice valore dati.

---

## 5. Registro dei 9 esterni

| Target | Provider | UUID | Offset esempio | Sezione | Stato |
|---:|---|---|---:|---|---|
| `0x3F8C007F` | X4000 | `5D0B64FE-9944-3382-A0FA-26D1CAC4BC01` | `0x3B6300` | **?** | **candidato** |
| `0x3E8203F2` | X4000 | `5D0B64FE-9944-3382-A0FA-26D1CAC4BC01` | `0x3BD000` | **?** | **candidato** |
| `0x334FE856` | X4000HWLibs | `DFD77453-7CFD-3F72-8BFE-779582EA4E73` | `0x7BC010` | **?** | **candidato** |
| `0x1780000E` | X4000HWLibs | `DFD77453-7CFD-3F72-8BFE-779582EA4E73` | `0x9A4530` | **?** | **candidato** |
| `0x20A` | X4000HWLibs | `DFD77453-7CFD-3F72-8BFE-779582EA4E73` | `0x9B3B08` | **?** | **candidato** |
| `0x4A6` | X4000HWLibs | `DFD77453-7CFD-3F72-8BFE-779582EA4E73` | `0xA50700` | **?** | **candidato** |
| `0x16400001` | X4000HWLibs | `DFD77453-7CFD-3F72-8BFE-779582EA4E73` | `0x9B3AD0` | **?** | **candidato** |
| `0x8B1` | X5200HWLibs | **non risolto** | `0x7EA5330` | **?** | **contraddetto** |
| `0x1A000002` | X4000HWLibs | `DFD77453-7CFD-3F72-8BFE-779582EA4E73` | `0x9B7DD8` | **?** | **candidato** |

**PROVEN:** gli offset sono **file offset**, non indirizzi VM; la sezione non è risolta.
**PROVEN:** **1/9** è contraddetto; **8/9** restano candidati non univoci.
**UNPROVEN:** sezione e raggiungibilità.

---

## 6. I 3 non esterni

| Gruppo | Auth | Slot | Stato |
|---|---:|---:|---|
| Esterni | 9 | **0** | **UNPROVEN** |
| Non esterni | 3 | **0** | **UNPROVEN** |
| **Totale** | **12** | **0** | **UNPROVEN** |

**PROVEN:** i 3 non esterni non sono identificati nei report.
**UNPROVEN:** provider, target e slot.

---

## 7. Rischio runtime

| Condizione | Conseguenza |
|---|---|
| Slot non percorso | **nessun effetto** |
| Slot percorso con `basePointers[2]=0` | **fixup rifiutato / stop** |
| Slot in area dati non referenziata | **nessun effetto** |
| Slot in tabella attiva | **rischio** |

**PROVEN:** `basePointers[2]` non è inizializzato.
**UNPROVEN:** quale delle condizioni si verifichi.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| 12 slot esatti? | **NO — 0/12** |
| `page_start`/`next` per X4000? | **NO** |
| Occorrenze univoche? | **NO** |
| `0x8B1` in X4000HWLibs? | **NO — 0** |
| `0x8B1` in X5200? | **SÌ — 2** |
| Reachability? | **UNPROVEN** |
| Rischio? | **condizionato** |
| X6100 coinvolto? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** gli slot **non sono recuperabili** dai report né da una catena X4000/X4000HWLibs inesistente. Le occorrenze sono multiple e `0x8B1` contraddice la fonte dichiarata. **0/12** slot certi; reachability **UNPROVEN**; rischio **condizionato**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
