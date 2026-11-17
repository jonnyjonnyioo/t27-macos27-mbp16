# T27 — AGENT-AMD — X6100 FINAL BINARY EVIDENCE

**Scope:** consolidare la prova tecnica delle differenze tra `AMDRadeonX6100HWLibs` di `systemkc-all` e root2, verificando struttura, sezioni, simboli, relocation e aritmetica dei report.  
**Modalità:** sola lettura; `shasum`, `dwarfdump`, `otool -l`, `otool -tvV`, `otool -rv`, `nm -a -m`; nessuna scrittura di sezioni, estrazione, copia, build o boot.  
**Esito:** **21.315 B mappati** hanno scheletro di istruzioni compatibile; **68 B non assegnati**. La differenza di layout è confinata a `__LINKEDIT`/firma; non ci sono differenze strutturali di opcode o registri nei byte mappati. **Non è dimostrata equivalenza semantica, ABI o compatibilità 26B131.** T27 resta **OPEN**.

---

## 1. Identità dei due binari

| Campo | `systemkc-all` | root2 |
|---|---|---|
| SHA-256 | **`e521d3cce8f9bb027642897fed8754ff4d9ef66dd08a8d13ab318e0c2db01bb5`** | **`00b6214e4771d84f2cda4a9943fceafaac0e632f57fbfda20e6ee5cbf051d61f`** |
| Dimensione | **16.985.840 B** | **17.256.336 B** |
| Architettura | `Mach-O 64-bit kext bundle x86_64` | `Mach-O 64-bit kext bundle x86_64` |
| UUID | `533D1262-BE83-3507-B48A-FDB91C9D8793` | `533D1262-BE83-3507-B48A-FDB91C9D8793` |
| `LC_SOURCE_VERSION` | `7.1.11` | `7.1.11` |

**Fatto:** i binari sono **distinti** (hash e dimensione diversi) ma condividono UUID e `LC_SOURCE_VERSION`.  
**Limite:** l'UUID condiviso **non prova identità**; è compatibile con varianti dello stesso prodotto.

---

## 2. Load commands e sezioni

### 2.1 Conteggio load commands

| Binario | Load commands | Composizione |
|---|---:|---|
| `systemkc-all` | **8** | 4 × `LC_SEGMENT_64`, `LC_SYMTAB`, `LC_DYSYMTAB`, `LC_UUID`, `LC_SOURCE_VERSION` |
| root2 | **9** | gli stessi 8 + **`LC_CODE_SIGNATURE`** |

Root2 ha `LC_CODE_SIGNATURE` a `dataoff = 17.104.352`; la firma occupa **151.984 B** fino alla fine del file. Questo spiega esattamente la differenza di dimensione:

```text
17.256.336 − 16.985.840 = 270.496 B
```

`__LINKEDIT` passa da **581.360 B** a **851.856 B**: +270.496 B.

### 2.2 Segmenti

| Segmento | `systemkc-all` fileoff / filesize | root2 fileoff / filesize | Sezioni |
|---|---|---|---|
| `__TEXT` | 0 / 3.858.432 | 0 / 3.858.432 | 3 |
| `__DATA` | 3.858.432 / 12.541.952 | 3.858.432 / 12.541.952 | 7 |
| `__DATA_CONST` | 16.400.384 / 4.096 | 16.400.384 / 4.096 | 1 |
| `__LINKEDIT` | 16.404.480 / **581.360** | 16.404.480 / **851.856** | 0 |

I segmenti `__TEXT`, `__DATA` e `__DATA_CONST` hanno **stessi offset e stesse dimensioni**. L'unica differenza di layout è `__LINKEDIT`, coerente con la firma presente solo in root2.

### 2.3 Sezioni

Le sezioni hanno gli **stessi nomi, ordine, dimensioni e offset** in entrambi:

| Sezione | Segmento | Size | Offset |
|---|---|---:|---:|
| `__text` | `__TEXT` | **0x240BD6 = 2.362.326 B** | **2.400** |
| `__cstring` | `__TEXT` | `0x7C209` | 2.364.726 |
| `__const` | `__TEXT` | `0xF03E8` | 2.873.152 |
| `__got` | `__DATA` | `0xE8` | 3.858.432 |
| `__mod_init_func` | `__DATA` | `0x18` | 3.858.664 |
| `__mod_term_func` | `__DATA` | `0x18` | 3.858.688 |
| `__const` | `__DATA` | `0x10170` | 3.858.720 |
| `__data` | `__DATA` | `0xBE5766` | 3.924.624 |
| `__common` | `__DATA` | `0x5F8` | 0 |
| `__bss` | `__DATA` | `0xAEC` | 0 |
| `__kalloc_type` | `__DATA_CONST` | `0xC0` | 16.400.384 |

