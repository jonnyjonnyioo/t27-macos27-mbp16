# T27 — AGENT-AMD — CACHELEVEL 2 INVALID POINTERS

**Scope:** determinare perché **12 auth pointer** e **9 target esterni** usano `cacheLevel=2`, indice privo di `KCKind`; verificare byte grezzi, decodifica, formato, differenze XNU/dyld/linker; escludere corruzione o errore del parser; rivalutare X6100.

**Modalità:** sola lettura; scan SystemKC allineato a 8 byte, decoding `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`, confronto con `kc_index` e `fixup-chains.h`. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** i **9 esterni** a livello 2 sono tutti **auth**, con parole encoded coerenti (`target` nei 30 bit bassi, `cacheLevel=2`, `isAuth=1`). Il decoder è **corretto**: il campo è a 2 bit e vale davvero 2. `cacheLevel=2` **non ha `KCKind`**: `kc_kind2index` mappa solo 0/1/3 e va in `panic` sul resto. I **12 auth** a livello 2 includono i **9 esterni**; restano **12 unici**, di cui **9 esterni** e **3 non esterni**. La causa è **UNPROVEN**: emissione del linker, variante o corruzione. X6100 è **cacheLevel 0** e non è coinvolto. T27 resta **OPEN**.

---

## 1. Conteggi

| Classe | Livello 2 | Note |
|---|---:|---|
| **Auth totali** | **12** | 56 auth totali |
| **Target esterni** | **9** | tutti auth |
| **Unici** | **12** | i 9 esterni sono già nei 12 |
| **Non esterni** | **3** | probabilmente AMD10000/altro |

**PROVEN:** **9/38** esterni sono livello 2; **12/56** auth sono livello 2.
**PROVEN:** l’intersezione è **9**; **12** è il numero unico, non 21.

---

## 2. I 9 esterni

| Target | Sorgente | Parola encoded (esempio) | `cacheLevel` | `isAuth` |
|---:|---|---|---:|---:|
| `0x3F8C007F` | X4000 | `0xF0001100BF8C007F` | **2** | **1** |
| `0x3E8203F2` | X4000 | `0xBF820006BE8203F2` | **2** | **1** |
| `0x334FE856` | X4000HWLibs | `0x8348FFFBB34FE856` | **2** | **1** |
| `0x1780000E` | X4000HWLibs | `0xC03831019780000E` | **2** | **1** |
| `0x20A` | X4000HWLibs | `0x800002218000020A` | **2** | **1** |
| `0x4A6` | X4000HWLibs | `0x800004AE800004A6` | **2** | **1** |
| `0x16400001` | X4000HWLibs | `0xD800002296400001` | **2** | **1** |
| `0x8B1` | X4000HWLibs | `0x80000925800008B1` | **2** | **1** |
| `0x1A000002` | X4000HWLibs | `0xC01400049A000002` | **2** | **1** |

**PROVEN:** tutte le parole hanno `target` corretto nei 30 bit bassi, `cacheLevel=2` nei bit 30–31 e `isAuth=1` nel bit 63.
**UNPROVEN:** che queste occorrenze siano le **slot sorgente** esatte; sono parole encoded **verificate** con gli stessi target, non un’attribuzione di slot.

---

## 3. Decodifica

```text
target     = raw & 0x3FFFFFFF
cacheLevel = (raw >> 30) & 0x3
isAuth     = (raw >> 63) & 0x1
```

Esempio `0xF0001100BF8C007F`:

| Campo | Valore |
|---|---:|
| `target` | **`0x3F8C007F`** |
| `cacheLevel` | **2** |
| `diversity` | `0x1100` |
| `addrDiv` | **0** |
| `key` | **0** |
| `isAuth` | **1** |

**PROVEN:** il campo è a 2 bit; **2** è un valore legale del campo ma **non** un indice `KCKind` valido.
**PROVEN:** non è un errore di shift (`>>30 & 3`).
**PROVEN:** non è un errore di maschera (`target` 30 bit, `next` 12 bit).

