# T27 — AGENT-AMD — AMD10000 AUTH ADDRESS RECONSTRUCTION

**Scope:** risolvere i **17 auth pointer** attribuiti ad **AMD10000Controller** ma privi di sezione/file offset, ricostruendo `LC_FILESET_ENTRY`, segmenti, `vmaddr`, `fileoff`, `_PrelinkExecutableSize`, UUID e confrontando indirizzi assoluti/relativi. Verificare separatamente i **38 target anomali** e l’anomalia X6100.

**Modalità:** sola lettura; parsing SystemKC, `LC_FILESET_ENTRY`, sezioni, chained fixups, `nm`. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** **0/17** target AMD10000 cadono in un segmento dell’immagine embedded. `LC_FILESET_ENTRY` dà **vmaddr `0x188000`**, **fileoff `1.605.632`**, UUID `B52EC43A-…`; i target sono **0x3E4000–0x14400078**, tutti **fuori** da `__TEXT`/`__DATA`/`__DATA_CONST`/`__LINKEDIT`. **`_PrelinkExecutableSize` non è un simbolo separato**; `__TEXT` filesize è **385.024**. I **17** restano **UNPROVEN**. I **38** esterni restano fuori KC. T27 resta **OPEN**.

---

## 1. `LC_FILESET_ENTRY` AMD10000Controller

| Campo | Valore |
|---|---:|
| Bundle | `com.apple.kext.AMD10000Controller` |
| `vmaddr` | **`0x188000`** |
| `fileoff` | **1.605.632** (`0x188000`) |
| UUID | **`B52EC43A-4077-3460-A1F5-4BC94CE9CCF7`** |
| `_PrelinkExecutableSize` | **non trovato come simbolo** |
| `__TEXT` filesize | **385.024** |

---

## 2. Segmenti

| Segmento | VM address | Size | File offset |
|---|---:|---:|---:|
| **`__TEXT`** | `0x188000` | `0x5E000` | `0x188000` |
| **`__DATA`** | `0x1E6000` | `0x1E000` | `0x1E6000` |
| **`__DATA_CONST`** | `0x204000` | `0x2000` | `0x204000` |
| **`__LINKEDIT`** | **`0x153A0000`** | **`0xC5A677`** | `0x153A0000` |

**PROVEN:** l’immagine utile è **`0x188000–0x206000`**; `__LINKEDIT` è separato a **`0x153A0000`**.

---

## 3. I 17 target

| Target | `target − vmaddr` | Segmento | File offset | Stato |
|---:|---:|---|---:|---|
| `0x10C48348` | `0x10AC0348` | **NO** | **NO** | **UNPROVEN** |
| `0x15341C0` | `0x13AC1C0` | **NO** | **NO** | **UNPROVEN** |
| `0x258840F` | `0x240040F` | **NO** | **NO** | **UNPROVEN** |
| `0x2D08E89` | `0x2B80E89` | **NO** | **NO** | **UNPROVEN** |
| `0x167850F` | `0x14F050F` | **NO** | **NO** | **UNPROVEN** |
| `0x348783C` | `0x32FF83C` | **NO** | **NO** | **UNPROVEN** |
| `0x803E1C1` | `0x7EB61C1` | **NO** | **NO** | **UNPROVEN** |
| `0xA0B68B` | `0x88368B` | **NO** | **NO** | **UNPROVEN** |
| `0x14B68D49` | `0x149E0D49` | **NO** | **NO** | **UNPROVEN** |
| `0x133FE857` | `0x13276857` | **NO** | **NO** | **UNPROVEN** |
| `0x42C001D` | `0x413801D` | **NO** | **NO** | **UNPROVEN** |
| `0xE81C078` | `0xE694078` | **NO** | **NO** | **UNPROVEN** |
| `0x3E4000` | `0x25C000` | **NO** | **NO** | **UNPROVEN** |
| `0xE5C0340` | `0xE438340` | **NO** | **NO** | **UNPROVEN** |
| `0xCC00037` | `0xCA78037` | **NO** | **NO** | **UNPROVEN** |
| `0x4B30228` | `0x49A8228` | **NO** | **NO** | **UNPROVEN** |
| `0x14400078` | `0x14278078` | **NO** | **NO** | **UNPROVEN** |

**PROVEN:** **0/17** cadono nei segmenti `0x188000–0x206000` o in `__LINKEDIT`.
**PROVEN:** **nessun** file offset è calcolabile.
**INFERRED:** i 17 valori non sono **vmaddr assoluti** validi per questa immagine.
**UNPROVEN:** se siano offset relativi, valori prelink diversi o dati non canonici.

---

## 4. Assoluto, relativo, base

| Verifica | Esito |
|---|---|
| Target in `__TEXT`/`__DATA`/`__DATA_CONST` | **NO** |
| Target in `__LINKEDIT` | **NO** |
| Target = `vmaddr + offset` noto | **NO** |
| Target = file offset | **NO** |
| Target = target X6100/X4000 | **NO** |
| `_PrelinkExecutableSize` separato | **NO** |

**PROVEN:** nessuna delle quattro interpretazioni risolve i 17 target.
**UNPROVEN:** la codifica corretta; senza runtime o base kernel non è ricostruibile.

---

## 5. I 38 target anomali

| Classe | Esempi | Stato |
|---|---|---:|
| **Null/small** | `0x0`, `0x1`, `0x7`, `0x20A`, `0x4A6`, `0x550`, `0x8B1` | **non canonici** |
| **Alti** | `0x3FFFFB28`, `0x3F8C007F`, `0x3E8203F2`, `0x39C02C43` | **esterni** |
| **Medi** | `0x1B102270`, `0x2A48E8DF`, `0x16415341` ×2 | **esterni** |

**PROVEN:** **38/38** non ricadono in alcun provider.
**PROVEN:** **8** valori non sono indirizzi VM canonici.
**UNPROVEN:** la provenienza; **non attribuibili** senza kernel/runtime.

---

## 6. X6100

| Target | Provider | Sezione | Simbolo | Stato |
|---:|---|---|---|---|
| **`0x12AA488`** | X4000 | **`__DATA,__data`** | **`_polaris10_kicker_smc_firmware + 0x100D8`** | **risolto** |

**PROVEN:** **1/56** target è **risolto** e **1/56** è auth verso **firmware/dati**.
**PROVEN:** X6100 è **l’unico** caso confermato.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| 17 target in segmento AMD10000? | **NO** |
| 17 file offset? | **NO** |
| 17 risolti? | **NO — UNPROVEN** |
| `_PrelinkExecutableSize`? | **non separato** |
| 38 target in KC? | **NO** |
| 38 canonici? | **NO — 8 non canonici** |
| Nuovi provider AMD? | **NO** |
| X6100 target risolto? | **SÌ, `0x12AA488`** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** i **17** target AMD10000 **non sono indirizzi vm/file validi** per l’immagine embedded; `LC_FILESET_ENTRY` e i segmenti non li coprono. I **38** restano esterni, con **8** non canonici. **Nessun nuovo provider AMD**; l’unico target risolto resta **`0x12AA488` X4000**. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
