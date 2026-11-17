# T27 — AGENT-AMD — BOOTKC CODE INTEGRITY

**Scope:** capire perché `otool` non disassembla `__text`; verificare se il codice loader è realmente nel BootKC; confrontare `LC_SEGMENT_64`, `LC_FILESET_ENTRY`, UUID e hash con i donor.

**Modalità:** sola lettura; parsing Mach-O, `stat`, `shasum`, ispezione dei prologhi; nessuna estrazione, modifica o boot.

**Esito:** il codice **è incorporato** in `__TEXT_EXEC` (`fileoff 0xE8000`, `filesize = vmsize = 0xA14000`), ma il segmento ha **0 sezioni**. `otool` non disassembla perché non esiste una sezione `__text` con codice: `__PRELINK_TEXT,__text` ha **size 0** e `__HIB,__text` è **data**. `readPrelinkedExtensions` e `addKextsFromKextCollection` hanno prologhi reali e corpo. Nessun donor coincide. T27 resta **OPEN**.

---

## 1. Header

| Campo | Valore |
|---|---|
| Magic | **0xFEEDFACF** |
| Filetype | **0xC** |
| `ncmds` | **831** |
| Size | **67.600.384 B** |
| UUID | **63C931A6A4C0AB5DE2FBD1712B1143DB** |
| SHA-256 | **9BB053CF695957C13CE4B5497490B1F24AB69FEA1CDEED57138580A8235BA840** |
| `LC_FILESET_ENTRY` | **204** |

**PROVEN:** il file è un Mach-O fileset valido.
**PROVEN:** contiene 204 entry.

---

## 2. Segmenti chiave

| Segmento | vmaddr | vmsize | fileoff | filesize | sezioni |
|---|---:|---:|---:|---:|---:|
| `__TEXT` | `0xFFFFFF8000200000` | `0x10000` | `0x0` | `0x10000` | **0** |
| `__TEXT_EXEC` | `0xFFFFFF80002E8000` | `0xA14000` | `0xE8000` | `0xA14000` | **0** |
| `__PRELINK_TEXT` | `0xFFFFFF8000210000` | `0x0` | `0x10000` | `0x0` | **1** |
| `__HIB` | `0xFFFFFF8000100000` | `0x100000` | `0x126C000` | `0x100000` | **1** |
| `__LINKEDIT` | `0xFFFFFF8003404000` | `0xD74000` | `0x3304000` | `0xD74000` | **0** |

**PROVEN:** `__TEXT_EXEC` ha **filesize = vmsize**.
**PROVEN:** `__TEXT_EXEC` ha **0 sezioni**.
**PROVEN:** il codice è **incorporato**, non esterno.

---

## 3. Sezioni

| Segmento | Sezione | addr | size | offset | flags |
|---|---|---:|---:|---:|---:|
| `__PRELINK_TEXT` | `__text` | `0xFFFFFF8000210000` | **0x0** | `0x10000` | **0x80000400** |
| `__PRELINK_INFO` | `__info` | `0xFFFFFF8000CFC000` | `0x454000` | `0xAFC000` | **0x0** |
| `__HIB` | `__text` | `0xFFFFFF8000100000` | `0x100000` | `0x126C000` | **0x400** |

**PROVEN:** l’unica `__text` con flag istruzioni ha **size 0**.
**PROVEN:** `__HIB,__text` ha flag **0x400**, non `S_ATTR_PURE_INSTRUCTIONS`.
**PROVEN:** non esiste una sezione codice utilizzabile.

---

## 4. Perché `otool` non disassembla

| Causa | Evidenza |
|---|---|
| `__TEXT_EXEC` senza sezioni | **nsects = 0** |
| `__PRELINK_TEXT,__text` vuota | **size 0** |
| `__HIB,__text` è data | **flags 0x400** |
| `objdump -h` vede 3 sezioni | **nessuna codice** |
| `otool` stampa `(__TEXT,__text)` vuoto | **coerente** |

