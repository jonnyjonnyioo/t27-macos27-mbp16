# T27 — AGENT-AMD — AUTH TARGET RESOLUTION

**Scope:** risolvere i **38 target autenticati unknown** e verificare se appartengano a provider AMD non attribuiti. Classificare tutti i **56 auth pointer** per target, provider, UUID, sezione, simbolo, `cacheLevel`, VM address e file offset.

**Modalità:** sola lettura; parsing SystemKC, provider, sezioni, UUID, chained fixups, `nm`. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** **38/56** target restano **esterni al SystemKC** e non attribuibili. **17/56** cadono nel **range** di `AMD10000Controller`, ma **non** in una sezione/file offset risolvibile. **1/56** è in **X4000** (`_polaris10_kicker_smc_firmware + 0x100D8`). **0** verso `gMetaClass`. L’anomalia X6100 resta **l’unico auth pointer confermato verso firmware/dati**. T27 resta **OPEN**.

---

## 1. Totali

| Voce | Valore |
|---|---:|
| Provider SystemKC | **172** |
| Auth pointer totali | **56** |
| Target esterni/unknown | **38** |
| Target in range AMD10000Controller | **17** |
| Target X4000 risolto | **1** |
| Target `gMetaClass` | **0** |

**PROVEN:** **38** target non ricadono in alcun provider; **17** ricadono nel range AMD10000; **1** è X4000.

---

## 2. Sorgenti e UUID

| Bundle sorgente | Auth | UUID |
|---|---:|---|
| **`com.apple.kext.AMDRadeonX4000HWLibs`** | **50** | `DFD77453-7CFD-3F72-8BFE-779582EA4E73` |
| **`com.apple.kext.AMDRadeonX4000`** | **5** | `5D0B64FE-9944-3382-A0FA-26D1CAC4BC01` |
| **`com.apple.kext.AMDRadeonX6100HWLibs`** | **1** | `533D1262-BE83-3507-B48A-FDB91C9D8793` |
| **Totale** | **56** | |

**PROVEN:** **55/56** provengono da X4000; **1** da X6100.

---

## 3. Target noti

### 3.1 X4000 — 1/56

| Proprietà | Valore |
|---|---|
| Target | **`0x12AA488`** |
| Provider | **`com.apple.kext.AMDRadeonX4000HWLibs`** |
| UUID | `DFD77453-7CFD-3F72-8BFE-779582EA4E73` |
| Sezione | **`__DATA,__data`** |
| Simbolo | **`_polaris10_kicker_smc_firmware`** a `0x129A3B0` |
| Offset | **`+0x100D8`** |
| `cacheLevel` | **0** |
| Sorgente | **X6100 `0xE11CA90`** |
| File offset | **non risolto con certezza** |

**PROVEN:** è l’unico target autenticato **noto** verso **firmware/dati**.
**UNPROVEN:** il file offset esatto; la sezione è `__data`.

### 3.2 AMD10000Controller — 17/56

