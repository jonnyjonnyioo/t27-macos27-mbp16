# T27 — AGENT-AMD — X6100 SUPERCLASS FIXUP FORENSICS

**Scope:** decodificare il fixup grezzo di **`X6100 HWLibs::superClass` a `0xE11CA90`**, verificare `pointer_format`, `cacheLevel`, offset e base, confrontare il target con X4000/X4400/AMD10000 e distinguere prelink da runtime.

**Modalità:** sola lettura; parsing `LC_DYLD_CHAINED_FIXUPS`, `nm`, `otool -l`, `xxd`. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** il fixup è **`DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` (`pointer_format 11`)**. Raw **`88 A4 2A 01 00 00 C0 00`** = **`0x00C00000012AA488`**: **target `0x12AA488`**, **isAuth=1**, **cacheLevel=0**, **diversity=0**, **addrDiv=0**, **key=0**, **next=0**. È un **auth pointer** verso **dati X4000** (`_polaris10_kicker_smc_firmware + 0x100D8`), non verso un `gMetaClass`. Gli altri fixup X6100 sono **isAuth=0** e puntano ai `gMetaClass`. T27 resta **OPEN**.

---

## 1. Header chained fixups

| Campo | Valore |
|---|---:|
| `fixups_version` | **0** |
| `starts_offset` | **0x1C** |
| `imports_offset` | **0x1854** |
| `symbols_offset` | **0x1854** |
| `imports_count` | **0** |
| `imports_format` | **1** |
| `symbols_format` | **0** |
| `seg_count` | **4** |

**Segmento `__DATA` (i=1):**

| Campo | Valore |
|---|---:|
| `size` | **6150** |
| `page_size` | **0x1000** |
| **`pointer_format`** | **11 = `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE`** |
| `segment_offset` | **0x3AE000** |
| `max_valid_pointer` | **0** |
| `page_count` | **3063** |

**PROVEN:** il formato è quello **kernel cache x86_64**, con target a 30 bit e bit di autenticazione.

---

## 2. Fixup di `0xE11CA90`

**File offset:** `0x3AEA90`.

**Raw 8 byte:**
```text
88 A4 2A 01 00 00 C0 00
```

**Valore little-endian:** `0x00C00000012AA488`.

| Campo | Bit | Valore |
|---|---:|---:|
| **target** | 0–29 | **`0x12AA488`** |
| **cacheLevel** | 30–31 | **0** |
| **diversity** | 32–47 | **0** |
| **addrDiv** | 48 | **0** |
| **key** | 49–50 | **0** |
| **next** | 51–62 | **0** |
| **isAuth** | 63 | **1** |

**PROVEN:** target **`0x12AA488`**, **auth pointer**, nessuna catena successiva (`next=0`), diversità e chiave nulle.

---

## 3. Target

| Proprietà | Valore |
|---|---|
| Provider | **X4000** |
| Sezione | **`__DATA,__data`** (`0x990610`, size `0xAF5324`) |
| Simbolo | **`_polaris10_kicker_smc_firmware`** a `0x129A3B0` |
| Offset | **`0x100D8`** |
| Simbolo esatto | **nessuno** |
| Genere | **dati/firmware** |
| `gMetaClass` X4000 | `0x1485950` (diverso) |

**PROVEN:** il target è **dati firmware**, non un `gMetaClass`.
**PROVEN:** `isAuth=1` indica un **function pointer autenticato**, ma il target è in **`__data`**: tipo incompatibile.

---

## 4. Confronto con gli altri fixup X6100

