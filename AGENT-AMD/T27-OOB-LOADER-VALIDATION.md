# T27 — AGENT-AMD — OOB LOADER VALIDATION

**Scope:** verificare se il loader valida il puntatore successivo prima di leggerlo; cercare sorgenti, simboli e disassembly di dyld/XNU per `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`; confrontare i due OOB con il donor T6.

**Modalità:** sola lettura; ricerca testuale, simboli e stringhe in root-full, T16 e BootKC. Nessuna modifica, boot o simulazione.

**Esito:** **non c’è codice locale** del loader `LC_DYLD_CHAINED_FIXUPS` né `fixup_value`. L’unica fonte XNU disponibile è `vm_shared_region.c`, che valida `page_starts` per lo **slide della shared region** (v2–v5), **non** per questo formato. BootKC ha `_collection_base_pointers` come **dato**, ma **nessun** simbolo `fixup_value`. La validazione del successore prima della lettura resta **UNPROVEN**. T6 ripete **1 OOB per provider sulle stesse pagine**, con offset/raw diversi. T27 resta **OPEN**.

---

## 1. Sorgenti locali

| File | Trovato | Pertinenza |
|---|---|---|
| `fixup-chains.h` | **NO** | **assente** |
| `kcformat.c` | **NO** | **assente** |
| `kcgen` | **NO** | **assente** |
| dyld source | **NO** | **assente** |
| `vm_shared_region.c` | **SÌ** | **slide v2–v5, non chained fixups** |

**PROVEN:** non c’è una copia locale del loader chained.
**PROVEN:** `vm_shared_region.c` non implementa `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`.
**UNPROVEN:** il comportamento del loader reale.

---

## 2. Simboli BootKC

| Simbolo/stringa | Presente | Nota |
|---|---|---|
| `_collection_base_pointers` | **SÌ** | **dato**, non funzione |
| `fixup_value` | **NO** | **assente** |
| `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` | **NO** | **assente** |
| `chained` | **5 stringhe** | **manifest/dir-stats**, non fixup |
| `page_start` | **7 stringhe** | `vm_shared_region_slide_sanity_check_v3/v4/v5` |
| `page_size` | **15 stringhe** | **shared region**, non chained |

**PROVEN:** i simboli `page_start`/`page_size` appartengono allo **slide shared region**.
**PROVEN:** non c’è un simbolo del loader chained.
**UNPROVEN:** se il loader sia stripped o assente.

---

## 3. Controlli XNU disponibili

| Controllo | File | Applicabile? |
|---|---|---|
| `page_starts_count` | `vm_shared_region.c` | **NO — slide v2–v5** |
| `pageIndex >= count` | `vm_shared_region.c` | **NO** |
| `page_start_offset` | `vm_shared_region.c` | **NO** |
| `next`/page boundary chained | **assente** | **NO** |
| `fixup_value` | **assente** | **NO** |

**PROVEN:** i controlli XNU locali sono per un formato diverso.
**UNPROVEN:** la validazione del successore chained.

---

## 4. T6: ricorrenza

| Provider | OOB | Pagina | Ultimo T6 | Raw T6 | Ultimo 25G342 | Raw 25G342 |
|---|---:|---:|---|---:|---|---|
| X5400HWLibs | **1** | **3475** | `0x9C6CFF0` | `0x050000048C9A426` | `0x9C78FF0` | `0x050000048CA6426` |
| AMDSupport | **1** | **33** | `0x13C07FF4` | `0x050000053BAD9E0` | `0x13C13FF4` | `0x050000053BB99E0` |

**PROVEN:** T6 ha 1 OOB per provider.
**PROVEN:** le pagine sono le stesse.
**PROVEN:** offset e raw sono diversi.
**INFERRED:** l’anomalia è sistematica nella struttura, non identica byte-per-byte.

---

## 5. Validazione del successore

| Domanda | Risposta | Grado |
|---|---|---|
| Il loader legge `next`? | **sì, per definizione** | **PROVEN** |
| Controlla `next+8 <= page_end`? | **non dimostrato** | **UNPROVEN** |
| Interrompe la catena? | **non dimostrato** | **UNPROVEN** |
| Ignora il successore? | **non dimostrato** | **UNPROVEN** |
| Rifiuta l’intera catena? | **non dimostrato** | **UNPROVEN** |

**PROVEN:** il successore è OOB.
**UNPROVEN:** la decisione del loader.

---

## 6. Limite probatorio

| Elemento mancante | Impatto |
|---|---|
| `fixup-chains.h` | **nessuna definizione locale** |
| `fixup_value` | **nessun loop da analizzare** |
| disassembly del loader | **nessuna verifica** |
| simbolo del loader | **nessun punto di ingresso** |
| runtime trace | **nessuna osservazione** |

**PROVEN:** senza questi elementi non si può classificare stop/ignore/reject.
**UNPROVEN:** l’impatto runtime.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Sorgente loader locale? | **NO** |
| `fixup_value` locale? | **NO** |
| XNU locale pertinente? | **NO — shared region** |
| Validazione `next` provata? | **NO** |
| T6 stesso pattern? | **SÌ — stesse pagine, raw diversi** |
| OOB sistematico? | **INFERRED** |
| Impatto runtime? | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** non esiste codice locale del loader chained; `vm_shared_region.c` valida un formato diverso e BootKC non espone `fixup_value`. La validazione del successore prima della lettura resta **UNPROVEN**. T6 ripete 1 OOB per provider sulle stesse pagine, con offset/raw diversi: l’anomalia è **sistematica nella struttura**, non identica. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna simulazione/modifica/build/boot.