**Indirizzi virtuali:** `systemkc` ha `__text` a `0xDD6E960`; root2 a `0x960`. Lo shift è **`0xDD6E000`**, coerente con il base address del kernel collection.

---

## 3. Simboli

| Misura | `systemkc-all` | root2 | Differenza |
|---|---:|---:|---:|
| `nm -m` righe | 12.602 | 12.602 | 0 |
| `nm -a -m` righe | 12.602 | 12.917 | **+315** |
| `non-external` | 12.182 | 12.497 | **+315** |
| `undefined` (token in `nm -a -m`) | 348 | 367 | +19 |
| `private external` | 9.624 | 9.624 | 0 |
| `LC_DYSYMTAB` `undef` | **348** | **348** | **0** |
| Export names | **72** | **72** | 0 |
| Undefined/import names | **348** | **348** | 0 |

**Interpretazione:** la differenza `nm -a -m` è di **315 simboli locali** in root2; i 19 `undefined` aggiuntivi sono visibili solo includendo i locali (`-a`) e **non** cambiano il conteggio `LC_DYSYMTAB` (348/348). I 72 export e i 348 import hanno gli **stessi nomi**.

---

## 4. Relocation

| Binario | External relocation entries |
|---|---:|
| `systemkc-all` | **0** |
| root2 | **6.243** |

Distribuzione root2 (da `X6100-RELOCATION-ANALYSIS.md`):

- `_PE_enter_debugger`: 3.849
- `_kprintf`: 580
- `___bzero`: 380
- `_memcpy`: 58

Il binario `systemkc-all` non contiene una tabella di relocation esterna; root2 sì. Questo è coerente con le differenze di resa numerica/simbolica delle call.

---

## 5. Codice: conteggi consolidati

| Voce | Valore |
|---|---:|
| `__text` size | **2.362.326 B** |
| Byte differenti | **21.383 B** (0,905%) |
| Bucket `nm` con differenze | **2.573** |
| Istanze `otool` con differenze | **2.478** |
| Nomi `otool` unici con differenze | **2.476** |
| Byte mappati | **21.315** |
| Byte non assegnati | **68** |

### 5.1 Copertura

```text
16.758 B  address/relocation-only candidate
 4.557 B  residuo dopo normalizzazione stretta
    68 B  non assegnati (prima della prima etichetta otool)
--------
21.383 B  totale
```

**Verifica aritmetica:** `16.758 + 4.557 + 68 = 21.383`. **OK.**

### 5.2 Residuo istruzione-level

| Categoria | Istanze | Byte | Quota |
|---|---:|---:|---:|
| Address/symbol-resolvable | 277 | **4.521** | **99,21%** |
| Branch-target `loop`/`loope` | 4 | **36** | **0,79%** |
| Structural (opcode/registri/numero istruzioni) | **0** | **0** | **0%** |
| Ambiguous residuo | **0** | **0** | **0%** |
| **Totale residuo** | **281** | **4.557** | **100%** |

- **281/281** hanno lo stesso numero di istruzioni delle corrispondenti root2.
- **0** differenze di opcode.
- **0** differenze di registri.
- **0** differenze strutturali.

### 5.3 Correzione rispetto al primo conteggio

Il primo report indicava **284 funzioni / 4.577 B**. La verifica per istanza ha mostrato tre nomi locali duplicati:

- `_getValidClk`
- `_copyOverDriveSettingsLimitsArray`
- `_copyClockLimitsArray`

Il conteggio per nome aveva incluso **20 B** di istanze pulite nel residuo. Il valore corretto è **281 istanze / 4.557 B**; i byte puliti passano da 16.738 a **16.758 B**. Il totale resta 21.383 B.

---

## 6. Coerenza con i report precedenti

| Report | SHA-256 | Valori usati |
|---|---|---|
| `X6100-CODE-DIFF.md` | `4afdee76ca1a83ca62b83a96cd8dd681c440852ad80eba00acdfbd96f0ff27fb` | `__text` 2.362.326 B; 21.383 B; 2.573 bucket |
| `X6100-RELOCATION-ANALYSIS.md` | `5ae9588a75221aea3860bca4758c5825619020949e5bc7cbaf0d34b3099c3fde` | 0 vs 6.243 relocation; 72/348; `LC_DYSYMTAB` 348/348 |
| `X6100-RESIDUAL-DIFF.md` | `87652af78eb91eb8a1c9914577bab50c403ccf3a445a4d2906a68250790a914d` | 16.758 / 4.557 / 68; 281 residui |
| `X6100-INSTRUCTION-VERIFICATION.md` | `b1f2291cc4ca39f6c6a50349dbab62cc56716b9922eaeed3997e62810e605ab1` | 281 residui; 0 structural |

