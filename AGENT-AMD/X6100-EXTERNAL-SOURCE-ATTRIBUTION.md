# T27 — AGENT-AMD — X6100 EXTERNAL SOURCE ATTRIBUTION

**Scope:** attribuire i **886 puntatori esterni** di `AMDRadeonX6100HWLibs` alle **posizioni sorgente** nella propria immagine: sezione, offset, simbolo nearest, vtable/GOT e struttura. Verificare separatamente gli **8 puntatori AMD10000Controller**. Nessuna presunzione di dipendenza runtime.

**Modalità:** sola lettura; parsing Mach-O embedded, `LC_DYLD_CHAINED_FIXUPS`, `nm -n`, `otool -l`, SHA-256. Nessuna estrazione, copia, modifica, build o boot.

**Esito:** **870/886** sorgenti sono slot in **`__DATA,__const`**, tutti in **vtable C++** (`__ZTV…`) tranne **1** in `superClass`; **16/886** sono slot in **`__DATA,__got`** vicino a `_DCE_BASE`. Gli **870** puntano tutti a **X4000HWLibs** (675 `__data`, 135 `__const`, 57 `__cstring`, 3 `__const` testo). I **16 GOT** si dividono in **8 codice AMD10000** (funzioni `Vega10Dce::BandwidthManager`), **7 dati X4000** e **1 dato X4400**. **0 slot esterni in `__DATA,__data`, `__DATA_CONST`, `__mod_*`**. La sorgente è PROVEN; il ruolo semantico e la risoluzione runtime restano **INFERRED/UNPROVEN**.

---

## 1. Input e metodo

| Input | Uso |
|---|---|
| `X6100-CROSS-PROVIDER-ATTRIBUTION.md` | 886 target e split 877/8/1 |
| `X6100-FIXUP-VALIDATION.md` | 154 catene, 8.544 slot |
| `X6100-RUNTIME-ADDRESSES.md` | base-0, target relativi |
| `X6100-KC-FIXUPS.md` | fileoff KC assoluti, sezioni |
| `systemkc-all/com.apple.kext.AMDRadeonX6100HWLibs` | sezioni, `nm`, `otool` |

Procedura:
1. traversal delle **154 catene** e dei **8.544 slot**;
2. filtro dei soli target esterni (**886**);
3. sezione sorgente da `sectname/offset` dell’immagine embedded;
4. simbolo X6100 **exact** o **nearest preceding** da `nm -n` (12.254 simboli definiti);
5. associazione a **vtable**, **GOT** o **struttura** dal simbolo e dalla sezione;
6. target provider e target symbol già attribuiti nel report precedente.

`nm` X6100 espone indirizzi assoluti KC-relativi; gli slot sono stati confrontati direttamente, senza sottrarre la load address.

---

## 2. Sorgenti: sintesi

| Sezione sorgente | Slot esterni | Quota | Simbolo sorgente | Classe |
|---|---:|---:|---|---|
| `__DATA,__const` | **870** | **98,19%** | 869 `__ZTV…` + 1 `superClass` | **vtable / metadata** |
| `__DATA,__got` | **16** | **1,81%** | `_DCE_BASE` nearest | **GOT** |
| `__DATA,__data` | **0** | 0% | — | — |
| `__DATA_CONST` | **0** | 0% | — | — |
| `__mod_init_func` / `__mod_term_func` | **0** | 0% | — | — |
| **Totale** | **886** | 100% | — | — |

**PROVEN:** **0 slot esterni** in `__DATA,__data`; **0** in `__DATA_CONST`; **0** nei moduli init/term. Tutti gli esterni partono da **`__const`** o **`__got`**.

---

## 3. `__DATA,__const` — 870 slot

### 3.1 Simboli sorgente

| Simbolo | Slot | Ruolo |
|---|---:|---|
| `__ZTV34AMDRadeonX6100_AMDRadeonHWLibsSWIP` | **256** | vtable |
| `__ZTV35AMDRadeonX6100_AMDRadeonHWLibsX6100` | **255** | vtable |
| `__ZTV30AMDRadeonX6100_AMDRadeonHWLibs` | **255** | vtable |
| `__ZTV21AtiPowerPlayInterface` | **32** | vtable |
| `__ZTVN35AMDRadeonX6100_AMDRadeonHWLibsX61009MetaClassE` | **23** | vtable/metaclass |
| `__ZTVN30AMDRadeonX6100_AMDRadeonHWLibs9MetaClassE` | **23** | vtable/metaclass |
| `__ZTVN34AMDRadeonX6100_AMDRadeonHWLibsSWIP9MetaClassE` | **23** | vtable/metaclass |
| `__ZTV25AtiApplePowerTuneServices` | **2** | vtable |
| `__ZN30AMDRadeonX6100_AMDRadeonHWLibs10superClassE` | **1** | metadata esatta |
| **Totale** | **870** | — |

