# T27 — AGENT-AMD — X6100 METACLASS HIERARCHY VALIDATION

**Scope:** verificare la gerarchia **X6100 → SWIP → HWLibs**, il contenuto delle **3 coppie vtable/MetaClass**, i puntatori **`metaClass` / `superClass` / `gMetaClass`** e il target esterno **`0x12AA488`**, indicato come `_polaris10_kicker_smc_firmware`.

**Modalità:** sola lettura; `nm -n -S`, `otool -l`, parsing chained fixups, `xxd`. Nessuna estrazione, modifica, build o boot. Nessuna cancellazione.

**Esito:** **2/3 `superClass` sono validi**: X6100 → SWIP e SWIP → HWLibs. La **`superClass` di HWLibs** punta a **`0x12AA488`**, che cade **dentro `_polaris10_kicker_smc_firmware` in `__DATA,__data` di X4000**, non a un `gMetaClass`. La gerarchia è quindi **X6100 → SWIP → HWLibs → firmware X4000**: l’ultimo anello è **invalido/UNPROVEN**. T27 resta **OPEN**.

---

## 1. Mappa delle sezioni X6100

| Sezione | Address | Size | Uso |
|---|---:|---:|---|
| **`__DATA,__got`** | `0xE11C000` | `0xE8` | GOT |
| **`__DATA,__const`** | `0xE11C120` | `0x10170` | **6 vtable**, `metaClass`, `superClass` |
| **`__DATA,__data`** | `0xE12C290` | `0xBE5766` | dati; `_polaris` X6100 a `0xE6134D0` |
| **`__DATA,__common`** | `0xED11A00` | `0x5F8` | **`gMetaClass`** a `0xED11A10/38/60` |
| **`__DATA,__bss`** | `0xED12000` | `0xAEC` | BSS |

**PROVEN:** le **3 coppie vtable/MetaClass** stanno in **`__const`**; i **3 `gMetaClass`** stanno in **`__common`**, quindi sono **zero-fill** e **non hanno contenuto nel file**.

---

## 2. Le 3 coppie

| Classe | Vtable main | MetaClass | `metaClass` | `superClass` | Target `superClass` |
|---|---|---|---:|---:|---:|
| **X6100** | `__ZTV35` `0xE11C130` | `__ZTVN35` `0xE11C9A0` | `0xE11C120` | `0xE11C128` | **`0xED11A60` = SWIP::gMetaClass** |
| **HWLibs** | `__ZTV30` `0xE11CA98` | `__ZTVN30` `0xE11D300` | `0xE11CA88` | `0xE11CA90` | **`0x12AA488` = firmware X4000** |
| **SWIP** | `__ZTV34` `0xE11D3F8` | `__ZTVN34` `0xE11DC68` | `0xE11D3E8` | `0xE11D3F0` | **`0xED11A38` = HWLibs::gMetaClass** |

**PROVEN:** ogni `metaClass` punta al proprio `gMetaClass`; **X6100** e **SWIP** puntano al `gMetaClass` della classe base.
**PROVEN:** **HWLibs** punta a **`0x12AA488`**, non a un `gMetaClass`.

---

## 3. Gerarchia

```text
X6100::gMetaClass 0xED11A10
  └─ superClass → SWIP::gMetaClass 0xED11A60
       └─ superClass → HWLibs::gMetaClass 0xED11A38
            └─ superClass → 0x12AA488 (X4000 firmware)
```

**PROVEN:** **X6100 → SWIP** e **SWIP → HWLibs**.
**PROVEN:** **HWLibs → `0x12AA488`** come puntatore.
**UNPROVEN/INVALID:** che `0x12AA488` sia un `gMetaClass`.

---

## 4. `0x12AA488`

