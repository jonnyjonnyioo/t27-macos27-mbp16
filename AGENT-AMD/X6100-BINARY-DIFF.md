# T27 — AGENT-AMD — X6100HWLIBS BINARY DIFF

**Scope:** determinare quali differenze strutturali distinguono `AMDRadeonX6100HWLibs` in `systemkc-all` (16.985.840 B) dalla copia root2 (17.256.336 B), senza attribuire provenienza o compatibilità non dimostrate.  
**Modalità:** sola lettura; `shasum`, `dwarfdump`, `otool -l`, `otool -L`, `nm -gU`, `cmp -l`, `stat`. Nessuna copia, estrazione, build, firma o boot.  
**Esito:** i due file **non sono identici**: SHA diverso, 537.388 byte differenti nei primi 16.985.840 B, più 270.496 B solo root2. UUID, `LC_SOURCE_VERSION` e i 72 export hanno gli stessi nomi; cambiano indirizzi, code, `__DATA`, `__LINKEDIT` e firma.

---

## 1. Identità

| Campo | `systemkc-all` | root2 |
|---|---|---|
| Percorso | `.../work/systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` | `.../root2/.../AMDRadeonX6100HWLibs.kext/Contents/MacOS/AMDRadeonX6100HWLibs` |
| Byte | 16.985.840 | 17.256.336 |
| SHA-256 | `e521d3cce8f9bb027642897fed8754ff4d9ef66dd08a8d13ab318e0c2db01bb5` | `00b6214e4771d84f2cda4a9943fceafaac0e632f57fbfda20e6ee5cbf051d61f` |
| UUID | `533D1262-BE83-3507-B48A-FDB91C9D8793` | uguale |
| Arch | x86_64 | x86_64 |
| `LC_SOURCE_VERSION` | `7.1.11` | `7.1.11` |

**UUID uguale, SHA diverso:** l’identità di build non è dimostrata.

---

## 2. Segmenti

| Segmento | systemkc vmaddr / fileoff / filesize | root2 vmaddr / fileoff / filesize | Delta filesize |
|---|---|---|---:|
| `__TEXT` | `0xdd6e000` / 0 / 3.858.432 | `0x0` / 0 / 3.858.432 | 0 |
| `__DATA` | `0xe11c000` / 3.858.432 / 12.541.952 | `0x3ae000` / 3.858.432 / 12.541.952 | 0 |
| `__DATA_CONST` | `0xed13000` / 16.400.384 / 4.096 | `0xfa5000` / 16.400.384 / 4.096 | 0 |
| `__LINKEDIT` | `0x1539c000` / 16.404.480 / 581.360 | `0xfa6000` / 16.404.480 / 851.856 | **+270.496** |

Tutti i `vmaddr` di systemkc sono root2 **+ `0xdd6e000`**. I primi tre segmenti hanno **identici fileoff e filesize**; cambia solo `__LINKEDIT`.

`__TEXT` contiene `__text` (offset 2.400), `__cstring` (offset 2.364.726) e `__const` (offset 2.873.152). `__DATA` e `__DATA_CONST` hanno gli stessi offset in entrambi.

### 2.1 Code signature

| Campo | `systemkc-all` | root2 |
|---|---|---|
| `LC_CODE_SIGNATURE` | **ASSENTE** | presente |
| `dataoff` | — | `17.104.352` |
| `datasize` | — | `151.984` |

Root2 termina a 17.256.336 = 17.104.352 + 151.984. La firma è **solo root2**. Il delta `__LINKEDIT` di 270.496 B comprende 151.984 B di firma e **118.512 B** di linkedit aggiuntivo prima della firma.

---

## 3. Hash per intervallo e differenze byte

| Intervallo | Offset / lunghezza | SHA systemkc | SHA root2 | Byte diversi (`cmp -l`) |
|---|---|---|---:|---:|
| header | 0 / 2.400 | `603a55fb…` | `a7fb2cc2…` | **89** |
| `__text` | 2.400 / 2.362.326 | `19dcb85d…` | `c65134cb…` | **21.383** |
| `__cstring` | 2.364.726 / 508.426 | `9851055a…` | `9851055a…` | **0** |
| `__const` | 2.873.152 / 985.280 | `fd5b170c…` | `fd5b170c…` | **0** |
| `__DATA` | 3.858.432 / 12.541.952 | `8c8a7400…` | `aa5dccec…` | **35.319** |
| `__DATA_CONST` | 16.400.384 / 4.096 | `23078b60…` | `1e5b12a1…` | **25** |
| `__LINKEDIT` | 16.404.480 / 581.360 | `330e52b0…` | `40abc76d…` | **480.572** |
| **totale confrontato** | 16.985.840 | — | — | **537.388** |

- Primo byte differente: **17** (header, offset 0x10).
- Ultimo byte differente confrontato: **16.985.840**, fine del file systemkc.
- Root2 ha **270.496 B in più**, non confrontati da `cmp` perché oltre la fine di systemkc.

`__cstring` e `__const` sono **byte-identici**. `__text`, `__DATA`, `__DATA_CONST` e `__LINKEDIT` differiscono.

---

## 4. Load commands e collegamento

