# T27 — AGENT-AMD — X6100 CODE / ABI COMPARISON

**Scope:** verificare se le differenze tra `AMDRadeonX6100HWLibs` di `systemkc-all` (`e521d3cc…`) e root2/KDK25 (`00b6214e…`) coinvolgono **codice, interfacce o solo linking**, senza dichiarare compatibilità 26B131.  
**Modalità:** sola lettura; `nm`, `otool`, `strings`, `shasum`, `dwarfdump`. Nessuna copia, estrazione, build, firma o boot.  
**Esito:** **interfaccia esterna per nome invariata** (72 export, 348 import), **stringhe significative identiche**, **sezioni identiche**; ma **codice `__text` diverso** (21.383 B) e **simboli locali diversi**. Non è “solo linking”; l’ABI semantica resta **UNPROVEN**.

---

## 1. Identità e sezioni

| Campo | `systemkc-all` | root2 / KDK25 |
|---|---|---|
| SHA-256 | `e521d3cc…` | `00b6214e…` |
| Byte | 16.985.840 | 17.256.336 |
| UUID | `533D1262-BE83-3507-B48A-FDB91C9D8793` | uguale |
| `LC_SOURCE_VERSION` | `7.1.11` | `7.1.11` |
| `LC_BUILD_VERSION` / `LC_VERSION_MIN_*` | **assente** | **assente** |
| `LC_LOAD_DYLIB` | **0** | **0** |

Sezioni presenti, identiche per nome e ordine:

```text
__TEXT,__text
__TEXT,__cstring
__TEXT,__const
__DATA,__got
__DATA,__mod_init_func
__DATA,__mod_term_func
__DATA,__const
__DATA,__data
__DATA,__common
__DATA,__bss
__DATA_CONST,__kalloc_type
```

Non ci sono sezioni aggiunte o rimosse.

---

## 2. Interfaccia esterna

### 2.1 Export

| Misura | systemkc | root2/KDK25 |
|---|---:|---:|
| `nm -gU` | **72** | **72** |
| Nomi esportati | 72 | 72 |
| Diff nomi | — | **vuoto** |
| Indirizzi | base `0xdd6e000` | base `0`; shift `0xdd6e000` |

I 72 nomi esportati sono identici. Gli indirizzi differiscono per il rebase, non per l’interfaccia.

### 2.2 Import

| Misura | systemkc | root2/KDK25 |
|---|---:|---:|
| `nm -arch x86_64 -u` | **348** | **348** |
| Nomi unici | 348 | 348 |
| Diff nomi | — | **vuoto** |

Le 348 importazioni undefined hanno gli **stessi nomi**. Non ci sono import aggiunti o rimossi.

### 2.3 Indirect symbols e dylib

| Comando | systemkc | root2/KDK25 |
|---|---|---|
| `otool -Iv` | solo header, **nessuna entry** | solo header, **nessuna entry** |
| `otool -L` | **nessuna dipendenza** | **nessuna dipendenza** |

`otool -Iv` non emette una tabella indiretta separata; `otool -L` non mostra dylib. Non c’è un’interfaccia aggiuntiva osservabile.

---

## 3. Codice

| Intervallo | Byte diversi | Nota |
|---|---:|---|
| `__text` | **21.383** | codice macchina non identico |
| `__cstring` | **0** | hash identico |
| `__const` | **0** | hash identico |
| `__DATA` | 35.319 | dati/puntatori; non interfaccia |
| `__DATA_CONST` | 25 | dati |
| `__LINKEDIT` | 480.572 | symtab/string table/firma |

Il dato decisivo è **21.383 B differenti in `__text`**: non è una semplice ricollocazione. Le stringhe e le costanti `__cstring`/`__const` sono identiche, quindi la differenza non è spiegata da nuove stringhe o costanti.

---

## 4. Simboli locali