| Proprietà | Valore |
|---|---|
| Provider | **X4000** |
| Sezione | **`__DATA,__data`** (`0x990610`, size `0xAF5324`) |
| Simbolo precedente | **`_polaris10_kicker_smc_firmware`** a **`0x129A3B0`** |
| Offset nel simbolo | **`0x100D8`** |
| Simbolo esatto a `0x12AA488` | **nessuno** |
| Genere | **firmware/dati**, non `OSMetaClass` |
| Allineamento | 8 byte |

**PROVEN:** `0x12AA488` è **dentro `_polaris10_kicker_smc_firmware`** X4000, non è l’inizio del simbolo e non ha un simbolo proprio.
**PROVEN:** la `_polaris10_kicker_smc_firmware` di **X6100** sta a **`0xE6134D0`**, quindi il target **non è** la copia X6100.

**Conseguenza:** la `superClass` di HWLibs è **mispointed** verso dati firmware X4000. Non è una classe base valida.

---

## 5. `gMetaClass` e fixup

| Simbolo | Address | Sezione | Contenuto file |
|---|---:|---|---|
| X6100::gMetaClass | `0xED11A10` | `__common` | **zero-fill** |
| HWLibs::gMetaClass | `0xED11A38` | `__common` | **zero-fill** |
| SWIP::gMetaClass | `0xED11A60` | `__common` | **zero-fill** |

**PROVEN:** i tre `gMetaClass` sono in **`__common`** e **non hanno bytes inizializzati**.
**INFERRED:** vengono costruiti a runtime da `OSMetaClass`; senza boot non se ne può leggere il contenuto.

**Fixup:**
- `superClass` X6100: **`0xE11C128` → `0xED11A60`**;
- `superClass` HWLibs: **`0xE11CA90` → `0x12AA488`**;
- `superClass` SWIP: **`0xE11D3F0` → `0xED11A38`**;
- `metaClass` X6100/HWLibs/SWIP: **`0xE11C120/0xE11CA88/0xE11D3E8` → `0xED11A10/38/60`**.

**PROVEN:** i fixup sono a 8 byte in **`__const`**, allineati 8; **0 scritture successive**.

---

## 6. Altri bundle AMD

| Bundle | `superClass` | `gMetaClass` | Note |
|---|---:|---:|---|
| **X6100** | `0xE11C128`, `0xE11CA90`, `0xE11D3F0` | `0xED11A10/38/60` | 3 classi |
| **X4000** | `0x9840B8`, `0x984A18` | `0x1485950/78` | HWLibs, CAIL |
| **X4400** | `0x23700B8`, `0x2370A18` | `0x31D4A90/B8` | HWLibs, CAIL |
| **AMD10000Controller** | import `IOService::gMetaClass` | — | non definisce le 3 classi |

**PROVEN:** X4000 e X4400 hanno proprie coppie **`superClass` / `gMetaClass`**, separate da X6100.
**UNPROVEN:** la relazione esatta tra la `superClass` X6100 e le classi X4000; il target **`0x12AA488`** non è un `gMetaClass` X4000.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| 3 coppie vtable/MetaClass? | **SÌ** |
| `metaClass` → `gMetaClass`? | **SÌ, 3/3** |
| Gerarchia X6100 → SWIP? | **PROVEN** |
| Gerarchia SWIP → HWLibs? | **PROVEN** |
| HWLibs → `0x12AA488`? | **PROVEN come puntatore** |
| `0x12AA488` è un `gMetaClass`? | **NO — firmware X4000** |
| Gerarchia completa valida? | **NO — ultimo anello invalido** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** la gerarchia **X6100 → SWIP → HWLibs** è **PROVEN**; l’ultimo anello **HWLibs → `0x12AA488`** punta **dentro `_polaris10_kicker_smc_firmware` X4000**, non a un `gMetaClass`. La gerarchia delle 6 vtable è quindi **valida fino a HWLibs**, ma **non completa**. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **≈12,28 GiB** > **10 GiB**. Nessuna cancellazione eseguita; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessuna estrazione/modifica/build/boot.