**PROVEN:** `otool` non ha una sezione codice da disassemblare.
**PROVEN:** il codice non è corrotto o assente; è **non sezionato**.

---

## 5. `LC_FILESET_ENTRY`

| Entry | vmaddr | fileoff | Match |
|---|---:|---:|---|
| **#0** | **0xFFFFFF80002E8000** | **0xE8000** | **`__TEXT_EXEC`** |
| #1 | `0xFFFFFF800146C000` | `0x136C000` | `__REGION0` |
| #2 | `0xFFFFFF8001475000` | `0x1375000` | `__REGION2` |

**PROVEN:** la prima entry coincide con `__TEXT_EXEC`.
**PROVEN:** `fileoff`/`vmaddr` sono coerenti con il segmento.
**PROVEN:** `filesize`/`vmsize` sono nel `LC_SEGMENT_64`, non nella entry.

---

## 6. Codice di `readPrelinkedExtensions` e `addKextsFromKextCollection`

| Funzione | vmaddr | fileoff | Segmento | Primi byte | Non-zero |
|---|---:|---:|---|---|---:|
| `readPrelinkedExtensions` | `0xFFFFFF8000CE87B0` | **0xAE87B0** | `__TEXT_EXEC` | `55 48 89 E5 41 57 41 56 53 48 83 EC 18 41 89 D6` | **520/592** |
| `addKextsFromKextCollection` (1) | `0xFFFFFF8000A33E10` | **0x833E10** | `__TEXT_EXEC` | `55 48 89 E5 41 57 41 56 53 50 48 89 CB 48 C7 45` | **515/592** |
| `addKextsFromKextCollection` (2) | `0xFFFFFF8000A33E60` | **0x833E60** | `__TEXT_EXEC` | `55 48 89 E5 41 57 41 56 41 55 41 54 53 48 81 EC` | **517/592** |

**PROVEN:** tutti iniziano con prologo `push rbp; mov rbp, rsp`.
**PROVEN:** il corpo è presente e non è uno stub.
**PROVEN:** gli offset cadono in `__TEXT_EXEC` (`0xE8000–0xAFC000`).

---

## 7. Confronto donor

| File | UUID | SHA-256 (primi 16) | Size | Entry | `__TEXT_EXEC` vm/fileoff/fs |
|---|---|---|---:|---:|---|
| **Target** | **63C931A6…** | **9BB053CF…** | **67.600.384** | **204** | **0x2E8000 / 0xE8000 / 0xA14000** |
| T4 | A10A9F1B… | 7386434E… | 65.011.712 | 203 | 0x2F0000 / 0xF0000 / 0xA58000 |
| T4 bindinput | A10A9F1B… | 7386434E… | 65.011.712 | 203 | 0x2F0000 / 0xF0000 / 0xA58000 |
| T3 | 252CABB5… | B3CB72D1… | 18.055.168 | 1 | 0x2E4000 / 0xE4000 / 0xA58000 |

**PROVEN:** UUID e hash del target sono diversi da tutti i donor.
**PROVEN:** T4 e T4-bindinput sono identici.
**PROVEN:** il target ha 204 entry, T4 203, T3 1.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| Codice incorporato? | **SÌ — `__TEXT_EXEC`** |
| Compresso? | **NO — fs = vs** |
| Esterno? | **NO** |
| Stub? | **NO — prologhi e corpo** |
| `__TEXT_EXEC` sezionato? | **NO — nsects 0** |
| `otool` può disassemblare? | **NO — nessuna sezione codice** |
| `LC_FILESET_ENTRY` coerente? | **SÌ — prima entry = `__TEXT_EXEC`** |
| Donor coincidente? | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il codice è **realmente presente** in `__TEXT_EXEC`, incorporato e non compresso; `otool` non lo disassembla perché il segmento non ha sezioni e l’unica `__text` con flag istruzioni è vuota. `readPrelinkedExtensions` e `addKextsFromKextCollection` hanno prologo e corpo reali. La prima `LC_FILESET_ENTRY` coincide con `__TEXT_EXEC`. Nessun donor coincide per UUID/hash. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
