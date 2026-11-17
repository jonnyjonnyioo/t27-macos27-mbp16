# T27 — AGENT-AMD — KERNEL CACHE LEVEL BASES

**Scope:** verificare se i **17 auth pointer AMD10000** sono irrisolvibili perché manca la base corretta del formato **`DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`**; ricostruire le basi `cacheLevel 0–3`; confrontare i target con riferimenti interni già risolti; ripetere la classificazione dei **38** target esterni.

**Modalità:** sola lettura; parsing Mach-O, `LC_FILESET_ENTRY`, `LC_DYLD_CHAINED_FIXUPS`, header SystemKC/BootKC, `__PRELINK_INFO`, `nm`, SHA-256. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** **0/4** basi `basePointers[0..3]` sono serializzate nella KC. Il campo `target` **non è un vmaddr**: è un **offset a 30 bit**; l’indirizzo si ottiene con **`basePointers[cacheLevel] + target`**. `cacheLevel` indicizza un **array di `mach_header`** fornito dal loader. SystemKC è **base-0**, BootKC ha `__TEXT` a **`0xffffff8000200000`**, ma nessuna delle due contiene l’array. I **17 AMD10000** restano **UNPROVEN**; i **38** restano esterni; **0** nuovi provider. T27 resta **OPEN**.

---

## 1. Formato autorevole

Fonte: Apple `mach-o/fixup-chains.h` e XNU `osfmk/mach/dyld_kernel_fixups.h`.

| Campo | Bit | Significato |
|---|---:|---|
| `target` | 0–29 | **offset**, non vmaddr |
| `cacheLevel` | 30–31 | indice dell’array `basePointers` |
| `diversity` | 32–47 | diversità PAC |
| `addrDiv` | 48 | address diversity |
| `key` | 49–50 | chiave PAC |
| `next` | 51–62 | stride catena |
| `isAuth` | 63 | 1 = autenticato |

