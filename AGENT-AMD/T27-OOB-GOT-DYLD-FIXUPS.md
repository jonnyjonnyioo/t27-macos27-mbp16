# T27 — AGENT-AMD — GOT DYLD FIXUPS

**Scope:** determinare se il loader trasforma le destinazioni NX delle GOT in indirizzi eseguibili; analizzare `LC_DYLD_CHAINED_FIXUPS`/`LC_DYLD_INFO`, formato e percorso di `0x241E8` e adiacenti; confrontare 10 entry `__REGION19` con 10 entry eseguibili.

**Modalità:** sola lettura; SystemKC; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **REBASE-ONLY**. `imports_count = 0`; nessun bind. Il loader applica solo lo slide: `0x9A7640` resta dati NX. La branch stub `0x1016E` è **staticamente invalida** come chiamata di funzione; il comportamento runtime resta **UNPROVEN**. T27 **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf8b8340c987a98e33b039622e62b0a304fce9df799356f7f7d05ca840` |
| Report 144 | `8d5420d64ad1aa1acf4c160d3807f132b50849c9fcfee1b7cf2160262d5ce137` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Load command

| Elemento | Valore |
|---|---|
| Comando | `LC_DYLD_CHAINED_FIXUPS` (`0x80000034`) |
| File offset comando | `0x50` |
| Data offset | `0x1601B656` |
| Data size | `0x874` |
| `LC_DYLD_INFO` | **assente** |

**PROVEN:** il metadata dei fixup è presente.
**PROVEN:** non c’è la coppia rebase/bind classica di `LC_DYLD_INFO`.

---

## 3. Header fixup

| Campo | Valore |
|---|---:|
| version | `0` |
| starts_offset | `28` |
| imports_offset | `2164` |
| symbols_offset | `2164` |
| imports_count | `0` |
| imports_format | `1` |
| symbols_format | `0` |

**PROVEN:** `imports_count = 0`.
**PROVEN:** nessun import/bind.
**PROVEN:** restano solo rebase.

---

## 4. `__BRANCH_GOTS`

| Campo | Valore |
|---|---:|
| Segment index | `3` |
| Starts offset | `0x82C` |
| Page size | `0x1000` |
| Pointer format | `11` |
| Segment offset | `0x24000` |
| Page count | `4` |
| Page starts | `0, 0, 0, 0` |

**PROVEN:** `__BRANCH_GOTS` è coperto dai fixup.
**PROVEN:** quattro pagine, catene dall’offset 0.
**PROVEN:** formato 11 (kernel-cache x86_64).

---

## 5. Decodifica di 0x241E8

| Campo | Valore |
|---|---:|
| Qword | `0x400000009A7640` |
| Target | `0x9A7640` |
| Next | `8` |
| Auth | `0` |
| Bind | **NO** |
| Tipo | **rebase** |

**PROVEN:** è un rebase, non un bind.
**PROVEN:** il target resta `0x9A7640`.
**PROVEN:** il loader non lo trasforma in codice.

---

## 6. Dieci entry `__REGION19`

| GOT | Target | Next | Auth | Segmento | Prot |
|---:|---:|---:|---:|---|---:|
| `0x24000` | `0x988550` | `8` | `0` | `__REGION19` | `0x3` |
| `0x24008` | `0x988330` | `8` | `0` | `__REGION19` | `0x3` |
| `0x24010` | `0x988F10` | `8` | `0` | `__REGION19` | `0x3` |
| `0x24028` | `0x988570` | `8` | `0` | `__REGION19` | `0x3` |
| `0x24030` | `0x988310` | `8` | `0` | `__REGION19` | `0x3` |
| `0x24038` | `0x988500` | `8` | `0` | `__REGION19` | `0x3` |
| `0x24050` | `0x9E59B0` | `8` | `0` | `__REGION19` | `0x3` |
| `0x24098` | `0x9D6860` | `8` | `0` | `__REGION19` | `0x3` |
| `0x240B0` | `0x9D2480` | `8` | `0` | `__REGION19` | `0x3` |
| `0x240B8` | `0x9CDBE0` | `8` | `0` | `__REGION19` | `0x3` |

**PROVEN:** tutte rebase.
**PROVEN:** tutte NX (`0x3`).

---

## 7. Dieci entry eseguibili

| GOT | Target | Next | Auth | Segmento | Prot |
|---:|---:|---:|---:|---|---:|
| `0x24018` | `0x3CCEB0` | `8` | `0` | `__REGION12` | `0x5` |
| `0x24020` | `0x3CD1E0` | `8` | `0` | `__REGION12` | `0x5` |
| `0x24040` | `0x91E6A0` | `8` | `0` | `__REGION18` | `0x5` |
| `0x24048` | `0x91E650` | `8` | `0` | `__REGION18` | `0x5` |
| `0x24088` | `0x91C3E0` | `8` | `0` | `__REGION18` | `0x5` |
| `0x24090` | `0x91CAD0` | `8` | `0` | `__REGION18` | `0x5` |
| `0x240A0` | `0x924160` | `8` | `0` | `__REGION18` | `0x5` |
| `0x240A8` | `0x91C540` | `8` | `0` | `__REGION18` | `0x5` |
| `0x240C8` | `0x91FAE0` | `8` | `0` | `__REGION18` | `0x5` |
| `0x240D8` | `0x94AD00` | `8` | `0` | `__REGION18` | `0x5` |

**PROVEN:** tutte rebase.
**PROVEN:** i target sono RX (`0x5`).
**PROVEN:** il loader non distingue NX/RX nel fixup: applica lo slide.

---

## 8. Bilancio

| Categoria | Count |
|---|---:|
| GOT totali | `12288` |
| Zero | `10619` |
| Non-zero | `1669` |
| `__REGION19` | `266` |
| `__REGION12` | `434` |
| `__REGION18` | `400` |
| `__REGION25` | `353` |

**PROVEN:** la GOT è mista: target NX e RX.
**PROVEN:** 10/10 NX e 10/10 RX sono rebase.
**UNPROVEN:** il comportamento runtime.

---

## 9. Verdetto

| Domanda | Risposta |
|---|---|
| Loader trasforma NX in RX? | **NO** |
| Bind? | **NO** |
| Rebase? | **SÌ** |
| `0x9A7640` post-fixup | dati + slide |
| Branch stub valida | **NO** statico |
| Runtime | **UNPROVEN** |

**PROVEN:** il fixup non cambia la protezione.
**PROVEN:** il target resta NX.
**REFUTED:** trasformazione in codice eseguibile.

---

## 10. STOP

| Criterio | Esito |
|---|---|
| Metadata fixup | **SÌ** |
| Formato ricostruito | **SÌ** |
| Valore post-fixup | **NO** |
| Runtime | **UNPROVEN** |
| Spazio >10 GiB | **SÌ** |
| Modifiche | **NO** |

**PROVEN:** il criterio di stop è raggiunto.
**PROVEN:** non è possibile proseguire staticamente con certezza.

---

## 11. Conclusione

| Domanda | Risposta |
|---|---|
| `LC_DYLD_CHAINED_FIXUPS` | presente |
| `imports_count` | `0` |
| Formato | `11` |
| GOT | `0x24000`, 4 pagine |
| `0x241E8` | rebase `0x9A7640` |
| NX → RX | **NO** |
| Branch stub | **staticamente invalida** |
| Caller Wrangler | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il loader **non** trasforma le destinazioni NX in indirizzi eseguibili. SystemKC ha `LC_DYLD_CHAINED_FIXUPS`, ma `imports_count = 0`: non ci sono bind, solo rebase. La GOT `0x241E8` contiene `0x400000009A7640`, decodificato come target `0x9A7640`, `next = 8`, `auth = 0`, **rebase**; il valore post-fixup è il target più lo slide, non un nuovo codice. Le 10 entry `__REGION19` e le 10 entry `__REGION12/18` sono tutte rebase; il loader non cambia la protezione. Quindi `0x9A7640` resta dati NX e la branch stub `0x1016E` è **staticamente invalida** come chiamata di funzione. Il comportamento runtime resta **UNPROVEN**: non simulato. STOP; **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈11,9 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
