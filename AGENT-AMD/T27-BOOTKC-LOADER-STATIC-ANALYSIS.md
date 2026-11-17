# T27 — AGENT-AMD — BOOTKC LOADER STATIC ANALYSIS

**Scope:** inventariare simboli e stringhe del BootKC su chained fixups, kernel collections e pointer format 11; cercare `kc_kind2index`, `PE_get_kc_base_pointers`, `collection_base_pointers` e funzioni di caricamento; verificare controlli statici su `next`, stride e page boundary.

**Modalità:** sola lettura; `nm`, `strings`, parsing Mach-O; nessuna estrazione, modifica o boot.

**Esito:** BootKC contiene **1 `LC_DYLD_CHAINED_FIXUPS`** (dataoff 67.549.480, size 36.010) e i simboli `_PE_get_kc_base_pointers`, `_PE_get_kc_slide`, `_PE_get_kc_format`, `_PE_get_primary_kc_format`. **Non** contiene `fixup_value`, `kc_kind2index`, `kernel_collection_slide` o `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`. I candidati sono **accessor**, non un loop di fixup; `otool -p` non produce disassembly per il simbolo. Nessun controllo statico su `next`/stride/page boundary è identificato. T27 resta **OPEN**.

---

## 1. BootKC

| Proprietà | Valore |
|---|---|
| Size | **64 MB** |
| `LC_DYLD_CHAINED_FIXUPS` | **1** |
| Command offset | **0x170** |
| Dataoff | **67.549.480** |
| Datasize | **36.010** |
| Simboli `PE_get_kc_*` | **6** |

**PROVEN:** BootKC ha una tabella chained.
**PROVEN:** la tabella è **dati**, non codice loader.

---

## 2. Simboli

| Simbolo | Indirizzo | Ruolo |
|---|---|---:|
| `_PE_get_kc_base_pointers` | `0xFFFFFF8000B68A70` | **accessor** |
| `_PE_get_kc_header` | `0xFFFFFF8000B68930` | **accessor** |
| `_PE_get_kc_baseaddress` | `0xFFFFFF8000B68B20` | **accessor** |
| `_PE_get_kc_slide` | `0xFFFFFF8000B68A80` | **accessor** |
| `_PE_get_kc_format` | `0xFFFFFF8000B68B60` | **accessor** |
| `_PE_get_primary_kc_format` | `0xFFFFFF8000B68AF0` | **accessor** |
| `_collection_base_pointers` | `0xFFFFFF80013AA6F0` | **dato globale** |
| `KLDBootstrap::readPrelinkedExtensions` | `0xFFFFFF8000CE87B0` | **bootstrap** |

**PROVEN:** `_collection_base_pointers` è un **dato**, non una funzione.
**PROVEN:** i `PE_get_kc_*` sono accessor.
**UNPROVEN:** il loop di fixup.

---

## 3. Stringhe

| Stringa | Occorrenze | Nota |
|---|---:|---|
| `PE_get_kc_base_pointers` | **1** | simbolo |
| `collection_base_pointers` | **1** | simbolo |
| `fixup_value` | **0** | **assente** |
| `kc_kind2index` | **0** | **assente** |
| `kernel_collection_slide` | **0** | **assente** |
| `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` | **0** | **assente** |
| `next` | **387** | **generico** |
| `stride` | **2** | **generico** |
| `page boundary` | **2** | **generico** |

**PROVEN:** non c’è una stringa del loader chained.
**PROVEN:** `next`/`stride`/`page boundary` sono generici e non associati.
**UNPROVEN:** un loader non simbolizzato.

---

## 4. Candidati e disassembly

| Candidato | Disassembly | Esito |
|---|---|---|
| `_PE_get_kc_base_pointers` | `otool -tvV -p` → **nessuna istruzione** | **non verificato** |
| `_PE_get_kc_slide` | **non disassemblato** | **non verificato** |
| `_PE_get_kc_format` | **non disassemblato** | **non verificato** |
| `KLDBootstrap::readPrelinkedExtensions` | **non disassemblato** | **non verificato** |

**PROVEN:** `otool -p` non ha prodotto istruzioni per `_PE_get_kc_base_pointers`.
**PROVEN:** nessun loop di fixup è stato identificato.
**UNPROVEN:** il comportamento dei candidati.

---

## 5. Controlli statici

| Controllo | Rilevato | Grado |
|---|---|---|
| `next` bounds | **NO** | **UNPROVEN** |
| stride | **NO** | **UNPROVEN** |
| page boundary | **NO** | **UNPROVEN** |
| terminazione | **NO** | **UNPROVEN** |
| `fixup_value` | **NO** | **UNPROVEN** |

**PROVEN:** nessun controllo è associato a un simbolo o stringa del loader.
**UNPROVEN:** la presenza nel codice non simbolizzato.

---

## 6. Componenti mancanti

| Componente | Stato |
|---|---|
| `fixup_value` | **assente** |
| `kc_kind2index` | **assente** |
| `kernel_collection_slide` | **assente** |
| `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` | **assente** |
| disassembly del loader | **non disponibile** |
| simbolo del loop | **assente** |
| trace runtime | **assente** |

**PROVEN:** mancano i componenti per una verifica statica del loop.
**UNPROVEN:** l’esistenza del loop nel BootKC.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| BootKC ha chained fixups? | **SÌ — 1** |
| `PE_get_kc_base_pointers` presente? | **SÌ — accessor** |
| `fixup_value` presente? | **NO** |
| `kc_kind2index` presente? | **NO** |
| Controlli `next`/stride/page? | **NO identificati** |
| Disassembly candidato? | **NO** |
| Loader identificato? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** BootKC ha la tabella chained e gli accessor `PE_get_kc_*`, ma **non** il loop `fixup_value` né i controlli `next`/stride/page boundary. `otool -p` non disassembla il candidato. Il loader non è identificabile staticamente da questi simboli. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
