# T27 — AGENT-AMD — BASEPOINTERS[1] RUNTIME

**Scope:** determinare se `basePointers[1]` è non nullo durante il caricamento di X5400 e AMDSupport, ricostruire assegnazione/inizializzazione/validazione, esaminare le fileset entry e separare condizioni statiche e runtime.

**Modalità:** sola lettura; BootKC 26B131, simboli, disassemblaggio, sorgente Apple `kcformat.c`, SystemKC; nessun boot, trace, modifica, build, download o cancellazione.

**Esito:** **PROVEN staticamente** che `basePointers[1]` è assegnato da `PE_set_kc_header(KCKindPageable, ...)` con `lowest_vmaddr + slide` e che `OSKext::mapKCFileSet` chiama quel setter prima del caricamento dei kext. **PROVEN** che nel BootKC il simbolo `_collection_base_pointers` è a `0xffffff80013aa6f0` e i suoi quattro slot sono **zero nel file**. **UNPROVEN** che a runtime l’assegnazione avvenga prima del caricamento dei due kext e che i due kext vengano caricati. Entrambi usano `cacheLevel=1` e condividono lo stesso `basePointers[1]`; non ci sono condizioni separate note. T27 resta **OPEN**.

## CORREZIONE (Prompt 88)

`KCKindPageable` vale **2**, non 1. Al call site `0xa3302f`, `bl = (kind == 2)` e `type = bl ^ 3`: per `kind=2`, `bl=1` e `type=2` = **KCKindPageable**. La frase “per `bl=2` dà 1” è errata; la conclusione Pageable resta valida. Il tipo 1 a `0x4c6aba` è **KCKindPrimary**. Vedi `T27-OOB-PAGEABLE-ORDER.md`.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| BootKC x86_64 | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |
| Report 84 corrente | `cf67fadc1a97c9261ed4984508b9b1eb6449a3255a29a0ba5998cc9fccdad41f` |
| Correzione 85 | `39a48d1a18057297070f6b356bf44c294783d5c139a63553e86cd437287d318a` |
| Report 86 | `4eb3ac9969066e270dffdd82a5a6465c193d58ab25e155f0ce18e3dfba82b1eb` |

**PROVEN:** gli artefatti analizzati sono quelli indicati.
**PROVEN:** BootKC è la build 26B131.

---

## 2. Simbolo e contenuto statico

| Elemento | Valore |
|---|---|
| Simbolo | `_collection_base_pointers` |
| Tipo | **S** (dato globale) |
| VA | `0xffffff80013aa6f0` |
| File offset | `0x11aa6f0` |
| Slot `[0]` | **0x0** |
| Slot `[1]` | **0x0** |
| Slot `[2]` | **0x0** |
| Slot `[3]` | **0x0** |

**PROVEN:** il simbolo è un dato, non una funzione.
**PROVEN:** nel file tutti e quattro gli slot sono zero.
**PROVEN:** `basePointers[1]` non è serializzato nel BootKC.

---

## 3. Assegnazione in `kcformat.c`

```c
typedef enum kc_index {
    primary_kc_index  = 0,
    pageable_kc_index = 1,
    auxiliary_kc_index = 3,
} kc_index_t;

void *collection_base_pointers[KCNumKinds] = {};

MARK_AS_FIXUP_TEXT void
PE_set_kc_header(kc_kind_t type, kernel_mach_header_t *header, uintptr_t slide)
{
    kc_index_t i = kc_kind2index(type);
    assert(!collection_base_pointers[i]);
    assert(!collection_mach_headers[i]);
    collection_mach_headers[i] = header;
    collection_slide[i] = slide;
    // calcola lowest_vmaddr
    collection_base_pointers[i] =
        (void *)((uintptr_t)lowest_vmaddr + slide);
    assert((uint64_t)(uintptr_t)collection_base_pointers[i] != ~0ULL);
}
```

**PROVEN:** `KCKindPageable` mappa `pageable_kc_index = 1`.
**PROVEN:** `PE_set_kc_header` assegna `collection_base_pointers[1]`.
**PROVEN:** il valore è `lowest_vmaddr + slide`, non `__TEXT`.
**PROVEN:** l’assegnazione richiede che lo slot sia zero.
**PROVEN:** `PE_reset_kc_header(KCKindPageable)` può riazzerarlo.

---

## 4. Call site del setter

| Caller | Call site | Callee |
|---|---|---:|
| `OSKext::mapKCFileSet` | `0xffffff8000a3302f` | `_PE_set_kc_header` |
| funzione a `0xffffff80004c6aba` | `0xffffff80004c6aba` | `_PE_set_kc_header` |

Disassemblaggio del call site:

```text
0xffffff8000a33022: movq   (%r15), %rsi        ; mach_header
0xffffff8000a33025: movq   (%r12), %rdx        ; slide
0xffffff8000a33029: movzbl %bl, %edi
0xffffff8000a3302c: xorl   $0x3, %edi          ; tipo KC
0xffffff8000a3302f: callq  0xffffff8000b68770  ; PE_set_kc_header
```

**PROVEN:** `OSKext::mapKCFileSet` chiama `PE_set_kc_header`.
**PROVEN:** il tipo è derivato da `bl ^ 3`; con `kind=2` si ha `bl=1` e `type=2 = KCKindPageable`.
**PROVEN:** header e slide sono passati dal contesto della KC.
**PROVEN:** il chiamante Pageable passa `kind=2`; `mapKCFileSet` calcola `bl=(kind==2)=1` e `type=2`.
**PROVEN:** `KCKindPrimary=1`, `KCKindPageable=2`, `KCKindAuxiliary=3`.

