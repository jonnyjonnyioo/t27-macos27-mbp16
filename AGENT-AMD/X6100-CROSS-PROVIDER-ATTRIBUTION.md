# T27 — AGENT-AMD — X6100 CROSS-PROVIDER ATTRIBUTION

**Scope:** attribuire gli **886 target esterni** di `AMDRadeonX6100HWLibs` ai tre bundle AMD in cui ricadono — **877 X4000HWLibs, 8 AMD10000Controller, 1 X4400HWLibs** — mappandoli su sezioni e simboli, senza presumere che il contenimento KC-relativo sia una dipendenza runtime.  
**Modalità:** sola lettura; parsing Mach-O dei provider embedded, sezioni, `nm -n`, symbol table, SHA-256. Nessuna estrazione, copia, scrittura, build o boot.  
**Esito:** i **877** target X4000 sono **682 dati + 195 tabelle/stringhe + 0 codice**; gli **8** target AMD10000 sono **8 codice** (`Vega10Dce::BandwidthManager...`); l’unico target X4400 è **1 dato firmware** (`_kicker_hainan_2_smc_firmware`). **0 target non classificabili**, **0 fuori sezione**, **0 assenti dalla symbol table**. La attribuzione **raw** è PROVEN; la dipendenza runtime resta **UNPROVEN** perché `basePointers` non è serializzato e `OSBundleLibraries` non dichiara alcun AMD.

---

## 1. Input e metodo

| Input | Uso |
|---|---|
| `X6100-PROVIDER-RESOLUTION.md` | 886 esterni grezzi e split 877/8/1 |
| `X6100-RUNTIME-ADDRESSES.md` | target KC-relativi, basi assolute UNPROVEN |
| `AMD-SYSTEMKC-28-INVENTORY.md` | UUID, `entry_id`, fileoff, prelink size |
| Provider `systemkc-all` | sezioni embedded e `nm -n` |

Per ciascun provider:
1. header Mach-O embedded al `LC_FILESET_ENTRY.fileoff`;
2. sezioni (`segname`, `sectname`, `addr`, `size`, `flags`);
3. `nm -n` sul file `systemkc-all`;
4. contenimento del target in **una** sezione;
5. simbolo **exact** o **nearest preceding**;
6. classificazione per sezione: **code**, **data**, **table/string**.

Le sezioni sono state lette dall’immagine embedded, quindi i loro `addr` sono già coordinati KC-relativi. `nm -n` espone indirizzi assoluti dello stesso spazio (`X4000` inizia a `0x6E7960`; `AMD10000` a `0x188600`; `X4400` a `0x2092960`).

---

## 2. Sintesi per provider

| Provider | Target | Unique | Code | Data | Table/string | Unknown | Symbol exact | Nearest | Absent |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `AMDRadeonX4000HWLibs` | **877** | **281** | **0** | **682** | **195** | **0** | **0** | **281** | **0** |
| `AMD10000Controller` | **8** | **8** | **8** | **0** | **0** | **0** | **1** | **7** | **0** |
| `AMDRadeonX4400HWLibs` | **1** | **1** | **0** | **1** | **0** | **0** | **0** | **1** | **0** |
| **Totale** | **886** | **290** | **8** | **683** | **195** | **0** | **1** | **289** | **0** |

**PROVEN:** ogni target ricade in **una sola** sezione; **0 unknown**, **0 absent**. La somma `682 + 195 = 877`; `8 + 1 = 9`; totale **886**.

---

## 3. `AMDRadeonX4000HWLibs` — 877 target

### 3.1 Sezioni

| Sezione | Target | Quota |
|---|---:|---:|
| `__DATA,__data` | **682** | 77,76% |
| `__DATA,__const` | **135** | 15,39% |
| `__TEXT,__cstring` | **57** | 6,50% |
| `__TEXT,__const` | **3** | 0,34% |
| **Totale** | **877** | 100% |

**Classificazione:** **682 dati**, **195 tabelle/stringhe**, **0 codice**. **Nessun target in `__TEXT,__text`**: questi puntatori **non sono function pointer**.

### 3.2 Simboli nearest

`nm -n` definisce **9.847** simboli. I 281 target unici hanno **0 exact**, **281 nearest**, **0 absent**. Tipi dei simboli nearest:

| Tipo | Unique |
|---|---:|
| `d` (data locale) | 216 |
| `s` (section) | 46 |
| `t` (text locale) | 18 |
| `D` (data globale) | 1 |

I 18 simboli `t` sono **nearest label** ma il target cade in una sezione **data/table**, non in `__text`: la classificazione primaria resta la sezione.

Simboli nearest più frequenti:

| Simbolo | Target |
|---|---:|
| `_aF32_MEC_Ucode` | 109 |
| `_CAILAsicCapsInitTable` | 63 |
| `__ZL20CAIL_ASIC_CAPS_TABLE` | 42 |
| `MCILDebugPrint.cold.1` | 18 |
| `_aRLC_Ucode` | 18 |
| `_scbu_tbl` | 11 |
| `_aSpectre_GoldenRegisterSettings` | 5 |
| `_polaris10_kicker_smc_firmware` | 3 |
| `_aBONAIRE_GoldenRegisterSettings_A1` | 2 |
| `_stSPUKernel_CI` | 2 |
| `_PwrVirusTable` | 1 |
| `__ZTV20AtiPowerPlayServices` | 1 |

**Attribuzione:** firmware, tabelle ASIC/CAIL, stringhe e dati di inizializzazione. **Nessuna funzione X4000**.

### 3.3 `__got` X4000

I 7 `__got` esterni puntano tutti a `__DATA,__data`:

| Target | Simbolo nearest | Tipo |
|---|---|---|
| `0x9D69E0` | `_aF32_CE_Ucode` | `d` |
| `0x12AA488` | `_polaris10_kicker_smc_firmware` | `d` |
| `0x10EE040` | `_stSPUKernel_CI` | `d` |
| `0x12AA520` | `_polaris10_kicker_smc_firmware` | `d` |
| `0x12AA5C0` | `_polaris10_kicker_smc_firmware` | `d` |
| `0x106D510` | `_stSPUKernel_SI` | `d` |
| `0x10E8C58` | `_stSPUKernel_CI` | `d` |

**PROVEN:** anche i `__got` X4000 sono **dati/firmware**, non codice.

---

## 4. `AMD10000Controller` — 8 target

| Sezione | Target | Classe |
|---|---:|---|
| `__TEXT,__text` | **8** | **code** |

`nm -n` definisce **2.340** simboli. **1 exact**, **7 nearest**, **0 absent**; tutti i simboli sono `T` (**text global**). Target e simboli:

| Target | Simbolo | Exact? |
|---|---|---|
| `0x1AD4C0` | `Vega10Dce::BandwidthManager::calculateWatermark(...)` | **SÌ** |
| `0x1ADD30` | `Vega10Dce::BandwidthManager::programDisplayMark(...)` | nearest |
| `0x1ADD38` | idem | nearest |
| `0x1ADD40` | idem | nearest |
| `0x1ADD48` | idem | nearest |
| `0x1ADD68` | idem | nearest |
| `0x1ADD70` | `Vega10Dce::BandwidthManager::nbPStateWatermark(...)` | nearest |
| `0x1AF250` | `Vega10Dce::BandwidthManager::programAdvancedStart(...)` | nearest |

**PROVEN (raw):** gli 8 target sono **function pointer** in `AMD10000Controller.__TEXT,__text`; **UNPROVEN** che siano risolti/validi a runtime. **Nessun simbolo AMD importato** in X6100 (`nm -u` 0 AMD); sono riferimenti **prelinkati**, non import simbolici.

---

## 5. `AMDRadeonX4400HWLibs` — 1 target

| Target | Sezione | Simbolo nearest | Tipo |
|---|---|---|---|
| `0x2941C50` | `__DATA,__data` | `_kicker_hainan_2_smc_firmware` | `d` |

`nm -n`: **11.008** simboli; **0 exact**, **1 nearest**, **0 absent**. **Dato firmware**, non codice.

---

## 6. Sorgenti X6100 e destinazioni

| Sorgente X6100 | Target esterni | Destinazione |
|---|---:|---|
| `__DATA,__const` | **870** | X4000 (dati/tabelle) |
| `__DATA,__got` | **7** | X4000 (firmware) |
| `__DATA,__got` | **8** | AMD10000 (codice) |
| `__DATA,__got` | **1** | X4400 (firmware) |
| **Totale** | **886** | — |

