# T27 — AGENT-AMD — BASEPOINTERS ORIGIN

**Scope:** stabilire come XNU, dyld e il linker costruiscono `basePointers[0..3]` per `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`; verificare se `LC_FILESET_ENTRY` o l’ordine dei bundle permettono di ricostruirle; confrontare SystemKC e BootKC; determinare cosa manca per i **17 AMD10000** e per X6100.

**Modalità:** sola lettura; header Mach-O, `LC_FILESET_ENTRY`, `LC_DYLD_CHAINED_FIXUPS`, `__PRELINK_INFO`, ricerca locale e fonti Apple XNU/dyld. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** `basePointers` è un **array runtime** di `mach_header`, non un campo del file. XNU inizializza esplicitamente **solo l’indice 0** (`collection_base_pointers[0] = kc_mh`) e passa l’array a `kernel_collection_slide`; gli altri indici sono riempiti dal caricamento delle altre collezioni. `LC_FILESET_ENTRY` descrive i **kext dentro una collezione**, non i livelli di cache. **Nessuna base è ricostruibile dal solo SystemKC/BootKC**. I **17** e X6100 restano **UNPROVEN**. T27 resta **OPEN**.

---

## 1. Definizione

```c
// osfmk/mach/dyld_kernel_fixups.h
static inline void
fixup_value(..., const void* basePointers[KCNumKinds], int* stop)
{
    const void* baseAddress = basePointers[fixupLoc->fixup64.cacheLevel];
    if (baseAddress == 0) { /* Invalid cache level */ return; }
    uintptr_t slidValue = (uintptr_t)baseAddress + fixupLoc->fixup64.target;
}
```

```c
// EXTERNAL_HEADERS/mach-o/fixup-chains.h
struct dyld_chained_ptr_64_kernel_cache_rebase {
    uint64_t target     : 30,   // basePointers[cacheLevel] + target
             cacheLevel :  2,   // indexes a mach_header array
             diversity  : 16,
             addrDiv    :  1,
             key        :  2,
             next       : 12,
             isAuth     :  1;
};
```

**PROVEN:** `basePointers` è indicizzato da `cacheLevel`; l’indirizzo è **base + offset**; base nulla = **cache level invalido**.

---

## 2. Origine in XNU

`osfmk/arm/arm_init.c`:

```c
kc_mh = (kernel_mach_header_t*)(VM_KERNEL_LINK_ADDRESS + slide);
assert(kc_mh->filetype == MH_FILESET);

const void *collection_base_pointers[KCNumKinds] = {[0] = kc_mh, };
kernel_collection_slide((struct mach_header_64 *)kc_mh,
    collection_base_pointers);

PE_set_kc_header(KCKindPrimary, kc_mh, slide);
```

**PROVEN:** l’array è **locale allo stack**; **solo `[0]`** è inizializzato esplicitamente; `kc_mh` è il **mach header della collezione primaria**.
**PROVEN:** `PE_set_kc_header` registra il **KCKindPrimary**, non un array di basi.
**PROVEN:** `KCNumKinds` è la dimensione dell’array; **non è serializzata**.
**UNPROVEN:** quali indici 1–3 siano popolati e con quale ordine; dipende dal caricamento delle collezioni pageable/aux.

---

## 3. Tipi di collezione

`libkern/c++/OSKext.cpp`:

| Tipo | `KCKind` |
|---|---|
| `kKCTypePrimary` | **`KCKindPrimary`** |
| `kKCTypeSystem` | **`KCKindPageable`** |
| `kKCTypeAuxiliary` | **`KCKindAuxiliary`** |
| `kKCTypeCodeless` | **`KCKindNone`** |

**PROVEN:** la mappatura è per **tipo di collezione**, non per `LC_FILESET_ENTRY`.
**INFERRED:** `cacheLevel` è compatibile con l’indice della collezione (primary/pageable/auxiliary), ma la corrispondenza numerica esatta **non è serializzata**.
**UNPROVEN:** che `cacheLevel 0/1/2/3` mappi esattamente Primary/Pageable/Auxiliary/None.