---

## 4b. Caller diretti del loader

| Ricerca | Esito |
|---|---|
| `E8 rel32` in `__TEXT_EXEC` verso `0x4c5a20` | **1 solo** |
| Call site | `0xffffff8000a29629` |
| Funzione contenente | `OSKext::loadExecutable` (`0xa294e0`) |
| Altri chiamanti diretti | **nessuno** |
| Chiamanti indiretti | **non osservati** |

**PROVEN:** `_i386_slide_individual_kext` ha un solo chiamante diretto nel `__TEXT_EXEC`.
**PROVEN:** il chiamante è `OSKext::loadExecutable`.
**PROVEN:** `i386_slide_kext_collection_mh_addrs` è un callee diverso (`0x4c61e0`), non un chiamante del loader individuale.
**UNPROVEN:** chiamanti indiretti non codificati come `E8`.

---

## 5. Ordine statico

```text
OSKext::mapKCFileSet
  -> PE_set_kc_header(KCKindPageable, header, slide)
     -> collection_base_pointers[1] = lowest_vmaddr + slide

OSKext::loadExecutable
  -> _i386_slide_individual_kext
     -> kernel_collection_slide
        -> fixup_value(basePointers[1])
```

**PROVEN:** il setter e il loader sono due funzioni distinte.
**PROVEN:** il loader usa `collection_base_pointers` globale.
**PROVEN:** il setter può rendere `[1]` non nullo.
**UNPROVEN:** che l’ordine reale sia setter prima del loader per X5400/AMDSupport.

---

## 6. Fileset entry X5400 e AMDSupport

| Provider | `LC_FILESET_ENTRY` | Entry vmaddr | Segmento | `cacheLevel` |
|---|---|---|---:|---|---:|
| X5400 | **SÌ** | `0x8A90000` | `__DATA` | **1** |
| AMDSupport | **SÌ** | `0x13B2C000` | `__DATA` | **1** |

**PROVEN:** entrambi sono kext fileset del SystemKC.
**PROVEN:** entrambi usano `cacheLevel=1`.
**PROVEN:** entrambi richiedono `basePointers[1]` non nullo.
**PROVEN:** non ci sono condizioni separate note.
**UNPROVEN:** che il boot li carichi e che `[1]` sia già valorizzato.

---

## 7. Validazione e reset

| Funzione | Effetto |
|---|---|
| `PE_set_kc_header` | **setta `[1]` se era zero** |
| `PE_set_kc_header_and_base` | **setta header e base** |
| `PE_reset_kc_header` | **azzera `[1]` per KC non primary** |
| `PE_get_kc_base_pointers` | **espone l’array** |
| `assert(!collection_base_pointers[i])` | **impedisce doppio set** |
| `assert(base != ~0ULL)` | **esclude il valore massimo** |

**PROVEN:** la scrittura è protetta da assert.
**PROVEN:** il reset può azzerare la base.
**UNPROVEN:** se un reset avvenga tra setter e loader.

---

## 8. Evidenze runtime preesistenti

| Evidenza | Esito |
|---|---|
| Boot log | **assente** |
| `ioreg`/DeviceTree | **assente** |
| Trace di `PE_set_kc_header` | **assente** |
| Trace di `OSKext::loadExecutable` | **assente** |
| Configurazione serializzata | **assente** |
| Valore runtime di `[1]` | **UNPROVEN** |

**PROVEN:** non ci sono trace o log preesistenti.
**UNPROVEN:** il valore runtime.

---

## 9. Condizioni per i due kext

| Condizione | X5400 | AMDSupport |
|---|---|---|
| `cacheLevel=1` | **SÌ** | **SÌ** |
| `basePointers[1]` non nullo | **necessario** | **necessario** |
| Stesso array globale | **SÌ** | **SÌ** |
| Setter chiamato | **SÌ staticamente** | **SÌ staticamente** |
| Ordine setter→loader | **UNPROVEN** | **UNPROVEN** |
| Kext caricato | **UNPROVEN** | **UNPROVEN** |

**PROVEN:** la condizione di base è comune.
**PROVEN:** non ci sono differenze note tra i due.
**UNPROVEN:** l’ordine runtime e il caricamento effettivo.

---

## 10. Conclusione

| Domanda | Risposta |
|---|---|
| `_collection_base_pointers` è dato | **SÌ** |
| Slot `[1]` nel file | **0x0** |
| `PE_set_kc_header` assegna `[1]` | **SÌ** |
| Base = lowest_vmaddr + slide | **SÌ** |
| `OSKext::mapKCFileSet` chiama il setter | **SÌ** |
| `OSKext::loadExecutable` chiama il loader | **SÌ** |
| Ordine runtime setter→loader | **UNPROVEN** |
| `[1]` non nullo a runtime | **UNPROVEN** |
| X5400/AMDSupport stessi requisiti | **SÌ** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il file non contiene alcuna base: `_collection_base_pointers` è a `0xffffff80013aa6f0` e i quattro slot sono zero. La base `[1]` nasce a runtime in `PE_set_kc_header(KCKindPageable, ...)` come `lowest_vmaddr + slide`; `OSKext::mapKCFileSet` chiama quel setter, mentre `OSKext::loadExecutable` chiama `_i386_slide_individual_kext`, che usa l’array globale. X5400 e AMDSupport hanno entrambi `cacheLevel=1` e condividono lo stesso requisito; non ci sono condizioni separate note. Resta **UNPROVEN** che a runtime il setter preceda il loader e che i due kext vengano caricati. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,20 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
