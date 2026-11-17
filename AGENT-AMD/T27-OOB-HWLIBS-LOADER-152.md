# T27 — AGENT-AMD — HWLIBS LOADER (152)

**Scope:** identificare il meccanismo effettivo che carica `AMDRadeonX6000HWLibs`, chiarire il caller di `getMatchProperty`, seguire `setProperty("LoadPlugIn")` e il consumatore IOKit, ricostruire la catena `HWServices::start → registerService → findPlugIn → createTtlInterface`.

**Modalità:** sola lettura; SystemKC, `AMDRadeonX6000HWServices`, `AMDRadeonX6000HWLibs.kext/Contents/Info.plist`, HWServices/acceleratore plist; nessun boot, trace, modifica, build, download o estrazione pesante.

**Esito:** **CORRETTA LA CONCLUSIONE DEL REPORT 151**. `getMatchProperty` **ha un caller statico**: `AMDRadeonX6000_AMDRadeonHWServicesAbstract::start` a `0xc26d9b3` (`callq *0x868(%rax)`). Il vptr oggetto è `__ZTV Navi + 0x10` = `0xc26f088`; lo slot `0x868` punta a `0xc26cbe0` (`getMatchProperty`). Il vecchio slot `0x878` era letto da `__ZTV` e ha causato l'errore. Il caricamento di HWLibs non è una chiamata diretta a `OSKext::load`: è il matching IOKit dichiarativo attivato da `registerService(2)` dopo la pubblicazione di `LoadPlugIn`. `findPlugIn` cerca un child già presente; non lo carica e non lo avvia. Il runtime resta **UNPROVEN**. T27 resta **OPEN**.

---

## 1. SHA-256

| Artefatto | SHA-256 |
|---|---|
| SystemKC | `b4b618bfb835fc761cf59f00904e4ef865a0d2a6dad3cd76dd827f91c1d8b5a7` |
| X6000HWServices | `cc7aaca45446f98cc4ea03b1fdf80b402975c1b0e0d07585a304d78dcdf797f7` |
| HWServices `Info.plist` | `c6dcc67430bbbff1490e7101d395b3dbcfe248c10adc889efd59dd1689810bf0` |
| X6000HWLibs `Info.plist` | `42599c7cdb3269e7ed39614766dc1955c3eba5eba52d3d1aeab5cad75ffcbd5c` |
| X6000 `Info.plist` | `b23242e2202383f7f7fe2dbc053fbf211a18298065e8fe752bf68064bb10ab98` |

**PROVEN:** gli artefatti sono quelli indicati.
**PROVEN:** la SHA di HWServices è quella corrente; i report precedenti che riportano `2aa47c…` usano una copia diversa.

---

## 2. Rettifica del vptr e degli slot

### 2.1 Costruttore Navi

`AMDRadeonX6000_AMDRadeonHWServicesNavi::AMDRadeonX6000_AMDRadeonHWServicesNavi` è a `0xc26c980`.

| Indirizzo | Istruzione |
|---:|---|
| `0xc26c99c` | chiama il costruttore SWIP |
| `0xc26c9a5` | `leaq __ZTV…Navi(%rip), %rcx` |
| `0xc26c9ac` | `addq $0x10, %rcx` |
| `0xc26c9b0` | `movq %rcx, (%rax)` — imposta il vptr |

**PROVEN:** il vptr dell'oggetto è `__ZTV Navi + 0x10`. `__ZTV` è a `0xc26f078`; il vptr oggetto è **`0xc26f088`**.

### 2.2 Slot oggetto

| Slot oggetto | Entry | Raw | Target | Simbolo |
|---:|---:|---:|---:|---|
| `0x858` | `0xc26f8e0` | `0x004000004c26cd30` | `0xc26cd30` | `AMDRadeonX6000_AMDRadeonHWServicesAbstract::getCail()` |
| `0x868` | `0xc26f8f0` | `0x010000004c26cbe0` | `0xc26cbe0` | `AMDRadeonX6000_AMDRadeonHWServicesNavi::getMatchProperty()` |
| `0x878` | `0xc26f900` | `0x0000000000000000` | — | vuoto |

**PROVEN:** lo slot `0x868` è `getMatchProperty`.
**PROVEN:** lo slot `0x878` è vuoto; non esiste un secondo entry `getMatchProperty` a `0xc26f900`.
**PROVEN:** `getCail` è nello slot `0x858`, non nello slot `0x868`.

