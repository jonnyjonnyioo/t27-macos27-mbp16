# T27 — AGENT-AMD — CACHELEVEL → KCKIND MAPPING

**Scope:** determinare la corrispondenza numerica tra `cacheLevel[0..3]`, `KCKind` e le collezioni XNU; confrontare x86_64 e ARM64; ricostruire l’ordine Primary/Pageable/Auxiliary; verificare se gli header permettono di ricostruire le basi; rivalutare i **17 AMD10000** e il fixup X6100.

**Modalità:** sola lettura; fonti Apple XNU/dyld, header Mach-O, `LC_FILESET_ENTRY`, `LC_DYLD_CHAINED_FIXUPS`, SystemKC/BootKC. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** la mappatura è **`primary=0`, `pageable=1`, `auxiliary=3`**; l’indice **2 è un buco non mappato**. `PE_set_kc_header` calcola la base come **lowest segment vmaddr + slide**, non come `__TEXT`. L’array `collection_base_pointers[KCNumKinds]` è globale/runtime, non serializzato. `cacheLevel 2` non ha `KCKind` e va trattato come **invalido**. I **17** restano **UNPROVEN**; X6100 resta **relativo**. T27 resta **OPEN**.

---

## 1. Enum esatta

`pexpert/gen/kcformat.c` (xnu-12377.1.9):

```c
typedef enum kc_index {
    primary_kc_index   = 0,
    pageable_kc_index  = 1,
    auxiliary_kc_index = 3,
} kc_index_t;

static inline kc_index_t
kc_kind2index(kc_kind_t type)
{
    switch (type) {
    case KCKindPrimary:   return primary_kc_index;
    case KCKindPageable:  return pageable_kc_index;
    case KCKindAuxiliary: return auxiliary_kc_index;
    default: panic("Invalid KC Kind");
    }
}
```

**PROVEN:** `Primary=0`, `Pageable=1`, `Auxiliary=3`; **`2` non è assegnato**.
**PROVEN:** un `cacheLevel=2` non ha `KCKind` corrispondente e cade nel caso invalido.
**UNPROVEN:** il valore numerico di `KCNumKinds` e l’eventuale uso futuro dell’indice 2.

---

## 2. Base calcolata

```c
void
PE_set_kc_header(kc_kind_t type, kernel_mach_header_t *header, uintptr_t slide)
{
    kc_index_t i = kc_kind2index(type);
    ...
    uint64_t lowest_vmaddr = ~0ULL;
    for (lc = ...; ...; lc = ...) {
        if (lc->cmd != LC_SEGMENT_64) continue;
        seg = (struct segment_command_64 *)lc;
        if (seg->vmaddr < lowest_vmaddr) lowest_vmaddr = seg->vmaddr;
    }
    collection_base_pointers[i] =
        (void *)((uintptr_t)lowest_vmaddr + slide);
}
```

**PROVEN:** la base non è il `__TEXT` né il `mach_header`: è **lowest segment vmaddr + slide**.
**PROVEN:** `PE_set_kc_header_and_base` permette una base esplicita; `PE_get_kc_base_pointers()` restituisce l’array.
**PROVEN:** l’array è globale in `kcformat.c`:

```c
#if defined(__x86_64__) || defined(__i386__)
void *collection_base_pointers[KCNumKinds] = {};
#else
SECURITY_READ_ONLY_LATE(void *) collection_base_pointers[KCNumKinds];
#endif
```

---

## 3. Mappatura

| `cacheLevel` | `kc_index` | `KCKind` | Collezione | Valido |
|---:|---:|---|---|---|
| **0** | **0** | **`KCKindPrimary`** | BootKC/Primary | **SÌ** |
| **1** | **1** | **`KCKindPageable`** | SystemKC/Pageable | **SÌ** |
| **2** | **—** | **nessuno** | **—** | **NO — buco** |
| **3** | **3** | **`KCKindAuxiliary`** | AuxKC | **SÌ** |

**PROVEN:** 0/1/3 sono mappati; **2 non lo è**.
**PROVEN:** `cacheLevel` è un indice a 2 bit, non un’etichetta di bundle.

---

## 4. x86_64 e ARM64