```c
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

```c
const void* baseAddress = basePointers[fixupLoc->fixup64.cacheLevel];
if (baseAddress == 0) { /* Invalid cache level */ return; }
uintptr_t slidValue = (uintptr_t)baseAddress + fixupLoc->fixup64.target;
```

**PROVEN:** `target` è un **offset**; `basePointers[cacheLevel]` è la base; una base nulla rende il puntatore **non risolvibile**.

---

## 2. Basi Serializzate

| Collezione | `__TEXT` vmaddr | `__TEXT` fileoff | UUID | `basePointers` |
|---|---:|---:|---|---|
| **SystemKC** | **`0x0`** | **`0x0`** | `93336203-88E3-AA73-08FC-7C9F4D7B21E0` | **assente** |
| **BootKC** | **`0xffffff8000200000`** | **`0x0`** | `63C931A6-A4C0-AB5D-E2FB-D1712B1143DB` | **assente** |

**PROVEN:** SystemKC è **base-0**; BootKC è linkata a **`0xffffff8000200000`**.
**PROVEN:** `basePointers` e `kernelSlide` hanno **0 occorrenze** nei metadati SystemKC; `__PRELINK_INFO` espone solo `_BootKCID`, `_PrelinkKCID`, `KMBuildVersion`, `ManagerVersion`, `OSPrelinkInfoContainsUUIDs`.
**PROVEN:** **0/4** basi `basePointers[0..3]` sono presenti.
**UNPROVEN:** qualsiasi valore concreto di `basePointers[0]`, `[1]`, `[2]`, `[3]`.

---

## 3. Livelli

### 3.1 Auth pointer — 56

| `cacheLevel` | Auth | Base | Stato |
|---:|---:|---|---|
| **0** | **16** | `basePointers[0]` **assente** | **UNPROVEN** |
| **1** | **11** | `basePointers[1]` **assente** | **UNPROVEN** |
| **2** | **12** | `basePointers[2]` **assente** | **UNPROVEN** |
| **3** | **17** | `basePointers[3]` **assente** | **UNPROVEN** |
| **Totale** | **56** | — | — |

### 3.2 Target esterni — 38

| `cacheLevel` | Esterni | Base | Stato |
|---:|---:|---|---|
| **0** | **10** | assente | **UNPROVEN** |
| **1** | **9** | assente | **UNPROVEN** |
| **2** | **9** | assente | **UNPROVEN** |
| **3** | **10** | assente | **UNPROVEN** |
| **Totale** | **38** | — | — |

**PROVEN:** i **38** esterni coprono **tutti e quattro** i livelli.
**PROVEN:** nessuna base è serializzata; nessun livello è risolvibile in assoluto.

### 3.3 Riferimenti interni X6100

| Classe | Puntatori | `cacheLevel` |
|---|---:|---:|
| **Interni X6100** | **7.658** | **1** |
| **Esterni grezzi** | **886** | **0** |

**PROVEN:** la separazione è netta: **livello 1 = X6100**, **livello 0 = esterni**.
**UNPROVEN:** che `basePointers[1]` o `[0]` siano zero.

---

## 4. I 17 AMD10000

| Verifica | Esito |
|---|---|
| Target in segmento AMD10000 | **0/17** |
| Target con file offset | **0/17** |
| Target = `basePointers[0] + offset` | **base assente** |
| Target = `basePointers[3] + offset` | **base assente** |
| Target assoluto | **UNPROVEN** |
| Attribuzione per prossimità | **rifiutata** |

**PROVEN:** i **17** sono **offset**, non vmaddr; giacciono fuori dai segmenti dell’immagine embedded.
**PROVEN:** nessuna base `basePointers` è disponibile; **neanche** con `cacheLevel` corretto è possibile calcolare l’indirizzo finale.
**UNPROVEN:** il livello effettivo dei singoli 17; la distribuzione aggregata **3:17** coincide numericamente con il totale dei 17, ma **non prova** che siano tutti livello 3.
**UNPROVEN:** la validità runtime; il simbolo nearest resta **solo prossimità**, non attribuzione.

---

## 5. I 38 esterni

| Controllo | Risultato |
|---|---:|
| In un provider SystemKC | **0/38** |
| Non canonici | **8** (`0x0`, `0x1`, `0x7`, `0x20A`, `0x4A6`, `0x550`, `0x8B1`, `0x30BE`) |
| Con base serializzata | **0/38** |
| Con indirizzo assoluto | **0/38** |
| Nuovi provider AMD | **0** |

**PROVEN:** i **38** non sono risolvibili con i metadati della KC; la mancanza di `basePointers` è **condizione necessaria**, non prova di provenienza.

---

## 6. X6100

| Proprietà | Valore |
|---|---|
| Target | **`0x12AA488`** |
| `cacheLevel` | **0** |
| `basePointers[0]` | **assente** |
| Indirizzo KC-relativo | **`0x12AA488`** |
| Indirizzo assoluto | **UNPROVEN** |
| Sezione X4000 | **`__DATA,__data`** |
| Simbolo | **`_polaris10_kicker_smc_firmware + 0x100D8`** |

**PROVEN:** il target è **relativo**; il report precedente lo chiamava “risolto” nel senso **KC-relativo**, non assoluto.
**PROVEN:** resta l’unico auth pointer noto verso **firmware/dati**.
**UNPROVEN:** l’indirizzo finale e la validità runtime.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| `target` è vmaddr? | **NO — è offset** |
| `basePointers` è serializzato? | **NO — 0/4** |
| SystemKC base? | **0** |
| BootKC `__TEXT`? | **`0xffffff8000200000`** |
| Basi 0–3 ricostruite? | **NO** |
| 17 AMD10000 risolti? | **NO — UNPROVEN** |
| 38 esterni risolti? | **NO — UNPROVEN** |
| X6100 `0x12AA488` assoluto? | **NO — relativo** |
| Nuovi provider AMD? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i **17** non sono risolvibili perché **manca `basePointers`**, non perché manchi una sezione AMD10000. La formula corretta è **`basePointers[cacheLevel] + target`**; con **0/4** basi serializzate, nessun target può essere portato ad assoluto. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