| Target | Provider range | Sezione | File offset | Simbolo |
|---:|---|---|---|---|
| `0x10C48348` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x15341C0` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x258840F` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x2D08E89` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x167850F` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x348783C` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x803E1C1` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0xA0B68B` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x14B68D49` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x133FE857` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x42C001D` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0xE81C078` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x3E4000` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0xE5C0340` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0xCC00037` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x4B30228` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |
| `0x14400078` | AMD10000Controller | **?** | **NO** | `kalloc_type_view_338` |

**PROVEN:** i 17 indirizzi cadono nel **range** del provider AMD10000Controller.
**UNPROVEN:** che siano **sezioni/file offset reali**; il simbolo nearest è **solo il più vicino**, non il target.
**UNPROVEN:** che siano **auth function pointer** validi.

---

## 4. Target esterni — 38/56

| Target | `cacheLevel` | Sorgente |
|---:|---:|---|
| `0x3FFFFB28` | 3 | X4000 |
| `0x3F8C007F` | 2 | X4000 |
| `0x3E8203F2` | 2 | X4000 |
| `0x39C02C43` | 1 | X4000 |
| `0x1B102270` | 0 | X4000 |
| `0x2A48E8DF` | 1 | X4000HWLibs |
| `0x30BE` | 0 | X4000HWLibs |
| `0x1A7BE8F8` | 1 | X4000HWLibs |
| `0x550` | 0 | X4000HWLibs |
| `0x2787E853` | 3 | X4000HWLibs |
| `0x3EE83E8B` | 1 | X4000HWLibs |
| `0x20FF5D16` | 3 | X4000HWLibs |
| `0x28187B8B` | 3 | X4000HWLibs |
| `0x16415341` | 1 | X4000HWLibs |
| `0x16415341` | 1 | X4000HWLibs |
| `0x3F854D3E` | 3 | X4000HWLibs |
| `0x1F894800` | 3 | X4000HWLibs |
| `0x2FF73D8D` | 3 | X4000HWLibs |
| `0x1` | 0 | X4000HWLibs |
| `0x1D5F415E` | 1 | X4000HWLibs |
| `0x3FFFFEEE` | 3 | X4000HWLibs |
| `0x334FE856` | 2 | X4000HWLibs |
| `0x3C3F3D8D` | 3 | X4000HWLibs |
| `0x0` | 0 | X4000HWLibs |
| `0x2B851FC1` | 3 | X4000HWLibs |
| `0x7` | 0 | X4000HWLibs |
| `0x1780000E` | 2 | X4000HWLibs |
| `0x20A` | 2 | X4000HWLibs |
| `0x4A6` | 2 | X4000HWLibs |
| `0x3C408001` | 1 | X4000HWLibs |
| `0x2B300000` | 0 | X4000HWLibs |
| `0x26680001` | 0 | X4000HWLibs |
| `0x28CC0008` | 0 | X4000HWLibs |
| `0x16400001` | 2 | X4000HWLibs |
| `0x3D30EC6F` | 0 | X4000HWLibs |
| `0x8B1` | 2 | X4000HWLibs |
| `0x1A000002` | 2 | X4000HWLibs |
| `0x3DAD8009` | 1 | X4000HWLibs |

**PROVEN:** **38/38** non ricadono in alcun provider del SystemKC.
**UNPROVEN:** la provenienza; potrebbero essere **kernel text esterno**, **indirizzi prelink non ricostruibili** o **valori non canonici**. I target **`0x0`, `0x1`, `0x7`, `0x20A`, `0x4A6`, `0x550`, `0x8B1`, `0x30BE`** non sono indirizzi VM canonici.

---

## 5. Cache e pattern

| Campo | Distribuzione |
|---|---|
| **cacheLevel** | **3:17, 0:16, 2:12, 1:11** |
| **key** | **0:39, 1:6, 2:6, 3:5** |
| **addrDiv** | **0:31, 1:25** |
| **diversity=0** | **8** |
| **target unici** | **54** (2 duplicati `0x16415341`) |

**PROVEN:** **38** target sono esterni; **17** in range AMD10000; **1** X4000.
**PROVEN:** **0** target `gMetaClass`.

---

## 6. X6100

| Simbolo | Auth | Target | Target valido |
|---|---:|---:|---|
| X6100::metaClass | 0 | `0xED11A10` | **gMetaClass** |
| X6100::superClass | 0 | `0xED11A60` | **SWIP gMetaClass** |
| HWLibs::metaClass | 0 | `0xED11A38` | **HWLibs gMetaClass** |
| **HWLibs::superClass** | **1** | **`0x12AA488`** | **NO — firmware** |
| SWIP::metaClass | 0 | `0xED11A60` | **SWIP gMetaClass** |
| SWIP::superClass | 0 | `0xED11A38` | **HWLibs gMetaClass** |

**PROVEN:** **5/6** non-auth e validi; **1/6** auth e invalido.
**PROVEN:** X6100 è l’unico con auth verso firmware/dati.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Auth totali | **56** |
| Target esterni | **38** |
| Target AMD10000 range | **17** |
| Target X4000 risolto | **1** |
| Target `gMetaClass` | **0** |
| Nuovi provider AMD? | **NO** |
| Target AMD10000 con sezione/file offset? | **NO** |
| X6100 auth verso firmware | **1** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** **38** target restano **esterni** e non attribuibili; **17** cadono nel **range** AMD10000 ma **senza sezione/file offset**; **1** è il target X4000 `_polaris`. **Nessun nuovo provider AMD** emerge. L’anomalia X6100 resta **l’unico auth pointer confermato verso firmware/dati**. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