**869** slot sono in **`__ZTV…`**; **1** è il simbolo esatto `superClass`. **0 callback** e **0 tabelle dati generiche** in questa sezione: la sorgente è **vtable/metadata**, non un array di callback.

### 3.2 Exact/nearest

| Metrica | Valore |
|---|---:|
| Exact | **1** (`superClass`) |
| Nearest | **869** |
| Absent | **0** |
| Tipo `S` | **836** |
| Tipo `s` | **34** |

**PROVEN:** ogni slot ha un simbolo sorgente; **0 absent**. La maggior parte è **nearest** perché lo slot è una **entry interna** alla vtable, non l’indirizzo iniziale del simbolo.

### 3.3 Target

Tutti gli **870** puntano a **X4000HWLibs**:

| Target X4000 | Slot | Quota |
|---|---:|---:|
| `__DATA,__data` | **675** | 77,59% |
| `__DATA,__const` | **135** | 15,52% |
| `__TEXT,__cstring` | **57** | 6,55% |
| `__TEXT,__const` | **3** | 0,34% |
| **Totale** | **870** | 100% |

**PROVEN (raw):** le vtable X6100 contengono slot che puntano a **dati/tabelle/firmware X4000**, non a codice X4000. **Non è una normale vtable di funzioni**; la semantica precisa di questi slot è **INFERRED** e il loro uso a runtime è **UNPROVEN**.

---

## 4. `__DATA,__got` — 16 slot

### 4.1 Sorgente

| Metrica | Valore |
|---|---:|
| Slot esterni | **16** |
| Exact | **0** |
| Nearest | **16** |
| Absent | **0** |
| Simbolo nearest | `_DCE_BASE` (16/16) |
| Sezione | `__DATA,__got` |

`_DCE_BASE` è a **0xE11BA98**; il `__got` inizia a **0xE11C000**. Il simbolo è il **nearest preceding**, non l’inizio del GOT: **`__got` non ha simboli propri** e `otool -Iv` non espone una tabella indirect per questa KC.

### 4.2 Ripartizione target

| Provider | Slot | Sezione target | Classe |
|---|---:|---|---|
| `AMD10000Controller` | **8** | `__TEXT,__text` | **codice** |
| `AMDRadeonX4000HWLibs` | **7** | `__DATA,__data` | **dati/firmware** |
| `AMDRadeonX4400HWLibs` | **1** | `__DATA,__data` | **dato/firmware** |
| **Totale** | **16** | — | — |

### 4.3 Dettaglio dei 16 slot

| Slot sorgente | Target | Provider | Target simbolo | Target classe |
|---|---|---|---|---|
| `0xE11C068` | `0x2941C50` | X4400 | `_kicker_hainan_2_smc_firmware` | data |
| `0xE11C070` | `0x9D69E0` | X4000 | `_aF32_CE_Ucode` | data |
| `0xE11C078` | `0x1ADD30` | AMD10000 | `Vega10Dce::BandwidthManager::programDisplayMark(...)` | code |
| `0xE11C080` | `0x1ADD68` | AMD10000 | idem | code |
| `0xE11C088` | `0x1ADD70` | AMD10000 | `Vega10Dce::BandwidthManager::nbPStateWatermark(...)` | code |
| `0xE11C090` | `0x1ADD40` | AMD10000 | `programDisplayMark(...)` | code |
| `0xE11C098` | `0x1ADD48` | AMD10000 | `programDisplayMark(...)` | code |
| `0xE11C0A0` | `0x12AA488` | X4000 | `_polaris10_kicker_smc_firmware` | data |
| `0xE11C0A8` | `0x1ADD38` | AMD10000 | `programDisplayMark(...)` | code |
| `0xE11C0B0` | `0x1AD4C0` | AMD10000 | `Vega10Dce::BandwidthManager::calculateWatermark(...)` | code |
| `0xE11C0B8` | `0x10EE040` | X4000 | `_stSPUKernel_CI` | data |
| `0xE11C0C0` | `0x12AA520` | X4000 | `_polaris10_kicker_smc_firmware` | data |
| `0xE11C0C8` | `0x12AA5C0` | X4000 | `_polaris10_kicker_smc_firmware` | data |
| `0xE11C0D0` | `0x1AF250` | AMD10000 | `Vega10Dce::BandwidthManager::programAdvancedStart(...)` | code |
| `0xE11C0D8` | `0x106D510` | X4000 | `_stSPUKernel_SI` | data |
| `0xE11C0E0` | `0x10E8C58` | X4000 | `_stSPUKernel_CI` | data |

