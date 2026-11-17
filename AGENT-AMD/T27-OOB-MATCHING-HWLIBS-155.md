# T27 — AGENT-AMD — MATCHING HWLIBS X6000 (155)

**Scope:** stabilire staticamente se la personality `AMDRadeonX6000_AMDRadeonHWLibsX6000` può associarsi all'istanza `AMDRadeonX6000_AMDRadeonHWServicesNavi` tramite `IOProviderClass=AMDRadeonX6000_AMDRadeonHWServicesInterface`, analizzando `IOProviderClass`, `IOMatchCategory`, `IOPropertyMatch`, la gerarchia `OSMetaClass` e i simboli BootKC/SystemKC. Nessuna ripetizione dei report 152–154.

**Esito:** **PROVEN** che il provider class matcha: `Navi` è sottoclasse di `Interface`, quindi `IOProviderClass` non è il blocco. **REFUTED** però il match completo della personality X6000 sul target Navi 14: `getMatchProperty` pubblica `Load6100` per il project name `ATY,Boa`, mentre X6000 richiede `Load6000`. Il candidato coerente è **X6100**, che richiede `Load6100`. L'attach runtime resta **UNPROVEN**. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| X6000HWServices | `cc7aaca45446f98cc4ea03b1fdf80b402975c1b0e0d07585a304d78dcdf797f7` |
| HWServices `Info.plist` | `c6dcc67430bbbff1490e7101d395b3dbcfe248c10adc889efd59dd1689810bf0` |
| X6000HWLibs `Info.plist` | `42599c7cdb3269e7ed39614766dc1955c3eba5eba52d3d1aeab5cad75ffcbd5c` |
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| BootKC | `9bb053cf695957c13ce4b5497490b1f24ab69fea1cdeed57138580a8235ba840` |

**PROVEN:** gli artefatti sono quelli indicati.

---

## 2. Gerarchia del provider: Navi è Interface

### 2.1 MetaClass costruttori

I costruttori `MetaClassC2` passano a `OSMetaClass::OSMetaClass(char const*, OSMetaClass const*, unsigned int)` — simbolo BootKC `0xFFFFFF8000A1C3E0` — il nome della classe, il puntatore alla MetaClass della superclasse e la dimensione dell'oggetto.