| Aspetto | x86_64 | ARM64 |
|---|---|---|
| `collection_base_pointers` | **globale writable** | **`SECURITY_READ_ONLY_LATE`** |
| `kc_index` | **0/1/3** | **0/1/3** |
| `PE_set_kc_header` | **lowest + slide** | **lowest + slide** |
| `PE_get_kc_baseaddress` Primary | **array** | **`segLOWESTTEXT`** |
| Base serializzata nel KC | **NO** | **NO** |

**PROVEN:** la mappatura degli indici è la stessa; **non** va trasferita la base BootKC x86 all’ARM64 o viceversa.
**PROVEN:** nessuna delle due architetture serializza l’array.

---

## 5. Impatto sui 56 auth

| `cacheLevel` | Auth | `KCKind` | Base | Stato |
|---:|---:|---|---|---|
| **0** | **16** | Primary | `collection_base_pointers[0]` | **UNPROVEN** |
| **1** | **11** | Pageable | `collection_base_pointers[1]` | **UNPROVEN** |
| **2** | **12** | **nessuno** | **—** | **INVALIDO** |
| **3** | **17** | Auxiliary | `collection_base_pointers[3]` | **UNPROVEN** |

**PROVEN:** **12/56** auth pointer hanno `cacheLevel=2`, che non ha `KCKind`; sono **strutturalmente invalidi** secondo `kc_kind2index`.
**PROVEN:** **17/56** sono livello 3 (Auxiliary); **16/56** livello 0; **11/56** livello 1.

---

## 6. Impatto sui 38 esterni

| `cacheLevel` | Esterni | `KCKind` | Stato |
|---:|---:|---|---|
| **0** | **10** | Primary | **UNPROVEN** |
| **1** | **9** | Pageable | **UNPROVEN** |
| **2** | **9** | **nessuno** | **INVALIDO** |
| **3** | **10** | Auxiliary | **UNPROVEN** |
| **Totale** | **38** | — | — |

**PROVEN:** **9/38** esterni sono livello 2, quindi senza `KCKind`.
**PROVEN:** **0/38** hanno una base serializzata.

---

## 7. I 17 AMD10000

| Verifica | Esito |
|---|---|
| `target` è offset | **SÌ** |
| `cacheLevel` individuale preservato | **NO** |
| Livello 2? | **UNPROVEN** |
| Livello 3? | **UNPROVEN** |
| Base Primary/Pageable/Auxiliary | **NO** |
| Indirizzo assoluto | **UNPROVEN** |
| Attribuzione per prossimità | **rifiutata** |

**PROVEN:** i 17 sono offset; **0/17** in un segmento AMD10000.
**INFERRED:** la distribuzione aggregata **3:17** è compatibile con Auxiliary, ma **non prova** che i 17 siano tutti livello 3.
**UNPROVEN:** se qualche target sia livello 2 (invalido) o 0/1.

---

## 8. X6100

| Proprietà | Valore |
|---|---|
| Target | **`0x12AA488`** |
| `cacheLevel` | **0** |
| `KCKind` | **Primary** |
| Base | **`collection_base_pointers[0]` assente** |
| Indirizzo assoluto | **UNPROVEN** |
| Sezione X4000 | **`__DATA,__data`** |
| Simbolo | **`_polaris10_kicker_smc_firmware + 0x100D8`** |

**PROVEN:** il fixup X6100 è livello 0 / Primary; resta **relativo**.
**PROVEN:** l’anomalia semantica auth→firmware resta; la base assoluta manca.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| `cacheLevel 0` | **Primary** |
| `cacheLevel 1` | **Pageable** |
| `cacheLevel 2` | **nessun KCKind — invalido** |
| `cacheLevel 3` | **Auxiliary** |
| Base calcolata da | **lowest segment vmaddr + slide** |
| Base serializzata | **NO** |
| 12 auth livello 2 validi? | **NO** |
| 9 esterni livello 2 validi? | **NO** |
| 17 AMD10000 risolti? | **NO — UNPROVEN** |
| X6100 assoluto? | **NO — relativo** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la mappatura è **0 Primary, 1 Pageable, 3 Auxiliary**; **2 è un buco**. `PE_set_kc_header` calcola la base da **lowest segment + slide**, ma l’array resta **runtime**. **12 auth** e **9 esterni** a livello 2 sono **invalidi**; i **17** restano **UNPROVEN**; X6100 resta **relativo**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