**`__DATA,__data` di X6100:** **0** target esterni. **`__DATA_CONST`:** **0**. **`__mod_*`:** **0**.

---

## 7. Coerenza con i metadati dei provider

| Provider | UUID | fileoff = load | Prelink size | Target range | Sezioni |
|---|---|---|---:|---|---|
| X4000 | `DFD77453-7CFD-3F72-8BFE-779582EA4E73` | **7.237.632** | 2.739.696 | `0x91C1F0–0x12AA5C0` | `__TEXT` + `__DATA` |
| AMD10000 | `B52EC43A-4077-3460-A1F5-4BC94CE9CCF7` | **1.605.632** | 382.670 | `0x1AD4C0–0x1AF250` | `__TEXT,__text` |
| X4400 | `02740323-FC2D-30DF-9FD4-2106BE3F3131` | **34.152.448** | 3.006.332 | `0x2941C50` | `__DATA,__data` |

**PROVEN:** tutti i target sono interni alle sezioni dei provider; **0 fuori sezione**. `_PrelinkExecutableSize` è la dimensione dell’eseguibile prelinkato, non dell’intero bundle: i target X4000/X4400 in `__DATA` sono **oltre** quella size ma dentro le sezioni `__DATA`; non è una contraddizione.

---

## 8. Interpretazione

### PROVEN

- X4000: **877** target = **682 data + 195 table/string + 0 code**.
- AMD10000: **8** target = **8 code** in `__TEXT,__text`; **1 exact**, **7 nearest**.
- X4400: **1** target = **1 data firmware**.
- **0 unknown**, **0 absent**, **0 fuori sezione**.
- I 16 `__got` esterni: **7 X4000 dati**, **8 AMD10000 codice**, **1 X4400 dato**.
- Le sezioni e i simboli sono coerenti con UUID/fileoff/load/prelink size dei tre provider.

### INFERRED

- X6100 condivide **tabelle/firmware** con X4000 e **funzioni DCE** con AMD10000.
- I riferimenti X4000/X4400 sono **puntatori dati**, quelli AMD10000 sono **function pointer** prelinkati.
- La presenza di tre provider reali rende il mapping grezzo plausibile, ma non dimostra la dipendenza.

### UNPROVEN

- Che `basePointers[cacheLevel]` sia zero e che i target siano gli indirizzi finali.
- Che i function pointer AMD10000 siano validi a runtime su 26B131.
- Che X6100 dichiari o possa usare AMD10000/X4000/X4400 senza dipendenze AMD in `OSBundleLibraries`.
- ABI, firma, SIP/AMFI, caricamento e boot.

---

## 9. Conclusione

| Domanda | Risposta |
|---|---|
| X4000: codice o dati? | **Dati/tabelle: 682 + 195; codice 0** |
| AMD10000: codice o dati? | **Codice: 8/8** (`Vega10Dce::BandwidthManager`) |
| X4400: codice o dati? | **Dato firmware: 1/1** |
| Target non classificabili? | **0** |
| Target fuori sezione? | **0** |
| Simboli exact/nearest/absent? | **1 / 289 / 0** |
| Attribuzione raw PROVEN? | **SÌ, per sezione e simbolo** |
| Dipendenza runtime PROVEN? | **NO — UNPROVEN** |
| T27 è GO? | **NO — OPEN** |

L’attribuzione **strutturale** è completa: i 886 esterni non sono un blocco indistinto. **877** sono dati/tabelle X4000 (inclusi firmware e CAIL), **8** sono function pointer AMD10000 e **1** è firmware X4400. Resta però **UNPROVEN** che questi riferimenti siano risolti e caricati su 26B131, soprattutto perché `basePointers` manca e `OSBundleLibraries` non dichiara AMD. T27 resta **OPEN**; percentuali ufficiali invariate: **94% engineering / 32% first boot / 8% desktop**.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, build, boot o modifica EFI/NVRAM/T2/SIP/AMFI. Spazio libero **12.899.228 KiB** (circa **12,30 GiB**) > **10 GiB**.