| Classe | MetaClassC2 | Nome passato | Superclasse passata | Size |
|---|---:|---|---|---:|
| `HWServicesNavi` | `0xc26cac0` | `AMDRadeonX6000_AMDRadeonHWServicesNavi` | `SWIP::gMetaClass` | `0xd8` |
| `HWServicesSWIP` | `0xc26ceb0` | `AMDRadeonX6000_AMDRadeonHWServicesSWIP` | `Abstract::gMetaClass` | `0xd8` |
| `HWServicesAbstract` | `0xc26d4f0` | `AMDRadeonX6000_AMDRadeonHWServicesAbstract` | `Interface::gMetaClass` | `0xd0` |
| `HWServicesInterface` | `0xc26d300` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` | `IOService::gMetaClass` (import/GOT) | `0x88` |

**PROVEN:** Navi → SWIP → Abstract → Interface.
**PROVEN:** il nome della classe Interface è esattamente `AMDRadeonX6000_AMDRadeonHWServicesInterface`.
**INFERRED:** la superclasse di Interface è `IOService::gMetaClass`; il costruttore Interface carica il puntatore dalla GOT `0xc26f018`, e HWServices importa `__ZN9IOService10gMetaClassE`.

### 2.2 Catena di costruzione dell'oggetto

| Costruttore | Indirizzo | Chiama |
|---|---:|---|
| `Navi` | `0xc26c980` | `SWIP` a `0xc26ce10` |
| `SWIP` | `0xc26ce10` | `Abstract` |
| `Abstract` | `0xc26d440` | `Interface` a `0xc26d260` |
| `Interface` | `0xc26d260` | base `IOService`; imposta il vptr Interface |

**PROVEN:** l'istanza Navi contiene la catena Interface; non esiste un oggetto Interface separato.
**PROVEN:** `Navi` è quindi `isKindOf`/`metaCast` compatibile con il nome `AMDRadeonX6000_AMDRadeonHWServicesInterface`.

---

## 3. `IOProviderClass`: il match è compatibile

### 3.1 Evidenza BootKC

| Simbolo | Indirizzo |
|---|---:|
| `OSMetaClassBase::metaCast(OSMetaClass const*)` | `0xFFFFFF8000A1C580` |
| `OSMetaClassBase::metaCast(OSSymbol const*)` | `0xFFFFFF8000A1C710` |
| `OSMetaClassBase::metaCast(OSString const*)` | `0xFFFFFF8000A1C830` |
| `OSMetaClassBase::metaCast(char const*)` | `0xFFFFFF8000A1C8D0` |
| `OSMetaClassBase::safeMetaCast` | `0xFFFFFF8000A1C540` |
| `OSMetaClass::getSuperClass()` | `0xFFFFFF8000A1DBF0` |
| `OSMetaClass::checkMetaCastWithName(char const*, ...)` | `0xFFFFFF8000A1DB50` |
| `IOService::matchPropertyTable(OSDictionary*, int*)` | `0xFFFFFF8000A95AB0` |
| `IOService::matchPropertyTable(OSDictionary*)` | `0xFFFFFF8000A95AD0` |
| `IOService::compareProperty` | `0xFFFFFF8000A95C60`, `0xA95CD0` |
| `IOService::propertyMatching` | `0xFFFFFF8000AAA640` |
| `gIOProviderClassKey` | `0xFFFFFF80013A1188` |
| `gIOMatchCategoryKey` | `0xFFFFFF80013A11A0` |
| `gIOClassKey` | `0xFFFFFF80013A9E40` |

**PROVEN:** i simboli e le chiavi esistono nel BootKC.
**INFERRED (semantica XNU):** `IOProviderClass` viene confrontato con la classe del provider tramite `metaCast`/`checkMetaCast`, che percorre la catena delle superclassi; non è un confronto di stringa esatta.
**UNPROVEN:** il corpo byte-per-byte di `IOService::matchPropertyTable` nei fileset BootKC; i segmenti non sono disassemblabili con gli strumenti disponibili.

### 3.2 Applicazione al target

`IOProviderClass` della personality X6000HWLibs:

```text
AMDRadeonX6000_AMDRadeonHWServicesInterface
```

Il provider pubblicato da HWServices è un oggetto `AMDRadeonX6000_AMDRadeonHWServicesNavi`, la cui catena MetaClass include `...Interface`.

**PROVEN:** il requisito `IOProviderClass` è soddisfatto.
**REFUTED:** `IOProviderClass` è la causa del mancato match X6000.

---

## 4. `IOMatchCategory`: non è un filtro di classe

| Personality | `IOClass` | `IOMatchCategory` | `IOProviderClass` | `IOPropertyMatch` |
|---|---|---|---|---|
| HWServices Navi | `...HWServicesNavi` | `AMDRadeonX6000HWServices` | `IOPCIDevice` | `LoadHWServices=true` |
| X6000HWLibs | `...HWLibsX6000` | `AMDRadeonHWLibs` | `...HWServicesInterface` | `LoadPlugIn=Load6000` |
| X6100HWLibs | `...HWLibsX6100` | `AMDRadeonHWLibs` | `...HWServicesInterface` | `LoadPlugIn=Load6100` |

**PROVEN:** `IOMatchCategory` non è il nome della classe e non sostituisce `IOProviderClass`; è una categoria di servizio.
**PROVEN:** `findPlugIn` (`0xc26dc80`) cerca un child con `IOMatchCategory == AMDRadeonHWLibs`.
**INFERRED:** `IOMatchCategory` non impedisce il match X6000; il blocco è `IOPropertyMatch`.
**NOTA:** la categoria uguale per X6000/X6100/X6200/... rende possibile che `findPlugIn` restituisca il primo child della categoria; non distingue X6000 da X6100.

---

## 5. `IOPropertyMatch.LoadPlugIn`: qui il match X6000 fallisce

### 5.1 Ordine in `Abstract::start`

`Abstract::start` a `0xc26d8c0`:

| Indirizzo | Azione |
|---:|---|
| `0xc26d9a0` | `readProjectName()` |
| `0xc26d9a9` | salva il project name in `0xa0(this)` |
| `0xc26d9b3` | `getMatchProperty()` via slot `0x868` |
| `0xc26d9d7` | `setProperty(MATCH_PLUG_IN_REG_KEY, valore)` via slot `0x270` |
| `0xc26da0d` | `registerService(2)` via slot `0x5b0` |
| `0xc26da21` | `findPlugIn()` |

**PROVEN:** `LoadPlugIn` è impostato **prima** di `registerService(2)`.
**PROVEN:** il valore pubblicato è quello restituito da `getMatchProperty`.

### 5.2 `ProjectNameTable`

`getMatchProperty` (`0xc26cbe0`) parte da `Load6000`, controlla `-amd_simnow` e poi confronta il project name con `ProjectNameTable` a `0xc271730`.

| Project name | Valore `LoadPlugIn` |
|---|---|
| `ATY,Henbury` | `Load6810` |
| `ATY,Belknap` | `Load6800` |
| `ATY,Carswell` | `Load6800` |
| `ATY,Sunbeam` | `Load6300` |
| `ATY,Ikaheka` | `Load6200` |
| `ATY,Keelback` | `Load6200` |
| `ATY,Python` | `Load6700` |
| `ATY,Adder` | `Load6700` |
| `ATY,Boa` | `Load6100` |

**PROVEN:** `ATY,Boa` → `Load6100`.
**PROVEN:** il default è `Load6000`; `-amd_simnow` produce `Load6000Sim`.
**PROVEN:** il target Navi 14 `0x7340` è un `ATY,Boa` (nome progetto osservato in IORegistry come `ATY,Boa@0` e proprietà `name = ATY,Boa`).
**INFERRED:** `readProjectName` legge la proprietà `@0,name` del provider e fornisce `ATY,Boa` a `getMatchProperty`.

### 5.3 Conseguenza

| Personality | Richiede | Target pubblica | Match |
|---|---|---|---|
| X6000HWLibs | `Load6000` | `Load6100` | **NO** |
| X6100HWLibs | `Load6100` | `Load6100` | **SÌ statico** |
| X6000 con project assente/default | `Load6000` | `Load6000` | **condizionale** |
| X6000 con `-amd_simnow` | `Load6000` | `Load6000Sim` | **NO** |

**REFUTED:** `AMDRadeonX6000_AMDRadeonHWLibsX6000` non può soddisfare `IOPropertyMatch.LoadPlugIn=Load6000` sul target Navi 14 `ATY,Boa`, perché il provider pubblica `Load6100`.
**PROVEN:** `AMDRadeonX6100_AMDRadeonHWLibsX6100` ha la stessa `IOProviderClass`, la stessa `IOMatchCategory`, e richiede `Load6100`: è il candidato statico coerente.
**PROVEN:** la classe `AMDRadeonX6100_AMDRadeonHWLibsX6100` è presente in SystemKC (`MetaClassC1 0xdd6e980`, ctor `0xdd6e9d0`, `MetaClassC2 0xdd6eb10`, vtable `0xe11c130`).

---

## 6. Verdetto

| Domanda | Risposta | Stato |
|---|---|---|
| Navi è sottoclasse di Interface? | **SÌ** | **PROVEN** |
| `IOProviderClass=Interface` è soddisfatto? | **SÌ** | **PROVEN** |
| `IOClass=HWLibsX6000` esiste? | **SÌ** | **PROVEN** |
| `IOMatchCategory` blocca? | **NO** | **INFERRED** |
| `LoadPlugIn=Load6000` sul target? | **NO; pubblica Load6100** | **REFUTED** |
| X6000HWLibs si associa al target? | **NO staticamente** | **REFUTED** |
| X6100HWLibs è il candidato? | **SÌ** | **PROVEN staticamente** |
| Attach runtime | non osservato | **UNPROVEN** |
| T27 GO? | **NO** | **OPEN** |

**Risposta netta:** `AMDRadeonX6000_AMDRadeonHWLibsX6000` è compatibile con il **provider class** `AMDRadeonX6000_AMDRadeonHWServicesInterface`, perché `HWServicesNavi` è una sottoclasse di Interface. Tuttavia la personality completa non è compatibile con il target Navi 14 `ATY,Boa`: `getMatchProperty` pubblica `Load6100`, mentre X6000 richiede `Load6000`. Il match statico X6000 è quindi **REFUTED**; il candidato coerente è **X6100**. Restano **UNPROVEN** l'attach runtime e la selezione univoca del child; `findPlugIn` continua a controllare solo `IOMatchCategory`. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **12.299.240 KiB ≈ 11,73 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
