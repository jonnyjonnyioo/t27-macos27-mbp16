# T27 — AGENT-AMD — 0x9A7640 CLASSIFICATION

**Scope:** stabilire se `0x9A7640`, destinazione della branch stub `0x1016E`, è codice, dati o struttura interna; verificare segmenti, protezioni, offset, finestra di 512 byte, confronto BootKC e xref.

**Modalità:** sola lettura; SystemKC, BootKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **DATA — REGIONE NON ESECUTIVA**. `0x9A7640` cade in `__REGION19` (`maxprot/initprot = 0x3`, RW, NX); `_aRLC_Ucode` è a `0x9A7000` (+`0x640`). Nessuna xref diretta oltre la GOT. La funzione e l’oggetto di `start` restano **UNPROVEN**; T27 **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf8b8340c987a98e33b039622e62b0a304fce9df799356f7f7d05ca840` |
| AMDSupportPart | `849ccf34c3976f6859eee962f2fc829c27061dff8d0b0526a1561d374f3b5cf4` |
| Report 142 | `855009824520c68fc06bce9725ea8029e4476928d0d900d56d4628eb354db0b3` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Segmento e protezione

| Segmento | VM | Size | File | Maxprot | Initprot |
|---|---:|---:|---:|---:|---:|
| `__TEXT` | `0x0` | `0x10000` | `0x0` | `0x1` | `0x1` |
| `__BRANCH_STUBS` | `0x10000` | `0x14000` | `0x10000` | `0x5` | `0x5` |
| `__BRANCH_GOTS` | `0x24000` | `0x18000` | `0x24000` | `0x3` | `0x3` |
| `__REGION19` | `0x984000` | `0xB04000` | `0x984000` | `0x3` | `0x3` |

**PROVEN:** `__REGION19` è RW (`0x3`), **non eseguibile**.
**PROVEN:** `0x9A7640` è dentro `__REGION19`.
**PROVEN:** `__BRANCH_STUBS` è RX (`0x5`), ma il target non lo è.

---

## 3. Finestra SystemKC

| Intervallo | Byte |
|---|---|
| `0x9A7540`–`0x9A7640` | dati, pattern ricorrenti |
| `0x9A7640`–`0x9A7740` | `00 00 91 c4 1f 00 10 25...` |
| `0x9A7740`–`0x9A7840` | `33 00 1c c4 fa ff c0 95...` |

**PROVEN:** nessun prologo di funzione.
**PROVEN:** nessun simbolo di funzione a `0x9A7640`.
**UNPROVEN:** il formato esatto della tabella.

---

## 4. Simbolo vicino

| Simbolo | Indirizzo | Delta |
|---|---:|---:|
| `_aRLC_Ucode` | `0x9A7000` | `+0x640` |
| `_sCapeVerdeGbTileModeTbl` | `0x9A9000` | dopo il target |

**PROVEN:** `_aRLC_Ucode` è una tabella dati.
**PROVEN:** il target è all’interno del suo intervallo.
**UNPROVEN:** se sia ucode, tabella o blob.

---

## 5. Confronto BootKC

| Elemento | SystemKC | BootKC |
|---|---|---|
| VA | `0x9A7640` | `0xFFFFFF80009A7640` |
| Segmento | `__REGION19` | `__TEXT_EXEC` |
| File offset | `0x9A7640` | `0x7A7640` |
| Maxprot | `0x3` | `0x5` |
| Byte | dati | codice |
| Stessa semantica | **NO** | **NO** |

**PROVEN:** gli indirizzi non sono intercambiabili.
**PROVEN:** BootKC è eseguibile, SystemKC no.
**REFUTED:** usare BootKC come prova del target SystemKC.

---

## 6. Xref

| Ricerca | Occorrenze | Posizione |
|---|---:|---|
| `0x9A7640` qword | `0` | — |
| `0x9A7640` dword | `1` | `0x241E8` (GOT) |
| `_aRLC_Ucode` qword | `1` | `0x153F8C28` (LINKEDIT) |
| `_aRLC_Ucode` dword | `1` | `0x153F8C28` (LINKEDIT) |

**PROVEN:** l’unico riferimento al target è la GOT.
**PROVEN:** nessuna xref diretta nel testo.
**UNPROVEN:** xref indirette a runtime.

---

## 7. Verdetto

| Test | Esito |
|---|---|
| Codice eseguibile | **NO** |
| Dati/tabella | **SÌ** |
| Firmware blob | **PROBABILE** |
| Funzione | **NO** |
| Branch stub valida | **UNPROVEN** |
| Oggetto `start` | **UNPROVEN** |

**PROVEN:** il target statico è dati non eseguibili.
**REFUTED:** target come function start.
**UNPROVEN:** relazione runtime con la branch stub.

---

## 8. STOP

| Criterio | Esito |
|---|---|
| Classificazione | **DATA** |
| Eseguibilità | **NO** |
| Funzione finale | **NO** |
| Oggetto `start` | **UNPROVEN** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `0x9A7640` | dati in `__REGION19` |
| Protezione | RW, NX (`0x3`) |
| `_aRLC_Ucode` | `0x9A7000` +`0x640` |
| Codice | **NO** |
| Xref dirette | nessuna oltre GOT |
| BootKC | code, ma namespace diverso |
| Branch stub | `jmp *0x241E8` |
| Target funzione | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `0x9A7640` non è codice. È dentro `__REGION19`, segmento RW con `maxprot/initprot = 0x3` e quindi **non eseguibile**; la finestra di 512 byte è dati, senza prologo né simbolo di funzione, e il simbolo vicino è `_aRLC_Ucode` (`0x9A7000`, +`0x640`). L’unico riferimento al target è la GOT `0x241E8`; non ci sono xref dirette nel testo. In BootKC lo stesso VA relativo è codice in `__TEXT_EXEC`, ma è un namespace diverso e non dimostra nulla su SystemKC. Verdetto: **DATA / blob non eseguibile**, non funzione; la branch stub `0x1016E` resta **UNPROVEN** nella sua semantica runtime. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