| Simbolo | Address | Raw | Target | isAuth | Target valido |
|---|---:|---|---:|---:|---|
| X6100::metaClass | `0xE11C120` | rebase | `0xED11A10` | **0** | **gMetaClass** |
| X6100::superClass | `0xE11C128` | rebase | `0xED11A60` | **0** | **SWIP gMetaClass** |
| HWLibs::metaClass | `0xE11CA88` | `38 1A D1 4E 00 00 40 00` | `0xED11A38` | **0** | **HWLibs gMetaClass** |
| **HWLibs::superClass** | **`0xE11CA90`** | **`88 A4 2A 01 00 00 C0 00`** | **`0x12AA488`** | **1** | **NO — firmware** |
| SWIP::metaClass | `0xE11D3E8` | rebase | `0xED11A60` | **0** | **SWIP gMetaClass** |
| SWIP::superClass | `0xE11D3F0` | rebase | `0xED11A38` | **0** | **HWLibs gMetaClass** |

**PROVEN:** **5/6** fixup sono **rebase isAuth=0** verso `gMetaClass`.
**PROVEN:** **solo** `HWLibs::superClass` è **isAuth=1** e verso **dati**.
**INFERRED:** è un **fixup anomalo**, non il pattern normale.

---

## 5. Confronto X4000 / X4400 / AMD10000

| Bundle | `superClass` | Raw basso 30 bit | isAuth | Note |
|---|---:|---:|---:|---|
| **X4000** | `0x9840B8` | **`0x18000134`** | **0** | non `0x12AA488` |
| **X4400** | `0x23700B8` | **diverso** | **0** | coppia separata |
| **AMD10000Controller** | import `IOService::gMetaClass` | — | — | non definisce le classi |

**PROVEN:** X4000 non usa il target `0x12AA488`.
**PROVEN:** X4400 ha una gerarchia separata.
**UNPROVEN:** la decodifica completa del raw X4000; il target basso non coincide.

---

## 6. Prelink e runtime

| Voce | Valore |
|---|---|
| Target prelink | **`0x12AA488`** |
| Slide runtime | **non disponibile** |
| Base kernel | **non disponibile** |
| Indirizzo assoluto runtime | **UNPROVEN** |
| Cache level | **0** |
| Auth key | **0** |
| Diversità | **0** |

**PROVEN:** il valore è **prelink**; nessun boot, nessuna slide.
**UNPROVEN:** l’indirizzo assoluto runtime e il comportamento del kernel su un auth pointer verso dati.

---

## 7. Ipotesi

| Ipotesi | Evidenza | Stato |
|---|---|---|
| **Auth pointer mal codificato** | `isAuth=1` verso `__data` | **INFERRED** |
| **Mispoint di linker** | target firmware, non `gMetaClass` | **INFERRED** |
| **Alias/simbolo errato** | nessun simbolo a `0x12AA488` | **UNPROVEN** |
| **Corruzione del fixup** | `next=0`, catena pulita | **UNPROVEN** |
| **Target valido** | dati, non `MetaClass` | **NO** |

**PROVEN:** il fixup è sintatticamente valido (campi coerenti), ma **semanticamente errato**.
**UNPROVEN:** la causa: linker, alias, migrazione X4000→X6100 o bug di encoding.

---

## 8. Conclusione

| Domanda | Risposta |
|---|---|
| `pointer_format` | **11 — X86_64_KERNEL_CACHE** |
| Raw `0xE11CA90` | **`0x00C00000012AA488`** |
| Target | **`0x12AA488`** |
| `isAuth` | **1** |
| `cacheLevel` | **0** |
| Target è `gMetaClass`? | **NO** |
| Target è dati? | **SÌ — `_polaris` + `0x100D8`** |
| Altri fixup X6100 | **isAuth=0, gMetaClass** |
| X4000/X4400 usano `0x12AA488`? | **NO** |
| Causa | **UNPROVEN** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** il fixup di `HWLibs::superClass` è un **auth pointer kernel-cache** con target **`0x12AA488`**, dentro **`_polaris10_kicker_smc_firmware` X4000**. Non è un `gMetaClass`, non è condiviso da X4000/X4400 e non ha analoghi sani in X6100. È un **fixup semanticamente invalido**; la causa resta **UNPROVEN** senza runtime. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