---

## 4. Formato

| Formato | `cacheLevel` | Layout |
|---|---:|---|
| **8** `DYLD_CHAINED_PTR_64_KERNEL_CACHE` | **2 bit** | stesso struct |
| **11** `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` | **2 bit** | stesso struct, stride 1 |

**PROVEN:** il campo `cacheLevel` è identico nei formati 8 e 11.
**PROVEN:** il formato 11 non introduce un’interpretazione diversa di `cacheLevel=2`.
**UNPROVEN:** una variante Apple non documentata che assegni 2 a una collezione.

---

## 5. XNU

```c
typedef enum kc_index {
    primary_kc_index   = 0,
    pageable_kc_index  = 1,
    auxiliary_kc_index = 3,
} kc_index_t;

switch (type) {
case KCKindPrimary:   return 0;
case KCKindPageable:  return 1;
case KCKindAuxiliary: return 3;
default: panic("Invalid KC Kind");
}
```

**PROVEN:** **2 non è mappato**; non esiste un `KCKind` per 2.
**PROVEN:** `basePointers[2]` non viene inizializzato da `PE_set_kc_header`.
**INFERRED:** un fixup con `cacheLevel=2` sarebbe rifiutato o produrrebbe base nulla a runtime.

---

## 6. Cause

| Ipotesi | Stato | Evidenza |
|---|---|---|
| Errore del parser | **ESCLUSA** | campo a 2 bit, raw coerenti |
| Corruzione casuale | **UNPROVEN** | 9 target distinti e coerenti |
| Emissione del linker | **UNPROVEN** | nessuna sorgente ld64/kcgen |
| Variante del formato | **UNPROVEN** | nessuna documentazione |
| Indice riservato usato per errore | **UNPROVEN** | 0/1/3 documentati, 2 buco |

**PROVEN:** il pattern non è un singolo bit flip: i 9 target sono diversi e tutti `cacheLevel=2`.
**INFERRED:** è più probabile un’emissione deliberata del linker o un uso di un indice riservato, non un errore del parser.
**UNPROVEN:** la causa esatta.

---

## 7. I 12 auth

| Gruppo | Auth | Livello 2 | Stato |
|---|---:|---:|---|
| Esterni | 9 | 9 | **invalidi** |
| Non esterni | 3 | 3 | **UNPROVEN** |
| **Totale** | **12** | **12** | **invalidi** |

**PROVEN:** **12/56** auth hanno `cacheLevel=2`.
**PROVEN:** **9** sono esterni; **3** non lo sono.
**UNPROVEN:** i 3 non esterni; potrebbero essere AMD10000 o altro.

---

## 8. X6100

| Proprietà | Valore |
|---|---|
| Target | **`0x12AA488`** |
| `cacheLevel` | **0** |
| `isAuth` | **1** |
| `KCKind` | **Primary** |
| Base | **assente** |
| Stato | **relativo, non assoluto** |

**PROVEN:** X6100 **non** usa `cacheLevel=2`; l’anomalia X6100 è indipendente dai 21 puntatori.
**PROVEN:** resta auth verso firmware/dati; l’assoluto resta **UNPROVEN**.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| 12 auth livello 2? | **SÌ** |
| 9 esterni livello 2? | **SÌ** |
| Unici? | **12** |
| Decoder corretto? | **SÌ** |
| `cacheLevel=2` valido? | **NO — nessun KCKind** |
| Errore parser? | **NO** |
| Causa? | **UNPROVEN** |
| X6100 coinvolto? | **NO — livello 0** |
| 17 AMD10000 risolti? | **NO — UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** **12 auth** (di cui **9 esterni**) e **9 target esterni** usano davvero `cacheLevel=2`; il decoder è corretto, ma l’indice **2** non ha `KCKind`. Non è un errore di parsing. La causa resta **UNPROVEN**; **12 auth unici** sono strutturalmente invalidi. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