Le cifre **2.573 bucket `nm`** e **2.476 nomi `otool`** non sono equivalenti: `nm` può creare più bucket per una funzione; `otool` espone 2.478 istanze distinte (2.476 nomi unici). La classificazione usa le istanze `otool` accoppiate per indirizzo normalizzato.

---

## 7. Equivalenza osservata

### 7.1 PROVEN

- `__text` ha **stessa dimensione, stesso offset e stesse sezioni**.
- `__TEXT`, `__DATA`, `__DATA_CONST` hanno **stessi offset e dimensioni**.
- root2 differisce per **`LC_CODE_SIGNATURE`** e **`__LINKEDIT` +270.496 B**.
- **21.315 B mappati** hanno scheletro di istruzioni compatibile:
  - 16.758 B puliti dopo call/RIP;
  - 4.557 B residui, tutti con stessi opcode/registri/numero istruzioni dopo normalizzazione;
  - 0 differenze strutturali.
- **68 B** non sono assegnati ad alcuna etichetta `otool`.
- 72 export e 348 import hanno gli **stessi nomi**.
- `LC_SOURCE_VERSION` è **7.1.11** in entrambi.

### 7.2 INFERRED

- Le differenze nei 21.315 B mappati sono compatibili con **symbolization/relocation** e con il diverso rendering dei simboli locali.
- La firma root2 e la tabella relocation spiegano la differenza di layout e di dimensione.

### 7.3 UNPROVEN

- **Equivalenza semantica**: nessuna esecuzione, nessun test funzionale, nessun boot.
- **ABI**: i nomi di export/import coincidono, ma non è stata verificata la compatibilità strutturale con il kernel 26B131.
- **Compatibilità 26B131**: nessuna kernel collection target, nessun bundle AMD target, nessun boot.
- **Causa** delle differenze residue oltre la compatibilità con relocation/symbolization.
- **68 B non assegnati**: non classificati.

---

## 8. Distinzione finale

| Affermazione | Stato |
|---|---|
| I due binari hanno lo stesso layout di `__text` | **PROVEN** |
| Hanno lo stesso scheletro per i 21.315 B mappati | **PROVEN** (metodo `otool`) |
| Le differenze sono solo operandi/address | **PROVEN per i byte mappati**, con limite del metodo |
| Sono semanticamente equivalenti | **UNPROVEN** |
| Sono ABI-compatibili con 26B131 | **UNPROVEN** |
| 26B131 può caricare questo kext | **BLOCKED** |
| T27 è GO | **NO — OPEN** |

**Conclusione:** l'evidenza sostiene una **equivalenza strutturale osservata** dei 21.315 B mappati, non una equivalenza binaria, semantica o ABI. La differenza di 270.496 B è contabilizzata da `__LINKEDIT`/firma; restano 68 B non assegnati. T27 resta **OPEN** e nessun GO è emesso.

**STOP rispettato:** sola lettura; nessuna scrittura di sezioni, estrazione, copia, build, firma o boot. Spazio libero 12.926.860 KiB (12,33 GiB) > 10 GiB.

---

## 9. Aggiornamento 17 Nov 2026

`X6100-EMBEDDED-IDENTITY.md` ha confrontato in memoria la SystemKC 25G342 con le due varianti:

- `__text` embedded SHA-256: **`19dcb85d59d7a1f63b36a6a9218392b9bd0ee347432199b530607965f32a7126`**, identico a **`e521`**;
- `00b6` differisce in **21.383 / 2.362.326 B** di `__text`;
- `e521` coincide in **9/9 sezioni file-backed** (16.395.381 B identici; **0 differenze reali**); le 2 sezioni `__common`/`__bss` sono **S_ZEROFILL, offset 0**, quindi non confrontabili (2.016 B apparenti esclusi);
- `00b6` coincide in **2/9 sezioni file-backed**; 7/9 differiscono, per **56.727 B reali** (altri 1.999 B apparenti esclusi dalle S_ZEROFILL).

**Conseguenza:** l’identità del **codice embedded** è **`e521` (PROVEN)**; l’identità del **file completo**, della firma e il runtime restano **UNPROVEN**. La conclusione precedente “variante esatta non provata” resta valida solo per il file completo, non per `__text`/sezioni.
