# T27 — AGENT-AMD — BOOTKC LOADER DISASSEMBLY

**Scope:** ricostruire le istruzioni di `readPrelinkedExtensions` e `addKextsFromKextCollection`; verificare offset, chiamate, registri e riferimenti a `PE_get_kc_*`; usare solo strumenti installati.

**Modalità:** sola lettura; mapping `__TEXT_EXEC` (`vmaddr 0xFFFFFF80002E8000`, `fileoff 0xE8000`), disassemblaggio `lldb`, controllo `otool`/`objdump`; nessuna installazione, estrazione, modifica o boot.

**Esito:** `lldb` disassembla correttamente `readPrelinkedExtensions`. La funzione legge `__PRELINK_INFO,__info`, deserializza il plist, valida l’UUID e chiama `addKextsFromKextCollection` con `__PRELINK_TEXT`. **Nessun** riferimento diretto a `PE_get_kc_*` o a un loader chained. Le 7 call indirette sono vtable (`0x140`, `0x148`, `0x178`, `0x28`) e restano **non risolte**. T27 resta **OPEN**.

---

## 1. Mapping

| Elemento | Valore |
|---|---|
| `__TEXT_EXEC` vmaddr | **0xFFFFFF80002E8000** |
| `__TEXT_EXEC` fileoff | **0xE8000** |
| `readPrelinkedExtensions` vmaddr | **0xFFFFFF8000CE87B0** |
| `readPrelinkedExtensions` fileoff | **0xAE87B0** |
| `addKextsFromKextCollection` (1) vmaddr | **0xFFFFFF8000A33E10** |
| `addKextsFromKextCollection` (1) fileoff | **0x833E10** |
| `addKextsFromKextCollection` (2) vmaddr | **0xFFFFFF8000A33E60** |
| `addKextsFromKextCollection` (2) fileoff | **0x833E60** |

**PROVEN:** gli offset cadono in `__TEXT_EXEC` (`0xE8000–0xAFC000`).
**PROVEN:** i prologhi sono `push rbp; mov rbp, rsp`.

---

## 2. Strumenti

| Strumento | Esito |
|---|---|
| `otool` | **nessuna sezione codice** |
| `objdump -h` | **3 sezioni, nessuna codice** |
| `objdump -b binary` | **opzione non supportata** |
| `llvm-objdump` | **assente** |
| `gobjdump` | **assente** |
| `capstone` | **assente** |
| **`lldb`** | **funziona** |

**PROVEN:** `lldb` produce istruzioni coerenti.
**PROVEN:** nessuno strumento è stato installato.
**PROVEN:** `lldb` segnala segmenti fuori file e simboli invalidi, ma il disassemblaggio di `readPrelinkedExtensions` è coerente con le chiamate note.

---

## 3. `readPrelinkedExtensions` — prologo e argomenti

| Istruzione | Indirizzo | Effetto |
|---|---:|---|
| `push rbp; mov rbp, rsp` | `0xCE87B0` | frame |
| `push r15; push r14; push rbx` | `0xCE87B4` | salvataggi |
| `sub rsp, 0x18` | `0xCE87B9` | stack |
| `mov edx, r14d` | `0xCE87BD` | **r14d = kc_kind** |
| `mov rsi, rbx` | `0xCE87C0` | **rbx = mach_header** |
| `movq $0, -0x28(%rbp)` | `0xCE87C3` | out = NULL |

**PROVEN:** `rsi` è usato come `mach_header_64 *`.
**PROVEN:** `edx` è usato come `kc_kind`.
**PROVEN:** `rdi` non viene conservato.

---

## 4. `readPrelinkedExtensions` — sequenza

| Indirizzo | Istruzione | Significato |
|---:|---|---|
| `0xCE87E3` | `call OSKextLog` | log “Starting from prelinked kernel.” |
| `0xCE87F9` | `call getsectbynamefromheader` | **`__PRELINK_INFO,__info`** |
| `0xCE8806` | `call OSUnserializeXML` | deserializza il plist |
| `0xCE8824` | `call safeMetaCast` | cast a `OSDictionary` |
| `0xCE882E` | `cmpl $3, %r14d` | **kind == 3?** |
| `0xCE883C` | `call validateKCFileSetUUID` | valida AuxKC |
| `0xCE88C9` | `call addKextsFromKextCollection` | **`__PRELINK_TEXT`** |
| `0xCE892C` | `call uuid_unparse_upper` | UUID |
| `0xCE8948` | `call registerDeferredKextCollection` | **kind 3** |
| `0xCE8991` | `call getsegbyname` | **`__PRELINK_TEXT`** |
| `0xCE89A3` | `call ml_static_mfree` | libera |
| `0xCE89F7` | `call 0xFFFFFF8000CF9C60` | **funzione non nominata** |

