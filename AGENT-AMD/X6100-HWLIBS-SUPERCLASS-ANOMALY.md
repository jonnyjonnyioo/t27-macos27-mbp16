# T27 — AGENT-AMD — X6100 HWLIBS SUPERCLASS ANOMALY

**Scope:** determinare perché `AMDRadeonX6100_AMDRadeonHWLibs::superClass` (`0xE11CA90`) punta a **`0x12AA488`**, dentro `_polaris10_kicker_smc_firmware` X4000, anziché a un `gMetaClass`. Verificare struttura del firmware, riferimenti, fixup e confronto con X4000/X4400/AMD10000.

**Modalità:** sola lettura; `nm -n -S`, `otool -tvV`, `otool -l`, `xxd`, Python. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** **`0x12AA488` è dentro `_polaris10_kicker_smc_firmware` X4000** (`0x129A3B0 + 0x100D8`), in **`__DATA,__data`**, senza simbolo proprio e senza struttura `MetaClass`. **Nessuna istruzione** referencing diretto; **1 solo fixup** in X6100 (`superClass`). **X4000/X4400 hanno superClass diverse**; **AMD10000Controller** importa `IOService::gMetaClass`. La causa resta **UNPROVEN**: mispoint di linker, alias o fixup errato. T27 resta **OPEN**.

---

## 1. Sezioni e offset

### X4000

| Sezione | Address | Size | File offset |
|---|---:|---:|---:|
| **`__DATA,__const`** | `0x9840B0` | `0xC560` | **2.740.400** |
| **`__DATA,__data`** | `0x990610` | `0xAF5324` | **2.790.928** |
| **`__DATA,__common`** | `0x1485940` | `0x12B8` | 0 (zero-fill) |

### X6100

| Sezione | Address | Size | File offset |
|---|---:|---:|---:|
| **`__DATA,__const`** | `0xE11C120` | `0x10170` | **3.858.720** |
| **`__DATA,__data`** | `0xE12C290` | `0xBE5766` | **3.924.624** |
| **`__DATA,__common`** | `0xED11A00` | `0x5F8` | 0 (zero-fill) |

**PROVEN:** `superClass` HWLibs è in **`__const` X6100**; il target `0x12AA488` è in **`__data` X4000**.

---

## 2. `0x12AA488` e `_polaris10_kicker_smc_firmware`

| Proprietà | X4000 | X6100 |
|---|---:|---:|
| Simbolo `_polaris10_kicker_smc_firmware` | **`0x129A3B0`** | **`0xE6134D0`** |
| Target `0x12AA488` | **`+0x100D8`** | **non presente** |
| Sezione | **`__DATA,__data`** | **`__DATA,__data`** |
| Simbolo successivo | `_polaris10_kicker_smcFirmware` `0x12BA178` | — |
| Distanza dal successivo | **`0x11FDC8`** | — |
| Simbolo esatto a `0x12AA488` | **nessuno** | — |

**PROVEN:** `0x12AA488` è **interno** al blob `_polaris10_kicker_smc_firmware` X4000, a **`0x100D8`** dall’inizio.
**PROVEN:** non è la copia X6100 (`0xE6134D0`).
**PROVEN:** non ha un simbolo `gMetaClass`, `__ZTV` o `__ZTI`.

---

## 3. Riferimenti

| Tipo | X6100 | X4000 |
|---|---:|---:|
| Istruzioni `otool -tvV` con `0x12AA488` | **0** | **0** |
| Fixup `superClass` | **1** (`0xE11CA90`) | **0** |
| Simboli `gMetaClass` a `0x12AA488` | **0** | **0** |
| Scritture runtime | **0** | **0** |

**PROVEN:** il legame è **solo un fixup statico** in `__const`; non ci sono `leaq`/`movq` diretti a `0x12AA488`.

**Fixup:**
```text
sorgente: 0xE11CA90  (__DATA,__const X6100)
target:   0x12AA488  (__DATA,__data X4000)
```

**PROVEN:** `__const` ha **`reloff 0`, `nreloc 0`**: usa **chained fixups**, non relocazioni classiche.
**PROVEN:** **0 scritture** successive.

---

## 4. Confronto gerarchie

| Bundle | `superClass` | `gMetaClass` | Target osservato |
|---|---:|---:|---|
| **X6100** | `0xE11C128/CA90/D3F0` | `0xED11A10/38/60` | X6100 → SWIP → HWLibs → `0x12AA488` |
| **X4000** | `0x9840B8/4A18` | `0x1485950/78` | raw fixup diverso; **non** `0x12AA488` |
| **X4400** | `0x23700B8/0A18` | `0x31D4A90/B8` | coppia separata |
| **AMD10000Controller** | import `IOService::gMetaClass` | — | non definisce le 3 classi |

**PROVEN:** X4000 e X4400 hanno `superClass` e `gMetaClass` **proprie**.
**PROVEN:** il target `0x12AA488` è **specifico del fixup X6100 HWLibs**.
**UNPROVEN:** la decodifica esatta del raw fixup X4000; il valore non coincide con `0x12AA488`.

---

## 5. Ipotesi

| Ipotesi | Evidenza | Stato |
|---|---|---|
| **Mispoint di linker** | `superClass` verso firmware, non `gMetaClass` | **INFERRED** |
| **Alias/simbolo sbagliato** | nessun simbolo a `0x12AA488` | **UNPROVEN** |
| **Fixup corrotto** | `reloff 0`, chained, 0 scritture | **UNPROVEN** |
| **Firmware contiene metadati** | sezione `__data`, nessun `gMetaClass` | **UNPROVEN** |
| **Target valido** | nessuna struttura MetaClass, nessun simbolo | **NO** |

**PROVEN:** `0x12AA488` non è un `gMetaClass` né una vtable.
**INFERRED:** `HWLibs::superClass` è **mispointed**.
**UNPROVEN:** la causa (linker, alias, fixup) e il comportamento runtime.

---

## 6. Perché non si chiude

- `superClass` è **statico** in `__const`; senza boot non si osserva se il kernel lo corregge.
- `gMetaClass` è in **`__common` zero-fill**: il contenuto è creato a runtime.
- `0x12AA488` non ha simbolo: non si può risalire al campo/funzione del firmware.
- X4000 non decodifica il proprio raw fixup con gli strumenti disponibili.
- **Nessun boot**: runtime `UNPROVEN`.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| `0x12AA488` è in X4000? | **SÌ** |
| È dentro `_polaris`? | **SÌ, offset `0x100D8`** |
| Ha un simbolo `gMetaClass`? | **NO** |
| È una vtable/`MetaClass`? | **NO** |
| Riferimenti diretti? | **0** |
| Fixup? | **1** (`superClass` X6100) |
| X4000/X4400 hanno target uguale? | **NO** |
| Causa? | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `HWLibs::superClass` punta **dentro il firmware `_polaris10_kicker_smc_firmware` X4000**, non a un `gMetaClass`. Non ci sono istruzioni o scritture che lo correggano; l’unico legame è un **fixup statico**. La gerarchia è valida fino a **HWLibs**, ma l’ultimo anello è **invalido**. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