### 2.3 Errore del report 151

Il report 151 aveva letto gli slot da `__ZTV` (`0xc26f078`):

| Lettura errata | Valore | Perché errata |
|---|---:|---|
| `__ZTV + 0x868` | `0xc26f8e0` ← `getCail` | il vptr oggetto è `+0x10`, non `__ZTV` |
| `__ZTV + 0x878` | `0xc26f8f0` ← `getMatchProperty` | slot spostato di `0x10` |
| `__ZTV + 0x900` | vuoto | non è lo slot oggetto `0x878` |

**PROVEN:** l'affermazione del report 151 «`start` chiama `getCail`, non `getMatchProperty`» è **REFUTED**.
**PROVEN:** l'affermazione «nessun call-site statico di `getMatchProperty` in HWServices» è **REFUTED**.

---

## 3. `getMatchProperty` e il suo caller

`AMDRadeonX6000_AMDRadeonHWServicesNavi::getMatchProperty()` è a `0xc26cbe0`.

| Indirizzo | Comportamento |
|---:|---|
| `0xc26cc02` | default `"Load6000"` |
| `0xc26cc1d` | `PE_parse_boot_argn("-amd_simnow", …)` |
| `0xc26cc45` | se presente: `"Load6000Sim"` |
| `0xc26cc50`–`0xc26cc8d` | legge `0xa0(%rax)` (project name) e confronta con `ProjectNameTable[i].first` |
| `0xc26ccb0` | se match: `ProjectNameTable[i].second` diventa il valore di ritorno |
| `0xc26ccc8`–`0xc26ccec` | ritorna la stringa selezionata |

`ProjectNameTable` è a `0xc271730`; `PROJECT_NAME_COUNT` è a `0xc26e3a0` e vale `9`.

| Indice | Project name | Load string |
|---:|---|---|
| 0 | `ATY,Henbury` | `Load6810` |
| 1 | `ATY,Belknap` | `Load6800` |
| 2 | `ATY,Carswell` | `Load6800` |
| 3 | `ATY,Sunbeam` | `Load6300` |
| 4 | `ATY,Ikaheka` | `Load6200` |
| 5 | `ATY,Keelback` | `Load6200` |
| 6 | `ATY,Python` | `Load6700` |
| 7 | `ATY,Adder` | `Load6700` |
| 8 | `ATY,Boa` | `Load6100` |

**PROVEN:** il default è `Load6000`.
**PROVEN:** `-amd_simnow` sostituisce il default con `Load6000Sim`.
**PROVEN:** la tabella progetto è di 9 elementi e contiene i mapping sopra.

### 3.1 Call-site

`AMDRadeonX6000_AMDRadeonHWServicesAbstract::start` è a `0xc26d8c0`.

| Indirizzo | Istruzione |
|---:|---|
| `0xc26d9a0` | `readProjectName()` |
| `0xc26d9a9` | salva il risultato a `+0xa0` |
| `0xc26d9b0` | `movq (%rdi), %rax` — carica il vptr oggetto |
| **`0xc26d9b3`** | **`callq *0x868(%rax)` → `getMatchProperty` (`0xc26cbe0`)** |
| `0xc26d9b9` | salva il ritorno in `-0x20(%rbp)` |
| `0xc26d9c5`–`0xc26d9d7` | `setProperty("LoadPlugIn", returnedValue)` |
| `0xc26da0d` | `callq *0x5b0(%rax)` con `esi = 2` |
| `0xc26da21` | `findPlugIn()` |

**PROVEN:** il caller statico di `getMatchProperty` è `start` a **`0xc26d9b3`**.
**PROVEN:** il valore restituito viene pubblicato come proprietà `LoadPlugIn` a `0xc26d9d7`.
**PROVEN:** non c'è alcun percorso esterno misterioso: la catena è interna a HWServices.

---

## 4. Pubblicazione e matching

### 4.1 `registerService(2)`

Il dispatch `*0x5b0` a `0xc26da0d` usa l'entry oggetto `0xc26f638`:

| Elemento | Valore |
|---|---:|
| raw | `0x0040000000994c60` |
| target chained L0 | `0x994c60 + 0xFFFFFF8000100000` = `0xFFFFFF8000A94C60` |
| simbolo | `IOService::registerService(unsigned int)` |
| argomento | `esi = 2` |