**PROVEN:** la funzione carica il plist di `__PRELINK_INFO`.
**PROVEN:** passa `__PRELINK_TEXT` ad `addKextsFromKextCollection`.
**PROVEN:** non chiama `PE_get_kc_base_pointers`, `slide`, `format`, `baseaddress` o `vp`.

---

## 5. Registri alla chiamata `addKextsFromKextCollection`

| Registro | Valore | Ruolo |
|---|---|---|
| `rdi` | `rbx` | **mach_header_64 *** |
| `rsi` | `rax` | **OSDictionary *** |
| `rdx` | `"__PRELINK_TEXT"` | **segmento** |
| `rcx` | `&out` | **OSSharedPtr<OSData> *** |
| `r8d` | `kind` o **0** | **ultimo argomento** |

**PROVEN:** la chiamata a `0xCE88C9` usa questi cinque argomenti.
**PROVEN:** `r8d = r14d` solo se `mh->filetype == 0xC`, altrimenti **0**.

---

## 6. Call indirette

| Call site | Istruzione | Destinazione |
|---:|---|---|
| `0xCE8861` | `callq *0x148(%rax)` | **vtable + 0x148** |
| `0xCE8873` | `callq *0x148(%rax)` | **vtable + 0x148** |
| `0xCE88EF` | `callq *0x178(%rax)` | **vtable + 0x178** |
| `0xCE88FF` | `callq *0x140(%rax)` | **vtable + 0x140** |
| `0xCE89CB` | `callq *0x28(%rax)` | **vtable + 0x28** |
| `0xCE89DA` | `callq *0x28(%rax)` | **vtable + 0x28** |
| `0xCE89E9` | `callq *0x28(%rax)` | **vtable + 0x28** |

**PROVEN:** 7 call indirette, tutte vtable.
**UNPROVEN:** la destinazione concreta di ciascuna.

---

## 7. `addKextsFromKextCollection`

| Elemento | Valore |
|---|---|
| Prima funzione | `0xA33E10–0xA33E60` |
| Seconda funzione | `0xA33E60–0xA34A20` |
| Call indirette | **33** |
| Call dirette a `PE_get_kc_*` | **0** |
| Call dirette a `fixup_value` | **0** |
| Prologo | `55 48 89 E5…` |

**PROVEN:** il corpo è presente.
**PROVEN:** non ci sono call dirette agli accessor PE.
**UNPROVEN:** le 33 destinazioni indirette.

---

## 8. Riferimenti a `PE_get_kc_*`

| Accessor | Riferimento in `read` | Riferimento in `add` |
|---|---|---|
| `PE_get_kc_header` | **NO** | **NO** |
| `PE_get_kc_base_pointers` | **NO** | **NO** |
| `PE_get_kc_slide` | **NO** | **NO** |
| `PE_get_kc_format` | **NO** | **NO** |
| `PE_get_kc_baseaddress` | **NO** | **NO** |
| `PE_get_kc_vp` | **NO** | **NO** |

**PROVEN:** nessun riferimento diretto.
**UNPROVEN:** riferimenti indiretti via vtable.

---

## 9. Limiti

| Limite | Effetto |
|---|---|
| `lldb` segnala segmenti fuori file | **mapping parziale** |
| simboli invalidi | **nomi non risolti** |
| vtable runtime | **destinazioni ignote** |
| `addKexts` non disassemblata integralmente | **solo call scan** |
| nessun trace runtime | **comportamento non osservato** |

**PROVEN:** il disassemblaggio di `read` è coerente.
**UNPROVEN:** il comportamento runtime e le destinazioni vtable.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| Offset verificati? | **SÌ** |
| `readPrelinkedExtensions` disassemblata? | **SÌ** |
| Chiama `PE_get_kc_*`? | **NO** |
| Chiama un loader chained? | **NO** |
| Call indirette? | **7 vtable, non risolte** |
| `addKexts` presente? | **SÌ** |
| Destinazioni indirette note? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `readPrelinkedExtensions` è disassemblabile e coerente: legge `__PRELINK_INFO`, deserializza il plist, valida l’UUID e passa `__PRELINK_TEXT` ad `addKextsFromKextCollection`. Non chiama gli accessor `PE_get_kc_*` né un loader chained. Le 7 indirette sono vtable e restano non risolute. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna installazione/estrazione/modifica/build/boot.