| Misura | systemkc | root2/KDK25 |
|---|---:|---:|
| `nm -m` righe | 12.602 | 12.602 |
| `nm -a -m` righe | 12.602 | **12.917** |
| Nomi unici `nm -m` | 12.332 | 12.356 |
| Differenze nomi visibili | — | **30 righe** |
| `LC_DYSYMTAB` local | 12.182 | 12.497 (+315) |

I **72 external defined** e i **348 undefined** restano invariati. Le differenze sono nei simboli **locali**:
- root2 aggiunge nomi `.pData`, `.cold.1`, `.types`, `.k` e `_reltable...`;
- systemkc ha `_GLOBAL__sub_I_AMDRadeonHWLibs.cpp`, `...SWIP.cpp`, `...X6100.cpp`;
- root2 ha `__GLOBAL__sub_I_...` (doppio underscore) per gli stessi inizializzatori.

I 315 simboli in più visibili con `-a` sono **locali** e non cambiano l’elenco degli export/import. La loro categoria precisa (debug/stab o altro) non è ulteriormente determinata.

---

## 5. Stringhe e riferimenti KPI/API

| Misura | systemkc | root2/KDK25 |
|---|---:|---:|
| `strings -a` righe | 61.828 | 61.745 |
| `strings -a -n 6` righe | 30.945 | 30.945 |
| `strings -a -n 6` uniche | 15.402 | 15.402 |
| Diff uniche (≥6) | — | **vuoto** |
| Stringhe KPI/API-like | 265 | 265 |

Le stringhe **significative** (≥6 caratteri) sono identiche come insieme. Le differenze grezze di `strings -a` includono sequenze brevi/casuali del testo macchina e non indicano nuove API. I riferimenti a `IO*`, `PowerPlay`, `AMDRadeon`, `IOPCI`, `IOAccel`, `IOSurface`, `AppleGraphics` sono gli stessi 265.

---

## 6. Interpretazione

### 6.1 PROVEN

- 72 export con **nomi identici**.
- 348 import undefined con **nomi identici**.
- `otool -Iv` senza entry indirette; `otool -L` senza dylib.
- `__cstring`/`__const` identici; stringhe significative identiche; 265 riferimenti KPI/API identici.
- Sezioni identiche per nome/ordine.
- `__text` differisce per **21.383 B**.
- `nm -a -m` root2 ha **315 simboli locali in più**; gli external/undefined restano 72/348.

### 6.2 INFERRED

- La differenza è **implementativa/locale**, non un cambio dell’interfaccia esterna per nome.
- I simboli `.pData`, `.cold.1`, `.types`, `.k`, `_reltable...` sono artefatti di compilazione/link locale.
- Le differenze `__DATA`/`__DATA_CONST` sono compatibili con rebasing e layout, ma non sono attribuite una per una.
- La firma e il `__LINKEDIT` più grande spiegano la parte “linking” del delta.

### 6.3 UNPROVEN

- Che l’ABI semantica (layout C++, vtable, calling convention, strutture) sia identica.
- Che le 21.383 B di codice siano innocue o solo ottimizzazioni.
- La causa delle differenze di codice.
- La compatibilità con 26B131 e il caricamento.
- La provenienza di `e521`.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Export names identici? | **SÌ**: 72/72 |
| Import names identici? | **SÌ**: 348/348 |
| Stringhe significative identiche? | **SÌ** |
| Sezioni identiche? | **SÌ** |
| Codice identico? | **NO**: 21.383 B in `__text` |
| Solo linking? | **NO** |
| Simboli locali identici? | **NO**: +315 in root2, 30 nomi visibili diversi |
| ABI 26B131 dimostrata? | **NO** |
| Compatibilità dichiarabile? | **NO** |

L’interfaccia **per nome** è invariata; il **codice** non lo è. La differenza non è solo firma/rebasing/linking: `__text` ha 21.383 B diversi. Questo basta per mantenere `UNPROVEN` l’ABI e per non dichiarare compatibilità con 26B131.

**STOP rispettato:** sola lettura; nessuna copia, estrazione, build, firma o boot. Spazio libero 12.927.952 KiB (12,33 GiB) > 10 GiB.