**PROVEN (raw):** 16 slot GOT, 8 code AMD10000, 8 data (7 X4000 + 1 X4400); **0 unknown**.

### 4.4 Gli 8 slot AMD10000

| Slot | Target | Funzione |
|---|---|---|
| `0xE11C078` | `0x1ADD30` | `programDisplayMark` |
| `0xE11C080` | `0x1ADD68` | `programDisplayMark` |
| `0xE11C088` | `0x1ADD70` | `nbPStateWatermark` |
| `0xE11C090` | `0x1ADD40` | `programDisplayMark` |
| `0xE11C098` | `0x1ADD48` | `programDisplayMark` |
| `0xE11C0A8` | `0x1ADD38` | `programDisplayMark` |
| `0xE11C0B0` | `0x1AD4C0` | `calculateWatermark` (exact) |
| `0xE11C0D0` | `0x1AF250` | `programAdvancedStart` |

**INFERRED:** sono **function pointer GOT** verso il DCE di AMD10000. **UNPROVEN:** che siano usati, risolti o validi senza una dipendenza AMD dichiarata.

---

## 5. `otool` e symbol table

| Comando | Esito |
|---|---|
| `otool -l` | sezioni `__DATA,__got` (232 B), `__DATA,__const` (65.904 B), `__DATA,__data` (12.474.214 B) |
| `otool -Iv` | **nessuna entry indirect** (solo intestazione file) |
| `nm -n` X6100 | **12.254** simboli definiti; sorgenti risolte |
| `nm -u` X6100 | **0** simboli AMD/Radeon (già misurato) |

`otool -Iv` non fornisce una tabella indirect utilizzabile con `LC_DYLD_CHAINED_FIXUPS`; la associazione è quindi basata su **sezione + symbol table**, non su nomi indirect.

---

## 6. Interpretazione

### PROVEN

- **886** esterni = **870 `__DATA,__const` + 16 `__DATA,__got`**.
- **870 `__const`**: **869 vtable `__ZTV…` + 1 `superClass`**; **1 exact, 869 nearest, 0 absent**.
- **16 `__got`**: **0 exact, 16 nearest `_DCE_BASE`, 0 absent**.
- **870 `__const` → X4000** (675 data, 135 const, 57 cstring, 3 text const).
- **16 GOT → 8 AMD10000 code, 7 X4000 data, 1 X4400 data**.
- **0 esterni** in `__DATA,__data`, `__DATA_CONST`, `__mod_*`.
- **0 unknown**, **0 absent**, **0 fuori sezione**.

### INFERRED

- Gli slot `__const` sono **entry di vtable C++** (metaclass, interfacce, servizi).
- Gli slot `__got` sono **GOT/function-pointer** per DCE e **GOT data** per firmware.
- Le vtable X6100 contengono riferimenti **data** a X4000; non sono vtable di sole funzioni.

### UNPROVEN

- Che una vtable con target **data** sia lecita o usata come tale a runtime.
- Che gli 8 function pointer AMD10000 siano risolti/validi su 26B131.
- Che X6100 possa usare AMD10000/X4000/X4400 senza `OSBundleLibraries` AMD.
- Che `basePointers` sia zero, che gli indirizzi assoluti siano finali, e ogni comportamento di boot/ABI.

---

## 7. Conclusione

| Domanda | Risposta |
|---|---|
| Da dove partono gli 886 esterni? | **870 `__DATA,__const` + 16 `__DATA,__got`** |
| Gli 870 `__const` sono tabelle o vtable? | **869 vtable + 1 `superClass`** |
| Gli 870 puntano a codice? | **No: tutti a X4000 data/table/string** |
| I 16 GOT? | **8 codice AMD10000 + 7 dati X4000 + 1 dato X4400** |
| Ci sono callback in `__DATA,__data`? | **0 slot esterni in `__data`** |
| Simboli sorgente exact/nearest/absent? | **1 / 885 / 0** |
| Ruolo semantico PROVEN? | **No: vtable/GOT INFERRED** |
| Dipendenza runtime PROVEN? | **No: UNPROVEN** |
| T27 è GO? | **No: OPEN** |

La **sorgente** è ora completamente attribuita: gli 886 esterni non sono un array unico, ma **870 entry di vtable** in `__const` e **16 entry GOT** in `__got`. Le vtable X6100 puntano **solo dati X4000**; il GOT contiene **8 function pointer AMD10000** e **8 dati firmware**. La struttura è PROVEN; la semantica e la risoluzione runtime restano **INFERRED/UNPROVEN**. T27 resta **OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**STOP rispettato:** sola lettura; nessuna estrazione, copia, build, boot o modifica EFI/NVRAM/T2/SIP/AMFI. Spazio libero ultimo controllo **≈12,30 GiB** > **10 GiB**.