**PROVEN:** `start` chiama `registerService(2)` a `0xc26da0d`.
**PROVEN:** la chiamata avviene **dopo** `setProperty("LoadPlugIn")` e **prima** di `findPlugIn`.
**NOTA:** la decodifica usa il formato `DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE` e la base livello 0; è la stessa decodifica verificata nei report 110/126. La lettura «slot `0x5b0` = `_RESERVEDIOService47`» derivava dall'uso di `__ZTV` senza `+0x10`.

### 4.2 `findPlugIn`

`AMDRadeonX6000_AMDRadeonHWServicesAbstract::findPlugIn()` è a `0xc26dc80`.

| Indirizzo | Istruzione / significato |
|---:|---|
| `0xc26dc9b` | `callq *0x6a8(%rax)` — ottiene il provider/collezione da scandire |
| `0xc26dca7`–`0xc26dcab` | se nullo, ritorna `0` |
| `0xc26dcd9` | `callq *0x128(%rax)` — ottiene l'iteratore dei child |
| `0xc26dcfb` | `getProperty` sul child |
| `0xc26dd15` | legge `"IOMatchCategory"` |
| `0xc26dd49` | confronta con `HWLIB_PLUG_IN_MATCH_CATEGORY` (`"AMDRadeonHWLibs"`) |
| `0xc26dd5c`–`0xc26dd64` | se match, salva il child e interrompe |
| `0xc26dd72` | rilascia l'iteratore |
| `0xc26dd75` | ritorna il child |

**PROVEN:** `findPlugIn` non chiama `OSKext::load`, `IOCatalogue::startMatching` o un carichitore: si limita a cercare un child già presente con `IOMatchCategory = AMDRadeonHWLibs`.
**PROVEN:** se non trova il child, `start` registra `"Could not find HW Lib Plug In."` e fallisce.
**PROVEN:** il child trovato viene salvato a `this+0xa8`; il successivo `*0x20` è `OSObject::release(int)`, non `start`.
**UNPROVEN:** chi ha creato/attaccato il child a runtime; il percorso statico si ferma al matching IOKit.

### 4.3 `SWIP::start` e `createTtlInterface`

`AMDRadeonX6000_AMDRadeonHWServicesSWIP::start` è a `0xc26cff0`.

| Indirizzo | Istruzione / significato |
|---:|---|
| `0xc26d008` | carica `__ZTV Abstract` |
| `0xc26d00f` | carica `0x5d0(%rax)` |
| `0xc26d01a` | chiama la funzione: target `0xc26d8c0` = `Abstract::start(provider)` |
| `0xc26d032` | se il ritorno è vero, chiama `createTtlInterface(IOPCIDevice*)` |
| `0xc26d03b` | salva l'interfaccia a `this+0xd0` |

`createTtlInterface` è a `0xc26d060`:

| Indirizzo | Istruzione / significato |
|---:|---|
| `0xc26d07c` | legge `this+0xa8` (child HWLibs) |
| `0xc26d09a` | prepara la chiave `"AmdTtlInterfaceKey"` |
| `0xc26d0b2` | `callq *0x6c0(%rax)` sul child |
| `0xc26d100`–`0xc26d104` | ritorna l'oggetto interfaccia |

**PROVEN:** `SWIP::start` chiama `Abstract::start` e, se riesce, usa il child HWLibs tramite `callPlatformFunction("AmdTtlInterfaceKey")`.
**PROVEN:** `createTtlInterface` non carica il kext; usa il child già trovato.
**PROVEN:** il percorso `Abstract::start → findPlugIn → SWIP::start → createTtlInterface` è staticamente concatenato.

---

## 5. Metadati HWLibs e matching

`AMDRadeonX6000HWLibs.kext/Contents/Info.plist`:

| Campo | Valore |
|---|---|
| `CFBundleIdentifier` | `com.apple.kext.AMDRadeonX6000HWLibs` |
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWLibsX6000` |
| `IOMatchCategory` | `AMDRadeonHWLibs` |
| `IOProviderClass` | `AMDRadeonX6000_AMDRadeonHWServicesInterface` |
| `IOPropertyMatch.LoadPlugIn` | `Load6000` |

`OSBundleLibraries` contiene `IOPCIFamily`, `bsd`, `iokit`, `libkern`, `mach`; **non** contiene HWServices.

**PROVEN:** la personality è completa e dichiara il provider Interface.
**PROVEN:** il match richiede `LoadPlugIn = Load6000` e `IOMatchCategory = AMDRadeonHWLibs`.
**PROVEN:** il legame HWServices/HWLibs non è una dipendenza di linkage: è un match IOKit dichiarativo.
**PROVEN:** il plugin X6000 è solo uno dei child possibili; X6100/X6200/X6700 usano `Load6100`/`Load6200`/`Load6700` e lo stesso provider Interface.

### 5.1 HWServices

`AMDRadeonX6000HWServices.kext/Contents/Info.plist`:

| Campo | Valore |
|---|---|
| `IOClass` | `AMDRadeonX6000_AMDRadeonHWServicesNavi` |
| `IOMatchCategory` | `AMDRadeonX6000HWServices` |
| `IOPCIMatch` | include `0x7340/41/43/47/4F` |
| `IOPropertyMatch.LoadHWServices` | `true` |
| `IOProviderClass` | `IOPCIDevice` |
| `IOProbeScore` | `65051` |

**PROVEN:** HWServices matcha il device PCI solo dopo che il wrangler ha scritto `LoadHWServices=true`.
**PROVEN:** la proprietà `LoadPlugIn` viene scritta sul servizio HWServices, non sul dispositivo PCI.

### 5.2 Acceleratore

`AMDRadeonX6000.kext/Contents/Info.plist` contiene personalities con:

| Campo | Valore |
|---|---|
| `IOMatchCategory` | `IOAccelerator` |
| `IOPropertyMatch.LoadAccelerator` | `true` |
| `IOPCIMatch` | include i cinque ID Navi 14 |
| `IOProviderClass` | `IOPCIDevice` |

**PROVEN:** l'acceleratore è un match separato, che dipende da `LoadAccelerator=true`.
**PROVEN:** `LoadAccelerator` non è scritto da HWServices/HWLibs; è scritto dal wrangler in `vendor_doDeviceAttribute` (`AMDSupport 0x13b8462d`, Framebuffer `0xbf98a72`).

---

## 6. Meccanismo effettivo

| Fase | Evidenza | Stato |
|---|---|---|
| 1. Wrangler scrive `LoadHWServices=true` | `AMDSupport 0x13b84611`; Framebuffer `0xbf98a25` | **PROVEN** |
| 2. HWServices matcha `LoadHWServices` | plist HWServices | **PROVEN** |
| 3. `Abstract::start` legge il project name | `readProjectName` `0xc26d9a0` | **PROVEN** |
| 4. `getMatchProperty` restituisce `Load6000` o `Load6100/6200/6700` | `0xc26cbe0` | **PROVEN** |
| 5. `setProperty("LoadPlugIn", value)` | `0xc26d9d7` | **PROVEN** |
| 6. `registerService(2)` pubblica il servizio | `0xc26da0d`; target `0xA94C60` | **PROVEN** |
| 7. IOKit matcha la personality HWLibs | plist `IOProviderClass`, `IOMatchCategory`, `LoadPlugIn` | **PROVEN metadati** |
| 8. `findPlugIn` trova il child HWLibs | `0xc26dc80`; `IOMatchCategory` | **PROVEN statico** |
| 9. `SWIP::start` crea il TTL tramite il child | `0xc26cff0` → `0xc26d060` | **PROVEN statico** |
| 10. `AmdTtlServices` legge `deviceTypeTable` | `0xc3211f4` | **PROVEN statico** |

**PROVEN:** il caricamento effettivo non è una funzione esplicita in HWServices. È il matching IOKit: `registerService(2)` pubblica il servizio/provider; la personality HWLibs dichiara `IOProviderClass=Interface`, `IOMatchCategory=AMDRadeonHWLibs` e `LoadPlugIn`; il kernel collega il child. `findPlugIn` si limita a recuperarlo.
**PROVEN:** il caller di `getMatchProperty` è `start`; non serve un caller esterno.
**PROVEN:** il vecchio «slot `0x878` senza caller» era un errore di base vtable.
**UNPROVEN:** l'ordine temporale runtime tra `registerService`, matching, attach e `findPlugIn`.
**UNPROVEN:** la pubblicazione IOService effettiva e la presenza del child in IORegistry.

---

## 7. Statico vs runtime

| Elemento | Statico | Runtime |
|---|---|---|
| Vptr oggetto `0xc26f088` | **PROVEN** | **UNPROVEN** |
| Slot `0x868` → `getMatchProperty` | **PROVEN** | **UNPROVEN** |
| Caller `0xc26d9b3` | **PROVEN** | **UNPROVEN** |
| `setProperty("LoadPlugIn")` | **PROVEN** | **UNPROVEN** |
| `registerService(2)` | **PROVEN** | **UNPROVEN** |
| `findPlugIn` → child | **PROVEN** | **UNPROVEN** |
| Match HWLibs nei metadati | **PROVEN** | **UNPROVEN** |
| `createTtlInterface` → `AmdTtlInterfaceKey` | **PROVEN** | **UNPROVEN** |
| Ordine dei match IOKit | **NON DIMOSTRATO** | **UNPROVEN** |
| Loader esplicito `OSKext::load` | **ASSENTE** | **UNPROVEN** |

**PROVEN:** la catena statica è completa dal `start` di HWServices al consumo della tabella.
**UNPROVEN:** che il kernel esegua questa catena nell'ordine previsto e che il child HWLibs sia già presente quando `findPlugIn` viene chiamato.

---

## 8. Punto mancante

Il punto mancante **non è** `getMatchProperty`: il caller è `start`. Il punto mancante è il **runtime del matching IOKit**:

1. `registerService(2)` deve pubblicare HWServices/Interface.
2. Il kernel deve eseguire il match della personality HWLibs con `IOProviderClass=Interface`, `IOMatchCategory=AMDRadeonHWLibs` e `IOPropertyMatch.LoadPlugIn`.
3. Il child HWLibs deve essere già attaccato quando `findPlugIn` scansiona i child.
4. Solo allora `SWIP::start` può ottenere `AmdTtlInterfaceKey`.

**PROVEN:** `findPlugIn` non può caricare il plugin da solo; se il child non c'è, fallisce.
**PROVEN:** non esiste una chiamata statica a `OSKext::load` o `IOCatalogue::startMatching` in HWServices.
**UNPROVEN:** il punto 1–3 a runtime; è necessario un trace/IORegistry, vietato in T27.

---

## 9. Verdetto

| Domanda | Risposta |
|---|---|
| `getMatchProperty` ha un caller statico? | **SÌ — `start` `0xc26d9b3`** |
| Slot oggetto di `getMatchProperty` | **`0x868`** |
| Slot `0x878` | **vuoto** |
| `getCail` slot | **`0x858`** |
| `start` chiama `registerService(2)`? | **SÌ — `0xc26da0d`** |
| `findPlugIn` carica il kext? | **NO — cerca un child** |
| Loader esplicito in HWServices | **NO** |
| Caricamento effettivo | **matching IOKit dichiarativo** |
| Catena statica completa | **SÌ** |
| Runtime osservato | **NO** |
| T27 GO? | **NO — OPEN** |

**Risposta netta:** `getMatchProperty` non è senza caller. Il caller è `AMDRadeonX6000_AMDRadeonHWServicesAbstract::start` a `0xc26d9b3`, tramite lo slot oggetto `0x868` del vptr `0xc26f088`; lo slot `0x878` è vuoto. Il report 151 aveva sbagliato la base della vtable (`__ZTV` invece di `__ZTV+0x10`). `start` pubblica `LoadPlugIn` e chiama `registerService(2)`; il caricamento di X6000HWLibs è il matching IOKit della personality (`IOProviderClass=Interface`, `IOMatchCategory=AMDRadeonHWLibs`, `IOPropertyMatch.LoadPlugIn`), non una chiamata a `OSKext::load`. `findPlugIn` recupera il child già attaccato; `SWIP::start` usa `AmdTtlInterfaceKey`. La catena statica è **PROVEN**; l'ordine runtime e l'attach effettivo restano **UNPROVEN**. **T27 OPEN**; percentuali invariate: **94% engineering / 32% first boot / 8% desktop**.

**Spazio:** **12.324.392 KiB ≈ 11,75 GiB** > **10 GiB**. Nessuna cancellazione; nessun file eliminabile proposto. **STOP rispettato:** sola lettura, nessun boot/trace/modifica/build/download.