---

## 4. `LC_FILESET_ENTRY`

`osfmk/kern/kalloc.c`:

```c
kc_mh = PE_get_kc_header(KCKindPrimary);
for (lc = ...; ...; lc = ...) {
    if (lc->cmd != LC_FILESET_ENTRY) continue;
    struct fileset_entry_command *fse = ...;
    kext_mh = (kernel_mach_header_t *)fse->vmaddr;
    /* usa kext_mh per __kalloc_type */
}
```

**PROVEN:** `LC_FILESET_ENTRY` serve a iterare i **kext dentro una collezione**; il suo `vmaddr` è il **mach header del kext**, non una base di cache.
**PROVEN:** l’ordine delle entry è l’ordine dei bundle nel fileset; **non codifica `cacheLevel`**.
**PROVEN:** **172** entry SystemKC non sono **4 basi**.
**UNPROVEN:** una relazione tra indice entry e livello.

---

## 5. SystemKC e BootKC

| Collezione | `LC_FILESET_ENTRY` | `basePointers` | `__TEXT` |
|---|---:|---|---:|
| **SystemKC** | **172** | **assente** | `0x0` |
| **BootKC** | **?** | **assente** | **`0xffffff8000200000`** |

**PROVEN:** nessuna delle due collezioni contiene un array `basePointers`.
**PROVEN:** BootKC è linkata alta; SystemKC è base-0.
**UNPROVEN:** la base assoluta delle altre collezioni e lo slide KASLR.

---

## 6. Cosa manca

| Dato | Stato |
|---|---|
| `basePointers[0]` | **runtime, non serializzato** |
| `basePointers[1]` | **runtime, non serializzato** |
| `basePointers[2]` | **runtime, non serializzato** |
| `basePointers[3]` | **runtime, non serializzato** |
| Ordine delle collezioni | **non deducibile da `LC_FILESET_ENTRY`** |
| KASLR slide | **assente** |
| `PE_get_kc_header(KCKind*)` | **solo runtime** |

**PROVEN:** nessun campo Mach-O contiene questi valori.
**UNPROVEN:** qualunque ricostruzione statica completa.

---

## 7. Effetto sui target

### 7.1 I 17 AMD10000

| Verifica | Esito |
|---|---|
| `target` è offset | **SÌ** |
| Base disponibile | **NO** |
| Segmento AMD10000 | **0/17** |
| File offset | **0/17** |
| Indirizzo assoluto | **UNPROVEN** |
| Attribuzione per prossimità | **rifiutata** |

**PROVEN:** i 17 sono offset; senza `basePointers` non sono indirizzi.
**UNPROVEN:** il livello e la base corretti.

### 7.2 X6100

| Proprietà | Valore |
|---|---|
| Target | **`0x12AA488`** |
| `cacheLevel` | **0** |
| Base | **`basePointers[0]` assente** |
| Indirizzo assoluto | **UNPROVEN** |
| Sezione X4000 | **`__DATA,__data`** |

**PROVEN:** il target X6100 è relativo; **non è un indirizzo finale**.
**PROVEN:** l’anomalia semantica (auth verso firmware) resta; la risoluzione assoluta no.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| `basePointers` è nel file? | **NO** |
| XNU inizializza `[0]`? | **SÌ, a `kc_mh`** |
| `[1..3]` sono nel file? | **NO** |
| `LC_FILESET_ENTRY` dà le basi? | **NO** |
| SystemKC/BootKC bastano? | **NO** |
| 17 AMD10000 risolti? | **NO — UNPROVEN** |
| X6100 risolto in assoluto? | **NO — relativo** |
| Nuovi provider AMD? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `basePointers` nasce a runtime; XNU ne inizializza solo l’indice 0 con il mach header della collezione primaria e lascia gli altri al caricamento delle collezioni. `LC_FILESET_ENTRY` elenca kext, non livelli di cache. **Nessuna base 0–3 è ricostruibile staticamente**; i **17** e X6100 restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
