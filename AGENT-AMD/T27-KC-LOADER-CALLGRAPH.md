# T27 — AGENT-AMD — KC LOADER CALLGRAPH

**Scope:** ricostruire il percorso `KLDBootstrap::readPrelinkedExtensions` → `PE_get_kc_*`; cercare chiamanti/chiamati, xref, fixup e pointer format 11; distinguere codice presente, simboli senza corpo e componenti mancanti.

**Modalità:** sola lettura; `nm`, parsing Mach-O, scansione diretta delle chiamate `E8 rel32` in `__TEXT_EXEC`; `otool`/`dwarfdump` come controllo.

**Esito:** `readStartupExtensions` (`0xCE8610`) chiama `PE_get_kc_header` e `readPrelinkedExtensions` (`0xCE87B0`). `readPrelinkedExtensions` chiama **15 volte 11 funzioni OSKext**, **nessun** `PE_get_kc_base_pointers`, `slide`, `format`, `baseaddress` o `vp`. **Nessun** riferimento a `fixup_value`, pointer format 11 o loader chained. T27 resta **OPEN**.

---

## 1. Simboli

| Simbolo | Indirizzo | Tipo | Corpo |
|---|---|---:|---|
| `KLDBootstrap::readStartupExtensions` | `0xFFFFFF8000CE8610` | **S** | **presente** |
| `KLDBootstrap::readPrelinkedExtensions` | `0xFFFFFF8000CE87B0` | **S** | **presente** |
| `KLDBootstrap::readBooterExtensions` | `0xFFFFFF8000CE8A00` | **S** | **non analizzato** |
| `_PE_get_kc_header` | `0xFFFFFF8000B68930` | **T** | **non disassemblato** |
| `_PE_get_kc_base_pointers` | `0xFFFFFF8000B68A70` | **T** | **non disassemblato** |
| `_PE_get_kc_slide` | `0xFFFFFF8000B68A80` | **T** | **non disassemblato** |
| `_PE_get_kc_baseaddress` | `0xFFFFFF8000B68B20` | **T** | **non disassemblato** |
| `_PE_get_kc_format` | `0xFFFFFF8000B68B60` | **T** | **non disassemblato** |
| `_PE_get_kc_vp` | `0xFFFFFF8000B689B0` | **T** | **non disassemblato** |
| `fixup_value` | — | — | **assente** |

**PROVEN:** `readStartupExtensions` e `readPrelinkedExtensions` hanno corpo.
**PROVEN:** gli accessor `PE_get_kc_*` sono simboli `T`.
**UNPROVEN:** il corpo/disassembly degli accessor.

---

## 2. Callgraph diretto

| Caller | Call site | Callee |
|---|---:|---|
| `readStartupExtensions` | `0xCE8659` | `_PE_get_kc_header` |
| `readStartupExtensions` | `0xCE8686` | `readPrelinkedExtensions` |
| `readStartupExtensions` | `0xCE8697` | `_PE_get_kc_header` |
| `readStartupExtensions` | `0xCE86A9` | `readPrelinkedExtensions` |

**PROVEN:** 2 chiamate a `PE_get_kc_header`, 2 a `readPrelinkedExtensions`.
**PROVEN:** nessuna chiamata diretta agli altri `PE_get_kc_*`.

---

## 3. Chiamati di `readPrelinkedExtensions`

| Call site | Callee |
|---|---:|
| `0xCE87E3` | `OSKextLog` |
| `0xCE87F9` | `getsectbynamefromheader` |
| `0xCE8806` | `OSUnserializeXML` |
| `0xCE8824` | `OSMetaClassBase::safeMetaCast` |
| `0xCE883C` | `OSKext::validateKCFileSetUUID` |
| `0xCE88A3` | `OSKextLog` |
| `0xCE88C9` | `OSKext::addKextsFromKextCollection` |
| `0xCE891D` | `memmove` |
| `0xCE892C` | `uuid_unparse_upper` |
| `0xCE8948` | `OSKext::registerDeferredKextCollection` |
| `0xCE8961` | `OSKextLog` |
| `0xCE897F` | `OSKextLog` |
| `0xCE8991` | `getsegbyname` |
| `0xCE89A3` | `ml_static_mfree` |
| `0xCE89BA` | `OSKextLog` |

**PROVEN:** 15 call site, 11 funzioni uniche.
**PROVEN:** nessuna chiamata diretta a `PE_get_kc_base_pointers`, `slide`, `format`, `baseaddress`, `vp`.
**PROVEN:** nessuna chiamata diretta a `fixup_value` o a un loader chained.

---

## 4. Accessor non collegati

| Accessor | Chiamanti diretti | Stato |
|---|---:|---|
| `PE_get_kc_header` | **2** | **collegato** |
| `PE_get_kc_base_pointers` | **0** | **non collegato** |
| `PE_get_kc_slide` | **0** | **non collegato** |
| `PE_get_kc_format` | **0** | **non collegato** |
| `PE_get_kc_baseaddress` | **0** | **non collegato** |
| `PE_get_kc_vp` | **0** | **non collegato** |

**PROVEN:** solo `PE_get_kc_header` è chiamato direttamente.
**PROVEN:** gli altri accessor non compaiono nel callgraph diretto.
**UNPROVEN:** chiamate indirette.

---

## 5. Fixup e pointer format 11

| Elemento | Trovato | Grado |
|---|---|---|
| `fixup_value` | **NO** | **assente** |
| `kc_kind2index` | **NO** | **assente** |
| `kernel_collection_slide` | **NO** | **assente** |
| `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` | **NO** | **assente** |
| chiamata a loader chained | **NO** | **non trovata** |
| riferimento indiretto a fixup | **NO** | **non trovato** |

**PROVEN:** nessun elemento nel callgraph diretto.
**UNPROVEN:** riferimenti indiretti non simbolizzati.

---

## 6. Codice, simboli, componenti

| Categoria | Evidenza |
|---|---|
| **Codice presente** | `readStartupExtensions`, `readPrelinkedExtensions` |
| **Simboli senza corpo disassemblato** | `PE_get_kc_*` |
| **Componenti mancanti** | `fixup_value`, loop chained, pointer format 11 |
| **Disassembly** | `otool -tvV` **non emette istruzioni** sul KC |
| **DWARF** | `dwarfdump --lookup` **nessuna informazione** |

**PROVEN:** il callgraph è ricostruito da simboli e `E8 rel32`.
**PROVEN:** non c’è un percorso loader chained diretto.
**UNPROVEN:** il comportamento runtime e le chiamate indirette.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| `readStartupExtensions` → `readPrelinkedExtensions`? | **SÌ — 2 call site** |
| `readPrelinkedExtensions` → `PE_get_kc_*`? | **NO** |
| `PE_get_kc_base_pointers` chiamato? | **NO** |
| `fixup_value` presente? | **NO** |
| Loader chained nel callgraph? | **NO** |
| Chiamate indirette? | **NON ANALIZZATE** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il percorso noto è `readStartupExtensions → PE_get_kc_header / readPrelinkedExtensions`; `readPrelinkedExtensions` carica le collection tramite `OSKext` e **non** chiama gli accessor `base_pointers/slide/format`. Non esiste un percorso diretto verso `fixup_value` o un loader chained. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