| Comando | systemkc | root2 |
|---|---|---|
| `LC_SEGMENT_64` | 4 | 4 |
| `LC_UUID` | 1 | 1 |
| `LC_SOURCE_VERSION` | 1 (`7.1.11`) | 1 (`7.1.11`) |
| `LC_SYMTAB` | 1 | 1 |
| `LC_DYSYMTAB` | 1 | 1 |
| `LC_CODE_SIGNATURE` | **0** | **1** |
| `LC_LOAD_DYLIB` / dipendenze | **0** | **0** |

`otool -L` non mostra dipendenze in nessuno dei due.

### 4.1 Symbol table

| Campo | systemkc | root2 | Delta |
|---|---:|---:|---:|
| `symoff` | 16.404.480 | 16.465.744 | +61.264 |
| `nsyms` | 12.602 | 12.917 | +315 |
| `stroff` | 16.606.232 | 16.722.480 | +116.248 |
| `strsize` | 379.608 | 381.864 | +2.256 |
| local symbols | 12.182 | 12.497 | +315 |
| external defined | 72 | 72 | 0 |
| undefined | 348 | 348 | 0 |

I **72 export esterni hanno gli stessi nomi**; gli indirizzi differiscono tutti di `0xdd6e000`.

Il delta `__LINKEDIT` pre-firma di 118.512 B si scompone con i valori misurati:

| Voce | Delta |
|---|---:|
| `symoff` | +61.264 |
| symtab (315 × 16) | +5.040 |
| gap symtab → `stroff` (120 → 50.064) | +49.944 |
| `strsize` | +2.256 |
| residuo di allineamento | +8 |
| **totale** | **+118.512** |

Il gap di 50.064 B tra fine symtab e inizio string table in root2 non è ulteriormente attribuito dai comandi disponibili.

### 4.2 Export

- `nm -gU`: **72** in entrambi.
- Diff dei **nomi**: **vuoto**.
- Diff degli indirizzi: tutti shiftati di `0xdd6e000`.
- Esempi: `_GLOBAL_VFTTABLE` `0xed11e00` vs `0xfa3e00`; `_PP_AdapterBDFList` `0xed11d80` vs `0xfa3d80`.

---

## 5. Attribuzione delle differenze

### 5.1 MEASURED

- SHA diversi; 537.388 byte differenti su 16.985.840; root2 +270.496 B.
- `__TEXT`, `__DATA`, `__DATA_CONST` hanno **stesse dimensioni** ma `vmaddr` shiftati di `0xdd6e000`.
- `__cstring` e `__const` sono **identici**; `__text` differisce per **21.383 B**.
- `__LINKEDIT` differisce per **480.572 B**; root2 ha `LC_CODE_SIGNATURE` da **151.984 B**, systemkc no.
- UUID e `LC_SOURCE_VERSION` identici; 72 nomi export identici; 0 dipendenze.
- Root2 ha **315 local symbols** in più; extdef/undef invariati.
- SYMTAB/string table offsets e sizes misurati come sopra.

### 5.2 INFERRED

- Root2 è una variante **firmata e ribasata a base 0**; systemkc è **non firmata** e linkata a `0xdd6e000`.
- Le differenze in `__DATA`/`__DATA_CONST` sono **compatibili** con ribasamento di puntatori, ma non sono attribuite una per una.
- I 21.383 B di `__text` indicano che **non è solo una ricollocazione**: il codice macchina non è identico. La causa (build flags, local symbols, patch, strumentazione) resta **UNPROVEN**.
- Il delta di 270.496 B è **coerente** con 151.984 B di firma + 118.512 B di linkedit aggiuntivo; la composizione interna del residuo è solo parzialmente misurata.

### 5.3 UNPROVEN

- Che root2 e systemkc siano lo stesso build/semanticamente equivalenti.
- La direzione della derivazione (root2 → systemkc o viceversa).
- Che la differenza di `__text` sia irrilevante per il caricamento.
- L’ABI con 26B131 e il caricamento su 26B131.

---

## 6. Conclusione

| Domanda | Risposta |
|---|---|
| I due binari sono identici? | **NO**: SHA diversi, 537.388 B differenti |
| Stesso UUID / source version / export names? | **SÌ** |
| Stesse dimensioni `__TEXT`/`__DATA`? | **SÌ** |
| `__cstring`/`__const` identici? | **SÌ** |
| `__text` identico? | **NO**: 21.383 B differenti |
| Root2 ha firma? | **SÌ**, 151.984 B |
| Systemkc ha firma? | **NO** |
| Root2 ha 270.496 B in più? | **SÌ**, incluso linkedit/firma |
| Root2 è copia esatta? | **NO** |
| Stessa provenienza? | **UNPROVEN** |

Root2 è una variante **dello stesso UUID/versione/export surface**, con base 0, firma e linkedit più grande; `systemkc-all` è la variante non firmata linkata a `0xdd6e000`. La differenza di 21.383 B in `__text` impedisce di trattarli come copie byte-equivalenti. Nessuna conclusione di compatibilità 26B131 è autorizzata.

**STOP rispettato:** sola lettura; nessuna copia, estrazione, build, firma o boot. Spazio libero 12.931.192 KiB (12,33 GiB) > 10 GiB.
