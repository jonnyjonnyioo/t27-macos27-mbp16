# T27 — AGENT-AMD — KC INDIRECT CALL ANALYSIS

**Scope:** verificare se il caricamento delle Kernel Collections raggiunge indirettamente `PE_get_kc_*` o un percorso chained fixups; analizzare le 15 call site di `readPrelinkedExtensions`, `addKextsFromKextCollection` e `registerDeferredKextCollection`; cercare vtable, function pointer e dispatch IOKit.

**Modalità:** sola lettura; `nm`, parsing Mach-O, scansione delle forme `FF /2` (`call r/m64`) e dei call diretti `E8 rel32`; `objdump`/`otool` come controllo.

**Esito:** `readPrelinkedExtensions` contiene **7 call indirette**, `addKextsFromKextCollection` **33** (1 + 32), `registerDeferredKextCollection` **8**: **48 totali, 0 con destinazione risolta**. Nessuna è RIP-relative: tutte usano registro/base (`mod1`/`mod2`), quindi vtable o function pointer. **Nessun** collegamento indiretto a `PE_get_kc_base_pointers`, `format` o `slide` è provato. T27 resta **OPEN**.

---

## 1. Call dirette note

| Caller | Call site | Callee |
|---|---:|---|
| `readStartupExtensions` | `0xCE8659` | `PE_get_kc_header` |
| `readStartupExtensions` | `0xCE8686` | `readPrelinkedExtensions` |
| `readStartupExtensions` | `0xCE8697` | `PE_get_kc_header` |
| `readStartupExtensions` | `0xCE86A9` | `readPrelinkedExtensions` |

**PROVEN:** solo `PE_get_kc_header` è raggiunto direttamente.
**PROVEN:** `PE_get_kc_base_pointers`, `slide`, `format`, `baseaddress`, `vp` hanno **0** chiamanti diretti.

---

## 2. Call indirette per funzione

| Funzione | Intervallo | Indirette | RIP-relative | Risolte a PE |
|---|---|---:|---:|---:|
| `readPrelinkedExtensions` | `0xCE87B0–0xCE8A00` | **7** | **0** | **0** |
| `addKextsFromKextCollection` (1) | `0xA33E10–0xA33E60` | **1** | **0** | **0** |
| `addKextsFromKextCollection` (2) | `0xA33E60–0xA34A20` | **32** | **0** | **0** |
| `registerDeferredKextCollection` | `0xA43020–0xA431B0` | **8** | **0** | **0** |
| **Totale** | — | **48** | **0** | **0** |

**PROVEN:** 48 call indirette.
**PROVEN:** nessuna ha destinazione risolta.
**PROVEN:** nessuna è RIP-relative.

---

## 3. Forme delle indirette

| Funzione | `mod1` (base+disp8) | `mod2` (base+disp32) | `mod0 rm5` (RIP) |
|---|---:|---:|---:|
| `readPrelinkedExtensions` | **3** | **4** | **0** |
| `addKextsFromKextCollection` (1) | **1** | **0** | **0** |
| `addKextsFromKextCollection` (2) | **8** | **24** | **0** |
| `registerDeferredKextCollection` | **5** | **3** | **0** |

**PROVEN:** tutte le indirette usano registro/base.
**INFERRED:** sono compatibili con vtable/function pointer.
**UNPROVEN:** la destinazione effettiva.

---

## 4. Registri e argomenti

| Funzione | Firma | Argomenti |
|---|---|---|
| `readPrelinkedExtensions` | `(mach_header_64 *, kc_kind)` | **rdi, rsi** |
| `addKextsFromKextCollection` | `(mach_header_64 *, OSDictionary *, const char *, OSSharedPtr<OSData> &, kc_kind)` | **rdi, rsi, rdx, rcx, r8** |
| `registerDeferredKextCollection` | `(mach_header_64 *, OSSharedPtr<OSObject> &, kc_kind)` | **rdi, rsi, rdx** |

**PROVEN:** le firme sono ricavate dai simboli demangled.
**UNPROVEN:** i registri effettivi alle 15 call site, perché manca il disassembly.

---

## 5. Vtable, function pointer, IOKit

| Elemento | Evidenza | Grado |
|---|---|---|
| vtable/function pointer | **48 call `mod1`/`mod2`** | **INFERRED** |
| IOKit dispatch | **nessun simbolo** | **UNPROVEN** |
| destinazione PE | **0 risolte** | **UNPROVEN** |
| destinazione chained | **0 risolte** | **UNPROVEN** |

**PROVEN:** non c’è una destinazione PE risolta.
**INFERRED:** le forme sono compatibili con dispatch indiretto.
**UNPROVEN:** quale vtable/funzione venga chiamata.

---

## 6. Percorsi alternativi

| Percorso | Esito |
|---|---|
| Call dirette a `PE_get_kc_base_pointers` | **0** |
| Call dirette a `PE_get_kc_format` | **0** |
| Call dirette a `PE_get_kc_slide` | **0** |
| Call indirette risolte a PE | **0** |
| Chiamate a `fixup_value` | **0** |
| Riferimenti a pointer format 11 | **0** |

**PROVEN:** fuori dal callgraph diretto non c’è un percorso PE identificato.
**UNPROVEN:** percorsi indiretti non risolti.

---

## 7. Limiti

| Limite | Effetto |
|---|---|
| `objdump -h` mostra `__text` size **0** | **nessun disassembly** |
| `otool -tvV` non emette istruzioni | **nessun disassembly** |
| `capstone` assente | **nessun decoding** |
| sezioni reali assenti | **solo scansione byte** |
| 48 indirette senza destinazione | **nessuna prova** |

**PROVEN:** senza disassembly non si risolvono le 48 indirette.
**UNPROVEN:** il percorso indiretto verso PE o chained.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Indirette totali | **48** |
| Destinazioni risolte | **0** |
| Indirette verso PE | **0 provate** |
| Indirette verso chained | **0 provate** |
| Vtable/function pointer | **INFERRED** |
| IOKit dispatch | **UNPROVEN** |
| Percorso alternativo PE | **NO identificato** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** le 48 call indirette sono tutte `mod1`/`mod2`, compatibili con vtable o function pointer, ma **nessuna destinazione è risolta**. Non si può dichiarare un percorso indiretto verso `PE_get_kc_base_pointers`, `format`, `slide` o un loader chained. `objdump`/`otool` non disassemblano il KC e `capstone` è assente. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
